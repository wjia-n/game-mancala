import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';
import 'game_screen.dart';

void main() => runApp(const MancalaApp());

class MancalaApp extends StatelessWidget {
  const MancalaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GameShell(
      variant: ShellVariant.zenStone,
      title: 'Mancala',
      tagline: 'The ancient battle of wits — sow smart, capture big! 🫘',
      emoji: '🫘',
      slug: 'mancala',
      howToPlay: '• Tap one of YOUR pits to sow its seeds\n'
          '• Seeds drop one-by-one, counter-clockwise\n'
          '• Land your last seed in your store (right side 🏪) for a BONUS turn\n'
          '• Land in an empty pit of yours to CAPTURE the opposite pit! 💰\n'
          '• Game ends when one side is empty — most seeds in store wins!',
      playerOptions: const [1, 2],
      supportsBots: true,
      gameBuilder: (ctx, players, cb) => MancalaScreen(players: players, callbacks: cb),
    );
  }
}
