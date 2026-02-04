import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart'; // لخطوط أنيقة مثل Spotify
import 'package:cached_network_image/cached_network_image.dart'; // لصور أفضل
import 'package:flutter_spinkit/flutter_spinkit.dart'; // للـ loading
import 'core/audio_kernel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AudioKernel().initialize(); // init audio with proper method
  runApp(const CentApp());
}

class CentApp extends StatelessWidget {
  const CentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFFD4AF37), // الذهبي الرئيسي
        scaffoldBackgroundColor: const Color(0xFF121212), // أسود سبوتيفاي
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: const Color(0xFFD4AF37), // accents ذهبية
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          color: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          shadowColor: const Color(0xFFD4AF37).withOpacity(0.2),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme.apply(bodyColor: Colors.white, displayColor: Colors.white),
        ),
      ),
      home: const MainSovereignScreen(),
    );
  }
}

class MainSovereignScreen extends StatefulWidget {
  const MainSovereignScreen({super.key});

  @override
  State<MainSovereignScreen> createState() => _MainSovereignScreenState();
}

class _MainSovereignScreenState extends State<MainSovereignScreen> {
  final AudioKernel _kernel = AudioKernel();
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedTab,
            children: [
              _buildHomeTab(),
              _buildSearchTab(),
              _buildFavoritesTab(),
            ],
          ),
          Positioned(bottom: 0, left: 0, right: 0, child: _buildGlobalMiniPlayer()),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // الصفحة الرئيسية (مثل Spotify Home)
  Widget _buildHomeTab() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 180,
          floating: false,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1A1A1A), Color(0xFF000000)],
                ),
              ),
              child: Center(
                child: Text(
                  "CENT",
                  style: GoogleFonts.michroma(
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFD4AF37),
                    letterSpacing: 4,
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle("Good Evening"),
                _buildRecentGrid(), // كروت كبيرة مثل Spotify
                const SizedBox(height: 24),
                _buildSectionTitle("Trending Now"),
                _buildTrendingList(),
                const SizedBox(height: 100), // مساحة للمشغل
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }

  // كروت ألبومات كبيرة (مثل Spotify)
  Widget _buildRecentGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Card(
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: "https://picsum.photos/300?random=$index",
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const SpinKitPulse(color: Color(0xFFD4AF37)),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                    ),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  ),
                  child: Text(
                    "Playlist ${index + 1}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrendingList() {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            width: 140,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: "https://picsum.photos/200?random=${index + 10}",
                    height: 140,
                    width: 140,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 8),
                Text("Trending ${index + 1}", style: const TextStyle(fontSize: 14)),
              ],
            ),
          );
        },
      ),
    );
  }

  // صفحة البحث (مثل Spotify Search)
  Widget _buildSearchTab() {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: "What do you want to listen to?",
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Color(0xFFD4AF37)),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                "Browse all",
                style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // صفحة المفضلة (Library مثل Spotify)
  Widget _buildFavoritesTab() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Your Library", style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const Text("Playlists • Artists • Albums", style: TextStyle(color: Colors.grey)),
            // أضف ListView للمفضلات هنا لاحقًا
            const Expanded(child: Center(child: Text("Your Golden Favorites", style: TextStyle(fontSize: 20, color: Color(0xFFD4AF37))))),
          ],
        ),
      ),
    );
  }

  // المشغل المصغر المحسن (مع progress bar)
  Widget _buildGlobalMiniPlayer() {
    return StreamBuilder<AudioTrack?>(
      stream: _kernel.currentTrackStream,
      builder: (context, snapshot) {
        final track = snapshot.data;
        return GestureDetector(
          onTap: () {
            // انتقل إلى صفحة المشغل الكامل لاحقًا
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                height: 90,
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E).withOpacity(0.85),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: track?.coverArt ?? "https://picsum.photos/100",
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const SpinKitThreeBounce(color: Color(0xFFD4AF37), size: 20),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            track?.title ?? "No Track Playing",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            track?.artist ?? "Cent Music",
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_previous, color: Color(0xFFD4AF37)),
                      onPressed: _kernel.previous,
                    ),
                    StreamBuilder<AudioState>(
                      stream: _kernel.stateStream,
                      builder: (context, s) {
                        final isPlaying = s.data == AudioState.playing;
                        return IconButton(
                          icon: Icon(
                            isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                            size: 50,
                            color: const Color(0xFFD4AF37),
                          ),
                          onPressed: () => isPlaying ? _kernel.pause() : _kernel.play(),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next, color: Color(0xFFD4AF37)),
                      onPressed: _kernel.next,
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

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedTab,
      onTap: (i) => setState(() => _selectedTab = i),
      backgroundColor: const Color(0xFF000000),
      selectedItemColor: const Color(0xFFD4AF37),
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.search_rounded), label: "Search"),
        BottomNavigationBarItem(icon: Icon(Icons.library_music_rounded), label: "Library"),
      ],
    );
  }
}
