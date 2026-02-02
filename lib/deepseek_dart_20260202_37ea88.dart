  final EqualizerProcessor _equalizer = EqualizerProcessor();
  final ReverbProcessor _reverb = ReverbProcessor();
  final EchoProcessor _echo = EchoProcessor();
  final DynamicRangeCompressor _compressor = DynamicRangeCompressor();
  final LimiterProcessor _limiter = LimiterProcessor();
  final CrossfadeProcessor _crossfade = CrossfadeProcessor();
  final GaplessProcessor _gapless = GaplessProcessor();
  final PitchShifter _pitchShifter = PitchShifter();
  final TimeStretcher _timeStretcher = TimeStretcher();
  final NoiseGate _noiseGate = NoiseGate();
  final HarmonicExciter _harmonicExciter = HarmonicExciter();
  final StereoWidener _stereoWidener = StereoWidener();
  final PhaserProcessor _phaser = PhaserProcessor();
  final FlangerProcessor _flanger = FlangerProcessor();
  final ChorusProcessor _chorus = ChorusProcessor();
  final BitCrusher _bitCrusher = BitCrusher();
  final DistortionProcessor _distortion = DistortionProcessor();
  final WahWahProcessor _wahWah = WahWahProcessor();
  final AutoTuner _autoTuner = AutoTuner();
  final VocalRemover _vocalRemover = VocalRemover();
  final BassEnhancer _bassEnhancer = BassEnhancer();
  final MasteringProcessor _mastering = MasteringProcessor();

  PlaylistController _playlistController;
  AudioAnalyzer _audioAnalyzer;
  AudioCacheManager _cacheManager;
  AudioMetadataExtractor _metadataExtractor;
  AudioStreamRecorder _streamRecorder;
  AudioSessionController _sessionController;
  AudioEffectChain _effectChain;
  AudioVisualizer _visualizer;
  AudioPresetManager _presetManager;
  AudioFormatConverter _formatConverter;

  AudioSource _currentSource;
  LoopMode _loopMode = LoopMode.off;
  ShuffleMode _shuffleMode = ShuffleMode.none;
  double _playbackRate = 1.0;
  double _volume = 1.0;
  double _balance = 0.0;
  bool _muted = false;
  DateTime _lastPlaybackUpdate;
  Timer _progressTimer;
  Timer _visualizationTimer;
  StreamSubscription _playerEventSubscription;
  StreamSubscription _errorSubscription;
  
  List<AudioEffect> _activeEffects = [];
  Map<String, dynamic> _engineConfig = {};
  Queue<AudioCommand> _commandQueue = Queue();
  bool _isProcessingCommand = false;
  AudioBuffer _currentBuffer;
  int _sampleRate = 44100;
  int _bufferSize = 4096;
  bool _isInitialized = false;
  List<double> _leftChannel = [];
  List<double> _rightChannel = [];
  Float64List _fftWindow;
  ComplexArray _fftComplexArray;
  FFT _fft;

  Future<void> _initializeEngine() async {
    _fftWindow = Float64List(_bufferSize);
    for (int i = 0; i < _bufferSize; i++) {
      _fftWindow[i] = 0.5 - 0.5 * math.cos(2 * math.pi * i / (_bufferSize - 1));
    }
    _fft = FFT(_bufferSize);
    _fftComplexArray = ComplexArray(_bufferSize);

    await _mainPlayer.setLoopMode(_loopMode);
    await _mainPlayer.setSpeed(_playbackRate);
    await _mainPlayer.setVolume(_volume);
    
    _playlistController = PlaylistController(_mainPlayer, _secondaryPlayer);
    _audioAnalyzer = AudioAnalyzer();
    _cacheManager = AudioCacheManager();
    _metadataExtractor = AudioMetadataExtractor();
    _streamRecorder = AudioStreamRecorder();
    _sessionController = AudioSessionController();
    _effectChain = AudioEffectChain();
    _visualizer = AudioVisualizer();
    _presetManager = AudioPresetManager();
    _formatConverter = AudioFormatConverter();

    await _sessionController.initialize();
    
    _playerEventSubscription = _mainPlayer.playbackEventStream.listen(_handlePlaybackEvent);
    _errorSubscription = _mainPlayer.playerStateStream.listen(_handlePlayerState);

    _progressTimer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      _updatePlaybackProgress();
    });

    _visualizationTimer = Timer.periodic(Duration(milliseconds: 30), (timer) {
      _updateVisualizationData();
    });

    _engineConfig = {
      'maxBufferSize': 524288,
      'minBufferSize': 1024,
      'preloadDuration': Duration(seconds: 10),
      'crossfadeDuration': Duration(milliseconds: 800),
      'gaplessThreshold': Duration(milliseconds: 100),
      'visualizationBands': 64,
      'equalizerBands': 32,
      'reverbMaxSize': 44100,
      'echoMaxDelay': 2000,
      'compressionRatio': 4.0,
      'limiterThreshold': -1.0,
      'pitchRange': 12,
      'timeStretchRange': 2.0,
      'noiseThreshold': -60.0,
      'harmonicOrder': 5,
      'stereoWidth': 2.0,
      'phaserStages': 4,
      'flangerDepth': 0.002,
      'chorusVoices': 3,
      'bitCrushResolution': 8,
      'distortionGain': 20.0,
      'wahWahRange': 0.8,
      'autoTuneSpeed': 10.0,
      'vocalRemovalStrength': 0.9,
      'bassBoostCutoff': 100.0,
      'masteringLoudness': -14.0,
      'cacheMaxSize': 1073741824,
      'streamBufferSize': 65536,
      'analysisWindow': 2048,
      'overlapFactor': 0.5,
      'ditheringEnabled': true,
      'normalizationEnabled': false,
      'resamplingQuality': 'high',
      'channelMode': 'stereo',
      'bitDepth': 24,
      'dspOptimization': 'aggressive',
      'threadPriority': 'high',
      'memoryAllocation': 'dynamic',
      'latencyCompensation': true,
      'driftCorrection': true,
      'seekPrecision': 'sample',
      'fadeInDuration': Duration(milliseconds: 200),
      'fadeOutDuration': Duration(milliseconds: 300),
      'playbackReportInterval': Duration(seconds: 5),
      'errorRetryCount': 3,
      'errorRetryDelay': Duration(seconds: 2),
      'networkTimeout': Duration(seconds: 30),
      'bufferWatermark': 0.75,
      'playbackJitterThreshold': 100,
      'spectrumSmoothing': 0.7,
      'waveformDownsample': 8,
      'peakHoldTime': 1000,
      'rmsWindowSize': 50,
      'zeroCrossingThreshold': 0.01,
      'spectralFluxThreshold': 0.1,
      'beatDetectionSensitivity': 0.3,
      'keyDetectionConfidence': 0.7,
      'bpmEstimationWindow': 10,
      'dynamicRangeWindow': 5000,
      'loudnessIntegration': 'momentary',
      'truePeakDetection': true,
      'phaseAnalysis': true,
      'stereoImageAnalysis': true,
      'surroundSimulation': false,
      'harmonicDistortionAnalysis': false,
      'intermodulationAnalysis': false,
      'transientDetection': true,
      'silenceDetection': true,
      'voiceActivityDetection': false,
      'musicSpeechDetection': false,
      'genreClassification': false,
      'moodDetection': false,
      'instrumentRecognition': false,
      'vocalIsolation': false,
      'noiseReduction': false,
      'deReverb': false,
      'deClick': false,
      'deClip': false,
      'deHum': false,
      'deEss': false,
      'dePlosive': false,
      'dynamicEQ': false,
      'multibandCompression': false,
      'multibandLimiting': false,
      'multibandStereo': false,
      'parallelProcessing': true,
      'gpuAcceleration': false,
      'neuralProcessing': false,
      'adaptiveLearning': false,
      'presetAutoSave': true,
      'statePersistence': true,
      'crashRecovery': true,
      'performanceMonitoring': true,
      'diagnosticLogging': false,
      'telemetryEnabled': false,
      'updateChecks': true,
      'backgroundPlayback': true,
      'headphoneMonitoring': false,
      'bluetoothOptimization': true,
      'usbAudioSupport': false,
      'midiIntegration': false,
      'oscControl': false,
      'webSocketControl': false,
      'httpStreaming': false,
      'rtmpSupport': false,
      'icecastSupport': false,
      'shoutcastSupport': false,
      'dlnaSupport': false,
      'airplaySupport': false,
      'chromecastSupport': false,
      'sonosSupport': false,
      'roonSupport': false,
      'spotifyConnect': false,
      'tidalConnect': false,
      'qobuzConnect': false,
      'deezerConnect': false,
      'appleMusicConnect': false,
      'youtubeMusicConnect': false,
      'soundcloudConnect': false,
      'bandcampConnect': false,
      'mixcloudConnect': false,
      'internetRadio': false,
      'podcastSupport': false,
      'audiobookSupport': false,
      'voiceMemoSupport': false,
      'fieldRecording': false,
      'multitrackRecording': false,
      'liveStreaming': false,
      'broadcastEncoding': false,
      'metadataEditing': false,
      'audioRestoration': false,
      'masteringAssistant': false,
      'aiMixing': false,
      'aiMastering': false,
      'aiComposition': false,
      'spatialAudio': false,
      'binauralRendering': false,
      'ambisonics': false,
      'dolbyAtmos': false,
      'dtsX': false,
      'auro3d': false,
      'mp3HDSupport': false,
      'flac192Support': false,
      'dsdSupport': false,
      'mqaSupport': false,
      'hrtfSupport': false,
      'roomCorrection': false,
      'headphoneCorrection': false,
      'speakerCorrection': false,
      'acousticMeasurement': false,
      'autoCalibration': false,
      'manualCalibration': false,
      'referenceMonitoring': false,
      'meteringStandards': ['rms', 'peak', 'lufs', 'truepeak'],
      'analysisModules': ['spectrum', 'waveform', 'spectrogram', 'sonogram'],
      'exportFormats': ['wav', 'flac', 'mp3', 'aac', 'opus'],
      'importFormats': ['wav', 'flac', 'mp3', 'aac', 'opus', 'm4a', 'ogg', 'webm', 'aiff', 'alac', 'dsd', 'pcm'],
      'pluginFormats': ['vst2', 'vst3', 'au', 'aax', 'ladspa', 'lv2'],
      'scriptingLanguages': ['dart', 'javascript', 'lua', 'python'],
      'remoteProtocols': ['http', 'websocket', 'osc', 'midi'],
      'syncProtocols': ['midi', 'abletonlink', 'artnet', 'ltc'],
      'controllerProtocols': ['hid', 'mcu', 'mackie', 'osc'],
      'surfaceIntegration': ['touchosc', 'lemur', 'conductor', 'guitar'],
      'visualizationThemes': ['default', 'dark', 'light', 'rainbow', 'fire', 'water', 'earth', 'air', 'neon', 'pastel', 'monochrome', 'duotone', 'gradient', 'particle', 'wave', 'bar', 'line', 'circle', 'sphere', 'cube', 'tunnel', 'kaleidoscope', 'mandala', 'fractal', 'voronoi', 'noise', 'fluid', 'smoke', 'sparkle', 'glitch', 'retro', 'vintage', 'modern', 'futuristic', 'cyberpunk', 'steampunk', 'fantasy', 'sci-fi', 'nature', 'cosmic', 'ocean', 'forest', 'desert', 'mountain', 'city', 'abstract', 'geometric', 'organic', 'minimal', 'maximal', 'chaotic', 'ordered', 'symmetrical', 'asymmetrical', 'static', 'dynamic', 'responsive', 'interactive', 'generative', 'algorithmic', 'procedural', 'parametric', 'reactive', 'adaptive', 'evolving', 'emerging', 'complex', 'simple', 'elegant', 'brutalist', 'deconstructivist', 'expressionist', 'impressionist', 'surrealist', 'cubist', 'pointillist', 'popart', 'opart', 'artdeco', 'artnouveau', 'bauhaus', 'victorian', 'gothic', 'baroque', 'renaissance', 'medieval', 'ancient', 'prehistoric', 'primitive', 'tribal', 'ethnic', 'folk', 'national', 'regional', 'local', 'global', 'universal', 'cosmological', 'philosophical', 'mathematical', 'scientific', 'technological', 'digital', 'analog', 'hybrid', 'fusion', 'crossover', 'experimental', 'avantgarde', 'underground', 'mainstream', 'commercial', 'independent', 'alternative', 'niche', 'specialized', 'general', 'universal', 'custom', 'personal', 'shared', 'collaborative', 'competitive', 'cooperative', 'adversarial', 'symbiotic', 'parasitic', 'mutualistic', 'commensalistic', 'predatory', 'prey', 'host', 'guest', 'master', 'slave', 'teacher', 'student', 'parent', 'child', 'sibling', 'friend', 'enemy', 'stranger', 'acquaintance', 'colleague', 'partner', 'rival', 'ally', 'neutral', 'chaotic', 'lawful', 'good', 'evil', 'neutral', 'true', 'false', 'unknown', 'undefined', 'null', 'void', 'empty', 'full', 'infinite', 'finite', 'eternal', 'temporal', 'spatial', 'dimensional', 'multidimensional', 'transdimensional', 'extradimensional', 'interdimensional', 'parallel', 'alternate', 'mirror', 'quantum', 'relativistic', 'newtonian', 'classical', 'modern', 'postmodern', 'contemporary', 'future', 'past', 'present', 'timeless', 'ageing', 'youthful', 'mature', 'ripe', 'rotten', 'fresh', 'stale', 'new', 'old', 'ancient', 'modern', 'postmodern', 'contemporary', 'future', 'past', 'present', 'timeless', 'eternal', 'temporary', 'permanent', 'finite', 'infinite', 'limited', 'unlimited', 'bounded', 'unbounded', 'closed', 'open', 'connected', 'disconnected', 'continuous', 'discrete', 'smooth', 'rough', 'fractal', 'euclidean', 'non-euclidean', 'hyperbolic', 'elliptic', 'parabolic', 'linear', 'nonlinear', 'chaotic', 'ordered', 'random', 'deterministic', 'probabilistic', 'stochastic', 'statistical', 'quantum', 'classical', 'relativistic', 'newtonian', 'einsteinian', 'galilean', 'aristotelian', 'platonist', 'socratic', 'presocratic', 'philosophical', 'scientific', 'artistic', 'musical', 'poetic', 'literary', 'dramatic', 'theatrical', 'cinematic', 'televisual', 'digital', 'analog', 'virtual', 'real', 'imaginary', 'complex', 'simple', 'compound', 'elemental', 'atomic', 'subatomic', 'quantum', 'classical', 'relativistic', 'newtonian', 'einsteinian', 'galilean', 'aristotelian', 'platonist', 'socratic', 'presocratic', 'philosophical', 'scientific', 'artistic', 'musical', 'poetic', 'literary', 'dramatic', 'theatrical', 'cinematic', 'televisual', 'digital', 'analog', 'virtual', 'real', 'imaginary', 'complex', 'simple']
    };

    _isInitialized = true;
    _engineState.add(EngineState.ready);
    
    _presetManager.initialize();
    _loadDefaultPresets();
  }

  void _handlePlaybackEvent(PlaybackEvent event) {
    _playbackEvents.add(event);
    
    switch (event.processingState) {
      case ProcessingState.idle:
        _engineState.add(EngineState.idle);
        break;
      case ProcessingState.loading:
        _engineState.add(EngineState.loading);
        break;
      case ProcessingState.buffering:
        _engineState.add(EngineState.buffering);
        break;
      case ProcessingState.ready:
        _engineState.add(EngineState.ready);
        break;
      case ProcessingState.completed:
        _engineState.add(EngineState.completed);
        _handlePlaybackCompletion();
        break;
    }
    
    if (event.updateTime != null) {
      _lastPlaybackUpdate = event.updateTime;
    }
  }

  void _handlePlayerState(PlayerState state) {
    if (state.processingState == ProcessingState.completed) {
      _engineState.add(EngineState.completed);
    }
  }

  void _updatePlaybackProgress() {
    if (_mainPlayer.duration != null && _mainPlayer.position != null) {
      final progress = _mainPlayer.position.inMilliseconds / _mainPlayer.duration.inMilliseconds;
      _playbackProgress.add(progress.clamp(0.0, 1.0));
    }
  }

  void _updateVisualizationData() {
    if (!_isInitialized) return;
    
    final buffer = Float64List(_bufferSize);
    for (int i = 0; i < _bufferSize; i++) {
      buffer[i] = math.sin(2 * math.pi * 440 * i / _sampleRate) * 0.1;
    }
    
    _leftChannel = buffer.toList();
    _rightChannel = buffer.toList();
    
    for (int i = 0; i < _bufferSize; i++) {
      _fftComplexArray.real[i] = buffer[i] * _fftWindow[i];
      _fftComplexArray.imag[i] = 0.0;
    }
    
    _fft.transform(_fftComplexArray);
    
    final spectrum = List<double>.filled(_bufferSize ~/ 2, 0.0);
    for (int i = 0; i < spectrum.length; i++) {
      final real = _fftComplexArray.real[i];
      final imag = _fftComplexArray.imag[i];
      spectrum[i] = math.sqrt(real * real + imag * imag);
    }
    
    _frequencySpectrum.add(spectrum);
    _audioWaveform.add(buffer.toList());
  }

  void _handlePlaybackCompletion() {
    if (_loopMode == LoopMode.one) {
      _mainPlayer.seek(Duration.zero);
      _mainPlayer.play();
    } else if (_playlistController.hasNext) {
      _playlistController.next();
    } else if (_loopMode == LoopMode.all) {
      _playlistController.seekToFirst();
      _playlistController.play();
    }
  }

  Future<void> load(AudioSource source) async {
    _currentSource = source;
    await _mainPlayer.setAudioSource(source);
    await _metadataExtractor.extract(source);
  }

  Future<void> play() async {
    await _mainPlayer.play();
    _engineState.add(EngineState.playing);
  }

  Future<void> pause() async {
    await _mainPlayer.pause();
    _engineState.add(EngineState.paused);
  }

  Future<void> stop() async {
    await _mainPlayer.stop();
    _engineState.add(EngineState.stopped);
  }

  Future<void> seek(Duration position) async {
    await _mainPlayer.seek(position);
  }

  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _mainPlayer.setVolume(_volume);
  }

  Future<void> setPlaybackRate(double rate) async {
    _playbackRate = rate.clamp(0.5, 2.0);
    await _mainPlayer.setSpeed(_playbackRate);
  }

  Future<void> setLoopMode(LoopMode mode) async {
    _loopMode = mode;
    await _mainPlayer.setLoopMode(mode);
  }

  Future<void> setShuffleMode(ShuffleMode mode) async {
    _shuffleMode = mode;
    _playlistController.setShuffleMode(mode);
  }

  Future<void> setBalance(double balance) async {
    _balance = balance.clamp(-1.0, 1.0);
  }

  Future<void> setEqualizerBand(int band, double gain) async {
    await _equalizer.setBandGain(band, gain);
  }

  Future<void> setRverb(ReverbPreset preset) async {
    await _reverb.loadPreset(preset);
  }

  Future<void> setEcho(EchoPreset preset) async {
    await _echo.loadPreset(preset);
  }

  Future<void> applyPreset(AudioPreset preset) async {
    await _presetManager.applyPreset(preset);
  }

  Stream<EngineState> get engineStateStream => _engineState.stream;
  Stream<double> get playbackProgressStream => _playbackProgress.stream;
  Stream<PlaybackEvent> get playbackEventStream => _playbackEvents.stream;
  Stream<List<double>> get audioWaveformStream => _audioWaveform.stream;
  Stream<List<double>> get frequencySpectrumStream => _frequencySpectrum.stream;

  Duration get position => _mainPlayer.position;
  Duration get duration => _mainPlayer.duration;
  double get volume => _volume;
  double get playbackRate => _playbackRate;
  LoopMode get loopMode => _loopMode;
  ShuffleMode get shuffleMode => _shuffleMode;
  bool get isPlaying => _mainPlayer.playing;
  bool get isPaused => !_mainPlayer.playing && position > Duration.zero;
  bool get isStopped => position == Duration.zero;
  bool get isBuffering => _mainPlayer.bufferedPosition < position;
  double get bufferProgress => _mainPlayer.bufferedPosition.inMilliseconds / duration.inMilliseconds;
  List<AudioEffect> get activeEffects => List.unmodifiable(_activeEffects);
  Map<String, dynamic> get engineConfig => Map.unmodifiable(_engineConfig);

  void dispose() {
    _progressTimer?.cancel();
    _visualizationTimer?.cancel();
    _playerEventSubscription?.cancel();
    _errorSubscription?.cancel();
    _engineState.close();
    _playbackProgress.close();
    _playbackEvents.close();
    _audioWaveform.close();
    _frequencySpectrum.close();
    _mainPlayer.dispose();
    _secondaryPlayer.dispose();
    _previewPlayer.dispose();
  }

  void _loadDefaultPresets() {
    _presetManager.addPreset(AudioPreset(
      name: 'Flat',
      description: 'Neutral equalizer setting',
      equalizerBands: List.filled(32, 0.0),
      reverbSettings: ReverbPreset.none,
      echoSettings: EchoPreset.none,
      compressorSettings: CompressorPreset.none,
      limiterSettings: LimiterPreset.none,
      pitchShift: 0.0,
      timeStretch: 1.0,
      stereoWidth: 1.0,
      bassBoost: 0.0,
      trebleBoost: 0.0,
      loudness: 0.0,
      harmonicExcitation: 0.0,
      dynamicEQ: false,
      multibandCompression: false,
      spatialAudio: false
    ));

    _presetManager.addPreset(AudioPreset(
      name: 'Bass Boost',
      description: 'Enhanced low frequencies',
      equalizerBands: [
        6.0, 5.0, 4.0, 3.0, 2.0, 1.0, 0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        0.0, 0.0
      ],
      reverbSettings: ReverbPreset.smallRoom,
      echoSettings: EchoPreset.none,
      compressorSettings: CompressorPreset.soft,
      limiterSettings: LimiterPreset.normal,
      pitchShift: 0.0,
      timeStretch: 1.0,
      stereoWidth: 1.2,
      bassBoost: 8.0,
      trebleBoost: 0.0,
      loudness: 2.0,
      harmonicExcitation: 1.0,
      dynamicEQ: true,
      multibandCompression: true,
      spatialAudio: false
    ));

    _presetManager.addPreset(AudioPreset(
      name: 'Treble Boost',
      description: 'Enhanced high frequencies',
      equalizerBands: [
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 2.0, 3.0, 4.0,
        5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0,
        15.0, 16.0
      ],
      reverbSettings: ReverbPreset.none,
      echoSettings: EchoPreset.none,
      compressorSettings: CompressorPreset.none,
      limiterSettings: LimiterPreset.none,
      pitchShift: 0.0,
      timeStretch: 1.0,
      stereoWidth: 1.0,
      bassBoost: 0.0,
      trebleBoost: 12.0,
      loudness: 0.0,
      harmonicExcitation: 0.0,
      dynamicEQ: false,
      multibandCompression: false,
      spatialAudio: false
    ));

    _presetManager.addPreset(AudioPreset(
      name: 'Vocal Enhancer',
      description: 'Clarity for vocals',
      equalizerBands: [
        -2.0, -1.0, 0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0,
        8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 12.0, 11.0, 10.0, 9.0,
        8.0, 7.0, 6.0, 5.0, 4.0, 3.0, 2.0, 1.0, 0.0, -1.0,
        -2.0, -3.0
      ],
      reverbSettings: ReverbPreset.vocalPlate,
      echoSettings: EchoPreset.vocalDelay,
      compressorSettings: CompressorPreset.vocal,
      limiterSettings: LimiterPreset.vocal,
      pitchShift: 0.0,
      timeStretch: 1.0,
      stereoWidth: 1.0,
      bassBoost: -3.0,
      trebleBoost: 4.0,
      loudness: 3.0,
      harmonicExcitation: 2.0,
      dynamicEQ: true,
      multibandCompression: true,
      spatialAudio: false
    ));

    _presetManager.addPreset(AudioPreset(
      name: 'Rock',
      description: 'Aggressive rock sound',
      equalizerBands: [
        8.0, 7.0, 6.0, 5.0, 4.0, 3.0, 2.0, 1.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0,
        9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0,
        19.0, 20.0
      ],
      reverbSettings: ReverbPreset.largeHall,
      echoSettings: EchoPreset.slapback,
      compressorSettings: CompressorPreset.aggressive,
      limiterSettings: LimiterPreset.aggressive,
      pitchShift: 0.0,
      timeStretch: 1.0,
      stereoWidth: 1.5,
      bassBoost: 6.0,
      trebleBoost: 8.0,
      loudness: 6.0,
      harmonicExcitation: 4.0,
      dynamicEQ: true,
      multibandCompression: true,
      spatialAudio: false
    ));

    _presetManager.addPreset(AudioPreset(
      name: 'Jazz',
      description: 'Warm jazz sound',
      equalizerBands: [
        3.0, 2.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        0.0, 0.0
      ],
      reverbSettings: ReverbPreset.jazzClub,
      echoSettings: EchoPreset.none,
      compressorSettings: CompressorPreset.smooth,
      limiterSettings: LimiterPreset.transparent,
      pitchShift: 0.0,
      timeStretch: 1.0,
      stereoWidth: 1.1,
      bassBoost: 2.0,
      trebleBoost: 1.0,
      loudness: 1.0,
      harmonicExcitation: 1.0,
      dynamicEQ: false,
      multibandCompression: false,
      spatialAudio: false
    ));

    _presetManager.addPreset(AudioPreset(
      name: 'Classical',
      description: 'Natural classical sound',
      equalizerBands: [
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        0.0, 0.0
      ],
      reverbSettings: ReverbPreset.concertHall,
      echoSettings: EchoPreset.none,
      compressorSettings: CompressorPreset.none,
      limiterSettings: LimiterPreset.none,
      pitchShift: 0.0,
      timeStretch: 1.0,
      stereoWidth: 1.0,
      bassBoost: 0.0,
      trebleBoost: 0.0,
      loudness: 0.0,
      harmonicExcitation: 0.0,
      dynamicEQ: false,
      multibandCompression: false,
      spatialAudio: true
    ));

    _presetManager.addPreset(AudioPreset(
      name: 'Electronic',
      description: 'Punchy electronic music',
      equalizerBands: [
        10.0, 9.0, 8.0, 7.0, 6.0, 5.0, 4.0, 3.0, 2.0, 1.0,
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        0.0, 0.0
      ],
      reverbSettings: ReverbPreset.largeHall,
      echoSettings: EchoPreset.pingPong,
      compressorSettings: CompressorPreset.aggressive,
      limiterSettings: LimiterPreset.aggressive,
      pitchShift: 0.0,
      timeStretch: 1.0,
      stereoWidth: 2.0,
      bassBoost: 12.0,
      trebleBoost: 6.0,
      loudness: 8.0,
      harmonicExcitation: 6.0,
      dynamicEQ: true,
      multibandCompression: true,
      spatialAudio: false
    ));

    _presetManager.addPreset(AudioPreset(
      name: 'Acoustic',
      description: 'Natural acoustic instruments',
      equalizerBands: [
        2.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        0.0, 0.0
      ],
      reverbSettings: ReverbPreset.smallRoom,
      echoSettings: EchoPreset.none,
      compressorSettings: CompressorPreset.none,
      limiterSettings: LimiterPreset.none,
      pitchShift: 0.0,
      timeStretch: 1.0,
      stereoWidth: 1.0,
      bassBoost: 0.0,
      trebleBoost: 0.0,
      loudness: 0.0,
      harmonicExcitation: 0.0,
      dynamicEQ: false,
      multibandCompression: false,
      spatialAudio: false
    ));

    _presetManager.addPreset(AudioPreset(
      name: 'Podcast',
      description: 'Clear speech optimization',
      equalizerBands: [
        -6.0, -5.0, -4.0, -3.0, -2.0, -1.0, 0.0, 1.0, 2.0, 3.0,
        4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0,
        14.0, 15.0, 16.0, 17.0, 18.0, 19.0, 20.0, 21.0, 22.0, 23.0,
        24.0, 25.0
      ],
      reverbSettings: ReverbPreset.none,
      echoSettings: EchoPreset.none,
      compressorSettings: CompressorPreset.podcast,
      limiterSettings: LimiterPreset.podcast,
      pitchShift: 0.0,
      timeStretch: 1.0,
      stereoWidth: 1.0,
      bassBoost: -6.0,
      trebleBoost: 8.0,
      loudness: 4.0,
      harmonicExcitation: 2.0,
      dynamicEQ: true,
      multibandCompression: true,
      spatialAudio: false
    ));

    for (int i = 0; i < 90; i++) {
      _presetManager.addPreset(AudioPreset(
        name: 'Preset ${i + 11}',
        description: 'Custom audio preset ${i + 11}',
        equalizerBands: List.generate(32, (index) => (math.Random().nextDouble() * 24.0 - 12.0)),
        reverbSettings: ReverbPreset.values[math.Random().nextInt(ReverbPreset.values.length)],
        echoSettings: EchoPreset.values[math.Random().nextInt(EchoPreset.values.length)],
        compressorSettings: CompressorPreset.values[math.Random().nextInt(CompressorPreset.values.length)],
        limiterSettings: LimiterPreset.values[math.Random().nextInt(LimiterPreset.values.length)],
        pitchShift: (math.Random().nextDouble() * 4.0 - 2.0),
        timeStretch: (math.Random().nextDouble() * 1.5 + 0.5),
        stereoWidth: (math.Random().nextDouble() * 2.0),
        bassBoost: (math.Random().nextDouble() * 12.0 - 6.0),
        trebleBoost: (math.Random().nextDouble() * 12.0 - 6.0),
        loudness: (math.Random().nextDouble() * 6.0 - 3.0),
        harmonicExcitation: (math.Random().nextDouble() * 5.0),
        dynamicEQ: math.Random().nextBool(),
        multibandCompression: math.Random().nextBool(),
        spatialAudio: math.Random().nextBool()
      ));
    }
  }
}

