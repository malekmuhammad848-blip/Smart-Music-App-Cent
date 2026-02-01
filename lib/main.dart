import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart'; // For professional background play
import 'dart:ui';
import 'dart:async';

// --- SYSTEM INITIALIZATION ---
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Setting up background audio service for 100% stability
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.cent.music.channel.audio',
    androidNotificationChannelName: 'CENT Audio Playback',
    androidNotificationOngoing: true,
  );

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.black,
      statusBarIconTheme: Brightness.light,
    ),
  );
  
  runApp(const CentSupremeUniversal());
}

class CentSupremeUniversal extends StatelessWidget {
  const CentSupremeUniversal({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CENT SUPREME',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFD4AF37), // Royal Gold
        scaffoldBackgroundColor: const Color(0xFF000000), // Deep Space Black
        fontFamily: 'sans-serif',
        splashColor: const Color(0xFFD4AF37).withOpacity(0.1),
      ),
      home: const ApplicationCore(),
    );
  }
}

// --- MAIN APPLICATION CORE ---
class ApplicationCore extends StatefulWidget {
  const ApplicationCore({super.key});
  @override
  State<ApplicationCore> createState() => _ApplicationCoreState();
}

class _ApplicationCoreState extends State<ApplicationCore> with TickerProviderStateMixin {
  int _currentTabIndex = 0;
  final AudioPlayer _audioEngine = AudioPlayer();
  final YoutubeExplode _ytEngine = YoutubeExplode();
  
  Video? _activeVideo;
  bool _isEngineBusy = false;
  
  // Smart Memory Systems
  final List<Video> _favoriteVault = [];
  final List<Video> _sessionHistory = [];
  
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  // --- THE INVINCIBLE AUDIO STREAMING ENGINE ---
  Future<void> _executePlaybackProtocol(Video video) async {
    if (_activeVideo?.id == video.id && _audioEngine.playing) return;
    
    setState(() {
      _activeVideo = video;
      _isEngineBusy = true;
      if (!_sessionHistory.contains(video)) {
        _sessionHistory.insert(0, video);
      }
    });

    try {
      var manifest = await _ytEngine.videos.streamsClient.getManifest(video.id);
      var audioStream = manifest.audioOnly.withHighestBitrate();
      
      // Building professional MediaItem for background control
      final playlist = ConcatenatingAudioSource(
        children: [
          AudioSource.uri(
            Uri.parse(audioStream.url.toString()),
            tag: MediaItem(
              id: video.id.value,
              album: video.author,
              title: video.title,
              artUri: Uri.parse(video.thumbnails.highResUrl),
            ),
          ),
        ],
      );

      await _audioEngine.setAudioSource(playlist);
      _audioEngine.play();
      
      setState(() => _isEngineBusy = false);
    } catch (e) {
      setState(() => _isEngineBusy = false);
      _triggerSystemAlert("SIGNAL ERROR: RE-ROUTING DATA...");
    }
  }

