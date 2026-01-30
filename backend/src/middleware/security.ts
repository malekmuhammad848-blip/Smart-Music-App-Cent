// backend/src/middleware/security.ts
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import { Request, Response, NextFunction } from 'express';
import { config } from '../config';
import { logger } from '../utils/logger';

export const securityHeaders = helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'", "https://fonts.googleapis.com"],
      fontSrc: ["'self'", "https://fonts.gstatic.com"],
      imgSrc: ["'self'", "data:", "https:", "blob:"],
      scriptSrc: ["'self'", "'unsafe-inline'", "'unsafe-eval'"],
      connectSrc: [
        "'self'",
        "ws:",
        "wss:",
        config.app.url,
        config.aws.cloudfrontUrl,
      ],
      frameSrc: ["'self'"],
      objectSrc: ["'none'"],
      mediaSrc: ["'self'", config.aws.cloudfrontUrl],
      workerSrc: ["'self'", "blob:"],
      childSrc: ["'self'", "blob:"],
      formAction: ["'self'"],
      baseUri: ["'self'"],
      frameAncestors: ["'none'"],
    },
  },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true,
  },
  frameguard: { action: 'deny' },
  noSniff: true,
  referrerPolicy: { policy: 'strict-origin-when-cross-origin' },
});

export const rateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.',
  standardHeaders: true,
  legacyHeaders: false,
  skipSuccessfulRequests: false,
  keyGenerator: (req) => {
    return req.ip || req.headers['x-forwarded-for'] || 'unknown';
  },
  handler: (req, res) => {
    logger.warn(`Rate limit exceeded for IP: ${req.ip}`);
    res.status(429).json({
      error: 'Rate limit exceeded',
      retryAfter: req.rateLimit.resetTime,
    });
  },
});

export const apiKeyAuth = (req: Request, res: Response, next: NextFunction) => {
  const apiKey = req.headers['x-api-key'] || req.query.apiKey;
  
  if (!apiKey) {
    return res.status(401).json({ error: 'API key required' });
  }
  
  if (apiKey !== config.api.key) {
    logger.warn(`Invalid API key attempt from IP: ${req.ip}`);
    return res.status(403).json({ error: 'Invalid API key' });
  }
  
  next();
};

export const corsMiddleware = (req: Request, res: Response, next: NextFunction) => {
  const allowedOrigins = [
    config.app.url,
    'https://cent.com',
    'https://www.cent.com',
    'capacitor://localhost',
    'ionic://localhost',
    'http://localhost',
    'http://localhost:8080',
    'http://localhost:3000',
  ];
  
  const origin = req.headers.origin;
  
  if (origin && allowedOrigins.includes(origin)) {
    res.setHeader('Access-Control-Allow-Origin', origin);
    res.setHeader('Access-Control-Allow-Credentials', 'true');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.setHeader(
      'Access-Control-Allow-Headers',
      'Origin, X-Requested-With, Content-Type, Accept, Authorization, X-API-Key'
    );
    res.setHeader('Access-Control-Expose-Headers', 'Content-Length, X-Total-Count');
    res.setHeader('Access-Control-Max-Age', '86400'); // 24 hours
  }
  
  if (req.method === 'OPTIONS') {
    return res.sendStatus(200);
  }
  
  next();
};

export const sqlInjectionProtection = (req: Request, res: Response, next: NextFunction) => {
  const sqlKeywords = [
    'SELECT', 'INSERT', 'UPDATE', 'DELETE', 'DROP', 'UNION', 'OR', 'AND',
    'WHERE', 'FROM', 'TABLE', 'DATABASE', 'ALTER', 'CREATE', 'EXEC',
  ];
  
  const checkObject = (obj: any): boolean => {
    for (const key in obj) {
      const value = obj[key];
      
      if (typeof value === 'string') {
        const upperValue = value.toUpperCase();
        for (const keyword of sqlKeywords) {
          if (upperValue.includes(keyword) && /[\s\(\)]/.test(upperValue)) {
            return false;
          }
        }
      } else if (typeof value === 'object' && value !== null) {
        if (!checkObject(value)) {
          return false;
        }
      }
    }
    return true;
  };
  
  if (!checkObject(req.body) || !checkObject(req.query) || !checkObject(req.params)) {
    logger.warn(`Possible SQL injection attempt from IP: ${req.ip}`);
    return res.status(400).json({ error: 'Invalid request' });
  }
  
  next();
};

export const xssProtection = (req: Request, res: Response, next: NextFunction) => {
  const xssPatterns = [
    /<script\b[^>]*>/i,
    /javascript:/i,
    /on\w+\s*=/i,
    /eval\(/i,
    /alert\(/i,
    /document\./i,
    /window\./i,
  ];
  
  const sanitize = (input: string): string => {
    return input
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#x27;')
      .replace(/\//g, '&#x2F;');
  };
  
  const checkAndSanitize = (obj: any): any => {
    const result: any = Array.isArray(obj) ? [] : {};
    
    for (const key in obj) {
      const value = obj[key];
      
      if (typeof value === 'string') {
        // Check for XSS patterns
        for (const pattern of xssPatterns) {
          if (pattern.test(value)) {
            logger.warn(`Possible XSS attempt from IP: ${req.ip}`);
            throw new Error('Potential XSS attack detected');
          }
        }
        
        // Sanitize string
        result[key] = sanitize(value);
      } else if (typeof value === 'object' && value !== null) {
        result[key] = checkAndSanitize(value);
      } else {
        result[key] = value;
      }
    }
    
    return result;
  };
  
  try {
    req.body = checkAndSanitize(req.body);
    req.query = checkAndSanitize(req.query);
    next();
  } catch (error) {
    return res.status(400).json({ error: 'Invalid input detected' });
  }
};

export const requestLogging = (req: Request, res: Response, next: NextFunction) => {
  const start = Date.now();
  const requestId = crypto.randomUUID();
  
  // Add request ID to request and response
  req.requestId = requestId;
  res.setHeader('X-Request-ID', requestId);
  
  // Log request
  logger.info({
    requestId,
    method: req.method,
    url: req.url,
    ip: req.ip,
    userAgent: req.headers['user-agent'],
    timestamp: new Date().toISOString(),
  });
  
  // Capture response
  const originalSend = res.send;
  res.send = function(body) {
    const duration = Date.now() - start;
    
    logger.info({
      requestId,
      method: req.method,
      url: req.url,
      statusCode: res.statusCode,
      duration,
      timestamp: new Date().toISOString(),
    });
    
    // Log errors
    if (res.statusCode >= 400) {
      logger.error({
        requestId,
        statusCode: res.statusCode,
        error: body,
        timestamp: new Date().toISOString(),
      });
    }
    
    return originalSend.call(this, body);
  };
  
  next();
};

export const dataSanitization = (req: Request, res: Response, next: NextFunction) => {
  // Remove sensitive data from logs
  const sensitiveFields = ['password', 'token', 'secret', 'creditCard', 'ssn'];
  
  const sanitize = (obj: any): any => {
    if (!obj || typeof obj !== 'object') return obj;
    
    const sanitized = Array.isArray(obj) ? [] : {};
    
    for (const key in obj) {
      if (sensitiveFields.some(field => key.toLowerCase().includes(field))) {
        sanitized[key] = '[REDACTED]';
      } else if (typeof obj[key] === 'object' && obj[key] !== null) {
        sanitized[key] = sanitize(obj[key]);
      } else {
        sanitized[key] = obj[key];
      }
    }
    
    return sanitized;
  };
  
  req.sanitizedBody = sanitize(req.body);
  req.sanitizedQuery = sanitize(req.query);
  
  next();
};
