// backend/src/services/stream.service.ts
import { createReadStream, statSync } from 'fs';
import path from 'path';
import ffmpeg from 'fluent-ffmpeg';
import { Readable } from 'stream';
import { config } from '../config';
import { redis } from '../redis';
import { s3Client } from '../aws';
import { GetObjectCommand } from '@aws-sdk/client-s3';
import { logger } from '../utils/logger';

export class StreamService {
  private readonly SUPPORTED_FORMATS = ['mp3', 'flac', 'aac', 'opus'];
  private readonly BITRATES = {
    low: 64000,
    medium: 128000,
    high: 192000,
    very_high: 320000,
    lossless: 1411000, // FLAC ~1411 kbps
  };

  async streamTrack(
    trackId: string,
    userId: string,
    quality: string = 'high',
    startTime: number = 0
  ): Promise<{
    stream: Readable;
    contentType: string;
    contentLength?: number;
    bitrate: number;
    startByte?: number;
    endByte?: number;
  }> {
    // Check if user has access to track
    await this.validateAccess(trackId, userId);
    
    // Get track metadata
    const track = await this.getTrackMetadata(trackId);
    if (!track) {
      throw new Error('Track not found');
    }

    // Record play
    await this.recordPlay(trackId, userId);

    // Check cache first
    const cacheKey = `stream:${trackId}:${quality}`;
    const cachedStream = await redis.get(cacheKey);
    
    if (cachedStream && config.cache.enabled) {
      return this.serveCachedStream(cachedStream);
    }

    // Get audio file from S3
    const s3Key = `audio/${trackId}/${track.fileName}`;
    const command = new GetObjectCommand({
      Bucket: config.aws.bucket,
      Key: s3Key,
    });

    const s3Response = await s3Client.send(command);
    const s3Stream = s3Response.Body as Readable;

    // Transcode if needed
    if (quality !== 'lossless' && track.format !== 'mp3') {
      return this.transcodeStream(
        s3Stream,
        track,
        quality,
        startTime,
        cacheKey
      );
    }

    // Serve directly (for MP3 or lossless)
    return {
      stream: s3Stream,
      contentType: this.getContentType(track.format),
      contentLength: s3Response.ContentLength,
      bitrate: this.BITRATES[quality] || this.BITRATES.high,
    };
  }

  async generateHLSStream(trackId: string, userId: string): Promise<string> {
    // Validate access
    await this.validateAccess(trackId, userId);

    const track = await this.getTrackMetadata(trackId);
    if (!track) {
      throw new Error('Track not found');
    }

    const hlsKey = `hls:${trackId}:${Date.now()}`;
    const hlsDir = path.join(config.hls.outputDir, trackId);

    // Check if HLS already exists
    const existingHls = await redis.get(`hls_cache:${trackId}`);
    if (existingHls) {
      return existingHls;
    }

    // Generate HLS playlist
    const s3Key = `audio/${trackId}/${track.fileName}`;
    const s3Url = `https://${config.aws.bucket}.s3.amazonaws.com/${s3Key}`;

    const manifest = await this.createHLSManifest(
      s3Url,
      hlsDir,
      trackId
    );

    // Cache manifest
    await redis.setex(
      `hls_cache:${trackId}`,
      3600, // 1 hour
      manifest
    );

    return manifest;
  }

  async getWaveformData(trackId: string): Promise<number[]> {
    const cacheKey = `waveform:${trackId}`;
    const cached = await redis.get(cacheKey);
    
    if (cached) {
      return JSON.parse(cached);
    }

    const track = await this.getTrackMetadata(trackId);
    if (!track) {
      throw new Error('Track not found');
    }

    const waveform = await this.generateWaveform(track);
    
    // Cache for 24 hours
    await redis.setex(cacheKey, 86400, JSON.stringify(waveform));
    
    return waveform;
  }

  private async transcodeStream(
    sourceStream: Readable,
    track: TrackMetadata,
    quality: string,
    startTime: number,
    cacheKey: string
  ): Promise<StreamResponse> {
    return new Promise((resolve, reject) => {
      const bitrate = this.BITRATES[quality] || this.BITRATES.high;
      const chunks: Buffer[] = [];

      ffmpeg(sourceStream)
        .audioCodec('libmp3lame')
        .audioBitrate(bitrate / 1000)
        .format('mp3')
        .on('start', (cmd) => {
          logger.debug(`Transcoding command: ${cmd}`);
        })
        .on('error', (err) => {
          logger.error('Transcoding error:', err);
          reject(err);
        })
        .on('end', async () => {
          const buffer = Buffer.concat(chunks);
          
          // Cache the transcoded stream
          if (config.cache.enabled) {
            await redis.setex(cacheKey, 3600, buffer.toString('base64'));
          }

          const stream = new Readable();
          stream.push(buffer);
          stream.push(null);

          resolve({
            stream,
            contentType: 'audio/mpeg',
            contentLength: buffer.length,
            bitrate,
          });
        })
        .pipe()
        .on('data', (chunk) => {
          chunks.push(chunk);
        });
    });
  }

