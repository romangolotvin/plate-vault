import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../core/theme.dart';
import '../../core/widgets/plate_badge.dart';
import '../../core/widgets/vault_page.dart';
import '../../data/models/trust_level.dart';
import '../collection/edit_plate_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _picker = ImagePicker();
  bool _busy = false;
  String? _status;
  String? _previewPath;

  Future<void> _pick(ImageSource source) async {
    setState(() {
      _busy = true;
      _status = source == ImageSource.camera
          ? 'Street-съёмка… распознаём номер'
          : 'Галерея → Unverified · распознаём…';
    });
    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 92,
        maxWidth: 2000,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (file == null) {
        setState(() => _status = null);
        return;
      }

      final state = context.read<AppState>();
      final photosDir = await state.localStore.photosDir();
      final saved = File(
        '$photosDir/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await File(file.path).copy(saved.path);

      final ocr = await state.ocrService.recognizeRichFromFile(saved.path);
      if (!mounted) return;

      final capture = source == ImageSource.camera
          ? CaptureSource.liveCamera
          : CaptureSource.gallery;
      final trust = capture.defaultTrust;

      setState(() {
        _previewPath = saved.path;
        _status = ocr == null
            ? 'Не удалось распознать — введите вручную (${trust.shortRu})'
            : 'Распознано: ${ocr.text} · ${ocr.suggestedCountry} · ${trust.shortRu}';
      });

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => EditPlateScreen(
            initialText: ocr?.text ?? '',
            initialCountry: ocr?.suggestedCountry ?? 'RU',
            photoPath: saved.path,
            captureSource: capture,
            trust: trust,
          ),
        ),
      );
    } catch (e) {
      setState(() => _status = 'Ошибка OCR: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return VaultPage(
      appBar: AppBar(title: const Text('Скан номера')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: VaultColors.gold.withValues(alpha: 0.28),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    VaultColors.slate,
                    VaultColors.panel.withValues(alpha: 0.85),
                    VaultColors.teal.withValues(alpha: 0.14),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: VaultColors.teal.withValues(alpha: 0.14),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Street capture',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: VaultColors.gold,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Камера в приложении = Street (идёт в Street-лидерборд). '
                    'Галерея и ручной ввод = Неквалифицированный — в коллекции, но без Street-очков.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: VaultColors.mist,
                          height: 1.35,
                        ),
                  ),
                  const SizedBox(height: 14),
                  const PlateBadge(
                    text: 'МЕР777178',
                    countryCode: 'RU',
                    compact: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _busy ? null : () => _pick(ImageSource.camera),
              icon: const Icon(Icons.photo_camera),
              label: const Text('Камера · Street'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _pick(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Галерея · Unverified'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _busy
                  ? null
                  : () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const EditPlateScreen(
                            captureSource: CaptureSource.manual,
                            trust: TrustLevel.unverified,
                          ),
                        ),
                      );
                    },
              child: const Text('Ввести вручную · Unverified'),
            ),
            const SizedBox(height: 16),
            if (_busy) const Center(child: CircularProgressIndicator()),
            if (_status != null) ...[
              const SizedBox(height: 12),
              Text(
                _status!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: VaultColors.gold,
                    ),
              ),
            ],
            if (_previewPath != null && File(_previewPath!).existsSync()) ...[
              const SizedBox(height: 16),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.file(
                    File(_previewPath!),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
