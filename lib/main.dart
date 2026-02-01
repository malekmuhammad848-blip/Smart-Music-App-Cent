import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:ui';
import 'dart:async';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.black,
      statusBarIconTheme: Brightness.light,
    ),
  );
  runApp(const CentEmpireApp());
}

class CentEmpireApp extends StatelessWidget {
  const CentEmpireApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFD4AF37),
        scaffoldBackgroundColor: const Color(0xFF000000),
        fontFamily: 'sans-serif',
      ),
      home: const MainSystemNavigator(),
    );
  }
}

class MainSystemNavigator extends StatefulWidget {
  const MainSystemNavigator({super.key});
  @override
  State<MainSystemNavigator> createState() => _MainSystemNavigatorState();
}

class _MainSystemNavigatorState extends State<MainSystemNavigator> {
  int _activePageIndex = 0;
  final AudioPlayer _audioCore = AudioPlayer();
  final YoutubeExplode _ytCore = YoutubeExplode();
  
  Video? _currentActiveTrack;
  bool _isEngineProcessing = false;
  final List<Video> _imperialFavorites = [];
  final List<Video> _listeningHistory = [];

  // --- THE ULTIMATE AUDIO PROTOCOL ---
  Future<void> _initiateAudioStream(Video video) async {
    if (_currentActiveTrack?.id == video.id && _audioCore.playing) return;
    
    setState(() {
      _currentActiveTrack = video;
      _isEngineProcessing = true;
      if (!_listeningHistory.contains(video)) _listeningHistory.insert(0, video);
    });

    try {
      var manifest = await _ytCore.videos.streamsClient.getManifest(video.id);
      var streamInfo = manifest.audioOnly.withHighestBitrate();
      
      // Advanced source configuration for maximum stability
      await _audioCore.setAudioSource(
        AudioSource.uri(
          Uri.parse(streamInfo.url.toString()),
          tag: video.title,
        ),
        preload: true,
      );
      
      _audioCore.play();
      setState(() => _isEngineProcessing = false);
    } catch (e) {
      setState(() => _isEngineProcessing = false);
      _showSystemToast("Connection Re-routing...");
    }
  }

