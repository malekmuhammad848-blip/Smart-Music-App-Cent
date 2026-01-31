import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const CentMusicApp());
}

class CentMusicApp extends StatelessWidget {
  const CentMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CENT Music',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFFD4AF37),
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

  @override
  void initState() {
    super.initState();
    fetchSongs();
  }

  // Correction: 'async' must be after the function name in Dart
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
      print("Error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CENT MUSIC', 
          style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
          : songs.isEmpty
              ? const Center(child: Text("No Songs Found. Add one from Admin!"))
              : ListView.builder(
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: Image.network(
                          songs[index]['cover'], 
                          width: 50, 
                          height: 50, 
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.music_note),
                        ),
                      ),
                      title: Text(songs[index]['title'], maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(songs[index]['artist'], style: const TextStyle(color: Colors.white70)),
                      trailing: const Icon(Icons.play_arrow, color: Color(0xFFD4AF37)),
                    );
                  },
                ),
    );
  }
}