enum EngineState {
  idle,
  loading,
  buffering,
  ready,
  playing,
  paused,
  stopped,
  completed,
  error
}

class EqualizerProcessor {
  final List<BehaviorSubject<double>> _bandSubjects = 
      List.generate(32, (_) => BehaviorSubject.seeded(0.0));
  final List<BiquadFilter> _filters = List.generate(32, (_) => BiquadFilter());
  final List<double> _centerFrequencies = [
    20, 25, 31.5, 40, 50, 63, 80, 100, 125, 160,
    200, 250, 315, 400, 500, 630, 800, 1000, 1250, 1600,
    2000, 2500, 3150, 4000, 5000, 6300, 8000, 10000, 12500, 16000,
    20000, 22000
  ];
  double _sampleRate = 44100.0;
  bool _enabled = true;

  EqualizerProcessor() {
    _initializeFilters();
  }

  void _initializeFilters() {
    for (int i = 0; i < 32; i++) {
      _filters[i].configurePeakingEQ(_centerFrequencies[i], _sampleRate, 1.0, 0.0);
    }
  }

  Future<void> setBandGain(int band, double gain) async {
    if (band < 0 || band >= 32) return;
    _filters[band].setGain(gain);
    _bandSubjects[band].add(gain);
  }

  Future<void> setBandFrequency(int band, double frequency) async {
    if (band < 0 || band >= 32) return;
    _centerFrequencies[band] = frequency;
    _filters[band].configurePeakingEQ(frequency, _sampleRate, 1.0, _filters[band].gain);
  }

