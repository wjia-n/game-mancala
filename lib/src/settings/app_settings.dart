import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../ai/mancala_ai.dart';
import '../artisan/palette.dart';
import '../theme/mancala_themes.dart';

/// Offline game modes.
enum GameMode {
  /// Human vs bot (seat chosen by [humanSide]).
  solo,

  /// Two humans, pass-and-play on one device.
  pass,

  /// One human + one bot; the bot occupies [mixedBotSeat].
  mixed,

  /// Bot vs bot demonstration match.
  watch,
}

/// Persisted user settings + lifetime stats (shared_preferences).
class AppSettings extends ChangeNotifier {
  static const _kMusic = 'mancala.music';
  static const _kSfx = 'mancala.sfx';
  static const _kMusicVol = 'mancala.music_vol';
  static const _kSfxVol = 'mancala.sfx_vol';
  static const _kVibration = 'mancala.vibration';
  static const _kDifficulty = 'mancala.difficulty';
  static const _kWins = 'mancala.wins';
  static const _kLosses = 'mancala.losses';
  static const _kDraws = 'mancala.draws';
  static const _kBestMargin = 'mancala.best_margin';
  static const _kNames = 'mancala.player_names'; // StringList, 2 entries
  static const _kTheme = 'mancala.theme_id';
  static const _kStoneStyle = 'mancala.stone_style';
  static const _kAccent = 'mancala.accent';
  static const _kIsPro = 'mancala.is_pro';
  static const _kMode = 'mancala.game_mode';
  static const _kHumanSide = 'mancala.human_side';
  static const _kMixedBotSeat = 'mancala.mixed_bot_seat';
  static const _kCustomPrefix = 'mancala_custom_';

  static const defaultNames = ['Player 1', 'Player 2'];

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  bool musicEnabled = true;
  bool sfxEnabled = true;
  double musicVolume = 0.7;
  double sfxVolume = 0.8;
  bool vibration = true;
  BotDifficulty difficulty = BotDifficulty.sharp;

  /// Renameable display names, one per seat (0 = bottom row, 1 = top row).
  List<String> playerNames = List.of(defaultNames);

  String themeId = 'heirloom';
  int stoneStyle = 0;
  int accent = 0;
  bool isPro = false;

  GameMode mode = GameMode.solo;
  int humanSide = 0; // solo: which seat the human plays
  int mixedBotSeat = 1; // mixed: which seat the bot plays

  /// Custom theme colors (ARGB ints), edited in the theme creator.
  Map<String, int> customColors = Map.of(_defaultCustomColors);

  static const Map<String, int> _defaultCustomColors = {
    'clay': 0xFF1E140C,
    'pitInner': 0xFF0D0603,
    'woodDark': 0xFF3B2416,
    'woodDeep': 0xFF2E1C0E,
    'mahogany': 0xFF5C3A21,
    'mahoganyLight': 0xFF442A18,
    'woodEdge': 0xFF4A301B,
    'accent': 0xFFB08D3C,
    'accentLight': 0xFFD9B25F,
    'ember': 0xFFE58235,
    'bone': 0xFFF2E7D5,
    'boneDim': 0xFFCBB896,
    'p0': 0xFFD98E2B,
    'p0Alt': 0xFF7A2E2E,
    'p1': 0xFF4F7A5B,
    'p1Alt': 0xFF7D695C,
  };

  int wins = 0;
  int losses = 0;
  int draws = 0;
  int bestMargin = 0;

  static Future<AppSettings> load() async {
    final s = AppSettings();
    await s._read();
    return s;
  }

