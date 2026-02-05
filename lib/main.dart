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

class AppSettings {
  static bool isArabic = false;

  static String greetingArabic(int hour) {
    if (hour < 12) return 'صباح الخير';
    if (hour < 18) return 'مساء الخير';
    return 'مساء الخير';
  }

  static Map<String, String> translations = {
    'home': 'الرئيسية',
    'search': 'البحث',
    'library': 'المكتبة',
    'settings': 'الإعدادات',
    'about': 'حول',
    'language': 'اللغة',
    'theme': 'المظهر',
    'notifications': 'الإخطارات',
    'logout': 'تسجيل الخروج',
  };
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

  Widget _buildProfileButton() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: GestureDetector(
        onTap: _showSettingsMenu,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFD700).withOpacity(0.1),
            ),
            child: const Icon(
              Icons.person,
              color: Color(0xFFFFD700),
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildSettingsMenu(),
    );
  }

  Widget _buildSettingsMenu() {
    return SafeArea(
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF535353),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              _buildSettingsMenuItem(
                icon: Icons.settings,
                title: AppSettings.isArabic ? 'الإعدادات' : 'Settings',
                onTap: () {
                  Navigator.pop(context);
                  _showSettingsScreen();
                },
              ),
              _buildSettingsMenuItem(
                icon: Icons.info,
                title: AppSettings.isArabic ? 'حول' : 'About',
                onTap: () {
                  Navigator.pop(context);
                  _showAboutScreen();
                },
              ),
              _buildSettingsMenuItem(
                icon: Icons.logout,
                title: AppSettings.isArabic ? 'تسجيل الخروج' : 'Logout',
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: const Color(0xFFFFD700), size: 24),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios, color: Color(0xFF535353), size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSettingsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => _SettingsScreen(onLanguageChange: (isArabic) {
        setState(() {
          AppSettings.isArabic = isArabic;
        });
      })),
    );
  }

  void _showAboutScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const _AboutScreen()),
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
          actions: [
            _buildProfileButton(),
          ],
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
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: _AnimatedCard(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF282828),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    _AnimatedIconContainer(
                      color: items[index]['color'] as Color,
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
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: _AnimatedCard(
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
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: _AnimatedCard(
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
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: _AnimatedCard(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Search',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                _buildProfileButton(),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'What do you want to listen to?',
                hintStyle: const TextStyle(color: Color(0xFF535353)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFFFFD700)),
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
                    _buildAnimatedIconButton(
                      icon: Icons.search,
                      color: const Color(0xFFFFD700),
                      iconSize: 24,
                      onPressed: () {},
                    ),
                    _buildAnimatedIconButton(
                      icon: Icons.add,
                      color: const Color(0xFFFFD700),
                      iconSize: 24,
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
                          _buildAnimatedIconButton(
                            icon: Icons.shuffle,
                            color: const Color(0xFFB3B3B3),
                            iconSize: 24,
                            onPressed: () {},
                          ),
                          _buildAnimatedIconButton(
                            icon: Icons.skip_previous,
                            color: Colors.white,
                            iconSize: 36,
                            onPressed: () => _kernel.next(),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(isPlaying ? 0.5 : 0.2),
                                  blurRadius: isPlaying ? 20 : 5,
                                  spreadRadius: isPlaying ? 2 : 0,
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: AnimatedIcon(
                                icon: AnimatedIcons.play_pause,
                                progress: isPlaying ? AlwaysStoppedAnimation(1.0) : AlwaysStoppedAnimation(0.0),
                                color: Colors.black,
                                size: 32,
                              ),
                              onPressed: () {
                                if (isPlaying) {
                                  _kernel.pause();
                                } else {
                                  _kernel.play();
                                }
                              },
                            ),
                          ),
                          _buildAnimatedIconButton(
                            icon: Icons.skip_next,
                            color: Colors.white,
                            iconSize: 36,
                            onPressed: () => _kernel.next(),
                          ),
                          _buildAnimatedIconButton(
                            icon: Icons.repeat,
                            color: const Color(0xFFB3B3B3),
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

  Widget _buildAnimatedIconButton({
    required IconData icon,
    required Color color,
    required double iconSize,
    required VoidCallback onPressed,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onPressed,
        child: _AnimatedPressButton(
          child: Icon(icon, color: color, size: iconSize),
        ),
      ),
    );
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
        selectedItemColor: const Color(0xFFFFD700),
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

class _AnimatedCard extends StatefulWidget {
  final Widget child;

  const _AnimatedCard({required this.child});

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: AnimatedOpacity(
          opacity: _isHovered ? 1.0 : 0.85,
          duration: const Duration(milliseconds: 300),
          child: widget.child,
        ),
      ),
    );
  }
}

class _AnimatedIconContainer extends StatefulWidget {
  final Color color;
  final Widget child;

  const _AnimatedIconContainer({required this.color, required this.child});

  @override
  State<_AnimatedIconContainer> createState() => _AnimatedIconContainerState();
}

class _AnimatedIconContainerState extends State<_AnimatedIconContainer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: ScaleTransition(
        scale: Tween(begin: 1.0, end: 1.1).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        ),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              bottomLeft: Radius.circular(4),
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class _SettingsScreen extends StatefulWidget {
  final Function(bool) onLanguageChange;

  const _SettingsScreen({required this.onLanguageChange});

  @override
  State<_SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<_SettingsScreen> {
  late bool _isArabic;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _isArabic = AppSettings.isArabic;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isArabic ? 'الإعدادات' : 'Settings'),
        elevation: 0,
        backgroundColor: const Color(0xFF121212),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _buildSettingSection(
            title: _isArabic ? 'التطبيق' : 'Application',
            children: [
              _buildSettingsTile(
                icon: Icons.language,
                title: _isArabic ? 'اللغة' : 'Language',
                subtitle: _isArabic ? 'العربية / English' : 'English / العربية',
                onTap: () {
                  setState(() {
                    _isArabic = !_isArabic;
                    AppSettings.isArabic = _isArabic;
                    widget.onLanguageChange(_isArabic);
                  });
                },
              ),
              _buildSettingsTile(
                icon: Icons.notifications,
                title: _isArabic ? 'الإخطارات' : 'Notifications',
                subtitle: _notificationsEnabled ? 'Enabled' : 'Disabled',
                trailing: Switch(
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() => _notificationsEnabled = value);
                  },
                  activeColor: const Color(0xFFFFD700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSettingSection(
            title: _isArabic ? 'حول' : 'About',
            children: [
              _buildSettingsTile(
                icon: Icons.info,
                title: _isArabic ? 'الإصدار' : 'Version',
                subtitle: '1.0.0',
              ),
              _buildSettingsTile(
                icon: Icons.privacy_tip,
                title: _isArabic ? 'سياسة الخصوصية' : 'Privacy Policy',
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFFFFD700),
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFFFFD700), size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFB3B3B3),
                      ),
                    ),
                  ],
                ),
              ),
              trailing ?? const Icon(Icons.arrow_forward_ios, color: Color(0xFF535353), size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutScreen extends StatefulWidget {
  const _AboutScreen();

  @override
  State<_AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<_AboutScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppSettings.isArabic ? 'حول' : 'About'),
        elevation: 0,
        backgroundColor: const Color(0xFF121212),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF121212),
              const Color(0xFF1A1A1A),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RotationTransition(
                  turns: _controller,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFFFD700),
                          Color(0xFFFFA500),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withOpacity(0.4),
                          blurRadius: 30,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.music_note,
                      size: 60,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'CENT',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFD700),
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: 60,
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  AppSettings.isArabic ? 'تطبيق الموسيقى الاحترافي' : 'Professional Music App',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFFD700),
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF282828),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFFFD700).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        AppSettings.isArabic ? 'تم التطوير بواسطة' : 'Developed by',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFFB3B3B3),
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                        ).createShader(bounds),
                        child: const Text(
                          'MALEK',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'music studio',
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFFFFD700).withOpacity(0.7),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFFB3B3B3).withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '2024 All Rights Reserved',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFFB3B3B3).withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedPressButton extends StatefulWidget {
  final Widget child;

  const _AnimatedPressButton({required this.child});

  @override
  State<_AnimatedPressButton> createState() => _AnimatedPressButtonState();
}

class _AnimatedPressButtonState extends State<_AnimatedPressButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: ScaleTransition(
        scale: Tween(begin: 1.0, end: 0.85).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        ),
        child: widget.child,
      ),
    );
  }
}
