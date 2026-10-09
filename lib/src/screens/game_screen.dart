import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../ai/mancala_ai.dart';
import '../artisan/painters.dart';
import '../artisan/palette.dart';
import '../artisan/widgets.dart';
import '../audio/audio_service.dart';
import '../engine/mancala_engine.dart';
import '../services/store_service.dart';
import '../settings/app_settings.dart';
import 'game_over.dart';
import 'settings_screen.dart';

/// Engine-owned turn phases. The UI never advances the game on its own
/// timers: every transition flows through [_setPhase], and the watchdog
/// recovers any phase that stops making progress.
enum _Phase { idle, animating, settling, botThinking, over }

/// Artisan Mancala game board (portrait): opponent plate — walnut slab with
/// 2×6 concave pits and 2 end stores — turn banner — own plate + controls.
///
/// Stones sow one at a time with weight; bot turns animate fully and are
/// narrated; illegal taps shake. A watchdog guarantees no stuck states.
class GameScreen extends StatefulWidget {
  final AppSettings settings;
  final StoreService store;

  const GameScreen({super.key, required this.settings, required this.store});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late MancalaEngine _engine;
  late List<int> _shown; // animated board
  final _rng = Random();

  _Phase _phase = _Phase.idle;
  bool _paused = false;
  bool _over = false;
  bool _botScheduled = false;
  int _moveToken = 0; // invalidates in-flight bot turns on restart
  int _round = 1;
  int _shakeToken = 0;
  int _shakePit = -1;
  int _popToken = 0;
  int _popPit = -1;
  DateTime _lastAdvance = DateTime.now();
  Timer? _watchdog;

  // Match stats.
  int _captures = 0;
  int _freeTurns = 0;
  int _sownStones = 0;

  String _banner = '';
  late AnimationController _pulse;

