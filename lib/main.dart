import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: const Color(0xFFD4AF37),
          brightness: Brightness.dark,
        ),
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
  List songs = [];
  bool isLoading = true;
  String errorMessage = "";
  final AudioPlayer _player = AudioPlayer();
  final yt = YoutubeExplode();
  
  String? currentTitle;
  String? currentArtist;
  String? currentCover;
  bool isPlaying = false;
  bool isBuffering = false;

  @override
  void initState() {
    super.initState();
    fetchSongs();
    
    _player.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          isPlaying = state.playing;
          isBuffering = state.processingState == ProcessingState.buffering || 
                        state.processingState == ProcessingState.loading;
        });
      }
    });
  }

  Future<void> fetchSongs() async {
    try {
      final response = await http.get(Uri.parse('https://smart-music-app-cent-12.onrender.com/api/songs/all'));
      if (response.statusCode == 200) {
        setState(() {
          songs = json.decode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Check your connection";
        isLoading = false;
      });
    }
  }

  Future<void> playMusic(String videoId, String title, String artist, String cover) async {
    try {
      setState(() {
        currentTitle = "Loading...";
        currentArtist = artist;
        currentCover = cover;
      });

      var manifest = await yt.videos.streamsClient.getManifest(videoId);
      var audioUrl = manifest.audioOnly.withHighestBitrate().url.toString();
      
      await _player.setAudioSource(AudioSource.uri(Uri.parse(audioUrl)));
      _player.play();
      
      setState(() {
        currentTitle = title;
      });
    } catch (e) {
      setState(() {
        currentTitle = "Playback Error";
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
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          isLoading 
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
            : ListView.builder(
                padding: EdgeInsets.only(bottom: currentTitle != null ? 100 : 20),
                itemCount: songs.length,
                itemBuilder: (context, index) {
                  final song = songs[index];
                  bool isThisSelected = currentTitle == song['title'];
                  return ListTile(
                    onTap: () => playMusic(song['youtubeId'], song['title'], song['artist'], song['cover']),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: song['cover'],
                        width: 50, height: 50, fit: BoxFit.cover,
                        errorWidget: (context, url, error) => const Icon(Icons.music_note),
                      ),
                    ),
                    title: Text(song['title'], style: TextStyle(color: isThisSelected ? const Color(0xFFD4AF37) : Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text(song['artist'], style: const TextStyle(color: Colors.grey)),
                    trailing: Icon(isThisSelected && isPlaying ? Icons.pause_circle : Icons.play_circle, color: const Color(0xFFD4AF37)),
                  );
                },
              ),
          
          if (currentTitle != null)
            Positioned(
              bottom: 10, left: 10, right: 10,
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
                          Text(currentTitle!, maxLines: 1, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(currentArtist ?? '', maxLines: 1, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    if (isBuffering)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD4AF37))),
                      )
                    else
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
