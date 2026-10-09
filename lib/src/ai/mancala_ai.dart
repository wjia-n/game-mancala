import 'dart:math';
import '../engine/mancala_engine.dart';

/// Bot difficulty levels, selectable in Settings (RULES.md §11).
enum BotDifficulty { calm, sharp, master }

extension BotDifficultyLabel on BotDifficulty {
  String get label => switch (this) {
        BotDifficulty.calm => 'Calm',
        BotDifficulty.sharp => 'Sharp',
        BotDifficulty.master => 'Master',
      };
  String get blurb => switch (this) {
        BotDifficulty.calm => 'Gentle, plays for fun',
        BotDifficulty.sharp => 'Tactical, watches for captures',
        BotDifficulty.master => 'Deep thinker, rarely blunders',
      };
}

/// Chooses the bot's pit. Always returns a legal pit (or -1 if none).
int chooseBotMove(
  MancalaEngine engine,
  int player,
  BotDifficulty difficulty,
  Random rng,
) {
  final legal = engine.legalMoves(player);
  if (legal.isEmpty) return -1;
  return switch (difficulty) {
    BotDifficulty.calm => _calm(engine, player, legal, rng),
    BotDifficulty.sharp => _sharp(engine, player, legal, rng),
    BotDifficulty.master => _master(engine, player, legal, rng),
  };
}

/// Simulates a move on a scratch clone; returns the resulting engine and
/// the resolved move record.
({MancalaEngine engine, MoveResult result}) _simulate(
    MancalaEngine engine, int pit, int player) {
  final e = engine.clone()..turn = player;
  final r = e.sow(pit);
  return (engine: e, result: r);
}

// ------------------------------------------------------------------ Calm
/// Calm (easy): random legal pit; 10% of the time prefers a free-turn move.
int _calm(MancalaEngine engine, int player, List<int> legal, Random rng) {
  if (rng.nextDouble() < 0.10) {
    final freebies = legal.where((p) {
      final e = engine.clone();
      e.turn = player;
      final r = e.sow(p);
      return r.freeTurn;
    }).toList();
    if (freebies.isNotEmpty) return freebies[rng.nextInt(freebies.length)];
  }
  return legal[rng.nextInt(legal.length)];
}

// ------------------------------------------------------------------ Sharp
/// Sharp (medium): 1-ply greedy.
int _sharp(MancalaEngine engine, int player, List<int> legal, Random rng) {
  var best = legal.first;
  var bestScore = -1e9;
  for (final p in legal) {
    final before = engine.clone()..turn = player;
    final sim = _simulate(engine, p, player);
    final sc = _sharpScore(before, sim.engine, sim.result, player, p);
    if (sc > bestScore || (sc == bestScore && rng.nextBool())) {
      bestScore = sc;
      best = p;
    }
  }
  return best;
}

double _sharpScore(MancalaEngine before, MancalaEngine after, MoveResult result,
    int player, int pit) {
  // 1. Capture moves, preferring the most stones.
  if (result.captured > 0) return 1000 + result.captured * 10;
  // 2. Free-turn moves, preferring ones that leave a follow-up opportunity.
  if (result.freeTurn) {
    var followUp = 0.0;
    for (final q in after.legalMoves(player)) {
      final r2 = _simulate(after, q, player).result;
      if (r2.captured > 0) followUp = max(followUp, r2.captured.toDouble());
    }
    return 500 + followUp * 5 + before.board[pit] * 0.5;
  }
  // 3. Avoid leaving big capture targets for the opponent.
  final risk = _opponentBestCapture(after, 1 - player);
  // 4. Tie-break: the pit with the most stones.
  return before.board[pit] * 1.0 - risk * 8.0;
}

/// Best capture the given player could make on this board next turn.
int _opponentBestCapture(MancalaEngine engine, int player) {
  var best = 0;
  for (final p in engine.legalMoves(player)) {
    best = max(best, _simulate(engine, p, player).result.captured);
  }
  return best;
}

