import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../core/theme.dart';
import '../../core/widgets/license_plate_view.dart';
import '../../core/widgets/vault_cta.dart' show VaultHeroPanel;
import '../../core/widgets/vault_page.dart';
import '../../data/sets/plate_sets.dart';

class SetsScreen extends StatelessWidget {
  const SetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final progress = PlateSetsCatalog.progressFor(
      state.collectionRepository.items,
    );
    final done = progress.where((p) => p.complete).length;

    return VaultPage(
      appBar: AppBar(
        title: const Text('Альбомы и сеты'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          VaultHeroPanel(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'СЕТЫ ОХОТНИКА',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: VaultColors.purpleBright,
                        letterSpacing: 2,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Собирай тематические Street-альбомы',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: VaultColors.cream,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Прогресс считается только по Street (два ракурса). '
                  'Закрыто $done из ${progress.length}.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: VaultColors.mist,
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...progress.map((p) => _SetCard(progress: p)),
        ],
      ),
    );
  }
}

class _SetCard extends StatelessWidget {
  const _SetCard({required this.progress});

  final PlateSetProgress progress;

  @override
  Widget build(BuildContext context) {
    final def = progress.definition;
    final accent = Color(def.accentArgb);
    final fill = progress.fill;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            VaultColors.panel,
            accent.withValues(alpha: 0.12),
            VaultColors.slate.withValues(alpha: 0.9),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  def.titleRu,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: VaultColors.cream,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: accent.withValues(alpha: 0.18),
                  border: Border.all(color: accent.withValues(alpha: 0.55)),
                ),
                child: Text(
                  progress.complete
                      ? 'ГОТОВО'
                      : '${progress.count}/${progress.goal}',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            def.subtitleRu,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: VaultColors.mist,
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: fill,
              minHeight: 10,
              backgroundColor: VaultColors.voidBg.withValues(alpha: 0.55),
              color: accent,
            ),
          ),
          if (progress.matched.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: progress.matched.take(8).length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final item = progress.matched[i];
                  return SizedBox(
                    width: 132,
                    child: LicensePlateView(
                      text: item.rawText,
                      countryCode: item.countryCode,
                      compact: true,
                    ),
                  );
                },
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            Text(
              'Пока пусто — ищи на улице и сканируй двумя ракурсами.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: VaultColors.mist.withValues(alpha: 0.85),
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact home teaser linking to full sets screen.
class SetsTeaserCard extends StatelessWidget {
  const SetsTeaserCard({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final progress = PlateSetsCatalog.progressFor(
      state.collectionRepository.items,
    );
    final best = progress.isEmpty
        ? null
        : (List<PlateSetProgress>.from(progress)
              ..sort((a, b) => b.fill.compareTo(a.fill)))
            .first;
    final done = progress.where((p) => p.complete).length;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const SetsScreen()),
          );
        },
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                VaultColors.panel,
                VaultColors.purple.withValues(alpha: 0.14),
              ],
            ),
            border: Border.all(
              color: VaultColors.purple.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [VaultColors.purpleBright, VaultColors.purpleDim],
                  ),
                ),
                child: const Icon(Icons.collections_bookmark_rounded,
                    color: VaultColors.voidBg),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Альбомы · $done/${progress.length}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      best == null
                          ? 'Открой сеты охотника'
                          : '${best.definition.titleRu} · ${(best.fill * 100).round()}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: VaultColors.mist,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: VaultColors.purpleBright),
            ],
          ),
        ),
      ),
    );
  }
}
