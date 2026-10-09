import 'package:flutter/material.dart';
import '../artisan/painters.dart';
import '../artisan/palette.dart';
import '../artisan/widgets.dart';
import '../audio/audio_service.dart';
import '../settings/app_settings.dart';

/// Hand-mix your own board: pick a color role, tap a swatch.
/// A live mini-board previews the mix. Requires Pro to apply.
class CustomThemeScreen extends StatefulWidget {
  final AppSettings settings;

  const CustomThemeScreen({super.key, required this.settings});

  @override
  State<CustomThemeScreen> createState() => _CustomThemeScreenState();
}

class _Role {
  final String key;
  final String label;
  final List<Color> swatches;
  const _Role(this.key, this.label, this.swatches);
}

class _CustomThemeScreenState extends State<CustomThemeScreen> {
  String _role = 'woodDark';

  static const _woods = [
    Color(0xFF3B2416), Color(0xFF4A1F14), Color(0xFF1A1A1E),
    Color(0xFF5A2A1A), Color(0xFF8A6A42), Color(0xFF3F4226),
    Color(0xFF3F1D24), Color(0xFF7A5A24), Color(0xFF2E3440),
    Color(0xFF3A1A2E), Color(0xFF1E3A38), Color(0xFF2E1A2E),
  ];
  static const _metals = [
    Color(0xFFB08D3C), Color(0xFFB87333), Color(0xFFC0C6D4),
    Color(0xFFD4AF37), Color(0xFF8C6A2F), Color(0xFF6E6E78),
    Color(0xFFC48E6E), Color(0xFF4A4E5E), Color(0xFF9A7B1E),
  ];
  static const _embers = [
    Color(0xFFE58235), Color(0xFFF0752B), Color(0xFFE88B3A),
    Color(0xFFDE7F2E), Color(0xFFD9762E), Color(0xFFE89B4A),
    Color(0xFFC46A2E), Color(0xFFE8A04C), Color(0xFFB85A28),
  ];
  static const _darks = [
    Color(0xFF1E140C), Color(0xFF221009), Color(0xFF121214),
    Color(0xFF1C1310), Color(0xFF181410), Color(0xFF14161A),
    Color(0xFF1D1014), Color(0xFF101816), Color(0xFF0D0603),
  ];
  static const _ivories = [
    Color(0xFFF2E7D5), Color(0xFFF8F1E2), Color(0xFFF5EFE0),
    Color(0xFFF0EBE0), Color(0xFFECEFF4), Color(0xFFF1EAD8),
    Color(0xFF2E2118), Color(0xFF2A2A26), Color(0xFFE8E0D0),
  ];
  static const _stones = [
    Color(0xFFD98E2B), Color(0xFF7A2E2E), Color(0xFF4F7A5B),
    Color(0xFF7D695C), Color(0xFFE0A83C), Color(0xFFB87333),
    Color(0xFF3E9E90), Color(0xFFD96E4E), Color(0xFF2E4E9E),
    Color(0xFFC42E4E), Color(0xFF2E9E5E), Color(0xFF9E5E6E),
    Color(0xFFC9A227), Color(0xFF1A1A22), Color(0xFFF2EAD8),
  ];

  List<_Role> get _roles => [
        _Role('clay', 'Backdrop', _darks),
        _Role('pitInner', 'Pit hollows', _darks),
        _Role('woodDark', 'Board base', _woods),
        _Role('woodDeep', 'Deep shadow', _woods),
        _Role('mahogany', 'Board body', _woods),
        _Role('mahoganyLight', 'Sunlit wood', _woods),
        _Role('woodEdge', 'Board edge', _woods),
        _Role('accent', 'Accent metal', _metals),
        _Role('accentLight', 'Bright metal', _metals),
        _Role('ember', 'Glow', _embers),
        _Role('bone', 'Engraved text', _ivories),
        _Role('boneDim', 'Dim text', _ivories),
        _Role('p0', 'Your stones', _stones),
        _Role('p0Alt', 'Your accent', _stones),
        _Role('p1', 'Rival stones', _stones),
        _Role('p1Alt', 'Rival accent', _stones),
      ];

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    return Scaffold(
      backgroundColor: ArtisanPalette.clay,
      body: ArtisanScaffold(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  WoodIconButton(
                    icon: Icons.arrow_back,
                    size: 40,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Center(
                      child: Text('Theme Atelier',
                          style: ArtisanType.plaqueTitle(size: 20)),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: 12),
              _preview(),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (final r in _roles)
                    GestureDetector(
                      onTap: () {
                        AudioService.instance.uiClick();
                        setState(() => _role = r.key);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _role == r.key
                                ? ArtisanPalette.brass
                                : ArtisanPalette.woodEdge,
                            width: _role == r.key ? 2 : 1.2,
                          ),
                          color: _role == r.key
                              ? ArtisanPalette.brass.withValues(alpha: 0.18)
                              : const Color(0xFF120A05),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(settings
                                        .customColors[r.key] ??
                                    0xFF000000),
                                border: Border.all(
                                    color: ArtisanPalette.boneDim),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(r.label,
                                style: ArtisanType.label(size: 10)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _swatches(settings),
              const SizedBox(height: 14),
              ListenableBuilder(
                listenable: settings,
                builder: (_, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ArtisanButton(
                      label: settings.isPro
                          ? 'CARVE MY BOARD'
                          : 'PRO ONLY — CARVE MY BOARD',
                      icon: Icons.brush_outlined,
                      primary: true,
                      width: double.infinity,
                      onTap: settings.isPro
                          ? () async {
                              await settings.setTheme('custom');
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            }
                          : null,
                    ),
                    const SizedBox(height: 10),
                    ArtisanButton(
                      label: 'RESET MIX',
                      icon: Icons.restart_alt,
                      width: double.infinity,
                      onTap: () => settings.resetCustomColors(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _preview() {
    final c = widget.settings.customColors;
    Color col(String k) => Color(c[k] ?? 0xFF000000);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ArtisanPalette.woodEdge, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: CustomPaint(
          painter: WoodSlabPainter(
            top: col('mahoganyLight'),
            mid: col('woodDark'),
            bottom: col('woodDeep'),
            seed: 5,
            radius: 10,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var i = 0; i < 6; i++)
                  Container(
                    width: 34,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(17),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black87,
                            blurRadius: 5,
                            offset: Offset(0, 3)),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(17),
                      child: CustomPaint(
                        painter: const PitPainter(),
                        child: Center(
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  col(i.isEven ? 'p0' : 'p1'),
                                  col(i.isEven ? 'p0' : 'p1')
                                      .withValues(alpha: 0.55),
                                ],
                              ),
                              border: Border.all(color: col('accent')),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _swatches(AppSettings settings) {
    final role = _roles.firstWhere((r) => r.key == _role);
    final current = settings.customColors[_role];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        for (final s in role.swatches)
          GestureDetector(
            onTap: () {
              AudioService.instance.uiClick();
              settings.setCustomColor(_role, s.toARGB32());
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: s,
                border: Border.all(
                  color: current == s.toARGB32()
                      ? ArtisanPalette.brassLight
                      : ArtisanPalette.woodEdge,
                  width: current == s.toARGB32() ? 3 : 1.5,
                ),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black54,
                      blurRadius: 4,
                      offset: Offset(0, 2)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
