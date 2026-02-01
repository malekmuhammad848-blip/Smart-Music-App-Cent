import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const CentSupremeApp());
}

class CentSupremeApp extends StatelessWidget {
  const CentSupremeApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFD4AF37),
        scaffoldBackgroundColor: const Color(0xFF050505),
      ),
      home: const SupremeArchitecture(),
    );
  }
}

class SupremeArchitecture extends StatefulWidget {
  const SupremeArchitecture({super.key});
  @override
  State<SupremeArchitecture> createState() => _SupremeArchitectureState();
}

class _SupremeArchitectureState extends State<SupremeArchitecture> {
  int _activeTab = 0;
  final AudioPlayer _audioEngine = AudioPlayer();
  final YoutubeExplode _ytEngine = YoutubeExplode();
  Video? _activeTrack;
  bool _isConnecting = false;
  
  final List<Video> _userVault = [];
  final List<Video> _userHistory = [];

  Future<void> _fireEngine(Video track) async {
    if (_activeTrack?.id == track.id && _audioEngine.playing) return;
    
    setState(() {
      _activeTrack = track;
      _isConnecting = true;
      if (!_userHistory.any((e) => e.id == track.id)) _userHistory.insert(0, track);
    });

    try {
      var manifest = await _ytEngine.videos.streamsClient.getManifest(track.id);
      var stream = manifest.audioOnly.withHighestBitrate();
      
      await _audioEngine.stop();
      await _audioEngine.setAudioSource(
        AudioSource.uri(Uri.parse(stream.url.toString())),
        preload: true,
      );
      _audioEngine.play();
    } catch (e) {
      _showError("SIGNAL_LOST: $e");
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _audioEngine.dispose();
    _ytEngine.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _layers = [
      DiscoveryLayer(yt: _ytEngine, onSelect: _fireEngine),
      VaultLayer(vault: _userVault, history: _userHistory, onSelect: _fireEngine),
      const EngineStatusLayer(),
    ];

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: _activeTab, children: _layers),
          if (_activeTrack != null) _buildSupremeConsole(),
        ],
      ),
      bottomNavigationBar: _buildImperialNav(),
    );
  }

  Widget _buildImperialNav() {
    return Container(
      height: 110,
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Colors.white12, width: 0.5)),
      ),
      child: BottomNavigationBar(
        currentIndex: _activeTab,
        onTap: (i) => setState(() => _activeTab = i),
        backgroundColor: Colors.transparent,
        selectedItemColor: const Color(0xFFD4AF37),
        unselectedItemColor: Colors.white24,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'HOME'),
          BottomNavigationBarItem(icon: Icon(Icons.library_music_rounded), label: 'VAULT'),
          BottomNavigationBarItem(icon: Icon(Icons.radar_rounded), label: 'CORE'),
        ],
      ),
    );
  }

  Widget _buildSupremeConsole() {
    return Positioned(
      bottom: 20, left: 15, right: 15,
      child: GestureDetector(
        onTap: _openVisualizer,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(
              height: 90,
              color: Colors.white.withOpacity(0.08),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _isConnecting 
                    ? const SpinKitDoubleBounce(color: Color(0xFFD4AF37), size: 40)
                    : CircleAvatar(backgroundImage: NetworkImage(_activeTrack!.thumbnails.mediumResUrl), radius: 28),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_activeTrack!.title, maxLines: 1, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                        Text(_activeTrack!.author, style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  StreamBuilder<PlayerState>(
                    stream: _audioEngine.playerStateStream,
                    builder: (context, snap) {
                      bool isP = snap.data?.playing ?? false;
                      return IconButton(
                        icon: Icon(isP ? Icons.pause_circle_filled : Icons.play_circle_filled, color: const Color(0xFFD4AF37), size: 50),
                        onPressed: () => isP ? _audioEngine.pause() : _audioEngine.play(),
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

  void _openVisualizer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FullVisualizer(
        player: _audioEngine,
        video: _activeTrack!,
        isFav: _userVault.any((v) => v.id == _activeTrack!.id),
        onFav: () => setState(() {
          if (_userVault.any((v) => v.id == _activeTrack!.id)) {
            _userVault.removeWhere((v) => v.id == _activeTrack!.id);
          } else {
            _userVault.add(_activeTrack!);
          }
        }),
      ),
    );
  }
}

class DiscoveryLayer extends StatefulWidget {
  final YoutubeExplode yt;
  final Function(Video) onSelect;
  const DiscoveryLayer({super.key, required this.yt, required this.onSelect});
  @override
  State<DiscoveryLayer> createState() => _DiscoveryLayerState();
}

class _DiscoveryLayerState extends State<DiscoveryLayer> {
  final TextEditingController _search = TextEditingController();
  List<Video> _trending = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initFetch();
  }

  void _initFetch() async {
    try {
      var search = await widget.yt.search.search("top global hits 2026", filter: TypeFilters.video);
      if (mounted) setState(() { _trending = search.toList(); _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _doSearch(String q) async {
    setState(() => _loading = true);
    var search = await widget.yt.search.search(q);
    setState(() { _trending = search.toList(); _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          expandedHeight: 250, pinned: true, backgroundColor: Colors.black,
          flexibleSpace: FlexibleSpaceBar(
            centerTitle: true,
            title: const Text("C E N T", style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.w900, letterSpacing: 10)),
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF202020), Colors.black]),
              ),
              child: const Icon(Icons.vibration_rounded, color: Colors.white10, size: 200),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: TextField(
              controller: _search, onSubmitted: _doSearch,
              decoration: InputDecoration(
                filled: true, fillColor: Colors.white.withOpacity(0.05),
                hintText: "Enter the frequency...",
                prefixIcon: const Icon(Icons.search, color: Color(0xFFD4AF37)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
              ),
            ),
          ),
        ),
        if (_loading) const SliverToBoxAdapter(child: Center(child: SpinKitPulse(color: Color(0xFFD4AF37)))),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 150),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, childAspectRatio: 0.68, mainAxisSpacing: 25, crossAxisSpacing: 20,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => _buildCard(_trending[i]),
              childCount: _trending.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(Video v) {
    return GestureDetector(
      onTap: () => widget.onSelect(v),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(35),
                image: DecorationImage(image: CachedNetworkImageProvider(v.thumbnails.highResUrl), fit: BoxFit.cover),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5))],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(v.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Text(v.author, style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class FullVisualizer extends StatelessWidget {
  final AudioPlayer player;
  final Video video;
  final bool isFav;
  final VoidCallback onFav;
  const FullVisualizer({super.key, required this.player, required this.video, required this.isFav, required this.onFav});

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFD4AF37);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: Opacity(opacity: 0.2, child: Image.network(video.thumbnails.highResUrl, fit: BoxFit.cover))),
          BackdropFilter(filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100), child: Container(color: Colors.black.withOpacity(0.8))),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 45), onPressed: () => Navigator.pop(context)),
                      const Text("CENT SUPREME SIGNAL", style: TextStyle(letterSpacing: 5, fontSize: 10, fontWeight: FontWeight.w900)),
                      IconButton(icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: gold, size: 30), onPressed: onFav),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  width: 320, height: 320,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    image: DecorationImage(image: CachedNetworkImageProvider(video.thumbnails.highResUrl), fit: BoxFit.cover),
                    boxShadow: [BoxShadow(color: gold.withOpacity(0.3), blurRadius: 100, spreadRadius: 2)],
                  ),
                ),
                const Spacer(),
                Text(video.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                Text(video.author.toUpperCase(), style: const TextStyle(color: gold, letterSpacing: 8, fontSize: 14, fontWeight: FontWeight.bold)),
                const Spacer(),
                _buildProgress(player, gold),
                _buildControls(player, gold),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress(AudioPlayer p, Color g) {
    return StreamBuilder<Duration>(
      stream: p.positionStream,
      builder: (context, snap) {
        final pos = snap.data ?? Duration.zero;
        final dur = p.duration ?? Duration.zero;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Slider(
            activeColor: g, inactiveColor: Colors.white12,
            value: pos.inSeconds.toDouble(),
            max: dur.inSeconds.toDouble() > 0 ? dur.inSeconds.toDouble() : 1.0,
            onChanged: (v) => p.seek(Duration(seconds: v.toInt())),
          ),
        );
      },
    );
  }

  Widget _buildControls(AudioPlayer p, Color g) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(icon: const Icon(Icons.skip_previous_rounded, size: 50), onPressed: () {}),
        const SizedBox(width: 30),
        StreamBuilder<PlayerState>(
          stream: p.playerStateStream,
          builder: (context, snap) {
            bool isP = snap.data?.playing ?? false;
            return GestureDetector(
              onTap: () => isP ? p.pause() : p.play(),
              child: Container(
                width: 90, height: 90,
                decoration: BoxDecoration(color: g, shape: BoxShape.circle),
                child: Icon(isP ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.black, size: 60),
              ),
            );
          },
        ),
        const SizedBox(width: 30),
        IconButton(icon: const Icon(Icons.skip_next_rounded, size: 50), onPressed: () {}),
      ],
    );
  }
}