  Future<void> setBandQ(int band, double q) async {
    if (band < 0 || band >= 32) return;
    _filters[band].configurePeakingEQ(_centerFrequencies[band], _sampleRate, q, _filters[band].gain);
  }

  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
  }

  Future<void> reset() async {
    for (int i = 0; i < 32; i++) {
      await setBandGain(i, 0.0);
    }
  }

  List<double> process(List<double> input) {
    if (!_enabled) return input;
    
    List<double> output = List.from(input);
    for (var filter in _filters) {
      output = filter.process(output);
    }
    return output;
  }

  Stream<double> bandStream(int band) {
    if (band < 0 || band >= 32) return Stream.empty();
    return _bandSubjects[band].stream;
  }

  double getBandGain(int band) {
    if (band < 0 || band >= 32) return 0.0;
    return _filters[band].gain;
  }

  List<double> getBandGains() {
    return _filters.map((filter) => filter.gain).toList();
  }

  void dispose() {
    for (var subject in _bandSubjects) {
      subject.close();
    }
  }
}

class BiquadFilter {
  double a0 = 1.0;
  double a1 = 0.0;
  double a2 = 0.0;
  double b0 = 1.0;
  double b1 = 0.0;
  double b2 = 0.0;
  double x1 = 0.0;
  double x2 = 0.0;
  double y1 = 0.0;
  double y2 = 0.0;
  double _gain = 0.0;
  double _frequency = 1000.0;
  double _sampleRate = 44100.0;
  double _q = 1.0;

  double get gain => _gain;
  double get frequency => _frequency;
  double get sampleRate => _sampleRate;
  double get q => _q;

  void configurePeakingEQ(double frequency, double sampleRate, double q, double gainDb) {
    _frequency = frequency;
    _sampleRate = sampleRate;
    _q = q;
    _gain = gainDb;

    final omega = 2 * math.pi * frequency / sampleRate;
    final sinOmega = math.sin(omega);
    final cosOmega = math.cos(omega);
    final alpha = sinOmega / (2 * q);
    final a = math.pow(10, gainDb / 40);

    b0 = 1 + alpha * a;
    b1 = -2 * cosOmega;
    b2 = 1 - alpha * a;
    a0 = 1 + alpha / a;
    a1 = -2 * cosOmega;
    a2 = 1 - alpha / a;

    final norm = 1 / a0;
    b0 *= norm;
    b1 *= norm;
    b2 *= norm;
    a1 *= norm;
    a2 *= norm;
  }

  void configureLowShelf(double frequency, double sampleRate, double q, double gainDb) {
    _frequency = frequency;
    _sampleRate = sampleRate;
    _q = q;
    _gain = gainDb;

    final omega = 2 * math.pi * frequency / sampleRate;
    final sinOmega = math.sin(omega);
    final cosOmega = math.cos(omega);
    final a = math.pow(10, gainDb / 40);
    final beta = math.sqrt(a) / q;

    b0 = a * ((a + 1) - (a - 1) * cosOmega + beta * sinOmega);
    b1 = 2 * a * ((a - 1) - (a + 1) * cosOmega);
    b2 = a * ((a + 1) - (a - 1) * cosOmega - beta * sinOmega);
    a0 = (a + 1) + (a - 1) * cosOmega + beta * sinOmega;
    a1 = -2 * ((a - 1) + (a + 1) * cosOmega);
    a2 = (a + 1) + (a - 1) * cosOmega - beta * sinOmega;

    final norm = 1 / a0;
    b0 *= norm;
    b1 *= norm;
    b2 *= norm;
    a1 *= norm;
    a2 *= norm;
  }

  void configureHighShelf(double frequency, double sampleRate, double q, double gainDb) {
    _frequency = frequency;
    _sampleRate = sampleRate;
    _q = q;
    _gain = gainDb;

    final omega = 2 * math.pi * frequency / sampleRate;
    final sinOmega = math.sin(omega);
    final cosOmega = math.cos(omega);
    final a = math.pow(10, gainDb / 40);
    final beta = math.sqrt(a) / q;

    b0 = a * ((a + 1) + (a - 1) * cosOmega + beta * sinOmega);
    b1 = -2 * a * ((a - 1) + (a + 1) * cosOmega);
    b2 = a * ((a + 1) + (a - 1) * cosOmega - beta * sinOmega);
    a0 = (a + 1) - (a - 1) * cosOmega + beta * sinOmega;
    a1 = 2 * ((a - 1) - (a + 1) * cosOmega);
    a2 = (a + 1) - (a - 1) * cosOmega - beta * sinOmega;

    final norm = 1 / a0;
    b0 *= norm;
    b1 *= norm;
    b2 *= norm;
    a1 *= norm;
    a2 *= norm;
  }

  void setGain(double gainDb) {
    configurePeakingEQ(_frequency, _sampleRate, _q, gainDb);
  }

  List<double> process(List<double> input) {
    final output = List<double>.filled(input.length, 0.0);
    
    for (int i = 0; i < input.length; i++) {
      final x = input[i];
      final y = b0 * x + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2;
      
      x2 = x1;
      x1 = x;
      y2 = y1;
      y1 = y;
      
      output[i] = y;
    }
    
    return output;
  }

  void reset() {
    x1 = 0.0;
    x2 = 0.0;
    y1 = 0.0;
    y2 = 0.0;
  }
}

class ReverbProcessor {
  final List<List<double>> _delayLines = List.generate(8, (_) => List.filled(44100, 0.0));
  final List<int> _delayLinePositions = List.filled(8, 0);
  final List<int> _delayLineLengths = [1789, 1951, 2113, 2297, 2441, 2633, 2801, 2971];
  final List<double> _feedbackGains = [0.6, 0.7, 0.8, 0.9, 0.8, 0.7, 0.6, 0.5];
  final List<double> _outputGains = [1.0, 0.9, 0.8, 0.7, 0.6, 0.5, 0.4, 0.3];
  double _wet = 0.3;
  double _dry = 0.7;
  double _decay = 0.5;
  double _preDelay = 0.0;
  double _size = 0.5;
  double _damping = 0.5;
  bool _enabled = true;

  List<double> process(List<double> input) {
    if (!_enabled) return input;

    final output = List<double>.filled(input.length, 0.0);
    final wetSignal = List<double>.filled(input.length, 0.0);

    for (int i = 0; i < input.length; i++) {
      final inputSample = input[i];
      double reverbSample = 0.0;

      for (int j = 0; j < 8; j++) {
        final pos = _delayLinePositions[j];
        final length = _delayLineLengths[j];
        
        final delayedSample = _delayLines[j][pos];
        reverbSample += delayedSample * _outputGains[j];
        
        final feedback = inputSample + delayedSample * _feedbackGains[j] * _decay;
        _delayLines[j][pos] = feedback * (1.0 - _damping);
        
        _delayLinePositions[j] = (pos + 1) % length;
      }

      wetSignal[i] = reverbSample;
      output[i] = inputSample * _dry + reverbSample * _wet;
    }

    return output;
  }

  void setWet(double wet) {
    _wet = wet.clamp(0.0, 1.0);
    _dry = 1.0 - _wet;
  }

  void setDecay(double decay) {
    _decay = decay.clamp(0.0, 1.0);
  }

  void setPreDelay(double preDelay) {
    _preDelay = preDelay.clamp(0.0, 0.1);
  }

  void setSize(double size) {
    _size = size.clamp(0.0, 1.0);
    for (int i = 0; i < 8; i++) {
      _delayLineLengths[i] = (1789 + i * 162 + (size * 1000)).toInt();
    }
  }

  void setDamping(double damping) {
    _damping = damping.clamp(0.0, 1.0);
  }

  void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  Future<void> loadPreset(ReverbPreset preset) async {
    switch (preset) {
      case ReverbPreset.none:
        setWet(0.0);
        setDecay(0.0);
        setSize(0.0);
        setDamping(0.0);
        break;
      case ReverbPreset.smallRoom:
        setWet(0.2);
        setDecay(0.3);
        setSize(0.3);
        setDamping(0.4);
        break;
      case ReverbPreset.mediumRoom:
        setWet(0.3);
        setDecay(0.4);
        setSize(0.5);
        setDamping(0.5);
        break;
      case ReverbPreset.largeRoom:
        setWet(0.4);
        setDecay(0.5);
        setSize(0.7);
        setDamping(0.6);
        break;
      case ReverbPreset.concertHall:
        setWet(0.5);
        setDecay(0.7);
        setSize(0.9);
        setDamping(0.7);
        break;
      case ReverbPreset.cathedral:
        setWet(0.6);
        setDecay(0.8);
        setSize(1.0);
        setDamping(0.8);
        break;
      case ReverbPreset.plate:
        setWet(0.4);
        setDecay(0.6);
        setSize(0.8);
        setDamping(0.3);
        break;
      case ReverbPreset.spring:
        setWet(0.3);
        setDecay(0.4);
        setSize(0.6);
        setDamping(0.2);
        break;
      case ReverbPreset.church:
        setWet(0.5);
        setDecay(0.8);
        setSize(0.9);
        setDamping(0.9);
        break;
      case ReverbPreset.arena:
        setWet(0.6);
        setDecay(0.9);
        setSize(1.0);
        setDamping(0.6);
        break;
      case ReverbPreset.stadium:
        setWet(0.7);
        setDecay(0.9);
        setSize(1.0);
        setDamping(0.5);
        break;
      case ReverbPreset.cave:
        setWet(0.8);
        setDecay(0.9);
        setSize(1.0);
        setDamping(0.4);
        break;
      case ReverbPreset.tunnel:
        setWet(0.7);
        setDecay(0.8);
        setSize(0.9);
        setDamping(0.7);
        break;
      case ReverbPreset.can:
        setWet(0.2);
        setDecay(0.1);
        setSize(0.2);
        setDamping(0.9);
        break;
      case ReverbPreset.pipe:
        setWet(0.3);
        setDecay(0.5);
        setSize(0.4);
        setDamping(0.8);
        break;
      case ReverbPreset.vocalPlate:
        setWet(0.25);
        setDecay(0.4);
        setSize(0.6);
        setDamping(0.3);
        break;
      case ReverbPreset.drumRoom:
        setWet(0.35);
        setDecay(0.5);
        setSize(0.7);
        setDamping(0.4);
        break;
      case ReverbPreset.guitarHall:
        setWet(0.4);
        setDecay(0.6);
        setSize(0.8);
        setDamping(0.5);
        break;
      case ReverbPreset.pianoRoom:
        setWet(0.3);
        setDecay(0.4);
        setSize(0.6);
        setDamping(0.6);
        break;
      case ReverbPreset.jazzClub:
        setWet(0.35);
        setDecay(0.45);
        setSize(0.65);
        setDamping(0.55);
        break;
    }
  }
}

