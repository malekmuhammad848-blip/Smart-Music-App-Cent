import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:ui';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.black,
    ),
  );
  runApp(const CentMusicElite());
}

class CentMusicElite extends StatelessWidget {
  const CentMusicElite({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFD4AF37),
        scaffoldBackgroundColor: const Color(0xFF000000),
        fontFamily: 'Georgia',
      ),
      home: const RootScreen(),
    );
  }
}

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _currentIndex = 0;
  final AudioPlayer _player = AudioPlayer();
  final YoutubeExplode _yt = YoutubeExplode();
  
  Video? _currentVideo;
  bool _isLoading = false;
  final List<Video> _favorites = [];

  final PageStorageBucket _bucket = PageStorageBucket();

  void _play(Video video) async {
    setState(() {
      _currentVideo = video;
      _isLoading = true;
    });
    try {
      var manifest = await _yt.videos.streamsClient.getManifest(video.id);
      var stream = manifest.audioOnly.withHighestBitrate();
      await _player.setAudioSource(AudioSource.uri(Uri.parse(stream.url.toString())));
      _player.play();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    _yt.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      MusicHomePage(key: const PageStorageKey('home'), onPlay: _play, yt: _yt),
      LibraryPage(key: const PageStorageKey('library'), favorites: _favorites, onPlay: _play),
      const SettingsPage(key: PageStorageKey('settings')),
    ];

    return Scaffold(
      body: Stack(
        children: [
          PageStorage(
            bucket: _bucket,
            child: IndexedStack(index: _currentIndex, children: _pages),
          ),
          if (_currentVideo != null) _buildAdvancedMiniPlayer(),
        ],
      ),
      bottomNavigationBar: _buildNavbar(),
    );
  }

  Widget _buildNavbar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        backgroundColor: Colors.black,
        selectedItemColor: const Color(0xFFD4AF37),
        unselectedItemColor: Colors.white24,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore_rounded), label: "CENT"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_rounded), label: "FAVORITES"),
          BottomNavigationBarItem(icon: Icon(Icons.tune_rounded), label: "ENGINE"),
        ],
      ),
    );
  }

  Widget _buildAdvancedMiniPlayer() {
    return Positioned(
      bottom: 15, left: 10, right: 10,
      child: GestureDetector(
        onTap: _showFullPlayer,
        child: Hero(
          tag: 'art_${_currentVideo!.id}',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                height: 75,
                color: Colors.white.withOpacity(0.08),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    CircleAvatar(backgroundImage: NetworkImage(_currentVideo!.thumbnails.lowResUrl), radius: 25),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_currentVideo!.title, maxLines: 1, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(_currentVideo!.author, style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 11)),
                        ],
                      ),
                    ),
                    _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD4AF37)))
                      : StreamBuilder<PlayerState>(
                          stream: _player.playerStateStream,
                          builder: (context, snap) {
                            final isP = snap.data?.playing ?? false;
                            return IconButton(
                              icon: Icon(isP ? Icons.pause_circle_filled : Icons.play_circle_filled, color: const Color(0xFFD4AF37), size: 40),
                              onPressed: () => isP ? _player.pause() : _player.play(),
                            );
                          },
                        ),
                  ],
                ),
              ),
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
      builder: (context) => FullPlayerUI(
        player: _player, 
        video: _currentVideo!, 
        onFav: () => setState(() {
          if(!_favorites.contains(_currentVideo)) _favorites.add(_currentVideo!);
        })
      ),
    );
  }
}

class MusicHomePage extends StatefulWidget {
  final Function(Video) onPlay;
  final YoutubeExplode yt;
  const MusicHomePage({super.key, required this.onPlay, required this.yt});

  @override
  State<MusicHomePage> createState() => _MusicHomePageState();
}

class _MusicHomePageState extends State<MusicHomePage> {
  final TextEditingController _ctrl = TextEditingController();
  List<Video> _list = [];
  bool _loading = false;

