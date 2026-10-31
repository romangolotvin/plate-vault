import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../core/theme.dart';
import '../../core/widgets/license_plate_view.dart';
import '../../core/widgets/share_plate_card.dart';
import '../../core/widgets/vault_cta.dart';
import '../../data/models/collection_item.dart';
import '../../data/museum/museum_picker.dart';
import '../../data/valuation/plate_valuation_engine.dart';

/// Profile / collection Museum: up to 6 best Street plates.
class MuseumSection extends StatelessWidget {
  const MuseumSection({
    super.key,
    required this.items,
    this.title = 'Музей',
    this.subtitle =
        'До 6 лучших Street-номеров на витрине профиля. Сначала вручную отмеченные, затем по цене.',
    this.editable = true,
  });

  final List<CollectionItem> items;
  final String title;
  final String subtitle;
  final bool editable;

  @override
  Widget build(BuildContext context) {
    final museum = MuseumPicker.pick(items);
    final currency = context.watch<AppState>().currency;
    final valuation = PlateValuationEngine.instance;

    return VaultHeroPanel(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.museum_outlined, color: VaultColors.purpleBright),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: VaultColors.cream,
                      ),
                ),
              ),
              Text(
                '${museum.length}/${MuseumPicker.defaultMax}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: VaultColors.magenta,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: VaultColors.mist,
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 14),
          if (museum.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: VaultColors.voidBg.withValues(alpha: 0.45),
                border: Border.all(
                  color: VaultColors.purple.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                'Музей пуст. Сними Street-номер двумя ракурсами — лучшие '
                'автоматически попадут на витрину. Можно вручную отметить «На витрину» '
                '(макс. ${MuseumPicker.defaultMax}).',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: VaultColors.mist,
                      height: 1.4,
                    ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: museum.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.55,
              ),
              itemBuilder: (context, index) {
                final item = museum[index];
                final value = valuation.estimate(
                  countryCode: item.countryCode,
                  rawText: item.rawText,
                );
                final label = valuation.formatDetailed(value, currency);
                return _MuseumTile(
                  item: item,
                  valueLabel: label,
                  editable: editable,
                );
              },
            ),
        ],
      ),
    );
  }
}

class _MuseumTile extends StatelessWidget {
  const _MuseumTile({
    required this.item,
    required this.valueLabel,
    required this.editable,
  });

  final CollectionItem item;
  final String valueLabel;
  final bool editable;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            VaultColors.slate,
            VaultColors.purple.withValues(alpha: 0.16),
          ],
        ),
        border: Border.all(
          color: item.isShowcase
              ? VaultColors.magenta.withValues(alpha: 0.65)
              : VaultColors.purple.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: LicensePlateView(
              text: item.rawText,
              countryCode: item.countryCode,
              compact: true,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  valueLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: VaultColors.purpleBright,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              GestureDetector(
                onTap: () => showSharePlateCard(
                  context,
                  item: item,
                  currency: state.currency,
                  seasonLabel: state.currentSeason.labelRu,
                ),
                child: const Icon(
                  Icons.ios_share,
                  size: 18,
                  color: VaultColors.purpleBright,
                ),
              ),
              if (editable) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => state.toggleShowcase(item),
                  child: Icon(
                    item.isShowcase
                        ? Icons.storefront
                        : Icons.storefront_outlined,
                    size: 18,
                    color: VaultColors.magenta,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
