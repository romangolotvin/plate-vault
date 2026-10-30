import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../core/update/update_service.dart';
import '../../core/widgets/vault_page.dart';
import '../../data/valuation/currency.dart';
import '../../data/valuation/plate_valuation_engine.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  PackageInfo? _info;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((v) {
      if (mounted) setState(() => _info = v);
    });
  }

  Future<void> _checkUpdates() async {
    final state = context.read<AppState>();
    setState(() => _checking = true);
    UpdateCheckResult? result;
    try {
      result = await state.updateService.check();
    } finally {
      if (mounted) setState(() => _checking = false);
    }
    if (!mounted) return;
    final checked = result;
    if (checked == null) return;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            checked.upToDate ? 'Обновлений нет' : 'Есть обновление',
          ),
          content: Text(
            [
              checked.message ?? '',
              if (checked.latestVersion != null)
                'Новая версия: ${checked.latestVersion}',
              if (!checked.upToDate && Platform.isIOS)
                'На iOS обновление через App Store (ссылка-заглушка).',
              if (!checked.upToDate && Platform.isAndroid)
                'Android: можно открыть GitHub Release / APK.',
            ].where((e) => e.trim().isNotEmpty).join('\n\n'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Закрыть'),
            ),
            if (!checked.upToDate)
              FilledButton(
                onPressed: () async {
                  await state.updateService.openUpdate(checked);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Обновить'),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final profile = state.profile;
    final version = _info == null
        ? '…'
        : '${_info!.version}+${_info!.buildNumber}';

    return VaultPage(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (profile != null)
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: VaultColors.slate,
                  child: Icon(
                    Icons.person,
                    color: VaultColors.gold.withValues(alpha: 0.95),
                  ),
                ),
                title: Text(profile.displayName),
                subtitle: Text(
                  profile.isLocalOnly
                      ? 'Локальный аккаунт'
                      : (profile.email ?? profile.uid),
                  style: const TextStyle(color: VaultColors.mist),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Публичная коллекция'),
                  value: profile?.publicCollectionEnabled ?? false,
                  onChanged: profile == null
                      ? null
                      : (v) => state.updateProfile(
                            profile.copyWith(publicCollectionEnabled: v),
                          ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.payments_outlined,
                    color: VaultColors.gold,
                  ),
                  title: const Text('Валюта оценки'),
                  subtitle: Text(
                    'Курс внутри приложения: \$1 = ${PlateValuationEngine.rubPerUsd.toInt()} ₽, '
                    '€1 = ${PlateValuationEngine.rubPerEur.toInt()} ₽',
                    style: const TextStyle(color: VaultColors.mist),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: SegmentedButton<AppCurrency>(
                    segments: [
                      for (final c in AppCurrency.values)
                        ButtonSegment(
                          value: c,
                          label: Text('${c.symbol} ${c.code}'),
                        ),
                    ],
                    selected: {state.currency},
                    onSelectionChanged: (set) {
                      if (set.isNotEmpty) state.setCurrency(set.first);
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.cloud_outlined,
                    color: state.cloudEnabled
                        ? VaultColors.teal
                        : VaultColors.mist,
                  ),
                  title: const Text('Облако Firebase'),
                  subtitle: Text(
                    state.cloudEnabled
                        ? 'Подключено'
                        : 'Не настроено (локальный режим)',
                    style: const TextStyle(color: VaultColors.mist),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline, color: VaultColors.gold),
                  title: const Text('Версия'),
                  subtitle: Text(
                    '$version · ${AppConstants.applicationId}',
                    style: const TextStyle(color: VaultColors.mist),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: _checking
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(
                          Icons.system_update,
                          color: VaultColors.teal,
                        ),
                  title: const Text('Проверить обновления'),
                  subtitle: const Text(
                    'Сейчас через GitHub Releases; позже — Play / App Store',
                    style: TextStyle(color: VaultColors.mist),
                  ),
                  onTap: _checking ? null : _checkUpdates,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFFE57373)),
              title: const Text('Выйти'),
              onTap: () => state.signOut(),
            ),
          ),
        ],
      ),
    );
  }
}