  Set<int> get _botSeats => widget.settings.botSeats;
  String _seatName(int seat) => widget.settings.seatName(seat);
  bool get _botTurn =>
      !_over && _botSeats.contains(_engine.turn) && _phase == _Phase.idle;
  bool get _humanTurn =>
      !_over &&
      _phase == _Phase.idle &&
      !_botSeats.contains(_engine.turn);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _engine = MancalaEngine.fresh();
    _shown = List<int>.from(_engine.board);
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _banner = _turnBannerText();
    AudioService.instance.gameMusic();
    _watchdog = Timer.periodic(const Duration(seconds: 1), (_) => _watch());
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeBotMove());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _watchdog?.cancel();
    _pulse.dispose();
    _moveToken++; // cancel any in-flight bot turn
    AudioService.instance.menuMusic();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && !_over && !_paused && mounted) {
      _pauseGame();
    }
  }

  // ------------------------------------------------------- phase + watchdog
  void _setPhase(_Phase p) {
    _phase = p;
    _lastAdvance = DateTime.now();
  }

  void _touch() {
    _lastAdvance = DateTime.now();
  }

  /// Watchdog: every second, verify the turn machine is making progress.
  /// - A bot turn with no scheduled move for > 2.5s gets re-scheduled.
  /// - Any non-idle phase silent for > 10s is force-settled back to idle.
  /// Stuck states are impossible by construction.
  void _watch() {
    if (!mounted || _over || _paused) return;
    final silent = DateTime.now().difference(_lastAdvance);
    if (_phase == _Phase.idle) {
      if (_botSeats.contains(_engine.turn) &&
          !_botScheduled &&
          silent > const Duration(milliseconds: 2500)) {
        _maybeBotMove();
      }
      return;
    }
    if (silent > const Duration(seconds: 10)) {
      debugPrint('Mancala watchdog: recovering stuck phase $_phase');
      _recover();
    }
  }

  void _recover() {
    _moveToken++;
    _botScheduled = false;
    _shown = List<int>.from(_engine.board);
    _setPhase(_Phase.idle);
    if (mounted) {
      setState(() => _banner = _turnBannerText());
      _maybeBotMove();
    }
  }

  // ------------------------------------------------------------------ text
  String _turnBannerText() {
    if (_over) return '';
    final name = _seatName(_engine.turn);
    if (_botSeats.contains(_engine.turn)) {
      return '◆  $name is studying the board…  ◆';
    }
    return '◆  $name — tap a glowing pit to sow  ◆';
  }

  // ------------------------------------------------------------------ moves
  Future<void> _onPitTap(int pit) async {
    if (_over || _phase != _Phase.idle || _paused) return;
    if (_botSeats.contains(_engine.turn)) return; // bot thinking
    if (!_engine.isLegal(pit)) {
      _illegalTap(pit);
      return;
    }
    await _doMove(pit);
  }

  void _illegalTap(int pit) {
    AudioService.instance.invalid();
    HapticFeedback.mediumImpact();
    setState(() {
      _shakePit = pit;
      _shakeToken++;
      _banner = '◆  That pit can\u2019t be sown — choose a glowing one  ◆';
    });
  }

  Future<void> _waitWhilePaused() async {
    while (_paused && mounted) {
      await Future.delayed(const Duration(milliseconds: 120));
    }
  }

  Future<void> _doMove(int pit) async {
    final token = _moveToken;
    _setPhase(_Phase.animating);
    MoveResult result;
    List<int> path;
    try {
      path = _engine.sowPath(pit);
      result = _engine.sow(pit);
    } catch (_) {
      _recover();
      return;
    }

    final mover = _seatName(result.player);
    _sownStones += result.hand;
    if (result.captured > 0) _captures += result.captured;
    if (result.freeTurn) _freeTurns++;

    AudioService.instance.scoop();
    setState(() {
      _shown[pit] = 0;
      _banner = '◆  $mover sows ${result.hand} stones…  ◆';
    });

    // Drop stones one at a time around the board — fully visible for bots.
    try {
      for (final dest in path) {
        await Future.delayed(const Duration(milliseconds: 210));
        if (!mounted || token != _moveToken) return;
        await _waitWhilePaused();
        if (!mounted || token != _moveToken) return;
        _touch();
        setState(() {
          _shown[dest]++;
          _popPit = dest;
          _popToken++;
        });
        AudioService.instance.sowDrop();
        if (widget.settings.vibration) HapticFeedback.lightImpact();
      }

      await Future.delayed(const Duration(milliseconds: 320));
      if (!mounted || token != _moveToken) return;
      await _waitWhilePaused();

      // Snap to the resolved board (captures / store landings settle).
      _setPhase(_Phase.settling);
      setState(() => _shown = List<int>.from(_engine.board));

      if (result.captured > 0) {
        AudioService.instance.capture();
        if (widget.settings.vibration) HapticFeedback.mediumImpact();
        setState(() => _banner =
            '◆  $mover CAPTURES +${result.captured} stones!  ◆');
        await Future.delayed(const Duration(milliseconds: 900));
      } else if (result.freeTurn) {
        AudioService.instance.freeTurn();
        setState(
            () => _banner = '◆  $mover lands in the store — bonus turn!  ◆');
        await Future.delayed(const Duration(milliseconds: 700));
      }
      if (!mounted || token != _moveToken) return;

      if (result.gameOver) {
        await _finishGame(token);
        return;
      }

      if (result.player == 1 && _engine.turn == 0) _round++;
      _setPhase(_Phase.idle);
      if (!mounted || token != _moveToken) return;
      setState(() => _banner = _turnBannerText());
      _maybeBotMove();
    } catch (_) {
      _recover();
    }
  }

  Future<void> _finishGame(int token) async {
    _setPhase(_Phase.over);
    _over = true;
    // Sweep animation: remaining pits empty into the stores one by one.
    setState(() => _banner = '◆  Final sweep — gathering the harvest…  ◆');
    for (var i = 0; i < 14; i++) {
      if (i == 6 || i == 13) continue;
      while (_shown[i] > 0) {
        await Future.delayed(const Duration(milliseconds: 55));
        if (!mounted || token != _moveToken) return;
        await _waitWhilePaused();
        _touch();
        setState(() {
          _shown[i]--;
          _shown[i < 6 ? 6 : 13]++;
        });
        AudioService.instance.sowDrop();
      }
    }
    setState(() => _shown = List<int>.from(_engine.board));
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted || token != _moveToken) return;

    final s0 = _engine.board[MancalaEngine.storeOf(0)];
    final s1 = _engine.board[MancalaEngine.storeOf(1)];
    final winner = _engine.winner;

    // Persist results when a human took part (solo / mixed).
    final mode = widget.settings.mode;
    if (mode == GameMode.solo || mode == GameMode.mixed) {
      final humanSeat =
          mode == GameMode.solo ? widget.settings.humanSide : 1 - widget.settings.mixedBotSeat;
      final outcome =
          winner == null ? 0 : (winner == humanSeat ? 1 : -1);
      widget.settings.recordBotResult(outcome, (s0 - s1).abs());
    }

    if (winner == null) {
      AudioService.instance.freeTurn();
    } else if (!_botSeats.contains(winner)) {
      AudioService.instance.win();
      if (widget.settings.vibration) HapticFeedback.heavyImpact();
    } else {
      AudioService.instance.lose();
    }

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameOverScreen(
          settings: widget.settings,
          store: widget.store,
          p0Name: _seatName(0),
          p1Name: _seatName(1),
          score0: s0,
          score1: s1,
          winner: winner,
          captures: _captures,
          freeTurns: _freeTurns,
          sownStones: _sownStones,
          rounds: _round,
        ),
      ),
    );
  }

  // -------------------------------------------------------------------- bot
  void _maybeBotMove() {
    if (!_botTurn || _botScheduled || _paused) return;
    _botScheduled = true;
    _setPhase(_Phase.botThinking);
    final token = _moveToken;
    final thinkMs = _rng.nextInt(400) + 650;
    Future.delayed(Duration(milliseconds: thinkMs), () async {
      if (!mounted || token != _moveToken || _paused) {
        _botScheduled = false;
        if (_phase == _Phase.botThinking) _setPhase(_Phase.idle);
        return;
      }
      final pit = await _computeBotPit();
      _botScheduled = false;
      if (!mounted || token != _moveToken || pit < 0) {
        if (_phase == _Phase.botThinking) _setPhase(_Phase.idle);
        return;
      }
      if (_phase == _Phase.botThinking) _setPhase(_Phase.idle);
      await _doMove(pit);
    });
  }

  Future<int> _computeBotPit() async {
    final difficulty = widget.settings.difficulty;
    if (difficulty == BotDifficulty.master) {
      // Deep search off the UI thread; never blocks a frame.
      try {
        return await compute(_botCompute, <dynamic>[
          List<int>.from(_engine.board),
          _engine.turn,
          _engine.turn,
          difficulty.index,
          _rng.nextInt(1 << 30),
        ]);
      } catch (_) {
        // Fall through to a fast local choice.
      }
    }
    return chooseBotMove(_engine, _engine.turn, difficulty, _rng);
  }

  // ------------------------------------------------------------- pause/menu
  void _pauseGame() {
    if (_over || _paused) return;
    setState(() => _paused = true);
    AudioService.instance.uiClick();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PauseDialog(
        onResume: () {
          Navigator.of(context).pop();
          setState(() {
            _paused = false;
            _banner = _turnBannerText();
          });
          _touch();
          _maybeBotMove();
        },
        onRestart: () {
          Navigator.of(context).pop();
          _restart();
        },
        onMenu: () {
          _moveToken++;
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _restart() {
    AudioService.instance.gameStart();
    setState(() {
      _moveToken++; // cancel in-flight bot turn / sow loop
      _engine = MancalaEngine.fresh();
      _shown = List<int>.from(_engine.board);
      _botScheduled = false;
      _paused = false;
      _over = false;
      _round = 1;
      _captures = 0;
      _freeTurns = 0;
      _sownStones = 0;
      _banner = _turnBannerText();
    });
    _setPhase(_Phase.idle);
    _maybeBotMove();
  }

  void _confirmRestart() {
    AudioService.instance.uiClick();
    showDialog(
      context: context,
      builder: (_) => _ConfirmDialog(
        title: 'Restart the game?',
        body: 'The board will be reset to a fresh harvest.',
        confirm: 'RESTART',
        onConfirm: () {
          Navigator.of(context).pop();
          _restart();
        },
      ),
    );
  }

  // ------------------------------------------------------------------ build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtisanPalette.clay,
      body: ArtisanScaffold(
        child: Column(
          children: [
            const SizedBox(height: 4),
            _topBar(),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: PlayerPlate(
                name: _seatName(1),
                mineral: widget.settings.activeStones.name,
                dotKind: StoneKind.jade,
                count: _engine.board[MancalaEngine.storeOf(1)],
                active: !_over && _engine.turn == 1,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: TurnBanner(text: _banner),
            ),
            const SizedBox(height: 8),
            Expanded(child: _boardSlab()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: PlayerPlate(
                name: _seatName(0),
                mineral: widget.settings.activeStones.name,
                dotKind: StoneKind.amber,
                count: _engine.board[MancalaEngine.storeOf(0)],
                active: !_over && _engine.turn == 0,
              ),
            ),
            const SizedBox(height: 10),
            _bottomBar(),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          WoodIconButton(
              icon: Icons.pause,
              size: 40,
              onTap: () {
                if (!_over) _pauseGame();
              }),
          Expanded(
            child: Column(
              children: [
                Text('Kalah', style: ArtisanType.plaqueTitle(size: 20)),
                Text(widget.settings.modeLabel,
                    style: ArtisanType.label(size: 9)),
              ],
            ),
          ),
          WoodIconButton(
            icon: Icons.settings,
            size: 40,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SettingsScreen(
                    settings: widget.settings, store: widget.store),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _boardSlab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final slabW = constraints.maxWidth - 28;
        const storeW = 52.0;
        const gap = 5.0;
        const pad = 10.0;
        final cellW = (slabW - pad * 2 - storeW * 2 - gap * 2) / 6;
        final pitD = cellW.clamp(30.0, 68.0);
        final storeH = pitD * 2 + 46;

        return Center(
          child: Container(
            width: slabW,
            padding: const EdgeInsets.symmetric(horizontal: pad, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: ArtisanPalette.woodEdge, width: 1.5),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black87,
                    blurRadius: 20,
                    offset: Offset(0, 10)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CustomPaint(
                painter: const WoodSlabPainter(seed: 2024, radius: 16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _storeView(13, 1, storeW, storeH),
                      SizedBox(width: gap),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            EngravedTag(text: '${_seatName(1)}  ←'),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                for (var p = 12; p >= 7; p--)
                                  _pitCell(p, 1, cellW, pitD),
                              ],
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 5),
                              child: Text('NORTH',
                                  style: ArtisanType.label(size: 8)),
                            ),
                            Row(
                              children: [
                                for (var p = 0; p <= 5; p++)
                                  _pitCell(p, 0, cellW, pitD),
                              ],
                            ),
                            const SizedBox(height: 6),
                            EngravedTag(
                                text:
                                    '${_seatName(0)}  →   (${_shown.sublist(0, 6).fold(0, (a, b) => a + b)})'),
                          ],
                        ),
                      ),
                      SizedBox(width: gap),
                      _storeView(6, 0, storeW, storeH),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _pitCell(int pit, int owner, double cellW, double pitD) {
    final playable = _humanTurn &&
        !_paused &&
        MancalaEngine.isOwnPit(pit, _engine.turn) &&
        _shown[pit] > 0;
    return SizedBox(
      width: cellW,
      child: Center(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _onPitTap(pit),
          child: Container(
            width: cellW,
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: Colors.transparent,
            child: Center(
              child: _PitView(
                pit: pit,
                owner: owner,
                count: _shown[pit],
                diameter: pitD,
                playable: playable,
                pulse: _pulse,
                shakeToken: pit == _shakePit ? _shakeToken : 0,
                popToken: pit == _popPit ? _popToken : 0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _storeView(int index, int owner, double w, double h) {
    final count = _shown[index];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        EngravedTag(text: _seatName(owner).split(' ·').first),
        const SizedBox(height: 4),
        Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(w / 2),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black87, blurRadius: 8, offset: Offset(0, 4)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(w / 2),
            child: CustomPaint(
              painter: const PitPainter(),
              child: Center(
                child: _stoneCluster(
                    count, owner, index, maxStones: 8, stoneSize: 13),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF7EFE1), Color(0xFFDFD1BC)],
            ),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black54, blurRadius: 3, offset: Offset(0, 2)),
            ],
          ),
          child: Text('$count', style: ArtisanType.count(size: 13)),
        ),
      ],
    );
  }

  /// A small cluster of glass stones; large counts collapse to ×N.
  Widget _stoneCluster(
      int count, int owner, int pitIndex, {int maxStones = 9, double stoneSize = 12}) {
    if (count == 0) return const SizedBox.shrink();
    if (count > maxStones) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GlassStone(
              kind: stoneKindFor(owner, pitIndex, 0),
              size: stoneSize,
              seed: pitIndex),
          const SizedBox(width: 3),
          Text('×$count',
              style: ArtisanType.bodyText(
                  size: 12, color: ArtisanPalette.bone)),
        ],
      );
    }
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 2,
      runSpacing: 2,
      children: [
        for (var s = 0; s < count; s++)
          GlassStone(
            kind: stoneKindFor(owner, pitIndex, s),
            size: stoneSize,
            seed: pitIndex * 7 + s,
          ),
      ],
    );
  }

  Widget _bottomBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _miniStat(Icons.timelapse, 'Round', '$_round'),
              const SizedBox(width: 18),
              _miniStat(Icons.stars_outlined, 'Stones in Play',
                  '${_engine.stonesInPlay()}'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ArtisanButton(
                  label: 'RESTART',
                  icon: Icons.replay,
                  onTap: _confirmRestart,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ArtisanButton(
                  label: 'MENU',
                  icon: Icons.menu,
                  onTap: () {
                    _moveToken++;
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF120A05),
        border: Border.all(
            color: ArtisanPalette.brass.withValues(alpha: 0.45), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: ArtisanPalette.brass, size: 14),
          const SizedBox(width: 6),
          Text(label, style: ArtisanType.label(size: 9)),
          const SizedBox(width: 6),
          Text(value,
              style: ArtisanType.bodyText(
                  size: 13, color: ArtisanPalette.bone)),
        ],
      ),
    );
  }
}