// ------------------------------------------------------------------ Master
/// Master (hard): 4-ply alpha-beta over the exact rules.
/// Hard time cap: 800 ms soft, 1.5 s hard — best-so-far move is played.
int _master(MancalaEngine engine, int player, List<int> legal, Random rng) {
  final deadline = DateTime.now().add(const Duration(milliseconds: 800));
  final hardDeadline = DateTime.now().add(const Duration(milliseconds: 1500));
  var best = _sharp(engine, player, legal, rng); // safe fallback
  // Iterative deepening: 1..4 ply, keeps best-so-far if the clock runs out.
  for (var depth = 1; depth <= 4; depth++) {
    var timedOut = false;
    var localBest = best;
    var localScore = -1e18;
    final order = List<int>.from(legal)..shuffle(rng);
    for (final p in order) {
      if (DateTime.now().isAfter(hardDeadline)) {
        timedOut = true;
        break;
      }
      final e = engine.clone()..turn = player;
      e.sow(p);
      // _alphaBeta returns the value from `player`'s perspective already.
      final sc = _alphaBeta(
        e,
        depth - 1,
        -1e18,
        1e18,
        e.turn, // free turns keep the same player to move
        player,
        hardDeadline,
      );
      // Small random tie-break for variety.
      final jittered = sc + rng.nextDouble() * 0.5;
      if (jittered > localScore) {
        localScore = jittered;
        localBest = p;
      }
    }
    if (!timedOut) best = localBest;
    if (DateTime.now().isAfter(deadline) || timedOut) break;
  }
  return best;
}

double _alphaBeta(
  MancalaEngine engine,
  int depth,
  double alpha,
  double beta,
  int toMove,
  int maximizer,
  DateTime hardDeadline,
) {
  if (engine.gameOver || depth == 0 || DateTime.now().isAfter(hardDeadline)) {
    return _evaluate(engine, maximizer);
  }
  final moves = engine.legalMoves(toMove);
  if (moves.isEmpty) return _evaluate(engine, maximizer);
  if (toMove == maximizer) {
    var value = -1e18;
    for (final m in moves) {
      final e = engine.clone()..turn = toMove;
      e.sow(m);
      // A free turn means the same player moves again: depth doesn't drop.
      final nextDepth = e.turn == toMove ? depth : depth - 1;
      value = max(value, _alphaBeta(e, nextDepth, alpha, beta, e.turn, maximizer, hardDeadline));
      alpha = max(alpha, value);
      if (alpha >= beta) break;
    }
    return value;
  } else {
    var value = 1e18;
    for (final m in moves) {
      final e = engine.clone()..turn = toMove;
      e.sow(m);
      final nextDepth = e.turn == toMove ? depth : depth - 1;
      value = min(value, _alphaBeta(e, nextDepth, alpha, beta, e.turn, maximizer, hardDeadline));
      beta = min(beta, value);
      if (beta <= alpha) break;
    }
    return value;
  }
}

/// (own store − opponent store) + 0.1 × stones on own side + capture bonus.
double _evaluate(MancalaEngine engine, int player) {
  final opp = 1 - player;
  final storeDiff = (engine.board[MancalaEngine.storeOf(player)] -
          engine.board[MancalaEngine.storeOf(opp)])
      .toDouble();
  var ownSide = 0;
  final base = player == 0 ? 0 : 7;
  for (var k = 0; k < 6; k++) {
    ownSide += engine.board[base + k];
  }
  var score = storeDiff + 0.1 * ownSide;
  if (engine.gameOver) {
    if (engine.winner == player) {
      score += 1000;
    } else if (engine.winner == null) {
      score += 0;
    } else {
      score -= 1000;
    }
  }
  // Capture-opportunity bonus: reward positions where a capture is available.
  score += _opponentBestCapture(engine, player) * 0.4;
  return score;
}
