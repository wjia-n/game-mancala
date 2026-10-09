import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../ai/mancala_ai.dart';

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

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  bool musicEnabled = true;
  bool sfxEnabled = true;
  double musicVolume = 0.7;
  double sfxVolume = 0.8;
  bool vibration = true;
  BotDifficulty difficulty = BotDifficulty.sharp;

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
    wins = await _prefs.getInt(_kWins) ?? 0;
    losses = await _prefs.getInt(_kLosses) ?? 0;
    draws = await _prefs.getInt(_kDraws) ?? 0;
    bestMargin = await _prefs.getInt(_kBestMargin) ?? 0;
    notifyListeners();
  }

  Future<void> _save(String key, Object v) async {
    if (v is bool) {
      await _prefs.setBool(key, v);
    } else if (v is double) {
      await _prefs.setDouble(key, v);
    } else if (v is int) {
      await _prefs.setInt(key, v);
    }
  }

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

  /// Records a finished vs-bot game from the human's perspective.
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
    await _save(_kMusic, true);
    await _save(_kSfx, true);
    await _save(_kMusicVol, 0.7);
    await _save(_kSfxVol, 0.8);
    await _save(_kVibration, true);
    await _save(_kDifficulty, BotDifficulty.sharp.index);
    notifyListeners();
  }
}