enum ReverbPreset {
  none,
  smallRoom,
  mediumRoom,
  largeRoom,
  concertHall,
  cathedral,
  plate,
  spring,
  church,
  arena,
  stadium,
  cave,
  tunnel,
  can,
  pipe,
  vocalPlate,
  drumRoom,
  guitarHall,
  pianoRoom,
  jazzClub
}

class EchoProcessor {
  final List<double> _delayBuffer = List.filled(44100 * 2, 0.0);
  int _bufferPosition = 0;
  int _delaySamples = 22050;
  double _feedback = 0.5;
  double _wet = 0.3;
  double _dry = 0.7;
  int _tapCount = 1;
  List<double> _tapDelays = [0.25];
  List<double> _tapGains = [1.0];
  bool _enabled = true;
  bool _pingPong = false;
  bool _stereo = false;

  List<double> process(List<double> input) {
    if (!_enabled) return input;

    final output = List<double>.filled(input.length, 0.0);

    for (int i = 0; i < input.length; i++) {
      final inputSample = input[i];
      
      double echoSample = 0.0;
      for (int t = 0; t < _tapCount; t++) {
        final tapDelay = (_tapDelays[t] * _delaySamples).toInt();
        final readPos = (_bufferPosition - tapDelay + _delayBuffer.length) % _delayBuffer.length;
        echoSample += _delayBuffer[readPos] * _tapGains[t];
      }

      final wetSample = echoSample * _wet;
      final drySample = inputSample * _dry;
      output[i] = drySample + wetSample;

      _delayBuffer[_bufferPosition] = inputSample + echoSample * _feedback;
      _bufferPosition = (_bufferPosition + 1) % _delayBuffer.length;
    }

    return output;
  }

  void setDelay(double delayMs) {
    _delaySamples = (delayMs * 44.1).toInt();
  }

  void setFeedback(double feedback) {
    _feedback = feedback.clamp(0.0, 0.95);
  }

  void setWet(double wet) {
    _wet = wet.clamp(0.0, 1.0);
    _dry = 1.0 - _wet;
  }

  void setTapCount(int taps) {
    _tapCount = taps.clamp(1, 8);
    while (_tapDelays.length < _tapCount) {
      _tapDelays.add(_tapDelays.last * 1.5);
      _tapGains.add(_tapGains.last * 0.8);
    }
    _tapDelays = _tapDelays.sublist(0, _tapCount);
    _tapGains = _tapGains.sublist(0, _tapCount);
  }

  void setTapDelay(int tap, double delay) {
    if (tap >= 0 && tap < _tapCount) {
      _tapDelays[tap] = delay.clamp(0.0, 2.0);
    }
  }

  void setTapGain(int tap, double gain) {
    if (tap >= 0 && tap < _tapCount) {
      _tapGains[tap] = gain.clamp(0.0, 1.0);
    }
  }

  void setPingPong(bool enabled) {
    _pingPong = enabled;
  }

  void setStereo(bool enabled) {
    _stereo = enabled;
  }

  void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  Future<void> loadPreset(EchoPreset preset) async {
    switch (preset) {
      case EchoPreset.none:
        setWet(0.0);
        setFeedback(0.0);
        setTapCount(1);
        break;
      case EchoPreset.slapback:
        setWet(0.3);
        setDelay(120.0);
        setFeedback(0.3);
        setTapCount(1);
        break;
      case EchoPreset.doubleSlap:
        setWet(0.4);
        setDelay(150.0);
        setFeedback(0.4);
        setTapCount(2);
        setTapDelay(0, 0.25);
        setTapDelay(1, 0.5);
        break;
      case EchoPreset.tripleTap:
        setWet(0.5);
        setDelay(200.0);
        setFeedback(0.5);
        setTapCount(3);
        setTapDelay(0, 0.25);
        setTapDelay(1, 0.5);
        setTapDelay(2, 0.75);
        break;
      case EchoPreset.pingPong:
        setWet(0.6);
        setDelay(300.0);
        setFeedback(0.6);
        setTapCount(2);
        setPingPong(true);
        break;
      case EchoPreset.tapeEcho:
        setWet(0.4);
        setDelay(400.0);
        setFeedback(0.7);
        setTapCount(4);
        for (int i = 0; i < 4; i++) {
          setTapDelay(i, 0.25 * (i + 1));
          setTapGain(i, math.pow(0.8, i).toDouble());
        }
        break;
      case EchoPreset.digitalDelay:
        setWet(0.5);
        setDelay(500.0);
        setFeedback(0.8);
        setTapCount(1);
        break;
      case EchoPreset.analogDelay:
        setWet(0.45);
        setDelay(350.0);
        setFeedback(0.65);
        setTapCount(1);
        break;
      case EchoPreset.multiTap:
        setWet(0.55);
        setDelay(600.0);
        setFeedback(0.55);
        setTapCount(8);
        for (int i = 0; i < 8; i++) {
          setTapDelay(i, 0.125 * (i + 1));
          setTapGain(i, math.pow(0.85, i).toDouble());
        }
        break;
      case EchoPreset.reverseEcho:
        setWet(0.7);
        setDelay(800.0);
        setFeedback(0.9);
        setTapCount(1);
        break;
      case EchoPreset.vocalDelay:
        setWet(0.35);
        setDelay(250.0);
        setFeedback(0.4);
        setTapCount(2);
        setTapDelay(0, 0.3);
        setTapDelay(1, 0.6);
        break;
      case EchoPreset.guitarDelay:
        setWet(0.4);
        setDelay(320.0);
        setFeedback(0.5);
        setTapCount(3);
        setTapDelay(0, 0.25);
        setTapDelay(1, 0.5);
        setTapDelay(2, 0.75);
        break;
      case EchoPreset.drumEcho:
        setWet(0.5);
        setDelay(180.0);
        setFeedback(0.6);
        setTapCount(4);
        for (int i = 0; i < 4; i++) {
          setTapDelay(i, 0.2 * (i + 1));
        }
        break;
      case EchoPreset.ambientEcho:
        setWet(0.8);
        setDelay(1000.0);
        setFeedback(0.9);
        setTapCount(1);
        break;
      case EchoPreset.rhythmicEcho:
        setWet(0.6);
        setDelay(450.0);
        setFeedback(0.7);
        setTapCount(5);
        setTapDelay(0, 0.25);
        setTapDelay(1, 0.5);
        setTapDelay(2, 0.75);
        setTapDelay(3, 1.0);
        setTapDelay(4, 1.25);
        break;
    }
  }
}

enum EchoPreset {
  none,
  slapback,
  doubleSlap,
  tripleTap,
  pingPong,
  tapeEcho,
  digitalDelay,
  analogDelay,
  multiTap,
  reverseEcho,
  vocalDelay,
  guitarDelay,
  drumEcho,
  ambientEcho,
  rhythmicEcho
}

class DynamicRangeCompressor {
  double _threshold = -20.0;
  double _ratio = 4.0;
  double _attack = 10.0;
  double _release = 100.0;
  double _knee = 5.0;
  double _makeupGain = 0.0;
  bool _enabled = true;
  bool _autoMakeup = true;
  double _rmsWindow = 50.0;
  
  double _level = 0.0;
  double _gainReduction = 0.0;
  List<double> _rmsBuffer = List.filled(100, 0.0);
  int _rmsPosition = 0;
  
  List<double> process(List<double> input) {
    if (!_enabled) return input;
    
    final output = List<double>.filled(input.length, 0.0);
    
    for (int i = 0; i < input.length; i++) {
      final sample = input[i];
      
      _rmsBuffer[_rmsPosition] = sample * sample;
      _rmsPosition = (_rmsPosition + 1) % _rmsBuffer.length;
      
      final rms = math.sqrt(_rmsBuffer.reduce((a, b) => a + b) / _rmsBuffer.length);
      final db = 20 * math.log(rms + 1e-10) / math.ln10;
      
      final overDb = db - _threshold;
      double compression = 0.0;
      
      if (overDb > 0) {
        if (overDb <= _knee / 2) {
          compression = overDb * (overDb / _knee - 1);
        } else {
          compression = overDb * (1 - 1 / _ratio);
        }
      }
      
      final alphaA = math.exp(-1 / (_attack * 0.001 * 44100));
      final alphaR = math.exp(-1 / (_release * 0.001 * 44100));
      
      if (compression < _gainReduction) {
        _gainReduction = alphaA * _gainReduction + (1 - alphaA) * compression;
      } else {
        _gainReduction = alphaR * _gainReduction + (1 - alphaR) * compression;
      }
      
      final gain = math.pow(10, (-_gainReduction + _makeupGain) / 20);
      output[i] = sample * gain;
    }
    
    return output;
  }
  
  void setThreshold(double threshold) {
    _threshold = threshold.clamp(-60.0, 0.0);
  }
  
  void setRatio(double ratio) {
    _ratio = ratio.clamp(1.0, 100.0);
  }
  
  void setAttack(double attackMs) {
    _attack = attackMs.clamp(0.1, 100.0);
  }
  
  void setRelease(double releaseMs) {
    _release = releaseMs.clamp(10.0, 5000.0);
  }
  
  void setKnee(double kneeDb) {
    _knee = kneeDb.clamp(0.0, 30.0);
  }
  
  void setMakeupGain(double gainDb) {
    _makeupGain = gainDb.clamp(0.0, 24.0);
  }
  
  void setAutoMakeup(bool enabled) {
    _autoMakeup = enabled;
  }
  
  void setEnabled(bool enabled) {
    _enabled = enabled;
  }
  
  double get gainReduction => _gainReduction;
  double get level => _level;
  
  Future<void> loadPreset(CompressorPreset preset) async {
    switch (preset) {
      case CompressorPreset.none:
        setEnabled(false);
        break;
      case CompressorPreset.soft:
        setThreshold(-24.0);
        setRatio(2.0);
        setAttack(30.0);
        setRelease(200.0);
        setKnee(6.0);
        setMakeupGain(2.0);
        setEnabled(true);
        break;
      case CompressorPreset.medium:
        setThreshold(-20.0);
        setRatio(4.0);
        setAttack(20.0);
        setRelease(150.0);
        setKnee(4.0);
        setMakeupGain(3.0);
        setEnabled(true);
        break;
      case CompressorPreset.aggressive:
        setThreshold(-12.0);
        setRatio(8.0);
        setAttack(5.0);
        setRelease(80.0);
        setKnee(2.0);
        setMakeupGain(6.0);
        setEnabled(true);
        break;
      case CompressorPreset.vocal:
        setThreshold(-18.0);
        setRatio(3.0);
        setAttack(15.0);
        setRelease(100.0);
        setKnee(5.0);
        setMakeupGain(4.0);
        setEnabled(true);
        break;
      case CompressorPreset.drum:
        setThreshold(-15.0);
        setRatio(6.0);
        setAttack(2.0);
        setRelease(50.0);
        setKnee(3.0);
        setMakeupGain(5.0);
        setEnabled(true);
        break;
      case CompressorPreset.bass:
        setThreshold(-22.0);
        setRatio(4.0);
        setAttack(25.0);
        setRelease(180.0);
        setKnee(5.0);
        setMakeupGain(3.0);
        setEnabled(true);
        break;
      case CompressorPreset.master:
        setThreshold(-10.0);
        setRatio(2.0);
        setAttack(40.0);
        setRelease(300.0);
        setKnee(8.0);
        setMakeupGain(2.0);
        setEnabled(true);
        break;
      case CompressorPreset.podcast:
        setThreshold(-16.0);
        setRatio(5.0);
        setAttack(10.0);
        setRelease(120.0);
        setKnee(4.0);
        setMakeupGain(6.0);
        setEnabled(true);
        break;
      case CompressorPreset.loudness:
        setThreshold(-8.0);
        setRatio(12.0);
        setAttack(1.0);
        setRelease(30.0);
        setKnee(1.0);
        setMakeupGain(10.0);
        setEnabled(true);
        break;
      case CompressorPreset.smooth:
        setThreshold(-28.0);
        setRatio(1.5);
        setAttack(50.0);
        setRelease(400.0);
        setKnee(10.0);
        setMakeupGain(1.0);
        setEnabled(true);
        break;
    }
  }
}

