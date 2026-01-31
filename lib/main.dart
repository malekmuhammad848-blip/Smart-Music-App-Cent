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
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
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
  List<exp.Video> trendingSongs = [];
  List<Map<String, String>> recentSongs = [];
  List<Map<String, String>> favoriteSongs = [];
  
  bool isSearching = false;
  bool showFullPlayer = false;
  bool isRepeat = false;
  
  String? currentTitle, currentArtist, currentCover, currentId;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: '',
      flags: const YoutubePlayerFlags(autoPlay: false, hideControls: true),
    )..addListener(_playerListener);

    _rotationController = AnimationController(vsync: this, duration: const Duration(seconds: 15));
    _initData();
  }

  void _initData() async {
    await loadRecentAndFavs();
    await fetchTrending();
  }

  void _playerListener() {
    if (mounted) {
      setState(() {
        if (_controller.value.isPlaying) {
          _rotationController.repeat();
        } else {
          _rotationController.stop();
        }
      });
    }
  }

  Future<void> fetchTrending() async {
    try {
      var playlist = await yt.playlists.getVideos('PLFgquLnL59alW3ElYiS2t6gBnL8I9Jp7p');
      setState(() => trendingSongs = playlist.take(10).toList());
    } catch (_) {}
  }

  Future<void> loadRecentAndFavs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      recentSongs = (prefs.getStringList('recent') ?? []).map((e) => Map<String, String>.from(json.decode(e))).toList();
      favoriteSongs = (prefs.getStringList('favs') ?? []).map((e) => Map<String, String>.from(json.decode(e))).toList();
    });
  }

  void playSong(String id, String title, String artist, String cover) async {
    setState(() {
      currentId = id; currentTitle = title; currentArtist = artist; currentCover = cover;
      showFullPlayer = true;
    });
    _controller.load(id);
    _controller.play();
    
    // Save to recent
    final prefs = await SharedPreferences.getInstance();
    var list = prefs.getStringList('recent') ?? [];
    var newItem = json.encode({'id': id, 'title': title, 'artist': artist, 'cover': cover});
    list.removeWhere((e) => json.decode(e)['id'] == id);
    list.insert(0, newItem);
    if (list.length > 10) list.removeLast();
    await prefs.setStringList('recent', list);
    loadRecentAndFavs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox(height: 0, width: 0, child: YoutubePlayer(controller: _controller)),
          _buildMainUI(),
          if (showFullPlayer) _buildVinylPlayer(),
        ],
      ),
    );
  }

  Widget _buildMainUI() {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("CENT MUSIC", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37))),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _searchController,
                    onSubmitted: (v) {
                      setState(() => isSearching = true);
                      yt.search.search(v).then((res) => setState(() { searchResults = res.toList(); isSearching = false; }));
                    },
                    decoration: InputDecoration(
                      hintText: "Search for artists, songs...",
                      prefixIcon: const Icon(Icons.search, color: Color(0xFFD4AF37)),
                      filled: true, fillColor: const Color(0xFF1A1A1A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isSearching) const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))),
          if (searchResults.isNotEmpty) _buildSection("Search Results", searchResults)
          else ...[
            if (recentSongs.isNotEmpty) _buildRecentHorizontal(),
            _buildSection("Global Trending", trendingSongs),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildRecentHorizontal() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10), child: Text("Recently Played", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
          SizedBox(
            height: 170,
            child: ListView.builder(
              scrollDirection: Axis.horizontal, padding: const EdgeInsets.only(left: 20),
              itemCount: recentSongs.length,
              itemBuilder: (c, i) => GestureDetector(
                onTap: () => playSong(recentSongs[i]['id']!, recentSongs[i]['title']!, recentSongs[i]['artist']!, recentSongs[i]['cover']!),
                child: Container(
                  width: 130, margin: const EdgeInsets.only(right: 15),
                  child: Column(children: [
                    ClipRRect(borderRadius: BorderRadius.circular(15), child: CachedNetworkImage(imageUrl: recentSongs[i]['cover']!, height: 110, width: 130, fit: BoxFit.cover)),
                    const SizedBox(height: 8),
                    Text(recentSongs[i]['title']!, maxLines: 1, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                  ]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<exp.Video> list) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((c, i) {
          if (i == 0) return Padding(padding: const EdgeInsets.symmetric(vertical: 15), child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)));
          final v = list[i-1];
          return ListTile(
            contentPadding: EdgeInsets.zero,
            onTap: () => playSong(v.id.value, v.title, v.author, v.thumbnails.highResUrl),
            leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: CachedNetworkImage(imageUrl: v.thumbnails.lowResUrl, width: 50, height: 50, fit: BoxFit.cover)),
            title: Text(v.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(v.author, style: const TextStyle(color: Colors.grey)),
            trailing: const Icon(Icons.play_arrow_rounded, color: Color(0xFFD4AF37)),
          );
        }, childCount: list.length + 1),
      ),
    );
  }

  Widget _buildVinylPlayer() {
    return Container(
      color: const Color(0xFF0F0F0F),
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        children: [
          const SizedBox(height: 60),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            IconButton(icon: const Icon(Icons.keyboard_arrow_down, size: 35), onPressed: () => setState(() => showFullPlayer = false)),
            const Text("NOW PLAYING", style: TextStyle(letterSpacing: 2, fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37))),
            const Icon(Icons.more_vert),
          ]),
          const Spacer(),
          AnimatedBuilder(
            animation: _rotationController,
            builder: (c, child) => Transform.rotate(
              angle: _rotationController.value * 2 * math.pi,
              child: Container(
                width: 280, height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.2), blurRadius: 40, spreadRadius: 10)],
                  image: DecorationImage(image: NetworkImage(currentCover!), fit: BoxFit.cover),
                  border: Border.all(color: const Color(0xFF1A1A1A), width: 12),
                ),
                child: Center(child: Container(width: 50, height: 50, decoration: const BoxDecoration(color: Color(0xFF0F0F0F), shape: BoxShape.circle))),
              ),
            ),
          ),
          const Spacer(),
          Text(currentTitle!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), maxLines: 1),
          Text(currentArtist!, style: const TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 30),
          Slider(
            activeColor: const Color(0xFFD4AF37), inactiveColor: Colors.white10,
            value: _controller.value.position.inSeconds.toDouble(),
            max: _controller.metadata.duration.inSeconds.toDouble(),
            onChanged: (v) => _controller.seekTo(Duration(seconds: v.toInt())),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(icon: const Icon(Icons.shuffle, color: Colors.grey), onPressed: () {}),
            IconButton(icon: const Icon(Icons.skip_previous, size: 40), onPressed: () {}),
            IconButton(
              icon: Icon(_controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, size: 85, color: const Color(0xFFD4AF37)),
              onPressed: () => _controller.value.isPlaying ? _controller.pause() : _controller.play(),
            ),
            IconButton(icon: const Icon(Icons.skip_next, size: 40), onPressed: () {}),
            IconButton(icon: Icon(isRepeat ? Icons.repeat_one : Icons.repeat, color: isRepeat ? const Color(0xFFD4AF37) : Colors.grey), onPressed: () => setState(() => isRepeat = !isRepeat)),
          ]),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}
