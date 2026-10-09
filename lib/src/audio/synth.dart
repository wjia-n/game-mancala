import 'dart:math';
import 'dart:typed_data';

/// Procedural artisan audio: every sound in the game is synthesized here as
/// 16-bit PCM WAV data — kalimba plucks, glass-stone clacks, wood knocks.
/// No recorded or AI-generated audio assets.
class Synth {
  static const int sampleRate = 22050;

  // A-minor pentatonic (kalimba/kora voice of the game).
  static const List<double> _scale = [
    220.00, // A3
    261.63, // C4
    293.66, // D4
    329.63, // E4
    392.00, // G4
    440.00, // A4
    523.25, // C5
    587.33, // D5
    659.25, // E5
  ];

  /// Builds every named sound. Runs inside [compute] — must stay top-level.
  static Map<String, Uint8List> buildAll(int _) {
    final rng = Random(20261009);
    return {
      'click': wav(_knock(1.0)),
      'scoop': wav(_scoop(rng)),
      'sow': wav(_clack(1.0, rng)),
      'capture': wav(_melody([3, 4, 5], 0.16, 0.9, rng)),
      'freeturn': wav(_melody([5, 8], 0.14, 0.8, rng)),
      'invalid': wav(_thud()),
      'start': wav(_melody([0, 1, 2, 3], 0.18, 0.85, rng)),
      'win': wav(_melody([4, 5, 6, 5, 4, 3, 2, 0], 0.22, 0.9, rng)),
      'lose': wav(_melodyLow([2, 1, 0], 0.3, 0.8, rng)),
      'musicMenu': wav(_music(bpm: 72, bars: 8, seed: 7, density: 0.38, rng: rng)),
      'musicGame': wav(_music(bpm: 92, bars: 8, seed: 21, density: 0.58, rng: rng)),
    };
  }

