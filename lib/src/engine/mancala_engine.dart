/// Mancala (Kalah) engine — pure, deterministic game logic.
///
/// Board layout (14 containers):
///   0-5  = player 0 pits (bottom row, left to right)
///   6    = player 0 store (right side)
///   7-12 = player 1 pits
///   13   = player 1 store (left side)
///
/// Sowing is counter-clockwise: from a bottom-row pit the stones move right
/// into the player's own store, then left across the top row, skipping the
/// opponent's store. Implements the authoritative RULES.md exactly.
class MancalaEngine {
  static const int pitsPerSide = 6;
  static const int stonesPerPit = 4;
  static const int totalStones = 48;

  final List<int> board; // length 14
  int turn; // 0 or 1
  bool gameOver;
  int? winner; // null until gameOver (null == draw)

  MancalaEngine.fresh()
      : board = List<int>.filled(14, stonesPerPit),
        turn = 0,
        gameOver = false,
        winner = null {
    board[storeOf(0)] = 0;
    board[storeOf(1)] = 0;
    assert(_invariant());
  }

  MancalaEngine._(this.board, this.turn, this.gameOver, this.winner);

  /// Rebuilds an engine from a raw board (used by the bot isolate).
  factory MancalaEngine.fromBoard(List<int> board, int turn) {
    assert(board.length == 14);
    assert(board.fold<int>(0, (a, b) => a + b) == totalStones,
        'fromBoard requires the 48-stone invariant');
    return MancalaEngine._(List<int>.from(board), turn, false, null);
  }

  MancalaEngine clone() => MancalaEngine._(List<int>.from(board), turn, gameOver, winner);

  static int storeOf(int player) => player == 0 ? 6 : 13;

  static bool isOwnPit(int index, int player) =>
      player == 0 ? index >= 0 && index <= 5 : index >= 7 && index <= 12;

  static int opposite(int pit) => 12 - pit; // 0<->12, ..., 5<->7

  /// Next pit when sowing counter-clockwise, skipping the opponent's store.
  static int nextPit(int index, int player) {
    do {
      index = (index + 1) % 14;
    } while ((player == 0 && index == 13) || (player == 1 && index == 6));
    return index;
  }

  bool isLegal(int pit) =>
      !gameOver && isOwnPit(pit, turn) && board[pit] > 0;

  List<int> legalMoves([int? player]) {
    final p = player ?? turn;
    final out = <int>[];
    final base = p == 0 ? 0 : 7;
    for (var i = 0; i < pitsPerSide; i++) {
      if (board[base + i] > 0) out.add(base + i);
    }
    return out;
  }

  bool _invariant() => board.fold<int>(0, (a, b) => a + b) == totalStones;

  int stonesInPlay() => board.fold<int>(0, (a, b) => a + b) -
      board[storeOf(0)] -
      board[storeOf(1)];

  /// Ordered list of pit indices that receive a stone during this sow.
  /// Pure preview used for animation; does not mutate state.
  List<int> sowPath(int pit) {
    final path = <int>[];
    var seeds = board[pit];
    var i = pit;
    while (seeds > 0) {
      i = nextPit(i, turn);
      path.add(i);
      seeds--;
    }
    return path;
  }

  /// Applies a full move for the current player. The pit must be legal.
  /// Returns a [MoveResult] describing everything that happened.
  MoveResult sow(int pit) {
    assert(isLegal(pit), 'Illegal sow attempted on pit $pit (turn $turn)');
    final player = turn;
    final hand = board[pit];
    board[pit] = 0;

    var i = pit;
    for (var s = 0; s < hand; s++) {
      i = nextPit(i, player);
      board[i]++;
    }

    final ownStore = storeOf(player);
    var captured = 0;
    var freeTurn = false;

    if (i == ownStore) {
      freeTurn = true;
    } else if (isOwnPit(i, player) && board[i] == 1) {
      // Last stone landed in a previously-empty own pit: capture the landing
      // stone plus everything in the opposite pit (RULES.md §6).
      final opp = opposite(i);
      captured = 1 + board[opp];
      board[ownStore] += captured;
      board[opp] = 0;
      board[i] = 0;
    }

    assert(_invariant(), '48-stone invariant broken after sow');

    // Game end: either side completely empty → sweep the other side.
    var swept = 0;
    final p0Empty = List.generate(6, (k) => board[k]).every((s) => s == 0);
    final p1Empty = List.generate(6, (k) => board[7 + k]).every((s) => s == 0);
    if (p0Empty || p1Empty) {
      gameOver = true;
      for (var k = 0; k < 6; k++) {
        swept += board[k];
        board[storeOf(0)] += board[k];
        board[k] = 0;
      }
      for (var k = 7; k <= 12; k++) {
        swept += board[k];
        board[storeOf(1)] += board[k];
        board[k] = 0;
      }
      final s0 = board[storeOf(0)];
      final s1 = board[storeOf(1)];
      winner = s0 == s1 ? null : (s0 > s1 ? 0 : 1);
      assert(_invariant(), '48-stone invariant broken after sweep');
    } else if (!freeTurn) {
      turn = 1 - player;
    }
    // freeTurn: same player moves again; game end forfeits the free turn.

    return MoveResult(
      player: player,
      pit: pit,
      hand: hand,
      path: null, // filled by caller via sowPath before mutation if needed
      lastPit: i,
      captured: captured,
      freeTurn: freeTurn && !gameOver,
      gameOver: gameOver,
      swept: swept,
      winner: winner,
    );
  }

  /// Convenience: preview path + apply in one call.
  MoveResult sowWithPath(int pit) {
    final path = sowPath(pit);
    final r = sow(pit);
    return r.withPath(path);
  }
}

/// Immutable record of a resolved move.
class MoveResult {
  final int player;
  final int pit;
  final int hand;
  final List<int>? path;
  final int lastPit;
  final int captured;
  final bool freeTurn;
  final bool gameOver;
  final int swept;
  final int? winner;

  const MoveResult({
    required this.player,
    required this.pit,
    required this.hand,
    required this.path,
    required this.lastPit,
    required this.captured,
    required this.freeTurn,
    required this.gameOver,
    required this.swept,
    required this.winner,
  });

  MoveResult withPath(List<int> p) => MoveResult(
        player: player,
        pit: pit,
        hand: hand,
        path: p,
        lastPit: lastPit,
        captured: captured,
        freeTurn: freeTurn,
        gameOver: gameOver,
        swept: swept,
        winner: winner,
      );
}
