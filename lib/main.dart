import 'package:flutter/material.dart';
import 'dart:ui';
import 'core/audio_kernel.dart';

void main() {
  runApp(const CentApp());
}

class CentApp extends StatelessWidget {
  const CentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cent Music',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFD4AF37), // اللون الذهبي الملكي
        scaffoldBackgroundColor: const Color(0xFF050505), // أسود فاخر
      ),
      home: const SovereignPlayer(),
    );
  }
}

class SovereignPlayer extends StatefulWidget {
  const SovereignPlayer({super.key});

  @override
  State<SovereignPlayer> createState() => _SovereignPlayerState();
}

class _SovereignPlayerState extends State<SovereignPlayer> with SingleTickerProviderStateMixin {
  final AudioKernel _kernel = AudioKernel(); // استدعاء المحرك الماسي من ديب سيك
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // الخلفية المتدرجة
          _buildBackground(),
          
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                _buildSearchBar(),
                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: [
                      _buildHomeContent(),
                      _buildSearchPlaceholder(),
                      _buildLibraryPlaceholder(),
                    ],
                  ),
                ),
                _buildBottomPlayerBar(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.7, -0.6),
          radius: 1.5,
          colors: [Color(0xFF1A1200), Color(0xFF050505)],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("WELCOME TO", style: TextStyle(color: Color(0xFFD4AF37), fontSize: 12, letterSpacing: 2)),
              Text("CENT", style: TextStyle(fontSize: 32, fontWeight: FontWeight.black, letterSpacing: 4)),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD4AF37), width: 1),
            ),
            child: const Icon(Icons.person_outline, color: Color(0xFFD4AF37)),
          )
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            height: 55,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: const TextField(
              decoration: InputDecoration(
                icon: Icon(Icons.search, color: Color(0xFFD4AF37)),
                hintText: "Search your supreme music...",
                hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildSectionHeader("Visualizer Feed"),
          _buildLiveVisualizer(),
          _buildSectionHeader("Trending Now"),
          _buildTrendingList(),
        ],
      ),
    );
  }

  Widget _buildLiveVisualizer() {
    return StreamBuilder<AudioVisualizationData>(
      stream: _kernel.visualizationStream,
      builder: (context, snapshot) {
        final data = snapshot.data?.magnitudes ?? List.filled(40, 0.1);
        return Container(
          height: 200,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: data.take(30).map((m) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: 6,
                height: 30 + (140 * m),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD4AF37), Color(0xFFB8860B)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.2 * m), blurRadius: 5, spreadRadius: 1)
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37))),
    );
  }

  Widget _buildTrendingList() {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            width: 160,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              image: const DecorationImage(
                image: NetworkImage("https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?q=80&w=500"),
                fit: BoxFit.cover,
                opacity: 0.5,
              ),
            ),
            child: const Center(child: Icon(Icons.play_circle_fill, size: 50, color: Color(0xFFD4AF37))),
          );
        },
      ),
    );
  }

  Widget _buildBottomPlayerBar() {
    return StreamBuilder<AudioTrack?>(
      stream: _kernel.currentTrackStream,
      builder: (context, snapshot) {
        return Container(
          margin: const EdgeInsets.all(15),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.5)),
          ),
          child: Row(
            children: [
              const CircleAvatar(backgroundColor: Color(0xFFD4AF37), child: Icon(Icons.music_note, color: Colors.black)),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(snapshot.data?.title ?? "Idle Mode", style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(snapshot.data?.artist ?? "Cent Audio Engine", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
              StreamBuilder<AudioState>(
                stream: _kernel.stateStream,
                builder: (context, snap) {
                  final playing = snap.data == AudioState.playing;
                  return IconButton(
                    icon: Icon(playing ? Icons.pause_circle_filled : Icons.play_circle_filled, color: const Color(0xFFD4AF37), size: 35),
                    onPressed: () => playing ? _kernel.pause() : _kernel.play(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (i) => setState(() => _currentIndex = i),
      backgroundColor: Colors.black,
      selectedItemColor: const Color(0xFFD4AF37),
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: false,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.explore), label: "Discover"),
        BottomNavigationBarItem(icon: Icon(Icons.library_music), label: "Library"),
      ],
    );
  }

  Widget _buildSearchPlaceholder() => const Center(child: Text("Global Audio Search Engine"));
  Widget _buildLibraryPlaceholder() => const Center(child: Text("Supreme Collection"));
}

