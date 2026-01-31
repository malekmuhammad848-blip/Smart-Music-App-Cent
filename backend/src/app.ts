import express, { Application, Request, Response } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import mongoose from 'mongoose';
import axios from 'axios';

dotenv.config();

const app: Application = express();
app.use(cors());
app.use(express.json());

const MONGO_URI = process.env.MONGO_URI || "";
const YOUTUBE_API_KEY = process.env.YOUTUBE_API_KEY || "";

if (MONGO_URI !== "") {
  mongoose.connect(MONGO_URI)
    .then(() => console.log("Database Connected"))
    .catch((err) => console.error("Database Error:", err));
}

app.get('/api/search', async (req: Request, res: Response) => {
  const query = req.query.query;
  if (!query) {
    return res.status(400).json({ error: "Query is required" });
  }

  try {
    const response = await axios.get(`https://www.googleapis.com/youtube/v3/search`, {
      params: {
        part: 'snippet',
        maxResults: 10,
        q: query,
        type: 'video',
        key: YOUTUBE_API_KEY
      }
    });

    const results = response.data.items.map((item: any) => ({
      title: item.snippet.title,
      youtubeId: item.id.videoId,
      cover: item.snippet.thumbnails.high.url,
      artist: item.snippet.channelTitle
    }));

    res.json(results);
  } catch (error) {
    res.status(500).json({ error: "YouTube Search Failed" });
  }
});

app.get('/', (req: Request, res: Response) => {
  res.status(200).json({ status: "Online" });
});

const PORT = process.env.PORT || 10000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

export default app;