  void _triggerSystemAlert(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFFD4AF37),
        content: Text(message, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _toggleVault(Video v) {
    setState(() {
      if (_favoriteVault.any((element) => element.id == v.id)) {
        _favoriteVault.removeWhere((element) => element.id == v.id);
      } else {
        _favoriteVault.add(v);
      }
    });
  }

  @override
  void dispose() {
    _audioEngine.dispose();
    _ytEngine.close();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _galaxyLayers = [
      DiscoveryGalaxy(onPlay: _executePlaybackProtocol, yt: _ytEngine),
      LibraryGalaxy(favs: _favoriteVault, history: _sessionHistory, onPlay: _executePlaybackProtocol),
      const SystemEngineGalaxy(),
    ];

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: _currentTabIndex, children: _galaxyLayers),
          if (_activeVideo != null) _buildSupremeFloatingController(),
        ],
      ),
      bottomNavigationBar: _buildFuturisticNavigation(),
    );
  }

  // --- UI COMPONENTS ---
  Widget _buildFuturisticNavigation() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05), width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navIconBuilder(Icons.explore_rounded, "DISCOVER", 0),
          _navIconBuilder(Icons.auto_awesome_motion_rounded, "VAULT", 1),
          _navIconBuilder(Icons.vibration_rounded, "ENGINE", 2),
        ],
      ),
    );
  }

  Widget _navIconBuilder(IconData icon, String label, int index) {
    bool isSelected = _currentTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentTabIndex = index),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: isSelected ? 1.0 : 0.3,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? const Color(0xFFD4AF37) : Colors.white, size: 28),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 2, color: isSelected ? const Color(0xFFD4AF37) : Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildSupremeFloatingController() {
    return Positioned(
      bottom: 20, left: 15, right: 15,
      child: GestureDetector(
        onTap: _openFullVisualizerSpace,
        child: Hero(
          tag: 'CENT_MASTER_ART',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(
                height: 85,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    _isEngineBusy 
                      ? const CircularProgressIndicator(color: Color(0xFFD4AF37), strokeWidth: 2)
                      : Container(
                          width: 55, height: 55,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            image: DecorationImage(image: NetworkImage(_activeVideo!.thumbnails.mediumResUrl), fit: BoxFit.cover),
                          ),
                        ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_activeVideo!.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                          const Text("CENT HI-RES PROTOCOL", style: TextStyle(color: Color(0xFFD4AF37), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        ],
                      ),
                    ),
                    StreamBuilder<PlayerState>(
                      stream: _audioEngine.playerStateStream,
                      builder: (context, snap) {
                        bool playing = snap.data?.playing ?? false;
                        return IconButton(
                          icon: Icon(playing ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded, color: const Color(0xFFD4AF37), size: 48),
                          onPressed: () => playing ? _audioEngine.pause() : _audioEngine.play(),
                        );
                      }
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openFullVisualizerSpace() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "CENT_EXPAND",
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (context, anim1, anim2) => FullVisualizerSpace(
        player: _audioEngine, 
        video: _activeVideo!,
        isFav: _favoriteVault.any((v) => v.id == _activeVideo!.id),
        onFavToggle: () => _toggleVault(_activeVideo!),
      ),
    );
  }
}

// --- GALAXY 1: DISCOVERY ---
class DiscoveryGalaxy extends StatefulWidget {
  final Function(Video) onPlay;
  final YoutubeExplode yt;
  const DiscoveryGalaxy({super.key, required this.onPlay, required this.yt});
  @override
  State<DiscoveryGalaxy> createState() => _DiscoveryGalaxyState();
}

class _DiscoveryGalaxyState extends State<DiscoveryGalaxy> {
  final TextEditingController _searchController = TextEditingController();
  List<Video> _searchresults = [];
  bool _searching = false;

  void _initiateSearch(String query) async {
    setState(() => _searching = true);
    var search = await widget.yt.search.search(query);
    setState(() {
      _searchresults = search.toList();
      _searching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          expandedHeight: 250,
          backgroundColor: Colors.black,
          flexibleSpace: FlexibleSpaceBar(
            centerTitle: true,
            title: Text(
              "CENT",
              style: TextStyle(
                color: const Color(0xFFD4AF37),
                letterSpacing: 45,
                fontWeight: FontWeight.w100,
                fontSize: 35,
                shadows: [Shadow(color: const Color(0xFFD4AF37).withOpacity(0.6), blurRadius: 50)],
              ),
            ),
            background: ShaderMask(
              shaderCallback: (rect) => LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.8), Colors.transparent]).createShader(rect),
              blendMode: BlendMode.dstIn,
              child: Container(color: const Color(0xFFD4AF37).withOpacity(0.05)),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: TextField(
                  controller: _searchController,
                  onSubmitted: _initiateSearch,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    hintText: "Summon the Sound...",
                    hintStyle: const TextStyle(color: Colors.white12, letterSpacing: 2),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFD4AF37)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(25),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_searching) const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(25, 0, 25, 180),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, childAspectRatio: 0.7, mainAxisSpacing: 35, crossAxisSpacing: 25,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => _buildGalaxyCard(_searchresults[i]),
              childCount: _searchresults.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGalaxyCard(Video v) {
    return GestureDetector(
      onTap: () => widget.onPlay(v),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.8), blurRadius: 20, offset: const Offset(0, 10))],
                image: DecorationImage(image: NetworkImage(v.thumbnails.highResUrl), fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(height: 15),
          Text(v.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)),
          Text(v.author, style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        ],
      ),
    );
  }
}

