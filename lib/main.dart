import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'core/audio_kernel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF000000),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  await AudioKernel().initialize();
  runApp(const CentApp());
}

class CentApp extends StatelessWidget {
  const CentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF1DB954),
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF1DB954),
          secondary: Color(0xFF1DB954),
          surface: Color(0xFF181818),
          background: Color(0xFF121212),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        cardTheme: CardTheme(
          color: const Color(0xFF282828),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
          headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          bodyLarge: TextStyle(fontSize: 16, color: Colors.white),
          bodyMedium: TextStyle(fontSize: 14, color: Color(0xFFB3B3B3)),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final AudioKernel _kernel = AudioKernel();
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedTab,
            children: [
              _buildHomeTab(),
              _buildSearchTab(),
              _buildLibraryTab(),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildMiniPlayer(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHomeTab() {
    final hour = DateTime.now().hour;
    String greeting = hour < 12 ? 'Good morning' : hour < 18 ? 'Good afternoon' : 'Good evening';

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 0,
          floating: true,
          pinned: false,
          backgroundColor: Colors.transparent,
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                _buildQuickAccessGrid(),
                const SizedBox(height: 32),
                _buildSectionHeader('Recently played'),
                const SizedBox(height: 16),
                _buildRecentlyPlayed(),
                const SizedBox(height: 32),
                _buildSectionHeader('Made for you'),
                const SizedBox(height: 16),
                _buildMadeForYou(),
                const SizedBox(height: 32),
                _buildSectionHeader('Popular playlists'),
                const SizedBox(height: 16),
                _buildPopularPlaylists(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAccessGrid() {
    final items = [
      {'title': 'Liked Songs', 'color': const Color(0xFF5E17EB)},
      {'title': 'Daily Mix 1', 'color': const Color(0xFFE13300)},
      {'title': 'Discover Weekly', 'color': const Color(0xFF1E3264)},
      {'title': 'Release Radar', 'color': const Color(0xFF27856A)},
      {'title': 'Your Top Songs', 'color': const Color(0xFF8D67AB)},
      {'title': 'Chill Vibes', 'color': const Color(0xFFB49BC8)},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3.2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => _playQuickAccess(index),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF282828),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: items[index]['color'] as Color,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      bottomLeft: Radius.circular(4),
                    ),
                  ),
                  child: const Icon(Icons.favorite, color: Colors.white, size: 24),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      items[index]['title'] as String,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentlyPlayed() {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 6,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _playQuickAccess(index),
            child: Container(
              width: 150,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        color: const Color(0xFF282828),
                        child: const Icon(Icons.music_note, size: 50, color: Color(0xFF535353)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Playlist ${index + 1}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your favorite tracks',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFB3B3B3),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMadeForYou() {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _playQuickAccess(index),
            child: Container(
              width: 150,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF1DB954),
                              const Color(0xFF1ED760).withOpacity(0.8),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Mix ${index + 1}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Daily Mix ${index + 1}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your personalized mix',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFB3B3B3),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPopularPlaylists() {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _playQuickAccess(index),
            child: Container(
              width: 150,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        color: const Color(0xFF282828),
                        child: const Icon(Icons.music_note, size: 50, color: Color(0xFF535353)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Top Hits ${index + 1}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Popular right now',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFB3B3B3),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _playQuickAccess(int index) async {
    final track = AudioTrack(
      id: 'demo_$index',
      uri: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-${(index % 8) + 1}.mp3',
      title: 'Demo Track ${index + 1}',
      artist: 'Demo Artist',
      coverArt: null,
    );
    await _kernel.playTrack(track);
  }

  Widget _buildSearchTab() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Search',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'What do you want to listen to?',
                hintStyle: const TextStyle(color: Color(0xFF535353)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF535353)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
              style: const TextStyle(color: Colors.black),
            ),
            const SizedBox(height: 24),
            const Text(
              'Browse all',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: 8,
                itemBuilder: (context, index) {
                  final colors = [
                    const Color(0xFFDC148C),
                    const Color(0xFF1E3264),
                    const Color(0xFF8D67AB),
                    const Color(0xFFE13300),
                    const Color(0xFF27856A),
                    const Color(0xFFBA5D07),
                    const Color(0xFF777777),
                    const Color(0xFF8D67AB),
                  ];
                  final titles = [
                    'Pop', 'Hip-Hop', 'Rock', 'Latin',
                    'Dance', 'Electronic', 'Indie', 'Jazz',
                  ];
                  return Container(
                    decoration: BoxDecoration(
                      color: colors[index],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        titles[index],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLibraryTab() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your Library',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.search, color: Colors.white),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.white),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildFilterChip('Playlists', true),
                const SizedBox(width: 8),
                _buildFilterChip('Artists', false),
                const SizedBox(width: 8),
                _buildFilterChip('Albums', false),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: 10,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFF282828),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.music_note, color: Color(0xFF535353)),
                    ),
                    title: Text(
                      'Playlist ${index + 1}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      'Playlist • ${10 + index} songs',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFB3B3B3),
                      ),
                    ),
                    contentPadding: EdgeInsets.zero,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF1DB954) : const Color(0xFF282828),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.black : Colors.white,
        ),
      ),
    );
  }

  Widget _buildMiniPlayer() {
    return StreamBuilder<AudioTrack?>(
      stream: _kernel.currentTrackStream,
      builder: (context, snapshot) {
        final track = snapshot.data;
        if (track == null) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () => _openFullPlayer(),
          child: Container(
            height: 64,
            margin: const EdgeInsets.only(left: 8, right: 8, bottom: 76),
            decoration: BoxDecoration(
              color: const Color(0xFF282828),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF181818),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    ),
                  ),
                  child: const Icon(Icons.music_note, color: Color(0xFF535353)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        track.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        track.artist,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFB3B3B3),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                StreamBuilder<AudioState>(
                  stream: _kernel.stateStream,
                  builder: (context, stateSnapshot) {
                    final isPlaying = stateSnapshot.data == AudioState.playing;
                    return IconButton(
                      icon: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () {
                        if (isPlaying) {
                          _kernel.pause();
                        } else {
                          _kernel.play();
                        }
                      },
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openFullPlayer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFullPlayer(),
    );
  }

  Widget _buildFullPlayer() {
    return StreamBuilder<AudioTrack?>(
      stream: _kernel.currentTrackStream,
      builder: (context, snapshot) {
        final track = snapshot.data;
        if (track == null) return const SizedBox.shrink();

        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF1DB954).withOpacity(0.5),
                const Color(0xFF121212),
                const Color(0xFF000000),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 32),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'Playing from playlist',
                        style: TextStyle(fontSize: 14, color: Colors.white),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: MediaQuery.of(context).size.width - 48,
                  height: MediaQuery.of(context).size.width - 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF282828),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.music_note, size: 100, color: Color(0xFF535353)),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              track.title,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              track.artist,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFFB3B3B3),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.favorite_border, color: Colors.white, size: 28),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                StreamBuilder<Duration>(
                  stream: _kernel.positionStream,
                  builder: (context, posSnapshot) {
                    final position = posSnapshot.data ?? Duration.zero;
                    return StreamBuilder<Duration?>(
                      stream: _kernel.durationStream,
                      builder: (context, durSnapshot) {
                        final duration = durSnapshot.data ?? Duration.zero;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              SliderTheme(
                                data: const SliderThemeData(
                                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                                  trackHeight: 3,
                                  overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
                                ),
                                child: Slider(
                                  value: duration.inMilliseconds > 0
                                      ? position.inMilliseconds.toDouble().clamp(0.0, duration.inMilliseconds.toDouble())
                                      : 0.0,
                                  max: duration.inMilliseconds.toDouble() > 0 ? duration.inMilliseconds.toDouble() : 1.0,
                                  activeColor: Colors.white,
                                  inactiveColor: const Color(0xFF535353),
                                  onChanged: (value) {
                                    _kernel.seek(Duration(milliseconds: value.toInt()));
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDuration(position),
                                      style: const TextStyle(fontSize: 12, color: Color(0xFFB3B3B3)),
                                    ),
                                    Text(
                                      _formatDuration(duration),
                                      style: const TextStyle(fontSize: 12, color: Color(0xFFB3B3B3)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 24),
                StreamBuilder<AudioState>(
                  stream: _kernel.stateStream,
                  builder: (context, stateSnapshot) {
                    final isPlaying = stateSnapshot.data == AudioState.playing;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.shuffle, color: Color(0xFFB3B3B3)),
                            iconSize: 24,
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.skip_previous, color: Colors.white),
                            iconSize: 36,
                            onPressed: () => _kernel.next(),
                          ),
                          Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(
                                isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.black,
                              ),
                              iconSize: 32,
                              onPressed: () {
                                if (isPlaying) {
                                  _kernel.pause();
                                } else {
                                  _kernel.play();
                                }
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.skip_next, color: Colors.white),
                            iconSize: 36,
                            onPressed: () => _kernel.next(),
                          ),
                          IconButton(
                            icon: const Icon(Icons.repeat, color: Color(0xFFB3B3B3)),
                            iconSize: 24,
                            onPressed: () {},
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFF282828), width: 0.5),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedTab,
        onTap: (i) => setState(() => _selectedTab = i),
        backgroundColor: const Color(0xFF000000),
        selectedItemColor: Colors.white,
        unselectedItemColor: const Color(0xFFB3B3B3),
        selectedFontSize: 12,
        unselectedFontSize: 12,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_music),
            label: 'Your Library',
          ),
        ],
      ),
    );
  }
}
