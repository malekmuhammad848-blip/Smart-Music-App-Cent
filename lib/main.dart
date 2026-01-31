import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(const CentMusicApp());

class CentMusicApp extends StatelessWidget {
  const CentMusicApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
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

  @override
  void initState() {
    super.initState();
    fetchSongs();
  }

  Future<void> fetchSongs() async {
    try {
      final response = await http.get(Uri.parse('https://smart-music-app-cent-12.onrender.com/api/songs/all'));
      if (response.statusCode == 200) {
        setState(() {
          songs = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() { errorMessage = "Server Error: ${response.statusCode}"; isLoading = false; });
      }
    } catch (e) {
      setState(() { errorMessage = "Connection Failed! Check Internet."; isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("CENT MUSIC", style: TextStyle(color: Color(0xFFD4AF37)))),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : errorMessage.isNotEmpty
          ? Center(child: Text(errorMessage))
          : songs.isEmpty
            ? const Center(child: Text("No Songs Found in Database"))
            : ListView.builder(
                itemCount: songs.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Image.network(songs[index]['cover'], width: 50, errorBuilder: (c, e, s) => const Icon(Icons.music_note)),
                    title: Text(songs[index]['title']),
                    subtitle: Text(songs[index]['artist']),
                    trailing: const Icon(Icons.play_circle_fill, color: Color(0xFFD4AF37)),
                  );
                },
              ),
    );
  }
}
