// audio_kernel.dart
// Professional Audio Engine for Large-Scale Flutter Applications
// Features: Playback, Playlist Management, Caching, Audio Visualization
// Optimized for 50k+ LOC environments

import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:audio_session/audio_session.dart';
import 'package:rxdart/rxdart.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'dart:convert';

// ============================================
// CORE TYPES & CONSTANTS
// ============================================

enum AudioState { idle, loading, playing, paused, stopped, error, buffering }
enum RepeatMode { none, one, all }
enum CachePolicy { aggressive, moderate, conservative, none }

typedef AudioVisualizationData = ({Float64List magnitudes, Float64List frequencies});
typedef AudioMetadata = Map<String, dynamic>;

class AudioTrack {
  final String id;
  final String uri;
  final String title;
  final String artist;
  final String? album;
  final Duration duration;
  final AudioMetadata metadata;
  final String? coverArt;
  
  const AudioTrack({
    required this.id,
    required this.uri,
    required this.title,
    required this.artist,
    this.album,
    required this.duration,
    this.metadata = const {},
    this.coverArt,
  });
  
  @override
  bool operator ==(Object other) => identical(this, other) || 
    other is AudioTrack && runtimeType == other.runtimeType && id == other.id;
  
  @override
  int get hashCode => id.hashCode;
}

class PlaybackPosition {
  final Duration position;
  final Duration buffered;
  final Duration total;
  final double speed;
  
  const PlaybackPosition({
    required this.position,
    required this.buffered,
    required this.total,
    required this.speed,
  });
}

// ============================================
// MAIN AUDIO KERNEL CLASS
// ============================================

class AudioKernel {
  // Singleton instance
  static final AudioKernel _instance = AudioKernel._internal();
  factory AudioKernel() => _instance;
  AudioKernel._internal() {
    _initialize();
  }
  
  // Core players
  final _primaryPlayer = ja.AudioPlayer();
  final _precachePlayer = ja.AudioPlayer();
  
  // State management
  final _stateController = BehaviorSubject<AudioState>.seeded(AudioState.idle);
  final _positionController = BehaviorSubject<PlaybackPosition>();
  final _currentTrackController = BehaviorSubject<AudioTrack?>.seeded(null);
  final _volumeController = BehaviorSubject<double>.seeded(1.0);
  final _visualizationController = StreamController<AudioVisualizationData>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  
  // Playlist management
  final _playlist = ListQueue<AudioTrack>();
  final _originalPlaylist = ListQueue<AudioTrack>();
  int _currentIndex = -1;
  RepeatMode _repeatMode = RepeatMode.none;
  bool _shuffleEnabled = false;
  
  // Caching system
  final _cache = <String, File>{};
  final _pendingDownloads = <String, Future<File>>{};
  static const _maxCacheSize = 1024 * 1024 * 500; // 500 MB
  int _currentCacheSize = 0;
  
  // Performance optimization
  final _bufferDuration = const Duration(seconds: 30);
  final _precacheDistance = 2; // Number of tracks ahead to precache
  bool _disposed = false;
  DateTime _lastInteraction = DateTime.now();
  
  // Visualization
  static const _fftSize = 2048;
  final _fftBuffer = Float64List(_fftSize);
  Timer? _visualizationTimer;
  
  // Getter streams
  Stream<AudioState> get stateStream => _stateController.stream.distinct();
  Stream<PlaybackPosition> get positionStream => _positionController.stream;
  Stream<AudioTrack?> get currentTrackStream => _currentTrackController.stream;
  Stream<double> get volumeStream => _volumeController.stream;
  Stream<AudioVisualizationData> get visualizationStream => _visualizationController.stream;
  Stream<String> get errorStream => _errorController.stream;
  
  // Current values
  AudioState get currentState => _stateController.value;
  AudioTrack? get currentTrack => _currentTrackController.value;
  double get currentVolume => _volumeController.value;
  bool get isPlaying => currentState == AudioState.playing;
  bool get isBuffering => currentState == AudioState.buffering;
  List<AudioTrack> get playlist => _playlist.toList();
  int get playlistIndex => _currentIndex;
  
  // ============================================
  // INITIALIZATION
  // ============================================
  
