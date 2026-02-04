// lib/core/audio_kernel.dart
// Enhanced Professional Audio Engine - Fixed & Optimized (Music Mode, Background, High Quality)

import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:rxdart/rxdart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

enum AudioState { idle, loading, buffering, playing, paused, stopped, error }
enum RepeatMode { none, one, all }

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
    androidOffloadToHardware: true,
  );

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

  final _cacheDirFuture = getTemporaryDirectory().then((dir) => Directory('${dir.path}/cent_cache')..create(recursive: true));

  Future<void> initialize() async {
    if (_initialized || _disposed) return;

    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music(
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.allowBluetooth | AVAudioSessionCategoryOptions.defaultToSpeaker,
      ));

      session.interruptionEventStream.listen((event) {
        if (event.begin) {
          if (state == AudioState.playing) _player.pause();
        } else {
          if (state == AudioState.paused) _player.play();
        }
      });

      _player.positionStream.listen((pos) => _position.add(pos));
      _player.durationStream.listen((dur) => _duration.add(dur));
      _player.playerStateStream.listen((ps) {
        if (ps.playing) {
          _state.add(AudioState.playing);
        } else if (ps.processingState == ProcessingState.completed) {
          next();
        } else if (ps.processingState == ProcessingState.buffering) {
          _state.add(AudioState.buffering);
        }
      });

      _player.errorStream.listen((err) {
        _state.add(AudioState.error);
        _errors.add(err.toString());
      });

      _initialized = true;
    } catch (e) {
      _errors.add('Init error: $e');
    }
  }

  Future<void> playTrack(AudioTrack track) async {
    if (_disposed) return;

    try {
      _state.add(AudioState.loading);
      _currentTrack.add(track);

      final cached = await _getCachedFile(track.uri);
      final source = cached != null
          ? LockCachingAudioSource(Uri.file(cached.path))
          : LockCachingAudioSource(Uri.parse(track.uri));

      await _player.setAudioSource(source, preload: true);

      final session = await AudioSession.instance;
      if (await session.setActive(true)) {
        await _player.play();
        _state.add(AudioState.playing);
      }
    } catch (e) {
      _state.add(AudioState.error);
      _errors.add('Play error: $e');
    }
  }

  Future<File?> _getCachedFile(String uri) async {
    try {
      final cacheDir = await _cacheDirFuture;
      final hash = md5.convert(utf8.encode(uri)).toString();
      final file = File('${cacheDir.path}/$hash.audio');
      if (await file.exists()) return file;
    } catch (_) {}
    return null;
  }

  Future<void> play() async {
    final session = await AudioSession.instance;
    if (await session.setActive(true)) await _player.play();
  }

  Future<void> pause() => _player.pause();
  Future<void> stop() async {
    await _player.stop();
    _state.add(AudioState.stopped);
    _currentTrack.add(null);
    final session = await AudioSession.instance;
    await session.setActive(false);
  }

  Future<void> seek(Duration pos) => _player.seek(pos);
  Future<void> setVolume(double vol) => _player.setVolume(vol.clamp(0.0, 1.0));

  Future<void> next() async {
    // TODO: Implement playlist logic if needed
    stop();
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
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
