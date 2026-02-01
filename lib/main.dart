import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:just_audio/just_audio.dart';
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
        useMaterial3: true,
        fontFamily: 'sans-serif',
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
  bool _isLoading = false;
  Video? _currentVideo;
  final List<Video> _favorites = [];
  List<Video> _searchResults = [];
  final TextEditingController _searchController = TextEditingController();
  
  final Color gold = const Color(0xFFD4AF37);

  @override
  void initState() {
    super.initState();
    _player.playerStateStream.listen((state) {
      if (mounted) setState(() => _isPlaying = state.playing);
    });
  }

  Future<void> _searchSongs(String query) async {
    if (query.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      var search = await _yt.search.search(query);
      setState(() {
        _searchResults = search.toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _playVideo(Video video) async {
    setState(() {
      _isLoading = true;
      _currentVideo = video;
    });

    try {
      var manifest = await _yt.videos.streamsClient.getManifest(video.id);
      var streamInfo = manifest.audioOnly.withHighestBitrate();
      await _player.setAudioSource(AudioSource.uri(Uri.parse(streamInfo.url.toString())));
      _player.play();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _toggleFavorite(Video video) {
    setState(() {
      if (_favorites.contains(video)) {
        _favorites.remove(video);
      } else {
        _favorites.add(video);
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    _yt.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.black, gold.withOpacity(0.05), Colors.black],
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              child: CustomScrollView(
                slivers: [
                  _buildSliverAppBar(),
                  _buildSearchBox(),
                  _buildSectionTitle("Quick Picks"),
                  _buildResultsGrid(),
                  if (_favorites.isNotEmpty) _buildSectionTitle("Your Favorites"),
                  if (_favorites.isNotEmpty) _buildFavoritesList(),
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
            ),
            if (_currentVideo != null) _buildGlassMiniPlayer(),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text("CENT ELITE", style: TextStyle(color: gold, fontWeight: FontWeight.w900, letterSpacing: 3)),
      actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.history_rounded))],
    );
  }

  Widget _buildSearchBox() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: gold.withOpacity(0.2)),
              ),
              child: TextField(
                controller: _searchController,
                onSubmitted: _searchSongs,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search, color: gold),
                  hintText: "Search artist, song, podcast...",
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(15),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildResultsGrid() {
    if (_isLoading) {
      return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))));
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final video = _searchResults[index];
            return GestureDetector(
              onTap: () => _playVideo(video),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                        child: Image.network(video.thumbnails.highResUrl, fit: BoxFit.cover, width: double.infinity),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(video.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          },
          childCount: _searchResults.length,
        ),
      ),
    );
  }

  Widget _buildFavoritesList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final video = _favorites[index];
          return ListTile(
            leading: ClipRRect(borderRadius: BorderRadius.circular(5), child: Image.network(video.thumbnails.lowResUrl)),
            title: Text(video.title, maxLines: 1),
            subtitle: Text(video.author, style: TextStyle(color: gold, fontSize: 11)),
            trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _toggleFavorite(video)),
            onTap: () => _playVideo(video),
          );
        },
        childCount: _favorites.length,
      ),
    );
  }

  Widget _buildGlassMiniPlayer() {
    return Positioned(
      bottom: 10, left: 10, right: 10,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            height: 70,
            color: Colors.black.withOpacity(0.7),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _showFullPlayer,
                  child: Row(
                    children: [
                      Hero(tag: 'thumb', child: CircleAvatar(backgroundImage: NetworkImage(_currentVideo!.thumbnails.lowResUrl))),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.4,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_currentVideo!.title, maxLines: 1, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            Text(_currentVideo!.author, style: TextStyle(color: gold, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(icon: Icon(_favorites.contains(_currentVideo) ? Icons.favorite : Icons.favorite_border, color: gold), onPressed: () => _toggleFavorite(_currentVideo!)),
                IconButton(
                  icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 35, color: Colors.white),
                  onPressed: () => _isPlaying ? _player.pause() : _player.play(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFullPlayer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FullPlayerUI(
        player: _player,
        video: _currentVideo!,
        gold: gold,
      ),
    );
  }
}

class _FullPlayerUI extends StatelessWidget {
  final AudioPlayer player;
  final Video video;
  final Color gold;

  const _FullPlayerUI({required this.player, required this.video, required this.gold});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.94,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 60),
            Hero(
              tag: 'thumb',
              child: Container(
                width: 320, height: 320,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: gold.withOpacity(0.3), blurRadius: 50)],
                  image: DecorationImage(image: NetworkImage(video.thumbnails.highResUrl), fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(video.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(video.author, style: TextStyle(color: gold, fontSize: 18)),
                ],
              ),
            ),
            const Spacer(),
            _buildSlider(),
            const SizedBox(height: 20),
            _buildMainControls(),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider() {
    return StreamBuilder<Duration>(
      stream: player.positionStream,
      builder: (context, snapshot) {
        final pos = snapshot.data ?? Duration.zero;
        final dur = player.duration ?? Duration.zero;
        return Column(
          children: [
            Slider(
              activeColor: gold,
              inactiveColor: Colors.white10,
              value: pos.inSeconds.toDouble(),
              max: dur.inSeconds.toDouble() > 0 ? dur.inSeconds.toDouble() : 1.0,
              onChanged: (v) => player.seek(Duration(seconds: v.toInt())),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(pos), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  Text(_formatDuration(dur), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMainControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        const Icon(Icons.shuffle, color: Colors.white54),
        const Icon(Icons.skip_previous_rounded, size: 50),
        StreamBuilder<PlayerState>(
          stream: player.playerStateStream,
          builder: (context, snapshot) {
            final playing = snapshot.data?.playing ?? false;
            return IconButton(
              icon: Icon(playing ? Icons.pause_circle_filled : Icons.play_circle_filled, size: 90, color: gold),
              onPressed: () => playing ? player.pause() : player.play(),
            );
          },
        ),
        const Icon(Icons.skip_next_rounded, size: 50),
        const Icon(Icons.repeat, color: Colors.white54),
      ],
    );
  }

  String _formatDuration(Duration d) {
    return "${d.inMinutes.remainder(60)}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}";
  }
}
