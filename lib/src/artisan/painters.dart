import 'dart:math';
import 'package:flutter/material.dart';
import 'palette.dart';

/// Pseudo-3D physical materials for Artisan Mancala, painted from the Stitch
/// design system's CSS (wood slabs, concave pits, glass stones, vignette).

/// Oiled walnut/mahogany slab with directional grain and chisel tooling.
class WoodSlabPainter extends CustomPainter {
  final Color top;
  final Color mid;
  final Color bottom;
  final double radius;
  final int seed;
  final bool horizontalGrain;

  const WoodSlabPainter({
    this.top = ArtisanPalette.mahoganyLight,
    this.mid = ArtisanPalette.walnutDark,
    this.bottom = ArtisanPalette.walnutDeep,
    this.radius = 14,
    this.seed = 1,
    this.horizontalGrain = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect =
        RRect.fromRectAndRadius(rect, Radius.circular(radius));

    // Base: warm top light falling to deep shadow (sunlight from upper-left).
    final base = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [top, mid, bottom],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(rect);
    canvas.drawRRect(rrect, base);

    // Grain: long soft streaks with slight waviness, low alpha.
    final rng = Random(seed);
    final grainPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final lines = (size.height / 26).ceil().clamp(6, 16);
    for (var l = 0; l < lines; l++) {
      final y0 = (l + rng.nextDouble() * 0.7) / lines * size.height;
      final amp = 2.0 + rng.nextDouble() * 4.0;
      final phase = rng.nextDouble() * 2 * pi;
      final alpha = 0.05 + rng.nextDouble() * 0.08;
      grainPaint
        ..color = (rng.nextBool() ? Colors.black : const Color(0xFFFFD9A8))
            .withValues(alpha: alpha)
        ..strokeWidth = 0.8 + rng.nextDouble() * 1.6;
      final path = Path()..moveTo(-8, y0);
      for (var x = 0.0; x <= size.width + 16; x += 24) {
        path.lineTo(x, y0 + sin(x / 60 + phase) * amp);
      }
      canvas.save();
      canvas.clipRRect(rrect);
      if (horizontalGrain) {
        canvas.translate(size.width / 2, size.height / 2);
        canvas.rotate(pi / 2);
        canvas.translate(-size.height / 2, -size.width / 2);
      }
      canvas.drawPath(path, grainPaint);
      canvas.restore();
    }

    // Chisel tooling: a few short diagonal nicks.
    final nickPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.2
      ..color = Colors.black.withValues(alpha: 0.10);
    for (var k = 0; k < 5; k++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      canvas.save();
      canvas.clipRRect(rrect);
      canvas.drawLine(Offset(x, y), Offset(x + 7, y + 4), nickPaint);
      canvas.restore();
    }

    // Bevel: top-left light edge, bottom-right dark edge.
    final bevel = RRect.fromRectAndRadius(
        rect.deflate(0.75), Radius.circular(radius));
    canvas.drawRRect(
        bevel,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0x66FFB786),
              Color(0x00000000),
              Color(0x99000000),
            ],
            stops: [0.0, 0.5, 1.0],
          ).createShader(rect));
  }

  @override
  bool shouldRepaint(covariant WoodSlabPainter old) =>
      old.seed != seed ||
      old.top != top ||
      old.radius != radius ||
      old.horizontalGrain != horizontalGrain;
}

/// A genuinely concave pit: sunken cavity with inner shadow, ambient
/// occlusion at the bottom rim and a faint warm bounce from below.
class PitPainter extends CustomPainter {
  final bool active;
  final double pulse; // 0..1 ember breathing animation

  const PitPainter({this.active = false, this.pulse = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect =
        RRect.fromRectAndRadius(rect, Radius.circular(size.shortestSide / 2));

    // Cavity: near-black core fading slightly toward the rim.
    canvas.drawRRect(
        rrect,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(0, -0.35),
            radius: 0.95,
            colors: const [
              Color(0xFF150A04),
              ArtisanPalette.pitInner,
              Color(0xFF060302),
            ],
            stops: const [0.0, 0.55, 1.0],
          ).createShader(rect));

    // Inner shadow: dark crescent across the top (sunlight blocked by rim).
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRRect(
        rrect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.center,
            colors: [
              Colors.black.withValues(alpha: 0.85),
              Colors.black.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.55],
          ).createShader(rect));
    // Warm bounce on the lower rim.
    canvas.drawRRect(
        rrect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.center,
            colors: [
              ArtisanPalette.ember.withValues(alpha: 0.16),
              ArtisanPalette.ember.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.4],
          ).createShader(rect));
    canvas.restore();

    // Rim: thin dark edge with a top light catch.
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            rect.deflate(0.5), Radius.circular(size.shortestSide / 2)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = const Color(0xFF1A0E06));

    if (active) {
      // Breathing ember ring on playable pits.
      final glow = 0.45 + 0.35 * pulse;
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              rect.deflate(1.0), Radius.circular(size.shortestSide / 2)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2
            ..color = ArtisanPalette.ember.withValues(alpha: glow));
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              rect.inflate(2.0 + 3 * pulse),
              Radius.circular(size.shortestSide / 2)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..color = ArtisanPalette.ember.withValues(alpha: 0.35 * pulse)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    }
  }

  @override
  bool shouldRepaint(covariant PitPainter old) =>
      old.active != active || old.pulse != pulse;
}

