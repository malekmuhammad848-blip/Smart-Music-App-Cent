import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:ui';
import 'dart:async';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.black,
    ),
  );
  runApp(const CentSupremeApp());
}

class CentSupremeApp extends StatelessWidget {
  const CentSupremeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CENT SUPREME',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFD4AF37),
        scaffoldBackgroundColor: const Color(0xFF000000),
        fontFamily: 'Roboto',
      ),
      home: const ApplicationCoreEngine(),
    );
  }
}

class ApplicationCoreEngine extends StatefulWidget {
  const ApplicationCoreEngine({super.key});

  @override
  State<ApplicationCoreEngine> createState() => _ApplicationCoreEngineState();
}

class _ApplicationCoreEngineState extends State<ApplicationCoreEngine> with TickerProviderStateMixin {
  int _activeGalaxyIndex = 0;
  final AudioPlayer _audioEngine = AudioPlayer();
  final YoutubeExplode _ytEngine = YoutubeExplode();
  
  Video? _activeTrack;
  bool _isProcessing = false;
  
  final List<Video> _vaultCollection = [];
  final List<Video> _neuralHistory = [];

  Future<void> _initiateHyperStream(Video video) async {
    if (_activeTrack?.id == video.id && _audioEngine.playing) return;
    
    setState(() {
      _activeTrack = video;
      _isProcessing = true;
      if (!_neuralHistory.any((element) => element.id == video.id)) {
        _neuralHistory.insert(0, video);
      }
    });

    try {
      var manifest = await _ytEngine.videos.streamsClient.getManifest(video.id);
      var streamInfo = manifest.audioOnly.withHighestBitrate();
      
      await _audioEngine.setAudioSource(
        AudioSource.uri(Uri.parse(streamInfo.url.toString())),
      );
      _audioEngine.play();
      
      setState(() => _isProcessing = false);
    } catch (e) {
      setState(() => _isProcessing = false);
    }
  }

