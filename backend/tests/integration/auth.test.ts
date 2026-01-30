// backend/tests/integration/auth.test.ts
import request from 'supertest';
import { createServer } from '../../src/app';
import { prisma } from '../../src/database';
import { redis } from '../../src/redis';

describe('Authentication API', () => {
  let app: Express.Application;
  let testUser: any;

  beforeAll(async () => {
    app = await createServer();
    await prisma.$connect();
    await redis.connect();
  });

  afterAll(async () => {
    await prisma.$disconnect();
    await redis.quit();
  });

  beforeEach(async () => {
    // Clean up test data
    await prisma.user.deleteMany({});
    testUser = null;
  });

  describe('POST /api/v1/auth/register', () => {
    it('should register a new user successfully', async () => {
      const userData = {
        email: 'test@example.com',
        username: 'testuser',
        password: 'Password123!',
        displayName: 'Test User',
      };

      const response = await request(app)
        .post('/api/v1/auth/register')
        .send(userData)
        .expect(201);

      expect(response.body).toHaveProperty('user');
      expect(response.body).toHaveProperty('tokens');
      expect(response.body.user.email).toBe(userData.email);
      expect(response.body.user.username).toBe(userData.username);
      expect(response.body.user.passwordHash).toBeUndefined();

      // Verify user was created in database
      const dbUser = await prisma.user.findUnique({
        where: { email: userData.email },
      });
      expect(dbUser).toBeTruthy();
      expect(dbUser?.isVerified).toBe(false);
    });

    it('should fail with duplicate email', async () => {
      const userData = {
        email: 'duplicate@example.com',
        username: 'user1',
        password: 'Password123!',
      };

      // Create first user
      await request(app)
        .post('/api/v1/auth/register')
        .send(userData);

      // Try to create second user with same email
      const response = await request(app)
        .post('/api/v1/auth/register')
        .send({ ...userData, username: 'user2' })
        .expect(400);

      expect(response.body.error).toBe('Email already registered');
    });

    it('should fail with invalid password', async () => {
      const userData = {
        email: 'test@example.com',
        username: 'testuser',
        password: 'weak', // Too weak
      };

      const response = await request(app)
        .post('/api/v1/auth/register')
        .send(userData)
        .expect(400);

      expect(response.body.error).toContain('Password');
    });
  });

  describe('POST /api/v1/auth/login', () => {
    beforeEach(async () => {
      // Create test user
      testUser = await prisma.user.create({
        data: {
          email: 'login@example.com',
          username: 'loginuser',
          passwordHash: '$2a$12$K9qK8QlT9h9QlT9h9QlT9.', // Hashed 'Password123!'
          displayName: 'Login User',
        },
      });
    });

    it('should login successfully with correct credentials', async () => {
      const response = await request(app)
        .post('/api/v1/auth/login')
        .send({
          identifier: 'login@example.com',
          password: 'Password123!',
        })
        .expect(200);

      expect(response.body).toHaveProperty('tokens');
      expect(response.body.tokens).toHaveProperty('accessToken');
      expect(response.body.tokens).toHaveProperty('refreshToken');
      expect(response.body.user.email).toBe('login@example.com');
    });

    it('should login with username as identifier', async () => {
      const response = await request(app)
        .post('/api/v1/auth/login')
        .send({
          identifier: 'loginuser',
          password: 'Password123!',
        })
        .expect(200);

      expect(response.body.user.username).toBe('loginuser');
    });

    it('should fail with incorrect password', async () => {
      const response = await request(app)
        .post('/api/v1/auth/login')
        .send({
          identifier: 'login@example.com',
          password: 'WrongPassword!',
        })
        .expect(401);

      expect(response.body.error).toBe('Invalid credentials');
    });

    it('should require 2FA if enabled', async () => {
      // Enable 2FA for user
      await prisma.user.update({
        where: { id: testUser.id },
        data: {
          twoFactorEnabled: true,
          twoFactorSecret: 'JBSWY3DPEHPK3PXP',
        },
      });

      const response = await request(app)
        .post('/api/v1/auth/login')
        .send({
          identifier: 'login@example.com',
          password: 'Password123!',
        })
        .expect(200);

      expect(response.body.tokens).toHaveProperty('accessToken');
      expect(response.body.tokens.refreshToken).toBeNull();
      expect(response.body.requires2FA).toBe(true);
    });
  });

  describe('POST /api/v1/auth/refresh', () => {
    let refreshToken: string;

    beforeEach(async () => {
      // Create user and get refresh token
      const loginResponse = await request(app)
        .post('/api/v1/auth/login')
        .send({
          identifier: 'login@example.com',
          password: 'Password123!',
        });

      refreshToken = loginResponse.body.tokens.refreshToken;
    });

    it('should refresh access token successfully', async () => {
      const response = await request(app)
        .post('/api/v1/auth/refresh')
        .set('Cookie', [`refreshToken=${refreshToken}`])
        .expect(200);

      expect(response.body).toHaveProperty('accessToken');
      expect(response.body.accessToken).not.toBe(refreshToken);
    });

    it('should fail with invalid refresh token', async () => {
      const response = await request(app)
        .post('/api/v1/auth/refresh')
        .set('Cookie', ['refreshToken=invalid-token'])
        .expect(401);

      expect(response.body.error).toBe('Invalid refresh token');
    });

    it('should fail with blacklisted refresh token', async () => {
      // First refresh
      await request(app)
        .post('/api/v1/auth/refresh')
        .set('Cookie', [`refreshToken=${refreshToken}`]);

      // Try to use same refresh token again
      const response = await request(app)
        .post('/api/v1/auth/refresh')
        .set('Cookie', [`refreshToken=${refreshToken}`])
        .expect(401);

      expect(response.body.error).toBe('Token revoked');
    });
  });

  describe('POST /api/v1/auth/logout', () => {
    let accessToken: string;
    let refreshToken: string;

    beforeEach(async () => {
      const loginResponse = await request(app)
        .post('/api/v1/auth/login')
        .send({
          identifier: 'login@example.com',
          password: 'Password123!',
        });

      accessToken = loginResponse.body.tokens.accessToken;
      refreshToken = loginResponse.body.tokens.refreshToken;
    });

    it('should logout successfully', async () => {
      const response = await request(app)
        .post('/api/v1/auth/logout')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ refreshToken })
        .expect(200);

      expect(response.body.message).toBe('Logged out successfully');

      // Verify token is blacklisted
      const response2 = await request(app)
        .post('/api/v1/auth/refresh')
        .set('Cookie', [`refreshToken=${refreshToken}`])
        .expect(401);
    });

    it('should fail without authentication', async () => {
      const response = await request(app)
        .post('/api/v1/auth/logout')
        .expect(401);

      expect(response.body.error).toBe('Authentication required');
    });
  });
});