/// Polished translucent glass stone: radial mineral gradient, bright
/// specular highlight, soft contact shadow.
class StonePainter extends CustomPainter {
  final StoneKind kind;
  final int seed;

  const StonePainter({required this.kind, this.seed = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2;
    final cols = ArtisanPalette.stoneColors(kind);

    // Contact shadow.
    canvas.drawCircle(
        c + Offset(0, r * 0.22),
        r * 0.96,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));

    // Mineral body: light pools upper-left, deep color lower-right.
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.35, -0.4),
            radius: 1.05,
            colors: cols,
            stops: const [0.0, 0.45, 1.0],
          ).createShader(Rect.fromCircle(center: c, radius: r)));

    // Inner depth: darker crescent bottom-right (translucency).
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(0.55, 0.6),
            radius: 0.8,
            colors: [
              cols[2].withValues(alpha: 0.55),
              cols[2].withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromCircle(center: c, radius: r)));

    // Crisp specular highlight, offset with the sun (upper-left).
    final rng = Random(seed * 97 + 13);
    final hx = c.dx - r * (0.28 + rng.nextDouble() * 0.1);
    final hy = c.dy - r * (0.32 + rng.nextDouble() * 0.08);
    canvas.drawCircle(
        Offset(hx, hy),
        r * 0.30,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.75)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
    canvas.drawCircle(
        Offset(hx - r * 0.05, hy - r * 0.06),
        r * 0.13,
        Paint()..color = Colors.white.withValues(alpha: 0.9));

    // Rim light: thin bright arc on the sun side.
    canvas.drawArc(
        Rect.fromCircle(center: c, radius: r - 0.8),
        pi * 1.05,
        pi * 0.75,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1
          ..color = Colors.white.withValues(alpha: 0.5));
  }

  @override
  bool shouldRepaint(covariant StonePainter old) =>
      old.kind != kind || old.seed != seed;
}

/// Warm vignette darkening the screen perimeter (sunlit courtyard feel).
class VignettePainter extends CustomPainter {
  const VignettePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
            center: Alignment.center,
            radius: 0.85,
            colors: [
              Colors.transparent,
              ArtisanPalette.clayDeep.withValues(alpha: 0.55),
            ],
            stops: const [0.55, 1.0],
          ).createShader(rect));
    // Faint warm bloom at the top, like afternoon sun.
    canvas.drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(0, -0.9),
            radius: 0.9,
            colors: [
              ArtisanPalette.ember.withValues(alpha: 0.10),
              ArtisanPalette.ember.withValues(alpha: 0.0),
            ],
          ).createShader(rect));
  }

  @override
  bool shouldRepaint(covariant VignettePainter old) => false;
}

/// Hand-pounded brass rivet for plaque corners.
class RivetPainter extends CustomPainter {
  const RivetPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2;
    canvas.drawCircle(
        c + const Offset(0, 1),
        r,
        Paint()..color = Colors.black.withValues(alpha: 0.5));
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-0.35, -0.4),
            radius: 1.1,
            colors: [
              Color(0xFFE8C876),
              ArtisanPalette.brass,
              Color(0xFF6E521F),
            ],
            stops: [0.0, 0.55, 1.0],
          ).createShader(Rect.fromCircle(center: c, radius: r)));
    // Hammer dents.
    final rng = Random(5);
    for (var k = 0; k < 3; k++) {
      canvas.drawCircle(
          c +
              Offset((rng.nextDouble() - 0.5) * r, (rng.nextDouble() - 0.5) * r),
          r * 0.16,
          Paint()..color = Colors.black.withValues(alpha: 0.18));
    }
  }

  @override
  bool shouldRepaint(covariant RivetPainter old) => false;
}
