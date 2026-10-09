import 'package:flutter/material.dart';

/// Theme, stone-style and board-accent catalogs for Mancala.
///
/// Everything stays inside the Artisan Mancala material world (oiled woods,
/// hand-pounded metals, bone ivory, polished glass stones, warm sunlight).
/// Variety comes from different woods, metal accents and jewel-tone stones —
/// never neon, never flat, never generic.

/// A full board color scheme: background, woods, pit cavities, text ink.
class MancalaThemeDef {
  final String id;
  final String name;
  final String woodLine; // one-line flavor, shown in the picker
  final Color clay; // screen background
  final Color clayDeep; // vignette / deep shadow
  final Color pitInner; // concave pit cavity
  final Color woodDark; // board base, panels
  final Color woodDeep;
  final Color mahogany; // board body
  final Color mahoganyLight;
  final Color woodEdge; // slab borders
  final Color ember; // active-pit glow
  final Color emberSoft;
  final Color bone; // engraved text on dark wood
  final Color boneDim;
  final Color walnutInk; // text on bone plaques

  const MancalaThemeDef({
    required this.id,
    required this.name,
    required this.woodLine,
    required this.clay,
    required this.clayDeep,
    required this.pitInner,
    required this.woodDark,
    required this.woodDeep,
    required this.mahogany,
    required this.mahoganyLight,
    required this.woodEdge,
    required this.ember,
    required this.emberSoft,
    required this.bone,
    required this.boneDim,
    required this.walnutInk,
  });
}

/// A seed/stone visual style: two player minerals, each with a main and an
/// accent tone (each tone = [highlight, mid, shadow] gradient stops).
class StoneStyleDef {
  final String id;
  final String name;
  final String blurb;
  final List<Color> p0; // player 0 main mineral
  final List<Color> p0Alt; // player 0 accent mineral
  final List<Color> p1; // player 1 main mineral
  final List<Color> p1Alt; // player 1 accent mineral

  const StoneStyleDef({
    required this.id,
    required this.name,
    required this.blurb,
    required this.p0,
    required this.p0Alt,
    required this.p1,
    required this.p1Alt,
  });
}

/// A board accent metal: rivets, borders, slider fills, active highlights.
class BoardAccentDef {
  final String id;
  final String name;
  final Color accent;
  final Color accentLight;
  final Color accentDark;

  const BoardAccentDef({
    required this.id,
    required this.name,
    required this.accent,
    required this.accentLight,
    required this.accentDark,
  });
}

class MancalaThemes {
  /// First 4 are the FREE starter themes. The rest are PRO.
  static const List<String> freeThemeIds = [
    'heirloom',
    'mahogany',
    'emberwood',
    'forest',
  ];

