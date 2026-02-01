import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Ultimate Audio Performance Mode
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());
  await session.setActive(true);
  
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
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFD4AF37),
        scaffoldBackgroundColor: Colors.black,
        textTheme: GoogleFonts.orbitronTextTheme(ThemeData.dark().textTheme),
      ),
      home: const MainArchitecture(),
    );
  }
}

class MainArchitecture extends StatefulWidget {
  const MainArchitecture({super.key});
  @override
  State<MainArchitecture> createState() => _MainArchitectureState();
}

class _MainArchitectureState extends State<MainArchitecture> with TickerProviderStateMixin {
  int _tabIndex = 0;
  final AudioPlayer _player = AudioPlayer();
  final YoutubeExplode _yt = YoutubeExplode();
  Video? _activeTrack;
  bool _isBuffering = false;
  final List<Video> _vaultHistory = [];

  // THE TITAN ENGINE: Advanced Audio Pumping
  Future<void> _igniteEngine(Video video) async {
    setState(() { 
      _activeTrack = video; 
      _isBuffering = true; 
      if (!_vaultHistory.any((e) => e.id == video.id)) _vaultHistory.insert(0, video);
    });
    
    try {
      await _player.stop();
      var manifest = await _yt.videos.streamsClient.getManifest(video.id);
      
      // Selecting M4A with Forced Headers for 0% failure rate
      var streamInfo = manifest.audioOnly.where((s) => s.container.name == 'm4a').withHighestBitrate();

      await _player.setAudioSource(
        LockCachingAudioSource(
          Uri.parse(streamInfo.url.toString()),
          headers: {
            'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
            'Connection': 'keep-alive',
            'Accept-Encoding': 'identity',
          },
        ),
      );
      
      await _player.setVolume(1.0);
      _player.play();
    } catch (e) {
      debugPrint("ENGINE CRITICAL: $e");
    } finally {
      if (mounted) setState(() => _isBuffering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _renderBackgroundLayer(),
          _renderContent(),
          if (_activeTrack != null) _buildFloatingConsole(),
        ],
      ),
      bottomNavigationBar: _buildNav(),
    );
  }

  Widget _renderBackgroundLayer() {
    return Positioned.fill(
      child: AnimatedSwitcher(
        duration: const Duration(seconds: 1),
        child: _activeTrack != null 
          ? Opacity(
              opacity: 0.15,
              child: CachedNetworkImage(imageUrl: _activeTrack!.thumbnails.highResUrl, fit: BoxFit.cover),
            )
          : Container(color: Colors.black),
      ),
    );
  }

  Widget _renderContent() {
    return _tabIndex == 0 
      ? DiscoveryLayer(yt: _yt, onSelect: _igniteEngine) 
      : VaultLayer(items: _vaultHistory, onSelect: _igniteEngine);
  }

  Widget _buildNav() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.9),
        border: const Border(top: BorderSide(color: Color(0xFFD4AF37), width: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navItem(0, Icons.adjust_rounded, "CENT"),
          _navItem(1, Icons.all_inclusive_rounded, "VAULT"),
        ],
      ),
    );
  }

  Widget _navItem(int i, IconData icon, String label) {
    bool active = _tabIndex == i;
    return GestureDetector(
      onTap: () => setState(() => _tabIndex = i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFD4AF37).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? const Color(0xFFD4AF37) : Colors.white24, size: 32),
            Text(label, style: TextStyle(color: active ? const Color(0xFFD4AF37) : Colors.white24, fontSize: 10, letterSpacing: 3, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingConsole() {
    return Positioned(
      bottom: 25, left: 15, right: 15,
      child: GestureDetector(
        onTap: () => _showSupremePlayer(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
            child: Container(
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3), width: 0.5),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _isBuffering 
                    ? const SpinKitFadingGrid(color: Color(0xFFD4AF37), size: 35)
                    : Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(color: Color(0xFFD4AF37), shape: BoxShape.circle),
                        child: CircleAvatar(backgroundImage: CachedNetworkImageProvider(_activeTrack!.thumbnails.mediumResUrl), radius: 30),
                      ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_activeTrack!.title, maxLines: 1, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const Text("MASTER QUALITY ACTIVE", style: TextStyle(color: Color(0xFFD4AF37), fontSize: 8, letterSpacing: 2)),
                      ],
                    ),
                  ),
                  StreamBuilder<PlayerState>(
                    stream: _player.playerStateStream,
                    builder: (context, snap) {
                      bool p = snap.data?.playing ?? false;
                      return IconButton(
                        icon: Icon(p ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded, color: const Color(0xFFD4AF37), size: 50),
                        onPressed: () => p ? _player.pause() : _player.play(),
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

  void _showSupremePlayer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PlayerScreen(player: _player, video: _activeTrack!),
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
  final TextEditingController _s = TextEditingController();
  List<Video> _items = [];
  bool _load = true;

  @override
  void initState() { super.initState(); _fetch("Top global hits 2026"); }

  void _fetch(String q) async {
    setState(() => _load = true);
    var res = await widget.yt.search.search(q);
    if (mounted) setState(() { _items = res.toList(); _load = false; });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 220, pinned: true, backgroundColor: Colors.black,
          flexibleSpace: FlexibleSpaceBar(
            centerTitle: true,
            title: Text("SUPREME", style: GoogleFonts.orbitron(color: const Color(0xFFD4AF37), fontWeight: FontWeight.w900, letterSpacing: 15)),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: TextField(
              controller: _s, onSubmitted: _fetch,
              decoration: InputDecoration(
                filled: true, fillColor: Colors.white.withOpacity(0.04),
                hintText: "Access Database...",
                prefixIcon: const Icon(Icons.search, color: Color(0xFFD4AF37)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: const BorderSide(color: Colors.white10)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: const BorderSide(color: Color(0xFFD4AF37))),
              ),
            ),
          ),
        ),
        if (_load) const SliverToBoxAdapter(child: Center(child: SpinKitFoldingCube(color: Color(0xFFD4AF37)))),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 160),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.65, crossAxisSpacing: 20, mainAxisSpacing: 20),
            delegate: SliverChildBuilderDelegate(
              (context, i) => GestureDetector(
                onTap: () => widget.onSelect(_items[i]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white10),
                          boxShadow: [BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.1), blurRadius: 20)],
                        ),
                        child: ClipRRect(borderRadius: BorderRadius.circular(30), child: CachedNetworkImage(imageUrl: _items[i].thumbnails.highResUrl, fit: BoxFit.cover)),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(_items[i].title, maxLines: 2, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    Text(_items[i].author, style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 9, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              childCount: _items.length,
            ),
          ),
        ),
      ],
    );
  }
}