  Future<void> _read() async {
    musicEnabled = await _prefs.getBool(_kMusic) ?? true;
    sfxEnabled = await _prefs.getBool(_kSfx) ?? true;
    musicVolume = await _prefs.getDouble(_kMusicVol) ?? 0.7;
    sfxVolume = await _prefs.getDouble(_kSfxVol) ?? 0.8;
    vibration = await _prefs.getBool(_kVibration) ?? true;
    final d = await _prefs.getInt(_kDifficulty) ?? BotDifficulty.sharp.index;
    difficulty = BotDifficulty.values[d.clamp(0, 2)];
    final names = await _prefs.getStringList(_kNames);
    if (names != null && names.length == 2) {
      playerNames = [
        for (int i = 0; i < 2; i++)
          names[i].trim().isEmpty ? defaultNames[i] : names[i].trim()
      ];
    }
    themeId = await _prefs.getString(_kTheme) ?? 'heirloom';
    stoneStyle = (await _prefs.getInt(_kStoneStyle) ?? 0)
        .clamp(0, StoneStyles.all.length - 1);
    accent = (await _prefs.getInt(_kAccent) ?? 0)
        .clamp(0, BoardAccents.all.length - 1);
    isPro = await _prefs.getBool(_kIsPro) ?? false;
    final m = await _prefs.getInt(_kMode) ?? GameMode.solo.index;
    mode = GameMode.values[m.clamp(0, GameMode.values.length - 1)];
    humanSide = (await _prefs.getInt(_kHumanSide) ?? 0).clamp(0, 1);
    mixedBotSeat = (await _prefs.getInt(_kMixedBotSeat) ?? 1).clamp(0, 1);
    for (final k in _defaultCustomColors.keys) {
      customColors[k] =
          await _prefs.getInt('$_kCustomPrefix$k') ?? _defaultCustomColors[k]!;
    }
    wins = await _prefs.getInt(_kWins) ?? 0;
    losses = await _prefs.getInt(_kLosses) ?? 0;
    draws = await _prefs.getInt(_kDraws) ?? 0;
    bestMargin = await _prefs.getInt(_kBestMargin) ?? 0;
    _enforceFreeLimits(silent: true);
    notifyListeners();
  }

  Future<void> _save(String key, Object v) async {
    if (v is bool) {
      await _prefs.setBool(key, v);
    } else if (v is double) {
      await _prefs.setDouble(key, v);
    } else if (v is int) {
      await _prefs.setInt(key, v);
    } else if (v is String) {
      await _prefs.setString(key, v);
    }
  }

  // ------------------------------------------------------------- appearance
  MancalaThemeDef get activeTheme =>
      MancalaThemes.byId(themeId, custom: customTheme);

  StoneStyleDef get activeStones {
    if (themeId == 'custom') return customStones;
    return StoneStyles.byIndex(stoneStyle);
  }

  BoardAccentDef get activeAccent {
    if (themeId == 'custom') {
      Color c(String k) => Color(customColors[k] ?? 0xFF000000);
      return BoardAccentDef(
        id: 'custom',
        name: 'My Accent',
        accent: c('accent'),
        accentLight: c('accentLight'),
        accentDark: c('accent'),
      );
    }
    return BoardAccents.byIndex(accent);
  }

  /// Builds the user-designed custom theme from stored colors.
  MancalaThemeDef get customTheme {
    Color c(String k) => Color(customColors[k] ?? 0xFF000000);
    return MancalaThemeDef(
      id: 'custom',
      name: 'My Creation',
      woodLine: 'Hand-mixed by you',
      clay: c('clay'),
      clayDeep: c('clay'),
      pitInner: c('pitInner'),
      woodDark: c('woodDark'),
      woodDeep: c('woodDeep'),
      mahogany: c('mahogany'),
      mahoganyLight: c('mahoganyLight'),
      woodEdge: c('woodEdge'),
      ember: c('ember'),
      emberSoft: c('ember'),
      bone: c('bone'),
      boneDim: c('boneDim'),
      walnutInk: const Color(0xFF3B2311),
    );
  }

