import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../core/country_flag.dart';
import '../../core/theme.dart';
import '../../core/widgets/confirm_delete_dialog.dart';
import '../../core/widgets/plate_card.dart';
import '../../core/widgets/share_plate_card.dart';
import '../../core/widgets/vault_cta.dart';
import '../../core/widgets/vault_page.dart';
import '../../data/models/collection_item.dart';
import '../../data/models/user_profile.dart';
import '../collection/edit_plate_screen.dart';
import '../settings/settings_screen.dart';

/// Own or public profile: header + full plate collection (not just showcase).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    this.profile,
    this.isTab = false,
  });

  /// If null, uses signed-in profile.
  final UserProfile? profile;
  final bool isTab;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final me = state.profile;
    final viewed = profile ?? me;
    if (viewed == null) {
      return const VaultPage(
        body: Center(child: Text('Нет профиля')),
      );
    }
    final isMe = me != null && me.uid == viewed.uid;
    final items = isMe
        ? state.collectionRepository.items
        : state.publicFeed
            .where((e) => e.userId == viewed.uid)
            .toList();
    final dateFmt = DateFormat.yMMMd('ru');

    return VaultPage(
      appBar: AppBar(
        title: Text(isMe ? 'Мой профиль' : viewed.displayName),
        automaticallyImplyLeading: !isTab,
        actions: [
          if (isMe)
            IconButton(
              tooltip: 'Настройки',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SettingsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.settings_outlined,
                  color: VaultColors.purpleBright),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          _ProfileHeader(
            profile: viewed,
            editable: isMe,
          ),
          const SizedBox(height: 18),
          Text(
            isMe ? 'Моя коллекция' : 'Коллекция',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: VaultColors.cream,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            isMe
                ? 'Все снятые номера. Плохой кадр — можно удалить.'
                : 'Публичные номера этого коллекционера.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: VaultColors.mist,
                ),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            VaultHeroPanel(
              child: Text(
                isMe
                    ? 'Коллекция пуста. Открой «Скан» и сними номер двумя ракурсами.'
                    : 'Пока нет публичных номеров.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: VaultColors.mist,
                      height: 1.4,
                    ),
              ),
            )
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PlateCard(
                  item: item,
                  subtitle: dateFmt.format(item.createdAt),
                  onTap: isMe
                      ? () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => EditPlateScreen(existing: item),
                            ),
                          );
                        }
                      : null,
                  onShare: () => showSharePlateCard(
                    context,
                    item: item,
                    currency: state.currency,
                    seasonLabel: state.currentSeason.labelRu,
                  ),
                  onDelete: isMe
                      ? () => _deleteWithConfirm(context, state, item)
                      : null,
                  onFavorite:
                      isMe ? () => state.toggleFavorite(item) : null,
                  onShowcase:
                      isMe ? () => state.toggleShowcase(item) : null,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _deleteWithConfirm(
    BuildContext context,
    AppState state,
    CollectionItem item,
  ) async {
    final ok = await confirmDeletePlate(context, plateText: item.rawText);
    if (!ok) return;
    await state.deletePlate(item.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Номер ${item.rawText} удалён')),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.profile,
    required this.editable,
  });

  final UserProfile profile;
  final bool editable;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final flag = countryFlagEmoji(profile.countryCode);
    final avatarFile =
        profile.avatarPath != null ? File(profile.avatarPath!) : null;
    final hasAvatar = avatarFile != null && avatarFile.existsSync();

    return VaultHeroPanel(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: editable ? () => _pickAvatar(context, state) : null,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: VaultColors.slate,
                      backgroundImage:
                          hasAvatar ? FileImage(avatarFile) : null,
                      child: hasAvatar
                          ? null
                          : const Icon(
                              Icons.person_rounded,
                              size: 40,
                              color: VaultColors.purpleBright,
                            ),
                    ),
                    if (editable)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: VaultColors.purple,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: VaultColors.voidBg,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.photo_camera,
                            size: 14,
                            color: VaultColors.cream,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: VaultColors.cream,
                                fontWeight: FontWeight.w800,
                              ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'В Plate Vault с ${profile.registeredYear} г.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: VaultColors.mist,
                          ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: editable
                          ? () => _pickCountry(context, state, profile)
                          : null,
                      child: Row(
                        children: [
                          Text(flag, style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 8),
                          Text(
                            profile.countryCode,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: VaultColors.purpleBright,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          if (editable) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.edit_outlined,
                              size: 16,
                              color: VaultColors.mist.withValues(alpha: 0.8),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${profile.itemCount} номеров в коллекции',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: VaultColors.magenta,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (editable) ...[
            const SizedBox(height: 14),
            Text(
              'Нажми на аватар, чтобы поставить фото из галереи. '
              'Страну можно сменить рядом с флагом.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: VaultColors.mist.withValues(alpha: 0.9),
                    height: 1.35,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickAvatar(BuildContext context, AppState state) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 88,
    );
    if (file == null) return;
    final dir = await state.localStore.photosDir();
    final dest = File(
      '$dir/avatar_${profile.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await File(file.path).copy(dest.path);
    await state.updateProfile(profile.copyWith(avatarPath: dest.path));
  }

  Future<void> _pickCountry(
    BuildContext context,
    AppState state,
    UserProfile profile,
  ) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: VaultColors.panel,
      builder: (context) {
        return SafeArea(
          child: ListView(
            children: [
              const ListTile(
                title: Text(
                  'Страна профиля',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              ...kProfileCountries.map(
                (c) => ListTile(
                  leading: Text(
                    countryFlagEmoji(c),
                    style: const TextStyle(fontSize: 22),
                  ),
                  title: Text(c),
                  trailing: c == profile.countryCode
                      ? const Icon(Icons.check, color: VaultColors.purpleBright)
                      : null,
                  onTap: () => Navigator.pop(context, c),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (selected == null) return;
    await state.updateProfile(profile.copyWith(countryCode: selected));
  }
}
