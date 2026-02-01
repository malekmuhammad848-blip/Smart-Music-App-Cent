import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:ui';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.black,
      statusBarIconTheme: Brightness.light,
    ),
  );
  runApp(const CentGlobalApp());
}

class CentGlobalApp extends StatelessWidget {
  const CentGlobalApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFD4AF37),
        scaffoldBackgroundColor: const Color(0xFF000000),
      ),
      home: const ApplicationUniverse(),
    );
  }
}

class ApplicationUniverse extends StatefulWidget {
  const ApplicationUniverse({super.key});
  @override
  State<ApplicationUniverse> createState() => _ApplicationUniverseState();
}

class _ApplicationUniverseState extends State<ApplicationUniverse> {
  int _activeTab = 0;
  final AudioPlayer _audioEngine = AudioPlayer();
  final YoutubeExplode _ytEngine = YoutubeExplode();
  
  Video? _selectedTrack;
  bool _isEngineLoading = false;
  final List<Video> _smartLibrary = [];
  final List<Video> _history = [];

  // --- SUPREME AUDIO FLOW CONTROL ---
  Future<void> _launchAudioStream(Video video) async {
    if (_selectedTrack?.id == video.id && _audioEngine.playing) return;
    
    setState(() {
      _selectedTrack = video;
      _isEngineLoading = true;
      if (!_history.contains(video)) _history.insert(0, video);
    });

    try {
      var manifest = await _ytEngine.videos.streamsClient.getManifest(video.id);
      var streamInfo = manifest.audioOnly.withHighestBitrate();
      
      await _audioEngine.setAudioSource(
        AudioSource.uri(
          Uri.parse(streamInfo.url.toString()),
          tag: video.title,
        ),
      );
      
      _audioEngine.play();
      setState(() => _isEngineLoading = false);
    } catch (e) {
      setState(() => _isEngineLoading = false);
      _triggerAlert("Network instability detected. Optimizing stream...");
    }
  }

