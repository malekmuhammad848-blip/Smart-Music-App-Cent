import express, { Request, Response } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import { createServer } from 'http';
import { Server } from 'socket.io';

const app = express();
const httpServer = createServer(app);
const io = new Server(httpServer, {
  cors: { origin: "*" }
});

app.use(helmet());
app.use(cors());
app.use(compression());
app.use(express.json());

app.get('/', (req: Request, res: Response) => {
  res.json({
    status: "CENT_MUSIC_LIVE",
    system: "PRO_BACKEND_V1",
    timestamp: new Date().toISOString(),
    endpoints: {
      stream_test: "/stream/test",
      health: "/health"
    }
  });
});

app.get('/health', (req: Request, res: Response) => {
  res.status(200).send('OK');
});

app.get('/stream/test', (req: Request, res: Response) => {
  const demoTrack = "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3";
  res.redirect(demoTrack);
});

const PORT = process.env.PORT || 10000;

httpServer.listen(PORT, () => {
  console.log(`PRO_SERVER_ACTIVE_PORT_${PORT}`);
});
