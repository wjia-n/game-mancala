import 'package:flutter/material.dart';
import '../artisan/painters.dart';
import '../artisan/palette.dart';
import '../artisan/widgets.dart';
import '../audio/audio_service.dart';
import '../settings/app_settings.dart';
import 'game_screen.dart';

/// Victory / defeat / draw screen per the Stitch "Mancala Victory" design:
/// carved banner → overflowing grand store → tally panels → match stats.
class GameOverScreen extends StatefulWidget {
  final AppSettings settings;
  final bool vsBot;
  final String p0Name;
  final String p1Name;
  final int score0;
  final int score1;
  final int? winner; // null = draw
  final int captures;
  final int freeTurns;
  final int sownStones;
  final int rounds;

  const GameOverScreen({
    super.key,
    required this.settings,
    required this.vsBot,
    required this.p0Name,
    required this.p1Name,
    required this.score0,
    required this.score1,
    required this.winner,
    required this.captures,
    required this.freeTurns,
    required this.sownStones,
    required this.rounds,
  });

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _in;
  late Animation<double> _scale;

  bool get _draw => widget.winner == null;
  bool get _humanWon =>
      widget.winner != null && (!widget.vsBot || widget.winner == 0);

  String get _bannerTitle {
    if (_draw) return 'DRAW';
    if (_humanWon) return 'VICTORY';
    return 'DEFEAT';
  }

  String get _bannerSub {
    if (_draw) return 'An honorable harvest, evenly split';
    if (_humanWon) return 'Your harvest is plentiful!';
    if (widget.vsBot) return 'The bot out-harvested you this time';
    return '${_winnerName()} takes the harvest!';
  }

  String _winnerName() =>
      widget.winner == 0 ? widget.p0Name : widget.p1Name;

  @override
  void initState() {
    super.initState();
    _in = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _scale = CurvedAnimation(parent: _in, curve: Curves.elasticOut);
    _in.forward();
  }

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtisanPalette.clay,
      body: ArtisanScaffold(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  WoodIconButton(
                    icon: Icons.arrow_back,
                    size: 40,
                    onTap: () => Navigator.of(context)
                        .popUntil((r) => r.isFirst),
                  ),
                  Expanded(
                    child: Center(
                      child: Text('Mancala',
                          style: ArtisanType.plaqueTitle(size: 20)),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: 12),
              ScaleTransition(
                scale: _scale,
                child: _banner(),
              ),
              const SizedBox(height: 16),
              _grandStore(),
              const SizedBox(height: 16),
              _tallyPanels(),
              const SizedBox(height: 14),
              _statsPanel(),
              const SizedBox(height: 18),
              ArtisanButton(
                label: 'PLAY AGAIN',
                icon: Icons.replay,
                primary: true,
                width: double.infinity,
                onTap: () {
                  AudioService.instance.gameStart();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => GameScreen(
                          settings: widget.settings, vsBot: widget.vsBot),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              ArtisanButton(
                label: 'MAIN MENU',
                icon: Icons.home_outlined,
                width: double.infinity,
                onTap: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _banner() {
    final accent = _draw
        ? ArtisanPalette.quartzHi
        : _humanWon
            ? ArtisanPalette.brassLight
            : ArtisanPalette.garnetHi;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ArtisanPalette.brass, width: 1.5),
        boxShadow: const [
          BoxShadow(
              color: Colors.black87, blurRadius: 14, offset: Offset(0, 6)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: CustomPaint(
          painter: const WoodSlabPainter(seed: 11, radius: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              children: [
                Text('◆  $_bannerTitle  ◆',
                    textAlign: TextAlign.center,
                    style: ArtisanType.plaqueTitle(size: 30)
                        .copyWith(color: accent)),
                const SizedBox(height: 4),
                Text(_bannerSub,
                    textAlign: TextAlign.center,
                    style: ArtisanType.label(size: 11)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Overflowing store-pit centerpiece with the winning harvest.
  Widget _grandStore() {
    final winScore =
        widget.winner == null ? widget.score0 : (widget.winner == 0 ? widget.score0 : widget.score1);
    return Column(
      children: [
        Container(
          width: 190,
          height: 190,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: Colors.black87, blurRadius: 20, offset: Offset(0, 8)),
            ],
          ),
          child: ClipOval(
            child: CustomPaint(
              painter: const PitPainter(),
              child: Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 3,
                  runSpacing: 3,
                  children: [
                    for (var s = 0;
                        s < winScore.clamp(0, 24);
                        s++)
                      GlassStone(
                        kind: stoneKindFor(
                            widget.winner == 1 ? 1 : 0, 6, s),
                        size: 17,
                        seed: s * 3,
                      ),
                    if (winScore > 24)
                      Text('×$winScore',
                          style: ArtisanType.bodyText(
                              size: 14, color: ArtisanPalette.bone)),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        EngravedTag(
            text: _draw
                ? 'SHARED HARVEST'
                : 'GRAND STORE — ${_winnerName()}'),
      ],
    );
  }

  Widget _tallyPanels() {
    return Row(
      children: [
        Expanded(
          child: _tally(
            name: widget.vsBot ? 'YOU' : widget.p0Name,
            score: widget.score0,
            player: 0,
            tag: widget.winner == 0 ? 'WINNER' : 'HARVEST',
            highlighted: widget.winner == 0,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _tally(
            name: widget.vsBot ? 'BOT' : widget.p1Name,
            score: widget.score1,
            player: 1,
            tag: widget.winner == 1 ? 'WINNER' : 'HARVEST',
            highlighted: widget.winner == 1,
          ),
        ),
      ],
    );
  }

  Widget _tally({
    required String name,
    required int score,
    required int player,
    required String tag,
    required bool highlighted,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlighted
              ? ArtisanPalette.brass
              : ArtisanPalette.woodEdge,
          width: highlighted ? 2 : 1.2,
        ),
        boxShadow: [
          const BoxShadow(
              color: Colors.black87, blurRadius: 8, offset: Offset(0, 4)),
          if (highlighted)
            BoxShadow(
              color: ArtisanPalette.ember.withValues(alpha: 0.25),
              blurRadius: 12,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: CustomPaint(
          painter: WoodSlabPainter(seed: 60 + player, radius: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                EngravedTag(text: tag),
                const SizedBox(height: 8),
                Text(name, style: ArtisanType.sectionTitle(size: 13)),
                const SizedBox(height: 4),
                Text('$score',
                    style: ArtisanType.plaqueTitle(size: 32)),
                Text('stones', style: ArtisanType.label(size: 9)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var s = 0; s < 3; s++)
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 2),
                        child: GlassStone(
                          kind: stoneKindFor(player, 20, s),
                          size: 13,
                          seed: player * 10 + s,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statsPanel() {
    final margin = (widget.score0 - widget.score1).abs();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ArtisanPalette.woodEdge, width: 1.2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: CustomPaint(
          painter: const WoodSlabPainter(seed: 71, radius: 10),
          child: Container(
            padding:
                const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Column(
              children: [
                Text('MATCH STATISTICS',
                    style: ArtisanType.label(size: 10)),
                const SizedBox(height: 10),
                _statRow('Captures', '${widget.captures} stones'),
                _statRow('Free turns', '${widget.freeTurns}'),
                _statRow('Stones sown', '${widget.sownStones}'),
                _statRow('Rounds played', '${widget.rounds}'),
                if (!_draw) _statRow('Winning margin', '$margin stones'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: ArtisanType.bodyText(size: 13)),
          Text(value,
              style: ArtisanType.bodyText(
                  size: 13, color: ArtisanPalette.brassLight)),
        ],
      ),
    );
  }
}