  void _showSystemToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: const Color(0xFFD4AF37), content: Text(msg, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
    );
  }

  void _manageFavorites(Video v) {
    setState(() {
      if (_imperialFavorites.any((e) => e.id == v.id)) {
        _imperialFavorites.removeWhere((e) => e.id == v.id);
      } else {
        _imperialFavorites.add(v);
      }
    });
  }

  @override
  void dispose() {
    _audioCore.dispose();
    _ytCore.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _systemPages = [
      ImperialDiscovery(onPlay: _initiateAudioStream, yt: _ytCore),
      ImperialLibrary(favs: _imperialFavorites, history: _listeningHistory, onPlay: _initiateAudioStream),
      const ImperialEngineSettings(),
    ];

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: _activePageIndex, children: _systemPages),
          if (_currentActiveTrack != null) _buildFloatingControlPanel(),
        ],
      ),
      bottomNavigationBar: _buildFuturisticNavBar(),
    );
  }

  Widget _buildFuturisticNavBar() {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navCoreBtn(Icons.auto_awesome_mosaic_rounded, 0),
          _navCoreBtn(Icons.favorite_rounded, 1),
          _navCoreBtn(Icons.settings_input_component_rounded, 2),
        ],
      ),
    );
  }

  Widget _navCoreBtn(IconData icon, int index) {
    bool isSelected = _activePageIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _activePageIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD4AF37).withOpacity(0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, color: isSelected ? const Color(0xFFD4AF37) : Colors.white24, size: 30),
      ),
    );
  }

  Widget _buildFloatingControlPanel() {
    return Positioned(
      bottom: 25, left: 15, right: 15,
      child: GestureDetector(
        onTap: _launchFullVisualizer,
        child: Hero(
          tag: 'master_art',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(
                height: 80,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 55, height: 55,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        image: DecorationImage(image: NetworkImage(_currentActiveTrack!.thumbnails.mediumResUrl), fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_currentActiveTrack!.title, maxLines: 1, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                          const Text("CENT SUPREME AUDIO • ACTIVE", style: TextStyle(color: Color(0xFFD4AF37), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        ],
                      ),
                    ),
                    _isEngineProcessing 
                      ? const SizedBox(width: 25, height: 25, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD4AF37)))
                      : StreamBuilder<PlayerState>(
                          stream: _audioCore.playerStateStream,
                          builder: (context, snap) {
                            bool isPlaying = snap.data?.playing ?? false;
                            return IconButton(
                              icon: Icon(isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded, color: const Color(0xFFD4AF37), size: 48),
                              onPressed: () => isPlaying ? _audioCore.pause() : _audioCore.play(),
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

  void _launchFullVisualizer() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "CENT_FULL",
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, a1, a2) => FullImperialVisualizer(
        player: _audioCore, 
        video: _currentActiveTrack!,
        isFav: _imperialFavorites.any((v) => v.id == _currentActiveTrack!.id),
        onFavToggle: () => _manageFavorites(_currentActiveTrack!),
      ),
    );
  }
}

// --- IMPERIAL DISCOVERY VIEW ---
class ImperialDiscovery extends StatefulWidget {
  final Function(Video) onPlay;
  final YoutubeExplode yt;
  const ImperialDiscovery({super.key, required this.onPlay, required this.yt});
  @override
  State<ImperialDiscovery> createState() => _ImperialDiscoveryState();
}

class _ImperialDiscoveryState extends State<ImperialDiscovery> {
  final TextEditingController _searchBox = TextEditingController();
  List<Video> _results = [];
  bool _isBusy = false;

  void _performSearch(String q) async {
    setState(() => _isBusy = true);
    var search = await widget.yt.search.search(q);
    setState(() {
      _results = search.toList();
      _isBusy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          expandedHeight: 220,
          backgroundColor: Colors.black,
          flexibleSpace: FlexibleSpaceBar(
            centerTitle: true,
            title: Text(
              "CENT",
              style: TextStyle(
                color: const Color(0xFFD4AF37),
                letterSpacing: 45, // THE ELITE SPACING
                fontWeight: FontWeight.w100,
                fontSize: 32,
                shadows: [Shadow(color: const Color(0xFFD4AF37).withOpacity(0.5), blurRadius: 40)],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 25),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: TextField(
                  controller: _searchBox,
                  onSubmitted: _performSearch,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    hintText: "Enter the soundscape...",
                    hintStyle: const TextStyle(color: Colors.white24, letterSpacing: 1),
                    prefixIcon: const Icon(Icons.blur_on_rounded, color: Color(0xFFD4AF37)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(22),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_isBusy) const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(25, 0, 25, 150),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, childAspectRatio: 0.72, mainAxisSpacing: 30, crossAxisSpacing: 25,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => _buildTrackTile(_results[i]),
              childCount: _results.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrackTile(Video v) {
    return GestureDetector(
      onTap: () => widget.onPlay(v),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(45),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 15, offset: const Offset(0, 8))],
                image: DecorationImage(image: NetworkImage(v.thumbnails.highResUrl), fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(height: 15),
          Text(v.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
          Text(v.author, style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ],
      ),
    );
  }
}

// --- FULL IMPERIAL VISUALIZER ---
class FullImperialVisualizer extends StatelessWidget {
  final AudioPlayer player;
  final Video video;
  final bool isFav;
  final VoidCallback onFavToggle;
  const FullImperialVisualizer({super.key, required this.player, required this.video, required this.isFav, required this.onFavToggle});

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFD4AF37);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: Opacity(opacity: 0.25, child: Image.network(video.thumbnails.highResUrl, fit: BoxFit.cover))),
          BackdropFilter(filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100), child: Container(color: Colors.black.withOpacity(0.8))),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 15),
                _buildHeader(context),
                const Spacer(),
                _buildArt(),
                const Spacer(),
                _buildMeta(),
                _buildProgressBar(gold),
                _buildControls(gold),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 45), onPressed: () => Navigator.pop(context)),
          const Column(
            children: [
              Text("CENT SUPREME", style: TextStyle(letterSpacing: 8, fontSize: 10, fontWeight: FontWeight.w900)),
              Text("LOSSLESS AUDIO ENGINE", style: TextStyle(color: Color(0xFFD4AF37), fontSize: 8, fontWeight: FontWeight.bold)),
            ],
          ),
          IconButton(icon: Icon(isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: const Color(0xFFD4AF37), size: 30), onPressed: onFavToggle),
        ],
      ),
    );
  }

  Widget _buildArt() {
    return Hero(
      tag: 'master_art',
      child: Container(
        width: 320, height: 320,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(60),
          boxShadow: [BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.3), blurRadius: 100, spreadRadius: 5)],
          image: DecorationImage(image: NetworkImage(video.thumbnails.highResUrl), fit: BoxFit.cover),
        ),
      ),
    );
  }

  Widget _buildMeta() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 45),
      child: Column(
        children: [
          Text(video.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          const SizedBox(height: 12),
          Text(video.author.toUpperCase(), style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 14, letterSpacing: 5, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildProgressBar(Color g) {
    return StreamBuilder<Duration>(
      stream: player.positionStream,
      builder: (context, snap) {
        final pos = snap.data ?? Duration.zero;
        final dur = player.duration ?? Duration.zero;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
          child: Column(
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(trackHeight: 2, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6)),
                child: Slider(
                  activeColor: g, inactiveColor: Colors.white10,
                  value: pos.inSeconds.toDouble(),
                  max: dur.inSeconds.toDouble() > 0 ? dur.inSeconds.toDouble() : 1.0,
                  onChanged: (v) => player.seek(Duration(seconds: v.toInt())),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDur(pos), style: const TextStyle(color: Colors.white24, fontSize: 12, fontWeight: FontWeight.bold)),
                  Text(_formatDur(dur), style: const TextStyle(color: Colors.white24, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildControls(Color g) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.shuffle_rounded, color: Colors.white10, size: 28),
        const SizedBox(width: 30),
        const Icon(Icons.skip_previous_rounded, size: 60),
        const SizedBox(width: 25),
        StreamBuilder<PlayerState>(
          stream: player.playerStateStream,
          builder: (context, snap) {
            bool isP = snap.data?.playing ?? false;
            return GestureDetector(
              onTap: () => isP ? player.pause() : player.play(),
              child: Container(
                width: 95, height: 95,
                decoration: BoxDecoration(color: g, shape: BoxShape.circle, boxShadow: [BoxShadow(color: g.withOpacity(0.5), blurRadius: 40)]),
                child: Icon(isP ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.black, size: 60),
              ),
            );
          },
        ),
        const SizedBox(width: 25),
        const Icon(Icons.skip_next_rounded, size: 60),
        const SizedBox(width: 30),
        const Icon(Icons.repeat_one_rounded, color: Colors.white10, size: 28),
      ],
    );
  }

  String _formatDur(Duration d) => "${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}";
}

// --- IMPERIAL LIBRARY VIEW ---
class ImperialLibrary extends StatelessWidget {
  final List<Video> favs;
  final List<Video> history;
  final Function(Video) onPlay;
  const ImperialLibrary({super.key, required this.favs, required this.history, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("IMPERIAL ARCHIVE", style: TextStyle(letterSpacing: 10, fontWeight: FontWeight.w100)), centerTitle: true, backgroundColor: Colors.black),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 150),
        children: [
          const Text("FAVORITES", style: TextStyle(color: Color(0xFFD4AF37), letterSpacing: 5, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 15),
          if (favs.isEmpty) const Text("NO ELITE TRACKS SAVED", style: TextStyle(color: Colors.white10, fontSize: 10)),
          ...favs.map((v) => _trackItem(v)),
          const SizedBox(height: 40),
          const Text("RECENT SESSIONS", style: TextStyle(color: Color(0xFFD4AF37), letterSpacing: 5, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 15),
          if (history.isEmpty) const Text("HISTORY IS CLEAR", style: TextStyle(color: Colors.white10, fontSize: 10)),
          ...history.map((v) => _trackItem(v)),
        ],
      ),
    );
  }

  Widget _trackItem(Video v) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(v.thumbnails.lowResUrl)),
      title: Text(v.title, maxLines: 1, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      subtitle: Text(v.author, style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 11)),
      onTap: () => onPlay(v),
    );
  }
}

// --- IMPERIAL ENGINE SETTINGS ---
class ImperialEngineSettings extends StatelessWidget {
 
