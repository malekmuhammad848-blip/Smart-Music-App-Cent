// mobile/lib/src/features/player/services/player_service.dart
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:rxdart/rxdart.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cent_app/src/core/services/api_service.dart';

class PlayerService extends BaseAudioHandler {
  final AudioPlayer _audioPlayer;
  final ApiService _apiService;
  final Connectivity _connectivity;
  
  final _playlist = ConcatenatingAudioSource(children: []);
  final _currentIndex = BehaviorSubject<int>.seeded(-1);
  final _playerState = BehaviorSubject<PlayerState>.seeded(PlayerState.stopped);
  final _playbackState = BehaviorSubject<PlaybackState>.seeded(PlaybackState.none);
  final _currentPosition = BehaviorSubject<Duration>.seeded(Duration.zero);
  final _bufferedPosition = BehaviorSubject<Duration>.seeded(Duration.zero);
  final _duration = BehaviorSubject<Duration?>.seeded(null);
  
  List<Track> _queue = [];
  Track? _currentTrack;
  
  PlayerService(this._apiService, this._connectivity) 
      : _audioPlayer = AudioPlayer() {
    _setupAudioPlayer();
    _setupConnectivityListener();
    _loadOfflineCache();
  }
  
  void _setupAudioPlayer() {
    // Configure audio player
    _audioPlayer.setLoopMode(LoopMode.off);
    _audioPlayer.setSpeed(1.0);
    
    // Listen to player events
    _audioPlayer.playerStateStream.listen((playerState) {
      _playerState.add(playerState);
      _updatePlaybackState();
    });
    
    _audioPlayer.positionStream.listen(_currentPosition.add);
    _audioPlayer.bufferedPositionStream.listen(_bufferedPosition.add);
    _audioPlayer.durationStream.listen(_duration.add);
    
    _audioPlayer.currentIndexStream.listen((index) {
      if (index != null && index < _queue.length) {
        _currentIndex.add(index);
        _currentTrack = _queue[index];
        _updateMediaItem();
        _recordPlayback();
      }
    });
    
    _audioPlayer.processingStateStream.listen((processingState) {
      _updatePlaybackState();
    });
    
    _audioPlayer.sequenceStateStream.listen((sequenceState) {
      if (sequenceState != null) {
        _updateQueue(sequenceState.effectiveSequence);
      }
    });
  }
  
  Future<void> playTrack(Track track, {List<Track>? queue}) async {
    try {
      // Check connectivity for streaming quality
      final connectivity = await _connectivity.checkConnectivity();
      final quality = _getQualityForConnectivity(connectivity);
      
      // Get streaming URL
      final streamUrl = await _apiService.getStreamUrl(
        track.id, 
        quality: quality
      );
      
      // Create audio source
      final audioSource = ProgressiveAudioSource(
        Uri.parse(streamUrl),
        tag: MediaItem(
          id: track.id,
          title: track.title,
          artist: track.artistName,
          album: track.albumTitle,
          artUri: Uri.parse(track.coverUrl),
          duration: Duration(milliseconds: track.durationMs),
          extras: {
            'track': track.toJson(),
            'quality': quality,
          },
        ),
      );
      
      if (queue != null && queue.isNotEmpty) {
        // Replace entire queue
        _queue = [track, ...queue];
        await _audioPlayer.setAudioSource(
          ConcatenatingAudioSource(children: [
            audioSource,
            ...queue.map((t) => _createAudioSource(t, quality)),
          ]),
          initialIndex: 0,
        );
      } else {
        // Add to current queue
        await _audioPlayer.addAudioSource(audioSource);
        _queue.add(track);
      }
      
      await play();
      
    } catch (error) {
      // Check offline cache
      final offlinePath = await _getOfflineTrackPath(track.id);
      if (offlinePath != null) {
        await playOfflineTrack(track, offlinePath);
      } else {
        rethrow;
      }
    }
  }
  
  Future<void> playOfflineTrack(Track track, String filePath) async {
    final audioSource = AudioSource.uri(
      Uri.file(filePath),
      tag: MediaItem(
        id: track.id,
        title: track.title,
        artist: track.artistName,
        album: track.albumTitle,
        artUri: Uri.parse(track.coverUrl),
        duration: Duration(milliseconds: track.durationMs),
        extras: {
          'track': track.toJson(),
          'offline': true,
        },
      ),
    );
    
    await _audioPlayer.setAudioSource(audioSource);
    await play();
  }
  