  void _search(String val) async {
    setState(() => _loading = true);
    var res = await widget.yt.search.search(val);
    setState(() {
      _list = res.toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          expandedHeight: 120,
          backgroundColor: Colors.black,
          flexibleSpace: FlexibleSpaceBar(
            centerTitle: true,
            title: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              decoration: BoxDecoration(border: Border.all(color: const Color(0xFFD4AF37), width: 1.5)),
              child: const Text("CENT", style: TextStyle(color: Color(0xFFD4AF37), letterSpacing: 12, fontWeight: FontWeight.w900, fontSize: 18)),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: TextField(
              controller: _ctrl,
              onSubmitted: _search,
              decoration: InputDecoration(
                hintText: "Search Elite Tracks...",
                prefixIcon: const Icon(Icons.search, color: Color(0xFFD4AF37)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
          ),
        ),
        if (_loading) const SliverToBoxAdapter(child: LinearProgressIndicator(color: Color(0xFFD4AF37))),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 15, mainAxisSpacing: 15,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => GestureDetector(
                onTap: () => widget.onPlay(_list[i]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(_list[i].thumbnails.highResUrl, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_list[i].title, maxLines: 1, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    Text(_list[i].author, style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 10)),
                  ],
                ),
              ),
              childCount: _list.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }
}

class FullPlayerUI extends StatelessWidget {
  final AudioPlayer player;
  final Video video;
  final VoidCallback onFav;
  const FullPlayerUI({super.key, required this.player, required this.video, required this.onFav});

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFD4AF37);
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
      child: Container(
        height: MediaQuery.of(context).size.height,
        color: Colors.black.withOpacity(0.9),
        child: Column(
          children: [
            const SizedBox(height: 60),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.keyboard_arrow_down, size: 40), onPressed: () => Navigator.pop(context)),
                const Text("CENT PREMIUM PLAYBACK", style: TextStyle(letterSpacing: 2, fontSize: 10)),
                IconButton(icon: const Icon(Icons.favorite_border, color: gold), onPressed: onFav),
              ],
            ),
            const Spacer(),
            Hero(
              tag: 'art_${video.id}',
              child: Container(
                width: 310, height: 310,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [BoxShadow(color: gold.withOpacity(0.2), blurRadius: 100)],
                  image: DecorationImage(image: NetworkImage(video.thumbnails.highResUrl), fit: BoxFit.cover),
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  Text(video.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(video.author, style: const TextStyle(color: gold, fontSize: 16)),
                ],
              ),
            ),
            const Spacer(),
            _buildSlider(player, gold),
            _buildControls(player, gold),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(AudioPlayer p, Color g) {
    return StreamBuilder<Duration>(
      stream: p.positionStream,
      builder: (context, snap) {
        final pos = snap.data ?? Duration.zero;
        final dur = p.duration ?? Duration.zero;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Slider(
            activeColor: g, inactiveColor: Colors.white10,
            value: pos.inSeconds.toDouble(),
            max: dur.inSeconds.toDouble() > 0 ? dur.inSeconds.toDouble() : 1.0,
            onChanged: (v) => p.seek(Duration(seconds: v.toInt())),
          ),
        );
      },
    );
  }

  Widget _buildControls(AudioPlayer p, Color g) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.skip_previous_rounded, size: 60),
        const SizedBox(width: 20),
        StreamBuilder<PlayerState>(
          stream: p.playerStateStream,
          builder: (context, snap) {
            final isP = snap.data?.playing ?? false;
            return IconButton(
              icon: Icon(isP ? Icons.pause_circle_filled : Icons.play_circle_filled, size: 90, color: g),
              onPressed: () => isP ? p.pause() : p.play(),
            );
          },
        ),
        const SizedBox(width: 20),
        const Icon(Icons.skip_next_rounded, size: 60),
      ],
    );
  }
}

class LibraryPage extends StatelessWidget {
  final List<Video> favorites;
  final Function(Video) onPlay;
  const LibraryPage({super.key, required this.favorites, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.black, title: const Text("LIBRARY", style: TextStyle(letterSpacing: 5))),
      body: favorites.isEmpty 
        ? const Center(child: Text("NO DATA IN ELITE LIBRARY", style: TextStyle(color: Colors.white24)))
        : ListView.builder(
            itemCount: favorites.length,
            itemBuilder: (context, i) => ListTile(
              leading: Image.network(favorites[i].thumbnails.lowResUrl),
              title: Text(favorites[i].title),
              subtitle: Text(favorites[i].author, style: const TextStyle(color: Color(0xFFD4AF37))),
              onTap: () => onPlay(favorites[i]),
            ),
          ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_user_rounded, color: Color(0xFFD4AF37), size: 80),
            const SizedBox(height: 20),
            const Text("CENT ELITE SYSTEM", style: TextStyle(letterSpacing: 5, fontWeight: FontWeight.bold)),
            const Text("VERSION 1.0.0 (MASTER)", style: TextStyle(color: Colors.white24, fontSize: 10)),
            const SizedBox(height: 40),
            Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(border: Border.all(color: Colors.white10)), child: const Text("HIGH FIDELITY AUDIO ENABLED")),
          ],
        ),
      ),
    );
  }
}