  void _triggerAlert(String m) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: const Color(0xFFD4AF37).withOpacity(0.8)),
    );
  }

  @override
  void dispose() {
    _audioEngine.dispose();
    _ytEngine.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _galaxyPages = [
      DiscoveryGalaxy(onPlay: _launchAudioStream, yt: _ytEngine),
      SmartLibraryGalaxy(favs: _smartLibrary, history: _history, onPlay: _launchAudioStream),
      const EngineGalaxy(),
    ];

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: _activeTab, children: _galaxyPages),
          if (_selectedTrack != null) _buildUniversalMiniPlayer(),
        ],
      ),
      bottomNavigationBar: _buildModernSystemNav(),
    );
  }

  Widget _buildModernSystemNav() {
    return Container(
      height: 95,
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navCore(Icons.bubble_chart_outlined, 0),
          _navCore(Icons.auto_awesome_motion_rounded, 1),
          _navCore(Icons.vibration_rounded, 2),
        ],
      ),
    );
  }

  Widget _navCore(IconData icon, int i) {
    bool active = _activeTab == i;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = i),
      child: AnimatedScale(
        scale: active ? 1.2 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: Icon(icon, color: active ? const Color(0xFFD4AF37) : Colors.white24, size: 30),
      ),
    );
  }

  Widget _buildUniversalMiniPlayer() {
    return Positioned(
      bottom: 20, left: 10, right: 10,
      child: GestureDetector(
        onTap: _openVisualSpace,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
            child: Container(
              height: 85,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  _isEngineLoading 
                    ? const CircularProgressIndicator(color: Color(0xFFD4AF37))
                    : CircleAvatar(backgroundImage: NetworkImage(_selectedTrack!.thumbnails.mediumResUrl), radius: 28),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_selectedTrack!.title, maxLines: 1, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                        const Text("MASTER QUALITY • 320KBPS", style: TextStyle(color: Color(0xFFD4AF37), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ],
                    ),
                  ),
                  StreamBuilder<PlayerState>(
                    stream: _audioEngine.playerStateStream,
                    builder: (context, snap) {
                      bool p = snap.data?.playing ?? false;
                      return IconButton(
                        icon: Icon(p ? Icons.pause_circle_filled : Icons.play_circle_filled, color: const Color(0xFFD4AF37), size: 50),
                        onPressed: () => p ? _audioEngine.pause() : _audioEngine.play(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openVisualSpace() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VisualSpaceUI(
        player: _audioEngine, 
        video: _selectedTrack!,
        onFavToggle: () {
          setState(() {
            if (_smartLibrary.contains(_selectedTrack)) {
              _smartLibrary.remove(_selectedTrack);
            } else {
              _smartLibrary.add(_selectedTrack!);
            }
          });
        },
        isFav: _smartLibrary.contains(_selectedTrack),
      ),
    );
  }
}

// --- DISCOVERY GALAXY ---
class DiscoveryGalaxy extends StatefulWidget {
  final Function(Video) onPlay;
  final YoutubeExplode yt;
  const DiscoveryGalaxy({super.key, required this.onPlay, required this.yt});
  @override
  State<DiscoveryGalaxy> createState() => _DiscoveryGalaxyState();
}

class _DiscoveryGalaxyState extends State<DiscoveryGalaxy> {
  final TextEditingController _controller = TextEditingController();
  List<Video> _streamResults = [];
  bool _searching = false;

  void _searchInternal(String val) async {
    setState(() => _searching = true);
    var search = await widget.yt.search.search(val);
    setState(() {
      _streamResults = search.toList();
      _searching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
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
                letterSpacing: 45,
                fontWeight: FontWeight.w100,
                fontSize: 30,
                shadows: [Shadow(color: const Color(0xFFD4AF37).withOpacity(0.5), blurRadius: 40)],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: TextField(
              controller: _controller,
              onSubmitted: _searchInternal,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                hintText: "Summon the sound...",
                prefixIcon: const Icon(Icons.blur_on_rounded, color: Color(0xFFD4AF37)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(40), borderSide: BorderSide.none),
              ),
            ),
          ),
        ),
        if (_searching) const SliverToBoxAdapter(child: LinearProgressIndicator(color: Color(0xFFD4AF37))),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 150),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, childAspectRatio: 0.75, mainAxisSpacing: 30, crossAxisSpacing: 20,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => _itemCard(_streamResults[i]),
              childCount: _streamResults.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _itemCard(Video v) {
    return GestureDetector(
      onTap: () => widget.onPlay(v),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(45),
                image: DecorationImage(image: NetworkImage(v.thumbnails.highResUrl), fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(v.title, maxLines: 1, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Text(v.author, style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 10, letterSpacing: 2)),
        ],
      ),
    );
  }
}

// --- VISUAL SPACE UI (The Visualizer) ---
class VisualSpaceUI extends StatelessWidget {
  final AudioPlayer player;
  final Video video;
  final VoidCallback onFavToggle;
  final bool isFav;
  const VisualSpaceUI({super.key, required this.player, required this.video, required this.onFavToggle, required this.isFav});

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFD4AF37);
    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: const BoxDecoration(color: Colors.black),
      child: Stack(
        children: [
          Positioned.fill(child: Opacity(opacity: 0.3, child: Image.network(video.thumbnails.highResUrl, fit: BoxFit.cover))),
          BackdropFilter(filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100), child: Container(color: Colors.black.withOpacity(0.8))),
          Column(
            children: [
              const SizedBox(height: 60),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(icon: const Icon(Icons.keyboard_arrow_down, size: 45), onPressed: () => Navigator.pop(context)),
                    const Text("CENT SUPREME PROTOCOL", style: TextStyle(letterSpacing: 4, fontSize: 10, fontWeight: FontWeight.w900)),
                    IconButton(icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: gold, size: 30), onPressed: onFavToggle),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                width: 320, height: 320,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(60),
                  boxShadow: [BoxShadow(color: gold.withOpacity(0.2), blurRadius: 100)],
                  image: DecorationImage(image: NetworkImage(video.thumbnails.highResUrl), fit: BoxFit.cover),
                ),
              ),
              const Spacer(),
              Text(video.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              Text(video.author.toUpperCase(), style: const TextStyle(color: gold, letterSpacing: 5, fontSize: 12, fontWeight: FontWeight.bold)),
              const Spacer(),
              _streamSlider(player, gold),
              _controls(player, gold),
              const Spacer(flex: 2),
            ],
          ),
        ],
      ),
    );
  }

  Widget _streamSlider(AudioPlayer p, Color g) {
    return StreamBuilder<Duration>(
      stream: p.positionStream,
      builder: (context, snap) {
        final pos = snap.data ?? Duration.zero;
        final dur = p.duration ?? Duration.zero;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Slider(
            activeColor: g, inactiveColor: Colors.white10,
            value: pos.inSeconds.toDouble(),
            max: dur.inSeconds.toDouble() > 0 ? dur.inSeconds.toDouble() : 1.0,
            onChanged: (v) => p.seek(Duration(seconds: v.toInt())),
          ),
        );
      },
    );
  }

  Widget _controls(AudioPlayer p, Color g) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.skip_previous_rounded, size: 60),
        const SizedBox(width: 20),
        StreamBuilder<PlayerState>(
          stream: p.playerStateStream,
          builder: (context, snap) {
            bool playing = snap.data?.playing ?? false;
            return GestureDetector(
              onTap: () => playing ? p.pause() : p.play(),
              child: Container(
                width: 90, height: 90,
                decoration: BoxDecoration(color: g, shape: BoxShape.circle, boxShadow: [BoxShadow(color: g.withOpacity(0.4), blurRadius: 40)]),
                child: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.black, size: 60),
              ),
            );
          },
        ),
        const SizedBox(width: 20),
        const Icon(Icons.skip_next_rounded, size: 60),
      ],
    );
  }
}

// --- SMART LIBRARY GALAXY ---
class SmartLibraryGalaxy extends StatelessWidget {
  final List<Video> favs;
  final List<Video> history;
  final Function(Video) onPlay;
  const SmartLibraryGalaxy({super.key, required this.favs, required this.history, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          const SizedBox(height: 80),
          const Text("NEURAL PLAYLISTS", style: TextStyle(letterSpacing: 5, fontWeight: FontWeight.w100, fontSize: 24)),
          const SizedBox(height: 30),
          _smartCard("SMART EVOLUTION", Icons.auto_awesome),
          _smartCard("GLOBAL TOP 50", Icons.public),
          const SizedBox(height: 40),
          const Text("HISTORY", style: TextStyle(letterSpacing: 10, fontSize: 12, color: Color(0xFFD4AF37))),
          ...history.map((v) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(v.thumbnails.lowResUrl)),
            title: Text(v.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            onTap: () => onPlay(v),
          )),
        ],
      ),
    );
  }

  Widget _smartCard(String t, IconData i) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(t, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
          Icon(i, color: const Color(0xFFD4AF37)),
        ],
      ),
    );
  }
}

// --- ENGINE GALAXY ---
class EngineGalaxy extends StatelessWidget {
  const EngineGalaxy({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.vibration_rounded, color: Color(0xFFD4AF37), size: 100),
            SizedBox(height: 20),
            Text("CENT GLOBAL CORE", style: TextStyle(letterSpacing: 20, fontWeight: FontWeight.w100)),
            Text("ACTIVE STATUS: UNIVERSAL", style: TextStyle(color: Colors.white24, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
