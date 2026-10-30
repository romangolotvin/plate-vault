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

    if (checked.upToDate) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Обновлений нет'),
          content: Text(checked.message ?? 'У вас актуальная версия.'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ок'),
            ),
          ],
        ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _UpdateDialog(
        result: checked,
        updateService: state.updateService,
      ),
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
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  colors: [
                    VaultColors.panel,
                    VaultColors.teal.withValues(alpha: 0.12),
                  ],
                ),
                border: Border.all(
                  color: VaultColors.gold.withValues(alpha: 0.25),
                ),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: VaultColors.slate,
                  child: Icon(
                    Icons.person,
                    color: VaultColors.gold.withValues(alpha: 0.95),
                  ),
                ),
                title: Text(
                  profile.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  profile.isLocalOnly
                      ? 'Локальный сейф'
                      : (profile.email ?? profile.uid),
                  style: const TextStyle(color: VaultColors.mist),
                ),
              ),
            ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: VaultColors.panel.withValues(alpha: 0.92),
              border: Border.all(
                color: VaultColors.gold.withValues(alpha: 0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: VaultColors.gold.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
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
                Divider(height: 1, color: VaultColors.gold.withValues(alpha: 0.12)),
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
                Divider(height: 1, color: VaultColors.gold.withValues(alpha: 0.12)),
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
                Divider(height: 1, color: VaultColors.gold.withValues(alpha: 0.12)),
                ListTile(
                  leading: const Icon(Icons.info_outline, color: VaultColors.gold),
                  title: const Text('Версия'),
                  subtitle: Text(
                    '$version · ${AppConstants.applicationId}',
                    style: const TextStyle(color: VaultColors.mist),
                  ),
                ),
                Divider(height: 1, color: VaultColors.gold.withValues(alpha: 0.12)),
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
                  subtitle: Text(
                    Platform.isIOS
                        ? 'iOS: App Store (заглушка)'
                        : 'Android: скачивание APK внутри приложения, без браузера',
                    style: const TextStyle(color: VaultColors.mist),
                  ),
                  onTap: _checking ? null : _checkUpdates,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: VaultColors.panel.withValues(alpha: 0.9),
              border: Border.all(
                color: const Color(0xFFE57373).withValues(alpha: 0.35),
              ),
            ),
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

class _UpdateDialog extends StatefulWidget {
  const _UpdateDialog({
    required this.result,
    required this.updateService,
  });

  final UpdateCheckResult result;
  final UpdateService updateService;

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  bool _busy = false;
  double? _progress;
  String? _error;
  String _status = '';

  Future<void> _confirm() async {
    setState(() {
      _busy = true;
      _error = null;
      _progress = Platform.isAndroid ? 0 : null;
      _status = Platform.isAndroid ? 'Скачиваем APK…' : 'Открываем Store…';
    });
    try {
      if (Platform.isIOS) {
        await widget.updateService.openUpdate(widget.result);
        if (mounted) Navigator.pop(context);
        return;
      }

      await widget.updateService.downloadAndInstall(
        widget.result,
        onProgress: (p) {
          if (!mounted) return;
          setState(() {
            _progress = p.total > 0 ? p.fraction : null;
            if (p.total > 0) {
              final mb = (p.received / (1024 * 1024)).toStringAsFixed(1);
              final totalMb = (p.total / (1024 * 1024)).toStringAsFixed(1);
              _status = 'Скачивание $mb / $totalMb МБ';
            } else {
              _status = 'Скачивание… ${(p.received / (1024 * 1024)).toStringAsFixed(1)} МБ';
            }
          });
        },
      );
      if (!mounted) return;
      setState(() {
        _status = 'Запуск установщика…';
        _progress = 1;
      });
      // Installer UI takes over; close dialog shortly after.
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString().replaceFirst('Bad state: ', '');
        _status = '';
        _progress = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final notes = (widget.result.releaseNotes ?? '').trim();
    final clipped = notes.length > 420 ? '${notes.substring(0, 420)}…' : notes;

    return AlertDialog(
      title: const Text('Обновить?'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Доступна ${widget.result.latestVersion} '
              '(сейчас ${widget.result.currentVersion})',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: VaultColors.gold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              Platform.isAndroid
                  ? 'APK скачается внутри приложения и откроется установщик Android. Браузер не нужен.'
                  : 'На iOS обновление через App Store (sideload недоступен).',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: VaultColors.mist,
                    height: 1.35,
                  ),
            ),
            if (clipped.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Что нового',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: VaultColors.teal,
                    ),
              ),
              const SizedBox(height: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 140),
                child: SingleChildScrollView(
                  child: Text(
                    clipped,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: VaultColors.mist,
                          height: 1.35,
                        ),
                  ),
                ),
              ),
            ],
            if (_busy) ...[
              const SizedBox(height: 16),
              if (_progress != null)
                LinearProgressIndicator(
                  value: _progress,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(8),
                )
              else
                const LinearProgressIndicator(minHeight: 8),
              const SizedBox(height: 8),
              Text(
                _status,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: VaultColors.cream,
                    ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Color(0xFFE57373), height: 1.35),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Позже'),
        ),
        FilledButton(
          onPressed: _busy ? null : _confirm,
          child: Text(
            Platform.isAndroid ? 'Да, обновить' : 'Открыть Store',
          ),
        ),
      ],
    );
  }
}