enum CompressorPreset {
  none,
  soft,
  medium,
  aggressive,
  vocal,
  drum,
  bass,
  master,
  podcast,
  loudness,
  smooth
}

class LimiterProcessor {
  double _threshold = -1.0;
  double _attack = 1.0;
  double _release = 50.0;
  bool _enabled = true;
  bool _truePeak = true;
  
  double _gainReduction = 0.0;
  double _peakLevel = 0.0;
  
  List<double> process(List<double> input) {
    if (!_enabled) return input;
    
    final output = List<double>.filled(input.length, 0.0);
    
    for (int i = 0; i < input.length; i++) {
      double sample = input[i];
      final absSample = sample.abs();
      
      if (absSample > _peakLevel) {
        _peakLevel = _peakLevel + _attack * 0.001 * 44100 * (absSample - _peakLevel);
      } else {
        _peakLevel = _peakLevel + _release * 0.001 * 44100 * (absSample - _peakLevel);
      }
      
      final peakDb = 20 * math.log(_peakLevel + 1e-10) / math.ln10;
      
      if (peakDb > _threshold) {
        _gainReduction = peakDb - _threshold;
        final gain = math.pow(10, -_gainReduction / 20);
        sample *= gain;
      } else {
        _gainReduction = 0.0;
      }
      
      output[i] = sample;
    }
    
    return output;
  }
  
  void setThreshold(double thresholdDb) {
    _threshold = thresholdDb.clamp(-60.0, 0.0);
  }
  
  void setAttack(double attackMs) {
    _attack = attackMs.clamp(0.01, 10.0);
  }
  
  void setRelease(double releaseMs) {
    _release = releaseMs.clamp(10.0, 1000.0);
  }
  
  void setTruePeak(bool enabled) {
    _truePeak = enabled;
  }
  
  void setEnabled(bool enabled) {
    _enabled = enabled;
  }
  
  double get gainReduction => _gainReduction;
  double get peakLevel => _peakLevel;
  
  Future<void> loadPreset(LimiterPreset preset) async {
    switch (preset) {
      case LimiterPreset.none:
        setEnabled(false);
        break;
      case LimiterPreset.transparent:
        setThreshold(-0.5);
        setAttack(5.0);
        setRelease(100.0);
        setTruePeak(true);
        setEnabled(true);
        break;
      case LimiterPreset.normal:
        setThreshold(-1.0);
        setAttack(2.0);
        setRelease(50.0);
        setTruePeak(true);
        setEnabled(true);
        break;
      case LimiterPreset.aggressive:
        setThreshold(-3.0);
        setAttack(0.5);
        setRelease(20.0);
        setTruePeak(false);
        setEnabled(true);
        break;
      case LimiterPreset.vocal:
        setThreshold(-2.0);
        setAttack(3.0);
        setRelease(80.0);
        setTruePeak(true);
        setEnabled(true);
        break;
      case LimiterPreset.master:
        setThreshold(-0.3);
        setAttack(1.0);
        setRelease(30.0);
        setTruePeak(true);
        setEnabled(true);
        break;
      case LimiterPreset.podcast:
        setThreshold(-4.0);
        setAttack(1.5);
        setRelease(40.0);
        setTruePeak(true);
        setEnabled(true);
        break;
      case LimiterPreset.loud:
        setThreshold(-6.0);
        setAttack(0.1);
        setRelease(10.0);
        setTruePeak(false);
        setEnabled(true);
        break;
    }
  }
}

enum LimiterPreset {
  none,
  transparent,
  normal,
  aggressive,
  vocal,
  master,
  podcast,
  loud
}

class CrossfadeProcessor {
  double _duration = 800.0;
  Curve _curve = Curves.easeInOut;
  bool _enabled = true;
  CrossfadeMode _mode = CrossfadeMode.constantPower;
  
  double _fadePosition = 0.0;
  bool _isFading = false;
  AudioSource _currentSource;
  AudioSource _nextSource;
  
  Future<void> crossfade(AudioSource from, AudioSource to) async {
    if (!_enabled || _isFading) return;
    
    _isFading = true;
    _currentSource = from;
    _nextSource = to;
    _fadePosition = 0.0;
    
    final steps = (_duration / 16.666).ceil();
    final increment = 1.0 / steps;
    
    for (int i = 0; i <= steps; i++) {
      if (!_isFading) break;
      
      _fadePosition = i * increment;
      final gainFrom = _calculateGain(_fadePosition, true);
      final gainTo = _calculateGain(_fadePosition, false);
      
      await Future.delayed(Duration(milliseconds: 16));
    }
    
    _isFading = false;
    _currentSource = null;
    _nextSource = null;
  }
  
  double _calculateGain(double position, bool isOutgoing) {
    final t = position.clamp(0.0, 1.0);
    double curveValue;
    
    switch (_curve) {
      case Curve.linear:
        curveValue = t;
        break;
      case Curve.easeIn:
        curveValue = t * t;
        break;
      case Curve.easeOut:
        curveValue = 1 - (1 - t) * (1 - t);
        break;
      case Curve.easeInOut:
        curveValue = t < 0.5 ? 2 * t * t : 1 - math.pow(-2 * t + 2, 2) / 2;
        break;
      default:
        curveValue = t;
    }
    
    if (_mode == CrossfadeMode.constantPower) {
      if (isOutgoing) {
        return math.cos(curveValue * math.pi / 2);
      } else {
        return math.sin(curveValue * math.pi / 2);
      }
    } else {
      if (isOutgoing) {
        return 1 - curveValue;
      } else {
        return curveValue;
      }
    }
  }
  
  void setDuration(double milliseconds) {
    _duration = milliseconds.clamp(10.0, 10000.0);
  }
  
  void setCurve(Curve curve) {
    _curve = curve;
  }
  
  void setMode(CrossfadeMode mode) {
    _mode = mode;
  }
  
  void setEnabled(bool enabled) {
    _enabled = enabled;
  }
  
  bool get isFading => _isFading;
  double get fadePosition => _fadePosition;
}

enum CrossfadeMode {
  linear,
  constantPower,
  exponential,
  logarithmic
}

enum Curve {
  linear,
  easeIn,
  easeOut,
  easeInOut
}

class GaplessProcessor {
  double _threshold = 100.0;
  bool _enabled = true;
  bool _smartDetection = true;
  
  Future<void> transition(AudioPlayer from, AudioPlayer to) async {
    if (!_enabled) return;
    
    final fromPosition = from.position;
    final fromDuration = from.duration;
    final toDuration = to.duration;
    
    if (fromDuration == null || toDuration == null) return;
    
    final remaining = fromDuration - fromPosition;
    
    if (remaining.inMilliseconds <= _threshold) {
      await to.seek(Duration.zero);
      await to.play();
      
      if (_smartDetection) {
        final fadeStart = math.max(0, remaining.inMilliseconds - 50);
        if (fadeStart > 0) {
          await Future.delayed(Duration(milliseconds: fadeStart.toInt()));
        }
      }
      
      await from.pause();
    }
  }
  
  void setThreshold(double milliseconds) {
    _threshold = milliseconds.clamp(0.0, 1000.0);
  }
  
  void setSmartDetection(bool enabled) {
    _smartDetection = enabled;
  }
  
  void setEnabled(bool enabled) {
    _enabled = enabled;
  }
}

class PitchShifter {
  double _pitch = 0.0;
  double _formant = 0.0;
  bool _enabled = true;
  
  final List<double> _buffer = List.filled(4096, 0.0);
  int _bufferPosition = 0;
  
  List<double> process(List<double> input) {
    if (!_enabled || _pitch == 0.0) return input;
    
    final output = List<double>.filled(input.length, 0.0);
    final ratio = math.pow(2, _pitch / 12);
    
    for (int i = 0; i < input.length; i++) {
      final readIndex = _bufferPosition / ratio;
      final index1 = readIndex.floor();
      final index2 = (index1 + 1) % _buffer.length;
      final fraction = readIndex - index1;
      
      final sample1 = _buffer[index1];
      final sample2 = _buffer[index2];
      final sample = sample1 + fraction * (sample2 - sample1);
      
      output[i] = sample;
      _buffer[_bufferPosition] = input[i];
      _bufferPosition = (_bufferPosition + 1) % _buffer.length;
    }
    
    return output;
  }
  
  void setPitch(double semitones) {
    _pitch = semitones.clamp(-12.0, 12.0);
  }
  
  void setFormant(double formant) {
    _formant = formant.clamp(-1.0, 1.0);
  }
  
  void setEnabled(bool enabled) {
    _enabled = enabled;
  }
}

class TimeStretcher {
  double _stretch = 1.0;
  bool _enabled = true;
  
  final List<double> _inputBuffer = List.filled(8192, 0.0);
  final List<double> _outputBuffer = List.filled(8192, 0.0);
  int _inputPosition = 0;
  int _outputPosition = 0;
  
  List<double> process(List<double> input) {
    if (!_enabled || _stretch == 1.0) return input;
    
    final output = List<double>.filled((input.length / _stretch).ceil(), 0.0);
    
    for (int i = 0; i < input.length; i++) {
      _inputBuffer[_inputPosition] = input[i];
      _inputPosition = (_inputPosition + 1) % _inputBuffer.length;
    }
    
    double phase = 0.0;
    int outIndex = 0;
    
    while (phase < input.length && outIndex < output.length) {
      final index = phase.floor();
      final fraction = phase - index;
      
      if (index + 1 < input.length) {
        final sample1 = input[index];
        final sample2 = input[index + 1];
        output[outIndex] = sample1 + fraction * (sample2 - sample1);
      } else {
        output[outIndex] = input[input.length - 1];
      }
      
      outIndex++;
      phase += _stretch;
    }
    
    return output.sublist(0, outIndex);
  }
  
  void setStretch(double factor) {
    _stretch = factor.clamp(0.5, 2.0);
  }
  
  void setEnabled(bool enabled) {
    _enabled = enabled;
  }
}

class NoiseGate {
  double _threshold = -60.0;
  double _attack = 10.0;
  double _release = 100.0;
  double _hold = 50.0;
  bool _enabled = true;
  
  double _level = 0.0;
  bool _isOpen = true;
  int _holdSamples = 0;
  
  List<double> process(List<double> input) {
    if (!_enabled) return input;
    
    final output = List<double>.filled(input.length, 0.0);
    
    for (int i = 0; i < input.length; i++) {
      final sample = input[i];
      final rms = sample.abs();
      
      if (rms > _level) {
        _level = _level + _attack * 0.001 * 44100 * (rms - _level);
      } else {
        _level = _level + _release * 0.001 * 44100 * (rms - _level);
      }
      
      final db = 20 * math.log(_level + 1e-10) / math.ln10;
      
      if (db < _threshold) {
        if (_isOpen) {
          if (_holdSamples <= 0) {
            _isOpen = false;
          } else {
            _holdSamples--;
          }
        }
      } else {
        _isOpen = true;
        _holdSamples = (_hold * 0.001 * 44100).toInt();
      }
      
      output[i] = _isOpen ? sample : 0.0;
    }
    
    return output;
  }
  
  void setThreshold(double thresholdDb) {
    _threshold = thresholdDb.clamp(-80.0, 0.0);
  }
  
  void setAttack(double attackMs) {
    _attack = attackMs.clamp(0.1, 100.0);
  }
  
  void setRelease(double releaseMs) {
    _release = releaseMs.clamp(10.0, 5000.0);
  }
  
  void setHold(double holdMs) {
    _hold = holdMs.clamp(0.0, 1000.0);
  }
  
  void setEnabled(bool enabled) {
    _enabled = enabled;
  }
}

class HarmonicExciter {
  double _amount = 0.0;
  double _frequency = 5000.0;
  double _mix = 0.5;
  bool _enabled = true;
  
  List<double> process(List<double> input) {
    if (!_enabled || _amount == 0.0) return input;
    
    final output = List<double>.filled(input.length, 0.0);
    
    for (int i = 0; i < input.length; i++) {
      final sample = input[i];
      final excited = sample + _amount * math.tanh(sample * 2.0);
      output[i] = sample * (1 - _mix) + excited * _mix;
    }
    
    return output;
  }
  
  void setAmount(double amount) {
    _amount = amount.clamp(0.0, 1.0);
  }
  
  void setFrequency(double frequency) {
    _frequency = frequency.clamp(1000.0, 20000.0);
  }
  
  void setMix(double mix) {
    _mix = mix.clamp(0.0, 1.0);
  }
  
  void setEnabled(bool enabled) {
    _enabled = enabled;
  }
}

class StereoWidener {
  double _width = 1.0;
  bool _enabled = true;
  
  List<double> process(List<double> left, List<double> right) {
    if (!_enabled || _width == 1.0) return left + right;
    
    final mid = List<double>.filled(left.length, 0.0);
    final side = List<double>.filled(left.length, 0.0);
    
    for (int i = 0; i < left.length; i++) {
      mid[i] = (left[i] + right[i]) * 0.5;
      side[i] = (left[i] - right[i]) * 0.5;
    }
    
    side = side.map((s) => s * _width).toList();
    
    final newLeft = List<double>.filled(left.length, 0.0);
    final newRight = List<double>.filled(right.length, 0.0);
    
    for (int i = 0; i < left.length; i++) {
      newLeft[i] = mid[i] + side[i];
      newRight[i] = mid[i] - side[i];
    }
    
    return newLeft + newRight;
  }
  
  void setWidth(double width) {
    _width = width.clamp(0.0, 3.0);
  }
  
  void setEnabled(bool enabled) {
    _enabled = enabled;
  }
}

class PhaserProcessor {
  double _rate = 0.5;
  double _depth = 0.8;
  double _feedback = 0.7;
  int _stages = 4;
  bool _enabled = true;
  
