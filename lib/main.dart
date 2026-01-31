import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:cached_network_image/cached_network_image.dart';

void main() => runApp(const CentMusicApp());

class CentMusicApp extends StatelessWidget {
  const CentMusicApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFFD4AF37),
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
      ),
      home: const MainMusicScreen(),
    );
  }
}

class MainMusicScreen extends StatefulWidget {
  const MainMusicScreen({super.key});
  @override
  State<MainMusicScreen> createState() => _MainMusicScreenState();
}

class _MainMusicScreenState extends State<MainMusicScreen> {
  final AudioPlayer _player = AudioPlayer();
  final yt = YoutubeExplode();
  final TextEditingController _searchController = TextEditingController();
  
  List<Video> searchResults = [];
  bool isSearching = false;
  
  String? currentTitle;
  String? currentArtist;
  String? currentCover;
  bool isPlaying = false;
  bool isLoadingAudio = false;

  @override
  void initState() {
    super.initState();
    _player.playerStateStream.listen((state) {
      if (mounted) setState(() => isPlaying = state.playing);
    });
  }

  Future<void> searchYouTube(String query) async {
    if (query.isEmpty) return;
    setState(() => isSearching = true);
    try {
      var search = await yt.search.search(query);
      setState(() {
        searchResults = search.toList();
        isSearching = false;
      });
    } catch (e) {
      setState(() => isSearching = false);
    }
  }

  Future<void> playMusic(Video video) async {
    setState(() {
      isLoadingAudio = true;
      currentTitle = "Fetching Audio...";
      currentArtist = video.author;
      currentCover = video.thumbnails.highResUrl;
    });

    try {
      // Get the stream manifest
      var manifest = await yt.videos.streamsClient.getManifest(video.id);
      
      // Get the best audio-only stream
      var audioStream = manifest.audioOnly.withHighestBitrate();
      
      // Set source and play
      await _player.setAudioSource(AudioSource.uri(Uri.parse(audioStream.url.toString())));
      _player.play();
      
      setState(() {
        currentTitle = video.title;
        isLoadingAudio = false;
      });
    } catch (e) {
      setState(() {
        currentTitle = "Error: Use another song";
        isLoadingAudio = false;
        isPlaying = false;
      });
    }
  }

  @override
  void dispose() {
    _player.dispose();
    yt.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("CENT MUSIC", style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search any song...",
                prefixIcon: const Icon(Icons.search, color: Color(0xFFD4AF37)),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
              onSubmitted: (value) => searchYouTube(value),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          isSearching 
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
            : ListView.builder(
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  final video = searchResults[index];
                  return ListTile(
                    onTap: () => playMusic(video),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(imageUrl: video.thumbnails.lowResUrl, width: 50, height: 50, fit: BoxFit.cover),
                    ),
                    title: Text(video.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
                    subtitle: Text(video.author, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    trailing: const Icon(Icons.play_arrow_rounded, color: Color(0xFFD4AF37)),
                  );
                },
              ),
          if (currentTitle != null)
            Positioned(
              bottom: 15, left: 10, right: 10,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFD4AF37), width: 0.5),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(imageUrl: currentCover ?? '', width: 50, height: 50, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(currentTitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(currentArtist ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    if (isLoadingAudio)
                      const SizedBox(width: 25, height: 25, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD4AF37)))
                    else
                      IconButton(
                        icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, size: 40, color: const Color(0xFFD4AF37)),
                        onPressed: () => isPlaying ? _player.pause() : _player.play(),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