class VaultLayer extends StatelessWidget {
  final List<Video> vault;
  final List<Video> history;
  final Function(Video) onSelect;
  const VaultLayer({super.key, required this.vault, required this.history, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      children: [
        const SizedBox(height: 80),
        const Text("VAULT ARCHIVE", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w100, letterSpacing: 10)),
        const SizedBox(height: 40),
        _section("FAVORITES", vault),
        const SizedBox(height: 40),
        _section("NEURAL HISTORY", history),
      ],
    );
  }

  Widget _section(String title, List<Video> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, letterSpacing: 4, fontSize: 12)),
        const SizedBox(height: 20),
        if (list.isEmpty) const Text("DATABASE EMPTY", style: TextStyle(color: Colors.white10, fontSize: 10)),
        ...list.map((v) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(v.thumbnails.lowResUrl)),
          title: Text(v.title, maxLines: 1, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          onTap: () => onSelect(v),
        )),
      ],
    );
  }
}

class EngineStatusLayer extends StatelessWidget {
  const EngineStatusLayer({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SpinKitPulse(color: Color(0xFFD4AF37), size: 100),
          SizedBox(height: 30),
          Text("CORE ENGINE ACTIVE", style: TextStyle(letterSpacing: 10, fontWeight: FontWeight.w100)),
        ],
      ),
    );
  }
}
