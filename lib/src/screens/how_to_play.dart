import 'package:flutter/material.dart';
import '../artisan/painters.dart';
import '../artisan/palette.dart';
import '../artisan/widgets.dart';
import '../audio/audio_service.dart';

/// Carved "How to Play" sheet — a faithful summary of RULES.md.
void showHowToPlay(BuildContext context) {
  AudioService.instance.uiClick();
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _HowToPlaySheet(),
  );
}

class _HowToPlaySheet extends StatelessWidget {
  const _HowToPlaySheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ArtisanPalette.brass, width: 1.5),
        boxShadow: const [
          BoxShadow(
              color: Colors.black87, blurRadius: 20, offset: Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: CustomPaint(
          painter: const WoodSlabPainter(seed: 77, radius: 14),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Text('HOW TO PLAY',
                      style: ArtisanType.sectionTitle(size: 18)),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text('Traditional Kalah rules',
                      style: ArtisanType.label(size: 10)),
                ),
                const SizedBox(height: 14),
                for (final rule in _rules) _ruleRow(rule.$1, rule.$2),
                const SizedBox(height: 16),
                Center(
                  child: ArtisanButton(
                    label: 'GOT IT',
                    icon: Icons.check,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _ruleRow(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child:
                GlassStone(kind: StoneKind.amber, size: 14, seed: title.length),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: ArtisanType.bodyText(
                        size: 13.5, color: ArtisanPalette.brassLight)),
                const SizedBox(height: 2),
                Text(body, style: ArtisanType.bodyText(size: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const List<(String, String)> _rules = [
  (
    'Sow your pits',
    'Tap one of YOUR pits to lift all its stones. They drop one by one, '
        'counter-clockwise — across your row, into your store (right side), '
        'then across the far row. The rival store is always skipped.'
  ),
  (
    'Free turn',
    'If your last stone lands in your own store, you move again immediately.'
  ),
  (
    'Capture',
    'If your last stone lands in an empty pit on your side, that stone plus '
        'every stone in the opposite pit flies into your store.'
  ),
  (
    'Game end',
    'The moment either row is completely empty, the game ends. All remaining '
        'stones sweep into their owner\u2019s store.'
  ),
  (
    'Winning',
    'Most stones in your store wins — more than 24 of the 48 takes the '
        'harvest. 24–24 is an honorable draw.'
  ),
];
