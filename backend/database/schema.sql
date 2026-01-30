-- backend/database/schema.sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(50) UNIQUE NOT NULL,
    display_name VARCHAR(100),
    password_hash VARCHAR(255),
    avatar_url TEXT,
    banner_url TEXT,
    bio TEXT,
    is_verified BOOLEAN DEFAULT FALSE,
    is_artist BOOLEAN DEFAULT FALSE,
    is_premium BOOLEAN DEFAULT FALSE,
    premium_until TIMESTAMP,
    privacy_level VARCHAR(20) DEFAULT 'public',
    two_factor_enabled BOOLEAN DEFAULT FALSE,
    two_factor_secret VARCHAR(32),
    last_login TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- OAuth connections
CREATE TABLE user_oauth (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    provider VARCHAR(20) NOT NULL,
    provider_user_id VARCHAR(255) NOT NULL,
    access_token TEXT,
    refresh_token TEXT,
    expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(provider, provider_user_id)
);

-- Artists
CREATE TABLE artists (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    name VARCHAR(255) NOT NULL,
    normalized_name VARCHAR(255) NOT NULL,
    bio TEXT,
    avatar_url TEXT,
    banner_url TEXT,
    verified BOOLEAN DEFAULT FALSE,
    monthly_listeners INT DEFAULT 0,
    followers_count INT DEFAULT 0,
    labels JSONB,
    social_links JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Albums
CREATE TABLE albums (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    normalized_title VARCHAR(255) NOT NULL,
    artist_id UUID REFERENCES artists(id) ON DELETE CASCADE,
    cover_url TEXT,
    release_date DATE NOT NULL,
    album_type VARCHAR(20) NOT NULL, -- 'album', 'ep', 'single', 'compilation'
    genre VARCHAR(100),
    label VARCHAR(255),
    upc VARCHAR(20),
    duration_ms BIGINT DEFAULT 0,
    track_count INT DEFAULT 0,
    popularity INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Tracks
CREATE TABLE tracks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    normalized_title VARCHAR(255) NOT NULL,
    album_id UUID REFERENCES albums(id) ON DELETE CASCADE,
    duration_ms INT NOT NULL,
    track_number INT,
    disc_number INT DEFAULT 1,
    explicit BOOLEAN DEFAULT FALSE,
    isrc VARCHAR(15),
    audio_url TEXT NOT NULL,
    preview_url TEXT,
    waveform_data JSONB,
    bpm SMALLINT,
    key VARCHAR(5),
    mode VARCHAR(10),
    danceability DECIMAL(3,2),
    energy DECIMAL(3,2),
    valence DECIMAL(3,2),
    acousticness DECIMAL(3,2),
    instrumentalness DECIMAL(3,2),
    liveness DECIMAL(3,2),
    speechiness DECIMAL(3,2),
    popularity INT DEFAULT 0,
    play_count BIGINT DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Track-Artist relationship (for multiple artists)
CREATE TABLE track_artists (
    track_id UUID REFERENCES tracks(id) ON DELETE CASCADE,
    artist_id UUID REFERENCES artists(id) ON DELETE CASCADE,
    PRIMARY KEY (track_id, artist_id)
);

-- Playlists
CREATE TABLE playlists (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    cover_url TEXT,
    is_public BOOLEAN DEFAULT TRUE,
    is_collaborative BOOLEAN DEFAULT FALSE,
    rules JSONB, -- For smart playlists
    duration_ms BIGINT DEFAULT 0,
    track_count INT DEFAULT 0,
    followers_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Playlist tracks
CREATE TABLE playlist_tracks (
    playlist_id UUID REFERENCES playlists(id) ON DELETE CASCADE,
    track_id UUID REFERENCES tracks(id) ON DELETE CASCADE,
    added_by UUID REFERENCES users(id) ON DELETE SET NULL,
    added_at TIMESTAMP DEFAULT NOW(),
    position INT,
    PRIMARY KEY (playlist_id, track_id)
);

-- User library
CREATE TABLE user_library (
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    track_id UUID REFERENCES tracks(id) ON DELETE CASCADE,
    added_at TIMESTAMP DEFAULT NOW(),
    play_count INT DEFAULT 0,
    last_played TIMESTAMP,
    PRIMARY KEY (user_id, track_id)
);

-- Following system
CREATE TABLE follows (
    follower_id UUID REFERENCES users(id) ON DELETE CASCADE,
    following_id UUID REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (follower_id, following_id)
);

CREATE TABLE artist_follows (
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    artist_id UUID REFERENCES artists(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (user_id, artist_id)
);

-- Listening history
CREATE TABLE listening_history (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    track_id UUID REFERENCES tracks(id) ON DELETE CASCADE,
    played_at TIMESTAMP DEFAULT NOW(),
    progress_ms INT,
    completed BOOLEAN DEFAULT FALSE,
    device_id VARCHAR(100),
    context JSONB -- {type: 'playlist', id: '...'}
);

-- Create indexes for performance
CREATE INDEX idx_tracks_popularity ON tracks(popularity DESC);
CREATE INDEX idx_tracks_created_at ON tracks(created_at DESC);
CREATE INDEX idx_listening_history_user_played ON listening_history(user_id, played_at DESC);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_artists_normalized_name ON artists USING gin(normalized_name gin_trgm_ops);
CREATE INDEX idx_tracks_normalized_title ON tracks USING gin(normalized_title gin_trgm_ops);

-- Create materialized view for recommendations
CREATE MATERIALIZED VIEW user_recommendations AS
SELECT DISTINCT ON (uh.user_id, t.id)
    uh.user_id,
    t.id as track_id,
    t.title,
    t.popularity,
    COUNT(*) as affinity_score
FROM listening_history uh
JOIN tracks t ON t.album_id IN (
    SELECT album_id 
    FROM listening_history 
    WHERE user_id = uh.user_id 
    GROUP BY album_id 
    ORDER BY COUNT(*) DESC 
    LIMIT 10
)
WHERE NOT EXISTS (
    SELECT 1 FROM user_library ul 
    WHERE ul.user_id = uh.user_id AND ul.track_id = t.id
)
GROUP BY uh.user_id, t.id, t.title, t.popularity
ORDER BY uh.user_id, affinity_score DESC, t.popularity DESC;

REFRESH MATERIALIZED VIEW user_recommendations;
