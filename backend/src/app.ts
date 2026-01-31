import express, { Application, Request, Response } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import mongoose from 'mongoose';
import axios from 'axios';
import path from 'path';

dotenv.config();
const app: Application = express();
app.use(cors());
app.use(express.json());

// Serve static files (to open admin.html)
app.use(express.static(path.join(__dirname, '../')));

const MONGO_URI = process.env.MONGO_URI || "";
const YOUTUBE_API_KEY = process.env.YOUTUBE_API_KEY || "";

const songSchema = new mongoose.Schema({
  title: String,
  artist: String,
  youtubeId: String,
  cover: String
});
const Song = mongoose.model('Song', songSchema);

if (MONGO_URI !== "") {
  mongoose.connect(MONGO_URI)
    .then(() => console.log("Database Connected"))
    .catch((err) => console.error("Database Error:", err));
}

app.get('/api/songs/all', async (req: Request, res: Response) => {
  const songs = await Song.find();
  res.json(songs);
});

app.get('/api/search', async (req: Request, res: Response) => {
  const query = req.query.query;
  try {
    const response = await axios.get(`https://www.googleapis.com/youtube/v3/search`, {
      params: { part: 'snippet', maxResults: 10, q: query, type: 'video', key: YOUTUBE_API_KEY }
    });
    const results = response.data.items.map((item: any) => ({
      title: item.snippet.title,
      youtubeId: item.id.videoId,
      cover: item.snippet.thumbnails.high.url,
      artist: item.snippet.channelTitle
    }));
    res.json(results);
  } catch (error) { res.status(500).json({ error: "Search failed" }); }
});

app.post('/api/songs/add', async (req: Request, res: Response) => {
  try {
    const newSong = new Song(req.body);
    await newSong.save();
    res.json({ message: "Song added successfully" });
  } catch (error) { res.status(500).json({ error: "Save failed" }); }
});

// Open Admin Page on home URL
app.get('/', (req: Request, res: Response) => {
  res.sendFile(path.join(__dirname, '../admin.html'));
});

const PORT = process.env.PORT || 10000;
app.listen(PORT, () => { console.log(`Server running on port ${PORT}`); });
