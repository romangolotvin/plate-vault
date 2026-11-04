import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../core/theme.dart';
import '../../core/widgets/plate_badge.dart';
import '../../core/widgets/vault_cta.dart';
import '../../core/widgets/vault_page.dart';
import '../../data/appeals/plate_appeal.dart';
import '../../data/models/collection_item.dart';
import '../scan/country_switch.dart';
import 'appeal_widgets.dart';

/// Correct a scanned plate and send it, with photos, to the owner's desktop.
class SubmitAppealScreen extends StatefulWidget {
  const SubmitAppealScreen({super.key, required this.item});

  final CollectionItem item;

  @override
  State<SubmitAppealScreen> createState() => _SubmitAppealScreenState();
}

class _SubmitAppealScreenState extends State<SubmitAppealScreen> {
  late final TextEditingController _corrected;
  late final TextEditingController _url;
  late final TextEditingController _token;
  late String _country;
  var _busy = false;
  var _loadedDesk = false;

  @override
  void initState() {
    super.initState();
    _corrected = TextEditingController(text: widget.item.rawText);
    _country = widget.item.countryCode;
    _url = TextEditingController();
    _token = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDesk());
  }

  Future<void> _loadDesk() async {
    final state = context.read<AppState>();
    _url.text = state.appealDesktopUrl;
    _token.text = state.appealDesktopToken;
    await state.refreshAppealDecisions();
    if (mounted) setState(() => _loadedDesk = true);
  }

  @override
  void dispose() {
    _corrected.dispose();
    _url.dispose();
    _token.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final state = context.read<AppState>();
    setState(() => _busy = true);
    await state.setAppealDesktop(url: _url.text, token: _token.text);
    final error = await state.submitPlateAppeal(
      item: widget.item,
      correctedNumber: _corrected.text,
      countryCode: _country,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ??
              'Заявление ушло владельцу. Он посмотрит его на своём компьютере.',
        ),
      ),
    );
  }

  Future<void> _retry(PlateAppeal appeal) async {
    final state = context.read<AppState>();
    setState(() => _busy = true);
    await state.setAppealDesktop(url: _url.text, token: _token.text);
    final error = await state.retryAppeal(appeal.id);
    if (!mounted) return;
    setState(() => _busy = false);
    if (error == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Заявление доставлено.')));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _refresh() async {
    final state = context.read<AppState>();
    setState(() => _busy = true);
    await state.setAppealDesktop(url: _url.text, token: _token.text);
    await state.refreshAppealDecisions();
    if (!mounted) return;
    setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final latest = latestAppeal(state.appeals, widget.item.id);
    final blocked = appealBlockReason(state.appeals, widget.item.id);
    final photos = widget.item.allPhotoPaths;

    return VaultPage(
      appBar: AppBar(title: const Text('Обжаловать')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          VaultHeroPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Как распознано',
                  style: Theme.of(context).textTheme.labelLarge
                      ?.copyWith(color: VaultColors.mist),
                ),
                const SizedBox(height: 8),
                PlateBadge(
                  text: widget.item.rawText,
                  countryCode: widget.item.countryCode,
                  compact: true,
                ),
                const SizedBox(height: 8),
                Text(
                  'Владелец увидит этот номер, исправленный текст, страну и фото номера.',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: VaultColors.mist, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CountrySwitch(
            countryCode: _country,
            onChanged: (value) => setState(() => _country = value),
          ),
          const SizedBox(height: 6),
          Text(
            'Эту страну получит программа владельца вместе с номером и фото.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: VaultColors.mist,
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 12),
          AppealCorrectedField(controller: _corrected),
          const SizedBox(height: 12),
          TextField(
            controller: _url,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Адрес программы владельца',
              hintText: 'http://192.168.0.12:8787',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _token,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Код доступа',
              hintText: 'Показан в окне программы',
            ),
          ),
          const SizedBox(height: 16),
          Text('Фото', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (photos.isEmpty)
            Text(
              'У этого номера нет сохранённых фото. Уйдёт только текст.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: VaultColors.mist),
            )
          else
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final path = photos[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(path),
                      width: 160,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 160,
                        color: VaultColors.slate,
                        alignment: Alignment.center,
                        child: const Text(
                          'Фото не открылось',
                          style: TextStyle(color: VaultColors.mist),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          if (latest != null) ...[
            const SizedBox(height: 16),
            Text(
              '${appealDeliveryLabel(latest.delivery)}'
              '${latest.error == null ? '' : ' · ${latest.error}'}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: VaultColors.purpleBright,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (blocked != null) ...[
            const SizedBox(height: 8),
            Text(
              blocked,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: VaultColors.mist),
            ),
          ],
          const SizedBox(height: 20),
          if (latest != null && latest.delivery == AppealDelivery.queued)
            VaultCta(
              label: 'Повторить отправку',
              icon: Icons.refresh,
              busy: _busy,
              onPressed: _busy ? null : () => _retry(latest),
            )
          else if (latest != null && latest.delivery == AppealDelivery.sent)
            VaultCta(
              label: 'Проверить решение',
              icon: Icons.fact_check_outlined,
              busy: _busy,
              secondary: true,
              onPressed: _busy || !_loadedDesk ? null : _refresh,
            )
          else
            VaultCta(
              label: 'Отправить обжалование',
              icon: Icons.outgoing_mail,
              busy: _busy,
              onPressed: _busy || blocked != null ? null : _submit,
            ),
        ],
      ),
    );
  }
}
