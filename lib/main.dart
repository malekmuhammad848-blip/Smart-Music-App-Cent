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

  Future<void> _igniteEngine(Video video) async {
    setState(() { 
      _activeTrack = video; 
      _isBuffering = true; 
      if (!_vaultHistory.any((e) => e.id == video.id)) _vaultHistory.insert(0, video);
    });
    
    try {
      await _player.stop();
      var manifest = await _yt.videos.streamsClient.getManifest(video.id);
      var streamInfo = manifest.audioOnly.where((s) => s.container.name == 'm4a').withHighestBitrate();

      // THE TITAN AUDIO ENGINE - Zero Latency Configuration
      await _player.setAudioSource(
        LockCachingAudioSource(
          Uri.parse(streamInfo.url.toString()),
          headers: {
            'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
            'Connection': 'keep-alive',
          },
        ),
      );
      
      await _player.setVolume(1.0);
      _player.play();
    } catch (e) {
      debugPrint("CRITICAL ENGINE ERROR: $e");
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
        color: Colors.black.withOpacity(0.95),
        border: const Border(top: BorderSide(color: Color(0xFFD4AF37), width: 0.5)),
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
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFD4AF37).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? const Color(0xFFD4AF37) : Colors.white24, size: 35),
            Text(label, style: TextStyle(color: active ? const Color(0xFFD4AF37) : Colors.white24, fontSize: 10, letterSpacing: 4, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingConsole() {
    return Positioned(
      bottom: 25, left: 15, right: 15,
      child: GestureDetector(
        onTap: () => _showPlayer(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
            child: Container(
              height: 95,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.4), width: 1),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _isBuffering 
                    ? const SpinKitDoubleBounce(color: Color(0xFFD4AF37), size: 40)
                    : Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(color: Color(0xFFD4AF37), shape: BoxShape.circle),
                        child: CircleAvatar(backgroundImage: CachedNetworkImageProvider(_activeTrack!.thumbnails.mediumResUrl), radius: 32),
                      ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_activeTrack!.title, maxLines: 1, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, overflow: TextOverflow.ellipsis)),
                        const Text("CENT ENGINE: MASTER QUALITY", style: TextStyle(color: Color(0xFFD4AF37), fontSize: 8, letterSpacing: 2, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  StreamBuilder<PlayerState>(
                    stream: _player.playerStateStream,
                    builder: (context, snap) {
                      bool p = snap.data?.playing ?? false;
                      return IconButton(
                        icon: Icon(p ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded, color: const Color(0xFFD4AF37), size: 55),
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

  void _showPlayer() {
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
          expandedHeight: 250, pinned: true, backgroundColor: Colors.black,
          flexibleSpace: FlexibleSpaceBar(
            centerTitle: true,
            title: Text("C E N T", style: GoogleFonts.orbitron(color: const Color(0xFFD4AF37), fontWeight: FontWeight.w900, letterSpacing: 20, fontSize: 25)),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            child: TextField(
              controller: _s, onSubmitted: _fetch,
              decoration: InputDecoration(
                filled: true, fillColor: Colors.white.withOpacity(0.05),
                hintText: "Access Cent Database...",
                prefixIcon: const Icon(Icons.search, color: Color(0xFFD4AF37)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: Colors.white10)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: Color(0xFFD4AF37))),
              ),
            ),
          ),
        ),
        if (_load) const SliverToBoxAdapter(child: Center(child: SpinKitCubeGrid(color: Color(0xFFD4AF37), size: 60))),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(25, 0, 25, 160),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.62, crossAxisSpacing: 25, mainAxisSpacing: 25),
            delegate: SliverChildBuilderDelegate(
              (context, i) => GestureDetector(
                onTap: () => widget.onSelect(_items[i]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(35),
                          border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.2)),
                          boxShadow: [BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.15), blurRadius: 25)],
                        ),
                        child: ClipRRect(borderRadius: BorderRadius.circular(35), child: CachedNetworkImage(imageUrl: _items[i].thumbnails.highResUrl, fit: BoxFit.cover)),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(_items[i].title, maxLines: 2, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
                    Text(_items[i].author, style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
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
          BackdropFilter(filter: ImageFilter.blur(sigmaX: 130, sigmaY: 130), child: Container(color: Colors.black.withOpacity(0.9))),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 60, color: Colors.white24),
                const Spacer(),
                Container(
                  width: 350, height: 350,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(60),
                    boxShadow: [BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.6), blurRadius: 120, spreadRadius: 10)],
                  ),
                  child: ClipRRect(borderRadius: BorderRadius.circular(60), child: CachedNetworkImage(imageUrl: video.thumbnails.highResUrl, fit: BoxFit.cover)),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      Text(video.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      const SizedBox(height: 15),
                      Text(video.author.toUpperCase(), style: const TextStyle(color: Color(0xFFD4AF37), letterSpacing: 6, fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const Spacer(),
                _buildDynamicSlider(),
                const Spacer(),
                _buildTitanControls(),
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
                trackHeight: 6,
                thumbColor: const Color(0xFFD4AF37),
                activeTrackColor: const Color(0xFFD4AF37),
                inactiveTrackColor: Colors.white10,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              ),
              child: Slider(
                value: pos.inSeconds.toDouble().clamp(0, dur.inSeconds.toDouble()),
                max: dur.inSeconds.toDouble(),
                onChanged: (v) => player.seek(Duration(seconds: v.toInt())),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_fmt(pos), style: const TextStyle(color: Colors.white30, fontSize: 13, fontWeight: FontWeight.bold)),
                  Text(_fmt(dur), style: const TextStyle(color: Colors.white30, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTitanControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.shuffle_rounded, color: Color(0xFFD4AF37), size: 35),
        const SizedBox(width: 30),
        const Icon(Icons.skip_previous_rounded, size: 70),
        const SizedBox(width: 20),
        StreamBuilder<PlayerState>(
          stream: player.playerStateStream,
          builder: (context, snap) {
            bool p = snap.data?.playing ?? false;
            return GestureDetector(
              onTap: () => p ? player.pause() : player.play(),
              child: Container(
                padding: const EdgeInsets.all(30),
                decoration: const BoxDecoration(
                  color: Color(0xFFD4AF37),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Color(0xFFD4AF37), blurRadius: 40, spreadRadius: 2)],
                ),
                child: Icon(p ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.black, size: 65),
              ),
            );
          },
        ),
        const SizedBox(width: 20),
        const Icon(Icons.skip_next_rounded, size: 70),
        const SizedBox(width: 30),
        const Icon(Icons.repeat_one_rounded, color: Color(0xFFD4AF37), size: 35),
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
      padding: const EdgeInsets.all(35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 80),
          Text("CENT VAULT", style: GoogleFonts.orbitron(fontSize: 45, fontWeight: FontWeight.w900, color: const Color(0xFFD4AF37), letterSpacing: 15)),
          const Text("TOTAL SECURE ARCHIVE", style: TextStyle(fontSize: 12, letterSpacing: 8, color: Colors.white24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 50),
          Expanded(
            child: items.isEmpty 
              ? const Center(child: Text("ARCHIVE IS EMPTY", style: TextStyle(color: Colors.white10, letterSpacing: 10)))
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, i) => Container(
                    margin: const EdgeInsets.only(bottom: 25),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.1)),
                    ),
                    child: ListTile(
                      onTap: () => onSelect(items[i]),
                      contentPadding: const EdgeInsets.all(20),
                      leading: ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.network(items[i].thumbnails.lowResUrl)),
                      title: Text(items[i].title, maxLines: 1, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Text(items[i].author.toUpperCase(), style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 11, letterSpacing: 2)),
                      trailing: const Icon(Icons.security_rounded, color: Color(0xFFD4AF37), size: 25),
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }
}