  Future<void> _initialize() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.speech());
      
      // Primary player setup
      _primaryPlayer.playbackEventStream.listen(_handlePlaybackEvent);
      _primaryPlayer.positionStream.listen(_handlePositionUpdate);
      _primaryPlayer.playerStateStream.listen(_handlePlayerState);
      _primaryPlayer.processingStateStream.listen(_handleProcessingState);
      
      // Error handling
      _primaryPlayer.playbackEventStream
          .where((event) => event.state == ja.ProcessingState.idle)
          .listen((_) => _setState(AudioState.idle));
      
      // Start visualization timer
      _startVisualization();
      
      // Initialize cache
      await _initializeCache();
      
      debugPrint('🔊 Audio Kernel initialized successfully');
    } catch (e) {
      _errorController.add('Initialization failed: $e');
      rethrow;
    }
  }
  
  Future<void> _initializeCache() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final cacheFolder = Directory('${cacheDir.path}/audio_cache');
      
      if (!await cacheFolder.exists()) {
        await cacheFolder.create(recursive: true);
      }
      
      // Load existing cache metadata
      await _loadCacheIndex();
    } catch (e) {
      debugPrint('Cache initialization error: $e');
    }
  }
  
  // ============================================
  // PLAYBACK CONTROL
  // ============================================
  
  Future<void> playTrack(AudioTrack track, {bool enqueue = false}) async {
    try {
      _lastInteraction = DateTime.now();
      
      if (enqueue) {
        await _addToPlaylist(track);
        return;
      }
      
      _setState(AudioState.loading);
      _currentTrackController.add(track);
      
      // Check cache first
      final cachedFile = await _getCachedFile(track.uri);
      final source = cachedFile != null
          ? ja.AudioSource.uri(Uri.file(cachedFile.path))
          : ja.AudioSource.uri(Uri.parse(track.uri));
      
      await _primaryPlayer.setAudioSource(
        source,
        preload: true,
        initialPosition: Duration.zero,
      );
      
      await _primaryPlayer.play();
      _currentIndex = _playlist.indexOf(track);
      _setState(AudioState.playing);
      
      // Precache upcoming tracks
      _precacheUpcomingTracks();
    } catch (e) {
      _setState(AudioState.error);
      _errorController.add('Playback failed: $e');
    }
  }
  
  Future<void> play() async {
    if (_disposed) return;
    
    try {
      await _primaryPlayer.play();
      _setState(AudioState.playing);
    } catch (e) {
      _errorController.add('Play failed: $e');
    }
  }
  
  Future<void> pause() async {
    if (_disposed) return;
    
    try {
      await _primaryPlayer.pause();
      _setState(AudioState.paused);
    } catch (e) {
      _errorController.add('Pause failed: $e');
    }
  }
  
  Future<void> stop() async {
    if (_disposed) return;
    
    try {
      await _primaryPlayer.stop();
      _setState(AudioState.stopped);
      _currentTrackController.add(null);
    } catch (e) {
      _errorController.add('Stop failed: $e');
    }
  }
  
  Future<void> seek(Duration position) async {
    if (_disposed) return;
    
    try {
      await _primaryPlayer.seek(position);
    } catch (e) {
      _errorController.add('Seek failed: $e');
    }
  }
  
  Future<void> next() async {
    if (_playlist.isEmpty || _currentIndex >= _playlist.length - 1) {
      await stop();
      return;
    }
    
    final nextIndex = _getNextIndex();
    if (nextIndex != -1 && nextIndex < _playlist.length) {
      await playTrack(_playlist.elementAt(nextIndex));
    }
  }
  
  Future<void> previous() async {
    final currentPos = await _primaryPlayer.position;
    
    if (currentPos.inSeconds > 3) {
      await seek(Duration.zero);
    } else if (_currentIndex > 0) {
      await playTrack(_playlist.elementAt(_currentIndex - 1));
    }
  }
  
  Future<void> setVolume(double volume) async {
    if (_disposed) return;
    
    try {
      final clampedVolume = volume.clamp(0.0, 1.0);
      await _primaryPlayer.setVolume(clampedVolume);
      _volumeController.add(clampedVolume);
    } catch (e) {
      _errorController.add('Volume set failed: $e');
    }
  }
  
  Future<void> setSpeed(double speed) async {
    if (_disposed) return;
    
    try {
      await _primaryPlayer.setSpeed(speed);
    } catch (e) {
      _errorController.add('Speed set failed: $e');
    }
  }
  
  // ============================================
  // PLAYLIST MANAGEMENT
  // ============================================
  
  Future<void> setPlaylist(List<AudioTrack> tracks, {int startIndex = 0}) async {
    _playlist.clear();
    _originalPlaylist.clear();
    
    _playlist.addAll(tracks);
    _originalPlaylist.addAll(tracks);
    
    if (tracks.isNotEmpty && startIndex < tracks.length) {
      await playTrack(tracks[startIndex]);
    }
  }
  
  Future<void> addToPlaylist(AudioTrack track) async {
    await _addToPlaylist(track);
  }
  
  Future<void> _addToPlaylist(AudioTrack track) async {
    _playlist.add(track);
    if (!_shuffleEnabled) {
      _originalPlaylist.add(track);
    }
    
    // Auto-play if nothing is playing
    if (currentState == AudioState.idle) {
      await playTrack(track);
    }
  }
  
  Future<void> removeFromPlaylist(int index) async {
    if (index >= 0 && index < _playlist.length) {
      final removed = _playlist.removeAt(index);
      
      if (_shuffleEnabled) {
        _originalPlaylist.remove(removed);
      }
      
      if (index == _currentIndex) {
        await next();
      } else if (index < _currentIndex) {
        _currentIndex--;
      }
    }
  }
  
  void shufflePlaylist() {
    if (_playlist.isEmpty) return;
    
    final current = _currentIndex >= 0 ? _playlist.elementAt(_currentIndex) : null;
    final shuffled = _playlist.toList()..shuffle();
    
    _playlist.clear();
    _playlist.addAll(shuffled);
    _shuffleEnabled = true;
    
    if (current != null) {
      final newIndex = _playlist.indexOf(current);
      if (newIndex != -1) {
        _currentIndex = newIndex;
      }
    }
  }
  
  void unshufflePlaylist() {
    if (!_shuffleEnabled) return;
    
    final current = _currentIndex >= 0 ? _playlist.elementAt(_currentIndex) : null;
    _playlist.clear();
    _playlist.addAll(_originalPlaylist);
    _shuffleEnabled = false;
    
    if (current != null) {
      final newIndex = _playlist.indexOf(current);
      if (newIndex != -1) {
        _currentIndex = newIndex;
      }
    }
  }
  
  void setRepeatMode(RepeatMode mode) {
    _repeatMode = mode;
    _primaryPlayer.setLoopMode(_convertRepeatMode(mode));
  }
  
  int _getNextIndex() {
    if (_playlist.isEmpty) return -1;
    
    switch (_repeatMode) {
      case RepeatMode.one:
        return _currentIndex;
      case RepeatMode.all:
        return (_currentIndex + 1) % _playlist.length;
      case RepeatMode.none:
        return _currentIndex < _playlist.length - 1 ? _currentIndex + 1 : -1;
    }
  }
  
  ja.LoopMode _convertRepeatMode(RepeatMode mode) {
    switch (mode) {
      case RepeatMode.one:
        return ja.LoopMode.one;
      case RepeatMode.all:
        return ja.LoopMode.all;
      case RepeatMode.none:
        return ja.LoopMode.off;
    }
  }
  
  // ============================================
  // CACHING SYSTEM
  // ============================================
  
  Future<File?> _getCachedFile(String uri) async {
    final key = _generateCacheKey(uri);
    
    // Return if already in memory cache
    if (_cache.containsKey(key)) {
      return _cache[key];
    }
    
    // Check if downloading
    if (_pendingDownloads.containsKey(key)) {
      return _pendingDownloads[key];
    }
    
    // Check disk cache
    try {
      final cacheDir = await getTemporaryDirectory();
      final cacheFile = File('${cacheDir.path}/audio_cache/$key');
      
      if (await cacheFile.exists()) {
        _cache[key] = cacheFile;
        _currentCacheSize += await cacheFile.length();
        return cacheFile;
      }
    } catch (e) {
      debugPrint('Cache read error: $e');
    }
    
    return null;
  }
  
  Future<void> cacheTrack(String uri, {bool background = false}) async {
    final key = _generateCacheKey(uri);
    
    if (_cache.containsKey(key) || _pendingDownloads.containsKey(key)) {
      return;
    }
    
    final completer = Completer<File>();
    _pendingDownloads[key] = completer.future;
    
    if (!background) {
      await _downloadAndCache(uri, key, completer);
    } else {
      unawaited(_downloadAndCache(uri, key, completer));
    }
  }
  
  Future<void> _downloadAndCache(
    String uri, 
    String key, 
    Completer<File> completer,
  ) async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final cacheFile = File('${cacheDir.path}/audio_cache/$key');
      
      if (!await cacheFile.exists()) {
        final response = await HttpClient().getUrl(Uri.parse(uri));
        final fileData = await (await response.close()).fold<List<int>>(
          <int>[],
          (previous, element) => previous..addAll(element),
        );
        
        await cacheFile.writeAsBytes(fileData);
      }
      
      final fileSize = await cacheFile.length();
      
      // Manage cache size
      if (_currentCacheSize + fileSize > _maxCacheSize) {
        await _cleanupCache(fileSize);
      }
      
      _cache[key] = cacheFile;
      _currentCacheSize += fileSize;
      
      completer.complete(cacheFile);
      _pendingDownloads.remove(key);
      
      debugPrint('✅ Cached: ${uri.substring(uri.lastIndexOf('/') + 1)}');
    } catch (e) {
      completer.completeError(e);
      _pendingDownloads.remove(key);
      debugPrint('❌ Cache failed: $uri - $e');
    }
  }
  
  Future<void> _cleanupCache(int neededSpace) async {
    final lruEntries = _cache.entries.toList()
      ..sort((a, b) => a.value.lastModifiedSync().compareTo(b.value.lastModifiedSync()));
    
    int freedSpace = 0;
    
    for (final entry in lruEntries) {
      if (freedSpace >= neededSpace) break;
      
      final fileSize = await entry.value.length();
      await entry.value.delete();
      _cache.remove(entry.key);
      _currentCacheSize -= fileSize;
      freedSpace += fileSize;
    }
  }
  
  Future<void> _precacheUpcomingTracks() async {
    if (_playlist.isEmpty) return;
    
    final start = _currentIndex + 1;
    final end = min(_currentIndex + _precacheDistance + 1, _playlist.length);
    
    final precacheTasks = <Future<dynamic>>[];
    
    for (var i = start; i < end; i++) {
      final track = _playlist.elementAt(i);
      precacheTasks.add(cacheTrack(track.uri, background: true));
    }
    
    try {
      await Future.wait<dynamic>(precacheTasks);
    } catch (e) {
      // Silent fail for precaching
    }
  }
  
  String _generateCacheKey(String uri) {
    return sha256.convert(utf8.encode(uri)).toString();
  }
  
  Future<void> _loadCacheIndex() async {
    // Implement cache index loading if needed
  }
  
  // ============================================
  // AUDIO VISUALIZATION
  // ============================================
  
  void _startVisualization() {
    const frameDuration = Duration(milliseconds: 50); // 20 FPS
    
    _visualizationTimer = Timer.periodic(frameDuration, (timer) {
      if (_disposed) {
        timer.cancel();
        return;
      }
      
      if (currentState != AudioState.playing) return;
      
      _generateVisualizationData();
    });
  }
  
  void _generateVisualizationData() {
    // Simulated FFT data (replace with actual audio processing in production)
    // In a real implementation, you would:
    // 1. Use the audio package to decode audio
    // 2. Apply FFT algorithm
    // 3. Process frequency bins
    
    final magnitudes = Float64List(_fftSize ~/ 2);
    final frequencies = Float64List(_fftSize ~/ 2);
    
    final random = Random();
    final baseFrequency = 60.0; // Hz
    
    for (var i = 0; i < magnitudes.length; i++) {
      // Simulate frequency response with some random variation
      final freq = baseFrequency * pow(2, i / 12.0); // Logarithmic frequency scale
      final magnitude = 0.7 + 0.3 * random.nextDouble();
      
      // Add some resonance peaks
      final resonance = sin(freq * 0.01) * 0.2;
      
      magnitudes[i] = (magnitude + resonance).clamp(0.0, 1.0);
      frequencies[i] = freq;
    }
    
    // Apply smoothing
    _smoothFFTData(magnitudes);
    
    if (!_visualizationController.isClosed) {
      _visualizationController.add((magnitudes: magnitudes, frequencies: frequencies));
    }
  }
  
  void _smoothFFTData(Float64List data) {
    const smoothingFactor = 0.3;
    
    for (var i = 1; i < data.length; i++) {
      data[i] = smoothingFactor * data[i] + (1 - smoothingFactor) * data[i - 1];
    }
  }
  
  Future<AudioVisualizationData> getWaveformData(
    String audioUri, {
    int resolution = 100,
  }) async {
    // This would typically decode audio and compute waveform
    // For now, return simulated data
    
    final magnitudes = Float64List(resolution);
    final frequencies = Float64List(resolution);
    
    for (var i = 0; i < resolution; i++) {
      magnitudes[i] = Random().nextDouble();
      frequencies[i] = i * 22050.0 / resolution;
    }
    
    return (magnitudes: magnitudes, frequencies: frequencies);
  }
  
  // ============================================
  // EVENT HANDLERS
  // ============================================
  
  void _handlePlaybackEvent(ja.PlaybackEvent event) {
    // Handle audio session interruptions, etc.
  }
  
  void _handlePositionUpdate(Duration position) async {
    if (_disposed) return;
    
    try {
      final buffered = _primaryPlayer.bufferedPosition;
      final total = _primaryPlayer.duration ?? Duration.zero;
      final speed = _primaryPlayer.speed;
      
      _positionController.add(PlaybackPosition(
        position: position,
        buffered: buffered,
        total: total,
        speed: speed,
      ));
    } catch (e) {
      // Silent fail
    }
  }
  
  void _handlePlayerState(ja.PlayerState state) {
    // Handle player state changes
  }
  
  void _handleProcessingState(ja.ProcessingState state) {
    switch (state) {
      case ja.ProcessingState.idle:
        _setState(AudioState.idle);
        break;
      case ja.ProcessingState.loading:
        _setState(AudioState.loading);
        break;
      case ja.ProcessingState.buffering:
        _setState(AudioState.buffering);
        break;
      case ja.ProcessingState.ready:
        if (_primaryPlayer.playing) {
          _setState(AudioState.playing);
        } else {
          _setState(AudioState.paused);
        }
        break;
      case ja.ProcessingState.completed:
        _handlePlaybackCompleted();
        break;
    }
  }
  
  void _handlePlaybackCompleted() {
    if (_repeatMode == RepeatMode.one) {
      unawaited(seek(Duration.zero));
      unawaited(play());
    } else {
      unawaited(next());
    }
  }
  
  void _setState(AudioState state) {
    if (_disposed) return;
    _stateController.add(state);
  }
  
  // ============================================
  // PERFORMANCE OPTIMIZATION
  // ============================================
  
  void trimMemory() {
    if (_disposed) return;
    
    // Clear old cache if memory pressure is high
    final now = DateTime.now();
    if (now.difference(_lastInteraction) > const Duration(minutes: 30)) {
      _cache.clear();
      _currentCacheSize = 0;
    }
  }
  
  Future<void> warmup() async {
    // Pre-initialize audio session and buffer
    try {
      await _primaryPlayer.setSpeed(1.0);
      await _primaryPlayer.setVolume(0.0);
    } catch (e) {
      // Silent fail
    }
  }
  
  // ============================================
  // CLEANUP
  // ============================================
  
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    
    _visualizationTimer?.cancel();
    
    await _primaryPlayer.dispose();
    await _precachePlayer.dispose();
    
    await _stateController.close();
    await _positionController.close();
    await _currentTrackController.close();
    await _volumeController.close();
    await _visualizationController.close();
    await _errorController.close();
    
    _cache.clear();
    _pendingDownloads.clear();
    
    debugPrint('🔇 Audio Kernel disposed');
  }
}