  static const List<MancalaThemeDef> all = [
    MancalaThemeDef(
      id: 'heirloom',
      name: 'Heirloom Walnut',
      woodLine: 'The classic — dark walnut, brass, warm sun',
      clay: Color(0xFF1E140C),
      clayDeep: Color(0xFF150C07),
      pitInner: Color(0xFF0D0603),
      woodDark: Color(0xFF3B2416),
      woodDeep: Color(0xFF2E1C0E),
      mahogany: Color(0xFF5C3A21),
      mahoganyLight: Color(0xFF442A18),
      woodEdge: Color(0xFF4A301B),
      ember: Color(0xFFE58235),
      emberSoft: Color(0xFFFFB067),
      bone: Color(0xFFF2E7D5),
      boneDim: Color(0xFFCBB896),
      walnutInk: Color(0xFF3B2311),
    ),
    MancalaThemeDef(
      id: 'mahogany',
      name: 'Royal Mahogany',
      woodLine: 'Deep red-brown mahogany, golden brass',
      clay: Color(0xFF221009),
      clayDeep: Color(0xFF170903),
      pitInner: Color(0xFF0F0502),
      woodDark: Color(0xFF4A1F14),
      woodDeep: Color(0xFF381408),
      mahogany: Color(0xFF6E2F1C),
      mahoganyLight: Color(0xFF522313),
      woodEdge: Color(0xFF5A2A16),
      ember: Color(0xFFE88B3A),
      emberSoft: Color(0xFFFFB96E),
      bone: Color(0xFFF8F1E2),
      boneDim: Color(0xFFD6BE98),
      walnutInk: Color(0xFF3B1F0E),
    ),
    MancalaThemeDef(
      id: 'emberwood',
      name: 'Emberwood',
      woodLine: 'Smoked oak with a warm ember heart',
      clay: Color(0xFF1C1310),
      clayDeep: Color(0xFF130B08),
      pitInner: Color(0xFF0B0605),
      woodDark: Color(0xFF3E2A1A),
      woodDeep: Color(0xFF2E1E10),
      mahogany: Color(0xFF5E3B20),
      mahoganyLight: Color(0xFF472B16),
      woodEdge: Color(0xFF4E3018),
      ember: Color(0xFFF0752B),
      emberSoft: Color(0xFFFFA95E),
      bone: Color(0xFFF5E9D2),
      boneDim: Color(0xFFCEB48E),
      walnutInk: Color(0xFF3A2312),
    ),
    MancalaThemeDef(
      id: 'forest',
      name: 'Forest Lodge',
      woodLine: 'Pine lodge timber, mossy undertones',
      clay: Color(0xFF181410),
      clayDeep: Color(0xFF100C08),
      pitInner: Color(0xFF0A0805),
      woodDark: Color(0xFF3E3226),
      woodDeep: Color(0xFF2E251A),
      mahogany: Color(0xFF5D4C36),
      mahoganyLight: Color(0xFF463926),
      woodEdge: Color(0xFF52402A),
      ember: Color(0xFFE89B3C),
      emberSoft: Color(0xFFFFC276),
      bone: Color(0xFFF1EAD8),
      boneDim: Color(0xFFC9BB94),
      walnutInk: Color(0xFF36280F),
    ),
    MancalaThemeDef(
      id: 'ebony',
      name: 'Ebony & Silver',
      woodLine: 'Black ebony, cool silver rivets',
      clay: Color(0xFF121214),
      clayDeep: Color(0xFF0A0A0C),
      pitInner: Color(0xFF050506),
      woodDark: Color(0xFF1A1A1E),
      woodDeep: Color(0xFF121214),
      mahogany: Color(0xFF2A2A30),
      mahoganyLight: Color(0xFF33333C),
      woodEdge: Color(0xFF3A3A44),
      ember: Color(0xFFE8A04C),
      emberSoft: Color(0xFFFFC57E),
      bone: Color(0xFFF2EEE4),
      boneDim: Color(0xFFC4BCA8),
      walnutInk: Color(0xFF2A2A26),
    ),
    MancalaThemeDef(
      id: 'cherry',
      name: 'Cherrywood',
      woodLine: 'Polished cherry, honeyed highlights',
      clay: Color(0xFF221210),
      clayDeep: Color(0xFF160B08),
      pitInner: Color(0xFF0D0504),
      woodDark: Color(0xFF5A2A1A),
      woodDeep: Color(0xFF441F12),
      mahogany: Color(0xFF7C3F24),
      mahoganyLight: Color(0xFF5E301A),
      woodEdge: Color(0xFF63351D),
      ember: Color(0xFFF08A35),
      emberSoft: Color(0xFFFFB265),
      bone: Color(0xFFF7EFE0),
      boneDim: Color(0xFFD4BC96),
      walnutInk: Color(0xFF3E2110),
    ),
    MancalaThemeDef(
      id: 'sandalwood',
      name: 'Sandalwood',
      woodLine: 'Pale fragrant sandalwood, daybreak light',
      clay: Color(0xFF241A10),
      clayDeep: Color(0xFF181006),
      pitInner: Color(0xFF100A04),
      woodDark: Color(0xFF8A6A42),
      woodDeep: Color(0xFF6B5232),
      mahogany: Color(0xFFAA8757),
      mahoganyLight: Color(0xFFC49A62),
      woodEdge: Color(0xFF7A5F3A),
      ember: Color(0xFFDD7A2E),
      emberSoft: Color(0xFFFFA75E),
      bone: Color(0xFF2E2118),
      boneDim: Color(0xFF5E4C38),
      walnutInk: Color(0xFF2E2118),
    ),
    MancalaThemeDef(
      id: 'olive',
      name: 'Olive Grove',
      woodLine: 'Weathered olive wood, grove shade',
      clay: Color(0xFF171410),
      clayDeep: Color(0xFF0F0C08),
      pitInner: Color(0xFF090805),
      woodDark: Color(0xFF3F4226),
      woodDeep: Color(0xFF30331C),
      mahogany: Color(0xFF5E6238),
      mahoganyLight: Color(0xFF484C2A),
      woodEdge: Color(0xFF54522E),
      ember: Color(0xFFE89B3C),
      emberSoft: Color(0xFFFFC276),
      bone: Color(0xFFF1EAD8),
      boneDim: Color(0xFFC9BB94),
      walnutInk: Color(0xFF36300F),
    ),
    MancalaThemeDef(
      id: 'rosewood',
      name: 'Rosewood',
      woodLine: 'Dark rosewood, wine-dark grain',
      clay: Color(0xFF1D1014),
      clayDeep: Color(0xFF130A0D),
      pitInner: Color(0xFF0B0507),
      woodDark: Color(0xFF3F1D24),
      woodDeep: Color(0xFF30151B),
      mahogany: Color(0xFF5E2C36),
      mahoganyLight: Color(0xFF472129),
      woodEdge: Color(0xFF53262F),
      ember: Color(0xFFE88B4A),
      emberSoft: Color(0xFFFFB87A),
      bone: Color(0xFFF5EFE0),
      boneDim: Color(0xFFD0BA98),
      walnutInk: Color(0xFF3A1E12),
    ),
    MancalaThemeDef(
      id: 'goldenoak',
      name: 'Golden Oak',
      woodLine: 'Honeyed oak, harvest sunlight',
      clay: Color(0xFF231A0E),
      clayDeep: Color(0xFF171006),
      pitInner: Color(0xFF0F0A04),
      woodDark: Color(0xFF7A5A24),
      woodDeep: Color(0xFF5E461C),
      mahogany: Color(0xFF9A7534),
      mahoganyLight: Color(0xFFB8894A),
      woodEdge: Color(0xFF6E5220),
      ember: Color(0xFFDE7F2E),
      emberSoft: Color(0xFFFFAB60),
      bone: Color(0xFF2E2118),
      boneDim: Color(0xFF5E4E36),
      walnutInk: Color(0xFF2E2118),
    ),
    MancalaThemeDef(
      id: 'slate',
      name: 'Slate & Brass',
      woodLine: 'Driftwood grey, brass fittings',
      clay: Color(0xFF14161A),
      clayDeep: Color(0xFF0C0D10),
      pitInner: Color(0xFF060708),
      woodDark: Color(0xFF2E3440),
      woodDeep: Color(0xFF232833),
      mahogany: Color(0xFF434C5E),
      mahoganyLight: Color(0xFF525B70),
      woodEdge: Color(0xFF3E4656),
      ember: Color(0xFFE8A04C),
      emberSoft: Color(0xFFFFC57E),
      bone: Color(0xFFECEFF4),
      boneDim: Color(0xFFBEC6D4),
      walnutInk: Color(0xFF2A2E38),
    ),
    MancalaThemeDef(
      id: 'burgundy',
      name: 'Burgundy Velvet',
      woodLine: 'Wine-stained wood, candlelight',
      clay: Color(0xFF1E1016),
      clayDeep: Color(0xFF140A0F),
      pitInner: Color(0xFF0C0509),
      woodDark: Color(0xFF3A1A2E),
      woodDeep: Color(0xFF2C1422),
      mahogany: Color(0xFF552842),
      mahoganyLight: Color(0xFF421F33),
      woodEdge: Color(0xFF4C2438),
      ember: Color(0xFFE89B4A),
      emberSoft: Color(0xFFFFC07A),
      bone: Color(0xFFF8F1E2),
      boneDim: Color(0xFFD4BC9A),
      walnutInk: Color(0xFF3A2012),
    ),
    MancalaThemeDef(
      id: 'teal',
      name: 'Teal Atelier',
      woodLine: 'Lagoon-teal timber, brass inlay',
      clay: Color(0xFF101816),
      clayDeep: Color(0xFF0A100E),
      pitInner: Color(0xFF050907),
      woodDark: Color(0xFF1E3A38),
      woodDeep: Color(0xFF162C2A),
      mahogany: Color(0xFF2E5654),
      mahoganyLight: Color(0xFF3A6866),
      woodEdge: Color(0xFF2A4E4C),
      ember: Color(0xFFE89B3C),
      emberSoft: Color(0xFFFFC276),
      bone: Color(0xFFF0EDE2),
      boneDim: Color(0xFFC2BBA2),
      walnutInk: Color(0xFF24302A),
    ),
    MancalaThemeDef(
      id: 'winecellar',
      name: 'Wine Cellar',
      woodLine: 'Barrel oak, cellar dusk',
      clay: Color(0xFF191016),
      clayDeep: Color(0xFF100A0E),
      pitInner: Color(0xFF090509),
      woodDark: Color(0xFF2E1A2E),
      woodDeep: Color(0xFF231422),
      mahogany: Color(0xFF462844),
      mahoganyLight: Color(0xFF563354),
      woodEdge: Color(0xFF40243E),
      ember: Color(0xFFE89B4A),
      emberSoft: Color(0xFFFFC07A),
      bone: Color(0xFFF5EFE0),
      boneDim: Color(0xFFCFB898),
      walnutInk: Color(0xFF382012),
    ),
    MancalaThemeDef(
      id: 'charcoal',
      name: 'Charcoal Club',
      woodLine: 'Charred timber, copper glow',
      clay: Color(0xFF121110),
      clayDeep: Color(0xFF0A0A09),
      pitInner: Color(0xFF050505),
      woodDark: Color(0xFF242424),
      woodDeep: Color(0xFF1B1B1B),
      mahogany: Color(0xFF383838),
      mahoganyLight: Color(0xFF464646),
      woodEdge: Color(0xFF33302A),
      ember: Color(0xFFE89B4A),
      emberSoft: Color(0xFFFFC07A),
      bone: Color(0xFFF0EBE0),
      boneDim: Color(0xFFC2BAA4),
      walnutInk: Color(0xFF2C2822),
    ),
    MancalaThemeDef(
      id: 'porcelain',
      name: 'Porcelain Parlor',
      woodLine: 'Ivory porcelain, cobalt brushwork',
      clay: Color(0xFF2A241C),
      clayDeep: Color(0xFF1C1812),
      pitInner: Color(0xFF12100B),
      woodDark: Color(0xFFE8E0D0),
      woodDeep: Color(0xFFD0C4AC),
      mahogany: Color(0xFFF2EAD8),
      mahoganyLight: Color(0xFFFFFFFF),
      woodEdge: Color(0xFFB8A888),
      ember: Color(0xFFD9762E),
      emberSoft: Color(0xFFFFA75E),
      bone: Color(0xFF2A2118),
      boneDim: Color(0xFF6E5E46),
      walnutInk: Color(0xFF2A2118),
    ),
  ];