  Future<void> downloadTrack(Track track, {AudioQuality quality = AudioQuality.high}) async {
    final downloadBox = await Hive.openBox('downloads');
    final downloadKey = '${track.id}_${quality.name}';
    
    // Check if already downloading
    if (downloadBox.get(downloadKey) == 'downloading') {
      return;
    }
    
    // Start download
    downloadBox.put(downloadKey, 'downloading');
    
    try {
      final downloadUrl = await _apiService.getDownloadUrl(track.id, quality);
      final savePath = await _getDownloadPath(track, quality);
      
      // Download with progress tracking
      await _apiService.downloadFile(
        downloadUrl,
        savePath,
        onProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 100).toInt();
            // Update download progress
          }
        },
      );
      
      // Save metadata
      final metadata = {
        'track': track.toJson(),
        'quality': quality.name,
        'downloaded_at': DateTime.now().toIso8601String(),
        'file_path': savePath,
        'file_size': await File(savePath).length(),
      };
      
      await downloadBox.put(downloadKey, metadata);
      
      // Update offline cache
      await _updateOfflineCache(track, savePath);
      
    } catch (error) {
      downloadBox.delete(downloadKey);
      rethrow;
    }
  }
  
  Future<void> setEqualizerPreset(EqualizerPreset preset) async {
    await _audioPlayer.setVolume(preset.volume);
    
    if (preset.bass != 0 || preset.treble != 0 || preset.mid != 0) {
      // Apply EQ effects (platform-specific implementation)
      await _applyEqualizer(preset);
    }
  }
  
  Future<void> setCrossfade(Duration duration) async {
    _audioPlayer.setCrossfadeDuration(duration);
  }
  
  Future<void> setGaplessPlayback(bool enabled) async {
    _audioPlayer.setGapless(enabled);
  }
  
  Future<void> setSleepTimer(Duration duration) async {
    _sleepTimer?.cancel();
    
    _sleepTimer = Timer(duration, () async {
      await pause();
      _sleepTimer = null;
    });
  }
  
  Future<void> enableCarMode() async {
    // Configure for car playback
    await _audioPlayer.setAutomaticallyWaitsToMinimizeStalling(false);
    await setEqualizerPreset(EqualizerPreset.car);
    
    // Setup car controls
    await AudioServiceBackground.setQueue(_queue.map((track) => track.toMediaItem()).toList());
  }
  
  Stream<PlayerState> get playerStateStream => _playerState.stream;
  Stream<Duration> get positionStream => _currentPosition.stream;
  Stream<Duration?> get durationStream => _duration.stream;
  Stream<Track?> get currentTrackStream => _currentIndex.stream
      .map((index) => index >= 0 && index < _queue.length ? _queue[index] : null);
  
  List<Track> get queue => List.unmodifiable(_queue);
  Track? get currentTrack => _currentTrack;
  
  Future<void> play() => _audioPlayer.play();
  Future<void> pause() => _audioPlayer.pause();
  Future<void> stop() => _audioPlayer.stop();
  Future<void> seek(Duration position) => _audioPlayer.seek(position);
  Future<void> skipToNext() => _audioPlayer.seekToNext();
  Future<void> skipToPrevious() => _audioPlayer.seekToPrevious();
  Future<void> setVolume(double volume) => _audioPlayer.setVolume(volume);
  Future<void> setSpeed(double speed) => _audioPlayer.setSpeed(speed);
  
  Future<void> addToQueue(Track track) async {
    final quality = await _getCurrentQuality();
    final audioSource = _createAudioSource(track, quality);
    await _audioPlayer.addAudioSource(audioSource);
    _queue.add(track);
  }
  
  Future<void> removeFromQueue(int index) async {
    if (index >= 0 && index < _queue.length) {
      await _audioPlayer.removeAudioSourceAt(index);
      _queue.removeAt(index);
    }
  }
  
  Future<void> shuffleQueue() async {
    final shuffled = List<Track>.from(_queue)..shuffle();
    await _loadQueue(shuffled);
  }
  
  void _updatePlaybackState() {
    final processingState = _audioPlayer.processingState;
    final playing = _audioPlayer.playing;
    
    _playbackState.add(PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[processingState]!,
      playing: playing,
      updatePosition: _currentPosition.value,
      bufferedPosition: _bufferedPosition.value,
      speed: _audioPlayer.speed,
      queueIndex: _currentIndex.value,
    ));
  }
  
  void _updateMediaItem() {
    if (_currentTrack != null) {
      mediaItem.add(_currentTrack!.toMediaItem());
    }
  }
  
  void _recordPlayback() {
    if (_currentTrack != null) {
      // Record play in local database
      _recordLocalPlay(_currentTrack!);
      
      // Sync with server periodically
      _syncPlayHistory();
    }
  }
  
  AudioQuality _getQualityForConnectivity(ConnectivityResult connectivity) {
    switch (connectivity) {
      case ConnectivityResult.wifi:
        return AudioQuality.veryHigh;
      case ConnectivityResult.ethernet:
        return AudioQuality.lossless;
      case ConnectivityResult.mobile:
        return AudioQuality.high;
      case ConnectivityResult.vpn:
        return AudioQuality.medium;
      default:
        return AudioQuality.low;
    }
  }
  
  Future<AudioQuality> _getCurrentQuality() async {
    final connectivity = await _connectivity.checkConnectivity();
    return _getQualityForConnectivity(connectivity);
  }
  
  ProgressiveAudioSource _createAudioSource(Track track, AudioQuality quality) {
    return ProgressiveAudioSource(
      Uri.parse(track.getStreamUrl(quality)),
      tag: MediaItem(
        id: track.id,
        title: track.title,
        artist: track.artistName,
        album: track.albumTitle,
        artUri: Uri.parse(track.coverUrl),
        duration: Duration(milliseconds: track.durationMs),
        extras: {'track': track.toJson()},
      ),
    );
  }
}
