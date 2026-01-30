// mobile/lib/src/features/home/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rive/rive.dart';
import 'package:cent_app/src/core/design_system/design_system.dart';
import 'package:cent_app/src/features/home/providers/home_provider.dart';
import 'package:cent_app/src/features/home/widgets/content_section.dart';
import 'package:cent_app/src/features/home/widgets/quick_actions.dart';
import 'package:cent_app/src/features/home/widgets/now_playing_bar.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scrollController = ScrollController();
  bool _showAppBarBackground = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadHomeData();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _showAppBarBackground = _scrollController.offset > 100;
    });
  }

  Future<void> _loadHomeData() async {
    await ref.read(homeProvider.notifier).loadHomeContent();
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeProvider);
    final theme = AppTheme.of(context);

    return Scaffold(
      backgroundColor: theme.colors.background,
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              pinned: true,
              floating: true,
              expandedHeight: 200.0,
              backgroundColor: _showAppBarBackground
                  ? theme.colors.surface
                  : Colors.transparent,
              elevation: _showAppBarBackground ? 4.0 : 0.0,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        theme.colors.primary.withOpacity(0.8),
                        theme.colors.background.withOpacity(0.3),
                        theme.colors.background,
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good ${_getTimeOfDayGreeting()}',
                          style: theme.textStyles.headlineSmall.copyWith(
                            color: theme.colors.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your personal music universe',
                          style: theme.textStyles.bodyLarge.copyWith(
                            color: theme.colors.onPrimary.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ];
        },
        body: RefreshIndicator(
          onRefresh: _loadHomeData,
          child: _buildContent(homeState, theme),
        ),
      ),
      bottomNavigationBar: const NowPlayingBar(),
    );
  }

  Widget _buildContent(HomeState state, AppTheme theme) {
    if (state.isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: ContentSectionSkeleton(),
          );
        },
      );
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RiveAnimation.asset(
              'assets/animations/error.riv',
              fit: BoxFit.contain,
              height: 150,
            ),
            const SizedBox(height: 20),
            Text(
              'Something went wrong',
              style: theme.textStyles.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              state.error!,
              style: theme.textStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadHomeData,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Quick Actions
        QuickActionsSection(
          actions: state.quickActions,
          onActionSelected: _handleQuickAction,
        ),

        const SizedBox(height: 24),

        // Recently Played
        if (state.recentlyPlayed.isNotEmpty)
          ContentSection(
            title: 'Recently Played',
            items: state.recentlyPlayed,
            onItemTap: _playTrack,
            onSeeAll: () => _navigateToRecentlyPlayed(),
          ),

        const SizedBox(height: 24),

        // Daily Mixes
        if (state.dailyMixes.isNotEmpty)
          ContentSection(
            title: 'Your Daily Mixes',
            items: state.dailyMixes,
            onItemTap: _playPlaylist,
            onSeeAll: () => _navigateToDailyMixes(),
          ),

        const SizedBox(height: 24),

        // Discover Weekly
        if (state.discoverWeekly != null)
          ContentSection(
            title: 'Discover Weekly',
            subtitle: 'Updated every Monday',
            items: [state.discoverWeekly!],
            onItemTap: _playPlaylist,
          ),

        const SizedBox(height: 24),

        // Recommended For You
        if (state.recommendedTracks.isNotEmpty)
          ContentSection(
            title: 'Recommended For You',
            items: state.recommendedTracks,
            onItemTap: _playTrack,
            onSeeAll: () => _navigateToRecommendations(),
          ),

        const SizedBox(height: 24),

        // New Releases
        if (state.newReleases.isNotEmpty)
          ContentSection(
            title: 'New Releases',
            items: state.newReleases,
            onItemTap: _playAlbum,
            onSeeAll: () => _navigateToNewReleases(),
          ),

        const SizedBox(height: 24),

        // Top Charts
        if (state.topCharts.isNotEmpty)
          ContentSection(
            title: 'Top Charts',
            items: state.topCharts,
            onItemTap: _playPlaylist,
            onSeeAll: () => _navigateToCharts(),
          ),

        const SizedBox(height: 80), // Space for now playing bar
      ],
    );
  }

  String _getTimeOfDayGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }

  void _handleQuickAction(QuickAction action) {
    switch (action.type) {
      case QuickActionType.search:
        Navigator.pushNamed(context, '/search');
        break;
      case QuickActionType.likedSongs:
        Navigator.pushNamed(context, '/library/liked');
        break;
      case QuickActionType.radio:
        _startRadio(action.parameters?['seed']);
        break;
      case QuickActionType.mood:
        _playMoodPlaylist(action.parameters?['mood']);
        break;
    }
  }

  void _playTrack(Track track) {
    ref.read(playerProvider.notifier).playTrack(track);
  }

  void _playPlaylist(Playlist playlist) {
    Navigator.pushNamed(
      context,
      '/playlist/${playlist.id}',
      arguments: playlist,
    );
  }

  void _playAlbum(Album album) {
    Navigator.pushNamed(
      context,
      '/album/${album.id}',
      arguments: album,
    );
  }

  void _startRadio(String? seed) {
    // Start radio based on seed
  }

  void _playMoodPlaylist(String? mood) {
    // Play mood-based playlist
  }

  void _navigateToRecentlyPlayed() {
    Navigator.pushNamed(context, '/library/history');
  }

  void _navigateToDailyMixes() {
    Navigator.pushNamed(context, '/collection/daily-mixes');
  }

  void _navigateToRecommendations() {
    Navigator.pushNamed(context, '/recommendations');
  }

  void _navigateToNewReleases() {
    Navigator.pushNamed(context, '/browse/new-releases');
  }

  void _navigateToCharts() {
    Navigator.pushNamed(context, '/browse/charts');
  }
}
