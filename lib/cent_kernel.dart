import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'audio_engine.dart';
import 'visual_engine.dart';
import 'main_core.dart';
import 'main.dart';

class CentKernel extends StatelessWidget {
  const CentKernel({super.key});

  static Future<void> boot() async {
    WidgetsFlutterBinding.ensureInitialized();
    final manager = GlobalApplicationManager.instance;
    await manager.initializeAllSystems();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeOrchestrator()),
        Provider(create: (_) => GlobalApplicationManager.instance),
        Provider(create: (_) => VisualAudioSynchronizer()),
        Provider(create: (_) => QuantumAudioEngine()),
        Provider(create: (_) => HyperspaceVisualEngine()),
      ],
      child: const UltimateMusicApp(),
    );
  }
}
