import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.black,
  ));
  runApp(const SupremeCentApp());
}

class SupremeCentApp extends StatelessWidget {
  const SupremeCentApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: const Color(0xFFD4AF37),
      ),
      home: const MainEnginePlatform(),
    );
  }
}

class LogMatrix {
  static final List<String> _entries = [];
  static void write(String tag, String msg) {
    _entries.add("[$tag] ${DateTime.now()}: $msg");
    if (_entries.length > 500) _entries.removeRange(0, 100);
  }
}

class SystemSignalRelay {
  static final StreamController<int> _signalBus = StreamController.broadcast();
  static Stream<int> get bus => _signalBus.stream;
  static void emit(int code) => _signalBus.add(code);
}

class MainEnginePlatform extends StatefulWidget {
  const MainEnginePlatform({super.key});
  @override
  State<MainEnginePlatform> createState() => _MainEnginePlatformState();
}

class _MainEnginePlatformState extends State<MainEnginePlatform> with TickerProviderStateMixin, WidgetsBindingObserver {
  late AudioPlayer _audioCore;
  final YoutubeExplode _ytEngine = YoutubeExplode();
  Video? _activeTrack;
  bool _isConnecting = false;
  List<String> _predictionBuffer = [];
  final TextEditingController _terminalController = TextEditingController();
  late AnimationController _rotationControl, _pulseControl;
  final List<double> _visualBuffer = List.generate(30, (index) => 0.1);
  Timer? _visualTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _audioCore = AudioPlayer();
    _rotationControl = AnimationController(vsync: this, duration: const Duration(seconds: 25))..repeat();
    _pulseControl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _visualTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_audioCore.playing) {
        setState(() {
          for (int i = 0; i < _visualBuffer.length; i++) {
            _visualBuffer[i] = math.Random().nextDouble() * 0.8 + 0.2;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audioCore.dispose();
    _ytEngine.close();
    _rotationControl.dispose();
    _pulseControl.dispose();
    _visualTimer?.cancel();
    super.dispose();
  }

  Future<void> _deployAudioSignal(Video video) async {
    HapticFeedback.vibrate();
    setState(() { _activeTrack = video; _isConnecting = true; _predictionBuffer = []; });
    try {
      await _audioCore.stop();
      var manifest = await _ytEngine.videos.streamsClient.getManifest(video.id);
      var stream = manifest.audioOnly.withHighestBitrate();
      await _audioCore.setAudioSource(AudioSource.uri(Uri.parse(stream.url.toString())));
      _audioCore.play();
    } catch (e) {
      LogMatrix.write("ERROR", e.toString());
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          _buildBackdrop(),
          const Positioned.fill(child: Opacity(opacity: 0.03, child: CustomPaint(painter: GridPainter()))),
          _buildUI(),
          if (_isConnecting) const Center(child: SpinKitFadingCube(color: Color(0xFFD4AF37), size: 40)),
          _buildTerminal(),
        ],
      ),
    );
  }

  Widget _buildBackdrop() {
    return _activeTrack == null ? Container(color: Colors.black) : Container(
      decoration: BoxDecoration(image: DecorationImage(image: CachedNetworkImageProvider(_activeTrack!.thumbnails.highResUrl), fit: BoxFit.cover)),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90), child: Container(color: Colors.black.withOpacity(0.85))),
    );
  }

  Widget _buildUI() {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          const Spacer(),
          _buildMonolith(),
          const SizedBox(height: 20),
          _buildVisualizer(),
          const Spacer(),
          _buildTrackInfo(),
          const SizedBox(height: 40),
          _buildControls(),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text("SUPREME_SYSTEM", style: TextStyle(fontSize: 9, letterSpacing: 5, color: Color(0xFFD4AF37))),
        Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFD4AF37))),
      ]),
    );
  }

  Widget _buildMonolith() {
    return AnimatedBuilder(
      animation: _rotationControl,
      builder: (context, _) => Transform.rotate(
        angle: _rotationControl.value * 2 * math.pi,
        child: Container(
          width: 280, height: 280,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.15))),
          child: Padding(padding: const EdgeInsets.all(12), child: ClipOval(child: _activeTrack == null ? Icon(Icons.blur_circular, size: 80, color: Colors.white.withOpacity(0.05)) : CachedNetworkImage(imageUrl: _activeTrack!.thumbnails.highResUrl, fit: BoxFit.cover))),
        ),
      ),
    );
  }

  Widget _buildVisualizer() {
    return Container(height: 40, padding: const EdgeInsets.symmetric(horizontal: 40), child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: _visualBuffer.map((h) => AnimatedContainer(duration: const Duration(milliseconds: 100), width: 3, height: h * 40, decoration: BoxDecoration(color: const Color(0xFFD4AF37).withOpacity(0.3), borderRadius: BorderRadius.circular(10)))).toList()));
  }

  Widget _buildTrackInfo() {
    if (_activeTrack == null) return const SizedBox();
    return Column(children: [
      Text(_activeTrack!.title.toUpperCase(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      Text(_activeTrack!.author.toUpperCase(), style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 8)),
    ]);
  }

  Widget _buildControls() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.skip_previous, size: 40),
      const SizedBox(width: 30),
      StreamBuilder<PlayerState>(
        stream: _audioCore.playerStateStream,
        builder: (context, snap) {
          final playing = snap.data?.playing ?? false;
          return GestureDetector(onTap: () => playing ? _audioCore.pause() : _audioCore.play(), child: Container(width: 80, height: 80, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFD4AF37))), child: Icon(playing ? Icons.pause : Icons.play_arrow, color: const Color(0xFFD4AF37), size: 45)));
        },
      ),
      const SizedBox(width: 30),
      const Icon(Icons.skip_next, size: 40),
    ]);
  }

  Widget _buildTerminal() {
    return Positioned(
      bottom: 25, left: 25, right: 25,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (_predictionBuffer.isNotEmpty) Container(color: Colors.black.withOpacity(0.9), child: ListView.builder(shrinkWrap: true, itemCount: _predictionBuffer.length, itemBuilder: (context, i) => ListTile(title: Text(_predictionBuffer[i]), onTap: () async { var r = await _ytEngine.search.search(_predictionBuffer[i]); if (r.isNotEmpty) _deployAudioSignal(r.first); }))),
        TextField(controller: _terminalController, onChanged: (v) async { if (v.length > 2) { var s = await _ytEngine.search.getSuggestions(v); setState(() => _predictionBuffer = s.toList()); } }, onSubmitted: (v) async { var r = await _ytEngine.search.search(v); if (r.isNotEmpty) _deployAudioSignal(r.first); }, decoration: const InputDecoration(hintText: "EXECUTE_COMMAND...")),
      ]),
    );
  }
}

