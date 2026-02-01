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
  
  // High-Performance Audio Engine Setup
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());
  await session.setActive(true);
  
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
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

  Future<void> _igniteEngine(Video video) async {
    if (mounted) setState(() { 
      _activeTrack = video; 
      _isBuffering = true; 
      if (!_vaultHistory.any((e) => e.id == video.id)) _vaultHistory.insert(0, video);
    });
    
    try {
      await _player.stop();
      var manifest = await _yt.videos.streamsClient.getManifest(video.id);
      var streamInfo = manifest.audioOnly.where((s) => s.container.name == 'm4a').withHighestBitrate();

      // THE BEAST TUNNEL: Bypassing standard buffers for direct execution
      await _player.setAudioSource(
        LockCachingAudioSource(
          Uri.parse(streamInfo.url.toString()),
          headers: {
            'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
            'Range': 'bytes=0-',
          },
        ),
      );
      
      _player.play();
    } catch (e) {
      debugPrint("Engine Critical Failure: $e");
    } finally {
      if (mounted) setState(() => _isBuffering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _renderLayer(),
          if (_activeTrack != null) _buildSupremeConsole(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _renderLayer() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: _tabIndex == 0 
          ? DiscoveryLayer(yt: _yt, onSelect: _igniteEngine) 
          : VaultLayer(items: _vaultHistory, onSelect: _igniteEngine),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 95,
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.2), width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(0, Icons.grain_rounded, "CENT"),
          _navItem(1, Icons.auto_awesome_motion_rounded, "VAULT"),
        ],
      ),
    );
  }

  Widget _navItem(int i, IconData icon, String label) {
    bool active = _tabIndex == i;
    return GestureDetector(
      onTap: () => setState(() => _tabIndex = i),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFD4AF37).withOpacity(0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? const Color(0xFFD4AF37) : Colors.white24, size: 30),
            Text(label, style: TextStyle(color: active ? const Color(0xFFD4AF37) : Colors.white24, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
          ],
        ),
      ),
    );
  }

  Widget _buildSupremeConsole() {
    return Positioned(
      bottom: 20, left: 15, right: 15,
      child: GestureDetector(
        onTap: () => _openPlayer(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
            child: Container(
              height: 85,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _isBuffering 
                    ? const SpinKitFadingCircle(color: Color(0xFFD4AF37), size: 35)
                    : Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.3), blurRadius: 10)],
                        ),
                        child: CircleAvatar(backgroundImage: CachedNetworkImageProvider(_activeTrack!.thumbnails.mediumResUrl), radius: 28),
                      ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_activeTrack!.title, maxLines: 1, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, overflow: TextOverflow.ellipsis)),
                        const Text("SUPREME ENGINE ACTIVE", style: TextStyle(color: Color(0xFFD4AF37), fontSize: 8, letterSpacing: 2)),
                      ],
                    ),
                  ),
                  StreamBuilder<PlayerState>(
                    stream: _player.playerStateStream,
                    builder: (context, snap) {
                      bool p = snap.data?.playing ?? false;
                      return IconButton(
                        icon: Icon(p ? Icons.pause_circle_filled : Icons.play_circle_filled, color: const Color(0xFFD4AF37), size: 45),
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

  void _openPlayer() {
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
  final TextEditingController _ctrl = TextEditingController();
  List<Video> _items = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _runQuery("top global music 2026"); }

  void _runQuery(String q) async {
    setState(() => _isLoading = true);
    var search = await widget.yt.search.search(q);
    if (mounted) setState(() { _items = search.toList(); _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200, pinned: true, backgroundColor: Colors.black,
          flexibleSpace: FlexibleSpaceBar(
            centerTitle: true,
            title: Text("S U P R E M E", style: GoogleFonts.orbitron(color: const Color(0xFFD4AF37), fontWeight: FontWeight.w900, letterSpacing: 12)),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
            child: TextField(
              controller: _ctrl, onSubmitted: _runQuery,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: "Enter Neural Search Key...",
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true, fillColor: Colors.white.withOpacity(0.03),
                prefixIcon: const Icon(Icons.search, color: Color(0xFFD4AF37)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFFD4AF37))),
              ),
            ),
          ),
        ),
        if (_isLoading) const SliverToBoxAdapter(child: Center(child: SpinKitCubeGrid(color: Color(0xFFD4AF37), size: 50))),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 150),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.7, crossAxisSpacing: 20, mainAxisSpacing: 20),
            delegate: SliverChildBuilderDelegate(
              (context, i) => GestureDetector(
                onTap: () => widget.onSelect(_items[i]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5))],
                        ),
                        child: ClipRRect(borderRadius: BorderRadius.circular(25), child: CachedNetworkImage(imageUrl: _items[i].thumbnails.highResUrl, fit: BoxFit.cover)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(_items[i].title, maxLines: 2, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5)),
                    Text(_items[i].author, style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 8, fontWeight: FontWeight.w900)),
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
          Positioned.fill(child: Opacity(opacity: 0.5, child: CachedNetworkImage(imageUrl: video.thumbnails.highResUrl, fit: BoxFit.cover))),
          BackdropFilter(filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100), child: Container(color: Colors.black.withOpacity(0.85))),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 45, color: Colors.white24),
                const Spacer(),
                Container(
                  width: 320, height: 320,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.4), blurRadius: 80, spreadRadius: 10),
                    ],
                  ),
                  child: ClipRRect(borderRadius: BorderRadius.circular(40), child: CachedNetworkImage(imageUrl: video.thumbnails.highResUrl, fit: BoxFit.cover)),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(video.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
                const Spacer(),
                _buildSlider(),
                const Spacer(),
                _buildControls(),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider() {
    return StreamBuilder<Duration>(
      stream: player.positionStream,
      builder: (context, snap) {
        final pos = snap.data ?? Duration.zero;
        final dur = player.duration ?? video.duration ?? const Duration(seconds: 1);
        return Column(
          children: [
            SliderTheme(
              data: SliderThemeData(trackHeight: 2, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6), overlayShape: const RoundSliderOverlayShape(overlayRadius: 14)),
              child: Slider(
                activeColor: const Color(0xFFD4AF37),
                inactiveColor: Colors.white10,
                value: pos.inSeconds.toDouble().clamp(0, dur.inSeconds.toDouble()),
                max: dur.inSeconds.toDouble(),
                onChanged: (v) => player.seek(Duration(seconds: v.toInt())),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_format(pos), style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  Text(_format(dur), style: const TextStyle(color: Colors.white38, fontSize: 11)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.shuffle, color: Colors.white24, size: 25),
        const SizedBox(width: 30),
        const Icon(Icons.skip_previous_rounded, size: 55),
        const SizedBox(width: 20),
        StreamBuilder<PlayerState>(
          stream: player.playerStateStream,
          builder: (context, snap) {
            bool p = snap.data?.playing ?? false;
            return GestureDetector(
              onTap: () => p ? player.pause() : player.play(),
              child: Container(
                padding: const EdgeInsets.all(25),
                decoration: const BoxDecoration(color: Color(0xFFD4AF37), shape: BoxShape.circle),
                child: Icon(p ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.black, size: 50),
              ),
            );
          },
        ),
        const SizedBox(width: 20),
        const Icon(Icons.skip_next_rounded, size: 55),
        const SizedBox(width: 30),
        const Icon(Icons.repeat, color: Colors.white24, size: 25),
      ],
    );
  }

  String _format(Duration d) => "${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}";
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
          const SizedBox(height: 60),
          Text("THE VAULT", style: GoogleFonts.orbitron(fontSize: 35, fontWeight: FontWeight.w900, color: const Color(0xFFD4AF37), letterSpacing: 10)),
          const Text("SECURE AUDIO STORAGE", style: TextStyle(fontSize: 10, letterSpacing: 5, color: Colors.white30)),
          const SizedBox(height: 30),
          Expanded(
            child: items.isEmpty 
              ? const Center(child: Text("VAULT IS EMPTY", style: TextStyle(color: Colors.white10, letterSpacing: 5)))
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, i) => ListTile(
                    onTap: () => onSelect(items[i]),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    leading: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(items[i].thumbnails.lowResUrl)),
                    title: Text(items[i].title, maxLines: 1, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    trailing: const Icon(Icons.lock_outline, color: Color(0xFFD4AF37), size: 18),
                  ),
                ),
          ),
        ],
      ),
    );
  }
}
