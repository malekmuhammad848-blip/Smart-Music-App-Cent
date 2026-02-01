import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:ui';

void main() {
  // Lock orientation and set transparent status bar for immersive experience
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const CentMusicElite());
}

class CentMusicElite extends StatelessWidget {
  const CentMusicElite({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CENT',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFD4AF37),
        scaffoldBackgroundColor: const Color(0xFF000000), // Pure Black for OLED
        splashColor: const Color(0xFFD4AF37).withOpacity(0.1),
        highlightColor: Colors.transparent,
        useMaterial3: true,
        fontFamily: 'Georgia', // Elegant classic font
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

class _MainScaffoldState extends State<MainScaffold> with SingleTickerProviderStateMixin {
  final AudioPlayer _player = AudioPlayer();
  final YoutubeExplode _yt = YoutubeExplode();
  final TextEditingController _searchController = TextEditingController();
  
  bool _isPlaying = false;
  bool _isLoading = false;
  Video? _currentVideo;
  List<Video> _searchResults = [];
  final Color _gold = const Color(0xFFD4AF37);

  @override
  void initState() {
    super.initState();
    _listenToPlayerState();
  }

  void _listenToPlayerState() {
    _player.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          if (state.processingState == ProcessingState.loading) _isLoading = true;
          if (state.processingState == ProcessingState.ready) _isLoading = false;
        });
      }
    });
  }

  Future<void> _executeEliteSearch(String query) async {
    if (query.isEmpty) return;
    FocusScope.of(context).unfocus();
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

  Future<void> _initializePlayback(Video video) async {
    setState(() {
      _currentVideo = video;
      _isLoading = true;
    });

    try {
      var manifest = await _yt.videos.streamsClient.getManifest(video.id);
      var streamInfo = manifest.audioOnly.withHighestBitrate();
      
      await _player.setAudioSource(
        AudioSource.uri(
          Uri.parse(streamInfo.url.toString()),
          tag: video.title,
        ),
      );
      _player.play();
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
          _buildEliteBackground(),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverHeader(),
                _buildModernSearchBar(),
                _buildContentBody(),
              ],
            ),
          ),
          if (_currentVideo != null) _buildFloatingPlayer(),
        ],
      ),
    );
  }

  Widget _buildEliteBackground() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.6),
            radius: 1.4,
            colors: [Color(0xFF1A1A1A), Color(0xFF000000)],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverHeader() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      expandedHeight: 100,
      centerTitle: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(color: _gold, width: 2),
                borderRadius: BorderRadius.circular(0),
              ),
              child: Text(
                "CENT",
                style: TextStyle(
                  color: _gold,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 8,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernSearchBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(25, 40, 25, 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                border: Border.all(color: Colors.white10),
              ),
              child: TextField(
                controller: _searchController,
                onSubmitted: _executeEliteSearch,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: "Enter the world of sound...",
                  hintStyle: TextStyle(color: _gold.withOpacity(0.3)),
                  border: InputBorder.none,
                  suffixIcon: Icon(Icons.search_rounded, color: _gold),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentBody() {
    if (_isLoading && _searchResults.isEmpty) {
      return SliverFillRemaining(
        child: Center(child: CircularProgressIndicator(color: _gold, strokeWidth: 1)),
      );
    }
    
    if (_searchResults.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Opacity(
            opacity: 0.2,
            child: Text("C E N T", style: TextStyle(fontSize: 50, color: _gold, fontWeight: FontWeight.w100)),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final video = _searchResults[index];
            return GestureDetector(
              onTap: () => _initializePlayback(video),
              child: _buildMusicCard(video),
            );
          },
          childCount: _searchResults.length,
        ),
      ),
    );
  }

  Widget _buildMusicCard(Video video) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Hero(
            tag: video.id.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                image: DecorationImage(image: NetworkImage(video.thumbnails.highResUrl), fit: BoxFit.cover),
                boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 15, offset: const Offset(0, 8))],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(video.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(video.author, style: TextStyle(color: _gold, fontSize: 12, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildFloatingPlayer() {
    return Positioned(
      bottom: 25, left: 20, right: 20,
      child: GestureDetector(
        onTap: _showImmersivePlayer,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              height: 80,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                border: Border.all(color: _gold.withOpacity(0.3), width: 0.5),
              ),
              child: Row(
                children: [
                  CircleAvatar(backgroundImage: NetworkImage(_currentVideo!.thumbnails.lowResUrl), radius: 26),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_currentVideo!.title, maxLines: 1, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(_currentVideo!.author, style: TextStyle(color: _gold, fontSize: 11)),
                      ],
                    ),
                  ),
                  _isLoading 
                    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: _gold, strokeWidth: 2))
                    : IconButton(
                        icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: _gold, size: 35),
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

  void _showImmersivePlayer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ImmersivePlayerUI(player: _player, video: _currentVideo!, gold: _gold),
    );
  }
}

