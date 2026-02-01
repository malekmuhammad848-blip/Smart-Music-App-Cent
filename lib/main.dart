import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as exp;
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';

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
  late AnimationController _rotationController;
  
  List<exp.Video> trendingSongs = [];
  String? currentTitle, currentArtist, currentCover, currentId;
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: '',
      flags: const YoutubePlayerFlags(autoPlay: false, hideControls: true, mute: false),
    )..addListener(_playerListener);

    _rotationController = AnimationController(vsync: this, duration: const Duration(seconds: 20));
    _fetchTrending();
  }

  void _playerListener() {
    if (mounted) {
      final controllerPlaying = _controller.value.isPlaying;
      if (controllerPlaying != isPlaying) {
        setState(() {
          isPlaying = controllerPlaying;
          isPlaying ? _rotationController.repeat() : _rotationController.stop();
        });
      }
    }
  }

  // FIXED: Added 'await' to handle the Future correctly
  Future<void> _fetchTrending() async {
    try {
      final playlistVideos = await yt.playlists.getVideos('PLFgquLnL59alW3ElYiS2t6gBnL8I9Jp7p').toList();
      setState(() {
        trendingSongs = playlistVideos.take(15).toList();
      });
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  void _playSong(exp.Video video) {
    setState(() {
      currentId = video.id.value;
      currentTitle = video.title;
      currentArtist = video.author;
      currentCover = video.thumbnails.highResUrl;
    });
    _controller.load(video.id.value);
    _controller.play();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          CustomScrollView(
            slivers: [
              const SliverAppBar(
                expandedHeight: 100,
                backgroundColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text("CENT MUSIC", style: TextStyle(letterSpacing: 3, fontWeight: FontWeight.bold)),
                  centerTitle: true,
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildMusicTile(trendingSongs[index]),
                  childCount: trendingSongs.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
          if (currentId != null) _buildMiniPlayer(),
        ],
      ),
    );
  }

  Widget _buildBackground() => Container(decoration: const BoxDecoration(color: Color(0xFF0F0F0F)));

  Widget _buildMusicTile(exp.Video video) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        onTap: () => _playSong(video),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CachedNetworkImage(imageUrl: video.thumbnails.mediumResUrl, width: 50, height: 50, fit: BoxFit.cover),
        ),
        title: Text(video.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(video.author, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        // FIXED: Replaced 'null' with an empty function to satisfy the type system
        trailing: IconButton(icon: const Icon(Icons.play_circle_fill, color: Color(0xFFD4AF37)), onPressed: () => _playSong(video)),
      ),
    );
  }

  Widget _buildMiniPlayer() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 90,
        margin: const EdgeInsets.all(15),
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10)],
        ),
        child: Row(
          children: [
            RotationTransition(
              turns: _rotationController,
              child: CircleAvatar(backgroundImage: CachedNetworkImageProvider(currentCover!), radius: 25),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(currentTitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(currentArtist!, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ),
            IconButton(
              icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, size: 40, color: const Color(0xFFD4AF37)),
              onPressed: () => isPlaying ? _controller.pause() : _controller.play(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _rotationController.dispose();
    yt.close();
    super.dispose();
  }
}
