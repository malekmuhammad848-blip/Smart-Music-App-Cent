import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'dart:async';
import 'dart:math' as math;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // FORCING SYSTEM CONTROL
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());
  await session.setActive(true);

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  
  runApp(const CentSupreme());
}

class CentSupreme extends StatelessWidget {
  const CentSupreme({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        textTheme: GoogleFonts.audiowideTextTheme(ThemeData.dark().textTheme),
      ),
      home: const GodModule(),
    );
  }
}

// --- CORE ENGINE MODULE ---
class GodModule extends StatefulWidget {
  const GodModule({super.key});
  @override
  State<GodModule> createState() => _GodModuleState();
}

class _GodModuleState extends State<GodModule> with TickerProviderStateMixin {
  // SYSTEM CONTROLLERS
  late AudioPlayer _audioEngine;
  final YoutubeExplode _ytVault = YoutubeExplode();
  
  // STATE MANAGEMENT
  Video? _activeStream;
  bool _isWarping = false;
  List<String> _intelligenceBuffer = [];
  final TextEditingController _cmdTerminal = TextEditingController();
  
  // ANIMATION ENGINES
  late AnimationController _monolithRotation;
  late AnimationController _nebulaPulse;
  late AnimationController _uiSlide;
  
  double _volumeLevel = 1.0;
  bool _isTerminalOpen = false;

  @override
  void initState() {
    super.initState();
    _audioEngine = AudioPlayer();
    
    _monolithRotation = AnimationController(vsync: this, duration: const Duration(seconds: 30))..repeat();
    _nebulaPulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _uiSlide = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

    // AUDIO STREAM MONITORING
    _audioEngine.playbackEventStream.listen((event) {}, onError: (Object e, StackTrace st) {
      debugPrint('CRITICAL_AUDIO_ERROR: $e');
    });
  }

  @override
  void dispose() {
    _audioEngine.dispose();
    _ytVault.close();
    _monolithRotation.dispose();
    _nebulaPulse.dispose();
    super.dispose();
  }

  // --- SUPREME EXECUTION METHODS ---
  Future<void> _igniteStream(Video video) async {
    HapticFeedback.vibrate();
    setState(() {
      _isWarping = true;
      _activeStream = video;
      _intelligenceBuffer = [];
      _isTerminalOpen = false;
    });

    try {
      await _audioEngine.stop();
      var manifest = await _ytVault.videos.streamsClient.getManifest(video.id);
      var audioStream = manifest.audioOnly.withHighestBitrate();

      // FORCING BUFFER SATURATION
      await _audioEngine.setAudioSource(
        AudioSource.uri(
          Uri.parse(audioStream.url.toString()),
          tag: video.id.toString(),
        ),
        preload: true,
      );
      
      _audioEngine.play();
    } catch (e) {
      _handleSystemFailure(e);
    } finally {
      if (mounted) setState(() => _isWarping = false);
    }
  }