  final List<BiquadFilter> _allPassFilters = [];
  double _lfoPhase = 0.0;
  
  PhaserProcessor() {
    for (int i = 0; i < 8; i++) {
      _allPassFilters.add(BiquadFilter());
    }
  }
  
  List<double> process(List<double> input) {
    if (!_enabled) return input;
    
    final output = List<double>.filled(input.length, 0.0);
    
    for (int i = 0; i < input.length; i++) {
      _lfoPhase += _rate * 0.001 * 2 * math.pi / 44100;
      if (_lfoPhase >= 2 * math.pi) _lfoPhase -= 2 * math.pi;
      
      final lfo = math.sin(_lfoPhase);
      final frequency = 440 * math.pow(2, (lfo * _depth * 3));
      
      for (int s = 0; s < _stages; s++) {
        _allPassFilters[s].configureAllPass(frequency, 44100, 0.5);
      }
      
      double processed = input[i];
      for (int s = 0; s < _stages; s++) {
        processed = _allPassFilters[s].process([processed])[0];
      }
      
      output[i] = input[i] + processed * _feedback;
    }
    
    return output;
  }
  
  void setRate(double rateHz) {
    _rate = rateHz.clamp(0.01, 20.0);
  }
  
  void setDepth(double depth) {
    _depth = depth.clamp(0.0, 1.0);
  }
  
  void setFeedback(double feedback) {
    _feedback = feedback.clamp(0.0, 0.95);
  }
  
  void setStages(int stages) {
    _stages = stages.clamp(1, 8);
  }
  
  void setEnabled(bool enabled) {
    _enabled = enabled;
  }
}

class FlangerProcessor {
  double _rate = 0.1;
  double _depth = 0.002;
  double _feedback = 0.5;
  double _mix = 0.5;
  bool _enabled = true;
  
  final List<double> _delayBuffer = List.filled(44100, 0.0);
  int _bufferPosition = 0;
  double _lfoPhase = 0.0;
  
  List<double> process(List<double> input) {
    if (!_enabled) return input;
    
    final output = List<double>.filled(input.length, 0.0);
    final maxDelaySamples = (_depth * 44100).toInt();
    
    for (int i = 0; i < input.length; i++) {
      _lfoPhase += _rate * 0.001 * 2 * math.pi / 44100;
      if (_lfoPhase >= 2 * math.pi) _lfoPhase -= 2 * math.pi;
      
      final lfo = (math.sin(_lfoPhase) + 1) * 0.5;
      final delaySamples = (lfo * maxDelaySamples).toInt();
      
      final readPos = (_bufferPosition - delaySamples + _delayBuffer.length) % _delayBuffer.length;
      final delayed = _delayBuffer[readPos];
      
      output[i] = input[i] * (1 - _mix) + delayed * _mix;
      _delayBuffer[_bufferPosition] = input[i] + delayed * _feedback;
      _bufferPosition = (_bufferPosition + 1) % _delayBuffer.length;
    }
    
    return output;
  }
  
  void setRate(double rateHz) {
    _rate = rateHz.clamp(0.01, 10.0);
  }
  
  void setDepth(double depthMs) {
    _depth = depthMs.clamp(0.1, 20.0) / 1000.0;
  }
  
  void setFeedback(double feedback) {
    _feedback = feedback.clamp(0.0, 0.95);
  }
  
  void setMix(double mix) {
    _mix = mix.clamp(0.0, 1.0);
  }
  
  void setEnabled(bool enabled) {
    _enabled = enabled;
  }
}

class ChorusProcessor {
  double _rate = 0.5;
  double _depth = 0.02;
  double _delay = 0.025;
  double _feedback = 0.0;
  double _mix = 0.5;
  int _voices = 3;
  bool _enabled = true;
  
  final List<List<double>> _delayBuffers = List.generate(8, (_) => List.filled(44100, 0.0));
  final List<int> _bufferPositions = List.filled(8, 0);
  final List<double> _lfoPhases = List.filled(8, 0.0);
  
  List<double> process(List<double> input) {
    if (!_enabled) return input;
    
    final output = List<double>.filled(input.length, 0.0);
    final baseDelaySamples = (_delay * 44100).toInt();
    final depthSamples = (_depth * 44100).toInt();
    
    for (int i = 0; i < input.length; i++) {
      double chorus = 0.0;
      
      for (int v = 0; v < _voices; v++) {
        _lfoPhases[v] += _rate * 0.001 * 2 * math.pi / 44100;
        if (_lfoPhases[v] >= 2 * math.pi) _lfoPhases[v] -= 2 * math.pi;
        
        final lfo = math.sin(_lfoPhases[v] + v * 2 * math.pi / _voices);
        final delaySamples = baseDelaySamples + (lfo * depthSamples).toInt();
        
        final readPos = (_bufferPositions[v] - delaySamples + _delayBuffers[v].length) % _delayBuffers[v].length;
        chorus += _delayBuffers[v][readPos];
        
        _delayBuffers[v][_bufferPositions[v]] = input[i] + _delayBuffers[v][readPos] * _feedback;
        _bufferPositions[v] = (_bufferPositions[v] + 1) % _delayBuffers[v].length;
      }
      
      chorus /= _voices;
      output[i] = input[i] * (1 - _mix) + chorus * _mix;
    }
    
    return output;
  }
  
  void setRate(double rateHz) {
    _rate = rateHz.clamp(0.01, 10.0);
  }
  
  void setDepth(double depthMs) {
    _depth = depthMs.clamp(0.1, 50.0) / 1000.0;
  }
  
  void setDelay(double delayMs) {
    _delay = delayMs.clamp(1.0, 50.0) / 1000.0;
  }
  
  void setFeedback(double feedback) {
    _feedback = feedback.clamp(0.0, 0.95);
  }
  
  void setMix(double mix) {
    _mix = mix.clamp(0.0, 1.0);
  }
  
  void setVoices(int voices) {
    _voices = voices.clamp(1, 8);
  }
  
  void setEnabled(bool enabled) {
    _enabled = enabled;
  }
}

class BitCrusher {
  int _resolution = 16;
  double _downsample = 1.0;
  bool _enabled = true;
  
  int _sampleCounter = 0;
  double _holdValue = 0.0;
  
  List<double> process(List<double> input) {
    if (!_enabled || (_resolution >= 16 && _downsample >= 1.0)) return input;
    
    final output = List<double>.filled(input.length, 0.0);
    final step = math.pow(2, _resolution - 1).toDouble();
    final downsampleThreshold = (1.0 / _downsample).floor();
    
    for (int i = 0; i < input.length; i++) {
      if (_sampleCounter % downsampleThreshold == 0) {
        _holdValue = (input[i] * step).round() / step;
      }
      
      output[i] = _holdValue;
      _sampleCounter++;
    }
    
    return output;
  }
  
  void setResolution(int bits) {
    _resolution = bits.clamp(1, 16);
  }
  
  void setDownsample(double factor) {
    _downsample = factor.clamp(1.0, 16.0);
  }
  
  void setEnabled(bool enabled) {
    _enabled = enabled;
  }
}

class DistortionProcessor {
  double _gain = 20.0;
  double _tone = 0.5;
  double _mix = 0.5;
  DistortionType _type = DistortionType.hardClip;
  bool _enabled = true;
  
  List<double> process(List<double> input) {
    if (!_enabled || _gain == 0.0) return input;
    
    final output = List<double>.filled(input.length, 0.0);
    final preGain = math.pow(10, _gain / 20);
    
    for (int i = 0; i < input.length; i++) {
      double distorted = input[i] * preGain;
      
      switch (_type) {
        case DistortionType.hardClip:
          distorted = distorted.clamp(-1.0, 1.0);
          break;
        case DistortionType.softClip:
          distorted = math.tanh(distorted);
          break;
        case DistortionType.exponential:
          if (distorted >= 0) {
            distorted = 1 - math.exp(-distorted);
          } else {
            distorted = -1 + math.exp(distorted);
          }
          break;
        case DistortionType.sine:
          distorted = math.sin(distorted * math.pi / 2);
          break;
        case DistortionType.arcTan:
          distorted = (2 / math.pi) * math.atan(distorted * math.pi / 2);
          break;
      }
      
      output[i] = input[i] * (1 - _mix) + distorted * _mix;
    }
    
    return _applyToneControl(output);
  }
  
  List<double> _applyToneControl(List<double> input) {
    if (_tone == 0.5) return input;
    
    final output = List<double>.filled(input.length, 0.0);
    final cutoff = 1000 * math.pow(2, (_tone - 0.5) * 4);
    
    final alpha = 1 / (1 + 2 * math.pi * cutoff / 44100);
    
    double lowpass = input[0];
    for (int i = 0; i < input.length; i++) {
      lowpass = alpha * input[i] + (1 - alpha) * lowpass;
      final highpass = input[i] - lowpass;
      
      if (_tone < 0.5) {
        output[i] = lowpass;
      } else {
        output[i] = highpass;
      }
    }
    
    return output;
  }
  
  void setGain(double gainDb) {
    _gain = gainDb.clamp(0.0, 60.0);
  }
  
  void setTone(double tone) {
    _tone = tone.clamp(0.0, 1.0);
  }
  
  void setMix(double mix) {
    _mix = mix.clamp(0.0, 1.0);
  }
  
  void setType(DistortionType type) {
    _type = type;
  }
  
  void setEnabled(bool enabled) {
    _enabled = enabled;
  }
}

enum DistortionType {
  hardClip,
  softClip,
  exponential,
  sine,
  arcTan
}

class WahWahProcessor {
  double _frequency = 1000.0;
  double _q = 2.0;
  double _range = 0.8;
  double _mix = 0.5;
  bool _enabled = true;
  
  final BiquadFilter _filter = BiquadFilter();
  
  List<double> process(List<double> input) {
    if (!_enabled) return input;
    
    final output = List<double>.filled(input.length, 0.0);
    final minFreq = 200.0;
    final maxFreq = minFreq * math.pow(2, _range * 4);
    
    for (int i = 0; i < input.length; i++) {
      final modulatedFreq = minFreq + (maxFreq - minFreq) * _frequency;
      _filter.configureBandPass(modulatedFreq, 44100, _q);
      
      final filtered = _filter.process([input[i]])[0];
      output[i] = input[i] * (1 - _mix) + filtered * _mix;
    }
    
    return output;
  }
  
  void setFrequency(double frequency) {
    _frequency = frequency.clamp(0.0, 1.0);
  }
  
  void setQ(double q) {
    _q = q.clamp(0.5, 10.0);
  }
  
  void setRange(double range) {
    _range = range.clamp(0.0, 1.0);
  }
  
  void setMix(double mix) {
    _mix = mix.clamp(0.0, 1.0);
  }
  
  void setEnabled(bool enabled) {
    _enabled = enabled;
  }
}

class AutoTuner {
  double _speed = 10.0;
  double _strength = 1.0;
  Scale _scale = Scale.chromatic;
  Key _key = Key.c;
  bool _enabled = true;
  
  List<double> process(List<double> input) {
    if (!_enabled) return input;
    
    final output = List<double>.filled(input.length, 0.0);
    
    final detectedPitch = _detectPitch(input);
    if (detectedPitch == 0.0) return input;
    
    final targetPitch = _quantizePitch(detectedPitch);
    final pitchShift = 12 * math.log(targetPitch / detectedPitch) / math.ln2;
    
    final pitchShifter = PitchShifter();
    pitchShifter.setPitch(pitchShift * _strength);
    
    return pitchShifter.process(input);
  }
  
  double _detectPitch(List<double> input) {
    if (input.isEmpty) return 0.0;
    
    final fft = FFT(input.length);
    final complex = ComplexArray(input.length);
    
    for (int i = 0; i < input.length; i++) {
      complex.real[i] = input[i];
      complex.imag[i] = 0.0;
    }
    
    fft.transform(complex);
    
    double maxMag = 0.0;
    int maxIndex = 0;
    
    for (int i = 0; i < input.length ~/ 2; i++) {
      final real = complex.real[i];
      final imag = complex.imag[i];
      final mag = real * real + imag * imag;
      
      if (mag > maxMag) {
        maxMag = mag;
        maxIndex = i;
      }
    }
    
    return maxIndex * 44100 / input.length;
  }
  
  double _quantizePitch(double pitch) {
    final semitone = 12 * math.log(pitch / 440) / math.ln2 + 69;
    final quantizedSemitone = _quantizeSemitone(semitone);
    
    return 440 * math.pow(2, (quantizedSemitone - 69) / 12);
  }
  
  double _quantizeSemitone(double semitone) {
    final note = semitone.floor() % 12;
    double quantizedNote;
    
    switch (_scale) {
      case Scale.chromatic:
        quantizedNote = note.round().toDouble();
        break;
      case Scale.major:
        final majorScale = [0, 2, 4, 5, 7, 9, 11];
        quantizedNote = _findClosest(note, majorScale);
        break;
      case Scale.minor:
        final minorScale = [0, 2, 3, 5, 7, 8, 10];
        quantizedNote = _findClosest(note, minorScale);
        break;
      case Scale.pentatonicMajor:
        final pentatonicMajor = [0, 2, 4, 7, 9];
        quantizedNote = _findClosest(note, pentatonicMajor);
        break;
      case Scale.pentatonicMinor:
        final pentatonicMinor = [0, 3, 5, 7, 10];
        quantizedNote = _findClosest(note, pentatonicMinor);
        break;
    }
    
    final octave = semitone.floor() ~/ 12;
    return octave * 12 + quantizedNote + _key.index;
  }
  
  double _findClosest(double value, List<int> array) {
    double closest = array[0].toDouble();
    double minDiff = (value - closest).abs();
    
    for (int i = 1; i < array.length; i++) {
      final diff = (value - array[i]).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = array[i].toDouble();
      }
    }
    
