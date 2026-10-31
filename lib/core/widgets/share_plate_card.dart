import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/collection_item.dart';
import '../../data/models/trust_level.dart';
import '../../data/seasons/season.dart';
import '../../data/valuation/currency.dart';
import '../../data/valuation/plate_valuation_engine.dart';
import '../theme.dart';
import 'plate_badge.dart';
import 'vault_motion.dart';

/// Shareable collector flex card (copy text + on-screen trophy).
Future<void> showSharePlateCard(
  BuildContext context, {
  required CollectionItem item,
  required AppCurrency currency,
  String? seasonLabel,
}) async {
  final valuation = PlateValuationEngine.instance.estimate(
    countryCode: item.countryCode,
    rawText: item.rawText,
  );
  final valueLabel =
      PlateValuationEngine.instance.formatDetailed(valuation, currency);
  final trust = item.trust;
  final flexAllowed = trust == TrustLevel.street;
  final season = seasonLabel ?? Season.current().labelRu;
  final shareText = flexAllowed
      ? 'Plate Vault · Street ${item.rawText} (${item.countryCode}) · '
          '$valueLabel · ${item.rarity.labelRu} · сезон $season'
      : 'Plate Vault · ${item.rawText} · Unverified '
          '(не Street) · оценка $valueLabel';

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                VaultColors.panel,
                VaultColors.slate,
                VaultColors.purple.withValues(alpha: 0.22),
              ],
            ),
            border: Border.all(
              color: VaultColors.purpleBright.withValues(alpha: 0.45),
            ),
            boxShadow: [
              BoxShadow(
                color: VaultColors.purple.withValues(alpha: 0.28),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                flexAllowed ? 'STREET SHARE' : 'UNVERIFIED · без Street-flex',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: flexAllowed
                          ? VaultColors.purpleBright
                          : VaultColors.mist,
                      letterSpacing: 1.6,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                season,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: VaultColors.magenta,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 14),
              PlateShine(
                enabled: item.rarity.index >= 2,
                child: PlateBadge(
                  text: item.rawText,
                  countryCode: item.countryCode,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                valueLabel,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: VaultColors.purpleBright,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                '${item.rarity.labelRu} · ${trust.labelRu}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: VaultColors.mist,
                    ),
              ),
              if (!flexAllowed) ...[
                const SizedBox(height: 10),
                Text(
                  'Ручной ввод / галерея не дают полный portfolio flex в Street.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: VaultColors.mist.withValues(alpha: 0.9),
                      ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: shareText));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Скопировано')),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Копировать'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Закрыть'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
