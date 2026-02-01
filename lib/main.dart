import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize High-Level Audio Engine
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.black,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  
  runApp(const CentSupremeApp());
}

class CentSupremeApp extends StatelessWidget {
  const CentSupremeApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CENT SUPREME',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFD4AF37),
        hintColor: const Color(0xFFD4AF37),
        scaffoldBackgroundColor: const Color(0xFF000000),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MainSupremeArchitecture(),
    );
  }
}

class MainSupremeArchitecture extends StatefulWidget {
  const MainSupremeArchitecture({super.key});
  @override
  State<MainSupremeArchitecture> createState() => _MainSupremeArchitectureState();
}

class _MainSupremeArchitectureState extends State<MainSupremeArchitecture> with TickerProviderStateMixin {
  int _tabIndex = 0;
  final AudioPlayer _player = AudioPlayer();
  final YoutubeExplode _yt = YoutubeExplode();
  
  Video? _currentTrack;
  bool _isLoadingTrack = false;
  double _volume = 1.0;
  
  final List<Video> _favs = [];
  final List<Video> _history = [];
  
  late AnimationController _playPauseController;

  @override
  void initState() {
    super.initState();
    _playPauseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _setupAudioListeners();
  }

  void _setupAudioListeners() {
    _player.playerStateStream.listen((state) {
      if (state.playing) {
        _playPauseController.forward();
      } else {
        _playPauseController.reverse();
      }
    });
  }

  Future<void> _igniteEngine(Video video) async {
    if (_currentTrack?.id == video.id && _player.playing) return;
    
    setState(() {
      _currentTrack = video;
      _isLoadingTrack = true;
      if (!_history.any((e) => e.id == video.id)) _history.insert(0, video);
    });

    try {
      var manifest = await _yt.videos.streamsClient.getManifest(video.id);
      var audioStream = manifest.audioOnly.withHighestBitrate();
      
      await _player.setAudioSource(
        AudioSource.uri(
          Uri.parse(audioStream.url.toString()),
          tag: video.title,
        ),
        preload: true,
      );
      _player.play();
    } catch (e) {
      _triggerAlert("CORE_SIGNAL_ERROR: ARCHIVE NOT FOUND");
    } finally {
      if (mounted) setState(() => _isLoadingTrack = false);
    }
  }

  void _triggerAlert(String m) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFD4AF37),
        content: Text(m, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  void dispose() {
    _player.dispose();
    _yt.close();
    _playPauseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _fragments = [
      DiscoveryFragment(yt: _yt, onPlay: _igniteEngine),
      VaultFragment(favs: _favs, history: _history, onPlay: _igniteEngine),
      EngineFragment(player: _player, onVolumeChanged: (v) {
        setState(() => _volume = v);
        _player.setVolume(v);
      }, currentVolume: _volume),
    ];

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: _tabIndex, children: _fragments),
          if (_currentTrack != null) _supremeFloatingConsole(),
        ],
      ),
      bottomNavigationBar: _imperialNavBar(),
    );
  }

  Widget _imperialNavBar() {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.2), width: 0.5)),
      ),
      child: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        backgroundColor: Colors.transparent,
        selectedItemColor: const Color(0xFFD4AF37),
        unselectedItemColor: Colors.white10,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.blur_on_rounded, size: 28), label: 'DISCOVER'),
          BottomNavigationBarItem(icon: Icon(Icons.layers_rounded, size: 28), label: 'VAULT'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_input_antenna_rounded, size: 28), label: 'ENGINE'),
        ],
      ),
    );
  }

  Widget _supremeFloatingConsole() {
    return Positioned(
      bottom: 10, left: 10, right: 10,
      child: GestureDetector(
        onTap: _openVisualizer,
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity! < -300) _openVisualizer();
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(
              height: 75,
              color: const Color(0xFF111111).withOpacity(0.7),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Hero(
                        tag: 'art_${_currentTrack!.id}',
                        child: Container(
                          width: 50, height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(image: CachedNetworkImageProvider(_currentTrack!.thumbnails.mediumResUrl), fit: BoxFit.cover),
                          ),
                        ),
                      ),
                      if (_isLoadingTrack) const SpinKitRing(color: Color(0xFFD4AF37), size: 50, strokeWidth: 2),
                    ],
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_currentTrack!.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const Text("CENT SUPREME SIGNAL • 1411 KBPS", style: TextStyle(color: Color(0xFFD4AF37), fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                      ],
                    ),
                  ),
                  _playbackButton(40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _playbackButton(double size) {
    return StreamBuilder<PlayerState>(
      stream: _player.playerStateStream,
      builder: (context, snap) {
        bool isP = snap.data?.playing ?? false;
        return IconButton(
          icon: Icon(isP ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded, color: const Color(0xFFD4AF37), size: size),
          onPressed: () => isP ? _player.pause() : _player.play(),
        );
      },
    );
  }

  void _openVisualizer() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => SupremeVisualizer(
        player: _player,
        video: _currentTrack!,
        isFav: _favs.any((v) => v.id == _currentTrack!.id),
        onFavToggle: () => setState(() {
          if (_favs.any((v) => v.id == _currentTrack!.id)) {
            _favs.removeWhere((v) => v.id == _currentTrack!.id);
          } else {
            _favs.add(_currentTrack!);
          }
        }),
      ),
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(position: Tween(begin: const Offset(0, 1), end: const Offset(0, 0)).animate(anim1), child: child);
      },
    );
  }
}

// --- DISCOVERY LAYER (HIGH DENSITY GRID) ---
class DiscoveryFragment extends StatefulWidget {
  final YoutubeExplode yt;
  final Function(Video) onPlay;
  const DiscoveryFragment({super.key, required this.yt, required this.onPlay});
  @override
  State<DiscoveryFragment> createState() => _DiscoveryFragmentState();
}

