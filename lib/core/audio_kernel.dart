// lib/core/audio_kernel.dart
// Enhanced Efficient Audio Engine - Best practices 2026
// High quality, gapless-ready, background-capable, low resource usage

import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:rxdart/rxdart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';

enum AudioState { idle, loading, buffering, playing, paused, stopped, error }

class AudioTrack {
  final String id;
  final String uri;
  final String title;
  final String artist;
  final Duration? duration;
  final String? coverArt;
  final Map<String, dynamic> metadata;

  AudioTrack({
    required this.id,
    required this.uri,
    required this.title,
    required this.artist,
    this.duration,
    this.coverArt,
    this.metadata = const {},
  });
}

class AudioKernel {
  static final AudioKernel _instance = AudioKernel._internal();
  factory AudioKernel() => _instance;
  AudioKernel._internal();

  final _player = AudioPlayer(
    handleInterruptions: true,
    androidApplyAudioAttributes: true,
    androidOffloadToHardware: true, // أفضل جودة + توفير بطارية
    audioPipeline: const AudioPipeline(
      androidAudioSessionCategory: AndroidAudioSessionCategory.playback,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.music,
        flags: AndroidAudioFlags.none,
        usage: AndroidAudioUsage.media,
      ),
    ),
  );

  // Streams
  final _state = BehaviorSubject<AudioState>.seeded(AudioState.idle);
  final _position = BehaviorSubject<Duration>.seeded(Duration.zero);
  final _duration = BehaviorSubject<Duration?>.seeded(null);
  final _currentTrack = BehaviorSubject<AudioTrack?>.seeded(null);
  final _errors = PublishSubject<String>();

  Stream<AudioState> get stateStream => _state.distinct();
  Stream<Duration> get positionStream => _position;
  Stream<Duration?> get durationStream => _duration;
  Stream<AudioTrack?> get currentTrackStream => _currentTrack;
  Stream<String> get errorStream => _errors;

  AudioState get state => _state.value;
  Duration get position => _position.value;
  AudioTrack? get currentTrack => _currentTrack.value;

  bool _initialized = false;
  bool _disposed = false;

  // Cache basics (يمكن توسيعها)
  final _cacheDirFuture = getTemporaryDirectory().then((dir) => Directory('${dir.path}/cent_cache')..create(recursive: true));

  Future<void> initialize() async {
    if (_initialized || _disposed) return;

    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music(
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.allowBluetooth |
            AVAudioSessionCategoryOptions.defaultToSpeaker,
      ));

      // Handle interruptions (مكالمات، إشعارات، إلخ)
      session.interruptionEventStream.listen((event) {
        if (event.begin) {
          if (state == AudioState.playing) _player.pause();
        } else {
          if (state == AudioState.paused) _player.play();
        }
      });

      // Player listeners
      _player.positionStream.listen((pos) => _position.add(pos));
      _player.durationStream.listen((dur) => _duration.add(dur));
      _player.playerStateStream.listen((ps) {
        if (ps.playing) {
          _state.add(AudioState.playing);
        } else if (ps.processingState == ProcessingState.completed) {
          _handleCompletion();
        } else if (ps.processingState == ProcessingState.buffering) {
          _state.add(AudioState.buffering);
        }
      });

      _player.playbackEventStream.listen((event) {
        // يمكن استخراج metadata إضافي هنا إذا أردت
      });

      _player.errorStream.listen((err) {
        _state.add(AudioState.error);
        _errors.add(err.toString());
        debugPrint('Audio error: $err');
      });

      _initialized = true;
      debugPrint('AudioKernel initialized - efficient high-quality mode');
    } catch (e, st) {
      debugPrint('Init failed: $e\n$st');
      _errors.add('Initialization error: $e');
    }
  }

  Future<void> playTrack(AudioTrack track) async {
    if (_disposed) return;

    try {
      _state.add(AudioState.loading);
      _currentTrack.add(track);

      // Cache check (بسيط، يمكن تحسين)
      final cachedFile = await _getCachedFile(track.uri);
      final source = cachedFile != null
          ? LockCachingAudioSource(Uri.file(cachedFile.path))
          : LockCachingAudioSource(Uri.parse(track.uri)); // caching تلقائي

      await _player.setAudioSource(source, preload: true);

      final session = await AudioSession.instance;
      if (await session.setActive(true)) {
        await _player.play();
        _state.add(AudioState.playing);
      }
    } catch (e, st) {
      _state.add(AudioState.error);
      _errors.add('Play failed: $e');
      debugPrint('Play error: $e\n$st');
    }
  }

  Future<File?> _getCachedFile(String uri) async {
    try {
      final cacheDir = await _cacheDirFuture;
      final hash = md5.convert(utf8.encode(uri)).toString();
      final file = File('${cacheDir.path}/$hash.audio');
      if (await file.exists() && await file.length() > 0) {
        return file;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> pause() => _player.pause().then((_) => _state.add(AudioState.paused));
  Future<void> play() async {
    final session = await AudioSession.instance;
    if (await session.setActive(true)) {
      await _player.play();
      _state.add(AudioState.playing);
    }
  }

  Future<void> stop() async {
    await _player.stop();
    _state.add(AudioState.stopped);
    _currentTrack.add(null);
    final session = await AudioSession.instance;
    await session.setActive(false);
  }

  Future<void> seek(Duration pos) => _player.seek(pos);

  Future<void> setVolume(double vol) => _player.setVolume(vol.clamp(0.0, 1.0));

  Future<void> setSpeed(double speed) => _player.setSpeed(speed.clamp(0.5, 3.0));

  void _handleCompletion() {
    // هنا يمكنك إضافة next() للـ playlist
    stop(); // أو next track إذا كان عندك playlist
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    await _player.stop();
    await _player.dispose();
    await _state.close();
    await _position.close();
    await _duration.close();
    await _currentTrack.close();
    await _errors.close();

    final session = await AudioSession.instance;
    await session.setActive(false);
  }
}
