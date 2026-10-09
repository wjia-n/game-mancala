import 'package:flutter/material.dart';
import '../ai/mancala_ai.dart';
import '../artisan/painters.dart';
import '../artisan/palette.dart';
import '../artisan/widgets.dart';
import '../audio/audio_service.dart';
import '../settings/app_settings.dart';
import 'how_to_play.dart';

/// Carved mahogany settings chamber per the Stitch design: sliding wooden-peg
/// toggles, notched-rod volume sliders with glass-stone knobs, difficulty
/// beads, reset defaults.
class SettingsScreen extends StatelessWidget {
  final AppSettings settings;

  const SettingsScreen({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
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
                      child: Text('Game Chamber',
                          style: ArtisanType.plaqueTitle(size: 20)),
                    ),
                  ),
                  WoodIconButton(
                    icon: Icons.help_outline,
                    size: 40,
                    onTap: () => showHowToPlay(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _chamber(context),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chamber(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding:
              const EdgeInsets.fromLTRB(20, 18, 20, 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: ArtisanPalette.woodEdge, width: 1.5),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black87,
                  blurRadius: 18,
                  offset: Offset(0, 8)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: CustomPaint(
              painter: const WoodSlabPainter(
                top: Color(0xFF5C3A21),
                mid: Color(0xFF442A18),
                bottom: Color(0xFF2A1809),
                seed: 123,
                radius: 14,
              ),
              child: Container(
                padding:
                    const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: ListenableBuilder(
                  listenable: settings,
                  builder: (context, _) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Text('◆  SETTINGS  ◆',
                            style:
                                ArtisanType.sectionTitle(size: 16)),
                      ),
                      const SizedBox(height: 8),
                      SettingRow(
                        title: 'Music',
                        subtitle: 'Atmospheric kora & kalimba',
                        trailing: CarvedToggle(
                          value: settings.musicEnabled,
                          onChanged: (v) {
                            settings.setMusicEnabled(v);
                            AudioService.instance.applySettings(settings);
                          },
                        ),
                      ),
                      _volumeRow(
                        label: 'Music volume',
                        value: settings.musicVolume,
                        knob: StoneKind.amber,
                        onChanged: (v) {
                          settings.setMusicVolume(v);
                          AudioService.instance.applySettings(settings);
                        },
                      ),
                      const _Divider(),
                      SettingRow(
                        title: 'Sound effects',
                        subtitle: 'Stone clacks & pit scoops',
                        trailing: CarvedToggle(
                          value: settings.sfxEnabled,
                          onChanged: (v) {
                            settings.setSfxEnabled(v);
                            AudioService.instance.applySettings(settings);
                          },
                        ),
                      ),
                      _volumeRow(
                        label: 'SFX volume',
                        value: settings.sfxVolume,
                        knob: StoneKind.jade,
                        onChanged: (v) {
                          settings.setSfxVolume(v);
                          AudioService.instance.applySettings(settings);
                          AudioService.instance.uiClick();
                        },
                      ),
                      const _Divider(),
                      SettingRow(
                        title: 'Vibration',
                        subtitle: 'Haptic stone drops',
                        trailing: CarvedToggle(
                          value: settings.vibration,
                          onChanged: settings.setVibration,
                        ),
                      ),
                      const _Divider(),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text('Bot difficulty',
                                style:
                                    ArtisanType.bodyText(size: 15)),
                            const SizedBox(height: 2),
                            Text(settings.difficulty.blurb,
                                style: ArtisanType.label(size: 10)),
                            const SizedBox(height: 10),
                            DifficultyBeads(
                              selected: settings.difficulty.index,
                              labels: const ['Calm', 'Sharp', 'Master'],
                              onSelected: (i) => settings.setDifficulty(
                                  BotDifficulty.values[i]),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: Text(
                            'Crafted with wood, glass and patience.',
                            style: ArtisanType.label(size: 9)),
                      ),
                      const SizedBox(height: 12),
                      ArtisanButton(
                        label: 'RESET DEFAULTS',
                        icon: Icons.restart_alt,
                        onTap: () {
                          settings.resetDefaults();
                          AudioService.instance.applySettings(settings);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        for (final pos in [
          const Alignment(-1, -1),
          const Alignment(1, -1),
          const Alignment(-1, 1),
          const Alignment(1, 1),
        ])
          Align(
            alignment: pos,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: SizedBox(
                  width: 12,
                  height: 12,
                  child: CustomPaint(painter: RivetPainter())),
            ),
          ),
      ],
    );
  }

  Widget _volumeRow({
    required String label,
    required double value,
    required StoneKind knob,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: ArtisanType.label(size: 10)),
          ),
          Expanded(
            child: NotchedSlider(
              value: value,
              knobKind: knob,
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 46,
            child: Text('${(value * 100).round()}%',
                textAlign: TextAlign.right,
                style: ArtisanType.bodyText(
                    size: 12, color: ArtisanPalette.brassLight)),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            ArtisanPalette.brass.withValues(alpha: 0.4),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
