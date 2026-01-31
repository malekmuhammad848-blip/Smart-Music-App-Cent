import dotenv from 'dotenv';

dotenv.config();

export const config = {
  port: process.env.PORT || 3000,
  database: {
    url: process.env.DATABASE_URL || 'postgresql://cent:cent123@localhost:5432/cent'
  },
  redis: {
    url: process.env.REDIS_URL || 'redis://localhost:6379'
  },
  jwt: {
    secret: process.env.JWT_SECRET || 'your-secret-key',
    expiresIn: '7d'
  },
  cors: {
    origins: process.env.CORS_ORIGINS?.split(',') || ['http://localhost:8080']
  }
};
