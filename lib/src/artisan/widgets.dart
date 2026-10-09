import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../audio/audio_service.dart';
import 'painters.dart';
import 'palette.dart';

/// Shared artisan UI kit: plaques, buttons, toggles, sliders, stones.
/// Every widget is painted wood/glass/brass — no flat Material surfaces.

/// Full-screen artisan backdrop: clay background + warm vignette.
class ArtisanScaffold extends StatelessWidget {
  final Widget child;
  final bool safeTop;

  const ArtisanScaffold({super.key, required this.child, this.safeTop = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ArtisanPalette.clay,
      child: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: VignettePainter())),
          Positioned.fill(
            child: SafeArea(top: safeTop, child: child),
          ),
        ],
      ),
    );
  }
}

/// Engraved title plaque with brass rivet corners.
class TitlePlaque extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double titleSize;

  const TitlePlaque(
      {super.key, required this.title, this.subtitle, this.titleSize = 30});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ArtisanPalette.woodEdge, width: 1.5),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black87, blurRadius: 14, offset: Offset(0, 6)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CustomPaint(
              painter: const WoodSlabPainter(
                  top: Color(0xFF4A2E1A),
                  mid: Color(0xFF38220F),
                  bottom: Color(0xFF241307),
                  seed: 42),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                child: Column(
                  children: [
                    Text(title,
                        textAlign: TextAlign.center,
                        style: ArtisanType.plaqueTitle(size: titleSize)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(subtitle!,
                          textAlign: TextAlign.center,
                          style: ArtisanType.label(size: 12)),
                    ],
                  ],
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
              padding: EdgeInsets.all(7),
              child: SizedBox(
                  width: 11,
                  height: 11,
                  child: CustomPaint(painter: RivetPainter())),
            ),
          ),
      ],
    );
  }
}

/// Bevelled hand-sanded wooden button block.
class ArtisanButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool primary;
  final double? width;

  const ArtisanButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.primary = false,
    this.width,
  });

  @override
  State<ArtisanButton> createState() => _ArtisanButtonState();
}

class _ArtisanButtonState extends State<ArtisanButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap == null
          ? null
          : () {
              AudioService.instance.uiClick();
              widget.onTap!();
            },
      child: AnimatedScale(
        scale: _down ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: Opacity(
          opacity: widget.onTap == null ? 0.55 : 1.0,
          child: Container(
            width: widget.width,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.primary
                    ? ArtisanPalette.brass
                    : ArtisanPalette.woodEdge,
                width: widget.primary ? 2 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: _down ? 0.4 : 0.75),
                  blurRadius: _down ? 6 : 12,
                  offset: Offset(0, _down ? 2 : 5),
                ),
                if (widget.primary)
                  BoxShadow(
                    color: ArtisanPalette.ember.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CustomPaint(
                painter: WoodSlabPainter(
                  top: widget.primary
                      ? const Color(0xFF6B4426)
                      : ArtisanPalette.mahoganyLight,
                  mid: widget.primary
                      ? const Color(0xFF4E3018)
                      : ArtisanPalette.walnutDark,
                  bottom: ArtisanPalette.walnutDeep,
                  seed: widget.label.hashCode,
                ),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon,
                            color: ArtisanPalette.bone, size: 20),
                        const SizedBox(width: 10),
                      ],
                      Flexible(
                        child: Text(widget.label,
                            textAlign: TextAlign.center,
                            style: ArtisanType.button()),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small square wooden icon button (pause, back, gear).
class WoodIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  const WoodIconButton(
      {super.key, required this.icon, required this.onTap, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        AudioService.instance.uiClick();
        onTap();
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: ArtisanPalette.woodEdge, width: 1.5),
          boxShadow: const [
            BoxShadow(
                color: Colors.black87, blurRadius: 8, offset: Offset(0, 3)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CustomPaint(
            painter: const WoodSlabPainter(seed: 7),
            child: Icon(icon, color: ArtisanPalette.bone, size: size * 0.5),
          ),
        ),
      ),
    );
  }
}