class _ImmersivePlayerUI extends StatelessWidget {
  final AudioPlayer player;
  final Video video;
  final Color gold;

  const _ImmersivePlayerUI({required this.player, required this.video, required this.gold});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: const BoxDecoration(color: Color(0xFF000000)),
      child: Stack(
        children: [
          // Dynamic background glow
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: Image.network(video.thumbnails.highResUrl, fit: BoxFit.cover),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
            child: Container(color: Colors.black.withOpacity(0.4)),
          ),
          Column(
            children: [
              const SizedBox(height: 60),
              _buildControlHeader(context),
              const Spacer(),
              _buildMainArt(),
              const Spacer(),
              _buildMetadata(),
              const SizedBox(height: 30),
              _buildProgressSystem(),
              const SizedBox(height: 20),
              _buildMainTransportControls(),
              const Spacer(flex: 2),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.expand_more_rounded, size: 40), onPressed: () => Navigator.pop(context)),
          const Text("CENT PREMIUM", style: TextStyle(letterSpacing: 4, fontSize: 12, fontWeight: FontWeight.bold)),
          IconButton(icon: const Icon(Icons.more_horiz_rounded), onPressed: () {}),
        ],
      ),
    );
  }

  Widget _buildMainArt() {
    return Hero(
      tag: video.id.value,
      child: Container(
        width: 310, height: 310,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          image: DecorationImage(image: NetworkImage(video.thumbnails.highResUrl), fit: BoxFit.cover),
          boxShadow: [BoxShadow(color: gold.withOpacity(0.2), blurRadius: 80, spreadRadius: 10)],
        ),
      ),
    );
  }

  Widget _buildMetadata() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          Text(video.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Text(video.author, style: TextStyle(color: gold, fontSize: 16, letterSpacing: 2)),
        ],
      ),
    );
  }

  Widget _buildProgressSystem() {
    return StreamBuilder<Duration>(
      stream: player.positionStream,
      builder: (context, snapshot) {
        final pos = snapshot.data ?? Duration.zero;
        final dur = player.duration ?? Duration.zero;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            children: [
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                  activeTrackColor: gold,
                  inactiveTrackColor: Colors.white12,
                  thumbColor: Colors.white,
                ),
                child: Slider(
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
                    Text(_format(pos), style: const TextStyle(color: Colors.white38, fontSize: 12)),
                    Text(_format(dur), style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainTransportControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(icon: const Icon(Icons.skip_previous_rounded, size: 55), onPressed: () {}),
        const SizedBox(width: 25),
        StreamBuilder<PlayerState>(
          stream: player.playerStateStream,
          builder: (context, snapshot) {
            final playing = snapshot.data?.playing ?? false;
            return GestureDetector(
              onTap: () => playing ? player.pause() : player.play(),
              child: Container(
                width: 85, height: 85,
                decoration: BoxDecoration(color: gold, shape: BoxShape.circle),
                child: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.black, size: 50),
              ),
            );
          },
        ),
        const SizedBox(width: 25),
        IconButton(icon: const Icon(Icons.skip_next_rounded, size: 55), onPressed: () {}),
      ],
    );
  }

  String _format(Duration d) => "${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}";
}
