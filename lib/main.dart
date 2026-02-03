import 'package:flutter/material.dart';
import 'dart:ui';
import 'core/audio_kernel.dart';

void main() => runApp(const CentApp());

class CentApp extends StatelessWidget {
  const CentApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFFD4AF37),
        scaffoldBackgroundColor: const Color(0xFF000000),
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
          // المشغل العائم (مثل تطبيقات الموسيقى العالمية)
          Positioned(bottom: 0, left: 0, right: 0, child: _buildGlobalMiniPlayer()),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // --- واجهة الصفحة الرئيسية (التريندات وآخر المسموع) ---
  Widget _buildHomeTab() {
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("Recently Played"),
              _buildRecentList(), // آخر الأغاني
              _buildSectionTitle("Global Trending"),
              _buildTrendingGrid(), // التريندات
              const SizedBox(height: 120), // مساحة للمشغل السفلي
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar() {
    return const SliverAppBar(
      expandedHeight: 120,
      backgroundColor: Colors.black,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.only(left: 20, bottom: 16),
        title: Text("CENT SUPREME", style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, letterSpacing: 2)),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }

  // قائمة "آخر الأغاني"
  Widget _buildRecentList() {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: 5,
        itemBuilder: (context, i) => Container(
          width: 140,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            image: const DecorationImage(image: NetworkImage("https://picsum.photos/200"), fit: BoxFit.cover),
            // نضيف تراكب تدرجي فوق الصورة
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black.withOpacity(0.8), Colors.transparent],
            ),
          ),
          // محتوًى العنصر
          alignment: Alignment.bottomLeft,
          padding: const EdgeInsets.all(10),
          child: const Text("Recent Track", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
    );
  }

  // شبكة "التريندات"
  Widget _buildTrendingGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 15, crossAxisSpacing: 15, childAspectRatio: 1.5),
      itemCount: 4,
      itemBuilder: (context, i) => Container(
        decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.2))),
        child: const Row(
          children: [
            Padding(padding: EdgeInsets.all(8.0), child: Icon(Icons.trending_up, color: Color(0xFFD4AF37))),
            Text("Trending #1", style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  // --- واجهة البحث ---
  Widget _buildSearchTab() {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF111111),
                prefixIcon: const Icon(Icons.search, color: Color(0xFFD4AF37)),
                hintText: "Search artist, songs...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
            ),
          ),
          const Expanded(child: Center(child: Text("Search Engine Ready"))),
        ],
      ),
    );
  }

  // --- واجهة المفضلة ---
  Widget _buildFavoritesTab() {
    return const Center(child: Text("Your Golden Collection", style: TextStyle(color: Color(0xFFD4AF37))));
  }

  // --- المشغل العالمي (Mini-Player) ---
  Widget _buildGlobalMiniPlayer() {
    return StreamBuilder<AudioTrack?>(
      stream: _kernel.currentTrackStream,
      builder: (context, snapshot) {
        return ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: 80,
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A).withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  // لا نضع const هنا لأن NetworkImage ليست const
                  CircleAvatar(radius: 25, backgroundImage: NetworkImage("https://picsum.photos/100")),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(snapshot.data?.title ?? "Select Track", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(snapshot.data?.artist ?? "Cent Music", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.skip_previous), onPressed: () => _kernel.previous()),
                  StreamBuilder<AudioState>(
                    stream: _kernel.stateStream,
                    builder: (context, s) {
                      final isPlaying = s.data == AudioState.playing;
                      return IconButton(
                        icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, size: 40, color: const Color(0xFFD4AF37)),
                        onPressed: () => isPlaying ? _kernel.pause() : _kernel.play(),
                      );
                    },
                  ),
                  IconButton(icon: const Icon(Icons.skip_next), onPressed: () => _kernel.next()),
                ],
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
      backgroundColor: Colors.black,
      selectedItemColor: const Color(0xFFD4AF37),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
        BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Favorites"),
      ],
    );
  }
}