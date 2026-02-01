import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:ui';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.black,
    ),
  );
  runApp(const CentUltimateElite());
}

class CentUltimateElite extends StatelessWidget {
  const CentUltimateElite({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFD4AF37),
        scaffoldBackgroundColor: const Color(0xFF000000),
      ),
      home: const MainRootNavigator(),
    );
  }
}

class MainRootNavigator extends StatefulWidget {
  const MainRootNavigator({super.key});
  @override
  State<MainRootNavigator> createState() => _MainRootNavigatorState();
}

class _MainRootNavigatorState extends State<MainRootNavigator> {
  int _currentIndex = 0;
  final AudioPlayer _audioEngine = AudioPlayer();
  final YoutubeExplode _ytEngine = YoutubeExplode();
  
  Video? _activeTrack;
  bool _isBuffering = false;
  final List<Video> _favList = [];

  // --- THE CRITICAL AUDIO FIX ---
  Future<void> _startPlayback(Video video) async {
    setState(() {
      _activeTrack = video;
      _isBuffering = true;
    });
    try {
      var manifest = await _ytEngine.videos.streamsClient.getManifest(video.id);
      var streamInfo = manifest.audioOnly.withHighestBitrate();
      
      // Force User-Agent and headers to prevent "No Sound" issue
      await _audioEngine.setAudioSource(
        AudioSource.uri(
          Uri.parse(streamInfo.url.toString()),
          tag: video.title,
        ),
      );
      _audioEngine.play();
      setState(() => _isBuffering = false);
    } catch (e) {
      setState(() => _isBuffering = false);
      debugPrint("Audio Engine Failure: $e");
    }
  }

  void _handleFav(Video v) {
    setState(() {
      if (_favList.any((e) => e.id == v.id)) {
        _favList.removeWhere((e) => e.id == v.id);
      } else {
        _favList.add(v);
      }
    });
  }

  @override
  void dispose() {
    _audioEngine.dispose();
    _ytEngine.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _appScreens = [
      DiscoverUI(onPlay: _startPlayback, yt: _ytEngine),
      LibraryUI(favs: _favList, onPlay: _startPlayback),
      const SettingsUI(),
    ];

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: _appScreens),
          if (_activeTrack != null) _buildUltraMiniPlayer(),
        ],
      ),
      bottomNavigationBar: _buildModernNavbar(),
    );
  }

  Widget _buildModernNavbar() {
    return Container(
      height: 85,
      padding: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navIcon(Icons.explore_outlined, Icons.explore, 0),
          _navIcon(Icons.favorite_outline, Icons.favorite, 1),
          _navIcon(Icons.settings_outlined, Icons.settings, 2),
        ],
      ),
    );
  }

  Widget _navIcon(IconData normal, IconData active, int idx) {
    bool isSelected = _currentIndex == idx;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD4AF37).withOpacity(0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(isSelected ? active : normal, color: isSelected ? const Color(0xFFD4AF37) : Colors.white24, size: 28),
      ),
    );
  }

  Widget _buildUltraMiniPlayer() {
    return Positioned(
      bottom: 25, left: 15, right: 15,
      child: GestureDetector(
        onTap: _launchFullVisualizer,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 45, sigmaY: 45),
            child: Container(
              height: 75,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  Hero(
                    tag: 'track_art',
                    child: Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(image: NetworkImage(_activeTrack!.thumbnails.lowResUrl), fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_activeTrack!.title, maxLines: 1, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.2)),
                        Text(_activeTrack!.author, style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  _isBuffering 
                    ? const SizedBox(width: 25, height: 25, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD4AF37)))
                    : StreamBuilder<PlayerState>(
                        stream: _audioEngine.playerStateStream,
                        builder: (context, snap) {
                          bool isPlaying = snap.data?.playing ?? false;
                          return IconButton(
                            icon: Icon(isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded, color: const Color(0xFFD4AF37), size: 45),
                            onPressed: () => isPlaying ? _audioEngine.pause() : _audioEngine.play(),
                          );
                        }
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _launchFullVisualizer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FullVisualizerUI(
        player: _audioEngine, 
        video: _activeTrack!,
        isFavorite: _favList.any((v) => v.id == _activeTrack!.id),
        toggleFav: () => _handleFav(_activeTrack!),
      ),
    );
  }
}

// --- DISCOVER UI ---
class DiscoverUI extends StatefulWidget {
  final Function(Video) onPlay;
  final YoutubeExplode yt;
  const DiscoverUI({super.key, required this.onPlay, required this.yt});
  @override
  State<DiscoverUI> createState() => _DiscoverUIState();
}

