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
  
  // الاستحواذ على النظام: تفعيل بروتوكول الأولوية القصوى
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());
  await session.setActive(true);

  // السيطرة الكاملة على عتاد الجهاز
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const CentGodMode());
}

class CentGodMode extends StatelessWidget {
  const CentGodMode({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        textTheme: GoogleFonts.cinzelTextTheme(ThemeData.dark().textTheme),
      ),
      home: const GodEngine(),
    );
  }
}

class GodEngine extends StatefulWidget {
  const GodEngine({super.key});
  @override
  State<GodEngine> createState() => _GodEngineState();
}

class _GodEngineState extends State<GodEngine> {
  final AudioPlayer _player = AudioPlayer();
  final YoutubeExplode _yt = YoutubeExplode();
  Video? _activeSignal;
  bool _isIgniting = false;
  int _sector = 0;
  final List<Video> _history = [];

  // محرك الانفجار (The Ignitor): تشغيل فوري بدون انتظار
  Future<void> _ignite(Video video) async {
    setState(() { _activeSignal = video; _isIgniting = true; });
    if (!_history.any((v) => v.id == video.id)) _history.insert(0, video);

    try {
      await _player.stop();
      // استخراج المسار الصوتي الأعلى (Highest Bitrate) مباشرة من خوادم البث
      var manifest = await _yt.videos.streamsClient.getManifest(video.id);
      var stream = manifest.audioOnly.withHighestBitrate();

      // حقن الرابط في المحرك مع تفعيل خاصية التخزين المؤقت العدواني
      await _player.setAudioSource(
        AudioSource.uri(
          Uri.parse(stream.url.toString()),
          tag: video.id.toString(),
        ),
        preload: true,
      );
      
      _player.play();
    } catch (e) {
      debugPrint("ENGINE FAILURE: $e");
    } finally {
      if (mounted) setState(() => _isIgniting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackgroundAura(),
          _renderSector(),
          if (_activeSignal != null) _buildGodConsole(),
        ],
      ),
      bottomNavigationBar: _buildNav(),
    );
  }

  Widget _buildBackgroundAura() {
    return Positioned.fill(
      child: _activeSignal == null ? Container() : AnimatedOpacity(
        duration: const Duration(seconds: 3),
        opacity: 0.15,
        child: CachedNetworkImage(imageUrl: _activeSignal!.thumbnails.highResUrl, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildNav() {
    return Container(
      height: 70,
      color: Colors.black,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(0, "CORE"),
          _navItem(1, "VAULT"),
        ],
      ),
    );
  }

  Widget _navItem(int i, String label) {
    bool active = _sector == i;
    return GestureDetector(
      onTap: () => setState(() => _sector = i),
      child: Text(label, style: TextStyle(color: active ? const Color(0xFFD4AF37) : Colors.white10, fontSize: 12, letterSpacing: 8, fontWeight: FontWeight.bold)),
    );
  }

  Widget _renderSector() {
    return _sector == 0 
      ? DiscoveryView(yt: _yt, onSelect: _ignite) 
      : HistoryView(data: _history, onSelect: _ignite);
  }

  Widget _buildGodConsole() {
    return Positioned(
      bottom: 20, left: 15, right: 15,
      child: GestureDetector(
        onTap: () => _openTerminal(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.02),
                border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.2)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _isIgniting 
                    ? const SpinKitDoubleBounce(color: Color(0xFFD4AF37), size: 30)
                    : CircleAvatar(backgroundImage: CachedNetworkImageProvider(_activeSignal!.thumbnails.lowResUrl), radius: 25),
                  const SizedBox(width: 15),
                  Expanded(child: Text(_activeSignal!.title, maxLines: 1, style: const TextStyle(fontSize: 11, letterSpacing: 1))),
                  StreamBuilder<PlayerState>(
                    stream: _player.playerStateStream,
                    builder: (context, snap) {
                      bool p = snap.data?.playing ?? false;
                      return IconButton(
                        icon: Icon(p ? Icons.pause_circle_outline : Icons.play_circle_outline, color: const Color(0xFFD4AF37), size: 40),
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

  void _openTerminal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TerminalView(player: _player, video: _activeSignal!),
    );
  }
}

class TerminalView extends StatelessWidget {
  final AudioPlayer player;
  final Video video;
  const TerminalView({super.key, required this.player, required this.video});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      color: Colors.black,
      child: Stack(
        children: [
          Positioned.fill(child: CachedNetworkImage(imageUrl: video.thumbnails.highResUrl, fit: BoxFit.cover, opacity: const AlwaysStoppedAnimation(0.25))),
          BackdropFilter(filter: ImageFilter.blur(sigmaX: 150, sigmaY: 150), child: Container(color: Colors.transparent)),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 30),
                const Icon(Icons.keyboard_arrow_down, color: Color(0xFFD4AF37), size: 30),
                const Spacer(),
                Container(
                  width: 320, height: 320,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFD4AF37), width: 0.5),
                    boxShadow: [BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.2), blurRadius: 100)],
                    image: DecorationImage(image: CachedNetworkImageProvider(video.thumbnails.highResUrl), fit: BoxFit.cover),
                  ),
                ),
                const Spacer(),
                Text(video.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2)),
                const SizedBox(height: 10),
                Text(video.author.toUpperCase(), style: const TextStyle(color: Color(0xFFD4AF37), letterSpacing: 10, fontSize: 12)),
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
        final dur = player.duration ?? const Duration(seconds: 1);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 50),
          child: Column(
            children: [
              SliderTheme(
                data: SliderThemeData(trackHeight: 1, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0), activeTrackColor: const Color(0xFFD4AF37), inactiveTrackColor: Colors.white10),
                child: Slider(
                  value: pos.inSeconds.toDouble().clamp(0, dur.inSeconds.toDouble()),
                  max: dur.inSeconds.toDouble(),
                  onChanged: (v) => player.seek(Duration(seconds: v.toInt())),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_fmt(pos), style: const TextStyle(color: Colors.white24, fontSize: 10)),
                  Text(_fmt(dur), style: const TextStyle(color: Colors.white24, fontSize: 10)),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.fast_rewind, size: 40),
        const SizedBox(width: 40),
        StreamBuilder<PlayerState>(
          stream: player.playerStateStream,
          builder: (context, snap) {
            bool p = snap.data?.playing ?? false;
            return GestureDetector(
              onTap: () => p ? player.pause() : player.play(),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFD4AF37))),
                child: Icon(p ? Icons.pause : Icons.play_arrow, color: const Color(0xFFD4AF37), size: 40),
              ),
            );
          },
        ),
        const SizedBox(width: 40),
        const Icon(Icons.fast_forward, size: 40),
      ],
    );
  }

  String _fmt(Duration d) => "${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}";
}

