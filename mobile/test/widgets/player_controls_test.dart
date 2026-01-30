// mobile/test/widgets/player_controls_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cent_app/src/features/player/widgets/player_controls.dart';
import 'package:cent_app/src/features/player/providers/player_provider.dart';

void main() {
  group('PlayerControls Widget Tests', () {
    late ProviderContainer container;
    late MockPlayerService mockPlayerService;

    setUp(() {
      container = ProviderContainer(overrides: [
        playerServiceProvider.overrideWithValue(MockPlayerService()),
      ]);
      mockPlayerService = container.read(playerServiceProvider) as MockPlayerService;
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('renders play button when paused', (tester) async {
      mockPlayerService.isPlaying = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            parent: container,
            child: Scaffold(
              body: PlayerControls(),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsNothing);
    });

    testWidgets('renders pause button when playing', (tester) async {
      mockPlayerService.isPlaying = true;
      
      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            parent: container,
            child: Scaffold(
              body: PlayerControls(),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.pause), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
    });

    testWidgets('toggles play/pause when button is tapped', (tester) async {
      mockPlayerService.isPlaying = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            parent: container,
            child: Scaffold(
              body: PlayerControls(),
            ),
          ),
        ),
      );

      // Tap play button
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();
      
      expect(mockPlayerService.playCalled, isTrue);
      
      // Update state to playing
      mockPlayerService.isPlaying = true;
      container.read(playerProvider.notifier).state = 
        container.read(playerProvider.notifier).state.copyWith(
          isPlaying: true,
        );
      
      await tester.pump();
      
      expect(find.byIcon(Icons.pause), findsOneWidget);
      
      // Tap pause button
      await tester.tap(find.byIcon(Icons.pause));
      await tester.pump();
      
      expect(mockPlayerService.pauseCalled, isTrue);
    });

    testWidgets('skips to next track when next button is tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            parent: container,
            child: Scaffold(
              body: PlayerControls(),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.skip_next));
      await tester.pump();
      
      expect(mockPlayerService.skipToNextCalled, isTrue);
    });

    testWidgets('skips to previous track when previous button is tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            parent: container,
            child: Scaffold(
              body: PlayerControls(),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.skip_previous));
      await tester.pump();
      
      expect(mockPlayerService.skipToPreviousCalled, isTrue);
    });

    testWidgets('shows progress slider', (tester) async {
      mockPlayerService.duration = Duration(minutes: 3);
      mockPlayerService.position = Duration(minutes: 1);
      
      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            parent: container,
            child: Scaffold(
              body: PlayerControls(),
            ),
          ),
        ),
      );

      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('updates progress when slider is dragged', (tester) async {
      mockPlayerService.duration = Duration(minutes: 3);
      mockPlayerService.position = Duration(minutes: 1);
      
      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            parent: container,
            child: Scaffold(
              body: PlayerControls(),
            ),
          ),
        ),
      );

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.value, 1.0 / 3.0);
      
      // Simulate drag to 2 minutes
      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.byType(Slider)),
      );
      await gesture.moveBy(const Offset(100, 0));
      await gesture.up();
      await tester.pump();
      
      expect(mockPlayerService.seekCalled, isTrue);
      expect(mockPlayerService.seekPosition?.inMinutes, 2);
    });

    testWidgets('disables buttons when loading', (tester) async {
      container.read(playerProvider.notifier).state = 
        PlayerState(
          isPlaying: false,
          isLoading: true,
          currentTrack: null,
          queue: [],
        );
      
      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            parent: container,
            child: Scaffold(
              body: PlayerControls(),
            ),
          ),
        ),
      );

      // Buttons should be disabled
      final playButton = tester.widget<IconButton>(find.byIcon(Icons.play_arrow));
      expect(playButton.onPressed, isNull);
      
      final nextButton = tester.widget<IconButton>(find.byIcon(Icons.skip_next));
      expect(nextButton.onPressed, isNull);
      
      final prevButton = tester.widget<IconButton>(find.byIcon(Icons.skip_previous));
      expect(prevButton.onPressed, isNull);
    });

    testWidgets('shows loading indicator when buffering', (tester) async {
      container.read(playerProvider.notifier).state = 
        PlayerState(
          isPlaying: true,
          isLoading: false,
          isBuffering: true,
          currentTrack: null,
          queue: [],
        );
      
      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            parent: container,
            child: Scaffold(
              body: PlayerControls(),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}

class MockPlayerService extends PlayerService {
  bool isPlaying = false;
  bool playCalled = false;
  bool pauseCalled = false;
  bool skipToNextCalled = false;
  bool skipToPreviousCalled = false;
  bool seekCalled = false;
  Duration? seekPosition;
  
  Duration duration = Duration.zero;
  Duration position = Duration.zero;
  
  @override
  Future<void> play() async {
    playCalled = true;
    isPlaying = true;
  }
  
  @override
  Future<void> pause() async {
    pauseCalled = true;
    isPlaying = false;
  }
  
  @override
  Future<void> skipToNext() async {
    skipToNextCalled = true;
  }
  
  @override
  Future<void> skipToPrevious() async {
    skipToPreviousCalled = true;
  }
  
  @override
  Future<void> seek(Duration position) async {
    seekCalled = true;
    seekPosition = position;
  }
}
