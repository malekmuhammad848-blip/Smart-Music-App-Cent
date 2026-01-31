import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cent_music/src/app.dart';

void main() {
  runApp(
    ProviderScope(
      child: CentMusicApp(),
    ),
  );
}
