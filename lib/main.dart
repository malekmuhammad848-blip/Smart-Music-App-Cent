import 'package:flutter/material.dart';
import 'dart:ui';

void main() => runApp(const CentMusicElite());

class CentMusicElite extends StatelessWidget {
  const CentMusicElite({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFD4AF37),
        scaffoldBackgroundColor: const Color(0xFF050505),
      ),
      home: const MainScaffold(),
    );
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  final Color gold = const Color(0xFFD4AF37);
  final Color bgBlack = const Color(0xFF050505);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topLeft,
                  radius: 1.2,
                  colors: [gold.withOpacity(0.07), Colors.transparent],
                ),
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildHeader(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 25),
                        _buildSectionHeader("Top 10 Legendary", "Weekly Highlights"),
                        _buildTopTenCarousel(),
                        const SizedBox(height: 40),
                        _buildSectionHeader("Recently Played", "Your History"),
                        _buildRecentGrid(),
                        const SizedBox(height: 40),
                        _buildSectionHeader("Premium Categories", "Smart Filters"),
                        _buildSmartCategories(),
                        const SizedBox(height: 130),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildGlassPlayer(),
        ],
      ),
      bottomNavigationBar: _buildEliteNav(),
    );
  }

  Widget _buildHeader() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      expandedHeight: 70,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [gold, const Color(0xFFFBF5B7), gold],
            ).createShader(bounds),
            child: const Text("CENT", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 4, fontSize: 28)),
          ),
          _build3DButton(Icons.search, 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(subtitle.toUpperCase(), style: TextStyle(color: gold.withOpacity(0.5), fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _buildTopTenCarousel() {
    return Container(
      height: 240,
      margin: const EdgeInsets.only(top: 15),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 10,
        itemBuilder: (context, index) => _buildEliteCard(index),
      ),
    );
  }

  Widget _buildEliteCard(int index) {
    return Container(
      width: 170,
      margin: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(35),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.01)],
        ),
        border: Border.all(color: gold.withOpacity(0.2), width: 0.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                image: const DecorationImage(
                  image: NetworkImage("https://picsum.photos/400/400"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Text("Legend ${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text("CENT MUSIC PRO", style: TextStyle(color: gold, fontSize: 10, letterSpacing: 1)),
          const SizedBox(height: 15),
        ],
      ),
    );
  }

  Widget _buildRecentGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 2.8),
      itemCount: 4,
      itemBuilder: (context, index) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(2, 2))],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network("https://picsum.photos/100", width: 50, height: 50, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text("Track Echo", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartCategories() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildCategoryCircle(Icons.favorite_rounded, "Liked"),
        _buildCategoryCircle(Icons.playlist_play_rounded, "Playlists"),
        _buildCategoryCircle(Icons.bolt_rounded, "Energy"),
        _buildCategoryCircle(Icons.folder_special_rounded, "Vault"),
      ],
    );
  }

  Widget _buildCategoryCircle(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 65, height: 65,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bgBlack,
            border: Border.all(color: gold.withOpacity(0.4)),
            boxShadow: [
              BoxShadow(color: gold.withOpacity(0.1), blurRadius: 10, spreadRadius: 1),
              BoxShadow(color: Colors.white.withOpacity(0.05), offset: const Offset(-3, -3), blurRadius: 5),
            ],
          ),
          child: Icon(icon, color: gold, size: 28),
        ),
        const SizedBox(height: 10),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildGlassPlayer() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 75,
        margin: const EdgeInsets.only(bottom: 110, left: 15, right: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: gold.withOpacity(0.3), width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              color: Colors.black.withOpacity(0.6),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  const CircleAvatar(radius: 25, backgroundImage: NetworkImage("https://picsum.photos/200")),
                  const SizedBox(width: 15),
                  const Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Vibrant Resonance", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text("Spatial Audio • HQ", style: TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                  ),
                  _build3DButton(Icons.skip_previous_rounded, 18),
                  const SizedBox(width: 5),
                  Icon(Icons.play_circle_filled_rounded, color: gold, size: 48),
                  const SizedBox(width: 5),
                  _build3DButton(Icons.skip_next_rounded, 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _build3DButton(IconData icon, double size) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgBlack,
        boxShadow: [
          BoxShadow(color: Colors.white.withOpacity(0.1), offset: const Offset(-2, -2), blurRadius: 4),
          BoxShadow(color: Colors.black, offset: const Offset(2, 2), blurRadius: 4),
        ],
      ),
      child: Icon(icon, color: gold, size: size),
    );
  }

  Widget _buildEliteNav() {
    return Container(
      height: 95,
      decoration: BoxDecoration(
        color: bgBlack,
        border: Border(top: BorderSide(color: gold.withOpacity(0.15), width: 0.5)),
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: gold,
        unselectedItemColor: Colors.grey.shade700,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded, size: 28), label: "Studio"),
          BottomNavigationBarItem(icon: Icon(Icons.explore_outlined, size: 28), label: "Discover"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_outline_rounded, size: 28), label: "Library"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded, size: 28), label: "Profile"),
        ],
      ),
    );
  }
}
