import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../core/theme.dart';
import '../../core/widgets/vault_cta.dart';
import '../../data/valuation/plate_valuation_engine.dart';
import '../../data/models/rarity.dart';

/// Streak + weekly duel + clan — compact hub on collection home.
class PlayHubCard extends StatelessWidget {
  const PlayHubCard({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final streak = state.streakUi;
    final duel = state.weeklyDuel;
    final clan = state.myClan;
    final fmt = PlateValuationEngine.instance;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            VaultColors.purpleDim.withValues(alpha: 0.55),
            VaultColors.panel,
          ],
        ),
        border: Border.all(color: VaultColors.purple.withValues(alpha: 0.35)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'ОХОТА',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: VaultColors.purpleBright,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.local_fire_department_rounded,
                  title: 'Стрик',
                  value: '${streak.current} дн.',
                  subtitle: 'рекорд ${streak.best}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  icon: Icons.sports_kabaddi_rounded,
                  title: 'Дуэль',
                  value: duel == null
                      ? '—'
                      : (duel.winning
                          ? 'Победа'
                          : duel.tied
                              ? 'Ничья'
                              : 'Отстаём'),
                  subtitle: duel == null
                      ? 'нет матча'
                      : duel.opponent.displayName,
                ),
              ),
            ],
          ),
          if (duel != null) ...[
            const SizedBox(height: 10),
            Text(
              'Ты ${fmt.formatDetailed(PlateValuation(amountRub: duel.myPortfolioRub, rarityScore: 0, rarity: Rarity.common, rationale: ''), state.currency)}'
              ' · соперник ${fmt.formatDetailed(PlateValuation(amountRub: duel.opponent.portfolioRub, rarityScore: 0, rarity: Rarity.common, rationale: ''), state.currency)}'
              '${duel.opponent.isBot ? ' (бот)' : ''}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: VaultColors.mist,
                  ),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            'Клан',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          if (clan == null) ...[
            Text(
              'Создай двор или войди по коду — суммируете Street-портфели.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: VaultColors.mist,
                  ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: VaultCta(
                    label: 'Создать',
                    icon: Icons.group_add_rounded,
                    onPressed: () => _createClan(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: VaultCta(
                    label: 'Код',
                    icon: Icons.vpn_key_rounded,
                    secondary: true,
                    onPressed: () => _joinClan(context),
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              '${clan.name} · ${clan.memberCount} уч. · код ${clan.inviteCode}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Портфель клана: ${fmt.formatDetailed(PlateValuation(amountRub: clan.portfolioSum, rarityScore: 0, rarity: Rarity.common, rationale: ''), state.currency)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: VaultColors.mist,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: clan.inviteCode),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Код скопирован')),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Копировать код'),
                ),
                TextButton(
                  onPressed: () => context.read<AppState>().leaveClan(),
                  child: const Text('Выйти'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _createClan(BuildContext context) async {
    final ctrl = TextEditingController(text: 'Двор');
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Новый клан'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Название'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Создать'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || !context.mounted) return;
    final clan = await context.read<AppState>().createClan(name);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Клан создан. Код: ${clan.inviteCode}')),
      );
    }
  }

  Future<void> _joinClan(BuildContext context) async {
    final ctrl = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Вступить по коду'),
        content: TextField(
          controller: ctrl,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(labelText: 'Инвайт-код'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Войти'),
          ),
        ],
      ),
    );
    if (code == null || code.isEmpty || !context.mounted) return;
    final clan = await context.read<AppState>().joinClan(code);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          clan == null ? 'Клан не найден' : 'Ты в клане «${clan.name}»',
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: VaultColors.voidBg.withValues(alpha: 0.45),
        border: Border.all(color: VaultColors.purple.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: VaultColors.purpleBright, size: 22),
          const SizedBox(height: 8),
          Text(title, style: Theme.of(context).textTheme.labelMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: VaultColors.mist,
                ),
          ),
        ],
      ),
    );
  }
}
