import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:ui';

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
        scaffoldBackgroundColor: const Color(0xFF020202),
        useMaterial3: true,
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
  bool _isLoading = false;
  Video? _currentVideo;
  List<Video> _searchResults = [];
  final TextEditingController _searchController = TextEditingController();
  
  final Color gold = const Color(0xFFD4AF37);

  @override
  void initState() {
    super.initState();
    _player.playerStateStream.listen((state) {
      if (mounted) setState(() => _isPlaying = state.playing);
    });
  }

  Future<void> _searchSongs(String query) async {
    if (query.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      var search = await _yt.search.search(query);
      setState(() {
        _searchResults = search.toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _playVideo(Video video) async {
    setState(() {
      _isLoading = true;
      _currentVideo = video;
    });

    try {
      var manifest = await _yt.videos.streamsClient.getManifest(video.id);
      var streamInfo = manifest.audioOnly.withHighestBitrate();
      
      await _player.setAudioSource(
        AudioSource.uri(Uri.parse(streamInfo.url.toString())),
      );
      _player.play();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
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
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(),
                _buildSearchSection(),
                if (_isLoading) _buildLoadingBar(),
                _buildMusicGrid(),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),
          if (_currentVideo != null) _buildMiniPlayer(),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.5),
          radius: 1.2,
          colors: [Color(0xFF151515), Color(0xFF000000)],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      floating: true,
      centerTitle: false,
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: gold, width: 2.5),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text(
          "CENT",
          style: TextStyle(
            color: gold,
            fontWeight: FontWeight.w900,
            letterSpacing: 5,
            fontSize: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.white.withOpacity(0.05),
              child: TextField(
                controller: _searchController,
                onSubmitted: _searchSongs,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Search Golden Tracks",
                  hintStyle: TextStyle(color: gold.withOpacity(0.3)),
                  prefixIcon: Icon(Icons.search, color: gold),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: LinearProgressIndicator(color: gold, backgroundColor: Colors.transparent),
      ),
    );
  }

  Widget _buildMusicGrid() {
    if (_searchResults.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Text("Discover the Sound of Luxury", style: TextStyle(color: Colors.white24)),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.all(15),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          mainAxisSpacing: 15,
          crossAxisSpacing: 15,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final video = _searchResults[index];
            return GestureDetector(
              onTap: () => _playVideo(video),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        child: Image.network(video.thumbnails.highResUrl, fit: BoxFit.cover, width: double.infinity),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(video.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(video.author, style: TextStyle(color: gold, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          childCount: _searchResults.length,
        ),
      ),
    );
  }

  Widget _buildMiniPlayer() {
    return Positioned(
      bottom: 20, left: 10, right: 10,
      child: GestureDetector(
        onTap: _showFullPlayer,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              height: 75,
              color: Colors.black.withOpacity(0.8),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Hero(
                    tag: 'music_thumb',
                    child: CircleAvatar(backgroundImage: NetworkImage(_currentVideo!.thumbnails.lowResUrl), radius: 25),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_currentVideo!.title, maxLines: 1, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(_currentVideo!.author, style: TextStyle(color: gold, fontSize: 11)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 40, color: gold),
                    onPressed: () => _isPlaying ? _player.pause() : _player.play(),
                  ),
                ],
              ),
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
      builder: (context) => _FullPlayerUI(player: _player, video: _currentVideo!, gold: gold),
    );
  }
}

class _FullPlayerUI extends StatelessWidget {
  final AudioPlayer player;
  final Video video;
  final Color gold;

  const _FullPlayerUI({required this.player, required this.video, required this.gold});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: const BoxDecoration(color: Color(0xFF050505)),
      child: Column(
        children: [
          const SizedBox(height: 60),
          IconButton(icon: const Icon(Icons.keyboard_arrow_down, size: 40), onPressed: () => Navigator.pop(context)),
          const Spacer(),
          Hero(
            tag: 'music_thumb',
            child: Container(
              width: 320, height: 320,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                image: DecorationImage(image: NetworkImage(video.thumbnails.highResUrl), fit: BoxFit.cover),
                boxShadow: [BoxShadow(color: gold.withOpacity(0.15), blurRadius: 60, spreadRadius: 10)],
              ),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                Text(video.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(video.author, style: TextStyle(color: gold, fontSize: 18, letterSpacing: 1.5)),
              ],
            ),
          ),
          const Spacer(),
          _buildProgressBar(),
          _buildControls(),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return StreamBuilder<Duration>(
      stream: player.positionStream,
      builder: (context, snapshot) {
        final pos = snapshot.data ?? Duration.zero;
        final dur = player.duration ?? Duration.zero;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Slider(
            activeColor: gold,
            inactiveColor: Colors.white10,
            value: pos.inSeconds.toDouble(),
            max: dur.inSeconds.toDouble() > 0 ? dur.inSeconds.toDouble() : 1.0,
            onChanged: (v) => player.seek(Duration(seconds: v.toInt())),
          ),
        );
      },
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.skip_previous_rounded, size: 55),
        const SizedBox(width: 30),
        StreamBuilder<PlayerState>(
          stream: player.playerStateStream,
          builder: (context, snapshot) {
            final playing = snapshot.data?.playing ?? false;
            return IconButton(
              icon: Icon(playing ? Icons.pause_circle_filled : Icons.play_circle_filled, size: 95, color: gold),
              onPressed: () => playing ? player.pause() : player.play(),
            );
          },
        ),
        const SizedBox(width: 30),
        const Icon(Icons.skip_next_rounded, size: 55),
      ],
    );
  }
}