  /// Builds the user-designed custom stone style from stored colors.
  StoneStyleDef get customStones {
    List<Color> stops(String key) {
      final base = Color(customColors[key] ?? 0xFF000000);
      final hsl = HSLColor.fromColor(base);
      return [
        hsl.withLightness((hsl.lightness + 0.25).clamp(0.0, 1.0)).toColor(),
        base,
        hsl.withLightness((hsl.lightness - 0.25).clamp(0.0, 1.0)).toColor(),
      ];
    }

    return StoneStyleDef(
      id: 'custom',
      name: 'My Stones',
      blurb: 'Hand-mixed by you',
      p0: stops('p0'),
      p0Alt: stops('p0Alt'),
      p1: stops('p1'),
      p1Alt: stops('p1Alt'),
    );
  }

  /// Pushes the active theme/style/accent into the global artisan palette.
  void applyTheme() {
    ArtisanPalette.apply(activeTheme, activeStones, activeAccent);
  }

  /// Free-tier limits: clamp pro-only choices back when not Pro.
  void _enforceFreeLimits({bool silent = false}) {
    if (isPro) return;
    var changed = false;
    if (MancalaThemes.isProTheme(themeId)) {
      themeId = 'heirloom';
      changed = true;
    }
    if (StoneStyles.isPro(stoneStyle)) {
      stoneStyle = 0;
      changed = true;
    }
    if (BoardAccents.isPro(accent)) {
      accent = 0;
      changed = true;
    }
    if (changed && !silent) {
      applyTheme();
      notifyListeners();
      _save(_kTheme, themeId);
      _save(_kStoneStyle, stoneStyle);
      _save(_kAccent, accent);
    }
  }

  Future<void> setPro(bool v) async {
    isPro = v;
    if (!v) _enforceFreeLimits();
    notifyListeners();
    await _save(_kIsPro, v);
  }

  Future<void> setTheme(String id) async {
    if (!isPro && MancalaThemes.isProTheme(id)) return;
    themeId = id;
    applyTheme();
    notifyListeners();
    await _save(_kTheme, id);
  }

  Future<void> setStoneStyle(int v) async {
    v = v.clamp(0, StoneStyles.all.length - 1);
    if (!isPro && StoneStyles.isPro(v)) return;
    stoneStyle = v;
    applyTheme();
    notifyListeners();
    await _save(_kStoneStyle, v);
  }

  Future<void> setAccent(int v) async {
    v = v.clamp(0, BoardAccents.all.length - 1);
    if (!isPro && BoardAccents.isPro(v)) return;
    accent = v;
    applyTheme();
    notifyListeners();
    await _save(_kAccent, v);
  }

  Future<void> setCustomColor(String key, int argb) async {
    if (!_defaultCustomColors.containsKey(key)) return;
    customColors[key] = argb;
    if (themeId == 'custom') applyTheme();
    notifyListeners();
    await _prefs.setInt('$_kCustomPrefix$key', argb);
  }

  Future<void> resetCustomColors() async {
    customColors = Map.of(_defaultCustomColors);
    if (themeId == 'custom') applyTheme();
    notifyListeners();
    for (final e in customColors.entries) {
      await _prefs.setInt('$_kCustomPrefix${e.key}', e.value);
    }
  }

  // ------------------------------------------------------------------ modes
  /// Seats (0/1) controlled by the bot for the current mode.
  Set<int> get botSeats => switch (mode) {
        GameMode.solo => {1 - humanSide},
        GameMode.pass => const {},
        GameMode.mixed => {mixedBotSeat},
        GameMode.watch => const {0, 1},
      };

  bool get isBotSeat0 => botSeats.contains(0);
  bool get isBotSeat1 => botSeats.contains(1);

  String get modeLabel => switch (mode) {
        GameMode.solo => 'Solo vs ${difficulty.label} Bot',
        GameMode.pass => '2 Players · Pass & Play',
        GameMode.mixed => 'Human + ${difficulty.label} Bot',
        GameMode.watch => 'Bot vs Bot · Demo',
      };

