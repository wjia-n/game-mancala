import 'dart:math';
import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';

/// Mancala — the ancient pit-and-seed duel. Sow counter-clockwise, land your
/// last seed in your store for a bonus turn, capture opposite pits, and
/// hoard the most seeds. Greedy bot included.
class MancalaScreen extends StatefulWidget {
  final List<Player> players;
  final GameCallbacks callbacks;

  const MancalaScreen({super.key, required this.players, required this.callbacks});

  @override
  State<MancalaScreen> createState() => _MancalaScreenState();
}

// Board positions: 0-5 = player 0 pits, 6 = player 0 store,
// 7-12 = player 1 pits, 13 = player 1 store.
int _nextPit(int i, int player) {
  do {
    i = (i + 1) % 14;
  } while ((player == 0 && i == 13) || (player == 1 && i == 6));
  return i;
}

bool _isOwnPit(int i, int player) =>
    player == 0 ? i >= 0 && i <= 5 : i >= 7 && i <= 12;

int _opposite(int pit) => 12 - pit; // 0<->12, 1<->11, ..., 5<->7

/// WORKAROUND (core bug): shell solo setup yields a single bot seat instead of
/// human+bot. Synthesize the missing bot locally so solo mode stays playable.
List<Player> _effectivePlayers(List<Player> src) {
  if (src.length > 1) return src;
  final h = src.first;
  return [
    Player(name: h.name, color: h.color, emoji: h.emoji, isBot: false),
    PlayerPresets.make(1, isBot: true),
  ];
}

class _MancalaScreenState extends State<MancalaScreen> {
  late final List<Player> _ps; // always exactly 2
  late List<int> _board;
  int _turn = 0;
  bool _busy = false;
  bool _over = false;
  String _banner = ' • tap one of your pits to sow! 🫘';
  final _rand = Random();

  bool get _solo => _ps.length != widget.players.length;

