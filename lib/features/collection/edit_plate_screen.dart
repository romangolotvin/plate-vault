import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../core/theme.dart';
import '../../core/widgets/plate_badge.dart';
import '../../core/widgets/vault_motion.dart';
import '../../core/widgets/vault_scaffold.dart';
import '../../data/models/collection_item.dart';
import '../../data/models/rarity.dart';
import '../../data/plates/plate_registry.dart';
import '../../data/rarity/rarity_engine.dart';
import '../../data/valuation/plate_valuation_engine.dart';

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
  static final _countries = <String>{
    ...PlateRegistry.instance.codes.where((c) => c != 'GEN'),
    'NL',
    'CN',
    'JP',
    'XX',
  }.toList()
    ..sort();

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
    final state = context.watch<AppState>();
    final preview = _engine.evaluate(
      countryCode: _country,
      rawText: _textCtrl.text,
    );
    final valuation = PlateValuationEngine.instance.estimate(
      countryCode: _country,
      rawText: _textCtrl.text,
      precomputed: preview,
    );
    final valueLabel = PlateValuationEngine.instance.formatDetailed(
      valuation,
      state.currency,
    );
    final editing = widget.existing != null;
    final shine =
        preview.rarity.index >= Rarity.rare.index && _textCtrl.text.isNotEmpty;

    return VaultScaffold(
      appBar: AppBar(
        title: Text(editing ? 'Редактировать номер' : 'Новый номер'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          RarityPulse(
            rarity: preview.rarity,
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    VaultColors.slate.withValues(alpha: 0.98),
                    VaultColors.charcoal.withValues(alpha: 0.95),
                    preview.rarity.index >= Rarity.epic.index
                        ? VaultColors.legendary.withValues(alpha: 0.12)
                        : VaultColors.gold.withValues(alpha: 0.05),
                  ],
                ),
                border: Border.all(
                  color: VaultColors.gold.withValues(alpha: 0.28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: VaultColors.gold.withValues(alpha: 0.12),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'ТРОФЕЙ СЕЙФА',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: VaultColors.gold.withValues(alpha: 0.9),
                          letterSpacing: 2.4,
                        ),
                  ),
                  const SizedBox(height: 12),
                  PlateShine(
                    enabled: shine,
                    child: PlateBadge(
                      text: _textCtrl.text.isEmpty
                          ? 'А000АА00'
                          : _textCtrl.text,
                      countryCode: _country,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ValueCountUp(
                    key: ValueKey(
                      '${valuation.amountRub.round()}_${state.currency.code}',
                    ),
                    valuation: valuation,
                    currency: state.currency,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: VaultColors.gold,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RarityChip(rarity: preview.rarity),
                      const SizedBox(width: 10),
                      Text(
                        'score ${preview.score}',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: VaultColors.mist.withValues(alpha: 0.85),
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _textCtrl,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(
              letterSpacing: 1.4,
              fontWeight: FontWeight.w700,
            ),
            decoration: const InputDecoration(
              labelText: 'Госномер',
              hintText: 'МЕР777178',
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
          ValuationBreakdownCard(valuation: valuation),
          const SizedBox(height: 16),
          if (preview.meanings.isNotEmpty) ...[
            MeaningChips(meanings: preview.meanings),
            const SizedBox(height: 12),
          ],
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
            onPressed: _saving ? null : () => _save(preview.rarity, valueLabel),
            child: Text(editing ? 'Сохранить' : 'Добавить в коллекцию'),
          ),
        ],
      ),
    );
  }

  Future<void> _save(Rarity rarity, String valueLabel) async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите номер')),
      );
      return;
    }
    setState(() => _saving = true);
    final state = context.read<AppState>();
    final isNew = widget.existing == null;
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
      if (!mounted) return;
      if (isNew && rarity.index >= Rarity.rare.index) {
        await showRareCaptureCelebration(
          context,
          rarity: rarity,
          valueLabel: valueLabel,
          plateText: text,
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
