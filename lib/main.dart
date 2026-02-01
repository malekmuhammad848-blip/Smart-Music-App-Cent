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

class _MainScaffoldState extends State<MainScaffold> with TickerProviderStateMixin {
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
      await _player.setAudioSource(AudioSource.uri(Uri.parse(streamInfo.url.toString())));
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
          _buildAnimatedBackground(),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(),
                _buildSearchSection(),
                if (_isLoading) _buildLoadingIndicator(),
                _buildMusicGrid(),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),
          if (_currentVideo != null) _buildEliteMiniPlayer(),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 800),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.5),
          radius: 1.5,
          colors: [
            _currentVideo != null ? gold.withOpacity(0.05) : const Color(0xFF151515),
            const Color(0xFF000000),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      floating: true,
      centerTitle: true,
      title: Hero(
        tag: 'logo',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: gold, width: 2),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            "CENT",
            style: TextStyle(
              color: gold,
              fontWeight: FontWeight.w900,
              letterSpacing: 8,
              fontSize: 24,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: Colors.white.withOpacity(0.05),
              child: TextField(
                controller: _searchController,
                onSubmitted: _searchSongs,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Search Golden Tracks...",
                  hintStyle: TextStyle(color: gold.withOpacity(0.3)),
                  prefixIcon: Icon(Icons.search_rounded, color: gold),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(20),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: LinearProgressIndicator(color: gold, backgroundColor: Colors.transparent),
      ),
    );
  }

  Widget _buildMusicGrid() {
    if (_searchResults.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.vibration, color: gold.withOpacity(0.2), size: 50),
              const SizedBox(height: 10),
              const Text("Feel the Pulse of Luxury", style: TextStyle(color: Colors.white10, letterSpacing: 2)),
            ],
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final video = _searchResults[index];
            return TweenAnimationBuilder(
              duration: Duration(milliseconds: 400 + (index * 100)),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, double value, child) => Opacity(
                opacity: value,
                child: Transform.translate(offset: Offset(0, 20 * (1 - value)), child: child),
              ),
              child: GestureDetector(
                onTap: () => _playVideo(video),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: Image.network(video.thumbnails.highResUrl, fit: BoxFit.cover, width: double.infinity),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(video.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          childCount: _searchResults.length,
        ),
      ),
    );
  }

  Widget _buildEliteMiniPlayer() {
    return Positioned(
      bottom: 25, left: 15, right: 15,
      child: GestureDetector(
        onTap: _showFullPlayer,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              height: 80,
              color: Colors.black.withOpacity(0.7),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  Hero(
                    tag: 'art',
                    child: CircleAvatar(backgroundImage: NetworkImage(_currentVideo!.thumbnails.lowResUrl), radius: 28),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_currentVideo!.title, maxLines: 1, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(_currentVideo!.author, style: TextStyle(color: gold, fontSize: 11, letterSpacing: 1)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(_isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded, size: 45, color: gold),
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A0A0A), Color(0xFF000000)],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 60),
          const Icon(Icons.keyboard_arrow_down_rounded, size: 45, color: Colors.white24),
          const Spacer(),
          Hero(
            tag: 'art',
            child: Container(
              width: 320, height: 320,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                boxShadow: [BoxShadow(color: gold.withOpacity(0.2), blurRadius: 80, spreadRadius: 5)],
                image: DecorationImage(image: NetworkImage(video.thumbnails.highResUrl), fit: BoxFit.cover),
              ),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                Text(video.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                const SizedBox(height: 12),
                Text(video.author, style: TextStyle(color: gold, fontSize: 18, letterSpacing: 3, fontWeight: FontWeight.w300)),
              ],
            ),
          ),
          const SizedBox(height: 40),
          _buildSlider(),
          _buildControls(),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildSlider() {
    return StreamBuilder<Duration>(
      stream: player.positionStream,
      builder: (context, snapshot) {
        final pos = snapshot.data ?? Duration.zero;
        final dur = player.duration ?? Duration.zero;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(trackHeight: 4, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6)),
                child: Slider(
                  activeColor: gold,
                  inactiveColor: Colors.white10,
                  value: pos.inSeconds.toDouble(),
                  max: dur.inSeconds.toDouble() > 0 ? dur.inSeconds.toDouble() : 1.0,
                  onChanged: (v) => player.seek(Duration(seconds: v.toInt())),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatDuration(pos), style: const TextStyle(color: Colors.white30, fontSize: 12)),
                    Text(_formatDuration(dur), style: const TextStyle(color: Colors.white30, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.skip_previous_rounded, size: 60, color: Colors.white),
        const SizedBox(width: 30),
        StreamBuilder<PlayerState>(
          stream: player.playerStateStream,
          builder: (context, snapshot) {
            final playing = snapshot.data?.playing ?? false;
            return IconButton(
              icon: Icon(playing ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded, size: 100, color: gold),
              onPressed: () => playing ? player.pause() : player.play(),
            );
          },
        ),
        const SizedBox(width: 30),
        const Icon(Icons.skip_next_rounded, size: 60, color: Colors.white),
      ],
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }
}