  void _handleSystemFailure(dynamic e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("SYSTEM_OVERLOAD: $e", style: const TextStyle(color: Color(0xFFD4AF37)))),
    );
  }

  void _fetchNeuralSuggestions(String query) async {
    if (query.length < 2) {
      setState(() => _intelligenceBuffer = []);
      return;
    }
    try {
      var suggestions = await _ytVault.search.getQueries(query);
      setState(() => _intelligenceBuffer = suggestions.toList());
    } catch (_) {}
  }

  // --- UI CONSTRUCTION (THE DIVINE AESTHETIC) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _renderDeepSpaceBackground(),
          _renderGlassMorphismLayers(),
          _renderMainControlUnit(),
          if (_isWarping) _renderWarpLoader(),
          _renderCommandCenter(),
        ],
      ),
    );
  }

  Widget _renderDeepSpaceBackground() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 1500),
      child: _activeStream == null 
        ? Container(color: Colors.black)
        : Container(
            key: ValueKey(_activeStream!.id.toString()),
            decoration: BoxDecoration(
              image: DecorationImage(
                image: CachedNetworkImageProvider(_activeStream!.thumbnails.highResUrl),
                fit: BoxFit.cover,
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(color: Colors.black.withOpacity(0.8)),
            ),
          ),
    );
  }

  Widget _renderGlassMorphismLayers() {
    return Positioned.fill(
      child: CustomPaint(
        painter: GridPainter(opacity: 0.05),
      ),
    );
  }

  Widget _renderMainControlUnit() {
    return SafeArea(
      child: Column(
        children: [
          _buildTopBar(),
          const Spacer(),
          _buildMonolithDisc(),
          const Spacer(),
          _buildTrackData(),
          const SizedBox(height: 40),
          _buildHardwareController(),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("SUPREME_ENTITY", style: TextStyle(fontSize: 10, letterSpacing: 5, color: Color(0xFFD4AF37))),
              Text("PROTOCOL_ACTIVE", style: TextStyle(fontSize: 6, letterSpacing: 2, color: Colors.white24)),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.grid_view_rounded, color: Colors.white10),
            onPressed: () {},
          )
        ],
      ),
    );
  }

  Widget _buildMonolithDisc() {
    return AnimatedBuilder(
      animation: _nebulaPulse,
      builder: (context, child) {
        return RotationTransition(
          turns: _monolithRotation,
          child: Container(
            width: 300, height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.2), width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD4AF37).withOpacity(0.1 * _nebulaPulse.value),
                  blurRadius: 120,
                  spreadRadius: 5,
                )
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: ClipOval(
                child: _activeStream == null 
                  ? const Icon(Icons.all_inclusive_rounded, size: 100, color: Colors.white10)
                  : CachedNetworkImage(imageUrl: _activeStream!.thumbnails.highResUrl, fit: BoxFit.cover),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrackData() {
    if (_activeStream == null) return const SizedBox();
    return FadeInUp(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _activeStream!.title.toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _activeStream!.author.toUpperCase(),
            style: const TextStyle(color: Color(0xFFD4AF37), letterSpacing: 10, fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _buildHardwareController() {
    return Column(
      children: [
        _buildProgressBar(),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _circularBtn(Icons.shuffle_rounded, 20, Colors.white10),
            const SizedBox(width: 30),
            _circularBtn(Icons.skip_previous_rounded, 35, Colors.white),
            const SizedBox(width: 30),
            _buildPlayButton(),
            const SizedBox(width: 30),
            _circularBtn(Icons.skip_next_rounded, 35, Colors.white),
            const SizedBox(width: 30),
            _circularBtn(Icons.repeat_one_rounded, 20, Colors.white10),
          ],
        ),
      ],
    );
  }

  Widget _buildPlayButton() {
    return StreamBuilder<PlayerState>(
      stream: _audioEngine.playerStateStream,
      builder: (context, snap) {
        final playing = snap.data?.playing ?? false;
        return GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            playing ? _audioEngine.pause() : _audioEngine.play();
          },
          child: Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFD4AF37).withOpacity(0.05),
              border: Border.all(color: const Color(0xFFD4AF37), width: 1),
            ),
            child: Icon(
              playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: const Color(0xFFD4AF37),
              size: 45,
            ),
          ),
        );
      },
    );
  }

  Widget _circularBtn(IconData icon, double size, Color color) {
    return Icon(icon, size: size, color: color);
  }

  Widget _buildProgressBar() {
    return StreamBuilder<Duration>(
      stream: _audioEngine.positionStream,
      builder: (context, snap) {
        final pos = snap.data ?? Duration.zero;
        final dur = _audioEngine.duration ?? const Duration(seconds: 1);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 50),
          child: Column(
            children: [
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 1,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 3),
                  activeTrackColor: const Color(0xFFD4AF37),
                  inactiveTrackColor: Colors.white10,
                  thumbColor: Colors.white,
                ),
                child: Slider(
                  value: pos.inSeconds.toDouble().clamp(0, dur.inSeconds.toDouble()),
                  max: dur.inSeconds.toDouble(),
                  onChanged: (v) => _audioEngine.seek(Duration(seconds: v.toInt())),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_fmtDur(pos), style: const TextStyle(fontSize: 8, color: Colors.white24)),
                  Text(_fmtDur(dur), style: const TextStyle(fontSize: 8, color: Colors.white24)),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  String _fmtDur(Duration d) => "${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}";

  Widget _renderWarpLoader() {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: SpinKitFadingGrid(color: Color(0xFFD4AF37), size: 50),
      ),
    );
  }

  // --- COMMAND CENTER (INTELLIGENT SEARCH) ---
  Widget _renderCommandCenter() {
    return Positioned(
      bottom: 20, left: 20, right: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_intelligenceBuffer.isNotEmpty) _buildSuggestionsList(),
          ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  border: Border.all(color: Colors.white10),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: TextField(
                  controller: _cmdTerminal,
                  onChanged: _fetchNeuralSuggestions,
                  onSubmitted: (v) async {
                    var results = await _ytVault.search.search(v);
                    if (results.isNotEmpty) _igniteStream(results.first);
                  },
                  style: const TextStyle(fontSize: 12, letterSpacing: 2),
                  decoration: const InputDecoration(
                    icon: Icon(Icons.radar, size: 18, color: Color(0xFFD4AF37)),
                    hintText: "SEARCH_NETWORK...",
                    hintStyle: TextStyle(color: Colors.white10, fontSize: 10),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsList() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      constraints: const BoxConstraints(maxHeight: 250),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.2)),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _intelligenceBuffer.length,
        itemBuilder: (context, i) => ListTile(
          dense: true,
          title: Text(_intelligenceBuffer[i].toUpperCase(), style: const TextStyle(fontSize: 9, letterSpacing: 1)),
          onTap: () async {
            var r = await _ytVault.search.search(_intelligenceBuffer[i]);
            if (r.isNotEmpty) _igniteStream(r.first);
          },
        ),
      ),
    );
  }
}

// --- VISUAL PHYSICS COMPONENTS ---
class GridPainter extends CustomPainter {
  final double opacity;
  GridPainter({required this.opacity});
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()..color = Colors.white.withOpacity(opacity)..strokeWidth = 0.5;
    for (double i = 0; i < size.width; i += 30) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 30) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class FadeInUp extends StatelessWidget {
  final Widget child;
  const FadeInUp({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      builder: (context, double val, child) {
        return Opacity(
          opacity: val,
          child: Transform.translate(offset: Offset(0, 20 * (1 - val)), child: child),
        );
      },
      child: child,
    );
  }
}
