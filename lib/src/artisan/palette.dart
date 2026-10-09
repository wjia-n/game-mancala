import 'package:flutter/material.dart';
import '../theme/mancala_themes.dart';

/// "Artisan Mancala" design system — hand-carved African artisan woodwork.
/// Source of truth: Stitch project 10338186486160255320 (Mancala Game UI).
/// Dark walnut/mahogany, brass rivets, polished glass stones, warm sunlight.
///
/// The palette is theme-driven: [apply] installs the active [MancalaThemeDef],
/// [StoneStyleDef] and [BoardAccentDef] into these static fields. Every widget
/// reads the fields at build time, so switching theme re-skins the whole app.
/// Field names are stable so existing call sites keep working unchanged.
class ArtisanPalette {
  // Backgrounds
  static Color clay = const Color(0xFF1E140C); // screen background
  static Color clayDeep = const Color(0xFF150C07); // vignette / deep shadow
  static Color pitInner = const Color(0xFF0D0603); // concave pit cavity

  // Wood
  static Color walnutDark = const Color(0xFF3B2416); // board base, panels
  static Color walnutDeep = const Color(0xFF2E1C0E);
  static Color mahogany = const Color(0xFF5C3A21); // board body, panels
  static Color mahoganyLight = const Color(0xFF442A18);
  static Color woodEdge = const Color(0xFF4A301B); // slab borders

  // Metal + light accents (overridden by the board-accent catalog)
  static Color brass = const Color(0xFFB08D3C); // rivets, plaques, accents
  static Color brassLight = const Color(0xFFD9B25F);
  static Color ember = const Color(0xFFE58235); // active-pit glow, warm light
  static Color emberSoft = const Color(0xFFFFB067);

  // Glass stones — player 0 (kept as aliases; the stone style owns the
  // actual gradient stops below).
  static Color amber = const Color(0xFFD98E2B);
  static Color amberHi = const Color(0xFFFFC076);
  static Color amberLo = const Color(0xFF8A4806);
  static Color garnet = const Color(0xFF7A2E2E);
  static Color garnetHi = const Color(0xFFE26363);
  static Color garnetLo = const Color(0xFF3A0D0D);

  // Glass stones — player 1
  static Color jade = const Color(0xFF4F7A5B);
  static Color jadeHi = const Color(0xFF9DDDB0);
  static Color jadeLo = const Color(0xFF193822);
  static Color quartz = const Color(0xFF7D695C);
  static Color quartzHi = const Color(0xFFCDBDAF);
  static Color quartzLo = const Color(0xFF36281E);

  // Text
  static Color bone = const Color(0xFFF2E7D5); // engraved text on dark wood
  static Color boneDim = const Color(0xFFCBB896);
  static Color walnutInk = const Color(0xFF3B2311); // text on bone plaques

  /// Gradient stops per [StoneKind], installed by the active stone style.
  /// Index order matches StoneKind: amber, garnet, jade, quartz.
  static List<List<Color>> _stoneStops = [
    [const Color(0xFFFFC076), const Color(0xFFD98E2B), const Color(0xFF8A4806)],
    [const Color(0xFFE26363), const Color(0xFF7A2E2E), const Color(0xFF3A0D0D)],
    [const Color(0xFF9DDDB0), const Color(0xFF4F7A5B), const Color(0xFF193822)],
    [const Color(0xFFCDBDAF), const Color(0xFF7D695C), const Color(0xFF36281E)],
  ];

  /// Glass-stone gradient stops for a stone of [kind].
  static List<Color> stoneColors(StoneKind kind) => _stoneStops[kind.index];

  /// Installs a theme + stone style + board accent into the palette.
  static void apply(
      MancalaThemeDef theme, StoneStyleDef stones, BoardAccentDef accent) {
    clay = theme.clay;
    clayDeep = theme.clayDeep;
    pitInner = theme.pitInner;
    walnutDark = theme.woodDark;
    walnutDeep = theme.woodDeep;
    mahogany = theme.mahogany;
    mahoganyLight = theme.mahoganyLight;
    woodEdge = theme.woodEdge;
    ember = theme.ember;
    emberSoft = theme.emberSoft;
    bone = theme.bone;
    boneDim = theme.boneDim;
    walnutInk = theme.walnutInk;

    // Board accent metal overrides the brass family.
    brass = accent.accent;
    brassLight = accent.accentLight;

    // Stone style owns the glass gradient stops. Aliases follow the main
    // minerals so legacy references (toggles, sliders) stay coherent.
    _stoneStops = [stones.p0, stones.p0Alt, stones.p1, stones.p1Alt];
    amberHi = stones.p0[0];
    amber = stones.p0[1];
    amberLo = stones.p0[2];
    garnetHi = stones.p0Alt[0];
    garnet = stones.p0Alt[1];
    garnetLo = stones.p0Alt[2];
    jadeHi = stones.p1[0];
    jade = stones.p1[1];
    jadeLo = stones.p1[2];
    quartzHi = stones.p1Alt[0];
    quartz = stones.p1Alt[1];
    quartzLo = stones.p1Alt[2];
  }
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
