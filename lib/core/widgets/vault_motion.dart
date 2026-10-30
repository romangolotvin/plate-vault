import 'package:flutter/material.dart';

import '../theme.dart';
import '../../data/models/rarity.dart';
import '../../data/valuation/plate_valuation_engine.dart';
import '../../data/valuation/currency.dart';

/// Soft diagonal shine sweep across a plate (vault “metal” feel).
class PlateShine extends StatefulWidget {
  const PlateShine({
    super.key,
    required this.child,
    this.enabled = true,
  });

  final Widget child;
  final bool enabled;

  @override
  State<PlateShine> createState() => _PlateShineState();
}

class _PlateShineState extends State<PlateShine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    if (widget.enabled) {
      _ctrl.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant PlateShine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !_ctrl.isAnimating) {
      _ctrl.repeat();
    } else if (!widget.enabled && _ctrl.isAnimating) {
      _ctrl.stop();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = _ctrl.value;
        return Stack(
          fit: StackFit.passthrough,
          children: [
            child!,
            Positioned.fill(
              child: IgnorePointer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Opacity(
                    opacity: 0.35,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(-1.2 + t * 2.4, -0.4),
                          end: Alignment(-0.6 + t * 2.4, 0.6),
                          colors: [
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.55),
                            Colors.transparent,
                          ],
                          stops: const [0.35, 0.5, 0.65],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      child: widget.child,
    );
  }
}

/// Soft pulse ring for epic / legendary rarity.
class RarityPulse extends StatefulWidget {
  const RarityPulse({
    super.key,
    required this.rarity,
    required this.child,
  });

  final Rarity rarity;
  final Widget child;

  @override
  State<RarityPulse> createState() => _RarityPulseState();
}

class _RarityPulseState extends State<RarityPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  bool get _pulse =>
      widget.rarity == Rarity.epic || widget.rarity == Rarity.legendary;

  Color get _color => switch (widget.rarity) {
        Rarity.legendary => VaultColors.legendary,
        Rarity.epic => VaultColors.epic,
        Rarity.rare => VaultColors.rare,
        Rarity.uncommon => VaultColors.uncommon,
        Rarity.common => VaultColors.mist,
      };

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    if (_pulse) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant RarityPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_pulse && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!_pulse && _ctrl.isAnimating) {
      _ctrl
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_pulse) return widget.child;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final glow = 0.18 + _ctrl.value * 0.28;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _color.withValues(alpha: glow),
                blurRadius: 18 + _ctrl.value * 10,
                spreadRadius: 1 + _ctrl.value * 2,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Counts up to the valuation amount (gold ticker feel).
class ValueCountUp extends StatelessWidget {
  const ValueCountUp({
    super.key,
    required this.valuation,
    required this.currency,
    this.style,
    this.duration = const Duration(milliseconds: 900),
  });

  final PlateValuation valuation;
  final AppCurrency currency;
  final TextStyle? style;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final target = valuation.inCurrency(currency);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: target),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        final amountRub = switch (currency) {
          AppCurrency.rub => value,
          AppCurrency.usd => value * PlateValuationEngine.rubPerUsd,
          AppCurrency.eur => value * PlateValuationEngine.rubPerEur,
        };
        final fake = PlateValuation(
          amountRub: amountRub,
          rarityScore: valuation.rarityScore,
          rarity: valuation.rarity,
          rationale: valuation.rationale,
          factors: valuation.factors,
        );
        return Text(
          PlateValuationEngine.instance.formatDetailed(fake, currency),
          style: style ??
              Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: VaultColors.gold,
                    fontWeight: FontWeight.w800,
                  ),
        );
      },
    );
  }
}

/// Breakdown of why this price (series / digits / region / combo).
class ValuationBreakdownCard extends StatelessWidget {
  const ValuationBreakdownCard({
    super.key,
    required this.valuation,
  });

  final PlateValuation valuation;

  @override
  Widget build(BuildContext context) {
    final factors = valuation.factors
        .where((f) => f.category != ValuationFactorCategory.base)
        .toList();
    if (factors.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            VaultColors.panel,
            VaultColors.slate.withValues(alpha: 0.9),
            VaultColors.gold.withValues(alpha: 0.06),
          ],
        ),
        border: Border.all(color: VaultColors.gold.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: VaultColors.gold.withValues(alpha: 0.1),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_graph,
                size: 18,
                color: VaultColors.gold.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 8),
              Text(
                'Почему такая цена',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: VaultColors.cream,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Серия · цифры · регион — уличный фольклор коллекционеров',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: VaultColors.mist.withValues(alpha: 0.85),
                ),
          ),
          const SizedBox(height: 12),
          ...factors.map((f) => _FactorRow(factor: f)),
        ],
      ),
    );
  }
}

class _FactorRow extends StatelessWidget {
  const _FactorRow({required this.factor});

  final ValuationFactor factor;

  Color get _accent => switch (factor.category) {
        ValuationFactorCategory.digits => const Color(0xFF6EC8FF),
        ValuationFactorCategory.series => VaultColors.epic,
        ValuationFactorCategory.region => VaultColors.teal,
        ValuationFactorCategory.combo => VaultColors.legendary,
        ValuationFactorCategory.score => VaultColors.mist,
        ValuationFactorCategory.base => VaultColors.mist,
      };

  @override
  Widget build(BuildContext context) {
    final c = _accent;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 3),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: c.withValues(alpha: 0.45)),
            ),
            child: Text(
              factor.categoryLabelRu,
              style: TextStyle(
                color: c,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        factor.labelRu,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: VaultColors.cream,
                        ),
                      ),
                    ),
                    if (factor.multiplier > 1.01)
                      Text(
                        '×${factor.multiplier % 1 == 0 ? factor.multiplier.toInt() : factor.multiplier.toStringAsFixed(1)}',
                        style: TextStyle(
                          color: c,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
                if (factor.detailRu.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    factor.detailRu,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: VaultColors.mist.withValues(alpha: 0.9),
                          height: 1.3,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showRareCaptureCelebration(
  BuildContext context, {
  required Rarity rarity,
  required String valueLabel,
  required String plateText,
}) {
  if (rarity.index < Rarity.rare.index) {
    return Future.value();
  }
  final title = switch (rarity) {
    Rarity.legendary => 'Легенда в сейфе!',
    Rarity.epic => 'Эпик пойман!',
    Rarity.rare => 'Редкий трофей!',
    _ => 'В сейфе!',
  };
  final accent = switch (rarity) {
    Rarity.legendary => VaultColors.legendary,
    Rarity.epic => VaultColors.epic,
    Rarity.rare => VaultColors.rare,
    _ => VaultColors.gold,
  };

  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'celebration',
    barrierColor: Colors.black.withValues(alpha: 0.72),
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (context, anim, secondary) {
      return Center(
        child: ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 28),
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    VaultColors.panel,
                    accent.withValues(alpha: 0.22),
                    VaultColors.slate,
                  ],
                ),
                border: Border.all(color: accent.withValues(alpha: 0.55)),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.35),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.workspace_premium, color: accent, size: 42),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    plateText,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    valueLabel,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: VaultColors.gold,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('В коллекцию'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
