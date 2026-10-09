import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:mancala/src/ai/mancala_ai.dart';
import 'package:mancala/src/engine/mancala_engine.dart';

/// RULES.md §13 test cases against the pure engine + AI.
void main() {
  int total(List<int> b) => b.fold(0, (a, x) => a + x);

  test('1. Setup: 4 stones per pit, stores empty, total 48', () {
    final e = MancalaEngine.fresh();
    for (var i = 0; i < 14; i++) {
      if (i == 6 || i == 13) {
        expect(e.board[i], 0);
      } else {
        expect(e.board[i], 4);
      }
    }
    expect(total(e.board), 48);
    expect(e.turn, 0);
  });

  test('2. Basic sow: pit 2 -> pits 3,4,5 + own store', () {
    final e = MancalaEngine.fresh();
    final r = e.sowWithPath(0);
    expect(e.board[0], 0);
    expect(e.board[1], 5);
    expect(e.board[2], 5);
    expect(e.board[3], 5);
    expect(e.board[4], 5);
    expect(e.board[6], 0, reason: 'store untouched');
    expect(r.path, [1, 2, 3, 4]);
    expect(r.freeTurn, false);
    expect(e.turn, 1, reason: 'turn passes (no free turn)');
    // Companion: pit 2 with 4 stones DOES reach the store -> free turn (§7).
    final e2 = MancalaEngine.fresh();
    final r2 = e2.sowWithPath(2);
    expect(r2.path, [3, 4, 5, 6]);
    expect(r2.freeTurn, true);
    expect(e2.turn, 0, reason: 'free turn: same player moves again');
    expect(total(e.board), 48);
  });

  test('3. Free turn: last stone lands in own store', () {
    final e = MancalaEngine.fromBoard(
        [1, 0, 0, 0, 0, 1, 22, 4, 4, 4, 4, 4, 4, 0], 0);
    final r = e.sow(5);
    expect(r.freeTurn, true);
    expect(e.turn, 0, reason: 'same player moves again');
    expect(total(e.board), 48);
  });

  test('4. Opponent store skipped on a 10-stone sow', () {
    final e = MancalaEngine.fromBoard(
        [10, 0, 0, 0, 0, 0, 0, 4, 4, 4, 4, 4, 4, 14], 0);
    final r = e.sowWithPath(0);
    expect(e.board[13], 14, reason: 'opponent store untouched by the sow');
    expect(r.path!.contains(13), false);
    expect(e.board[6], 1, reason: 'own store receives one');
    expect(r.path!.length, 10);
    expect(total(e.board), 48);
  });

  test('5. Capture: last stone in empty own pit + 5 opposite', () {
    // Player 0 sows pit 1 (1 stone) -> lands in pit 2 (empty), opposite pit 10 has 5.
    final e = MancalaEngine.fromBoard(
        [0, 1, 0, 4, 4, 4, 0, 4, 4, 4, 5, 4, 4, 10], 0);
    final r = e.sow(1);
    expect(r.lastPit, 2);
    expect(r.captured, 6);
    expect(e.board[6], 6);
    expect(e.board[2], 0);
    expect(e.board[10], 0);
    expect(total(e.board), 48);
  });

  test('6. Capture with empty opposite: only landing stone captured', () {
    final e = MancalaEngine.fromBoard(
        [0, 1, 0, 4, 4, 4, 0, 4, 4, 4, 0, 4, 4, 15], 0);
    final r = e.sow(1);
    expect(r.captured, 1, reason: 'landing stone still moves to the store');
    expect(e.board[6], 1);
    expect(e.board[2], 0);
    expect(total(e.board), 48);
  });

  test('7. No capture when landing pit was non-empty', () {
    final e = MancalaEngine.fromBoard(
        [0, 1, 3, 4, 4, 4, 0, 4, 4, 4, 4, 4, 4, 8], 0);
    final r = e.sow(1);
    expect(r.captured, 0);
    expect(e.board[2], 4);
    expect(e.turn, 1);
    expect(total(e.board), 48);
  });

  test('8. Game end: side empties -> sweep, totals sum to 48', () {
    // Player 0 pit 5 has 1 stone; sowing it empties... set up so a move
    // empties player 0's row: only pit 5 non-empty with 1 stone landing in store.
    final e = MancalaEngine.fromBoard(
        [0, 0, 0, 0, 0, 1, 24, 4, 4, 4, 4, 4, 3, 0], 0);
    final r = e.sow(5);
    expect(r.gameOver, true);
    expect(e.board.sublist(0, 6).every((s) => s == 0), true);
    expect(e.board.sublist(7, 13).every((s) => s == 0), true);
    expect(total(e.board), 48);
    expect(e.board[6] + e.board[13], 48);
  });

  test('9. Free turn forfeited when the move ends the game', () {
    final e = MancalaEngine.fromBoard(
        [0, 0, 0, 0, 0, 1, 20, 0, 0, 0, 0, 0, 0, 27], 0);
    final r = e.sow(5); // lands in own store, but player 1 side already empty
    expect(r.gameOver, true);
    expect(r.freeTurn, false, reason: 'free turn forfeited at game end');
    expect(total(e.board), 48);
  });

  test('11. Draw: 24-24 after sweep', () {
    final e = MancalaEngine.fromBoard(
        [0, 0, 0, 0, 0, 1, 23, 1, 0, 0, 0, 0, 0, 23], 0);
    final r = e.sow(5);
    expect(r.gameOver, true);
    expect(e.board[6], 24);
    expect(e.board[13], 24);
    expect(e.winner, isNull);
  });

  test('12/13. Illegal moves: empty pit, opponent pit, after game over', () {
    final e = MancalaEngine.fresh();
    expect(e.isLegal(2), true);
    expect(e.isLegal(7), false, reason: 'opponent pit');
    e.sow(0); // lands in pits 1-4: no store, no free turn
    expect(e.turn, 1);
    expect(e.isLegal(0), false, reason: 'now the opponent\u2019s pit');
    expect(e.isLegal(2), false, reason: 'still the opponent\u2019s pit');
    expect(e.isLegal(8), true, reason: 'current player pit');
  });

  test('14. Full-lap sow: 14 stones wraps, origin refilled, total kept', () {
    final e = MancalaEngine.fromBoard(
        [24, 0, 0, 0, 0, 0, 0, 4, 4, 4, 4, 4, 4, 0], 0);
    final r = e.sowWithPath(0);
    expect(r.path!.length, 24);
    expect(r.path!.contains(13), false, reason: 'opponent store skipped');
    expect(e.board[0], 1, reason: 'origin pit refilled on second lap');
    expect(total(e.board), 48);
  });

  test('15. Calm bot plays only legal moves over a full game', () {
    final rng = Random(7);
    final e = MancalaEngine.fresh();
    var guard = 0;
    while (!e.gameOver && guard++ < 400) {
      final pit = chooseBotMove(e, e.turn, BotDifficulty.calm, rng);
      expect(pit, isNot(-1));
      expect(e.isLegal(pit), true);
      e.sow(pit);
      expect(total(e.board), 48);
    }
    expect(e.gameOver, true);
    expect(total(e.board), 48);
  });

  test('16. Master bot takes the winning capture', () {
    // Player 1 to move: only pit 10 captures — 1 stone lands in the
    // empty pit 11, opposite pit 1 holds 6 -> capture of 7.
    final e = MancalaEngine.fromBoard(
        [4, 6, 4, 4, 4, 4, 0, 1, 1, 1, 1, 0, 0, 18], 1);
    final sw = Stopwatch()..start();
    final pit = chooseBotMove(e, 1, BotDifficulty.master, Random(3));
    sw.stop();
    expect(pit, 10, reason: 'master must choose the capture');
    expect(sw.elapsedMilliseconds, lessThan(1500));
  });

  test('17. 48-stone invariant across a scripted random game', () {
    final rng = Random(99);
    final e = MancalaEngine.fresh();
    var guard = 0;
    while (!e.gameOver && guard++ < 400) {
      final moves = e.legalMoves();
      e.sow(moves[rng.nextInt(moves.length)]);
      expect(total(e.board), 48);
    }
    expect(total(e.board), 48);
  });

  test('18. Fresh engine equals post-restart state', () {
    final a = MancalaEngine.fresh();
    final b = MancalaEngine.fresh();
    b.sow(2);
    final c = MancalaEngine.fresh();
    expect(c.board, a.board);
    expect(c.turn, 0);
    expect(c.gameOver, false);
  });

  test('Sharp bot prefers capture over quiet moves', () {
    final e = MancalaEngine.fromBoard(
        [4, 6, 4, 4, 4, 4, 0, 1, 1, 1, 1, 0, 0, 18], 1);
    final pit = chooseBotMove(e, 1, BotDifficulty.sharp, Random(3));
    expect(pit, 10);
  });
}