class DiscoveryView extends StatefulWidget {
  final YoutubeExplode yt;
  final Function(Video) onSelect;
  const DiscoveryView({super.key, required this.yt, required this.onSelect});
  @override
  State<DiscoveryView> createState() => _DiscoveryViewState();
}

class _DiscoveryViewState extends State<DiscoveryView> {
  final TextEditingController _q = TextEditingController();
  List<Video> _list = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _search("Cyberpunk Cinema Music 2026"); }

  void _search(String q) async {
    setState(() => _loading = true);
    var res = await widget.yt.search.search(q);
    setState(() { _list = res.toList(); _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50),
            child: TextField(
              controller: _q, onSubmitted: _search,
              textAlign: TextAlign.center,
              style: const TextStyle(letterSpacing: 3),
              decoration: const InputDecoration(hintText: "SEARCH_SYSTEM", border: InputBorder.none, hintStyle: TextStyle(color: Colors.white10)),
            ),
          ),
        ),
        if (_loading) const SliverToBoxAdapter(child: Center(child: SpinKitFadingGrid(color: Color(0xFFD4AF37), size: 50))),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) => ListTile(
              title: Text(_list[i].title, maxLines: 1, style: const TextStyle(fontSize: 12)),
              onTap: () => widget.onSelect(_list[i]),
            ),
            childCount: _list.length,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 150)),
      ],
    );
  }
}

class HistoryView extends StatelessWidget {
  final List<Video> data;
  final Function(Video) onSelect;
  const HistoryView({super.key, required this.data, required this.onSelect});
  @override
  Widget build(BuildContext context) {
    return data.isEmpty 
      ? const Center(child: Text("VAULT_EMPTY", style: TextStyle(color: Colors.white10, letterSpacing: 10)))
      : ListView.builder(
          padding: const EdgeInsets.only(top: 150),
          itemCount: data.length,
          itemBuilder: (context, i) => ListTile(title: Text(data[i].title), onTap: () => onSelect(data[i])),
        );
  }
}