// ============================================
// HELPER FUNCTIONS
// ============================================

void unawaited(Future<dynamic> future) {
  // Helper to avoid "unawaited" warnings
  future.then((_) {});
}

// ============================================
// ERROR HANDLING EXTENSIONS
// ============================================

extension AudioKernelErrorHandling on AudioKernel {
  Future<T> withRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
  }) async {
    for (var i = 0; i < maxRetries; i++) {
      try {
        return await operation();
      } catch (e) {
        if (i == maxRetries - 1) rethrow;
        await Future.delayed(delay * (i + 1));
      }
    }
    throw StateError('Max retries exceeded');
  }
}

// ============================================
// PLAYBACK QUEUE EXTENSION
// ============================================

class PlaybackQueue {
  final List<AudioTrack> _queue = [];
  final List<AudioTrack> _history = [];
  final AudioKernel _kernel = AudioKernel();
  
  void enqueue(AudioTrack track) {
    _queue.add(track);
  }
  
  void enqueueNext(AudioTrack track) {
    _queue.insert(0, track);
  }
  
  Future<void> playNext() async {
    if (_queue.isNotEmpty) {
      final track = _queue.removeAt(0);
      _history.add(track);
      await _kernel.playTrack(track);
    }
  }
  
  Future<void> playPrevious() async {
    if (_history.length > 1) {
      _history.removeLast(); // Remove current
      final previous = _history.removeLast();
      _queue.insert(0, previous);
      await _kernel.playTrack(previous);
    }
  }
  