/// Sliding wooden peg in a dovetail slot (settings toggle).
class CarvedToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const CarvedToggle(
      {super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        AudioService.instance.uiClick();
        onChanged(!value);
      },
      child: Container(
        width: 64,
        height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          color: const Color(0xFF120A05),
          border: Border.all(color: ArtisanPalette.woodEdge, width: 1.5),
          boxShadow: const [
            BoxShadow(
                color: Colors.black87, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              alignment:
                  value ? Alignment.centerRight : Alignment.centerLeft,
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutBack,
              child: Container(
                width: 40,
                height: 28,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: value
                        ? [
                            ArtisanPalette.emberSoft,
                            ArtisanPalette.amber,
                            ArtisanPalette.amberLo
                          ]
                        : [
                            const Color(0xFF8A6F52),
                            ArtisanPalette.quartz,
                            ArtisanPalette.quartzLo
                          ],
                  ),
                  boxShadow: [
                    const BoxShadow(
                        color: Colors.black54,
                        blurRadius: 4,
                        offset: Offset(0, 2)),
                    if (value)
                      BoxShadow(
                        color: ArtisanPalette.ember.withValues(alpha: 0.5),
                        blurRadius: 8,
                      ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.25),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Volume slider: notched rod with a glass-stone knob.
class NotchedSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final StoneKind knobKind;

  const NotchedSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.knobKind = StoneKind.amber,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        return GestureDetector(
          onHorizontalDragUpdate: (d) =>
              onChanged((d.localPosition.dx / w).clamp(0.0, 1.0)),
          onTapDown: (d) =>
              onChanged((d.localPosition.dx / w).clamp(0.0, 1.0)),
          child: SizedBox(
            height: 40,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Rod.
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: const Color(0xFF120A05),
                    border:
                        Border.all(color: ArtisanPalette.woodEdge, width: 1),
                  ),
                ),
                // Notches.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (var i = 0; i < 9; i++)
                      Container(
                          width: 2,
                          height: 6,
                          color: ArtisanPalette.brass.withValues(alpha: 0.4)),
                  ],
                ),
                // Fill.
                FractionallySizedBox(
                  widthFactor: value.clamp(0.0, 1.0),
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      gradient: const LinearGradient(colors: [
                        ArtisanPalette.brass,
                        ArtisanPalette.amber
                      ]),
                    ),
                  ),
                ),
                // Glass-stone knob.
                Positioned(
                  left: (w - 30) * value.clamp(0.0, 1.0),
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: CustomPaint(
                        painter: StonePainter(kind: knobKind, seed: 3)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Bot difficulty as three carved beads (Calm / Sharp / Master).
class DifficultyBeads extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelected;
  final List<String> labels;

  const DifficultyBeads({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: GestureDetector(
              onTap: () {
                AudioService.instance.uiClick();
                onSelected(i);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: i == selected
                        ? ArtisanPalette.brass
                        : ArtisanPalette.woodEdge,
                    width: i == selected ? 2 : 1.2,
                  ),
                  boxShadow: [
                    const BoxShadow(
                        color: Colors.black87,
                        blurRadius: 6,
                        offset: Offset(0, 3)),
                    if (i == selected)
                      BoxShadow(
                        color: ArtisanPalette.ember.withValues(alpha: 0.3),
                        blurRadius: 10,
                      ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: CustomPaint(
                    painter: WoodSlabPainter(
                      top: i == selected
                          ? const Color(0xFF6B4426)
                          : ArtisanPalette.mahoganyLight,
                      mid: ArtisanPalette.walnutDark,
                      bottom: ArtisanPalette.walnutDeep,
                      seed: 100 + i,
                      radius: 18,
                    ),
                    child: Center(
                      child: Text(labels[i],
                          style: ArtisanType.button(size: 14)),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A single polished glass stone.
class GlassStone extends StatelessWidget {
  final StoneKind kind;
  final double size;
  final int seed;

  const GlassStone(
      {super.key, required this.kind, this.size = 18, this.seed = 0});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: StonePainter(kind: kind, seed: seed)),
    );
  }
}

/// Player name plate with mineral dot, name and engraved count plaque.
/// The active player's plate glows with a warm ember dot.
class PlayerPlate extends StatelessWidget {
  final String name;
  final String mineral;
  final StoneKind dotKind;
  final int count;
  final bool active;
  final bool reversed;

  const PlayerPlate({
    super.key,
    required this.name,
    required this.mineral,
    required this.dotKind,
    required this.count,
    required this.active,
    this.reversed = false,
  });

  @override
  Widget build(BuildContext context) {
    final inner = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            GlassStone(kind: dotKind, size: 20, seed: 9),
            if (active)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: ArtisanPalette.ember.withValues(alpha: 0.8),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(name,
                style: ArtisanType.bodyText(
                    size: 14, color: ArtisanPalette.bone)),
            Text(mineral,
                style: ArtisanType.label(size: 9)),
          ],
        ),
        const SizedBox(width: 10),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF7EFE1), Color(0xFFDFD1BC)],
            ),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black54, blurRadius: 3, offset: Offset(0, 2)),
            ],
          ),
          child: Text('$count', style: ArtisanType.count(size: 14)),
        ),
      ],
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? ArtisanPalette.brass : ArtisanPalette.woodEdge,
          width: active ? 2 : 1.2,
        ),
        boxShadow: [
          const BoxShadow(
              color: Colors.black87, blurRadius: 8, offset: Offset(0, 3)),
          if (active)
            BoxShadow(
              color: ArtisanPalette.ember.withValues(alpha: 0.25),
              blurRadius: 12,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: CustomPaint(
          painter: const WoodSlabPainter(seed: 21),
          child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: reversed
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [Expanded(child: inner)],
                    )
                  : inner),
        ),
      ),
    );
  }
}

/// Carved turn banner strip.
class TurnBanner extends StatelessWidget {
  final String text;

  const TurnBanner({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ArtisanPalette.woodEdge, width: 1.2),
        boxShadow: const [
          BoxShadow(
              color: Colors.black87, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CustomPaint(
          painter: const WoodSlabPainter(
              top: Color(0xFF4A2E1A),
              mid: Color(0xFF33200F),
              bottom: Color(0xFF201105),
              seed: 55,
              radius: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: ArtisanType.bodyText(size: 13.5),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small engraved label tag (e.g. "YOUR PITS (4)").
class EngravedTag extends StatelessWidget {
  final String text;

  const EngravedTag({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: const Color(0xFF120A05),
        border: Border.all(
            color: ArtisanPalette.brass.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(text, style: ArtisanType.label(size: 9)),
    );
  }
}

/// Settings row: label + subtitle + trailing control.
class SettingRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget trailing;

  const SettingRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: ArtisanType.bodyText(size: 15)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: ArtisanType.label(size: 10)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
