import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.black,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const CentSupremeFinal());
}

class CentSupremeFinal extends StatelessWidget {
  const CentSupremeFinal({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CENT SUPREME',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFD4AF37),
        scaffoldBackgroundColor: const Color(0xFF000000),
        splashColor: const Color(0xFFD4AF37).withOpacity(0.1),
        highlightColor: Colors.transparent,
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

  Future<void> _igniteStream(Video video) async {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Color(0xFFD4AF37), content: Text("ENGINE_SYNC_ERROR")),
      );
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
          _renderLayer(),
          if (_activeTrack != null) _buildConsole(),
        ],
      ),
      bottomNavigationBar: _buildNav(),
    );
  }

  Widget _renderLayer() {
    switch (_tabIndex) {
      case 0: return DiscoveryLayer(yt: _yt, onSelect: _igniteStream);
      case 1: return VaultLayer(items: _history, onSelect: _igniteStream);
      case 2: return const EngineLayer();
      default: return const SizedBox();
    }
  }

  Widget _buildNav() {
    return Container(
      height: 85,
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navBtn(0, Icons.blur_on_rounded, "CENT"),
          _navBtn(1, Icons.layers_rounded, "VAULT"),
          _navBtn(2, Icons.settings_input_antenna_rounded, "ENGINE"),
        ],
      ),
    );
  }

  Widget _navBtn(int i, IconData icon, String label) {
    bool a = _tabIndex == i;
    return GestureDetector(
      onTap: () => setState(() => _tabIndex = i),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: a ? const Color(0xFFD4AF37) : Colors.white24, size: 28),
          const SizedBox(height: 5),
          Text(label, style: TextStyle(color: a ? const Color(0xFFD4AF37) : Colors.white24, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
        ],
      ),
    );
  }

  Widget _buildConsole() {
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
                    ? const SpinKitDoubleBounce(color: Color(0xFFD4AF37), size: 35)
                    : CircleAvatar(backgroundImage: CachedNetworkImageProvider(_activeTrack!.thumbnails.mediumResUrl), radius: 25),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_activeTrack!.title, maxLines: 1, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const Text("GOLD SIGNAL • ACTIVE", style: TextStyle(color: Color(0xFFD4AF37), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                      ],
                    ),
                  ),
                  StreamBuilder<PlayerState>(
                    stream: _player.playerStateStream,
                    builder: (context, snap) {
                      bool p = snap.data?.playing ?? false;
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
  final TextEditingController _c = TextEditingController();
  List<Video> _r = [];
  bool _l = true;

  @override
  void initState() {
    super.initState();
    _search("high fidelity 2026");
  }

  void _search(String q) async {
    setState(() => _l = true);
    final res = await widget.yt.search.search(q);
    setState(() { _r = res.toList(); _l = false; });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200, pinned: true, backgroundColor: Colors.black,
          flexibleSpace: FlexibleSpaceBar(
            centerTitle: true,
            title: const Text("C E N T", style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.w900, letterSpacing: 15, fontSize: 28)),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              controller: _c, onSubmitted: _search,
              decoration: InputDecoration(
                filled: true, fillColor: Colors.white.withOpacity(0.05),
                hintText: "Access Neural Network...",
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFD4AF37)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
          ),
        ),
        if (_l) const SliverToBoxAdapter(child: Center(child: SpinKitPulse(color: Color(0xFFD4AF37)))),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(15, 0, 15, 120),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.7, crossAxisSpacing: 15, mainAxisSpacing: 15),
            delegate: SliverChildBuilderDelegate(
              (context, i) => GestureDetector(
                onTap: () => widget.onSelect(_r[i]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(20), child: CachedNetworkImage(imageUrl: _r[i].thumbnails.highResUrl, fit: BoxFit.cover))),
                    const SizedBox(height: 10),
                    Text(_r[i].title, maxLines: 1, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    Text(_r[i].author, style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 9, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              childCount: _r.length,
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
          Positioned.fill(child: Opacity(opacity: 0.4, child: CachedNetworkImage(imageUrl: video.thumbnails.highResUrl, fit: BoxFit.cover))),
          BackdropFilter(filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100), child: Container(color: Colors.black.withOpacity(0.8))),
          SafeArea(
            child: Column(
              children: [
                IconButton(icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 45), onPressed: () => Navigator.pop(context)),
                const Spacer(),
                Container(
                  width: 300, height: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    image: DecorationImage(image: CachedNetworkImageProvider(video.thumbnails.highResUrl), fit: BoxFit.cover),
                    boxShadow: [BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.2), blurRadius: 50)],
                  ),
                ),
                const Spacer(),
                Text(video.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Spacer(),
                StreamBuilder<Duration>(
                  stream: player.positionStream,
                  builder: (context, snap) {
                    final pos = snap.data ?? Duration.zero;
                    final dur = player.duration ?? const Duration(seconds: 1);
                    return Column(
                      children: [
                        Slider(
                          activeColor: const Color(0xFFD4AF37),
                          value: pos.inSeconds.toDouble().clamp(0, dur.inSeconds.toDouble()),
                          max: dur.inSeconds.toDouble(),
                          onChanged: (v) => player.seek(Duration(seconds: v.toInt())),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 25),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("${pos.inMinutes}:${(pos.inSeconds % 60).toString().padLeft(2, '0')}", style: const TextStyle(color: Colors.white24, fontSize: 10)),
                              Text("${dur.inMinutes}:${(dur.inSeconds % 60).toString().padLeft(2, '0')}", style: const TextStyle(color: Colors.white24, fontSize: 10)),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.skip_previous_rounded, size: 50),
                    const SizedBox(width: 30),
                    StreamBuilder<PlayerState>(
                      stream: player.playerStateStream,
                      builder: (context, snap) {
                        bool p = snap.data?.playing ?? false;
                        return GestureDetector(
                          onTap: () => p ? player.pause() : player.play(),
                          child: Container(
                            width: 85, height: 85,
                            decoration: const BoxDecoration(color: Color(0xFFD4AF37), shape: BoxShape.circle),
                            child: Icon(p ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.black, size: 50),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 30),
                    const Icon(Icons.skip_next_rounded, size: 50),
                  ],
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class VaultLayer extends StatelessWidget {
  final List<Video> items;
  final Function(Video) onSelect;
  const VaultLayer({super.key, required this.items, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(25),
      children: [
        const SizedBox(height: 60),
        const Text("VAULT", style: TextStyle(fontSize: 35, fontWeight: FontWeight.w100, letterSpacing: 10)),
        const Divider(color: Color(0xFFD4AF37), height: 40),
        ...items.map((v) => ListTile(
          onTap: () => onSelect(v),
          contentPadding: EdgeInsets.zero,
          leading: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(v.thumbnails.lowResUrl)),
          title: Text(v.title, maxLines: 1, style: const TextStyle(fontSize: 14)),
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
          SpinKitScanner(color: Color(0xFFD4AF37), size: 100),
          SizedBox(height: 30),
          Text("CORE ENGINE 2.0", style: TextStyle(letterSpacing: 10, fontWeight: FontWeight.w100)),
        ],
      ),
    );
  }
}
