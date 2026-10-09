import 'package:flutter/material.dart';
import '../artisan/painters.dart';
import '../artisan/palette.dart';
import '../audio/audio_service.dart';
import '../services/store_service.dart';
import '../settings/app_settings.dart';
import 'main_menu.dart';

/// Launch splash: game logo + name, animated loading line, credits.
///
/// Single splash (no separate company moment): the WAJIHA company logo rides
/// along in the "Credits: WAJIHA" line. Audio synthesis is pre-warmed here so
/// menu music starts reliably the moment the menu appears.
class SplashScreen extends StatefulWidget {
  final AppSettings settings;
  final StoreService store;

  const SplashScreen({super.key, required this.settings, required this.store});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loader;

  @override
  void initState() {
    super.initState();
    _loader = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _run();
  }

  Future<void> _run() async {
    widget.settings.applyTheme();
    AudioService.instance.prewarm();
    widget.store.init();
    _loader.forward();
    // Wait for synthesis so menu music can start on arrival.
    var waited = 0;
    while (!AudioService.instance.isReady && waited < 4000) {
      await Future.delayed(const Duration(milliseconds: 100));
      waited += 100;
    }
    AudioService.instance.menuMusic();
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MainMenuScreen(
          settings: widget.settings,
          store: widget.store,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _loader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtisanPalette.clay,
      body: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: VignettePainter())),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 190,
                    height: 190,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: ArtisanPalette.brass, width: 3),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black87,
                          offset: Offset(0, 10),
                          blurRadius: 24,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset('assets/mancala_logo.png',
                        fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 22),
                  Text('MANCALA', style: ArtisanType.plaqueTitle(size: 44)),
                  const SizedBox(height: 6),
                  Text('THE ANCIENT SOWING GAME',
                      style: ArtisanType.label(size: 12)),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: 220,
                    child: AnimatedBuilder(
                      animation: _loader,
                      builder: (_, _) => Column(
                        children: [
                          Container(
                            height: 6,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              color: Colors.black.withValues(alpha: 0.45),
                              border: Border.all(color: ArtisanPalette.brass),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: _loader.value.clamp(0.02, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(3),
                                  gradient: LinearGradient(
                                    colors: [
                                      ArtisanPalette.brassLight,
                                      ArtisanPalette.brass,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _loader.value < 1
                                ? 'Carving the board…'
                                : 'Ready!',
                            style: ArtisanType.bodyText(
                                size: 13,
                                color: ArtisanPalette.boneDim),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 44),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/wajiha_logo.png',
                        width: 30,
                        height: 30,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 10),
                      Text('Credits: WAJIHA',
                          style: ArtisanType.label(size: 14)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