  Future<void> setMode(GameMode m) async {
    mode = m;
    notifyListeners();
    await _save(_kMode, m.index);
  }

  Future<void> setHumanSide(int side) async {
    humanSide = side.clamp(0, 1);
    notifyListeners();
    await _save(_kHumanSide, humanSide);
  }

  Future<void> setMixedBotSeat(int seat) async {
    mixedBotSeat = seat.clamp(0, 1);
    notifyListeners();
    await _save(_kMixedBotSeat, mixedBotSeat);
  }

  Future<void> setPlayerName(int seat, String name) async {
    if (seat < 0 || seat > 1) return;
    final clean = name.trim();
    playerNames[seat] = clean.isEmpty ? defaultNames[seat] : clean;
    notifyListeners();
    await _prefs.setStringList(_kNames, playerNames);
  }

  /// Display name for a seat, with a BOT tag when a bot plays it.
  String seatName(int seat) {
    final base = playerNames[seat];
    return botSeats.contains(seat) ? '$base · BOT' : base;
  }

  // ------------------------------------------------------------------- misc
  void setMusicEnabled(bool v) {
    musicEnabled = v;
    _save(_kMusic, v);
    notifyListeners();
  }

  void setSfxEnabled(bool v) {
    sfxEnabled = v;
    _save(_kSfx, v);
    notifyListeners();
  }

  void setMusicVolume(double v) {
    musicVolume = v.clamp(0.0, 1.0);
    _save(_kMusicVol, musicVolume);
    notifyListeners();
  }

  void setSfxVolume(double v) {
    sfxVolume = v.clamp(0.0, 1.0);
    _save(_kSfxVol, sfxVolume);
    notifyListeners();
  }

  void setVibration(bool v) {
    vibration = v;
    _save(_kVibration, v);
    notifyListeners();
  }

  void setDifficulty(BotDifficulty d) {
    difficulty = d;
    _save(_kDifficulty, d.index);
    notifyListeners();
  }

  /// Records a finished game from the human's perspective (solo/mixed only).
  /// [outcome]: 1 = human won, -1 = human lost, 0 = draw.
  void recordBotResult(int outcome, int margin) {
    if (outcome > 0) {
      wins++;
      if (margin > bestMargin) bestMargin = margin;
      _save(_kBestMargin, bestMargin);
      _save(_kWins, wins);
    } else if (outcome < 0) {
      losses++;
      _save(_kLosses, losses);
    } else {
      draws++;
      _save(_kDraws, draws);
    }
    notifyListeners();
  }

  /// Carved rank shown on the main menu, earned by beating the bot.
  String get rank {
    if (wins >= 25) return 'Grand Elder';
    if (wins >= 15) return 'Harvester';
    if (wins >= 7) return 'Adept';
    if (wins >= 3) return 'Sprout';
    return 'Seedling';
  }

  Future<void> resetDefaults() async {
    musicEnabled = true;
    sfxEnabled = true;
    musicVolume = 0.7;
    sfxVolume = 0.8;
    vibration = true;
    difficulty = BotDifficulty.sharp;
    playerNames = List.of(defaultNames);
    themeId = 'heirloom';
    stoneStyle = 0;
    accent = 0;
    mode = GameMode.solo;
    humanSide = 0;
    mixedBotSeat = 1;
    applyTheme();
    await _save(_kMusic, true);
    await _save(_kSfx, true);
    await _save(_kMusicVol, 0.7);
    await _save(_kSfxVol, 0.8);
    await _save(_kVibration, true);
    await _save(_kDifficulty, BotDifficulty.sharp.index);
    await _prefs.setStringList(_kNames, playerNames);
    await _save(_kTheme, themeId);
    await _save(_kStoneStyle, stoneStyle);
    await _save(_kAccent, accent);
    await _save(_kMode, mode.index);
    await _save(_kHumanSide, humanSide);
    await _save(_kMixedBotSeat, mixedBotSeat);
    notifyListeners();
  }
}
