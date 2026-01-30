// backend/src/services/auth.service.ts
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import crypto from 'crypto';
import { Redis } from 'ioredis';
import { OAuth2Client } from 'google-auth-library';
import speakeasy from 'speakeasy';
import QRCode from 'qrcode';
import { config } from '../config';
import { User, UserOAuth } from '../models';
import { sendEmail } from '../utils/email';
import { logger } from '../utils/logger';

export class AuthService {
  private redis: Redis;
  private googleClient: OAuth2Client;

  constructor(redisClient: Redis) {
    this.redis = redisClient;
    this.googleClient = new OAuth2Client(config.google.clientId);
  }

  async register(userData: {
    email: string;
    username: string;
    password: string;
    displayName?: string;
  }): Promise<{ user: User; tokens: TokenPair }> {
    // Validate email uniqueness
    const existingUser = await User.findOne({ 
      where: { email: userData.email } 
    });
    
    if (existingUser) {
      throw new Error('Email already registered');
    }

    // Validate username uniqueness
    const existingUsername = await User.findOne({
      where: { username: userData.username }
    });
    
    if (existingUsername) {
      throw new Error('Username already taken');
    }

    // Hash password
    const salt = await bcrypt.genSalt(12);
    const passwordHash = await bcrypt.hash(userData.password, salt);

    // Create user
    const user = await User.create({
      email: userData.email,
      username: userData.username,
      displayName: userData.displayName || userData.username,
      passwordHash,
    });

    // Generate tokens
    const tokens = await this.generateTokens(user);

    // Send welcome email
    await sendEmail({
      to: user.email,
      subject: 'Welcome to CENT!',
      template: 'welcome',
      data: {
        username: user.username,
        verifyUrl: `${config.app.url}/verify-email?token=${tokens.accessToken}`,
      },
    });

    return { user, tokens };
  }

  async login(identifier: string, password: string): Promise<{ user: User; tokens: TokenPair }> {
    // Find user by email or username
    const user = await User.findOne({
      where: {
        [Op.or]: [
          { email: identifier },
          { username: identifier },
        ],
      },
    });

    if (!user) {
      throw new Error('Invalid credentials');
    }

    // Check password
    const validPassword = await bcrypt.compare(password, user.passwordHash);
    if (!validPassword) {
      throw new Error('Invalid credentials');
    }

    // Check if 2FA is enabled
    if (user.twoFactorEnabled) {
      const tempToken = this.generateTempToken(user.id);
      await this.redis.setex(
        `2fa:${tempToken}`,
        300, // 5 minutes
        user.id
      );
      
      return {
        user,
        tokens: { accessToken: tempToken, refreshToken: null },
      };
    }

    // Update last login
    user.lastLogin = new Date();
    await user.save();

    // Generate tokens
    const tokens = await this.generateTokens(user);

    return { user, tokens };
  }

  async verifyTwoFactor(userId: string, token: string): Promise<TokenPair> {
    const user = await User.findByPk(userId);
    if (!user || !user.twoFactorSecret) {
      throw new Error('2FA not setup');
    }

    const verified = speakeasy.totp.verify({
      secret: user.twoFactorSecret,
      encoding: 'base32',
      token,
      window: 1,
    });

    if (!verified) {
      throw new Error('Invalid 2FA code');
    }

    return this.generateTokens(user);
  }

  async googleAuth(idToken: string): Promise<{ user: User; tokens: TokenPair; isNew: boolean }> {
    const ticket = await this.googleClient.verifyIdToken({
      idToken,
      audience: config.google.clientId,
    });

    const payload = ticket.getPayload();
    if (!payload) {
      throw new Error('Invalid Google token');
    }

    // Find or create user
    let user = await User.findOne({
      include: [{
        model: UserOAuth,
        where: {
          provider: 'google',
          providerUserId: payload.sub,
        },
      }],
    });

    let isNew = false;
    
    if (!user) {
      // Check if email exists
      user = await User.findOne({
        where: { email: payload.email },
      });

      if (user) {
        // Link OAuth to existing account
        await UserOAuth.create({
          userId: user.id,
          provider: 'google',
          providerUserId: payload.sub,
        });
      } else {
        // Create new user
        const username = await this.generateUniqueUsername(payload.name);
        
        user = await User.create({
          email: payload.email!,
          username,
          displayName: payload.name,
          avatarUrl: payload.picture,
          isVerified: payload.email_verified,
        });

        await UserOAuth.create({
          userId: user.id,
          provider: 'google',
          providerUserId: payload.sub,
        });

        isNew = true;
      }
    }

    const tokens = await this.generateTokens(user);
    return { user, tokens, isNew };
  }

  async refreshToken(refreshToken: string): Promise<TokenPair> {
    try {
      const decoded = jwt.verify(refreshToken, config.jwt.refreshSecret) as {
        userId: string;
        tokenId: string;
      };

      // Check if refresh token is blacklisted
      const blacklisted = await this.redis.get(`blacklist:${decoded.tokenId}`);
      if (blacklisted) {
        throw new Error('Token revoked');
      }

      const user = await User.findByPk(decoded.userId);
      if (!user) {
        throw new Error('User not found');
      }

      // Rotate refresh token (invalidate old one)
      await this.redis.setex(
        `blacklist:${decoded.tokenId}`,
        config.jwt.refreshExpiry,
        '1'
      );

      return this.generateTokens(user);
    } catch (error) {
      throw new Error('Invalid refresh token');
    }
  }