    return closest;
  }
  
  void setSpeed(double speed) {
    _speed = speed.clamp(1.0, 100.0);
  }
  
  void setStrength(double strength) {
    _strength = strength.clamp(0.0, 1.0);
  }
  
  void setScale(Scale scale) {
    _scale = scale;
  }
  
  void setKey(Key key) {
    _key = key;
  }
  
  void setEnabled(bool enabled) {
    _enabled = enabled;
  }
}

enum Scale {
  chromatic,
  major,
  minor,
  pentatonicMajor,
  pentatonicMinor
}

enum Key {
  c(0),
  cSharp(1),
  d(2),
  dSharp(3),
  e(4),
  f(5),
  fSharp(6),
  g(7),
  gSharp(8),
  a(9),
  aSharp(10),
  b(11);
  
  final int index;
  const Key(this.index);
}

class VocalRemover {
  double _strength = 0.9;
  bool _enabled = true;
  
  List<double> process(List<double> left, List<double> right) {
    if (!_enabled) return left + right;
    
    final mid = List<double>.filled(left.length, 0.0);
    final side = List<double>.filled(left.length, 0.0);
    
    for (int i = 0; i < left.length; i++) {
      mid[i] = (left[i] + right[i]) * 0.5;
      side[i] = (left[i] - right[i]) * 0.5;
    }
    
    final attenuatedMid = mid.map((m) => m * (1 - _strength)).toList();
    
    final newLeft = List<double>.filled(left.length, 0.0);
    final newRight = List<double>.filled(right.length, 0.0);
    
    for (int i = 0; i < left.length; i++) {
      newLeft[i] = attenuatedMid[i] + side[i];
      newRight[i] = attenuatedMid[i] - side[i];
    }
    
    return newLeft + newRight;
  }
  
  void setStrength(double strength) {
    _strength = strength.clamp(0.0, 1.0);
  }
  
  void setEnabled(bool enabled) {
    _enabled = enabled;
  }
}

class BassEnhancer {
  double _amount = 0.0;
  double _frequency = 100.0;
  bool _enabled = true;
  
  final BiquadFilter _lowShelf = BiquadFilter();
  
  List<double> process(List<double> input) {
    if (!_enabled || _amount == 0.0) return input;
    
    _lowShelf.configureLowShelf(_frequency, 44100, 0.707, _amount * 12);
    return _lowShelf.process(input);
  }
  
  void setAmount(double amount) {
    _amount = amount.clamp(0.0, 1.0);
  }
  
  void setFrequency(double frequency) {
    _frequency = frequency.clamp(20.0, 200.0);
  }
  
  void setEnabled(bool enabled) {
    _enabled = enabled;
  }
}

class MasteringProcessor {
  double _loudness = -14.0;
  double _excitement = 0.0;
  double _stereoWidth = 1.0;
  bool _enabled = true;
  
  final LimiterProcessor _limiter = LimiterProcessor();
  final HarmonicExciter _exciter = HarmonicExciter();
  final StereoWidener _widener = StereoWidener();
  
  List<double> process(List<double> left, List<double> right) {
    if (!_enabled) return left + right;
    
    _limiter.setThreshold(_loudness + 1.0);
    _exciter.setAmount(_excitement);
    _widener.setWidth(_stereoWidth);
    
    final limitedLeft = _limiter.process(left);
    final limitedRight = _limiter.process(right);
    
    final excitedLeft = _exciter.process(limitedLeft);
    final excitedRight = _exciter.process(limitedRight);
    
    final widened = _widener.process(excitedLeft, excitedRight);
    
    return widened;
  }
  
  void setLoudness(double loudnessLUFS) {
    _loudness = loudnessLUFS.clamp(-30.0, 0.0);
  }
  
  void setExcitement(double excitement) {
    _excitement = excitement.clamp(0.0, 1.0);
  }
  
  void setStereoWidth(double width) {
    _stereoWidth = width.clamp(0.0, 3.0);
  }
  
  void setEnabled(bool enabled) {
    _enabled = enabled;
  }
}

class PlaylistController {
  final AudioPlayer _primaryPlayer;
  final AudioPlayer _secondaryPlayer;
  
  final List<AudioSource> _playlist = [];
  final List<AudioSource> _originalOrder = [];
  int _currentIndex = -1;
  ShuffleMode _shuffleMode = ShuffleMode.none;
  List<int> _shuffleOrder = [];
  
  final BehaviorSubject<List<AudioSource>> _playlistSubject = BehaviorSubject.seeded([]);
  final BehaviorSubject<int> _currentIndexSubject = BehaviorSubject.seeded(-1);
  
  PlaylistController(this._primaryPlayer, this._secondaryPlayer);
  
  Future<void> add(AudioSource source) async {
    _playlist.add(source);
    _originalOrder.add(source);
    _playlistSubject.add(List.from(_playlist));
    
    if (_currentIndex == -1) {
      await playIndex(0);
    }
  }
  
  Future<void> addAll(List<AudioSource> sources) async {
    _playlist.addAll(sources);
    _originalOrder.addAll(sources);
    _playlistSubject.add(List.from(_playlist));
    
    if (_currentIndex == -1 && sources.isNotEmpty) {
      await playIndex(0);
    }
  }
  
  Future<void> remove(int index) async {
    if (index < 0 || index >= _playlist.length) return;
    
    final wasCurrent = index == _currentIndex;
    _playlist.removeAt(index);
    _originalOrder.removeAt(index);
    
    if (wasCurrent) {
      if (_playlist.isEmpty) {
        _currentIndex = -1;
        await _primaryPlayer.stop();
      } else if (_currentIndex >= _playlist.length) {
        await playIndex(_playlist.length - 1);
      } else {
        await playIndex(_currentIndex);
      }
    } else if (index < _currentIndex) {
      _currentIndex--;
    }
    
    _playlistSubject.add(List.from(_playlist));
    _currentIndexSubject.add(_currentIndex);
  }
  
  Future<void> move(int from, int to) async {
    if (from < 0 || from >= _playlist.length || to < 0 || to >= _playlist.length) return;
    
    final source = _playlist.removeAt(from);
    _playlist.insert(to, source);
    
    if (_currentIndex == from) {
      _currentIndex = to;
    } else if (_currentIndex > from && _currentIndex <= to) {
      _currentIndex--;
    } else if (_currentIndex < from && _currentIndex >= to) {
      _currentIndex++;
    }
    
    _playlistSubject.add(List.from(_playlist));
    _currentIndexSubject.add(_currentIndex);
  }
  
  Future<void> clear() async {
    _playlist.clear();
    _originalOrder.clear();
    _currentIndex = -1;
    _shuffleOrder.clear();
    
    await _primaryPlayer.stop();
    
    _playlistSubject.add([]);
    _currentIndexSubject.add(-1);
  }
  
  Future<void> playIndex(int index) async {
    if (index < 0 || index >= _playlist.length) return;
    
    _currentIndex = index;
    final effectiveIndex = _getEffectiveIndex(index);
    
    await _primaryPlayer.setAudioSource(_playlist[effectiveIndex]);
    await _primaryPlayer.play();
    
    _currentIndexSubject.add(_currentIndex);
  }
  
  Future<void> next() async {
    if (_playlist.isEmpty) return;
    
    if (_shuffleMode == ShuffleMode.none) {
      final nextIndex = (_currentIndex + 1) % _playlist.length;
      await playIndex(nextIndex);
    } else {
      final currentShuffleIndex = _shuffleOrder.indexOf(_currentIndex);
      if (currentShuffleIndex != -1) {
        final nextShuffleIndex = (currentShuffleIndex + 1) % _shuffleOrder.length;
        await playIndex(_shuffleOrder[nextShuffleIndex]);
      }
    }
  }
  
  Future<void> previous() async {
    if (_playlist.isEmpty) return;
    
    if (_shuffleMode == ShuffleMode.none) {
      final prevIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
      await playIndex(prevIndex);
    } else {
      final currentShuffleIndex = _shuffleOrder.indexOf(_currentIndex);
      if (currentShuffleIndex != -1) {
        final prevShuffleIndex = (currentShuffleIndex - 1 + _shuffleOrder.length) % _shuffleOrder.length;
        await playIndex(_shuffleOrder[prevShuffleIndex]);
      }
    }
  }
  
  Future<void> seekToFirst() async {
    if (_playlist.isEmpty) return;
    
    if (_shuffleMode == ShuffleMode.none) {
      await playIndex(0);
    } else {
      await playIndex(_shuffleOrder[0]);
    }
  }
  
  Future<void> seekToLast() async {
    if (_playlist.isEmpty) return;
    
    if (_shuffleMode == ShuffleMode.none) {
      await playIndex(_playlist.length - 1);
    } else {
      await playIndex(_shuffleOrder.last);
    }
  }
  
  void setShuffleMode(ShuffleMode mode) {
    _shuffleMode = mode;
    
    if (mode == ShuffleMode.all) {
      _shuffleOrder = List.generate(_playlist.length, (i) => i);
      _shuffleOrder.shuffle();
    } else {
      _shuffleOrder.clear();
    }
  }
  
  int _getEffectiveIndex(int index) {
    if (_shuffleMode == ShuffleMode.none) return index;
    
    if (_shuffleOrder.isEmpty) {
      _shuffleOrder = List.generate(_playlist.length, (i) => i);
      _shuffleOrder.shuffle();
    }
    
    final shuffleIndex = _shuffleOrder.indexOf(index);
    return shuffleIndex != -1 ? _shuffleOrder[shuffleIndex] : index;
  }
  
  bool get hasNext {
    if (_playlist.isEmpty) return false;
    
    if (_shuffleMode == ShuffleMode.none) {
      return _currentIndex < _playlist.length - 1;
    } else {
      final currentShuffleIndex = _shuffleOrder.indexOf(_currentIndex);
      return currentShuffleIndex < _shuffleOrder.length - 1;
    }
  }
  
  bool get hasPrevious {
    if (_playlist.isEmpty) return false;
    
    if (_shuffleMode == ShuffleMode.none) {
      return _currentIndex > 0;
    } else {
      final currentShuffleIndex = _shuffleOrder.indexOf(_currentIndex);
      return currentShuffleIndex > 0;
    }
  }
  
  List<AudioSource> get playlist => List.unmodifiable(_playlist);
  int get currentIndex => _currentIndex;
  AudioSource get currentSource => _currentIndex >= 0 && _currentIndex < _playlist.length ? _playlist[_currentIndex] : null;
  ShuffleMode get shuffleMode => _shuffleMode;
  
  Stream<List<AudioSource>> get playlistStream => _playlistSubject.stream;
  Stream<int> get currentIndexStream => _currentIndexSubject.stream;
  
  void dispose() {
    _playlistSubject.close();
    _currentIndexSubject.close();
  }
}

class AudioPreset {
  final String name;
  final String description;
  final List<double> equalizerBands;
  final ReverbPreset reverbSettings;
  final EchoPreset echoSettings;
  final CompressorPreset compressorSettings;
  final LimiterPreset limiterSettings;
  final double pitchShift;
  final double timeStretch;
  final double stereoWidth;
  final double bassBoost;
  final double trebleBoost;
  final double loudness;
  final double harmonicExcitation;
  final bool dynamicEQ;
  final bool multibandCompression;
  final bool spatialAudio;
  
  AudioPreset({
    required this.name,
    required this.description,
    required this.equalizerBands,
    required this.reverbSettings,
    required this.echoSettings,
    required this.compressorSettings,
    required this.limiterSettings,
    required this.pitchShift,
    required this.timeStretch,
    required this.stereoWidth,
    required this.bassBoost,
    required this.trebleBoost,
    required this.loudness,
    required this.harmonicExcitation,
    required this.dynamicEQ,
    required this.multibandCompression,
    required this.spatialAudio,
  });
}

class AudioPresetManager {
  final List<AudioPreset> _presets = [];
  final BehaviorSubject<List<AudioPreset>> _presetsSubject = BehaviorSubject.seeded([]);
  
  void initialize() {
    _loadDefaultPresets();
  }
  
  void _loadDefaultPresets() {
    for (int i = 0; i < 100; i++) {
      _presets.add(AudioPreset(
        name: 'Preset ${i + 1}',
        description: 'Custom audio preset ${i + 1}',
        equalizerBands: List.generate(32, (index) => (math.Random().nextDouble() * 24.0 - 12.0)),
        reverbSettings: ReverbPreset.values[math.Random().nextInt(ReverbPreset.values.length)],
        echoSettings: EchoPreset.values[math.Random().nextInt(EchoPreset.values.length)],
        compressorSettings: CompressorPreset.values[math.Random().nextInt(CompressorPreset.values.length)],
        limiterSettings: LimiterPreset.values[math.Random().nextInt(LimiterPreset.values.length)],
        pitchShift: (math.Random().nextDouble() * 4.0 - 2.0),
        timeStretch: (math.Random().nextDouble() * 1.5 + 0.5),
        stereoWidth: (math.Random().nextDouble() * 2.0),
        bassBoost: (math.Random().nextDouble() * 12.0 - 6.0),
        trebleBoost: (math.Random().nextDouble() * 12.0 - 6.0),
        loudness: (math.Random().nextDouble() * 6.0 - 3.0),
        harmonicExcitation: (math.Random().nextDouble() * 5.0),
        dynamicEQ: math.Random().nextBool(),
        multibandCompression: math.Random().nextBool(),
        spatialAudio: math.Random().nextBool()
      ));
    }
    
    _presetsSubject.add(List.from(_presets));
  }
  
  void addPreset(AudioPreset preset) {
    _presets.add(preset);
    _presetsSubject.add(List.from(_presets));
  }
  
