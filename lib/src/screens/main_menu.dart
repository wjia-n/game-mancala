import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../artisan/painters.dart';
import '../artisan/palette.dart';
import '../artisan/widgets.dart';
import '../audio/audio_service.dart';
import '../settings/app_settings.dart';
import 'game_screen.dart';
import 'how_to_play.dart';
import 'settings_screen.dart';

/// Handcrafted main menu: engraved MANCALA plaque, decorative mini-board
/// relief, carved-wood buttons — per the Stitch "Handcrafted Main Menu".
class MainMenuScreen extends StatefulWidget {
  final AppSettings settings;

  const MainMenuScreen({super.key, required this.settings});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  @override
  void initState() {
    super.initState();
    AudioService.instance.menuMusic();
  }

  void _startGame(bool vsBot) {
    AudioService.instance.gameStart();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(settings: widget.settings, vsBot: vsBot),
      ),
    ).then((_) {
      if (mounted) {
        AudioService.instance.menuMusic();
        setState(() {}); // refresh rank after a match
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtisanPalette.clay,
      body: ArtisanScaffold(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('ANCIENT SOWING GAME',
                      style: ArtisanType.label(size: 11)),
                  WoodIconButton(
                    icon: Icons.settings,
                    size: 40,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            SettingsScreen(settings: widget.settings),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const TitlePlaque(
                title: 'MANCALA',
                subtitle: 'The ancient sowing game',
                titleSize: 34,
              ),
              const SizedBox(height: 6),
              Text('Heirloom Walnut Board  •  12 Wells',
                  style: ArtisanType.label(size: 10)),
              const SizedBox(height: 14),
              const _MiniBoardRelief(),
              const SizedBox(height: 16),
              ArtisanButton(
                label: 'PLAY VS BOT',
                icon: Icons.smart_toy_outlined,
                primary: true,
                width: double.infinity,
                onTap: () => _startGame(true),
              ),
              const SizedBox(height: 4),
              Text('Solo tactical training',
                  style: ArtisanType.label(size: 10)),
              const SizedBox(height: 12),
              ArtisanButton(
                label: '2 PLAYERS',
                icon: Icons.group_outlined,
                width: double.infinity,
                onTap: () => _startGame(false),
              ),
              const SizedBox(height: 4),
              Text('Shared device, pass & play',
                  style: ArtisanType.label(size: 10)),
              const SizedBox(height: 12),
              ArtisanButton(
                label: 'GAME SETTINGS & RULES',
                icon: Icons.tune,
                width: double.infinity,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SettingsScreen(settings: widget.settings),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _UtilityRow(settings: widget.settings),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// Decorative non-interactive mini board: walnut slab with tiny pits and
/// assorted glass stones, like a carved relief on the menu.
class _MiniBoardRelief extends StatelessWidget {
  const _MiniBoardRelief();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ArtisanPalette.woodEdge, width: 1.5),
        boxShadow: const [
          BoxShadow(
              color: Colors.black87, blurRadius: 16, offset: Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: CustomPaint(
          painter: const WoodSlabPainter(seed: 99, radius: 14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (var i = 0; i < 6; i++)
                      _miniPit(top: true, index: i),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (var i = 0; i < 6; i++)
                      _miniPit(top: false, index: i),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final k in [
                      StoneKind.amber,
                      StoneKind.jade,
                      StoneKind.quartz
                    ])
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            GlassStone(kind: k, size: 11, seed: k.index),
                            const SizedBox(width: 5),
                            Text(k.name[0].toUpperCase() + k.name.substring(1),
                                style: ArtisanType.label(size: 9)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniPit({required bool top, required int index}) {
    return Container(
      width: 40,
      height: 46,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black87, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: CustomPaint(
          painter: const PitPainter(),
          child: Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 2,
              runSpacing: 2,
              children: [
                for (var s = 0; s < 3 + ((index + (top ? 2 : 0)) % 3); s++)
                  GlassStone(
                    kind: stoneKindFor(top ? 1 : 0, index, s),
                    size: 9,
                    seed: index * 5 + s,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom utility row: sound quick-toggle, How to Play, player rank.
class _UtilityRow extends StatelessWidget {
  final AppSettings settings;

  const _UtilityRow({required this.settings});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _chip(
              icon: settings.sfxEnabled
                  ? Icons.volume_up
                  : Icons.volume_off,
              label: 'Sound: ${settings.sfxEnabled ? 'On' : 'Off'}',
              onTap: () {
                HapticFeedback.selectionClick();
                settings.setSfxEnabled(!settings.sfxEnabled);
                AudioService.instance.applySettings(settings);
              },
            ),
            _chip(
              icon: Icons.menu_book_outlined,
              label: 'How to Play',
              onTap: () => showHowToPlay(context),
            ),
            _chip(
              icon: Icons.military_tech_outlined,
              label: 'Rank: ${settings.rank}',
              onTap: null,
            ),
          ],
        );
      },
    );
  }

  Widget _chip(
      {required IconData icon, required String label, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap == null
          ? null
          : () {
              AudioService.instance.uiClick();
              onTap();
            },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFF120A05),
          border: Border.all(
              color: ArtisanPalette.brass.withValues(alpha: 0.5), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: ArtisanPalette.brass, size: 16),
            const SizedBox(width: 6),
            Text(label, style: ArtisanType.label(size: 10)),
          ],
        ),
      ),
    );
  }
}
