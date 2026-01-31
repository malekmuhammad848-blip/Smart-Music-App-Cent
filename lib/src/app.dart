import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cent_music/src/core/theme/app_theme.dart';
import 'package:cent_music/src/features/auth/presentation/providers/auth_provider.dart';
import 'package:cent_music/src/features/player/presentation/providers/player_provider.dart';
import 'package:cent_music/src/routes/app_router.dart';

class CentMusicApp extends ConsumerWidget {
  CentMusicApp({super.key});

  final _appRouter = AppRouter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    
    return MaterialApp.router(
      title: 'CENT Music',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: _appRouter.config(),
      debugShowCheckedModeBanner: false,
    );
  }
}