  void clear() {
    _queue.clear();
    _history.clear();
  }
}

// ============================================
// CACHE MANAGER EXTENSION
// ============================================

class AudioCacheManager {
  static final AudioCacheManager _instance = AudioCacheManager._internal();
  factory AudioCacheManager() => _instance;
  AudioCacheManager._internal();
  
  final Map<String, DateTime> _accessTimes = {};
  final Map<String, int> _accessCounts = {};
  
  String getCacheKey(String uri, {String quality = 'high'}) {
    return '${sha256.convert(utf8.encode(uri))}_$quality';
  }
  
  Future<bool> isCached(String uri) async {
    final key = getCacheKey(uri);
    final cacheDir = await getTemporaryDirectory();
    final file = File('${cacheDir.path}/audio_cache/$key');
    return file.exists();
  }
  
  Future<void> recordAccess(String uri) async {
    final key = getCacheKey(uri);
    _accessTimes[key] = DateTime.now();
    _accessCounts[key] = (_accessCounts[key] ?? 0) + 1;
  }
  
  List<String> getLRUCacheKeys({int count = 10}) {
    final entries = _accessTimes.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    
    return entries.take(count).map((e) => e.key).toList();
  }
}

// ============================================
// VISUALIZATION PROCESSOR
// ============================================

