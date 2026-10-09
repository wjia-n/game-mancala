import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'src/artisan/palette.dart';
import 'src/audio/audio_service.dart';
import 'src/screens/splash_screen.dart';
import 'src/services/store_service.dart';
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
  settings.applyTheme();
  final store = StoreService();
  final audio = AudioService.instance;
  audio.applySettings(settings);
  // The splash screen pre-warms synthesis and starts menu music.
  settings.addListener(() {
    settings.applyTheme();
    audio.applySettings(settings);
  });

  runApp(MancalaApp(settings: settings, store: store));
}

class MancalaApp extends StatefulWidget {
  final AppSettings settings;
  final StoreService store;

  const MancalaApp({super.key, required this.settings, required this.store});

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
    widget.store.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause (not stop) on interruption so music resumes exactly where it
    // left off; game screens additionally freeze their engines.
    AudioService.instance.setDucked(
        state == AppLifecycleState.paused || state == AppLifecycleState.hidden);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.settings,
      builder: (_, _) {
        // Theme changes re-skin the whole app via the applied palette.
        widget.settings.applyTheme();
        return MaterialApp(
          title: 'Mancala',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: ArtisanPalette.clay,
            fontFamily: ArtisanType.body,
            colorScheme: ColorScheme.dark(
              primary: ArtisanPalette.brass,
              surface: ArtisanPalette.clay,
            ),
          ),
          home: SplashScreen(
              settings: widget.settings, store: widget.store),
        );
      },
    );
  }
}
