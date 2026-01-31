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
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.music_note, size: 100, color: Colors.blue),
              SizedBox(height: 20),
              Text(
                'CENT Music',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              Text('System Initialized Successfully'),
            ],
          ),
        ),
      ),
    );
  }
}
