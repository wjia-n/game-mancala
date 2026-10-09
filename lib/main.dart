import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'src/artisan/palette.dart';
import 'src/audio/audio_service.dart';
import 'src/screens/main_menu.dart';
import 'src/settings/app_settings.dart';

/// Mancala — Artisan Mancala edition.
///
/// Hand-carved African artisan woodwork: dark walnut board, concave pits,
/// polished glass stones. Clean architecture: engine / AI / audio / settings
/// / artisan UI are fully separated; the game rules live in the pure-Dart
/// [MancalaEngine] and match RULES.md exactly.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Warm, sunlit presentation: edge-to-edge, no system chrome flash.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final settings = await AppSettings.load();
  final audio = AudioService.instance;
  audio.applySettings(settings);
  // Synthesize the artisan sound set in the background; the menu appears
  // immediately and music starts as soon as the first loop is ready.
  audio.init().then((_) {
    audio.applySettings(settings);
    audio.menuMusic();
  });
  settings.addListener(() => audio.applySettings(settings));

  runApp(MancalaApp(settings: settings));
}

class MancalaApp extends StatefulWidget {
  final AppSettings settings;

  const MancalaApp({super.key, required this.settings});

  @override
  State<MancalaApp> createState() => _MancalaAppState();
}

class _MancalaAppState extends State<MancalaApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Duck all audio while backgrounded; the game screen auto-pauses itself.
    AudioService.instance
        .setDucked(state == AppLifecycleState.paused || state == AppLifecycleState.hidden);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mancala',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: ArtisanPalette.clay,
        fontFamily: ArtisanType.body,
        colorScheme: const ColorScheme.dark(
          primary: ArtisanPalette.brass,
          surface: ArtisanPalette.clay,
        ),
      ),
      home: MainMenuScreen(settings: widget.settings),
    );
  }
}
