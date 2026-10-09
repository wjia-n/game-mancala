import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../ai/mancala_ai.dart';
import '../artisan/painters.dart';
import '../artisan/palette.dart';
import '../artisan/widgets.dart';
import '../audio/audio_service.dart';
import '../services/store_service.dart';
import '../settings/app_settings.dart';
import 'game_screen.dart';
import 'how_to_play.dart';
import 'pro_screen.dart';
import 'settings_screen.dart';

/// Handcrafted main menu: game logo, engraved MANCALA plaque, mode buttons.
class MainMenuScreen extends StatefulWidget {
  final AppSettings settings;
  final StoreService store;

  const MainMenuScreen(
      {super.key, required this.settings, required this.store});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  @override
  void initState() {
    super.initState();
    AudioService.instance.menuMusic();
    // Flip Pro on when the store reports a completed purchase.
    widget.store.proPurchased.addListener(_onProChanged);
    if (widget.store.proPurchased.value && !widget.settings.isPro) {
      widget.settings.setPro(true);
    }
  }

  void _onProChanged() {
    if (widget.store.proPurchased.value && !widget.settings.isPro) {
      widget.settings.setPro(true);
    }
  }

  @override
  void dispose() {
    widget.store.proPurchased.removeListener(_onProChanged);
    super.dispose();
  }

  void _startGame(GameMode mode) {
    widget.settings.setMode(mode);
    AudioService.instance.gameStart();
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (_) =>
            GameScreen(settings: widget.settings, store: widget.store),
      ),
    )
        .then((_) {
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
                        builder: (_) => SettingsScreen(
                            settings: widget.settings,
                            store: widget.store),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border:
                      Border.all(color: ArtisanPalette.brass, width: 2.5),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black87,
                        blurRadius: 16,
                        offset: Offset(0, 8)),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset('assets/mancala_logo.png',
                    fit: BoxFit.cover),
              ),
              const SizedBox(height: 10),
              const TitlePlaque(
                title: 'MANCALA',
                subtitle: 'The ancient sowing game',
                titleSize: 34,
              ),
              const SizedBox(height: 6),
              ListenableBuilder(
                listenable: widget.settings,
                builder: (_, _) => Text(
                    'Last setup: ${widget.settings.modeLabel}',
                    style: ArtisanType.label(size: 10)),
              ),
              const SizedBox(height: 14),
              const _MiniBoardRelief(),
              const SizedBox(height: 16),
              ArtisanButton(
                label: 'PLAY VS BOT',
                icon: Icons.smart_toy_outlined,
                primary: true,
                width: double.infinity,
                onTap: () => _startGame(GameMode.solo),
              ),
              const SizedBox(height: 4),
              ListenableBuilder(
                listenable: widget.settings,
                builder: (_, _) => Text(
                    'Solo vs ${widget.settings.difficulty.label} bot',
                    style: ArtisanType.label(size: 10)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ArtisanButton(
                      label: '2 PLAYERS',
                      icon: Icons.group_outlined,
                      onTap: () => _startGame(GameMode.pass),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ArtisanButton(
                      label: 'HUMAN + BOT',
                      icon: Icons.diversity_3_outlined,
                      onTap: () => _startGame(GameMode.mixed),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('Shared device, pass & play · mixed sides',
                  style: ArtisanType.label(size: 10)),
              const SizedBox(height: 12),
              ArtisanButton(
                label: 'WATCH BOTS DUEL',
                icon: Icons.visibility_outlined,
                width: double.infinity,
                onTap: () => _startGame(GameMode.watch),
              ),
              const SizedBox(height: 12),
              ListenableBuilder(
                listenable: widget.settings,
                builder: (_, _) => widget.settings.isPro
                    ? const SizedBox.shrink()
                    : ArtisanButton(
                        label: 'GET MANCALA PRO',
                        icon: Icons.workspace_premium_outlined,
                        width: double.infinity,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ProScreen(
                                settings: widget.settings,
                                store: widget.store),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 18),
              _UtilityRow(settings: widget.settings, store: widget.store),
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
                    for (var i = 0; i < 6; i++) _miniPit(top: true, index: i),
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
  final StoreService store;

  const _UtilityRow({required this.settings, required this.store});

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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
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
