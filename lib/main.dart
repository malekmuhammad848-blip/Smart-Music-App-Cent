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

  @override
  void initState() {
    super.initState();
    _player.playerStateStream.listen((state) {
      if (mounted) setState(() => isPlaying = state.playing);
    });
  }

  // Search function to find any song on YouTube
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
    try {
      setState(() {
        currentTitle = "Loading...";
        currentArtist = video.author;
        currentCover = video.thumbnails.highResUrl;
      });

      var manifest = await yt.videos.streamsClient.getManifest(video.id);
      var audioUrl = manifest.audioOnly.withHighestBitrate().url.toString();
      
      await _player.setAudioSource(AudioSource.uri(Uri.parse(audioUrl)));
      _player.play();
      
      setState(() => currentTitle = video.title);
    } catch (e) {
      setState(() => currentTitle = "Playback Error");
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
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search for any song...",
                prefixIcon: const Icon(Icons.search, color: Color(0xFFD4AF37)),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
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
                padding: EdgeInsets.only(bottom: currentTitle != null ? 100 : 20),
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  final video = searchResults[index];
                  return ListTile(
                    onTap: () => playMusic(video),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: video.thumbnails.lowResUrl,
                        width: 50, height: 50, fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(video.title, maxLines: 2, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(video.author, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    trailing: const Icon(Icons.play_circle_fill, color: Color(0xFFD4AF37)),
                  );
                },
              ),
          
          if (currentTitle != null)
            Positioned(
              bottom: 15, left: 10, right: 10,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFFD4AF37), width: 0.5),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(imageUrl: currentCover ?? '', width: 45, height: 45, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 12),
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
                    IconButton(
                      icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: const Color(0xFFD4AF37)),
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