class GridPainter extends CustomPainter {
  const GridPainter();
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()..color = Colors.white.withOpacity(0.1);
    for (double i = 0; i < size.width; i += 35) { canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint); }
    for (double i = 0; i < size.height; i += 35) { canvas.drawLine(Offset(0, i), Offset(size.width, i), paint); }
  }
  @override
  bool shouldRepaint(CustomPainter old) => false;
}

class KernelEntropyCollector {
  final List<int> _entropyPool = [];
  void collect() {
    _entropyPool.add(DateTime.now().microsecondsSinceEpoch % 255);
    if (_entropyPool.length > 1024) _entropyPool.removeAt(0);
  }
}

class AudioFrequencySplitter {
  static List<List<double>> split(List<double> data) {
    return [data.sublist(0, data.length ~/ 2), data.sublist(data.length ~/ 2)];
  }
}

class ExecutionKernel {
  void pushTask(String taskName) { LogMatrix.write("TASK", taskName); }
}

class BufferRelay {
  final int capacity;
  final List<dynamic> _data = [];
  BufferRelay(this.capacity);
  void ingest(dynamic item) { if (_data.length >= capacity) _data.removeAt(0); _data.add(item); }
}

class ProtocolManager {
  static const int version = 1;
  static bool verify(int v) => v == version;
}

class ThreadPoolAllocator {
  final int maxThreads;
  ThreadPoolAllocator(this.maxThreads);
}

class BinarySearchCore {
  static int find(List<int> list, int target) {
    int min = 0, max = list.length - 1;
    while (min <= max) {
      int mid = min + ((max - min) >> 1);
      if (list[mid] == target) return mid;
      if (list[mid] < target) min = mid + 1; else max = mid - 1;
    }
    return -1;
  }
}