  static MancalaThemeDef byId(String id, {MancalaThemeDef? custom}) {
    if (id == 'custom') return custom ?? all.first;
    return all.firstWhere((t) => t.id == id, orElse: () => all.first);
  }

  static bool isProTheme(String id) =>
      !freeThemeIds.contains(id) && id != 'custom';
}

/// Seed/stone visual styles. 0-3 = FREE, 4+ = PRO.
class StoneStyles {
  static const List<StoneStyleDef> all = [
    StoneStyleDef(
      id: 'amberjade',
      name: 'Amber & Jade',
      blurb: 'The classic pairing — honey amber, river jade',
      p0: [Color(0xFFFFC076), Color(0xFFD98E2B), Color(0xFF8A4806)],
      p0Alt: [Color(0xFFE26363), Color(0xFF7A2E2E), Color(0xFF3A0D0D)],
      p1: [Color(0xFF9DDDB0), Color(0xFF4F7A5B), Color(0xFF193822)],
      p1Alt: [Color(0xFFCDBDAF), Color(0xFF7D695C), Color(0xFF36281E)],
    ),
    StoneStyleDef(
      id: 'honeyopal',
      name: 'Honey & Opal',
      blurb: 'Golden honey against milky opal',
      p0: [Color(0xFFFFD98A), Color(0xFFE0A83C), Color(0xFF8A5E10)],
      p0Alt: [Color(0xFFFFE9C4), Color(0xFFD9A94E), Color(0xFF7A4E14)],
      p1: [Color(0xFFFFFFFF), Color(0xFFE8E0D0), Color(0xFF9A8E78)],
      p1Alt: [Color(0xFFF0EDE2), Color(0xFFCFC2A8), Color(0xFF6E6250)],
    ),
    StoneStyleDef(
      id: 'coppermoss',
      name: 'Copper & Moss',
      blurb: 'Hammered copper, deep forest moss',
      p0: [Color(0xFFF0A85E), Color(0xFFB87333), Color(0xFF5E3A14)],
      p0Alt: [Color(0xFFE8B06E), Color(0xFF9A5E28), Color(0xFF4E3010)],
      p1: [Color(0xFF9DBE8A), Color(0xFF4A6E3A), Color(0xFF1E3016)],
      p1Alt: [Color(0xFFB8CC9E), Color(0xFF5E7E46), Color(0xFF283A1C)],
    ),
    StoneStyleDef(
      id: 'garnetquartz',
      name: 'Garnet & Quartz',
      blurb: 'Wine-dark garnet, smoky quartz',
      p0: [Color(0xFFE26363), Color(0xFF7A2E2E), Color(0xFF3A0D0D)],
      p0Alt: [Color(0xFFD98E8E), Color(0xFF8E3E3E), Color(0xFF401414)],
      p1: [Color(0xFFCDBDAF), Color(0xFF7D695C), Color(0xFF36281E)],
      p1Alt: [Color(0xFFB8A894), Color(0xFF6E5B4C), Color(0xFF2E241A)],
    ),
    StoneStyleDef(
      id: 'obsidianpearl',
      name: 'Obsidian & Pearl',
      blurb: 'Volcanic glass against sea pearl',
      p0: [Color(0xFF8E94A8), Color(0xFF2A2E3E), Color(0xFF0A0C14)],
      p0Alt: [Color(0xFF6E7488), Color(0xFF1E2230), Color(0xFF080A10)],
      p1: [Color(0xFFFFFFFF), Color(0xFFF2EAD8), Color(0xFFA89E88)],
      p1Alt: [Color(0xFFF8F4E8), Color(0xFFE0D4BC), Color(0xFF948870)],
    ),
    StoneStyleDef(
      id: 'turquoisecoral',
      name: 'Turquoise & Coral',
      blurb: 'Desert turquoise, sun-baked coral',
      p0: [Color(0xFF9BE8DC), Color(0xFF3E9E90), Color(0xFF145E54)],
      p0Alt: [Color(0xFF8ED8CC), Color(0xFF348E80), Color(0xFF104E46)],
      p1: [Color(0xFFFFB09E), Color(0xFFD96E4E), Color(0xFF7A2E1A)],
      p1Alt: [Color(0xFFF0A08E), Color(0xFFC45E40), Color(0xFF6E2814)],
    ),
    StoneStyleDef(
      id: 'lapisivory',
      name: 'Lapis & Ivory',
      blurb: 'Deep lapis lazuli, carved ivory',
      p0: [Color(0xFF8EA8E8), Color(0xFF2E4E9E), Color(0xFF101E4E)],
      p0Alt: [Color(0xFF7E98D8), Color(0xFF28448E), Color(0xFF0E1A44)],
      p1: [Color(0xFFFFF6E4), Color(0xFFEFE0BC), Color(0xFFA8946E)],
      p1Alt: [Color(0xFFF8ECD2), Color(0xFFE2D0A6), Color(0xFF94805E)],
    ),
    StoneStyleDef(
      id: 'rubyemerald',
      name: 'Ruby & Emerald',
      blurb: 'Jewel-box ruby, vivid emerald',
      p0: [Color(0xFFFF7E8E), Color(0xFFC42E4E), Color(0xFF5E0E22)],
      p0Alt: [Color(0xFFE86E7E), Color(0xFFA42844), Color(0xFF540C1E)],
      p1: [Color(0xFF8EE8A8), Color(0xFF2E9E5E), Color(0xFF0E4E2A)],
      p1Alt: [Color(0xFF7ED898), Color(0xFF288E52), Color(0xFF0C4424)],
    ),
    StoneStyleDef(
      id: 'smokyrose',
      name: 'Smoky Rose',
      blurb: 'Smoked glass rose, ash grey',
      p0: [Color(0xFFE8A8B8), Color(0xFF9E5E6E), Color(0xFF4E2830)],
      p0Alt: [Color(0xFFD898A8), Color(0xFF8E525E), Color(0xFF442228)],
      p1: [Color(0xFFC8BCAE), Color(0xFF8E8474), Color(0xFF3E3830)],
      p1Alt: [Color(0xFFB8AC9E), Color(0xFF7E7464), Color(0xFF342E28)],
    ),
    StoneStyleDef(
      id: 'onyxgold',
      name: 'Onyx & Gold',
      blurb: 'Midnight onyx veined with gold',
      p0: [Color(0xFF9A94A8), Color(0xFF1A1A22), Color(0xFF050507)],
      p0Alt: [Color(0xFFD4AF37), Color(0xFF9A7B1E), Color(0xFF4E3A0E)],
      p1: [Color(0xFFF3DC8E), Color(0xFFC9A227), Color(0xFF6E5514)],
      p1Alt: [Color(0xFFE8CE7A), Color(0xFFB08D3C), Color(0xFF5E4A10)],
    ),
  ];

