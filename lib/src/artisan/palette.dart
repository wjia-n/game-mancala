import 'package:flutter/material.dart';

/// "Artisan Mancala" design system — hand-carved African artisan woodwork.
/// Source of truth: Stitch project 10338186486160255320 (Mancala Game UI).
/// Dark walnut/mahogany, brass rivets, polished glass stones, warm sunlight.
class ArtisanPalette {
  // Backgrounds
  static const Color clay = Color(0xFF1E140C); // screen background
  static const Color clayDeep = Color(0xFF150C07); // vignette / deep shadow
  static const Color pitInner = Color(0xFF0D0603); // concave pit cavity

  // Wood
  static const Color walnutDark = Color(0xFF3B2416); // board base, panels
  static const Color walnutDeep = Color(0xFF2E1C0E);
  static const Color mahogany = Color(0xFF5C3A21); // board body, panels
  static const Color mahoganyLight = Color(0xFF442A18);
  static const Color woodEdge = Color(0xFF4A301B); // slab borders

  // Metal + light accents
  static const Color brass = Color(0xFFB08D3C); // rivets, plaques, accents
  static const Color brassLight = Color(0xFFD9B25F);
  static const Color ember = Color(0xFFE58235); // active-pit glow, warm light
  static const Color emberSoft = Color(0xFFFFB067);

  // Glass stones — player 0 (YOU)
  static const Color amber = Color(0xFFD98E2B);
  static const Color amberHi = Color(0xFFFFC076);
  static const Color amberLo = Color(0xFF8A4806);
  static const Color garnet = Color(0xFF7A2E2E);
  static const Color garnetHi = Color(0xFFE26363);
  static const Color garnetLo = Color(0xFF3A0D0D);

  // Glass stones — player 1 (BOT)
  static const Color jade = Color(0xFF4F7A5B);
  static const Color jadeHi = Color(0xFF9DDDB0);
  static const Color jadeLo = Color(0xFF193822);
  static const Color quartz = Color(0xFF7D695C);
  static const Color quartzHi = Color(0xFFCDBDAF);
  static const Color quartzLo = Color(0xFF36281E);

  // Text
  static const Color bone = Color(0xFFF2E7D5); // engraved text on dark wood
  static const Color boneDim = Color(0xFFCBB896);
  static const Color walnutInk = Color(0xFF3B2311); // text on bone plaques

  /// Glass-stone gradient stops for a stone of [kind].
  static List<Color> stoneColors(StoneKind kind) => switch (kind) {
        StoneKind.amber => [amberHi, amber, amberLo],
        StoneKind.garnet => [garnetHi, garnet, garnetLo],
        StoneKind.jade => [jadeHi, jade, jadeLo],
        StoneKind.quartz => [quartzHi, quartz, quartzLo],
      };
}

enum StoneKind { amber, garnet, jade, quartz }

/// Deterministic assorted glass stones per player: mostly their primary
/// mineral with occasional accents, so the board feels hand-set.
StoneKind stoneKindFor(int player, int pitIndex, int ordinal) {
  final h = (pitIndex * 31 + ordinal * 17 + player * 7) % 10;
  if (player == 0) {
    return h < 7 ? StoneKind.amber : StoneKind.garnet;
  }
  return h < 7 ? StoneKind.jade : StoneKind.quartz;
}

/// Artisan typography: hand-carved serif display + humanist sans body.
class ArtisanType {
  static const String display = 'PlayfairDisplay';
  static const String body = 'Manrope';

  static TextStyle plaqueTitle({double size = 30}) => TextStyle(
        fontFamily: display,
        fontWeight: FontWeight.w900,
        fontSize: size,
        letterSpacing: 4,
        color: ArtisanPalette.bone,
        shadows: const [
          Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 3),
          Shadow(
              color: Color(0x66FFB067), offset: Offset(0, -1), blurRadius: 1),
        ],
      );

  static TextStyle sectionTitle({double size = 15}) => TextStyle(
        fontFamily: display,
        fontWeight: FontWeight.w700,
        fontSize: size,
        letterSpacing: 2.5,
        color: ArtisanPalette.bone,
      );

  static TextStyle label({double size = 11}) => TextStyle(
        fontFamily: body,
        fontWeight: FontWeight.w800,
        fontSize: size,
        letterSpacing: 2.2,
        color: ArtisanPalette.boneDim,
      );

  static TextStyle bodyText({double size = 14, Color? color}) => TextStyle(
        fontFamily: body,
        fontWeight: FontWeight.w600,
        fontSize: size,
        color: color ?? ArtisanPalette.bone,
        height: 1.45,
      );

  static TextStyle button({double size = 16}) => TextStyle(
        fontFamily: body,
        fontWeight: FontWeight.w800,
        fontSize: size,
        letterSpacing: 1.6,
        color: ArtisanPalette.bone,
        shadows: const [
          Shadow(color: Colors.black54, offset: Offset(0, 1), blurRadius: 2),
        ],
      );

  static TextStyle count({double size = 13}) => TextStyle(
        fontFamily: body,
        fontWeight: FontWeight.w800,
        fontSize: size,
        color: ArtisanPalette.walnutInk,
      );
}