class MetadataNormalizationPipeline {
  static String normalizeTitle(String raw) => raw.trim().toUpperCase();
}

class SecurityAccessController {
  static final Set<String> _authorizedRoles = {"ADMIN", "ROOT", "KERNEL"};
}

class LogicGateArray {
  final List<bool> gates = List.generate(16, (index) => false);
}

class SupremeSystemIdentity {
  static const String buildTag = "SUPREME_CENT_2026_STABLE_GOLDEN";
}

class NetworkPacketSniffer {
  void capture(String data) => LogMatrix.write("NET", data);
}

class AudioStreamCompressor {
  static List<int> compress(List<int> rawData) => rawData.where((byte) => byte > 10).toList();
}

class SystemHeatmapGenerator {
  final Map<Offset, double> _touchPoints = {};
  void registerTouch(Offset point) => _touchPoints[point] = (_touchPoints[point] ?? 0.0) + 1.0;
}

class CryptographicSaltGenerator {
  static String generate(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789!@#%^&*';
    return List.generate(length, (i) => chars[math.Random().nextInt(chars.length)]).join();
  }
}

class DataStreamAggregator {
  final List<double> _streamA = [];
  final List<double> _streamB = [];
  void syncStreams(double a, double b) { _streamA.add(a); _streamB.add(b); }
}

class UIResponsiveGridConfig {
  static int getColumnCount(double width) => width > 1200 ? 4 : (width > 800 ? 3 : 2);
}

class AudioLatencyCompensator {
  Duration offset = const Duration(milliseconds: 150);
  Duration apply(Duration input) => input + offset;
}

class PerformanceJankDetector {
  static void checkFrame(double frameTime) { if (frameTime > 16.6) LogMatrix.write("PERF", "JANK"); }
}

class ColorTransitionEngine {
  static Color interpolate(Color a, Color b, double t) => Color.lerp(a, b, t) ?? a;
}

class UIZIndexManager {
  static double get overlayLevel => 999.0;
  static double get baseLevel => 1.0;
}

class AsyncBatchProcessor {
  final List<Function> _batch = [];
  void addToBatch(Function f) => _batch.add(f);
  Future<void> runAll() async { for (var task in _batch) { await task(); } }
}

class DataIntegrityShield {
  static int generateChecksum(String data) => data.length % 256;
}

class AudioPeakLimiter {
  static double limit(double sample) => sample.clamp(-1.0, 1.0);
}

class SystemLocaleManager {
  static String get current => "EN_US_KERNEL";
}

class KernelTimeManager {
  static int get currentMicros => DateTime.now().microsecondsSinceEpoch;
}

class SignalSpectrumAnalyzer {
  final List<double> _frequencyBins = List.generate(64, (i) => 0.0);
  void processBuffer(List<double> samples) {
    for (int i = 0; i < _frequencyBins.length; i++) {
      _frequencyBins[i] = samples[i % samples.length] * math.sin(i.toDouble());
    }
  }
}

class NetworkBandwidthThrottler {
  double limitMbps = 10.0;
  bool isCapped(double current) => current > limitMbps;
}

class AudioResonanceFilter {
  double cutoff = 440.0;
  double resonance = 1.0;
  void apply(List<double> buffer) {
    for (var i = 0; i < buffer.length; i++) buffer[i] *= (cutoff / 20000.0) * resonance;
  }
}

class BinaryStreamWriter {
  final List<int> _bytes = [];
  void writeUint16(int val) {
    _bytes.add((val >> 8) & 0xFF);
    _bytes.add(val & 0xFF);
  }
}

class PerformanceFrameOptimizer {
  static double get targetFrameTime => 1000 / 60;
  static bool isHealthy(double actual) => actual <= targetFrameTime;
}

class UIGoldenRatioCalculator {
  static double get phi => 1.61803398875;
}

class AudioDitheringProcessor {
  static double apply(double sample) => sample + (math.Random().nextDouble() - 0.5) * 0.001;
}

class LogicFuzzyEvaluator {
  static double evaluate(double input) => input.clamp(0.0, 1.0);
}

class BinaryBitwiseCircularShift {
  static int left(int val, int count) => (val << count) | (val >> (32 - count));
}