  async logout(accessToken: string, refreshTokenId?: string): Promise<void> {
    try {
      const decoded = jwt.decode(accessToken) as { exp: number };
      const ttl = decoded.exp - Math.floor(Date.now() / 1000);
      
      if (ttl > 0) {
        await this.redis.setex(
          `blacklist:${accessToken}`,
          ttl,
          '1'
        );
      }

      if (refreshTokenId) {
        await this.redis.setex(
          `blacklist:${refreshTokenId}`,
          config.jwt.refreshExpiry,
          '1'
        );
      }
    } catch (error) {
      logger.error('Logout error:', error);
    }
  }

  async requestPasswordReset(email: string): Promise<void> {
    const user = await User.findOne({ where: { email } });
    if (!user) {
      // Don't reveal that user doesn't exist
      return;
    }

    const resetToken = crypto.randomBytes(32).toString('hex');
    const resetTokenHash = crypto
      .createHash('sha256')
      .update(resetToken)
      .digest('hex');

    const expiresAt = new Date(Date.now() + 3600000); // 1 hour

    await user.update({
      passwordResetToken: resetTokenHash,
      passwordResetExpires: expiresAt,
    });

    const resetUrl = `${config.app.url}/reset-password?token=${resetToken}`;
    
    await sendEmail({
      to: user.email,
      subject: 'Password Reset Request',
      template: 'password-reset',
      data: { resetUrl, username: user.username },
    });
  }

  async resetPassword(token: string, newPassword: string): Promise<void> {
    const resetTokenHash = crypto
      .createHash('sha256')
      .update(token)
      .digest('hex');

    const user = await User.findOne({
      where: {
        passwordResetToken: resetTokenHash,
        passwordResetExpires: { [Op.gt]: new Date() },
      },
    });

    if (!user) {
      throw new Error('Invalid or expired reset token');
    }

    const salt = await bcrypt.genSalt(12);
    const passwordHash = await bcrypt.hash(newPassword, salt);

    await user.update({
      passwordHash,
      passwordResetToken: null,
      passwordResetExpires: null,
    });
  }

  async setupTwoFactor(userId: string): Promise<{ secret: string; qrCode: string }> {
    const secret = speakeasy.generateSecret({
      name: `CENT:${userId}`,
    });

    const qrCode = await QRCode.toDataURL(secret.otpauth_url!);

    // Store secret temporarily (user needs to verify first)
    await this.redis.setex(
      `2fa_temp:${userId}`,
      600, // 10 minutes
      secret.base32
    );

    return {
      secret: secret.base32,
      qrCode,
    };
  }

  async enableTwoFactor(userId: string, token: string): Promise<void> {
    const tempSecret = await this.redis.get(`2fa_temp:${userId}`);
    if (!tempSecret) {
      throw new Error('2FA setup session expired');
    }

    const verified = speakeasy.totp.verify({
      secret: tempSecret,
      encoding: 'base32',
      token,
      window: 1,
    });

    if (!verified) {
      throw new Error('Invalid verification code');
    }

    await User.update(
      { twoFactorSecret: tempSecret, twoFactorEnabled: true },
      { where: { id: userId } }
    );

    await this.redis.del(`2fa_temp:${userId}`);
  }

  private async generateTokens(user: User): Promise<TokenPair> {
    const tokenId = crypto.randomBytes(16).toString('hex');
    const refreshTokenId = crypto.randomBytes(16).toString('hex');

    const accessToken = jwt.sign(
      {
        userId: user.id,
        email: user.email,
        username: user.username,
        isPremium: user.isPremium,
        tokenId,
      },
      config.jwt.secret,
      {
        expiresIn: config.jwt.accessExpiry,
        issuer: 'cent-backend',
        audience: 'cent-app',
      }
    );

    const refreshToken = jwt.sign(
      {
        userId: user.id,
        tokenId: refreshTokenId,
      },
      config.jwt.refreshSecret,
      {
        expiresIn: config.jwt.refreshExpiry,
        issuer: 'cent-backend',
        audience: 'cent-app',
      }
    );

    // Store refresh token in Redis
    await this.redis.setex(
      `refresh:${refreshTokenId}`,
      config.jwt.refreshExpiry,
      user.id
    );

    return {
      accessToken,
      refreshToken,
      tokenId,
      refreshTokenId,
    };
  }

  private generateTempToken(userId: string): string {
    return jwt.sign(
      { userId, type: '2fa_temp' },
      config.jwt.secret,
      { expiresIn: '5m' }
    );
  }

  private async generateUniqueUsername(base: string): Promise<string> {
    const baseUsername = base
      .toLowerCase()
      .replace(/[^a-z0-9]/g, '')
      .substring(0, 15);

    let username = baseUsername;
    let counter = 1;

    while (await User.findOne({ where: { username } })) {
      username = `${baseUsername}${counter}`;
      counter++;
    }

    return username;
  }
      }
