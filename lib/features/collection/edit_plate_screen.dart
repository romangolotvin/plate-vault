import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../core/theme.dart';
import '../../core/widgets/plate_badge.dart';
import '../../core/widgets/vault_scaffold.dart';
import '../../data/models/collection_item.dart';
import '../../data/rarity/rarity_engine.dart';

class EditPlateScreen extends StatefulWidget {
  const EditPlateScreen({
    super.key,
    this.existing,
    this.initialText,
    this.initialCountry,
    this.photoPath,
  });

  final CollectionItem? existing;
  final String? initialText;
  final String? initialCountry;
  final String? photoPath;

  @override
  State<EditPlateScreen> createState() => _EditPlateScreenState();
}

class _EditPlateScreenState extends State<EditPlateScreen> {
  static const _countries = [
    'RU',
    'BY',
    'KZ',
    'UA',
    'US',
    'DE',
    'FR',
    'PL',
    'GB',
    'IT',
    'ES',
    'NL',
    'TR',
    'CN',
    'JP',
    'XX',
  ];

  late final TextEditingController _textCtrl;
  late final TextEditingController _notesCtrl;
  late String _country;
  final _engine = RarityEngine.instance;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController(
      text: widget.existing?.rawText ?? widget.initialText ?? '',
    );
    _notesCtrl = TextEditingController(text: widget.existing?.notes ?? '');
    _country = widget.existing?.countryCode ??
        widget.initialCountry ??
        'RU';
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preview = _engine.evaluate(
      countryCode: _country,
      rawText: _textCtrl.text,
    );
    final editing = widget.existing != null;

    return VaultScaffold(
      appBar: AppBar(
        title: Text(editing ? 'Редактировать номер' : 'Новый номер'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PlateBadge(
            text: _textCtrl.text.isEmpty ? 'А000АА00' : _textCtrl.text,
            countryCode: _country,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _textCtrl,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(
              letterSpacing: 1.4,
              fontWeight: FontWeight.w700,
            ),
            decoration: const InputDecoration(
              labelText: 'Госномер',
              hintText: 'А123ВС77',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: _countries.contains(_country) ? _country : 'XX',
            decoration: const InputDecoration(labelText: 'Страна'),
            items: _countries
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _country = v ?? 'XX'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Заметка (необязательно)',
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      RarityChip(rarity: preview.rarity),
                      const Spacer(),
                      Text(
                        'score ${preview.score}',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: VaultColors.gold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    preview.reason,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: VaultColors.mist,
                          height: 1.35,
                        ),
                  ),
                  if (preview.meanings.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    MeaningChips(meanings: preview.meanings),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          MeaningDetailCard(meanings: preview.meanings),
          if (widget.photoPath != null) ...[
            const SizedBox(height: 8),
            Text(
              'Фото: ${widget.photoPath}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: VaultColors.mist.withValues(alpha: 0.7),
                  ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(editing ? 'Сохранить' : 'Добавить в коллекцию'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите номер')),
      );
      return;
    }
    setState(() => _saving = true);
    final state = context.read<AppState>();
    try {
      if (widget.existing != null) {
        await state.updatePlate(
          widget.existing!.copyWith(
            rawText: text,
            countryCode: _country,
            notes: _notesCtrl.text.trim().isEmpty
                ? null
                : _notesCtrl.text.trim(),
            photoPath: widget.photoPath ?? widget.existing!.photoPath,
          ),
        );
      } else {
        await state.addPlate(
          countryCode: _country,
          rawText: text,
          photoPath: widget.photoPath,
          notes: _notesCtrl.text.trim().isEmpty
              ? null
              : _notesCtrl.text.trim(),
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
