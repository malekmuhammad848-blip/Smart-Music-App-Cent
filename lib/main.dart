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

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
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
        scaffoldBackgroundColor: const Color(0xFF000000),
        textTheme: GoogleFonts.syneTextTheme(ThemeData.dark().textTheme),
      ),
      home: const MainEngineCore(),
    );
  }
}

class MainEngineCore extends StatefulWidget {
  const MainEngineCore({super.key});
  @override
  State<MainEngineCore> createState() => _MainEngineCoreState();
}

class _MainEngineCoreState extends State<MainEngineCore> {
  final AudioPlayer _core = AudioPlayer();
  final YoutubeExplode _yt = YoutubeExplode();
  Video? _activeTrack;
  bool _isConnecting = false;
  int _tabIndex = 0;
  final List<Video> _vault = [];

  Future<void> _fire(Video video) async {
    setState(() { _activeTrack = video; _isConnecting = true; });
    if (!_vault.any((v) => v.id == video.id)) _vault.insert(0, video);

    try {
      await _core.stop();
      var manifest = await _yt.videos.streamsClient.getManifest(video.id);
      var streamInfo = manifest.audioOnly.withHighestBitrate();

      await _core.setAudioSource(
        AudioSource.uri(
          Uri.parse(streamInfo.url.toString()),
          tag: video.id.toString(),
        ),
        preload: true,
      );
      
      _core.play();
    } catch (e) {
      debugPrint("SYS_ERR: $e");
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildVisualBuffer(),
          _renderActiveLayer(),
          if (_activeTrack != null) _buildControlPanel(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildVisualBuffer() {
    return Positioned.fill(
      child: _activeTrack == null ? Container() : AnimatedOpacity(
        duration: const Duration(seconds: 1),
        opacity: 0.1,
        child: CachedNetworkImage(imageUrl: _activeTrack!.thumbnails.highResUrl, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 75,
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Color(0xFFD4AF37), width: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navItem(0, Icons.bolt_rounded, "POWER"),
          _navItem(1, Icons.token_rounded, "ARCHIVE"),
        ],
      ),
    );
  }

  Widget _navItem(int i, IconData icon, String label) {
    bool active = _tabIndex == i;
    return GestureDetector(
      onTap: () => setState(() => _tabIndex = i),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: active ? const Color(0xFFD4AF37) : Colors.white10, size: 28),
          Text(label, style: TextStyle(color: active ? const Color(0xFFD4AF37) : Colors.white10, fontSize: 8, letterSpacing: 4)),
        ],
      ),
    );
  }

  Widget _renderActiveLayer() {
    return _tabIndex == 0 
      ? DiscoveryLayer(yt: _yt, onTrigger: _fire) 
      : ArchiveLayer(data: _vault, onTrigger: _fire);
  }