  // ---------------------------------------------------------- WAV encoding
  static Uint8List wav(List<double> samples) {
    final n = samples.length;
    final data = ByteData(44 + n * 2);
    void str(int o, String s) {
      for (var i = 0; i < s.length; i++) {
        data.setUint8(o + i, s.codeUnitAt(i));
      }
    }

    str(0, 'RIFF');
    data.setUint32(4, 36 + n * 2, Endian.little);
    str(8, 'WAVE');
    str(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little); // PCM
    data.setUint16(22, 1, Endian.little); // mono
    data.setUint32(24, sampleRate, Endian.little);
    data.setUint32(28, sampleRate * 2, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    str(36, 'data');
    data.setUint32(40, n * 2, Endian.little);
    for (var i = 0; i < n; i++) {
      final v = samples[i].clamp(-1.0, 1.0);
      data.setInt16(44 + i * 2, (v * 32767).round(), Endian.little);
    }
    return data.buffer.asUint8List();
  }

  // --------------------------------------------------------------- voices
  /// Kalimba tine: fundamental + inharmonic partials, fast attack, long decay.
  static double _pluckSample(double freq, double t) {
    final f = 2 * pi * freq * t;
    final env = exp(-3.2 * t) * min(1.0, t / 0.004);
    return env *
        (sin(f) +
            0.38 * sin(2.756 * f) * exp(-6.0 * t) +
            0.14 * sin(5.404 * f) * exp(-11.0 * t));
  }

  static List<double> _pluck(double freq, double dur, double vol) {
    final n = (dur * sampleRate).round();
    final out = List<double>.filled(n, 0.0);
    for (var i = 0; i < n; i++) {
      out[i] = vol * _pluckSample(freq, i / sampleRate);
    }
    return out;
  }

  /// Short wooden knock (UI clicks).
  static List<double> _knock(double vol) {
    final rng = Random(11);
    const dur = 0.10;
    final n = (dur * sampleRate).round();
    final out = List<double>.filled(n, 0.0);
    for (var i = 0; i < n; i++) {
      final t = i / sampleRate;
      out[i] = vol *
          ((rng.nextDouble() * 2 - 1) * exp(-55 * t) * 0.55 +
              sin(2 * pi * 168 * t) * exp(-32 * t) * 0.8);
    }
    return out;
  }

  /// Single glass-stone clack (one sowed stone).
  static List<double> _clack(double vol, Random rng) {
    const dur = 0.14;
    final n = (dur * sampleRate).round();
    final out = List<double>.filled(n, 0.0);
    final f1 = 2350 + rng.nextDouble() * 500;
    for (var i = 0; i < n; i++) {
      final t = i / sampleRate;
      out[i] = vol *
          ((rng.nextDouble() * 2 - 1) * exp(-95 * t) * 0.4 +
              sin(2 * pi * f1 * t) * exp(-52 * t) * 0.55 +
              sin(2 * pi * f1 * 2.18 * t) * exp(-75 * t) * 0.22);
    }
    return out;
  }

  /// Scooping a handful of stones out of a pit.
  static List<double> _scoop(Random rng) {
    const dur = 0.35;
    final n = (dur * sampleRate).round();
    final out = List<double>.filled(n, 0.0);
    for (var k = 0; k < 5; k++) {
      _mix(out, _clack(0.5, rng), (k * 0.055 * sampleRate).round(), 1.0);
    }
    _mix(out, _knock(0.35), 0, 1.0);
    return out;
  }

  /// Dull low thud (illegal move).
  static List<double> _thud() {
    final rng = Random(23);
    const dur = 0.28;
    final n = (dur * sampleRate).round();
    final out = List<double>.filled(n, 0.0);
    for (var i = 0; i < n; i++) {
      final t = i / sampleRate;
      out[i] = (rng.nextDouble() * 2 - 1) * exp(-38 * t) * 0.22 +
          sin(2 * pi * 88 * t) * exp(-16 * t) * 0.85;
    }
    return out;
  }

  static List<double> _melody(
      List<int> degrees, double step, double vol, Random rng) {
    final dur = step * degrees.length + 1.2;
    final out = List<double>.filled((dur * sampleRate).round(), 0.0);
    for (var k = 0; k < degrees.length; k++) {
      final f = _scale[degrees[k] % _scale.length];
      _mix(out, _pluck(f, 1.1, vol), (k * step * sampleRate).round(), 1.0);
      // faint octave shimmer
      _mix(out, _pluck(f * 2, 0.5, vol * 0.18),
          (k * step * sampleRate).round(), 1.0);
    }
    // soft stone-clack bed under celebratory sounds
    if (degrees.length > 2) {
      for (var k = 0; k < degrees.length; k += 2) {
        _mix(out, _clack(0.28, rng), (k * step * sampleRate).round(), 1.0);
      }
    }
    return out;
  }

  static List<double> _melodyLow(
      List<int> degrees, double step, double vol, Random rng) {
    final dur = step * degrees.length + 1.6;
    final out = List<double>.filled((dur * sampleRate).round(), 0.0);
    for (var k = 0; k < degrees.length; k++) {
      final f = _scale[degrees[k] % _scale.length] / 2;
      _mix(out, _pluck(f, 1.5, vol), (k * step * sampleRate).round(), 1.0);
    }
    _mix(out, _thud(), 0, 0.5);
    return out;
  }

  // ---------------------------------------------------------------- music
  /// Seamless ambient kora/kalimba loop: pentatonic plucks over a soft drone.
  /// The last bar stays empty so every pluck decays fully before the loop.
  static List<double> _music({
    required double bpm,
    required int bars,
    required int seed,
    required double density,
    required Random rng,
  }) {
    final rng = Random(seed);
    final beat = 60.0 / bpm;
    final eighth = beat / 2;
    final stepsPerBar = 8;
    final totalSteps = bars * stepsPerBar;
    final total = bars * 4 * beat;
    final n = (total * sampleRate).round();
    final out = List<double>.filled(n, 0.0);

    // Soft drone: low A + E with a slow breathing tremolo.
    for (var i = 0; i < n; i++) {
      final t = i / sampleRate;
      final trem = 0.75 + 0.25 * sin(2 * pi * 0.12 * t);
      out[i] = 0.055 *
          trem *
          (sin(2 * pi * 110 * t) +
              0.6 * sin(2 * pi * 164.81 * t) +
              0.35 * sin(2 * pi * 220 * t) * sin(2 * pi * 0.07 * t));
    }

    // Generative melody: random walk on the pentatonic scale.
    var degree = 3;
    const bass = [110.0, 164.81]; // A2, E3
    for (var s = 0; s < totalSteps - stepsPerBar; s++) {
      final at = (s * eighth * sampleRate).round();
      // Bass pulse on the downbeat of each bar.
      if (s % stepsPerBar == 0) {
        _mix(out, _pluck(bass[(s ~/ stepsPerBar) % 2], 2.2, 0.5), at, 1.0);
      }
      if (rng.nextDouble() < density) {
        degree += [-2, -1, -1, 0, 1, 1, 2][rng.nextInt(7)];
        degree = degree.clamp(0, _scale.length - 1);
        final f = _scale[degree];
        final vol = 0.34 + rng.nextDouble() * 0.22;
        _mix(out, _pluck(f, 1.6, vol), at, 1.0);
        // Occasional answering note a third above.
        if (rng.nextDouble() < 0.22 && degree + 2 < _scale.length) {
          _mix(
              out,
              _pluck(_scale[degree + 2], 1.2, vol * 0.55),
              at + (eighth * sampleRate * 0.5).round(),
              1.0);
        }
      }
    }
    // Gentle fade edges to guarantee a click-free loop.
    final fade = (0.15 * sampleRate).round();
    for (var i = 0; i < fade; i++) {
      final g = i / fade;
      out[i] *= g;
      out[n - 1 - i] *= g;
    }
    return out;
  }

  static void _mix(List<double> dst, List<double> src, int at, double gain) {
    for (var i = 0; i < src.length && at + i < dst.length; i++) {
      dst[at + i] += src[i] * gain;
    }
  }
}
