import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../settings/app_settings.dart';
import 'synth.dart';

/// Central audio: synthesized artisan SFX + generative kalimba music loops.
///
/// All sounds are generated once (in an isolate) as WAV bytes, then played
/// through audioplayers. Toggles/volumes come from [AppSettings].
class AudioService {
  static final AudioService instance = AudioService._();
  AudioService._();

  bool _ready = false;
  bool _ducked = false; // true while the app is backgrounded
  String _musicTrack = '';
  AppSettings? _settings;

  final AudioPlayer _music = AudioPlayer();
  final List<AudioPlayer> _sfxPool =
      List<AudioPlayer>.generate(6, (_) => AudioPlayer());
  int _sfxCursor = 0;
  Map<String, Uint8List> _bytes = const {};

  bool get isReady => _ready;

  Future<void> init() async {
    try {
      _bytes = await compute(Synth.buildAll, 0);
      await _music.setReleaseMode(ReleaseMode.loop);
      _ready = true;
    } catch (e) {
      debugPrint('AudioService: synth failed ($e) — running silent');
    }
  }

  /// Re-reads toggles/volumes and applies them immediately.
  void applySettings(AppSettings s) {
    _settings = s;
    _applyMusicState();
  }

  bool get _musicOn => (_settings?.musicEnabled ?? true) && !_ducked;
  bool get _sfxOn => (_settings?.sfxEnabled ?? true) && !_ducked;

  Future<void> _applyMusicState() async {
    if (!_ready) return;
    try {
      if (_musicOn && _musicTrack.isNotEmpty) {
        await _music.setVolume(_settings?.musicVolume ?? 0.7);
        if (_music.state != PlayerState.playing) {
          await _music.resume();
        }
      } else {
        await _music.pause();
      }
    } catch (e) {
      debugPrint('AudioService: music state failed ($e)');
    }
  }

  Future<void> _playTrack(String name) async {
    if (!_ready) return;
    final data = _bytes[name];
    if (data == null) return;
    try {
      if (_musicTrack == name) {
        await _applyMusicState();
        return;
      }
      _musicTrack = name;
      await _music.stop();
      await _music.setSource(BytesSource(data));
      await _applyMusicState();
    } catch (e) {
      debugPrint('AudioService: track $name failed ($e)');
    }
  }

  void menuMusic() => _playTrack('musicMenu');
  void gameMusic() => _playTrack('musicGame');

  Future<void> stopMusic() async {
    _musicTrack = '';
    if (!_ready) return;
    try {
      await _music.stop();
    } catch (_) {}
  }

  /// Called on app lifecycle changes; ducks everything while backgrounded.
  void setDucked(bool ducked) {
    if (_ducked == ducked) return;
    _ducked = ducked;
    _applyMusicState();
  }

  void _sfx(String name, {double gain = 1.0}) {
    if (!_ready || !_sfxOn) return;
    final data = _bytes[name];
    if (data == null) return;
    try {
      final p = _sfxPool[_sfxCursor++ % _sfxPool.length];
      p.setVolume(((_settings?.sfxVolume ?? 0.8) * gain).clamp(0.0, 1.0));
      p.play(BytesSource(data));
    } catch (e) {
      debugPrint('AudioService: sfx $name failed ($e)');
    }
  }

  // ------------------------------------------------------------ game sounds
  void uiClick() => _sfx('click');
  void scoop() => _sfx('scoop');
  void sowDrop() => _sfx('sow', gain: 0.9);
  void capture() => _sfx('capture');
  void freeTurn() => _sfx('freeturn');
  void invalid() => _sfx('invalid', gain: 0.9);
  void gameStart() => _sfx('start');
  void win() => _sfx('win');
  void lose() => _sfx('lose');

  Future<void> dispose() async {
    try {
      await _music.dispose();
      for (final p in _sfxPool) {
        await p.dispose();
      }
    } catch (_) {}
  }
}