  private async createHLSManifest(
    inputUrl: string,
    outputDir: string,
    trackId: string
  ): Promise<string> {
    return new Promise((resolve, reject) => {
      const playlistPath = path.join(outputDir, 'playlist.m3u8');
      
      ffmpeg(inputUrl)
        .outputOptions([
          '-c:a aac',
          '-b:a 128k',
          '-f hls',
          '-hls_time 10',
          '-hls_playlist_type vod',
          '-hls_segment_filename', `${outputDir}/segment_%03d.ts`,
        ])
        .output(playlistPath)
        .on('end', () => {
          // Read and return manifest
          const manifest = `
#EXTM3U
#EXT-X-VERSION:3
#EXT-X-TARGETDURATION:10
#EXT-X-MEDIA-SEQUENCE:0
#EXT-X-PLAYLIST-TYPE:VOD
#EXTINF:10.0,
/stream/hls/${trackId}/segment_001.ts
#EXTINF:10.0,
/stream/hls/${trackId}/segment_002.ts
#EXTINF:8.5,
/stream/hls/${trackId}/segment_003.ts
#EXT-X-ENDLIST
          `.trim();
          
          resolve(manifest);
        })
        .on('error', reject)
        .run();
    });
  }

  private async generateWaveform(track: TrackMetadata): Promise<number[]> {
    return new Promise((resolve, reject) => {
      const points: number[] = [];
      
      ffmpeg(track.filePath)
        .audioFilters('aformat=channel_layouts=mono')
        .format('dat')
        .on('data', (chunk) => {
          // Parse raw audio data to generate waveform points
          // Simplified version - in production use proper audio analysis
          for (let i = 0; i < chunk.length; i += 4) {
            const sample = chunk.readFloatLE(i);
            points.push(Math.abs(sample));
          }
        })
        .on('end', () => {
          // Normalize and downsample
          const normalized = this.normalizeWaveform(points, 200);
          resolve(normalized);
        })
        .on('error', reject)
        .pipe();
    });
  }

  private normalizeWaveform(points: number[], targetPoints: number): number[] {
    const step = Math.floor(points.length / targetPoints);
    const normalized: number[] = [];

    for (let i = 0; i < targetPoints; i++) {
      const start = i * step;
      const end = start + step;
      const segment = points.slice(start, end);
      const avg = segment.reduce((a, b) => a + b, 0) / segment.length;
      normalized.push(avg);
    }

    // Normalize to 0-100 range
    const max = Math.max(...normalized);
    return normalized.map(p => (p / max) * 100);
  }

  private getContentType(format: string): string {
    const types: Record<string, string> = {
      mp3: 'audio/mpeg',
      flac: 'audio/flac',
      aac: 'audio/aac',
      opus: 'audio/opus',
      m4a: 'audio/mp4',
    };
    
    return types[format] || 'audio/mpeg';
  }

  private async validateAccess(trackId: string, userId: string): Promise<void> {
    // Check if user has premium access for high quality
    const user = await User.findByPk(userId);
    if (!user?.isPremium) {
      // Freemium users limited to medium quality
      if (quality !== 'low' && quality !== 'medium') {
        throw new Error('Premium required for this quality');
      }
    }

    // Check regional restrictions
    const trackRestrictions = await TrackRestriction.findOne({
      where: { trackId },
    });
    
    if (trackRestrictions) {
      // Implement geo-blocking logic
      const userCountry = await this.getUserCountry(userId);
      if (trackRestrictions.blockedCountries.includes(userCountry)) {
        throw new Error('Content not available in your region');
      }
    }
  }

  private async recordPlay(trackId: string, userId: string): Promise<void> {
    await ListeningHistory.create({
      userId,
      trackId,
      playedAt: new Date(),
      completed: false,
    });

    // Update track play count asynchronously
    setImmediate(async () => {
      await Track.increment('playCount', { where: { id: trackId } });
      
      // Update user's recently played
      await redis.lpush(`recent:${userId}`, trackId);
      await redis.ltrim(`recent:${userId}`, 0, 99);
    });
  }
  }
