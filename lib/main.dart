import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:just_audio/just_audio.dart';

void main() => runApp(const CentMusicElite());

class CentMusicElite extends StatelessWidget {
  const CentMusicElite({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFD4AF37),
        scaffoldBackgroundColor: const Color(0xFF050505),
      ),
      home: const MainScaffold(),
    );
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  final AudioPlayer _player = AudioPlayer();
  final YoutubeExplode _yt = YoutubeExplode();
  bool _isPlaying = false;
  String _currentTitle = "Select Music";
  String _currentAuthor = "CENT Artist";
  String _currentThumbnail = "https://picsum.photos/400";
  final Color gold = const Color(0xFFD4AF37);
  
  List<Video> _searchResults = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _player.playerStateStream.listen((state) {
      if (mounted) setState(() => _isPlaying = state.playing);
    });
  }

  Future<void> _searchSongs(String query) async {
    if (query.isEmpty) return;
    try {
      var search = await _yt.search.search(query);
      setState(() => _searchResults = search.toList());
    } catch (e) {
      debugPrint("Search error: $e");
    }
  }

  Future<void> _playVideo(String videoId, String title, String author, String thumb) async {
    setState(() {
      _currentTitle = title;
      _currentAuthor = author;
      _currentThumbnail = thumb;
    });

    try {
      var manifest = await _yt.videos.streamsClient.getManifest(videoId);
      var audioStream = manifest.audioOnly.withHighestBitrate();
      await _player.setUrl(audioStream.url.toString());
      _player.play();
    } catch (e) {
      setState(() => _currentTitle = "Stream Error");
    }
  }

  @override
  void dispose() {
    _player.dispose();
    _yt.close();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildSearchBar(),
                Expanded(
                  child: _searchResults.isEmpty ? _buildHomeView() : _buildSearchList(),
                ),
              ],
            ),
          ),
          if (_currentTitle != "Select Music") _buildMiniPlayer(),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A1A), Colors.black],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      child: Row(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [gold, const Color(0xFFFBF5B7), gold],
            ).createShader(bounds),
            child: const Text("CENT", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 4, fontSize: 32)),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: gold.withOpacity(0.2)),
        ),
        child: TextField(
          controller: _searchController,
          onSubmitted: _searchSongs,
          decoration: InputDecoration(
            hintText: "Search Golden Tracks...",
            hintStyle: TextStyle(color: gold.withOpacity(0.3)),
            prefixIcon: Icon(Icons.search, color: gold),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _buildHomeView() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("TOP 10 MUSIC", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 15),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 5,
                itemBuilder: (context, index) => _buildTrackCard("Trending #${index + 1}"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackCard(String title) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF121212),
        border: Border.all(color: gold.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Expanded(child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(20)), child: Image.network("https://picsum.photos/200", fit: BoxFit.cover))),
          Padding(padding: const EdgeInsets.all(8.0), child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildSearchList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        var video = _searchResults[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 5),
          leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(video.thumbnails.lowResUrl, width: 50, height: 50, fit: BoxFit.cover)),
          title: Text(video.title, maxLines: 1, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          subtitle: Text(video.author, style: TextStyle(color: gold, fontSize: 11)),
          onTap: () => _playVideo(video.id.value, video.title, video.author, video.thumbnails.highResUrl),
        );
      },
    );
  }

  Widget _buildMiniPlayer() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: GestureDetector(
        onTap: _showFullPlayer,
        child: Container(
          height: 70,
          margin: const EdgeInsets.fromLTRB(15, 0, 15, 20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: gold.withOpacity(0.5)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10)],
          ),
          child: ListTile(
            leading: CircleAvatar(backgroundImage: NetworkImage(_currentThumbnail)),
            title: Text(_currentTitle, maxLines: 1, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            trailing: IconButton(
              icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, color: gold, size: 40),
              onPressed: () => _isPlaying ? _player.pause() : _player.play(),
            ),
          ),
        ),
      ),
    );
  }

  void _showFullPlayer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FullPlayerUI(
        player: _player,
        title: _currentTitle,
        author: _currentAuthor,
        thumb: _currentThumbnail,
        gold: gold,
      ),
    );
  }
}

class _FullPlayerUI extends StatelessWidget {
  final AudioPlayer player;
  final String title, author, thumb;
  final Color gold;

  const _FullPlayerUI({required this.player, required this.title, required this.author, required this.thumb, required this.gold});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.95,
      decoration: const BoxDecoration(color: Color(0xFF0A0A0A), borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
          const Spacer(),
          Container(
            width: 300, height: 300,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: gold.withOpacity(0.2), blurRadius: 50)], image: DecorationImage(image: NetworkImage(thumb), fit: BoxFit.cover)),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis), Text(author, style: TextStyle(color: gold, fontSize: 16))])),
                Icon(Icons.favorite_border, color: gold, size: 30),
              ],
            ),
          ),
          const SizedBox(height: 30),
          StreamBuilder<Duration>(
            stream: player.positionStream,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              final total = player.duration ?? Duration.zero;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Slider(
                      activeColor: gold,
                      inactiveColor: Colors.white10,
                      value: position.inSeconds.toDouble(),
                      max: total.inSeconds.toDouble() > 0 ? total.inSeconds.toDouble() : 1.0,
                      onChanged: (value) => player.seek(Duration(seconds: value.toInt())),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(_formatDuration(position), style: const TextStyle(fontSize: 12, color: Colors.grey)), Text(_formatDuration(total), style: const TextStyle(fontSize: 12, color: Colors.grey))]),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(icon: const Icon(Icons.skip_previous_rounded, size: 45), onPressed: () {}),
              const SizedBox(width: 20),
              StreamBuilder<PlayerState>(
                stream: player.playerStateStream,
                builder: (context, snapshot) {
                  final playing = snapshot.data?.playing ?? false;
                  return IconButton(icon: Icon(playing ? Icons.pause_circle_filled : Icons.play_circle_filled, size: 80, color: gold), onPressed: () => playing ? player.pause() : player.play());
                },
              ),
              const SizedBox(width: 20),
              IconButton(icon: const Icon(Icons.skip_next_rounded, size: 45), onPressed: () {}),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }
}
