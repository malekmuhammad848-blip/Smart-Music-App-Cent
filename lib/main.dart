import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as exp;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() => runApp(const CentMusicApp());

class CentMusicApp extends StatelessWidget {
  const CentMusicApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFFD4AF37),
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
      ),
      home: const MainMusicScreen(),
    );
  }
}

class MainMusicScreen extends StatefulWidget {
  const MainMusicScreen({super.key});
  @override
  State<MainMusicScreen> createState() => _MainMusicScreenState();
}

class _MainMusicScreenState extends State<MainMusicScreen> {
  late YoutubePlayerController _controller;
  final exp.YoutubeExplode yt = exp.YoutubeExplode();
  final TextEditingController _searchController = TextEditingController();
  
  List<exp.Video> searchResults = [];
  List<exp.Video> trendingSongs = [];
  List<Map<String, String>> recentSongs = [];
  
  bool isSearching = false;
  bool isPlayerReady = false;
  
  String? currentTitle;
  String? currentArtist;
  String? currentCover;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: '',
      flags: const YoutubePlayerFlags(autoPlay: false, hideControls: true),
    );
    loadTrending();
    loadRecentSongs();
  }

  // Load Trending Songs (Top Music)
  Future<void> loadTrending() async {
    try {
      var playlist = await yt.playlists.getVideos('PLFgquLnL59alW3ElYiS2t6gBnL8I9Jp7p'); // Global Top 50 Playlist
      setState(() {
        trendingSongs = playlist.take(10).toList();
      });
    } catch (e) {
      print("Error loading trending: $e");
    }
  }

  // Save song to Recent
  Future<void> addToRecent(exp.Video video) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> recentStrings = prefs.getStringList('recent_songs') ?? [];
    
    Map<String, String> newSong = {
      'id': video.id.value,
      'title': video.title,
      'artist': video.author,
      'cover': video.thumbnails.highResUrl,
    };

    recentStrings.removeWhere((item) => json.decode(item)['id'] == video.id.value);
    recentStrings.insert(0, json.encode(newSong));
    
    if (recentStrings.length > 10) recentStrings.removeLast();
    
    await prefs.setStringList('recent_songs', recentStrings);
    loadRecentSongs();
  }

  Future<void> loadRecentSongs() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> recentStrings = prefs.getStringList('recent_songs') ?? [];
    setState(() {
      recentSongs = recentStrings.map((item) => Map<String, String>.from(json.decode(item))).toList();
    });
  }

  Future<void> searchYouTube(String query) async {
    if (query.isEmpty) return;
    setState(() => isSearching = true);
    try {
      var search = await yt.search.search(query);
      setState(() {
        searchResults = search.toList();
        isSearching = false;
      });
    } catch (e) {
      setState(() => isSearching = false);
    }
  }

  void playMusic(String id, String title, String artist, String cover) {
    setState(() {
      currentTitle = title;
      currentArtist = artist;
      currentCover = cover;
      isPlayerReady = true;
    });
    _controller.load(id);
    _controller.play();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("CENT MUSIC", style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SizedBox(height: 0, width: 0, child: YoutubePlayer(controller: _controller)),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Search any song...",
                    prefixIcon: const Icon(Icons.search, color: Color(0xFFD4AF37)),
                    filled: true,
                    fillColor: const Color(0xFF1A1A1A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
                  onSubmitted: (value) => searchYouTube(value),
                ),
              ),
              Expanded(
                child: isSearching 
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (searchResults.isNotEmpty) ...[
                            const SectionHeader(title: "Search Results"),
                            buildVideoList(searchResults, true),
                          ] else ...[
                            if (recentSongs.isNotEmpty) ...[
                              const SectionHeader(title: "Recently Played"),
                              buildRecentList(),
                            ],
                            const SectionHeader(title: "Trending Now"),
                            buildVideoList(trendingSongs, false),
                          ],
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
              ),
            ],
          ),
          if (isPlayerReady) buildMiniPlayer(),
        ],
      ),
    );
  }

  Widget buildVideoList(List<exp.Video> videos, bool isSearch) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        return ListTile(
          onTap: () {
            playMusic(video.id.value, video.title, video.author, video.thumbnails.highResUrl);
            addToRecent(video);
          },
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(imageUrl: video.thumbnails.lowResUrl, width: 50, height: 50, fit: BoxFit.cover),
          ),
          title: Text(video.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(video.author, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          trailing: const Icon(Icons.play_circle_fill, color: Color(0xFFD4AF37)),
        );
      },
    );
  }

  Widget buildRecentList() {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: recentSongs.length,
        itemBuilder: (context, index) {
          final song = recentSongs[index];
          return GestureDetector(
            onTap: () => playMusic(song['id']!, song['title']!, song['artist']!, song['cover']!),
            child: Container(
              width: 120,
              margin: const EdgeInsets.only(right: 15),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: CachedNetworkImage(imageUrl: song['cover']!, height: 100, width: 120, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 5),
                  Text(song['title']!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Text(song['artist']!, maxLines: 1, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildMiniPlayer() {
    return Positioned(
      bottom: 15, left: 10, right: 10,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD4AF37), width: 0.5),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(imageUrl: currentCover ?? '', width: 50, height: 50, fit: BoxFit.cover),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(currentTitle ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(currentArtist ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            IconButton(
              icon: Icon(_controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, size: 40, color: const Color(0xFFD4AF37)),
              onPressed: () => setState(() => _controller.value.isPlaying ? _controller.pause() : _controller.play()),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37))),
    );
  }
}
