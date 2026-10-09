import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../ai/mancala_ai.dart';
import '../artisan/painters.dart';
import '../artisan/palette.dart';
import '../artisan/widgets.dart';
import '../audio/audio_service.dart';
import '../services/store_service.dart';
import '../settings/app_settings.dart';
import '../theme/mancala_themes.dart';
import 'custom_theme_screen.dart';
import 'how_to_play.dart';
import 'pro_screen.dart';

/// Carved mahogany settings chamber: players, modes, appearance, audio.
class SettingsScreen extends StatelessWidget {
  final AppSettings settings;
  final StoreService store;

  const SettingsScreen({super.key, required this.settings, required this.store});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtisanPalette.clay,
      body: ArtisanScaffold(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  WoodIconButton(
                    icon: Icons.arrow_back,
                    size: 40,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Center(
                      child: Text('Game Chamber',
                          style: ArtisanType.plaqueTitle(size: 20)),
                    ),
                  ),
                  WoodIconButton(
                    icon: Icons.help_outline,
                    size: 40,
                    onTap: () => showHowToPlay(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _chamber(context),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chamber(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ArtisanPalette.woodEdge, width: 1.5),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black87, blurRadius: 18, offset: Offset(0, 8)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: CustomPaint(
              painter: const WoodSlabPainter(
                top: Color(0xFF5C3A21),
                mid: Color(0xFF442A18),
                bottom: Color(0xFF2A1809),
                seed: 123,
                radius: 14,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: ListenableBuilder(
                  listenable: settings,
                  builder: (context, _) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _sectionTitle('◆  PLAYERS  ◆'),
                      _nameField(context, 0),
                      const SizedBox(height: 8),
                      _nameField(context, 1),
                      const _Divider(),
                      _sectionTitle('◆  GAME MODE  ◆'),
                      _modePicker(context),
                      const SizedBox(height: 10),
                      if (settings.mode == GameMode.solo)
                        _sidePicker(
                          label: 'You play',
                          options: const ['Bottom row', 'Top row'],
                          selected: settings.humanSide,
                          onSelected: settings.setHumanSide,
                        ),
                      if (settings.mode == GameMode.mixed)
                        _sidePicker(
                          label: 'Bot plays',
                          options: const ['Bottom row', 'Top row'],
                          selected: settings.mixedBotSeat,
                          onSelected: settings.setMixedBotSeat,
                        ),
                      if (settings.mode != GameMode.pass) ...[
                        const SizedBox(height: 10),
                        Text('Bot difficulty',
                            style: ArtisanType.bodyText(size: 15)),
                        const SizedBox(height: 2),
                        Text(settings.difficulty.blurb,
                            style: ArtisanType.label(size: 10)),
                        const SizedBox(height: 10),
                        DifficultyBeads(
                          selected: settings.difficulty.index,
                          labels: const ['Calm', 'Sharp', 'Master'],
                          onSelected: (i) => settings
                              .setDifficulty(BotDifficulty.values[i]),
                        ),
                        const SizedBox(height: 6),
                      ],
                      const _Divider(),
                      _sectionTitle('◆  BOARD  ◆'),
                      _themeGrid(context),
                      const SizedBox(height: 10),
                      ArtisanButton(
                        label: 'THEME ATELIER (CUSTOM)',
                        icon: Icons.brush_outlined,
                        width: double.infinity,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                CustomThemeScreen(settings: settings),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('Stone style',
                          style: ArtisanType.bodyText(size: 15)),
                      const SizedBox(height: 8),
                      _stonePicker(),
                      const SizedBox(height: 12),
                      Text('Board accent',
                          style: ArtisanType.bodyText(size: 15)),
                      const SizedBox(height: 8),
                      _accentPicker(),
                      const _Divider(),
                      _sectionTitle('◆  SOUND  ◆'),
                      SettingRow(
                        title: 'Music',
                        subtitle: 'Atmospheric kora & kalimba',
                        trailing: CarvedToggle(
                          value: settings.musicEnabled,
                          onChanged: (v) {
                            settings.setMusicEnabled(v);
                            AudioService.instance.applySettings(settings);
                          },
                        ),
                      ),
                      _volumeRow(
                        label: 'Music volume',
                        value: settings.musicVolume,
                        knob: StoneKind.amber,
                        onChanged: (v) {
                          settings.setMusicVolume(v);
                          AudioService.instance.applySettings(settings);
                        },
                      ),
                      SettingRow(
                        title: 'Sound effects',
                        subtitle: 'Stone clacks & pit scoops',
                        trailing: CarvedToggle(
                          value: settings.sfxEnabled,
                          onChanged: (v) {
                            settings.setSfxEnabled(v);
                            AudioService.instance.applySettings(settings);
                          },
                        ),
                      ),
                      _volumeRow(
                        label: 'SFX volume',
                        value: settings.sfxVolume,
                        knob: StoneKind.jade,
                        onChanged: (v) {
                          settings.setSfxVolume(v);
                          AudioService.instance.applySettings(settings);
                          AudioService.instance.uiClick();
                        },
                      ),
                      SettingRow(
                        title: 'Vibration',
                        subtitle: 'Haptic stone drops',
                        trailing: CarvedToggle(
                          value: settings.vibration,
                          onChanged: settings.setVibration,
                        ),
                      ),
                      const _Divider(),
                      ArtisanButton(
                        label: settings.isPro
                            ? 'PRO ACTIVE'
                            : 'GET MANCALA PRO',
                        icon: Icons.workspace_premium_outlined,
                        primary: true,
                        width: double.infinity,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ProScreen(
                                settings: settings, store: store),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ArtisanButton(
                        label: 'RESET DEFAULTS',
                        icon: Icons.restart_alt,
                        width: double.infinity,
                        onTap: () {
                          settings.resetDefaults();
                          AudioService.instance.applySettings(settings);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        for (final pos in [
          const Alignment(-1, -1),
          const Alignment(1, -1),
          const Alignment(-1, 1),
          const Alignment(1, 1),
        ])
          Align(
            alignment: pos,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: SizedBox(
                  width: 12,
                  height: 12,
                  child: CustomPaint(painter: RivetPainter())),
            ),
          ),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Center(
        child: Text(text, style: ArtisanType.sectionTitle(size: 15)),
      ),
    );
  }

  // ---------------------------------------------------------------- players
  Widget _nameField(BuildContext context, int seat) {
    final isBot = settings.botSeats.contains(seat);
    return Row(
      children: [
        GlassStone(
            kind: seat == 0 ? StoneKind.amber : StoneKind.jade,
            size: 22,
            seed: seat),
        const SizedBox(width: 10),
        Expanded(
          child: _NameField(
            key: ValueKey('name-$seat'),
            label: seat == 0 ? 'Bottom row' : 'Top row',
            initial: settings.playerNames[seat],
            onSubmitted: (v) {
              settings.setPlayerName(seat, v);
              AudioService.instance.uiClick();
            },
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: const Color(0xFF120A05),
            border: Border.all(
                color: ArtisanPalette.brass.withValues(alpha: 0.5)),
          ),
          child: Text(isBot ? 'BOT' : 'HUMAN',
              style: ArtisanType.label(size: 9)),
        ),
      ],
    );
  }

  // ------------------------------------------------------------------- mode
  Widget _modePicker(BuildContext context) {
    final modes = [
      (GameMode.solo, 'Vs Bot', Icons.smart_toy_outlined),
      (GameMode.pass, '2 Players', Icons.group_outlined),
      (GameMode.mixed, 'Human+Bot', Icons.diversity_3_outlined),
      (GameMode.watch, 'Watch', Icons.visibility_outlined),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.6,
      children: [
        for (final (m, label, icon) in modes)
          GestureDetector(
            onTap: () {
              AudioService.instance.uiClick();
              settings.setMode(m);
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: settings.mode == m
                      ? ArtisanPalette.brass
                      : ArtisanPalette.woodEdge,
                  width: settings.mode == m ? 2 : 1.2,
                ),
                color: settings.mode == m
                    ? ArtisanPalette.brass.withValues(alpha: 0.15)
                    : const Color(0xFF120A05),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon,
                      color: settings.mode == m
                          ? ArtisanPalette.brassLight
                          : ArtisanPalette.boneDim,
                      size: 18),
                  const SizedBox(width: 6),
                  Text(label, style: ArtisanType.bodyText(size: 13)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _sidePicker({
    required String label,
    required List<String> options,
    required int selected,
    required ValueChanged<int> onSelected,
  }) {
    return Row(
      children: [
        Text(label, style: ArtisanType.bodyText(size: 13)),
        const SizedBox(width: 10),
        for (var i = 0; i < options.length; i++)
          Expanded(
            child: GestureDetector(
              onTap: () {
                AudioService.instance.uiClick();
                onSelected(i);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected == i
                        ? ArtisanPalette.brass
                        : ArtisanPalette.woodEdge,
                    width: selected == i ? 2 : 1.2,
                  ),
                  color: selected == i
                      ? ArtisanPalette.brass.withValues(alpha: 0.15)
                      : Colors.transparent,
                ),
                child: Center(
                  child: Text(options[i],
                      style: ArtisanType.bodyText(size: 12)),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // --------------------------------------------------------------- board UI
  Widget _themeGrid(BuildContext context) {
    final ids = [
      ...MancalaThemes.freeThemeIds,
      'custom',
      for (final t in MancalaThemes.all)
        if (!MancalaThemes.freeThemeIds.contains(t.id)) t.id,
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 0.92,
      children: [
        for (final id in ids)
          Builder(builder: (_) {
            final isCustom = id == 'custom';
            final theme = MancalaThemes.byId(id,
                custom: settings.customTheme);
            final locked =
                !settings.isPro && MancalaThemes.isProTheme(id);
            final selected = settings.themeId == id;
            return GestureDetector(
              onTap: () {
                if (locked) {
                  HapticFeedback.mediumImpact();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          ProScreen(settings: settings, store: store),
                    ),
                  );
                  return;
                }
                AudioService.instance.uiClick();
                settings.setTheme(id);
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? ArtisanPalette.brass
                        : ArtisanPalette.woodEdge,
                    width: selected ? 2.5 : 1.2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CustomPaint(
                    painter: WoodSlabPainter(
                      top: theme.mahoganyLight,
                      mid: theme.woodDark,
                      bottom: theme.woodDeep,
                      seed: id.hashCode,
                      radius: 10,
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _dot(theme.woodEdge),
                                  _dot(theme.pitInner),
                                  _dot(brassSafe(theme)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4),
                                child: Text(
                                  isCustom ? 'My Creation' : theme.name,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: ArtisanType.label(size: 9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (locked)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Icon(Icons.lock,
                                size: 14,
                                color: ArtisanPalette.boneDim),
                          ),
                        if (selected)
                          Positioned(
                            top: 4,
                            left: 4,
                            child: Icon(Icons.check_circle,
                                size: 14,
                                color: ArtisanPalette.brassLight),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Color brassSafe(MancalaThemeDef t) => t.id == 'custom'
      ? Color(settings.customColors['accent'] ?? 0xFFB08D3C)
      : BoardAccents.byIndex(settings.accent).accent;

  Widget _dot(Color c) {
    return Container(
      width: 14,
      height: 14,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c,
        border: Border.all(color: Colors.black45),
      ),
    );
  }

  Widget _stonePicker() {
    return Column(
      children: [
        for (var i = 0; i < StoneStyles.all.length; i++)
          Builder(builder: (_) {
            final s = StoneStyles.all[i];
            final locked = !settings.isPro && StoneStyles.isPro(i);
            final selected =
                settings.stoneStyle == i && settings.themeId != 'custom';
            return GestureDetector(
              onTap: () {
                if (locked) {
                  HapticFeedback.mediumImpact();
                  return;
                }
                AudioService.instance.uiClick();
                settings.setStoneStyle(i);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? ArtisanPalette.brass
                        : ArtisanPalette.woodEdge,
                    width: selected ? 2 : 1.2,
                  ),
                  color: selected
                      ? ArtisanPalette.brass.withValues(alpha: 0.12)
                      : const Color(0xFF120A05),
                ),
                child: Row(
                  children: [
                    _stoneDot(s.p0[1]),
                    _stoneDot(s.p0Alt[1]),
                    _stoneDot(s.p1[1]),
                    _stoneDot(s.p1Alt[1]),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.name,
                              style: ArtisanType.bodyText(size: 13)),
                          Text(s.blurb,
                              style: ArtisanType.label(size: 9)),
                        ],
                      ),
                    ),
                    if (locked)
                      Icon(Icons.lock,
                          size: 16, color: ArtisanPalette.boneDim),
                    if (selected)
                      Icon(Icons.check_circle,
                          size: 16,
                          color: ArtisanPalette.brassLight),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _stoneDot(Color c) {
    return Container(
      width: 20,
      height: 20,
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [c.withValues(alpha: 0.7), c]),
        border: Border.all(color: Colors.black45),
      ),
    );
  }

  Widget _accentPicker() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < BoardAccents.all.length; i++)
          Builder(builder: (_) {
            final a = BoardAccents.all[i];
            final locked = !settings.isPro && BoardAccents.isPro(i);
            final selected =
                settings.accent == i && settings.themeId != 'custom';
            return GestureDetector(
              onTap: () {
                if (locked) {
                  HapticFeedback.mediumImpact();
                  return;
                }
                AudioService.instance.uiClick();
                settings.setAccent(i);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected
                        ? ArtisanPalette.brassLight
                        : ArtisanPalette.woodEdge,
                    width: selected ? 2 : 1.2,
                  ),
                  color: selected
                      ? ArtisanPalette.brass.withValues(alpha: 0.12)
                      : const Color(0xFF120A05),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [a.accentLight, a.accent],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(a.name, style: ArtisanType.label(size: 10)),
                    if (locked) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.lock,
                          size: 12, color: ArtisanPalette.boneDim),
                    ],
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _volumeRow({
    required String label,
    required double value,
    required StoneKind knob,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: ArtisanType.label(size: 10)),
          ),
          Expanded(
            child: NotchedSlider(
              value: value,
              knobKind: knob,
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 46,
            child: Text('${(value * 100).round()}%',
                textAlign: TextAlign.right,
                style: ArtisanType.bodyText(
                    size: 12, color: ArtisanPalette.brassLight)),
          ),
        ],
      ),
    );
  }
}

/// Renameable player slot: controller lives in State so rebuilds never
/// steal the cursor.
class _NameField extends StatefulWidget {
  final String label;
  final String initial;
  final ValueChanged<String> onSubmitted;

  const _NameField({
    super.key,
    required this.label,
    required this.initial,
    required this.onSubmitted,
  });

  @override
  State<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<_NameField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      maxLength: 14,
      style: ArtisanType.bodyText(size: 15),
      decoration: InputDecoration(
        counterText: '',
        labelText: widget.label,
        labelStyle: ArtisanType.label(size: 10),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: ArtisanPalette.woodEdge),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: ArtisanPalette.brass, width: 2),
        ),
      ),
      onSubmitted: widget.onSubmitted,
    );
  }
}

class _Divider extends StatelessWidget {  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            ArtisanPalette.brass.withValues(alpha: 0.4),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
