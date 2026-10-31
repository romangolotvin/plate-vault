import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../core/theme.dart';
import '../../core/widgets/plate_badge.dart';
import '../../core/widgets/vault_cta.dart';
import '../../core/widgets/vault_motion.dart';
import '../../core/widgets/vault_scaffold.dart';
import '../../data/models/collection_item.dart';
import '../../data/models/rarity.dart';
import '../../data/models/trust_level.dart';
import '../../data/plates/plate_registry.dart';
import '../../data/rarity/rarity_engine.dart';
import '../../data/sightings/sighting_service.dart';
import '../../data/valuation/plate_valuation_engine.dart';

class EditPlateScreen extends StatefulWidget {
  const EditPlateScreen({
    super.key,
    this.existing,
    this.initialText,
    this.initialCountry,
    this.photoPath,
    this.photoPathAlt,
    this.captureSource = CaptureSource.liveCamera,
    this.trust = TrustLevel.street,
  });

  final CollectionItem? existing;
  final String? initialText;
  final String? initialCountry;
  final String? photoPath;
  final String? photoPathAlt;
  final CaptureSource captureSource;
  final TrustLevel trust;

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
  int _priorSightings = 0;
  bool _sightingsLoaded = false;

  CaptureSource get _source =>
      widget.existing?.captureSource ?? widget.captureSource;

  TrustLevel get _trust {
    if (widget.existing != null) return widget.existing!.trust;
    return _source.qualifiesStreet ? widget.trust : TrustLevel.unverified;
  }

  String? get _photoWide =>
      widget.photoPath ?? widget.existing?.photoPath;
  String? get _photoClose =>
      widget.photoPathAlt ?? widget.existing?.photoPathAlt;

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController(
      text: widget.existing?.rawText ?? widget.initialText ?? '',
    );
    _notesCtrl = TextEditingController(text: widget.existing?.notes ?? '');
    _country =
        widget.existing?.countryCode ?? widget.initialCountry ?? 'RU';
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshSightings());
  }

  Future<void> _refreshSightings() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) {
      setState(() {
        _priorSightings = widget.existing?.sightingCount ?? 0;
        _sightingsLoaded = true;
      });
      return;
    }
    final state = context.read<AppState>();
    final count = await state.peekSightings(
      countryCode: _country,
      rawText: text,
    );
    if (!mounted) return;
    // For existing items, show stored count; for new, prior = current aggregate.
    setState(() {
      _priorSightings = widget.existing != null
          ? (widget.existing!.sightingCount > 0
              ? widget.existing!.sightingCount
              : count)
          : count;
      _sightingsLoaded = true;
    });
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
    final dup = _textCtrl.text.trim().isEmpty
        ? null
        : state.findDuplicate(
            countryCode: _country,
            rawText: _textCtrl.text,
            excludeId: widget.existing?.id,
          );
    final sightingText = _sightingsLoaded && _priorSightings > 0
        ? sightingLabelRu(_priorSightings)
        : null;

    return VaultScaffold(
      appBar: AppBar(
        title: Text(editing ? 'Редактировать номер' : 'Новый Street-номер'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          RarityPulse(
            rarity: preview.rarity,
            child: VaultHeroPanel(
              padding: const EdgeInsets.fromLTRB(14, 18, 14, 20),
              child: Column(
                children: [
                  Text(
                    'ТРОФЕЙ СЕЙФА',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: VaultColors.purpleBright.withValues(alpha: 0.95),
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
                          color: VaultColors.purpleBright,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RarityChip(rarity: preview.rarity),
                      const SizedBox(width: 10),
                      _TrustChip(trust: _trust),
                      const SizedBox(width: 10),
                      Text(
                        'score ${preview.score}',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color:
                                      VaultColors.mist.withValues(alpha: 0.85),
                                ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _trust.hintRu,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: VaultColors.mist,
                ),
          ),
          if (sightingText != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: VaultColors.purple.withValues(alpha: 0.14),
                border: Border.all(
                  color: VaultColors.purpleBright.withValues(alpha: 0.45),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.visibility_rounded,
                      color: VaultColors.purpleBright, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      sightingText,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: VaultColors.cream,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (dup != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: VaultColors.epic.withValues(alpha: 0.12),
                border: Border.all(
                  color: VaultColors.epic.withValues(alpha: 0.45),
                ),
              ),
              child: Text(
                'Дубликат: такой номер уже в сейфе (${dup.rawText}). Можно сохранить ещё раз — достижение «Двойник» откроется.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: VaultColors.cream,
                    ),
              ),
            ),
          ],
          if (_photoWide != null || _photoClose != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 110,
              child: Row(
                children: [
                  if (_photoWide != null)
                    Expanded(child: _PhotoChip(path: _photoWide!, label: 'Широкий')),
                  if (_photoWide != null && _photoClose != null)
                    const SizedBox(width: 10),
                  if (_photoClose != null)
                    Expanded(child: _PhotoChip(path: _photoClose!, label: 'Крупный')),
                ],
              ),
            ),
          ],
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
            onChanged: (_) {
              setState(() {});
              _refreshSightings();
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: _countries.contains(_country) ? _country : 'XX',
            decoration: const InputDecoration(labelText: 'Страна'),
            items: _countries
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) {
              setState(() => _country = v ?? 'XX');
              _refreshSightings();
            },
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
          const SizedBox(height: 24),
          VaultCta(
            label: editing ? 'Сохранить' : 'Добавить в коллекцию',
            icon: Icons.inventory_2_rounded,
            busy: _saving,
            onPressed: _saving ? null : () => _save(preview.rarity, valueLabel),
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
            photoPath: _photoWide ?? widget.existing!.photoPath,
            photoPathAlt: _photoClose ?? widget.existing!.photoPathAlt,
          ),
        );
      } else {
        await state.addPlate(
          countryCode: _country,
          rawText: text,
          photoPath: _photoWide,
          photoPathAlt: _photoClose,
          notes: _notesCtrl.text.trim().isEmpty
              ? null
              : _notesCtrl.text.trim(),
          trust: _trust,
          captureSource: _source,
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

class _PhotoChip extends StatelessWidget {
  const _PhotoChip({required this.path, required this.label});

  final String path;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (File(path).existsSync())
            Image.file(File(path), fit: BoxFit.cover)
          else
            ColoredBox(color: VaultColors.slate),
          Positioned(
            left: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: VaultColors.cream,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustChip extends StatelessWidget {
  const _TrustChip({required this.trust});

  final TrustLevel trust;

  @override
  Widget build(BuildContext context) {
    final street = trust == TrustLevel.street;
    final color = street ? VaultColors.purpleBright : VaultColors.mist;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.16),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(
        trust.shortRu,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}
