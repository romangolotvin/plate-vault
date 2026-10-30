import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../core/theme.dart';
import '../../core/widgets/vault_page.dart';
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
      _status = 'Распознаём номер…';
    });
    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 92,
        maxWidth: 2000,
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

      final text = await state.ocrService.recognizeFromFile(saved.path);
      if (!mounted) return;

      setState(() {
        _previewPath = saved.path;
        _status = text == null
            ? 'Не удалось распознать — введите вручную'
            : 'Распознано: $text (можете исправить)';
      });

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => EditPlateScreen(
            initialText: text ?? '',
            initialCountry: 'RU',
            photoPath: saved.path,
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
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: VaultColors.teal.withValues(alpha: 0.35),
                ),
                gradient: LinearGradient(
                  colors: [
                    VaultColors.teal.withValues(alpha: 0.12),
                    VaultColors.panel.withValues(alpha: 0.4),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Захват в сейф',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: VaultColors.teal,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Сфотографируйте госномер или выберите фото. После OCR можно поправить текст — серии и редкость посчитаются сразу.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: VaultColors.mist,
                          height: 1.35,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _busy ? null : () => _pick(ImageSource.camera),
              icon: const Icon(Icons.photo_camera),
              label: const Text('Камера'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _pick(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Галерея'),
            ),
            const SizedBox(height: 24),
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
                  borderRadius: BorderRadius.circular(16),
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
