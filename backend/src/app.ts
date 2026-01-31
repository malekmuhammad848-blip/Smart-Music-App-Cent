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

// Database Schema
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

// 1. Get all saved songs for the App
app.get('/api/songs/all', async (req: Request, res: Response) => {
  const songs = await Song.find();
  res.json(songs);
});

// 2. Search YouTube
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

// 3. Save song to Database
app.post('/api/songs/add', async (req: Request, res: Response) => {
  try {
    const newSong = new Song(req.body);
    await newSong.save();
    res.json({ message: "Song added successfully" });
  } catch (error) { res.status(500).json({ error: "Save failed" }); }
});

app.get('/', (req: Request, res: Response) => { res.status(200).json({ status: "Ready" }); });

const PORT = process.env.PORT || 10000;
app.listen(PORT, () => { console.log(`Server running on port ${PORT}`); });