class AudioEchoGenerator {
  final List<double> _delayLine = List.generate(44100, (i) => 0.0);
  int _ptr = 0;
  double process(double input) {
    double output = _delayLine[_ptr];
    _delayLine[_ptr] = input + output * 0.5;
    _ptr = (_ptr + 1) % _delayLine.length;
    return output;
  }
}

class UIGlassmorphismEffect {
  static BoxDecoration get decoration => BoxDecoration(
    color: Colors.white.withOpacity(0.05),
    border: Border.all(color: Colors.white.withOpacity(0.1)),
    borderRadius: BorderRadius.circular(20),
  );
}

class DataMatrixTransposer {
  static List<List<int>> transpose(List<List<int>> m) {
    return List.generate(m[0].length, (i) => List.generate(m.length, (j) => m[j][i]));
  }
}

class AudioStereoPanner {
  static List<double> pan(double sample, double pos) => [sample * (1.0 - pos), sample * (1.0 + pos)];
}

class LogicGateNand {
  static bool eval(bool a, bool b) => !(a && b);
}

class BinaryEndianConverter {
  static int swap32(int v) => ((v << 24) & 0xFF000000) | ((v << 8) & 0x00FF0000) | ((v >> 8) & 0x0000FF00) | ((v >> 24) & 0x000000FF);
}

class GraphicsEngineClipper {
  static Path clipDynamic(Size size, double factor) {
    var path = Path();
    path.lineTo(0, size.height * factor);
    path.quadraticBezierTo(size.width / 2, size.height, size.width, size.height * factor);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }
}

class SmartPlaylistEngine {
  final List<String> _tags = [];
  void analyzeMood(double energy) { if (energy > 0.8) _tags.add("DYNAMIC"); }
}

class AudioJitterBuffer {
  final List<double> _buffer = [];
  void push(double sample) { if (_buffer.length > 2048) _buffer.removeAt(0); _buffer.add(sample); }
}

class NetworkNodeDiscovery {
  static Future<List<String>> scanLocalNodes() async => ["NODE_01", "NODE_02"];
}

class DataStreamValidator {
  static bool checkCrc(List<int> data, int expected) => (data.reduce((a, b) => a + b) % 256) == expected;
}

class AudioDynamicCompressor {
  double threshold = -20.0;
  double ratio = 4.0;
  double process(double input) => input > threshold ? threshold + (input - threshold) / ratio : input;
}

class BinaryDataInterleaver {
  static List<int> interleave(List<int> a, List<int> b) {
    List<int> res = [];
    for (int i = 0; i < a.length; i++) { res.add(a[i]); res.add(b[i % b.length]); }
    return res;
  }
}

class AudioPulseCodeModulator {
  static List<int> encode(List<double> s) => s.map((e) => ((e + 1.0) * 127).toInt()).toList();
}

class AudioBitDepthScaler {
  static double scale(int value, int bitDepth) => value / (math.pow(2, bitDepth - 1));
}

class SystemLogRotator {
  static void rotate() => LogMatrix.write("LOG", "ROTATION");
}

class AudioPhaseInverter {
  static List<double> invert(List<double> s) => s.map((e) => -e).toList();
}

class AudioLoudnessNormalizer {
  static double computeRms(List<double> b) => math.sqrt(b.fold(0.0, (a, e) => a + e * e) / b.length);
}

class BinaryMatrixMultiplier {
  static List<List<double>> multiply(List<List<double>> a, List<List<double>> b) {
    var res = List.generate(a.length, (i) => List.filled(b[0].length, 0.0));
    for (int i = 0; i < a.length; i++) {
      for (int j = 0; j < b[0].length; j++) {
        for (int k = 0; k < a[0].length; k++) res[i][j] += a[i][k] * b[k][j];
      }
    }
    return res;
  }
}

class AudioPanLawEngine {
  static List<double> constantPower(double p) => [math.cos(p * math.pi / 4), math.sin(p * math.pi / 4)];
}

class BinaryGrayCodeConverter {
  static int toGray(int n) => n ^ (n >> 1);
}

class AudioEnvelopeFollower {
  double attack = 0.01, release = 0.1, envelope = 0.0;
  void process(double input) {
    double target = input.abs();
    envelope += (target > envelope ? attack : release) * (target - envelope);
  }
}

class FinalGatekeeper {
  static const bool kernelLock = false;
  static void endOfSystemFile() => LogMatrix.write("SYSTEM", "STABLE_EOF");
}