  @override
  void initState() {
    super.initState();
    _ps = _effectivePlayers(widget.players);
    _board = List.filled(14, 4);
    _board[6] = 0;
    _board[13] = 0;
    widget.callbacks.setActivePlayer(0);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeBot());
  }

  void _maybeBot() {
    if (_over || _busy || !_ps[_turn].isBot) return;
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted || _over || _busy || !_ps[_turn].isBot) return;
      final pit = _botPit();
      if (pit >= 0) _sow(pit);
    });
  }

  /// Greedy bot: extra turn > capture > store gains.
  int _botPit() {
    int best = -1, bestScore = -1000000;
    for (int p = 7; p <= 12; p++) {
      if (_board[p] == 0) continue;
      final sc = _simulate(p, 1);
      if (sc > bestScore || (sc == bestScore && _rand.nextBool())) {
        bestScore = sc;
        best = p;
      }
    }
    return best;
  }

  int _simulate(int pit, int player) {
    final b = List<int>.from(_board);
    int seeds = b[pit];
    b[pit] = 0;
    int i = pit;
    while (seeds > 0) {
      i = _nextPit(i, player);
      b[i]++;
      seeds--;
    }
    final ownStore = player == 0 ? 6 : 13;
    int score = (b[ownStore] - _board[ownStore]) * 10;
    if (i == ownStore) {
      score += 30;
    } else if (_isOwnPit(i, player) && b[i] == 1 && b[_opposite(i)] > 0) {
      score += 15 + b[_opposite(i)] * 2;
    }
    return score;
  }

  Future<void> _sow(int pit) async {
    if (_over || _busy || _board[pit] == 0 || !_isOwnPit(pit, _turn)) return;
    _busy = true;
    int seeds = _board[pit];
    setState(() {
      _board[pit] = 0;
      _banner = ' • sowing $seeds seeds… 🌱';
    });
    int i = pit;
    while (seeds > 0) {
      await Future.delayed(const Duration(milliseconds: 170));
      if (!mounted || _over) return;
      i = _nextPit(i, _turn);
      setState(() => _board[i]++);
      Sfx.tap();
      seeds--;
    }
    final ownStore = _turn == 0 ? 6 : 13;
    bool extra = false;
    String msg;
    if (i == ownStore) {
      extra = true;
      msg = ' • 🌟 store landing! Bonus turn, superstar!';
      Sfx.click();
    } else if (_isOwnPit(i, _turn) && _board[i] == 1 && _board[_opposite(i)] > 0) {
      final gained = _board[_opposite(i)] + 1;
      setState(() {
        _board[ownStore] += gained;
        _board[_opposite(i)] = 0;
        _board[i] = 0;
      });
      msg = ' • 💰 CAPTURE! +$gained seeds into the store!';
      Sfx.click();
    } else {
      msg = ' • nice sow! 🌱';
    }
    _syncScores();
    if (_checkGameOver()) return;
    setState(() => _banner = msg);
    _busy = false;
    if (extra) {
      _maybeBot();
    } else {
      _turn = 1 - _turn;
      setState(() => _banner = ' • ${_ps[_turn].name}\'s turn 🫘');
      widget.callbacks.setActivePlayer(min(_turn, widget.players.length - 1));
      _maybeBot();
    }
  }

  void _syncScores() {
    for (int i = 0; i < 2; i++) {
      final store = _board[i == 0 ? 6 : 13];
      _ps[i].score = store;
      if (i < widget.players.length) widget.players[i].score = store;
    }
    widget.callbacks.refreshHud();
    setState(() {});
  }

  /// Returns true if the game ended.
  bool _checkGameOver() {
    final p0Empty = List.generate(6, (i) => _board[i]).every((s) => s == 0);
    final p1Empty = List.generate(6, (i) => _board[7 + i]).every((s) => s == 0);
    if (!p0Empty && !p1Empty) return false;
    _over = true;
    setState(() {
      for (int i = 0; i < 6; i++) {
        _board[6] += _board[i];
        _board[i] = 0;
      }
      for (int i = 7; i <= 12; i++) {
        _board[13] += _board[i];
        _board[i] = 0;
      }
    });
    _syncScores();
    final s0 = _board[6], s1 = _board[13];
    if (s0 == s1) {
      widget.callbacks.finish(
        headline: '🤝 It\'s a tie!',
        subline: '$s0 seeds each — too evenly matched! Rematch?',
      );
    } else {
      final w = _ps[s0 > s1 ? 0 : 1];
      widget.callbacks.finish(
        winner: w,
        headline: '🏆 ${w.name} wins Mancala!',
        subline: '${w.score} seeds hoarded. Certified seed strategist! 🫘',
      );
    }
    return true;
  }

  // ------------------------------------------------------------------ build
  @override
  Widget build(BuildContext context) {
    final t = ThemeController.of(context).theme;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Column(
          children: [
            const SizedBox(height: 4),
            TurnBanner(player: _ps[_turn], action: _banner),
            if (_solo) ...[
              const SizedBox(height: 8),
              Text(
                '${_ps[0].emoji} ${_board[6]}  •  ${_board[13]} ${_ps[1].emoji}',
                style: TextStyle(color: t.text, fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ],
            const SizedBox(height: 14),
            // board: store | pits | store
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _storePit(t, 13, _ps[1]),
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          for (int p = 12; p >= 7; p--) Expanded(child: _pit(t, p, 1)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          for (int p = 0; p <= 5; p++) Expanded(child: _pit(t, p, 0)),
                        ],
                      ),
                    ],
                  ),
                ),
                _storePit(t, 6, _ps[0]),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              _over
                  ? ''
                  : _ps[_turn].isBot
                      ? '${_ps[_turn].name} is thinking… 🤖'
                      : _busy
                          ? 'Sowing… 🌱'
                          : 'Tap one of your glowing pits 👇',
              style: TextStyle(color: t.muted, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }

  Widget _pit(GameTheme t, int idx, int owner) {
    final seeds = _board[idx];
    final mine = owner == _turn && !_ps[_turn].isBot;
    final playable = mine && !_busy && !_over && seeds > 0;
    return GestureDetector(
      onTap: playable ? () => _sow(idx) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 74,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: t.radius,
          border: Border.all(
            color: playable ? _ps[owner].color : t.muted.withValues(alpha: 0.25),
            width: playable ? 3 : 1.5,
          ),
          boxShadow: playable
              ? [
                  BoxShadow(
                    color: _ps[owner].color.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _seedsView(seeds, _ps[owner].color),
            const SizedBox(height: 2),
            Text(
              '$seeds',
              style: TextStyle(
                  color: t.text, fontWeight: FontWeight.w900, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _storePit(GameTheme t, int idx, Player owner) {
    return Container(
      width: 64,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: owner.color.withValues(alpha: 0.18),
        borderRadius: t.radius,
        border: Border.all(color: owner.color, width: 2.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(owner.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text('🫘', style: const TextStyle(fontSize: 16)),
          Text(
            '${_board[idx]}',
            style: TextStyle(
                color: t.text, fontWeight: FontWeight.w900, fontSize: 20),
          ),
          Text('store',
              style: TextStyle(color: t.muted, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _seedsView(int n, Color color) {
    if (n == 0) return const SizedBox(height: 8);
    if (n > 12) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
              width: 9, height: 9,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text('×$n',
              style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
        ],
      );
    }
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 3,
      runSpacing: 3,
      children: [
        for (int i = 0; i < n; i++)
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 2)
              ],
            ),
          ),
      ],
    );
  }
}