// Performance tests
describe('Authentication Performance', () => {
  it('should handle concurrent login requests', async () => {
    const concurrentRequests = 100;
    const requests = [];

    for (let i = 0; i < concurrentRequests; i++) {
      requests.push(
        request(app)
          .post('/api/v1/auth/login')
          .send({
            identifier: `user${i}@example.com`,
            password: 'Password123!',
          })
      );
    }

    const startTime = Date.now();
    const responses = await Promise.all(requests);
    const endTime = Date.now();

    // All requests should complete within 5 seconds
    expect(endTime - startTime).toBeLessThan(5000);

    // Count successful responses
    const successful = responses.filter(r => r.status === 200).length;
    expect(successful).toBe(concurrentRequests);
  });

  it('should maintain response time under load', async () => {
    const sampleSize = 1000;
    const responseTimes = [];

    for (let i = 0; i < sampleSize; i++) {
      const start = Date.now();
      await request(app)
        .get('/health')
        .expect(200);
      responseTimes.push(Date.now() - start);
    }

    const average = responseTimes.reduce((a, b) => a + b) / sampleSize;
    const p95 = responseTimes.sort((a, b) => a - b)[
      Math.floor(sampleSize * 0.95)
    ];

    expect(average).toBeLessThan(100); // Average < 100ms
    expect(p95).toBeLessThan(200); // 95th percentile < 200ms
  });
});