  void _manageVaultStatus(Video v) {
    setState(() {
      if (_vaultCollection.any((element) => element.id == v.id)) {
        _vaultCollection.removeWhere((element) => element.id == v.id);
      } else {
        _vaultCollection.add(v);
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
    final List<Widget> _galaxyLayers = [
      DiscoveryGalaxy(onPlay: _initiateHyperStream, yt: _ytEngine),
      VaultGalaxy(vault: _vaultCollection, history: _neuralHistory, onPlay: _initiateHyperStream),
      const CoreEngineGalaxy(),
    ];

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: _activeGalaxyIndex, children: _galaxyLayers),
          if (_activeTrack != null) _buildSupremeFloatingDeck(),
        ],
      ),
      bottomNavigationBar: _buildImperialNavigation(),
    );
  }

  Widget _buildImperialNavigation() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.blur_on_rounded, "CENT", 0),
          _buildNavItem(Icons.token_rounded, "VAULT", 1),
          _buildNavItem(Icons.router_rounded, "ENGINE", 2),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _activeGalaxyIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _activeGalaxyIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? const Color(0xFFD4AF37) : Colors.white24, size: 30),
          const SizedBox(height: 5),
          Text(label, style: TextStyle(color: isSelected ? const Color(0xFFD4AF37) : Colors.white24, fontSize: 8, letterSpacing: 2, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSupremeFloatingDeck() {
    return Positioned(
      bottom: 25, left: 15, right: 15,
      child: GestureDetector(
        onTap: _openAtmosphericVisualizer,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _isProcessing 
                    ? const CircularProgressIndicator(color: Color(0xFFD4AF37), strokeWidth: 2)
                    : CircleAvatar(backgroundImage: NetworkImage(_activeTrack!.thumbnails.mediumResUrl), radius: 28),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_activeTrack!.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                        const Text("CENT SUPREME SIGNAL", style: TextStyle(color: Color(0xFFD4AF37), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 2.5)),
                      ],
                    ),
                  ),
                  StreamBuilder<PlayerState>(
                    stream: _audioEngine.playerStateStream,
                    builder: (context, snap) {
                      bool isPlaying = snap.data?.playing ?? false;
                      return IconButton(
                        icon: Icon(isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded, color: const Color(0xFFD4AF37), size: 52),
                        onPressed: () => isPlaying ? _audioEngine.pause() : _audioEngine.play(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openAtmosphericVisualizer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AtmosphericVisualizer(
        player: _audioEngine, 
        video: _activeTrack!,
        isVaulted: _vaultCollection.any((v) => v.id == _activeTrack!.id),
        onVaultToggle: () {
          _manageVaultStatus(_activeTrack!);
          Navigator.pop(context);
          _openAtmosphericVisualizer();
        },
      ),
    );
  }
}

class DiscoveryGalaxy extends StatefulWidget {
  final Function(Video) onPlay;
  final YoutubeExplode yt;
  const DiscoveryGalaxy({super.key, required this.onPlay, required this.yt});

  @override
  State<DiscoveryGalaxy> createState() => _DiscoveryGalaxyState();
}

class _DiscoveryGalaxyState extends State<DiscoveryGalaxy> {
  final TextEditingController _searchController = TextEditingController();
  List<Video> _searchresults = [];
  bool _isSearching = false;

  void _performSearch(String query) async {
    setState(() => _isSearching = true);
    try {
      var search = await widget.yt.search.search(query);
      setState(() {
        _searchresults = search.toList();
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          expandedHeight: 280,
          backgroundColor: Colors.black,
          flexibleSpace: FlexibleSpaceBar(
            centerTitle: true,
            title: Text(
              "CENT",
              style: TextStyle(
                color: const Color(0xFFD4AF37),
                letterSpacing: 45,
                fontWeight: FontWeight.w100,
                fontSize: 40,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
            child: TextField(
              controller: _searchController,
              onSubmitted: _performSearch,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                hintText: "SEARCH...",
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFD4AF37)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(25),
              ),
            ),
          ),
        ),
        if (_isSearching) const SliverToBoxAdapter(child: LinearProgressIndicator(color: Color(0xFFD4AF37))),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(25, 0, 25, 200),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, childAspectRatio: 0.65, mainAxisSpacing: 35, crossAxisSpacing: 25,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => _buildGalaxyCard(_searchresults[i]),
              childCount: _searchresults.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGalaxyCard(Video v) {
    return GestureDetector(
      onTap: () => widget.onPlay(v),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(45),
                image: DecorationImage(image: NetworkImage(v.thumbnails.highResUrl), fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(height: 15),
          Text(v.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
          Text(v.author, style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class AtmosphericVisualizer extends StatelessWidget {
  final AudioPlayer player;
  final Video video;
  final bool isVaulted;
  final VoidCallback onVaultToggle;
  const AtmosphericVisualizer({super.key, required this.player, required this.video, required this.isVaulted, required this.onVaultToggle});

  @override
  Widget build(BuildContext context) {
    const Color royalGold = Color(0xFFD4AF37);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: Opacity(opacity: 0.3, child: Image.network(video.thumbnails.highResUrl, fit: BoxFit.cover))),
          BackdropFilter(filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100), child: Container(color: Colors.black.withOpacity(0.85))),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(icon: const Icon(Icons.expand_more_rounded, size: 45), onPressed: () => Navigator.pop(context)),
                      IconButton(icon: Icon(isVaulted ? Icons.favorite : Icons.favorite_border, color: royalGold, size: 32), onPressed: onVaultToggle),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  width: 300, height: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(60),
                    image: DecorationImage(image: NetworkImage(video.thumbnails.highResUrl), fit: BoxFit.cover),
                  ),
                ),
                const Spacer(),
                Text(video.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                Text(video.author.toUpperCase(), style: const TextStyle(color: royalGold, letterSpacing: 6, fontSize: 14, fontWeight: FontWeight.bold)),
                const Spacer(),
                _buildSeekSystem(player, royalGold),
                _buildTransportControls(player, royalGold),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeekSystem(AudioPlayer p, Color g) {
    return StreamBuilder<Duration>(
      stream: p.positionStream,
      builder: (context, snap) {
        final pos = snap.data ?? Duration.zero;
        final dur = p.duration ?? Duration.zero;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Slider(
            activeColor: g,
            value: pos.inSeconds.toDouble(),
            max: dur.inSeconds.toDouble() > 0 ? dur.inSeconds.toDouble() : 1.0,
            onChanged: (v) => p.seek(Duration(seconds: v.toInt())),
          ),
        );
      },
    );
  }

  Widget _buildTransportControls(AudioPlayer p, Color g) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.skip_previous_rounded, size: 60),
        const SizedBox(width: 25),
        StreamBuilder<PlayerState>(
          stream: p.playerStateStream,
          builder: (context, snap) {
            bool isPlaying = snap.data?.playing ?? false;
            return GestureDetector(
              onTap: () => isPlaying ? p.pause() : p.play(),
              child: Container(
                width: 90, height: 90,
                decoration: BoxDecoration(color: g, shape: BoxShape.circle),
                child: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.black, size: 60),
              ),
            );
          },
        ),
        const SizedBox(width: 25),
        const Icon(Icons.skip_next_rounded, size: 60),
      ],
    );
  }
}

class VaultGalaxy extends StatelessWidget {
  final List<Video> vault;
  final List<Video> history;
  final Function(Video) onPlay;
  const VaultGalaxy({super.key, required this.vault, required this.history, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        children: [
          const SizedBox(height: 80),
          const Text("ARCHIVE", style: TextStyle(letterSpacing: 10, fontSize: 30, fontWeight: FontWeight.w100)),
          const SizedBox(height: 40),
          _buildSection("FAVORITES", vault),
          const SizedBox(height: 40),
          _buildSection("HISTORY", history),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Video> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 2)),
        const SizedBox(height: 15),
        if (items.isEmpty) const Text("NO DATA", style: TextStyle(color: Colors.white10, fontSize: 10)),
        ...items.map((v) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(v.thumbnails.lowResUrl)),
          title: Text(v.title, maxLines: 1, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          onTap: () => onPlay(v),
        )),
      ],
    );
  }
}

class CoreEngineGalaxy extends StatelessWidget {
  const CoreEngineGalaxy({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fingerprint_rounded, color: Color(0xFFD4AF37), size: 100),
            SizedBox(height: 30),
            Text("CENT SUPREME ENGINE", style: TextStyle(letterSpacing: 15, fontSize: 18, fontWeight: FontWeight.w100)),
            Text("STATUS: GLOBAL ACTIVE", style: TextStyle(color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
