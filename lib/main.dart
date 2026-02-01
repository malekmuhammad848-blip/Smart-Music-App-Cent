import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as exp;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
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
        scaffoldBackgroundColor: const Color(0xFF0F0F0F), // Deep black for 3D contrast
      ),
      home: const MainMusicScreen(),
    );
  }
}

// --- Dynamic 3D Neumorphic Button Component ---
class NeumorphicButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double size;

  const NeumorphicButton({super.key, required this.child, required this.onTap, this.size = 60});

  @override
  State<NeumorphicButton> createState() => _NeumorphicButtonState();
}

class _NeumorphicButtonState extends State<NeumorphicButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          shape: BoxShape.circle,
          boxShadow: _isPressed
              ? [] // No shadow when pressed for "Pressed In" effect
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    offset: const Offset(4, 4),
                    blurRadius: 10,
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.05),
                    offset: const Offset(-4, -4),
                    blurRadius: 10,
                  ),
                ],
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _isPressed
                ? [const Color(0xFF121212), const Color(0xFF1A1A1A)]
                : [const Color(0xFF222222), const Color(0xFF161616)],
          ),
        ),
        child: Center(child: widget.child),
      ),
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
      flags: const YoutubePlayerFlags(autoPlay: false, hideControls: true),
    )..addListener(_playerListener);

    _rotationController = AnimationController(vsync: this, duration: const Duration(seconds: 20));
    _fetchTrending();
  }

  void _playerListener() {
    if (mounted && _controller.value.isPlaying != isPlaying) {
      setState(() {
        isPlaying = _controller.value.isPlaying;
        isPlaying ? _rotationController.repeat() : _rotationController.stop();
      });
    }
  }

  Future<void> _fetchTrending() async {
    try {
      var playlist = await yt.playlists.getVideos('PLFgquLnL59alW3ElYiS2t6gBnL8I9Jp7p');
      setState(() => trendingSongs = playlist.take(15).toList());
    } catch (e) {
      debugPrint("Error fetching music: $e");
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
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F0F0F), Color(0xFF1A1A1A)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                backgroundColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text("CENT MUSIC", style: TextStyle(letterSpacing: 3, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37))),
                  centerTitle: true,
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final video = trendingSongs[index];
                    return _buildMusicTile(video);
                  },
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

  Widget _buildMusicTile(exp.Video video) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        onTap: () => _playSong(video),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(imageUrl: video.thumbnails.mediumResUrl, width: 60, height: 60, fit: BoxFit.cover),
        ),
        title: Text(video.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(video.author, style: TextStyle(color: Colors.white.withOpacity(0.6))),
        trailing: const NeumorphicButton(
          size: 40,
          onTap: null, // Just for UI in list
          child: Icon(Icons.play_arrow, size: 20, color: Color(0xFFD4AF37)),
        ),
      ),
    );
  }

  Widget _buildMiniPlayer() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 100,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A).withOpacity(0.9),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  RotationTransition(
                    turns: _rotationController,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                      ),
                      child: CircleAvatar(backgroundImage: CachedNetworkImageProvider(currentCover!), radius: 25),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(currentTitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(currentArtist!, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                      ],
                    ),
                  ),
                  NeumorphicButton(
                    size: 50,
                    onTap: () => isPlaying ? _controller.pause() : _controller.play(),
                    child: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: const Color(0xFFD4AF37)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