class FFTProcessor {
  static Float64List computeFFT(Float64List samples) {
    // Placeholder for actual FFT implementation
    // In production, use a package like fft or implement Cooley-Tukey
    final n = samples.length;
    final result = Float64List(n);
    
    // Simple DFT (replace with FFT for performance)
    for (var k = 0; k < n; k++) {
      var real = 0.0;
      var imag = 0.0;
      
      for (var t = 0; t < n; t++) {
        final angle = 2 * pi * k * t / n;
        real += samples[t] * cos(angle);
        imag -= samples[t] * sin(angle);
      }
      
      result[k] = sqrt(real * real + imag * imag) / n;
    }
    
    return result;
  }
  
  static List<double> applyWindow(Float64List samples, String windowType) {
    final windowed = Float64List(samples.length);
    final n = samples.length;
    
    for (var i = 0; i < n; i++) {
      double windowValue = 1.0;
      
      switch (windowType) {
        case 'hann':
          windowValue = 0.5 * (1 - cos(2 * pi * i / (n - 1)));
          break;
        case 'hamming':
          windowValue = 0.54 - 0.46 * cos(2 * pi * i / (n - 1));
          break;
        case 'blackman':
          windowValue = 0.42 - 
            0.5 * cos(2 * pi * i / (n - 1)) + 
            0.08 * cos(4 * pi * i / (n - 1));
          break;
      }
      
      windowed[i] = samples[i] * windowValue;
    }
    
    return windowed;
  }
}

// ============================================
// MAIN EXPORT
// ============================================

// Export key components
export 'audio_kernel.dart' show
  AudioKernel,
  AudioTrack,
  PlaybackPosition,
  AudioState,
  RepeatMode,
  CachePolicy,
  AudioVisualizationData,
  PlaybackQueue,
  AudioCacheManager,
  FFTProcessor;