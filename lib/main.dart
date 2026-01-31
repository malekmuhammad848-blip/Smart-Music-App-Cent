import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as exp;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math' as math;

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

class _MainMusicScreenState extends State<MainMusicScreen> with SingleTickerProviderStateMixin {
  late YoutubePlayerController _controller;
  final exp.YoutubeExplode yt = exp.YoutubeExplode();
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _rotationController;
  
  List<exp.Video> searchResults = [];
  List<Map<String, String>> favoriteSongs = [];
  bool isSearching = false;
  bool isPlayerReady = false;
  bool isRepeat = false;
  
  String? currentTitle, currentArtist, currentCover, currentId;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: '',
      flags: const YoutubePlayerFlags(autoPlay: false, hideControls: true),
    )..addListener(_onPlayerStateChange);

    _rotationController = AnimationController(vsync: this, duration: const Duration(seconds: 10));
    loadFavorites();
  }

  void _onPlayerStateChange() {
    if (mounted) {
      setState(() {
        if (_controller.value.isPlaying) {
          _rotationController.repeat();
        } else {
          _rotationController.stop();
        }
        
        if (_controller.value.playerState == PlayerState.ended && isRepeat) {
          _controller.play();
        }
      });
    }
  }

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favs = prefs.getStringList('fav_songs') ?? [];
    setState(() {
      favoriteSongs = favs.map((item) => Map<String, String>.from(json.decode(item))).toList();
    });
  }

  Future<void> toggleFavorite() async {
    if (currentId == null) return;
    final prefs = await SharedPreferences.getInstance();
    List<String> favs = prefs.getStringList('fav_songs') ?? [];
    
    bool exists = favs.any((item) => json.decode(item)['id'] == currentId);
    if (exists) {
      favs.removeWhere((item) => json.decode(item)['id'] == currentId);
    } else {
      favs.add(json.encode({'id': currentId, 'title': currentTitle, 'artist': currentArtist, 'cover': currentCover}));
    }
    await prefs.setStringList('fav_songs', favs);
    loadFavorites();
  }

  Future<void> searchYouTube(String query) async {
    setState(() => isSearching = true);
    var search = await yt.search.search(query);
    setState(() {
      searchResults = search.toList();
      isSearching = false;
    });
  }

  void playMusic(String id, String title, String artist, String cover) {
    setState(() {
      currentId = id; currentTitle = title; currentArtist = artist; currentCover = cover;
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
        backgroundColor: Colors.transparent, elevation: 0,
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
                    hintText: "Search for music...",
                    prefixIcon: const Icon(Icons.search, color: Color(0xFFD4AF37)),
                    filled: true, fillColor: const Color(0xFF1A1A1A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
                  onSubmitted: (value) => searchYouTube(value),
                ),
              ),
              Expanded(
                child: isSearching 
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
                : ListView.builder(
                    itemCount: searchResults.length,
                    itemBuilder: (context, index) {
                      final video = searchResults[index];
                      return ListTile(
                        onTap: () => playMusic(video.id.value, video.title, video.author, video.thumbnails.highResUrl),
                        leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(video.thumbnails.lowResUrl, width: 50, height: 50, fit: BoxFit.cover)),
                        title: Text(video.title, maxLines: 1),
                        subtitle: Text(video.author),
                        trailing: const Icon(Icons.play_circle_outline, color: Color(0xFFD4AF37)),
                      );
                    },
                  ),
              ),
            ],
          ),
          if (isPlayerReady) _buildProfessionalPlayer(),
        ],
      ),
    );
  }

  Widget _buildProfessionalPlayer() {
    return Container(
      color: const Color(0xFF0F0F0F),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 50),
          // القرص الدوار
          AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationController.value * 2 * math.pi,
                child: Container(
                  width: 250, height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 10),
                    image: DecorationImage(image: NetworkImage(currentCover ?? ''), fit: BoxFit.cover),
                    boxShadow: [BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.3), blurRadius: 20, spreadRadius: 5)],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 30),
          Text(currentTitle ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          Text(currentArtist ?? '', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          // شريط التقدم
          ProgressBar(controller: _controller),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(icon: Icon(isRepeat ? Icons.repeat_one : Icons.repeat, color: isRepeat ? const Color(0xFFD4AF37) : Colors.white), onPressed: () => setState(() => isRepeat = !isRepeat)),
              IconButton(icon: const Icon(Icons.skip_previous, size: 40), onPressed: () {}),
              IconButton(
                icon: Icon(_controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, size: 70, color: const Color(0xFFD4AF37)),
                onPressed: () => setState(() => _controller.value.isPlaying ? _controller.pause() : _controller.play()),
              ),
              IconButton(icon: const Icon(Icons.skip_next, size: 40), onPressed: () {}),
              IconButton(
                icon: Icon(favoriteSongs.any((s) => s['id'] == currentId) ? Icons.favorite : Icons.favorite_border, color: Colors.red),
                onPressed: toggleFavorite,
              ),
            ],
          ),
          TextButton(onPressed: () => setState(() => isPlayerReady = false), child: const Text("Close Player", style: TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }
}

class ProgressBar extends StatelessWidget {
  final YoutubePlayerController controller;
  const ProgressBar({super.key, required this.controller});
  @override
  Widget build(BuildContext context) {
    return Slider(
      activeColor: const Color(0xFFD4AF37),
      inactiveColor: Colors.grey,
      value: controller.value.position.inSeconds.toDouble(),
      max: controller.metadata.duration.inSeconds.toDouble(),
      onChanged: (value) {
        controller.seekTo(Duration(seconds: value.toInt()));
      },
    );
  }
}
