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
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.yellow,
        ).copyWith(secondary: const Color(0xFFD4AF37)),
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
  
  String? currentPlayingTitle;
  String? currentPlayingArtist;
  String? currentPlayingCover;
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    fetchSongs();
    _player.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          isPlaying = state.playing;
          if (state.processingState == ProcessingState.completed) {
            currentPlayingTitle = null;
            currentPlayingArtist = null;
            currentPlayingCover = null;
            isPlaying = false;
          }
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
          errorMessage = "";
        });
      } else {
        setState(() { errorMessage = "Server Error: ${response.statusCode}"; isLoading = false; });
      }
    } catch (e) {
      setState(() { errorMessage = "Connection Failed! Check Internet or Server."; isLoading = false; });
    }
  }

  Future<void> playMusic(String videoId, String title, String artist, String cover) async {
    setState(() { 
      currentPlayingTitle = "Loading: $title"; 
      currentPlayingArtist = artist;
      currentPlayingCover = cover;
      isPlaying = true;
    });
    
    try {
      var manifest = await yt.videos.streamsClient.getManifest(videoId);
      var audioUrl = manifest.audioOnly.withHighestBitrate().url;
      
      await _player.setUrl(audioUrl.toString());
      _player.play();
      
      setState(() { currentPlayingTitle = title; });
    } catch (e) {
      setState(() { currentPlayingTitle = "Error playing: $title"; isPlaying = false; });
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
        title: const Text("CENT MUSIC", style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          isLoading 
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
            : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage, style: const TextStyle(color: Colors.redAccent, fontSize: 16)))
              : songs.isEmpty
                ? const Center(child: Text("No Songs Found. Add from Admin Panel!", style: TextStyle(color: Colors.grey, fontSize: 16)))
                : ListView.builder(
                    padding: EdgeInsets.only(bottom: currentPlayingTitle != null ? 90 : 20),
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        onTap: () => playMusic(songs[index]['youtubeId'], songs[index]['title'], songs[index]['artist'], songs[index]['cover']),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: songs[index]['cover'],
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const CircularProgressIndicator(color: Color(0xFFD4AF37)),
                            errorWidget: (context, url, error) => const Icon(Icons.music_note, color: Colors.grey),
                          ),
                        ),
                        title: Text(songs[index]['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        subtitle: Text(songs[index]['artist'], style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        trailing: Icon(
                          (currentPlayingTitle == songs[index]['title'] && isPlaying) ? Icons.pause_circle_filled : Icons.play_circle_fill,
                          color: (currentPlayingTitle == songs[index]['title'] && isPlaying) ? Colors.redAccent : const Color(0xFFD4AF37),
                          size: 30,
                        ),
                      );
                    },
                  ),
          if (currentPlayingTitle != null)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  border: Border(top: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.5), width: 0.5)),
                ),
                child: Row(
                  children: [
                    if (currentPlayingCover != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: CachedNetworkImage(
                          imageUrl: currentPlayingCover!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Icon(Icons.audiotrack, color: Colors.grey),
                          errorWidget: (context, url, error) => const Icon(Icons.audiotrack, color: Colors.grey),
                        ),
                      ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(currentPlayingTitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(currentPlayingArtist!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, size: 40),
                      color: const Color(0xFFD4AF37),
                      onPressed: () {
                        if (isPlaying) { _player.pause(); } else { _player.play(); }
                        setState(() { isPlaying = !isPlaying; });
                      },
                    )
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