/// A single pit: concave cavity, glass stones, ember ring when playable,
/// shake on illegal taps, pop when a stone lands.
class _PitView extends StatefulWidget {
  final int pit;
  final int owner;
  final int count;
  final double diameter;
  final bool playable;
  final Animation<double> pulse;
  final int shakeToken;
  final int popToken;

  const _PitView({
    required this.pit,
    required this.owner,
    required this.count,
    required this.diameter,
    required this.playable,
    required this.pulse,
    required this.shakeToken,
    required this.popToken,
  });

  @override
  State<_PitView> createState() => _PitViewState();
}

class _PitViewState extends State<_PitView>
    with TickerProviderStateMixin {
  late AnimationController _shake;
  late AnimationController _pop;
  int _lastShake = 0;
  int _lastPop = 0;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
    _pop = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 220));
    _lastShake = widget.shakeToken;
    _lastPop = widget.popToken;
  }

  @override
  void didUpdateWidget(covariant _PitView old) {
    super.didUpdateWidget(old);
    if (widget.shakeToken != _lastShake && widget.shakeToken != 0) {
      _lastShake = widget.shakeToken;
      _shake.forward(from: 0);
    }
    if (widget.popToken != _lastPop && widget.popToken != 0) {
      _lastPop = widget.popToken;
      _pop.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_shake, _pop, widget.pulse]),
      builder: (context, _) {
        final shakeX = _shake.value == 0
            ? 0.0
            : sin(_shake.value * pi * 5) * 7 * (1 - _shake.value);
        final popScale = 1.0 + sin(_pop.value * pi) * 0.22;
        final pulse = widget.pulse.value; // 0..1
        return Transform.translate(
          offset: Offset(shakeX, 0),
          child: Transform.scale(
            scale: popScale,
            child: SizedBox(
              width: widget.diameter,
              height: widget.diameter,
              child: CustomPaint(
                painter: PitPainter(
                    active: widget.playable, pulse: pulse),
                child: Center(
                  child: widget.count == 0
                      ? const SizedBox.shrink()
                      : _stones(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _stones() {
    final n = widget.count;
    const maxShow = 7;
    if (n > maxShow) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GlassStone(
              kind: stoneKindFor(widget.owner, widget.pit, 0),
              size: widget.diameter * 0.26,
              seed: widget.pit),
          const SizedBox(width: 3),
          Text('×$n',
              style: ArtisanType.bodyText(
                  size: widget.diameter * 0.24,
                  color: ArtisanPalette.bone)),
        ],
      );
    }
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 2,
      runSpacing: 2,
      children: [
        for (var s = 0; s < n; s++)
          GlassStone(
            kind: stoneKindFor(widget.owner, widget.pit, s),
            size: widget.diameter * (n > 4 ? 0.22 : 0.27),
            seed: widget.pit * 7 + s,
          ),
      ],
    );
  }
}

/// Pause overlay: carved panel with Resume / Restart / Main Menu.
class _PauseDialog extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onMenu;

  const _PauseDialog({
    required this.onResume,
    required this.onRestart,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ArtisanPalette.brass, width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: CustomPaint(
            painter: const WoodSlabPainter(seed: 31, radius: 14),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('PAUSED',
                      style: ArtisanType.plaqueTitle(size: 24)),
                  const SizedBox(height: 4),
                  Text('The stones wait patiently',
                      style: ArtisanType.label(size: 10)),
                  const SizedBox(height: 20),
                  ArtisanButton(
                      label: 'RESUME',
                      icon: Icons.play_arrow,
                      primary: true,
                      width: double.infinity,
                      onTap: onResume),
                  const SizedBox(height: 10),
                  ArtisanButton(
                      label: 'RESTART',
                      icon: Icons.replay,
                      width: double.infinity,
                      onTap: onRestart),
                  const SizedBox(height: 10),
                  ArtisanButton(
                      label: 'MAIN MENU',
                      icon: Icons.home_outlined,
                      width: double.infinity,
                      onTap: onMenu),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfirmDialog extends StatelessWidget {
  final String title;
  final String body;
  final String confirm;
  final VoidCallback onConfirm;

  const _ConfirmDialog({
    required this.title,
    required this.body,
    required this.confirm,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ArtisanPalette.brass, width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: CustomPaint(
            painter: const WoodSlabPainter(seed: 33, radius: 14),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      textAlign: TextAlign.center,
                      style: ArtisanType.sectionTitle(size: 16)),
                  const SizedBox(height: 8),
                  Text(body,
                      textAlign: TextAlign.center,
                      style: ArtisanType.bodyText(size: 13)),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: ArtisanButton(
                          label: 'CANCEL',
                          onTap: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ArtisanButton(
                          label: confirm,
                          primary: true,
                          onTap: onConfirm,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bot search entry point for [compute]: args = [board, turn, player,
/// difficultyIndex, seed] → chosen pit.
int _botCompute(List<dynamic> args) {
  final board = (args[0] as List).cast<int>();
  final turn = args[1] as int;
  final player = args[2] as int;
  final difficulty = BotDifficulty.values[args[3] as int];
  final rng = Random(args[4] as int);
  final engine = MancalaEngine.fromBoard(board, turn);
  return chooseBotMove(engine, player, difficulty, rng);
}