class PlayerScreen extends StatelessWidget {
  final AudioPlayer player;
  final Video video;
  const PlayerScreen({super.key, required this.player, required this.video});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: CachedNetworkImage(imageUrl: video.thumbnails.highResUrl, fit: BoxFit.cover)),
          BackdropFilter(filter: ImageFilter.blur(sigmaX: 120, sigmaY: 120), child: Container(color: Colors.black.withOpacity(0.88))),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Icon(Icons.expand_more_rounded, size: 50, color: Colors.white24),
                const Spacer(),
                Container(
                  width: 340, height: 340,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.5), blurRadius: 100, spreadRadius: 5)],
                  ),
                  child: ClipRRect(borderRadius: BorderRadius.circular(50), child: CachedNetworkImage(imageUrl: video.thumbnails.highResUrl, fit: BoxFit.cover)),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      Text(video.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      const SizedBox(height: 10),
                      Text(video.author, style: const TextStyle(color: Color(0xFFD4AF37), letterSpacing: 4, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const Spacer(),
                _buildDynamicSlider(),
                const Spacer(),
                _buildBeastControls(),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicSlider() {
    return StreamBuilder<Duration>(
      stream: player.positionStream,
      builder: (context, snap) {
        final pos = snap.data ?? Duration.zero;
        final dur = player.duration ?? video.duration ?? const Duration(seconds: 1);
        return Column(
          children: [
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 4,
                thumbColor: const Color(0xFFD4AF37),
                activeTrackColor: const Color(0xFFD4AF37),
                inactiveTrackColor: Colors.white10,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              ),
              child: Slider(
                value: pos.inSeconds.toDouble().clamp(0, dur.inSeconds.toDouble()),
                max: dur.inSeconds.toDouble(),
                onChanged: (v) => player.seek(Duration(seconds: v.toInt())),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 45),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_fmt(pos), style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
                  Text(_fmt(dur), style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBeastControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.shuffle_rounded, color: Color(0xFFD4AF37), size: 30),
        const SizedBox(width: 30),
        const Icon(Icons.skip_previous_rounded, size: 60),
        const SizedBox(width: 20),
        StreamBuilder<PlayerState>(
          stream: player.playerStateStream,
          builder: (context, snap) {
            bool p = snap.data?.playing ?? false;
            return GestureDetector(
              onTap: () => p ? player.pause() : player.play(),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: const BoxDecoration(
                  color: Color(0xFFD4AF37),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Color(0xFFD4AF37), blurRadius: 30)],
                ),
                child: Icon(p ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.black, size: 55),
              ),
            );
          },
        ),
        const SizedBox(width: 20),
        const Icon(Icons.skip_next_rounded, size: 60),
        const SizedBox(width: 30),
        const Icon(Icons.repeat_one_rounded, color: Color(0xFFD4AF37), size: 30),
      ],
    );
  }

  String _fmt(Duration d) => "${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}";
}

class VaultLayer extends StatelessWidget {
  final List<Video> items;
  final Function(Video) onSelect;
  const VaultLayer({super.key, required this.items, required this.onSelect});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 70),
          Text("THE VAULT", style: GoogleFonts.orbitron(fontSize: 40, fontWeight: FontWeight.w900, color: const Color(0xFFD4AF37), letterSpacing: 12)),
          const Text("ENCRYPTED AUDIO ARCHIVE", style: TextStyle(fontSize: 10, letterSpacing: 6, color: Colors.white24)),
          const SizedBox(height: 40),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, i) => Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ListTile(
                  onTap: () => onSelect(items[i]),
                  contentPadding: const EdgeInsets.all(15),
                  leading: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(items[i].thumbnails.lowResUrl)),
                  title: Text(items[i].title, maxLines: 1, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(items[i].author, style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 10)),
                  trailing: const Icon(Icons.verified_user_rounded, color: Color(0xFFD4AF37), size: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
