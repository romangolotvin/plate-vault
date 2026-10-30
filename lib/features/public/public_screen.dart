import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../core/theme.dart';
import '../../core/widgets/plate_card.dart';
import '../../core/widgets/vault_page.dart';

class PublicScreen extends StatelessWidget {
  const PublicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final me = state.profile;

    return VaultPage(
      appBar: AppBar(
        title: const Text('Публичные коллекции'),
        actions: [
          IconButton(
            onPressed: () => state.refreshPublic(),
            icon: const Icon(Icons.refresh, color: VaultColors.gold),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: VaultColors.gold,
        onRefresh: state.refreshPublic,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (me != null)
              Card(
                child: SwitchListTile(
                  title: const Text('Показывать мою коллекцию'),
                  subtitle: Text(
                    state.cloudEnabled
                        ? 'Другие увидят публичные номера вашего профиля'
                        : 'Локально: публичные номера видны только в этом приложении, пока нет Firebase',
                    style: const TextStyle(color: VaultColors.mist),
                  ),
                  value: me.publicCollectionEnabled,
                  onChanged: (v) async {
                    await state.updateProfile(
                      me.copyWith(publicCollectionEnabled: v),
                    );
                  },
                ),
              ),
            const SizedBox(height: 18),
            Text(
              'Профили',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: VaultColors.gold,
                  ),
            ),
            const SizedBox(height: 8),
            if (state.publicProfiles.isEmpty)
              Text(
                'Пока нет публичных профилей.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: VaultColors.mist),
              ),
            ...state.publicProfiles.map(
              (p) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: VaultColors.slate,
                    child: Icon(
                      Icons.person,
                      color: VaultColors.gold.withValues(alpha: 0.9),
                    ),
                  ),
                  title: Text(p.displayName),
                  subtitle: Text(
                    p.bio.isEmpty ? '${p.itemCount} номеров' : p.bio,
                    style: const TextStyle(color: VaultColors.mist),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Лента номеров',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: VaultColors.gold,
                  ),
            ),
            const SizedBox(height: 8),
            if (state.publicFeed.isEmpty)
              Text(
                'Публичных номеров пока нет.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: VaultColors.mist),
              ),
            ...state.publicFeed.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PlateCard(item: item, showMeanings: true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
