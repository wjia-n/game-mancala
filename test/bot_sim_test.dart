import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:mancala/src/ai/mancala_ai.dart';
import 'package:mancala/src/engine/mancala_engine.dart';
import 'package:mancala/src/theme/mancala_themes.dart';

/// No-stuck-states proof: full bot-vs-bot games for every difficulty pairing.
///
/// Each simulated game must terminate (engine always reaches gameOver),
/// every chosen move must be legal, and the 48-stone invariant must hold
/// after every resolved move. A 1000-move guard catches infinite loops.
void main() {
  int total(List<int> b) => b.fold(0, (a, x) => a + x);

  void playGame(BotDifficulty d0, BotDifficulty d1, int seed) {
    final rng = Random(seed);
    final e = MancalaEngine.fresh();
    var moves = 0;
    while (!e.gameOver) {
      expect(moves++, lessThan(1000),
          reason: 'game did not terminate — stuck state suspected');
      final diff = e.turn == 0 ? d0 : d1;
      final pit = chooseBotMove(e, e.turn, diff, rng);
      expect(pit, isNot(-1), reason: 'bot found no move on a live board');
      expect(e.isLegal(pit), true, reason: 'bot chose an illegal pit');
      e.sow(pit);
      expect(total(e.board), MancalaEngine.totalStones);
    }
    expect(total(e.board), MancalaEngine.totalStones);
    final s0 = e.board[MancalaEngine.storeOf(0)];
    final s1 = e.board[MancalaEngine.storeOf(1)];
    expect(s0 + s1, MancalaEngine.totalStones);
    if (s0 == s1) {
      expect(e.winner, isNull, reason: '24-24 must be a draw');
    } else {
      expect(e.winner, s0 > s1 ? 0 : 1);
    }
  }

  final diffs = BotDifficulty.values;
  for (final d0 in diffs) {
    for (final d1 in diffs) {
      test('bot-vs-bot ${d0.label} vs ${d1.label} always terminates', () {
        for (var seed = 0; seed < 8; seed++) {
          playGame(d0, d1, seed * 977 + d0.index * 131 + d1.index * 17);
        }
      });
    }
  }

  test('free turns chain without corrupting turn state', () {
    // Board where player 0 repeatedly lands in the store.
    final e = MancalaEngine.fromBoard(
        [0, 0, 0, 0, 2, 1, 10, 4, 4, 4, 4, 4, 4, 11], 0);
    var r = e.sow(5); // lands in store -> free turn
    expect(r.freeTurn, true);
    expect(e.turn, 0);
    r = e.sow(4); // lands pit 5, then store -> free turn again
    expect(r.freeTurn, true);
    expect(e.turn, 0);
    expect(total(e.board), MancalaEngine.totalStones);
  });

  test('catalog sanity: 12+ themes, 8+ stone styles, free tiers', () {
    expect(MancalaThemes.all.length, greaterThanOrEqualTo(12));
    expect(MancalaThemes.freeThemeIds.length, 4);
    for (final t in MancalaThemes.all) {
      expect(MancalaThemes.byId(t.id).id, t.id);
    }
    expect(MancalaThemes.isProTheme('heirloom'), false);
    expect(MancalaThemes.isProTheme('ebony'), true);
    expect(StoneStyles.all.length, greaterThanOrEqualTo(8));
    expect(StoneStyles.freeCount, 4);
    expect(StoneStyles.isPro(3), false);
    expect(StoneStyles.isPro(4), true);
    expect(BoardAccents.all.length, greaterThanOrEqualTo(6));
    expect(BoardAccents.freeCount, 2);
    expect(BoardAccents.isPro(1), false);
    expect(BoardAccents.isPro(2), true);
  });
}
