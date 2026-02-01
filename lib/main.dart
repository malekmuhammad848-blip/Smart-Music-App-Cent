import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:just_audio/just_audio.dart';

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
  final AudioPlayer _player = AudioPlayer();
  final YoutubeExplode _yt = YoutubeExplode();
  bool _isPlaying = false;
  String _currentTitle = "Select a Song";
  String _currentThumbnail = "https://picsum.photos/200";
  final Color gold = const Color(0xFFD4AF37);
  
  List<Video> _searchResults = [];
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  Future<void> _searchSongs(String query) async {
    if (query.isEmpty) return;
    setState(() => _isSearching = true);
    try {
      var search = await _yt.search.search(query);
      setState(() {
        _searchResults = search.toList();
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _playVideo(String videoId, String title, String thumb) async {
    setState(() {
      _currentTitle = "Buffering...";
      _currentThumbnail = thumb;
      _isPlaying = false;
    });

    try {
      var manifest = await _yt.videos.streamsClient.getManifest(videoId);
      var audioStream = manifest.audioOnly.withHighestBitrate();
      await _player.setUrl(audioStream.url.toString());
      _player.play();
      setState(() {
        _currentTitle = title;
        _isPlaying = true;
      });
    } catch (e) {
      setState(() => _currentTitle = "Playback Error");
    }
  }

  @override
  void dispose() {
    _player.dispose();
    _yt.close();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackgroundGradient(),
          SafeArea(
            child: Column(
              children: [
                _buildEliteSearchBar(),
                Expanded(
                  child: _searchResults.isEmpty 
                    ? _buildHomeContent() 
                    : _buildSearchResultsList(),
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

  Widget _buildBackgroundGradient() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.2,
            colors: [gold.withOpacity(0.07), Colors.transparent],
          ),
        ),
      ),
    );
  }

  Widget _buildEliteSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 55,
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: gold.withOpacity(0.3)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10)],
              ),
              child: TextField(
                controller: _searchController,
                onSubmitted: _searchSongs,
                decoration: InputDecoration(
                  hintText: "Search Golden Tracks...",
                  hintStyle: TextStyle(color: gold.withOpacity(0.5)),
                  prefixIcon: Icon(Icons.search, color: gold),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),
          if (_searchResults.isNotEmpty)
            IconButton(
              icon: Icon(Icons.close, color: gold),
              onPressed: () => setState(() {
                _searchResults.clear();
                _searchController.clear();
              }),
            )
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                _buildSectionHeader("Top 10 Legendary", "Weekly Highlights"),
                _buildTopTenCarousel(),
                const SizedBox(height: 30),
                _buildSectionHeader("Smart Categories", "Premium Selection"),
                _buildSmartCategories(),
                const SizedBox(height: 150),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResultsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        var video = _searchResults[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(
            color: const Color(0xFF151515),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(video.thumbnails.lowResUrl, width: 60, height: 60, fit: BoxFit.cover),
            ),
            title: Text(video.title, maxLines: 1, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(video.author, style: TextStyle(color: gold, fontSize: 11)),
            trailing: Icon(Icons.play_circle_outline, color: gold),
            onTap: () => _playVideo(video.id.value, video.title, video.thumbnails.highResUrl),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(subtitle.toUpperCase(), style: TextStyle(color: gold.withOpacity(0.5), fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _buildTopTenCarousel() {
    return Container(
      height: 220,
      margin: const EdgeInsets.only(top: 15),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        itemBuilder: (context, index) => _buildEliteCard("Legendary ${index + 1}"),
      ),
    );
  }

  Widget _buildEliteCard(String title) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: const Color(0xFF121212),
        border: Border.all(color: gold.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: const DecorationImage(image: NetworkImage("https://picsum.photos/300"), fit: BoxFit.cover),
              ),
            ),
          ),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildSmartCategories() {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      childAspectRatio: 2.5,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildCategoryBox(Icons.favorite, "Favorites"),
        _buildCategoryBox(Icons.history, "History"),
        _buildCategoryBox(Icons.trending_up, "Trending"),
        _buildCategoryBox(Icons.download_done, "Vault"),
      ],
    );
  }

  Widget _buildCategoryBox(IconData icon, String label) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: gold.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: gold, size: 20),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildGlassPlayer() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 80,
        margin: const EdgeInsets.only(bottom: 110, left: 15, right: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: gold.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 20)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              color: Colors.black.withOpacity(0.7),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  CircleAvatar(radius: 25, backgroundImage: NetworkImage(_currentThumbnail)),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_currentTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
                        Text("CENT High Fidelity", style: TextStyle(color: gold, fontSize: 10)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      if (_player.playing) {
                        _player.pause();
                        setState(() => _isPlaying = false);
                      } else {
                        _player.play();
                        setState(() => _isPlaying = true);
                      }
                    },
                    child: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, color: gold, size: 45),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEliteNav() {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: const Color(0xFF050505),
        border: Border(top: BorderSide(color: gold.withOpacity(0.15))),
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: gold,
        unselectedItemColor: Colors.grey.shade700,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: "Discover"),
          BottomNavigationBarItem(icon: Icon(Icons.library_music), label: "Library"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
  }
}