  Widget _buildControlPanel() {
    return Positioned(
      bottom: 15, left: 10, right: 10,
      child: GestureDetector(
        onTap: () => _openMasterInterface(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              height: 75,
              color: Colors.white.withOpacity(0.02),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  _isConnecting 
                    ? const SpinKitThreeBounce(color: Color(0xFFD4AF37), size: 20)
                    : CircleAvatar(backgroundImage: CachedNetworkImageProvider(_activeTrack!.thumbnails.lowResUrl), radius: 24),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_activeTrack!.title, maxLines: 1, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                        const Text("ACTIVE STREAMING PROTOCOL", style: TextStyle(color: Color(0xFFD4AF37), fontSize: 7, letterSpacing: 1.5)),
                      ],
                    ),
                  ),
                  StreamBuilder<PlayerState>(
                    stream: _core.playerStateStream,
                    builder: (context, snap) {
                      bool isPlaying = snap.data?.playing ?? false;
                      return IconButton(
                        icon: Icon(isPlaying ? Icons.pause_circle : Icons.play_circle, color: const Color(0xFFD4AF37), size: 40),
                        onPressed: () => isPlaying ? _core.pause() : _core.play(),
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

  void _openMasterInterface() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MasterInterface(player: _core, video: _activeTrack!),
    );
  }
}

class MasterInterface extends StatelessWidget {
  final AudioPlayer player;
  final Video video;
  const MasterInterface({super.key, required this.player, required this.video});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      color: const Color(0xFF000000),
      child: Stack(
        children: [
          Positioned.fill(child: Opacity(opacity: 0.2, child: CachedNetworkImage(imageUrl: video.thumbnails.highResUrl, fit: BoxFit.cover))),
          BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: Container(color: Colors.transparent)),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                IconButton(icon: const Icon(Icons.expand_more_rounded, color: Color(0xFFD4AF37), size: 35), onPressed: () => Navigator.pop(context)),
                const Spacer(),
                Container(
                  width: 300, height: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
                    image: DecorationImage(image: CachedNetworkImageProvider(video.thumbnails.highResUrl), fit: BoxFit.cover),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      Text(video.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      const SizedBox(height: 10),
                      Text(video.author.toUpperCase(), style: const TextStyle(color: Color(0xFFD4AF37), letterSpacing: 10, fontSize: 10)),
                    ],
                  ),
                ),
                const Spacer(),
                _buildProgressBar(),
                const Spacer(),
                _buildPlaybackControls(),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return StreamBuilder<Duration>(
      stream: player.positionStream,
      builder: (context, snap) {
        final pos = snap.data ?? Duration.zero;
        final dur = player.duration ?? const Duration(seconds: 1);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            children: [
              SliderTheme(
                data: SliderThemeData(trackHeight: 1, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4), activeTrackColor: const Color(0xFFD4AF37), inactiveTrackColor: Colors.white12, thumbColor: Colors.white),
                child: Slider(
                  value: pos.inSeconds.toDouble().clamp(0, dur.inSeconds.toDouble()),
                  max: dur.inSeconds.toDouble(),
                  onChanged: (v) => player.seek(Duration(seconds: v.toInt())),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_format(pos), style: const TextStyle(color: Colors.white24, fontSize: 10)),
                  Text(_format(dur), style: const TextStyle(color: Colors.white24, fontSize: 10)),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlaybackControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.shuffle_rounded, color: Colors.white10),
        const SizedBox(width: 40),
        const Icon(Icons.skip_previous_rounded, size: 50),
        const SizedBox(width: 25),
        StreamBuilder<PlayerState>(
          stream: player.playerStateStream,
          builder: (context, snap) {
            bool isP = snap.data?.playing ?? false;
            return GestureDetector(
              onTap: () => isP ? player.pause() : player.play(),
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFD4AF37).withOpacity(0.1), border: Border.all(color: const Color(0xFFD4AF37))),
                child: Icon(isP ? Icons.pause_rounded : Icons.play_arrow_rounded, color: const Color(0xFFD4AF37), size: 45),
              ),
            );
          },
        ),
        const SizedBox(width: 25),
        const Icon(Icons.skip_next_rounded, size: 50),
        const SizedBox(width: 40),
        const Icon(Icons.repeat_one_rounded, color: Colors.white10),
      ],
    );
  }

  String _format(Duration d) => "${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}";
}

class DiscoveryLayer extends StatefulWidget {
  final YoutubeExplode yt;
  final Function(Video) onTrigger;
  const DiscoveryLayer({super.key, required this.yt, required this.onTrigger});
  @override
  State<DiscoveryLayer> createState() => _DiscoveryLayerState();
}

class _DiscoveryLayerState extends State<DiscoveryLayer> {
  final TextEditingController _ctrl = TextEditingController();
  List<Video> _results = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _executeSearch("Global Top 100 2026"); }

  void _executeSearch(String q) async {
    setState(() => _isLoading = true);
    var search = await widget.yt.search.search(q);
    setState(() { _results = search.toList(); _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 180, pinned: true, backgroundColor: Colors.black,
          flexibleSpace: FlexibleSpaceBar(
            centerTitle: true,
            title: Text("C E N T", style: GoogleFonts.syne(color: const Color(0xFFD4AF37), fontWeight: FontWeight.w900, letterSpacing: 25, fontSize: 22)),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: TextField(
              controller: _ctrl, onSubmitted: _executeSearch,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                filled: true, fillColor: Colors.white.withOpacity(0.02),
                hintText: "COMMAND SEARCH",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ),
        ),
        if (_isLoading) const SliverToBoxAdapter(child: Center(child: SpinKitPulse(color: Color(0xFFD4AF37), size: 80))),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 150),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: CachedNetworkImage(imageUrl: _results[i].thumbnails.lowResUrl, width: 50, height: 50, fit: BoxFit.cover)),
                title: Text(_results[i].title, maxLines: 1, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                subtitle: Text(_results[i].author, style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 9)),
                onTap: () => widget.onTrigger(_results[i]),
              ),
              childCount: _results.length,
            ),
          ),
        ),
      ],
    );
  }
}

class ArchiveLayer extends StatelessWidget {
  final List<Video> data;
  final Function(Video) onTrigger;
  const ArchiveLayer({super.key, required this.data, required this.onTrigger});
  @override
  Widget build(BuildContext context) {
    return data.isEmpty 
      ? const Center(child: Text("ARCHIVE_NULL", style: TextStyle(letterSpacing: 10, color: Colors.white10)))
      : ListView.builder(
          padding: const EdgeInsets.only(top: 150, left: 20, right: 20),
          itemCount: data.length,
          itemBuilder: (context, i) => ListTile(
            leading: const Icon(Icons.shield_rounded, color: Color(0xFFD4AF37)),
            title: Text(data[i].title, style: const TextStyle(fontSize: 12)),
            onTap: () => onTrigger(data[i]),
          ),
        );
  }
}
