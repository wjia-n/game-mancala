import 'package:flutter/material.dart';
import '../artisan/painters.dart';
import '../artisan/palette.dart';
import '../artisan/widgets.dart';
import '../audio/audio_service.dart';
import '../services/store_service.dart';
import '../settings/app_settings.dart';

/// Mancala PRO: Free-vs-Pro comparison, one-time unlock, tip jar.
///
/// Product IDs (created by Wajiha in Play Console): `mancalapro` (one-time),
/// `mancalacoffee` / `mancalachocolate` (consumable tips). Until the products
/// exist, the screen honestly says "available after store setup".
class ProScreen extends StatelessWidget {
  final AppSettings settings;
  final StoreService store;

  const ProScreen({super.key, required this.settings, required this.store});

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
                      child: Text('Mancala Pro',
                          style: ArtisanType.plaqueTitle(size: 20)),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: 12),
              ListenableBuilder(
                listenable: settings,
                builder: (context, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _comparisonCard(),
                    const SizedBox(height: 14),
                    if (settings.isPro) _proActiveCard() else _buyCard(),
                    const SizedBox(height: 14),
                    _tipJarCard(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ArtisanPalette.woodEdge, width: 1.5),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black87, blurRadius: 16, offset: Offset(0, 8)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: CustomPaint(
              painter: const WoodSlabPainter(seed: 77, radius: 14),
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                child: child,
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
              padding: EdgeInsets.all(7),
              child: SizedBox(
                  width: 11,
                  height: 11,
                  child: CustomPaint(painter: RivetPainter())),
            ),
          ),
      ],
    );
  }

  Widget _comparisonCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text('◆  FREE vs PRO  ◆',
                style: ArtisanType.sectionTitle(size: 16)),
          ),
          const SizedBox(height: 12),
          _compareRow('Full Mancala rules', true, true),
          _compareRow('3 bot difficulties', true, true),
          _compareRow('Pass-and-play · mixed · demo', true, true),
          _compareRow('Music & sound controls', true, true),
          _compareRow('Board themes', '4', '16'),
          _compareRow('Stone styles', '4', '10'),
          _compareRow('Board accents', '2', '8'),
          _compareRow('Custom theme creator', false, true),
          _compareRow('Tip jar (support the maker)', true, true),
          _compareRow('One-time unlock, yours forever', false, true),
        ],
      ),
    );
  }

  Widget _compareRow(String label, Object free, Object pro) {
    Widget cell(Object v, {required bool highlight}) {
      final Widget inner;
      if (v is bool) {
        inner = Icon(
          v ? Icons.check_circle : Icons.remove_circle_outline,
          color: v ? ArtisanPalette.brassLight : ArtisanPalette.boneDim,
          size: 18,
        );
      } else {
        inner = Text('$v',
            style: ArtisanType.bodyText(
                size: 13,
                color: highlight
                    ? ArtisanPalette.brassLight
                    : ArtisanPalette.bone));
      }
      return SizedBox(width: 52, child: Center(child: inner));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: ArtisanType.bodyText(size: 13)),
          ),
          cell(free, highlight: false),
          cell(pro, highlight: true),
        ],
      ),
    );
  }

  Widget _buyCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text('UNLOCK PRO',
                style: ArtisanType.sectionTitle(size: 16)),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text('One payment. No subscription. No ads, ever.',
                textAlign: TextAlign.center,
                style: ArtisanType.label(size: 10)),
          ),
          const SizedBox(height: 14),
          if (!store.storeReady)
            Center(
              child: Text(
                '◆  ${store.error ?? 'Available after store setup'}  ◆',
                textAlign: TextAlign.center,
                style: ArtisanType.bodyText(
                    size: 13, color: ArtisanPalette.boneDim),
              ),
            ),
          const SizedBox(height: 10),
          Center(
            child: GestureDetector(
              onTap: () {
                AudioService.instance.uiClick();
                store.restore();
              },
              child: Text('Restore purchase',
                  style: ArtisanType.bodyText(
                      size: 13, color: ArtisanPalette.brassLight)),
            ),
          ),
          ValueListenableBuilder<String?>(
            valueListenable: store.purchaseError,
            builder: (_, err, _) => err == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(err,
                        textAlign: TextAlign.center,
                        style: ArtisanType.bodyText(
                            size: 12, color: ArtisanPalette.garnetHi)),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _proActiveCard() {
    return _card(
      child: Column(
        children: [
          Icon(Icons.workspace_premium,
              color: ArtisanPalette.brassLight, size: 34),
          const SizedBox(height: 8),
          Text('PRO ACTIVE',
              style: ArtisanType.sectionTitle(size: 16)),
          const SizedBox(height: 4),
          Text('Every theme, stone and accent is yours.',
              textAlign: TextAlign.center,
              style: ArtisanType.label(size: 10)),
        ],
      ),
    );
  }

  Widget _tipJarCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text('◆  TIP JAR  ◆',
                style: ArtisanType.sectionTitle(size: 16)),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text('Mancala is free forever. Tips keep the carving going.',
                textAlign: TextAlign.center,
                style: ArtisanType.label(size: 10)),
          ),
          const SizedBox(height: 12),
          if (!store.storeReady)
            Center(
              child: Text(
                '◆  ${store.error ?? 'Available after store setup'}  ◆',
                textAlign: TextAlign.center,
                style: ArtisanType.bodyText(
                    size: 13, color: ArtisanPalette.boneDim),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: _tipButton(
                    icon: Icons.coffee_outlined,
                    label: 'Coffee',
                    product: store.coffeeProduct,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _tipButton(
                    icon: Icons.cookie_outlined,
                    label: 'Chocolate',
                    product: store.chocolateProduct,
                  ),
                ),
              ],
            ),
          ValueListenableBuilder<String?>(
            valueListenable: store.lastThanks,
            builder: (_, msg, _) => msg == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(msg,
                        textAlign: TextAlign.center,
                        style: ArtisanType.bodyText(
                            size: 13, color: ArtisanPalette.brassLight)),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _tipButton({
    required IconData icon,
    required String label,
    required dynamic product,
  }) {
    final price = product == null ? '' : ' · ${product.price}';
    return ArtisanButton(
      label: '$label$price',
      icon: icon,
      onTap: product == null ? null : () => store.buyTip(product),
    );
  }
}