class _DiscoveryFragmentState extends State<DiscoveryFragment> {
  final TextEditingController _search = TextEditingController();
  List<Video> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  void _loadInitial() async {
    try {
      var res = await widget.yt.search.search("ultra high fidelity music 2026", filter: TypeFilters.video);
      if (mounted) setState(() { _items = res.toList(); _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _runSearch(String v) async {
    setState(() => _loading = true);
    var res = await widget.yt.search.search(v);
    setState(() { _items = res.toList(); _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          expandedHeight: 240, pinned: true, backgroundColor: Colors.black,
          flexibleSpace: FlexibleSpaceBar(
            centerTitle: true,
            title: const Text("C E N T", style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.w900, letterSpacing: 12, fontSize: 24)),
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF222222), Colors.black]),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.vibration_rounded, color: const Color(0xFFD4AF37).withOpacity(0.05), size: 250),
                  const SpinKitDoubleBounce(color: Colors.white10, size: 200),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
            child: TextField(
              controller: _search, onSubmitted: _runSearch,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true, fillColor: const Color(0xFF111111),
                hintText: "Access Neural Network...",
                hintStyle: const TextStyle(color: Colors.white24, letterSpacing: 2),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFD4AF37)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
          ),
        ),
        if (_loading) const SliverToBoxAdapter(child: Center(child: SpinKitCubeGrid(color: Color(0xFFD4AF37), size: 40))),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(15, 0, 15, 120),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, childAspectRatio: 0.65, mainAxisSpacing: 15, crossAxisSpacing: 15,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => _buildSupremeCard(_items[i]),
              childCount: _items.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSupremeCard(Video v) {
    return GestureDetector(
      onTap: () => widget.onPlay(v),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                image: DecorationImage(image: CachedNetworkImageProvider(v.thumbnails.highResUrl), fit: BoxFit.cover),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 8))],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(v.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, height: 1.3)),
          const SizedBox(height: 4),
          Text(v.author, style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ],
      ),
    );
  }
}

// --- SUPREME VISUALIZER (FULL SCREEN EXPERIENCE) ---
class SupremeVisualizer extends StatelessWidget {
  final AudioPlayer player;
  final Video video;
  final bool isFav;
  final VoidCallback onFavToggle;
  const SupremeVisualizer({super.key, required this.player, required this.video, required this.isFav, required this.onFavToggle});

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFD4AF37);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: Opacity(opacity: 0.4, child: CachedNetworkImage(imageUrl: video.thumbnails.highResUrl, fit: BoxFit.cover))),
          BackdropFilter(filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100), child: Container(color: Colors.black.withOpacity(0.85))),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, gold),
                const Spacer(),
                _buildArtSection(gold),
                const Spacer(),
                _buildTrackInfo(gold),
                const Spacer(),
                _buildPlaybackEngine(player, gold),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext ctx, Color g) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 45), onPressed: () => Navigator.pop(ctx)),
          const Text("CENT SUPREME PLAYER", style: TextStyle(letterSpacing: 4, fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white54)),
          IconButton(icon: Icon(isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: g, size: 28), onPressed: onFavToggle),
        ],
      ),
    );
  }

  Widget _buildArtSection(Color g) {
    return Hero(
      tag: 'art_${video.id}',
      child: Container(
        width: 300, height: 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(35),
          image: DecorationImage(image: CachedNetworkImageProvider(video.thumbnails.highResUrl), fit: BoxFit.cover),
          boxShadow: [
            BoxShadow(color: g.withOpacity(0.2), blurRadius: 80, spreadRadius: 5),
            BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackInfo(Color g) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          Text(video.title, textAlign: TextAlign.center, maxLines: 2, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          const SizedBox(height: 12),
          Text(video.author.toUpperCase(), style: TextStyle(color: g, letterSpacing: 6, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPlaybackEngine(AudioPlayer p, Color g) {
    return Column(
      children: [
        StreamBuilder<Duration>(
          stream: p.positionStream,
          builder: (context, snap) {
            final pos = snap.data ?? Duration.zero;
            final dur = p.duration ?? Duration.zero;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                      activeTrackColor: g,
                      inactiveTrackColor: Colors.white10,
                      thumbColor: Colors.white,
                    ),
                    child: Slider(
                      value: pos.inSeconds.toDouble(),
                      max: dur.inSeconds.toDouble() > 0 ? dur.inSeconds.toDouble() : 1.0,
                      onChanged: (v) => p.seek(Duration(seconds: v.toInt())),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(pos), style: const TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold)),
                      Text(_formatDuration(dur), style: const TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shuffle_rounded, color: Colors.white24, size: 22),
            const SizedBox(width: 30),
            const Icon(Icons.skip_previous_rounded, size: 55),
            const SizedBox(width: 20),
            StreamBuilder<PlayerState>(
              stream: p.playerStateStream,
              builder: (context, snap) {
                bool isP = snap.data?.playing ?? false;
                return GestureDetector(
                  onTap: () => isP ? p.pause() : p.play(),
                  child: Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(color: g, shape: BoxShape.circle, boxShadow: [BoxShadow(color: g.withOpacity(0.3), blurRadius: 25)]),
                    child: Icon(isP ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.black, size: 60),
                  ),
                );
              },
            ),
            const SizedBox(width: 20),
            const Icon(Icons.skip_next_rounded, size: 55),
            const SizedBox(width: 30),
            const Icon(Icons.repeat_rounded, color: Colors.white24, size: 22),
          ],
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }
  