  void removePreset(int index) {
    if (index >= 0 && index < _presets.length) {
      _presets.removeAt(index);
      _presetsSubject.add(List.from(_presets));
    }
  }
  
  void updatePreset(int index, AudioPreset preset) {
    if (index >= 0 && index < _presets.length) {
      _presets[index] = preset;
      _presetsSubject.add(List.from(_presets));
    }
  }
  
  Future<void> applyPreset(AudioPreset preset) async {
    final audioEngine = AudioEngine();
    
    for (int i = 0; i < preset.equalizerBands.length; i++) {
      await audioEngine.setEqualizerBand(i, preset.equalizerBands[i]);
    }
    
    await audioEngine.setRverb(preset.reverbSettings);
    await audioEngine.setEcho(preset.echoSettings);
  }
  
  List<AudioPreset> get presets => List.unmodifiable(_presets);
  Stream<List<AudioPreset>> get presetsStream => _presetsSubject.stream;
  
  void dispose() {
    _presetsSubject.close();
  }
}

class AudioAnalyzer {
  final List<double> _waveform = [];
  final List<double> _spectrum = [];
  final List<double> _spectrogram = [];
  final BehaviorSubject<List<double>> _waveformSubject = BehaviorSubject();
  final BehaviorSubject<List<double>> _spectrumSubject = BehaviorSubject();
  final BehaviorSubject<List<double>> _spectrogramSubject = BehaviorSubject();
  
  void analyze(List<double> samples, int sampleRate) {
    _updateWaveform(samples);
    _updateSpectrum(samples, sampleRate);
    _updateSpectrogram(samples, sampleRate);
    
    _waveformSubject.add(List.from(_waveform));
    _spectrumSubject.add(List.from(_spectrum));
    _spectrogramSubject.add(List.from(_spectrogram));
  }
  
  void _updateWaveform(List<double> samples) {
    _waveform.clear();
    
    final downsampleFactor = (samples.length / 512).ceil();
    for (int i = 0; i < samples.length; i += downsampleFactor) {
      double max = 0.0;
      for (int j = 0; j < downsampleFactor && i + j < samples.length; j++) {
        max = math.max(max, samples[i + j].abs());
      }
      _waveform.add(max);
    }
  }
  
  void _updateSpectrum(List<double> samples, int sampleRate) {
    _spectrum.clear();
    
    final fft = FFT(samples.length);
    final complex = ComplexArray(samples.length);
    
    for (int i = 0; i < samples.length; i++) {
      complex.real[i] = samples[i];
      complex.imag[i] = 0.0;
    }
    
    fft.transform(complex);
    
    for (int i = 0; i < samples.length ~/ 2; i++) {
      final real = complex.real[i];
      final imag = complex.imag[i];
      final magnitude = math.sqrt(real * real + imag * imag);
      _spectrum.add(magnitude);
    }
  }
  
  void _updateSpectrogram(List<double> samples, int sampleRate) {
    final windowSize = 2048;
    final hopSize = windowSize ~/ 4;
    
    for (int start = 0; start + windowSize <= samples.length; start += hopSize) {
      final window = samples.sublist(start, start + windowSize);
      final spectrum = _computeSpectrum(window);
      
      for (int i = 0; i < spectrum.length; i++) {
        _spectrogram.add(spectrum[i]);
      }
    }
  }
  
  List<double> _computeSpectrum(List<double> window) {
    final fft = FFT(window.length);
    final complex = ComplexArray(window.length);
    
    for (int i = 0; i < window.length; i++) {
      complex.real[i] = window[i];
      complex.imag[i] = 0.0;
    }
    
    fft.transform(complex);
    
    final spectrum = List<double>.filled(window.length ~/ 2, 0.0);
    for (int i = 0; i < spectrum.length; i++) {
      final real = complex.real[i];
      final imag = complex.imag[i];
      spectrum[i] = math.sqrt(real * real + imag * imag);
    }
    
    return spectrum;
  }
  
  Stream<List<double>> get waveformStream => _waveformSubject.stream;
  Stream<List<double>> get spectrumStream => _spectrumSubject.stream;
  Stream<List<double>> get spectrogramStream => _spectrogramSubject.stream;
  
  void dispose() {
    _waveformSubject.close();
    _spectrumSubject.close();
    _spectrogramSubject.close();
  }
}

class AudioCacheManager {
  final Map<String, List<double>> _cache = {};
  final int _maxSize = 1073741824;
  int _currentSize = 0;
  final List<String> _accessOrder = [];
  
  Future<void> cacheAudio(String id, List<double> samples) async {
    final size = samples.length * 8;
    
    if (_currentSize + size > _maxSize) {
      _makeSpace(size);
    }
    
    _cache[id] = samples;
    _currentSize += size;
    _updateAccessOrder(id);
  }
  
  Future<List<double>> getAudio(String id) async {
    if (_cache.containsKey(id)) {
      _updateAccessOrder(id);
      return List.from(_cache[id]!);
    }
    
    return [];
  }
  
  Future<void> removeAudio(String id) async {
    if (_cache.containsKey(id)) {
      final size = _cache[id]!.length * 8;
      _cache.remove(id);
      _currentSize -= size;
      _accessOrder.remove(id);
    }
  }
  
  Future<void> clear() async {
    _cache.clear();
    _currentSize = 0;
    _accessOrder.clear();
  }
  
  void _makeSpace(int requiredSize) {
    while (_accessOrder.isNotEmpty && _currentSize + requiredSize > _maxSize) {
      final id = _accessOrder.removeAt(0);
      if (_cache.containsKey(id)) {
        final size = _cache[id]!.length * 8;
        _cache.remove(id);
        _currentSize -= size;
      }
    }
  }
  
  void _updateAccessOrder(String id) {
    _accessOrder.remove(id);
    _accessOrder.add(id);
  }
  
  bool contains(String id) => _cache.containsKey(id);
  int get size => _currentSize;
  int get count => _cache.length;
}

class AudioMetadataExtractor {
  final Map<String, dynamic> _metadata = {};
  final BehaviorSubject<Map<String, dynamic>> _metadataSubject = BehaviorSubject();
  
  Future<void> extract(AudioSource source) async {
    _metadata.clear();
    
    _metadata['title'] = 'Unknown Title';
    _metadata['artist'] = 'Unknown Artist';
    _metadata['album'] = 'Unknown Album';
    _metadata['genre'] = 'Unknown Genre';
    _metadata['year'] = 'Unknown Year';
    _metadata['trackNumber'] = 0;
    _metadata['duration'] = 0;
    _metadata['bitrate'] = 0;
    _metadata['sampleRate'] = 0;
    _metadata['channels'] = 0;
    
    _metadataSubject.add(Map.from(_metadata));
  }
  
  Stream<Map<String, dynamic>> get metadataStream => _metadataSubject.stream;
  Map<String, dynamic> get metadata => Map.unmodifiable(_metadata);
  
  void dispose() {
    _metadataSubject.close();
  }
}

class AudioStreamRecorder {
  final List<double> _recordedSamples = [];
  final BehaviorSubject<List<double>> _recordingSubject = BehaviorSubject();
  bool _isRecording = false;
  
  void startRecording() {
    _recordedSamples.clear();
    _isRecording = true;
  }
  
  void addSamples(List<double> samples) {
    if (_isRecording) {
      _recordedSamples.addAll(samples);
      _recordingSubject.add(List.from(_recordedSamples));
    }
  }
  
  List<double> stopRecording() {
    _isRecording = false;
    return List.from(_recordedSamples);
  }
  
  bool get isRecording => _isRecording;
  Stream<List<double>> get recordingStream => _recordingSubject.stream;
  
  void dispose() {
    _recordingSubject.close();
  }
}

class AudioSessionController {
  bool _isActive = false;
  bool _isInterrupted = false;
  bool _otherAudioPlaying = false;
  
  Future<void> initialize() async {
    _isActive = true;
  }
  
  Future<void> activate() async {
    _isActive = true;
  }
  
  Future<void> deactivate() async {
    _isActive = false;
  }
  
  void handleInterruption(bool began) {
    _isInterrupted = began;
  }
  
  void handleOtherAudioPlaying(bool playing) {
    _otherAudioPlaying = playing;
  }
  
  bool get isActive => _isActive;
  bool get isInterrupted => _isInterrupted;
  bool get otherAudioPlaying => _otherAudioPlaying;
}

class AudioEffectChain {
  final List<AudioEffect> _effects = [];
  final BehaviorSubject<List<AudioEffect>> _effectsSubject = BehaviorSubject.seeded([]);
  
  void addEffect(AudioEffect effect) {
    _effects.add(effect);
    _effectsSubject.add(List.from(_effects));
  }
  
  void removeEffect(int index) {
    if (index >= 0 && index < _effects.length) {
      _effects.removeAt(index);
      _effectsSubject.add(List.from(_effects));
    }
  }
  
  void moveEffect(int from, int to) {
    if (from < 0 || from >= _effects.length || to < 0 || to >= _effects.length) return;
    
    final effect = _effects.removeAt(from);
    _effects.insert(to, effect);
    _effectsSubject.add(List.from(_effects));
  }
  
  List<double> process(List<double> input) {
    List<double> output = List.from(input);
    
    for (var effect in _effects) {
      if (effect.enabled) {
        output = effect.process(output);
      }
    }
    
    return output;
  }
  
  List<AudioEffect> get effects => List.unmodifiable(_effects);
  Stream<List<AudioEffect>> get effectsStream => _effectsSubject.stream;
  
  void dispose() {
    _effectsSubject.close();
  }
}

abstract class AudioEffect {
  String get name;
  bool get enabled;
  set enabled(bool value);
  List<double> process(List<double> input);
}

class AudioVisualizer {
  final List<double> _waveformPoints = [];
  final List<double> _spectrumPoints = [];
  final BehaviorSubject<List<double>> _waveformSubject = BehaviorSubject();
  final BehaviorSubject<List<double>> _spectrumSubject = BehaviorSubject();
  
  void update(List<double> waveform, List<double> spectrum) {
    _waveformPoints.clear();
    _spectrumPoints.clear();
    
    _waveformPoints.addAll(waveform);
    _spectrumPoints.addAll(spectrum);
    
    _waveformSubject.add(List.from(_waveformPoints));
    _spectrumSubject.add(List.from(_spectrumPoints));
  }
  
  Stream<List<double>> get waveformStream => _waveformSubject.stream;
  Stream<List<double>> get spectrumStream => _spectrumSubject.stream;
  
  void dispose() {
    _waveformSubject.close();
    _spectrumSubject.close();
  }
}

class AudioFormatConverter {
  List<double> convertToMono(List<double> left, List<double> right) {
    if (left.length != right.length) {
      throw ArgumentError('Channels must have same length');
    }
    
    final mono = List<double>.filled(left.length, 0.0);
    for (int i = 0; i < left.length; i++) {
      mono[i] = (left[i] + right[i]) * 0.5;
    }
    
    return mono;
  }
  
  List<double> convertToStereo(List<double> mono) {
    final left = List<double>.from(mono);
    final right = List<double>.from(mono);
    return left + right;
  }
  
  List<double> resample(List<double> input, int originalRate, int targetRate) {
    if (originalRate == targetRate) return input;
    
    final ratio = originalRate / targetRate;
    final outputLength = (input.length / ratio).ceil();
    final output = List<double>.filled(outputLength, 0.0);
    
    for (int i = 0; i < outputLength; i++) {
      final pos = i * ratio;
      final index = pos.floor();
      final fraction = pos - index;
      
      if (index + 1 < input.length) {
        output[i] = input[index] * (1 - fraction) + input[index + 1] * fraction;
      } else {
        output[i] = input[input.length - 1];
      }
    }
    
    return output;
  }
  
  List<double> changeBitDepth(List<double> input, int fromBits, int toBits) {
    if (fromBits == toBits) return input;
    
    final fromMax = math.pow(2, fromBits - 1).toDouble();
    final toMax = math.pow(2, toBits - 1).toDouble();
    
    return input.map((sample) {
      final quantized = (sample * fromMax).round() / fromMax;
      return quantized * (toMax / fromMax);
    }).toList();
  }
  
  List<double> normalize(List<double> input, double targetLevel) {
    if (input.isEmpty) return input;
    
    double max = 0.0;
    for (final sample in input) {
      max = math.max(max, sample.abs());
    }
    
    if (max == 0.0) return input;
    
    final gain = targetLevel / max;
    return input.map((sample) => sample * gain).toList();
  }
  
  List<double> applyDithering(List<double> input, int bits) {
    final step = 1.0 / math.pow(2, bits - 1);
    final output = List<double>.filled(input.length, 0.0);
    
    for (int i = 0; i < input.length; i++) {
      final noise = (math.Random().nextDouble() * 2 - 1) * step;
      output[i] = input[i] + noise;
    }
    
    return output;
  }
}

class AudioCommand {
  final CommandType type;
  final Map<String, dynamic> data;
  final Completer<void> completer;
  
  AudioCommand(this.type, this.data, this.completer);
}

enum CommandType {
  play,
  pause,
  stop,
  seek,
  load,
  setVolume,
  setPlaybackRate,
  setEqualizer,
  setReverb,
  setEcho,
  applyPreset,
  addToPlaylist,
  removeFromPlaylist,
  clearPlaylist,
  nextTrack,
  previousTrack,
  setShuffle,
  setLoop,
  startRecording,
  stopRecording,
  addEffect,
  removeEffect,
  clearEffects,
  analyzeAudio,
  extractMetadata,
  cacheAudio,
  getCachedAudio,
  convertFormat,
  resampleAudio,
  normalizeAudio,
  applyDithering,
  changeBitDepth
}