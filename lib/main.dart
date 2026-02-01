100)),
        ],
      ),
    );
  }
}
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
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
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

class _MainArchitectureState extends State<MainArchitecture> {
  int _tabIndex = 0;
  final AudioPlayer _player = AudioPlayer();
  final YoutubeExplode _yt = YoutubeExplode();
  Video? _activeTrack;
  bool _isBuffering = false;
  final List<Video> _history = [];

  Future<void> _igniteEngine(Video video) async {
    if (_activeTrack?.id == video.id && _player.playing) return;
    setState(() {
      _activeTrack = video;
      _isBuffering = true;
      if (!_history.any((e) => e.id == video.id)) _history.insert(0, video);
    });
    try {
      final manifest = await _yt.videos.streamsClient.getManifest(video.id);
      final audioStream = manifest.audioOnly.withHighestBitrate();
      await _player.setAudioSource(
        AudioSource.uri(Uri.parse(audioStream.url.toString()), tag: video.title),
      );
      _player.play();
    } catch (e) {
      debugPrint("ENGINE_ERROR: $e");
    } finally {
      if (mounted) setState(() => _isBuffering = false);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    _yt.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _renderCurrentLayer(),
          if (_activeTrack != null) _buildSupremeConsole(),
        ],
      ),
      bottomNavigationBar: _buildImperialNav(),
    );
  }

  Widget _renderCurrentLayer() {
    switch (_tabIndex) {
      case 0: return DiscoveryLayer(yt: _yt, onSelect: _igniteEngine);
      case 1: return VaultLayer(items: _history, onSelect: _igniteEngine);
      case 2: return const EngineLayer();
      default: return const SizedBox();
    }
  }

  Widget _buildImperialNav() {
    return Container(
      height: 85,
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(0, Icons.blur_on_rounded, "CENT"),
          _navItem(1, Icons.layers_rounded, "VAULT"),
          _navItem(2, Icons.settings_input_antenna_rounded, "ENGINE"),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    bool active = _tabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _tabIndex = index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: active ? const Color(0xFFD4AF37) : Colors.white24, size: 28),
          const SizedBox(height: 5),
          Text(label, style: TextStyle(color: active ? const Color(0xFFD4AF37) : Colors.white24, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
        ],
      ),
    );
  }

  Widget _buildSupremeConsole() {
    return Positioned(
      bottom: 15, left: 15, right: 15,
      child: GestureDetector(
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => PlayerScreen(player: _player, video: _activeTrack!),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              height: 75,
              color: Colors.white.withOpacity(0.08),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  _isBuffering 
                    ? const SpinKitDoubleBounce(color: Color(0xFFD4AF37), size: 30)
                    : CircleAvatar(backgroundImage: CachedNetworkImageProvider(_activeTrack!.thumbnails.mediumResUrl), radius: 25),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_activeTrack!.title, maxLines: 1, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, overflow: TextOverflow.ellipsis)),
                        const Text("GOLD SIGNAL • ACTIVE", style: TextStyle(color: Color(0xFFD4AF37), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                      ],
                    ),
                  ),
                  StreamBuilder<bool>(
                    stream: _player.playingStream,
                    builder: (context, snap) {
                      bool p = snap.data ?? false;
                      return IconButton(
                        icon: Icon(p ? Icons.pause_rounded : Icons.play_arrow_rounded, color: const Color(0xFFD4AF37), size: 35),
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
  List<Video> _results = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _performSearch("high fidelity music 2026");
  }

  void _performSearch(String query) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final res = await widget.yt.search.search(query);
    if (mounted) setState(() { _results = res.toList(); _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 180, pinned: true, backgroundColor: Colors.black,
          flexibleSpace: FlexibleSpaceBar(
            centerTitle: true,
            title: Text("C E N T", style: GoogleFonts.orbitron(color: const Color(0xFFD4AF37), fontWeight: FontWeight.w900, letterSpacing: 12)),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              controller: _ctrl, onSubmitted: _performSearch,
              decoration: InputDecoration(
                filled: true, fillColor: Colors.white.withOpacity(0.05),
                hintText: "Access Neural Network...",
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFD4AF37)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
          ),
        ),
        if (_isLoading) const SliverToBoxAdapter(child: Center(child: SpinKitPulse(color: Color(0xFFD4AF37)))),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(15, 0, 15, 120),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 15, mainAxisSpacing: 15),
            delegate: SliverChildBuilderDelegate(
              (context, i) => GestureDetector(
                onTap: () => widget.onSelect(_results[i]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(15), child: CachedNetworkImage(imageUrl: _results[i].thumbnails.highResUrl, fit: BoxFit.cover))),
                    const SizedBox(height: 10),
                    Text(_results[i].title, maxLines: 1, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, overflow: TextOverflow.ellipsis)),
                    Text(_results[i].author, style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 9)),
                  ],
                ),
              ),
              childCount: _results.length,
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
          Positioned.fill(child: Opacity(opacity: 0.3, child: CachedNetworkImage(imageUrl: video.thumbnails.highResUrl, fit: BoxFit.cover))),
          BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: Container(color: Colors.black.withOpacity(0.7))),
          SafeArea(
            child: Column(
              children: [
                IconButton(icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 40), onPressed: () => Navigator.pop(context)),
                const Spacer(),
                Center(
                  child: Container(
                    width: 280, height: 280,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      image: DecorationImage(image: CachedNetworkImageProvider(video.thumbnails.highResUrl), fit: BoxFit.cover),
                      boxShadow: [BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.3), blurRadius: 40)],
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Text(video.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Text(video.author, style: const TextStyle(color: Color(0xFFD4AF37), letterSpacing: 4, fontSize: 12)),
                const Spacer(),
                _buildProgress(player),
                const Spacer(),
                _buildControls(player),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress(AudioPlayer p) {
    return StreamBuilder<Duration>(
      stream: p.positionStream,
      builder: (context, snap) {
        final pos = snap.data ?? Duration.zero;
        final dur = p.duration ?? const Duration(seconds: 1);
        return Column(
          children: [
            Slider(
              activeColor: const Color(0xFFD4AF37),
              inactiveColor: Colors.white10,
              value: pos.inSeconds.toDouble().clamp(0, dur.inSeconds.toDouble()),
              max: dur.inSeconds.toDouble(),
              onChanged: (v) => p.seek(Duration(seconds: v.toInt())),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_format(pos), style: const TextStyle(color: Colors.white30, fontSize: 10)),
                  Text(_format(dur), style: const TextStyle(color: Colors.white30, fontSize: 10)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildControls(AudioPlayer p) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.skip_previous_rounded, size: 45, color: Colors.white),
        const SizedBox(width: 40),
        StreamBuilder<bool>(
          stream: p.playingStream,
          builder: (context, snap) {
            bool isP = snap.data ?? false;
            return GestureDetector(
              onTap: () => isP ? p.pause() : p.play(),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(color: Color(0xFFD4AF37), shape: BoxShape.circle),
                child: Icon(isP ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.black, size: 45),
              ),
            );
          },
        ),
        const SizedBox(width: 40),
        const Icon(Icons.skip_next_rounded, size: 45, color: Colors.white),
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
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        const SizedBox(height: 70),
        Text("VAULT", style: GoogleFonts.orbitron(fontSize: 30, letterSpacing: 8)),
        const Divider(color: Color(0xFFD4AF37), thickness: 2, endIndent: 200),
        const SizedBox(height: 20),
        ...items.map((v) => ListTile(
          onTap: () => onSelect(v),
          contentPadding: EdgeInsets.zero,
          leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(v.thumbnails.lowResUrl)),
          title: Text(v.title, maxLines: 1, style: const TextStyle(fontSize: 13, overflow: TextOverflow.ellipsis)),
          subtitle: Text(v.author, style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 10)),
        )),
      ],
    );
  }
}

class EngineLayer extends StatelessWidget {
  const EngineLayer({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SpinKitDoubleBounce(color: Color(0xFFD4AF37), size: 100),
          SizedBox(height: 30),
          Text("CORE ENGINE 2.0", style: TextStyle(letterSpacing: 8, fontWeight: FontWeight.w100)),
        ],
      ),
    );
  }
}