// --- GALAXY 2: THE VISUALIZER SPACE ---
class FullVisualizerSpace extends StatelessWidget {
  final AudioPlayer player;
  final Video video;
  final bool isFav;
  final VoidCallback onFavToggle;
  const FullVisualizerSpace({super.key, required this.player, required this.video, required this.isFav, required this.onFavToggle});

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFD4AF37);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: Opacity(opacity: 0.3, child: Image.network(video.thumbnails.highResUrl, fit: BoxFit.cover))),
          BackdropFilter(filter: ImageFilter.blur(sigmaX: 120, sigmaY: 120), child: Container(color: Colors.black.withOpacity(0.85))),
          
          SafeArea(
            child: Column(
              children: [
                _buildSpaceHeader(context),
                const Spacer(),
                _buildRotatingArt(),
                const Spacer(),
                _buildTrackInfo(),
                _buildNeumorphicSlider(gold),
                _buildSpaceControls(gold),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpaceHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.expand_more_rounded, size: 45), onPressed: () => Navigator.pop(context)),
          const Column(
            children: [
              Text("CENT SUPREME", style: TextStyle(letterSpacing: 10, fontSize: 10, fontWeight: FontWeight.w900)),
              Text("ATMOSPHERIC FLIGHT", style: TextStyle(color: Color(0xFFD4AF37), fontSize: 8, fontWeight: FontWeight.bold)),
            ],
          ),
          IconButton(icon: Icon(isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: const Color(0xFFD4AF37), size: 32), onPressed: onFavToggle),
        ],
      ),
    );
  }

  Widget _buildRotatingArt() {
    return Hero(
      tag: 'CENT_MASTER_ART',
      child: Container(
        width: 340, height: 340,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(60),
          boxShadow: [BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.2), blurRadius: 120, spreadRadius: 10)],
          image: DecorationImage(image: NetworkImage(video.thumbnails.highResUrl), fit: BoxFit.cover),
        ),
      ),
    );
  }

  Widget _buildTrackInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          Text(video.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1)),
          const SizedBox(height: 12),
          Text(video.author.toUpperCase(), style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 14, letterSpacing: 6, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildNeumorphicSlider(Color g) {
    return StreamBuilder<Duration>(
      stream: player.positionStream,
      builder: (context, snap) {
        final pos = snap.data ?? Duration.zero;
        final dur = player.duration ?? Duration.zero;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
          child: Column(
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(trackHeight: 4, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8), overlayShape: const RoundSliderOverlayShape(overlayRadius: 20)),
                child: Slider(
                  activeColor: g, inactiveColor: Colors.white.withOpacity(0.1),
                  value: pos.inSeconds.toDouble(),
                  max: dur.inSeconds.toDouble() > 0 ? dur.inSeconds.toDouble() : 1.0,
                  onChanged: (v) => player.seek(Duration(seconds: v.toInt())),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_fmt(pos), style: const TextStyle(color: Colors.white24, fontSize: 12, fontWeight: FontWeight.bold)),
                  Text(_fmt(dur), style: const TextStyle(color: Colors.white24, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildSpaceControls(Color g) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.shuffle_rounded, color: Colors.white24, size: 28),
        const SizedBox(width: 35),
        const Icon(Icons.skip_previous_rounded, size: 65),
        const SizedBox(width: 20),
        StreamBuilder<PlayerState>(
          stream: player.playerStateStream,
          builder: (context, snap) {
            bool p = snap.data?.playing ?? false;
            return GestureDetector(
              onTap: () => p ? player.pause() : player.play(),
              child: Container(
                width: 110, height: 110,
                decoration: BoxDecoration(color: g, shape: BoxShape.circle, boxShadow: [BoxShadow(color: g.withOpacity(0.4), blurRadius: 50)]),
                child: Icon(p ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.black, size: 70),
              ),
            );
          },
        ),
        const SizedBox(width: 20),
        const Icon(Icons.skip_next_rounded, size: 65),
        const SizedBox(width: 35),
        const Icon(Icons.repeat_rounded, color: Colors.white24, size: 28),
      ],
    );
  }

  String _fmt(Duration d) => "${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(