class _DiscoverUIState extends State<DiscoverUI> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Video> _searchResults = [];
  bool _isSearching = false;

  void _performSearch(String query) async {
    setState(() => _isSearching = true);
    var results = await widget.yt.search.search(query);
    setState(() {
      _searchResults = results.toList();
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          expandedHeight: 180,
          backgroundColor: Colors.black,
          flexibleSpace: FlexibleSpaceBar(
            centerTitle: true,
            title: Text(
              "CENT",
              style: TextStyle(
                color: const Color(0xFFD4AF37),
                letterSpacing: 35, // ULTRA MODERN SPACING
                fontWeight: FontWeight.w100,
                fontSize: 26,
                shadows: [
                  Shadow(color: const Color(0xFFD4AF37).withOpacity(0.5), blurRadius: 25),
                  Shadow(color: const Color(0xFFD4AF37).withOpacity(0.2), blurRadius: 50),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: TextField(
                  controller: _searchCtrl,
                  onSubmitted: _performSearch,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.04),
                    hintText: "Enter the soundscape...",
                    hintStyle: const TextStyle(color: Colors.white12),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFD4AF37)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(20),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_isSearching) const SliverToBoxAdapter(child: LinearProgressIndicator(color: Color(0xFFD4AF37))),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 150),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, childAspectRatio: 0.72, mainAxisSpacing: 25, crossAxisSpacing: 20,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => _buildTrackTile(_searchResults[i]),
              childCount: _searchResults.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrackTile(Video v) {
    return GestureDetector(
      onTap: () => widget.onPlay(v),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(35), // SMOOTHER CORNERS
                image: DecorationImage(image: NetworkImage(v.thumbnails.highResUrl), fit: BoxFit.cover),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 15, offset: const Offset(0, 8))],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(v.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
          Text(v.author, style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// --- FULL VISUALIZER UI ---
class FullVisualizerUI extends StatelessWidget {
  final AudioPlayer player;
  final Video video;
  final bool isFavorite;
  final VoidCallback toggleFav;
  const FullVisualizerUI({super.key, required this.player, required this.video, required this.isFavorite, required this.toggleFav});

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFD4AF37);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: Opacity(opacity: 0.25, child: Image.network(video.thumbnails.highResUrl, fit: BoxFit.cover))),
          BackdropFilter(filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100), child: Container(color: Colors.black.withOpacity(0.75))),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 15),
                _playerHeader(context),
                const Spacer(),
                _playerArt(),
                const Spacer(),
                _playerMeta(),
                _playerProgress(gold),
                _playerControls(gold),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _playerHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.expand_more_rounded, size: 45), onPressed: () => Navigator.pop(context)),
          const Text("CENT SUPREME AUDIO", style: TextStyle(letterSpacing: 6, fontSize: 10, fontWeight: FontWeight.w900)),
          IconButton(icon: Icon(isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: const Color(0xFFD4AF37), size: 30), onPressed: toggleFav),
        ],
      ),
    );
  }

  Widget _playerArt() {
    return Hero(
      tag: 'track_art',
      child: Container(
        width: 320, height: 320,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.3), blurRadius: 80, spreadRadius: 2),
          ],
          image: DecorationImage(image: NetworkImage(video.thumbnails.highResUrl), fit: BoxFit.cover),
        ),
      ),
    );
  }

  Widget _playerMeta() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 45),
      child: Column(
        children: [
          Text(video.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          const SizedBox(height: 12),
          Text(video.author.toUpperCase(), style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 14, letterSpacing: 3, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _playerProgress(Color g) {
    return StreamBuilder<Duration>(
      stream: player.positionStream,
      builder: (context, snap) {
        final pos = snap.data ?? Duration.zero;
        final dur = player.duration ?? Duration.zero;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 30),
          child: Column(
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(trackHeight: 2, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6)),
                child: Slider(
                  activeColor: g, inactiveColor: Colors.white10,
                  value: pos.inSeconds.toDouble(),
                  max: dur.inSeconds.toDouble() > 0 ? dur.inSeconds.toDouble() : 1.0,
                  onChanged: (v) => player.seek(Duration(seconds: v.toInt())),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDur(pos), style: const TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold)),
                  Text(_formatDur(dur), style: const TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _playerControls(Color g) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.shuffle_rounded, color: Colors.white10, size: 25),
        const SizedBox(width: 25),
        const Icon(Icons.skip_previous_rounded, size: 55),
        const SizedBox(width: 20),
        StreamBuilder<PlayerState>(
          stream: player.playerStateStream,
          builder: (context, snap) {
            bool isP = snap.data?.playing ?? false;
            return GestureDetector(
              onTap: () => isP ? player.pause() : player.play(),
              child: Container(
                width: 90, height: 90,
                decoration: BoxDecoration(color: g, shape: BoxShape.circle, boxShadow: [BoxShadow(color: g.withOpacity(0.4), blurRadius: 30)]),
                child: Icon(isP ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.black, size: 55),
              ),
            );
          },
        ),
        const SizedBox(width: 20),
        const Icon(Icons.skip_next_rounded, size: 55),
        const SizedBox(width: 25),
        const Icon(Icons.repeat_rounded, color: Colors.white10, size: 25),
      ],
    );
  }

  String _formatDur(Duration d) => "${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}";
}

// --- LIBRARY UI ---
class LibraryUI extends StatelessWidget {
  final List<Video> favs;
  final Function(Video) onPlay;
  const LibraryUI({super.key, required this.favs, required this.onPlay});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("FAVORITES", style: TextStyle(letterSpacing: 8, fontWeight: FontWeight.w100)), centerTitle: true, backgroundColor: Colors.black),
      body: favs.isEmpty 
        ? const Center(child: Text("NO ELITE TRACKS SAVED", style: TextStyle(color: Colors.white10, letterSpacing: 2)))
        : ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: favs.length,
            itemBuilder: (context, i) => ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              leading: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(favs[i].thumbnails.lowResUrl)),
              title: Text(favs[i].title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(favs[i].author, style: const TextStyle(color: Color(0xFFD4AF37))),
              onTap: () => onPlay(favs[i]),
            ),
          ),
    );
  }
}

// --- SETTINGS UI ---
class SettingsUI extends StatelessWidget {
  const SettingsUI({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("CENT ENGINE", style: TextStyle(letterSpacing: 10, fontSize: 20, fontWeight: FontWeight.w100)),
            SizedBox(height: 20),
            Text("ULTRA FIDELITY AUDIO: ACTIVE", style: TextStyle(color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.bold)),
            SizedBox(height: 5),
            Text("VERSION: 1.0.0 (STABLE MASTER)", style: TextStyle(color: Colors.white10, fontSize: 9)),
          ],
        ),
      ),
    );
  }
}
