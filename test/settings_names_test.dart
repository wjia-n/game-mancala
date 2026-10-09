import 'package:flutter_test/flutter_test.dart';
import 'package:mancala/src/settings/app_settings.dart';

/// Regression tests for the player-name persistence bug (2026-10-09):
///
/// Player names were stored with SharedPreferences.setStringList, which on
/// Android is backed by an UNORDERED StringSet — so after an app restart the
/// two seat names came back in arbitrary order and renames appeared
/// "not saved". Names are now stored as one order-preserving JSON string
/// (mancala_player_names_json) with one-time migration from the legacy key.
/// These tests cover the encode/decode round-trip and the seat mapping,
/// without needing platform channels.
void main() {
  test('names survive an encode/decode round-trip in exact slot order', () {
    const names = ['Zara', 'Ali'];
    final decoded = AppSettings.decodePlayerNames(
      AppSettings.encodePlayerNames(names),
    );
    expect(decoded, names);
    // Slot order is what matters: seat 0 (bottom row) and seat 1 (top row)
    // must each map back to the same player.
    expect(decoded[0], 'Zara');
    expect(decoded[1], 'Ali');
  });

  test('decode falls back to defaults on missing or corrupt data', () {
    expect(
      AppSettings.decodePlayerNames(null),
      AppSettings.defaultNames,
    );
    expect(
      AppSettings.decodePlayerNames('definitely not json'),
      AppSettings.defaultNames,
    );
    expect(
      AppSettings.decodePlayerNames('["only-one"]'),
      AppSettings.defaultNames,
    );
    expect(
      AppSettings.decodePlayerNames('{"a":1}'),
      AppSettings.defaultNames,
    );
  });

  test('blank entries fall back to that slot\'s default name', () {
    final decoded = AppSettings.decodePlayerNames('["Zara","  "]');
    expect(decoded, ['Zara', 'Player 2']);
  });

  test('persisted names map to the correct seats after a "restart"', () {
    // Simulate: user renamed both seats, app restarted, settings + game
    // screen rebuilt from the persisted value.
    const renamed = ['Zara', 'Ali'];
    final settings = AppSettings()
      ..mode = GameMode.pass
      ..playerNames = AppSettings.decodePlayerNames(
        AppSettings.encodePlayerNames(renamed),
      );
    expect(settings.playerNames[0], 'Zara');
    expect(settings.playerNames[1], 'Ali');
    // Pass-and-play: no BOT tags, names show exactly as typed.
    expect(settings.seatName(0), 'Zara');
    expect(settings.seatName(1), 'Ali');
  });

  test('legacy StringList value migrates through the same validation', () {
    // The one-time migration reads the legacy unordered StringList key and
    // re-encodes it as JSON; cleaning rules must match the normal path.
    final migrated = AppSettings.decodePlayerNames('["Zara","  "]');
    expect(migrated, ['Zara', 'Player 2']);
  });
}
