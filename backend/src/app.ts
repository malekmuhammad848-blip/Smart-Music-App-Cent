// backend/src/app.ts - Main Application Entry Point
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import rateLimit from 'express-rate-limit';
import { ApolloServer } from '@apollo/server';
import { expressMiddleware } from '@apollo/server/express4';
import { ApolloServerPluginDrainHttpServer } from '@apollo/server/plugin/drainHttpServer';
import { WebSocketServer } from 'ws';
import { useServer } from 'graphql-ws/lib/use/ws';
import http from 'http';
import { Redis } from 'ioredis';
import { createClient } from 'redis';
import { config } from './config';
import { connectDB } from './database';
import { typeDefs, resolvers } from './graphql/schema';
import { authenticate, authorize } from './middleware/auth';
import { errorHandler } from './middleware/error';
import { logger } from './utils/logger';
import { metricsMiddleware } from './middleware/metrics';

class CENTApplication {
  private app: express.Application;
  private httpServer: http.Server;
  private redisClient: Redis;
  private apolloServer: ApolloServer;

  constructor() {
    this.app = express();
    this.httpServer = http.createServer(this.app);
    this.redisClient = new Redis(config.redis.url);
    this.setupMiddleware();
    this.setupDatabase();
    this.setupApollo();
    this.setupRoutes();
    this.setupErrorHandling();
  }

  private setupMiddleware(): void {
    // Security middleware
    this.app.use(helmet({
      contentSecurityPolicy: {
        directives: {
          defaultSrc: ["'self'"],
          styleSrc: ["'self'", "'unsafe-inline'"],
          scriptSrc: ["'self'", "'unsafe-inline'"],
          imgSrc: ["'self'", "data:", "https:"],
          connectSrc: ["'self'", "ws:", "wss:"],
        },
      },
    }));

    // Rate limiting
    const limiter = rateLimit({
      windowMs: 15 * 60 * 1000, // 15 minutes
      max: 100, // Limit each IP to 100 requests per windowMs
      standardHeaders: true,
      legacyHeaders: false,
    });

    this.app.use('/api/', limiter);
    this.app.use(cors(config.cors));
    this.app.use(compression());
    this.app.use(express.json({ limit: '10mb' }));
    this.app.use(express.urlencoded({ extended: true }));
    this.app.use(metricsMiddleware);
  }

  private async setupDatabase(): Promise<void> {
    await connectDB();
    logger.info('Database connected successfully');
  }

  private async setupApollo(): Promise<void> {
    // Create WebSocket server for subscriptions
    const wsServer = new WebSocketServer({
      server: this.httpServer,
      path: '/graphql',
    });

    const serverCleanup = useServer(
      {
        schema,
        onConnect: async (ctx) => {
          const token = ctx.connectionParams?.authorization;
          if (!token) throw new Error('Missing auth token');
          const user = await verifyToken(token);
          return { user };
        },
      },
      wsServer
    );

    this.apolloServer = new ApolloServer({
      typeDefs,
      resolvers,
      plugins: [
        ApolloServerPluginDrainHttpServer({ httpServer: this.httpServer }),
        {
          async serverWillStart() {
            return {
              async drainServer() {
                await serverCleanup.dispose();
              },
            };
          },
        },
      ],
      formatError: (error) => {
        logger.error('GraphQL Error:', error);
        return {
          message: error.message,
          locations: error.locations,
          path: error.path,
          extensions: {
            code: error.extensions?.code || 'INTERNAL_SERVER_ERROR',
            timestamp: new Date().toISOString(),
          },
        };
      },
      context: async ({ req }) => {
        const token = req.headers.authorization || '';
        let user = null;
        
        if (token) {
          try {
            user = await authenticate(token);
          } catch (error) {
            // Token verification failed, proceed without user
          }
        }
        
        return {
          user,
          redis: this.redisClient,
          dataSources: {
            musicAPI: new MusicAPI(),
            userAPI: new UserAPI(),
          },
        };
      },
    });

    await this.apolloServer.start();
    
    this.app.use(
      '/graphql',
      expressMiddleware(this.apolloServer, {
        context: async ({ req }) => ({ req }),
      })
    );
  }

  private setupRoutes(): void {
    // Health check
    this.app.get('/health', (req, res) => {
      res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        services: {
          database: 'connected',
          redis: this.redisClient.status === 'ready' ? 'connected' : 'disconnected',
        },
      });
    });

    // API routes
    this.app.use('/api/v1/auth', require('./routes/auth').default);
    this.app.use('/api/v1/music', authenticate, require('./routes/music').default);
    this.app.use('/api/v1/stream', authenticate, require('./routes/stream').default);
    this.app.use('/api/v1/social', authenticate, require('./routes/social').default);
    this.app.use('/api/v1/admin', authenticate, authorize(['admin']), require('./routes/admin').default);
  }

  private setupErrorHandling(): void {
    this.app.use(errorHandler);
  }

  public async start(): Promise<void> {
    const PORT = config.port;
    
    this.httpServer.listen(PORT, () => {
      logger.info(`🚀 CENT Backend running on port ${PORT}`);
      logger.info(`📊 GraphQL Playground: http://localhost:${PORT}/graphql`);
      logger.info(`📈 Metrics: http://localhost:${PORT}/metrics`);
    });

    // Graceful shutdown
    const signals = ['SIGINT', 'SIGTERM'];
    signals.forEach(signal => {
      process.on(signal, async () => {
        logger.info(`Received ${signal}, shutting down gracefully...`);
        await this.apolloServer.stop();
        await this.redisClient.quit();
        this.httpServer.close(() => {
          logger.info('Server closed');
          process.exit(0);
        });
      });
    });
  }
}

export default CENTApplication;