  /// Styles free players may use.
  static const freeCount = 4;
  static bool isPro(int index) => index >= freeCount;

  static StoneStyleDef byIndex(int i) =>
      all[i.clamp(0, all.length - 1)];
}

/// Board accent metals. 0-1 = FREE, 2+ = PRO.
class BoardAccents {
  static const List<BoardAccentDef> all = [
    BoardAccentDef(
      id: 'brass',
      name: 'Hand-pounded Brass',
      accent: Color(0xFFB08D3C),
      accentLight: Color(0xFFD9B25F),
      accentDark: Color(0xFF7A6128),
    ),
    BoardAccentDef(
      id: 'copper',
      name: 'Aged Copper',
      accent: Color(0xFFB87333),
      accentLight: Color(0xFFE09E5A),
      accentDark: Color(0xFF7E4F22),
    ),
    BoardAccentDef(
      id: 'silver',
      name: 'Old Silver',
      accent: Color(0xFFC0C6D4),
      accentLight: Color(0xFFE8ECF5),
      accentDark: Color(0xFF7E8698),
    ),
    BoardAccentDef(
      id: 'gold',
      name: 'Deep Gold',
      accent: Color(0xFFD4AF37),
      accentLight: Color(0xFFF3DC8E),
      accentDark: Color(0xFF96702A),
    ),
    BoardAccentDef(
      id: 'bronze',
      name: 'Dark Bronze',
      accent: Color(0xFF8C6A2F),
      accentLight: Color(0xFFC49A5A),
      accentDark: Color(0xFF54401E),
    ),
    BoardAccentDef(
      id: 'iron',
      name: 'Blackened Iron',
      accent: Color(0xFF6E6E78),
      accentLight: Color(0xFFA8A8B4),
      accentDark: Color(0xFF3E3E46),
    ),
    BoardAccentDef(
      id: 'rosegold',
      name: 'Rose Gold',
      accent: Color(0xFFC48E6E),
      accentLight: Color(0xFFE8B89E),
      accentDark: Color(0xFF8E5E44),
    ),
    BoardAccentDef(
      id: 'obsidian',
      name: 'Obsidian Inlay',
      accent: Color(0xFF4A4E5E),
      accentLight: Color(0xFF7E8498),
      accentDark: Color(0xFF22242E),
    ),
  ];

  /// Accents free players may use.
  static const freeCount = 2;
  static bool isPro(int index) => index >= freeCount;

  static BoardAccentDef byIndex(int i) =>
      all[i.clamp(0, all.length - 1)];
}
