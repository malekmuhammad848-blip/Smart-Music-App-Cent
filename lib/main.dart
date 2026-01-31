import 'package:flutter/material.dart';

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD4AF37),
          brightness: Brightness.dark,
          primary: const Color(0xFFD4AF37),
        ),
      ),
      home: const MainMusicScreen(),
    );
  }
}

class MainMusicScreen extends StatelessWidget {
  const MainMusicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CENT MUSIC', style: TextStyle(letterSpacing: 3, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37))),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                boxShadow: [
                  BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.2), blurRadius: 20, spreadRadius: 5)
                ],
              ),
              child: const Icon(Icons.headset_mic, size: 100, color: Color(0xFFD4AF37)),
            ),
            const SizedBox(height: 40),
            const Text(
              'Connecting to Render...',
              style: TextStyle(color: Colors.white70, fontSize: 16, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: Color(0xFFD4AF37)),
          ],
        ),
      ),
    );
  }
}
