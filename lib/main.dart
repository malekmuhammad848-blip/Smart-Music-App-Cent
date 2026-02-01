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
      statusBarIconTheme: Brightness.light,
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
        visualDensity: VisualDensity.adaptivePlatformDensity,
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
  int _currentGalaxyIndex = 0;
  final AudioPlayer _audioCore = AudioPlayer();
  final YoutubeExplode _ytCore = YoutubeExplode();
  
  Video? _activeTrack;
  bool _engineLoading = false;
  
  final List<Video> _vaultCollection = [];
  final List<Video> _neuralHistory = [];
  
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  Future<void> _initiateHyperStream(Video video) async {
    if (_activeTrack?.id == video.id && _audioCore.playing) return;
    
    setState(() {
      _activeTrack = video;
      _engineLoading = true;
      if (!_neuralHistory.any((element) => element.id == video.id)) {
        _neuralHistory.insert(0, video);
      }
    });

    try {
      var manifest = await _ytCore.videos.streamsClient.getManifest(video.id);
      var streamInfo = manifest.audioOnly.withHighestBitrate();
      
      await _audioCore.setAudioSource(
        AudioSource.uri(Uri.parse(streamInfo.url.toString())),
      );
      _audioCore.play();
      
      setState(() => _engineLoading = false);
    } catch (e) {
      setState(() => _engineLoading = false);
    }
  }

  void _toggleVaultStatus(Video v) {
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
    _audioCore.dispose();
    _ytCore.close();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _galaxyLayers = [
      DiscoveryGalaxy(onPlay: _initiateHyperStream, yt: _ytCore),
      VaultGalaxy(vault: _vaultCollection, history: _neuralHistory, onPlay: _initiateHyperStream),
      const CoreEngineGalaxy(),
    ];

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: _currentGalaxyIndex, children: _galaxyLayers),
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
          _buildNavItem(Icons.blur_on_rounded, "DISCOVER", 0),
          _buildNavItem(Icons.token_rounded, "VAULT", 1),
          _buildNavItem(Icons.router_rounded, "ENGINE", 2),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _currentGalaxyIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentGalaxyIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? const Color(0xFFD4AF37) : Colors.white24, size: 30),
            const SizedBox(height: 5),
            Text(label, style: TextStyle(color: isSelected ? const Color(0xFFD4AF37) : Colors.white24, fontSize: 8, letterSpacing: 2, fontWeight: FontWeight.bold)),
          ],
        ),
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
                  _engineLoading 
                    ? const CircularProgressIndicator(color: Color(0xFFD4AF37), strokeWidth: 2)
                    : Container(
                        width: 55, height: 55,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          image: DecorationImage(image: NetworkImage(_activeTrack!.thumbnails.mediumResUrl), fit: BoxFit.cover),
                        ),
                      ),
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
                    stream: _audioCore.playerStateStream,
                    builder: (context, snap) {
                      bool isPlaying = snap.data?.playing ?? false;
                      return IconButton(
                        icon: Icon(isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded, color: const Color(0xFFD4AF37), size: 52),
                        onPressed: () => isPlaying ? _audioCore.pause() : _audioCore.play(),
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
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "CENT_EXPAND",
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, anim1, anim2) => AtmosphericVisualizer(
        player: _audioCore, 
        video: _activeTrack!,
        isVaulted: _vaultCollection.any((v) => v.id == _activeTrack!.id),
        onVaultToggle: () => _toggleVaultStatus(_activeTrack!),
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
    var search = await widget.yt.search.search(query);
    setState(() {
      _searchresults = search.toList();
      _isSearching = false;
    });
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
                shadows: [Shadow(color: const Color(0xFFD4AF37).withOpacity(0.5), blurRadius: 40)],
              ),
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [const Color(0xFFD4AF37).withOpacity(0.15), Colors.transparent],
                  radius: 1,
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: TextField(
                  controller: _searchController,
                  onSubmitted: _performSearch,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    hintText: "SEARCH FREQUENCIES...",
                    hintStyle: const TextStyle(color: Colors.white12, letterSpacing: 3),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFD4AF37)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(25),
                  ),
                ),
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
                boxShadow: [BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.1), blurRadius: 30)],
                image: DecorationImage(image: NetworkImage(v.thumbnails.highResUrl), fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(height: 15),
          Text(v.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
          Text(v.author, style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
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
          BackdropFilter(filter: ImageFilter.blur(sigmaX: 120, sigmaY: 120), child: Container(color: Colors.black.withOpacity(0.85))),
          SafeArea(
            child: Column(
              children: [
                _buildVisualizerHeader(context),
                const Spacer(),
                _buildMainArtFrame(),
                const Spacer(),
                _buildTrackDetails(),
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

  Widget _buildVisualizerHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.expand_more_rounded, size: 45), onPressed: () => Navigator.pop(context)),
          const Column(
            children: [
              Text("CENT SUPREME", style: TextStyle(letterSpacing: 12, fontSize: 11, fontWeight: FontWeight.w900)),
              Text("LABS EDITION", style: TextStyle(color: Color(0xFFD4AF37), fontSize: 8, fontWeight: FontWeight.bold)),
            ],
          ),
          IconButton(icon: Icon(isVaulted ? Icons.token_rounded : Icons.token_outlined, color: const Color(0xFFD4AF37), size: 32), onPressed: onVaultToggle),
        ],
      ),
    );
  }

  Widget _buildMainArtFrame() {
    return Container(
      width: 320, height: 320,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(60),
        boxShadow: [BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.2), blurRadius: 100, spreadRadius: 5)],
        image: DecorationImage(image: NetworkImage(video.thumbnails.highResUrl), fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildTrackDetails() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          Text(video.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          const SizedBox(height: 10),
          Text(video.author.toUpperCase(), style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 14, letterSpacing: 6, fontWeight: FontWeight.bold)),
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
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
          child: Column(
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 2, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  activeTrackColor: g, inactiveTrackColor: Colors.white10, thumbColor: g,
                ),
                child: Slider(
                  value: pos.inSeconds.toDouble(),
                  max: dur.inSeconds.toDouble() > 0 ? dur.inSeconds.toDouble() : 1.0,
                  onChanged: (v) => p.seek(Duration(seconds: v.toInt())),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(pos), style: const TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold)),
                  Text(_formatDuration(dur), style: const TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransportControls(AudioPlayer p, Color g) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.shuffle_rounded, color: Colors.white10, size: 24),
        const SizedBox(width: 35),
        const Icon(Icons.skip_previous_rounded, size: 60),
        const SizedBox(width: 25),
        StreamBuilder<PlayerState>(
          stream: p.playerStateStream,
          builder: (context, snap) {
            bool isPlaying = snap.data?.playing ?? false;
            return GestureDetector(
              onTap: () => isPlaying ? p.pause() : p.play(),
              child: Container(
                width: 100, height: 100,
                decoration: BoxDecoration(color: g, shape: BoxShape.circle, boxShadow: [BoxShadow(color: g.withOpacity(0.3), blurRadius: 40)]),
                child: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.black, size: 65),
              ),
            );
          },
        ),
        const SizedBox(width: 25),
        const Icon(Icons.skip_next_rounded, size: 60),
        const SizedBox(width: 35),
        const Icon(Icons.repeat_rounded, color: Colors.white10, size: 24),
      ],
    );
  }

  String _formatDuration(Duration d) => "${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}";
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
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            expandedHeight: 140,
            backgroundColor: Colors.black,
            flexibleSpace: FlexibleSpaceBar(
              title: Text("ARCHIVE PROTOCOL", style: TextStyle(letterSpacing: 10, fontSize: 12, fontWeight: FontWeight.w100)),
              centerTitle: true,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildVaultSection("ELITE COLLECTION", vault),
                  const SizedBox(height: 50),
                  _buildVaultSection("NEURAL LOGS", history),
                  const SizedBox(height: 150),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVaultSection(String title, List<Video> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Color(0xFFD4AF37), letterSpacing: 4, fontWeight: FontWeight.w900, fontSize: 12)),
        const SizedBox(height: 25),
        if (items.isEmpty) const Text("NO DATA RECORDED", style: TextStyle(color: 
