import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../core/theme.dart';
import '../../core/widgets/plate_badge.dart';
import '../../core/widgets/vault_cta.dart';
import '../../core/widgets/vault_page.dart';
import '../../data/models/trust_level.dart';
import '../collection/edit_plate_screen.dart';

enum _CaptureStep { idle, wide, close, processing }

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  final _picker = ImagePicker();
  _CaptureStep _step = _CaptureStep.idle;
  String? _widePath;
  String? _closePath;
  String? _status;
  late final AnimationController _enter;

  bool get _busy =>
      _step == _CaptureStep.processing ||
      _step == _CaptureStep.wide ||
      _step == _CaptureStep.close;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowTutorial());
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  Future<void> _maybeShowTutorial({bool force = false}) async {
    final store = context.read<AppState>().localStore;
    if (!force && await store.hasSeenDualAngleTutorial()) return;
    if (!mounted) return;
    await _showTutorial();
    await store.setDualAngleTutorialSeen();
  }

  Future<void> _showTutorial() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: VaultColors.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: VaultColors.purple.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Два ракурса',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: VaultColors.purpleBright,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                'Чтобы номер попал в Street, снимите его дважды с разных углов. '
                'Так сложнее «сфотографировать монитор» вместо живой машины.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: VaultColors.mist,
                      height: 1.4,
                    ),
              ),
              const SizedBox(height: 18),
              _TutorialStep(
                n: '1',
                title: 'Широкий кадр',
                body: 'Машина целиком или номер в контексте улицы.',
              ),
              const SizedBox(height: 12),
              _TutorialStep(
                n: '2',
                title: 'Крупный план',
                body: 'Подойдите ближе — только табличка, читаемые символы.',
              ),
              const SizedBox(height: 12),
              _TutorialStep(
                n: '✓',
                title: 'Только камера',
                body: 'Галерея и ручной ввод отключены. Всё новое — Street.',
              ),
              const SizedBox(height: 22),
              VaultCta(
                label: 'Понятно',
                icon: Icons.check_rounded,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String?> _captureCamera(String label) async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 92,
      maxWidth: 2000,
      preferredCameraDevice: CameraDevice.rear,
    );
    if (file == null) return null;
    final state = context.read<AppState>();
    final photosDir = await state.localStore.photosDir();
    final saved = File(
      '$photosDir/${DateTime.now().millisecondsSinceEpoch}_$label.jpg',
    );
    await File(file.path).copy(saved.path);
    return saved.path;
  }

  Future<void> _startDualCapture() async {
    setState(() {
      _widePath = null;
      _closePath = null;
      _status = null;
      _step = _CaptureStep.wide;
    });

    // Soft check: both frames must come from live camera, in sequence.
    final wide = await _captureCamera('wide');
    if (!mounted) return;
    if (wide == null) {
      setState(() {
        _step = _CaptureStep.idle;
        _status = 'Широкий кадр отменён';
      });
      return;
    }
    setState(() {
      _widePath = wide;
      _step = _CaptureStep.close;
      _status = 'Теперь крупный план таблички…';
    });

    final close = await _captureCamera('close');
    if (!mounted) return;
    if (close == null) {
      setState(() {
        _step = _CaptureStep.idle;
        _status = 'Крупный план отменён — начните снова';
      });
      return;
    }
    setState(() {
      _closePath = close;
      _step = _CaptureStep.processing;
      _status = 'Распознаём лучший кадр…';
    });

    try {
      final state = context.read<AppState>();
      final ocr = await state.ocrService.recognizeBestFromFiles([close, wide]);
      if (!mounted) return;

      setState(() {
        _status = ocr == null
            ? 'Не удалось распознать — поправьте текст на следующем экране'
            : 'Распознано: ${ocr.text} · ${ocr.suggestedCountry} · Street';
      });

      await Navigator.of(context).push(
        PageRouteBuilder<void>(
          transitionDuration: const Duration(milliseconds: 380),
          pageBuilder: (_, anim, __) => FadeTransition(
            opacity: anim,
            child: EditPlateScreen(
              initialText: ocr?.text ?? '',
              initialCountry: ocr?.suggestedCountry ?? 'RU',
              photoPath: wide,
              photoPathAlt: close,
              captureSource: CaptureSource.liveCamera,
              trust: TrustLevel.street,
            ),
          ),
        ),
      );
    } catch (e) {
      setState(() => _status = 'Ошибка OCR: $e');
    } finally {
      if (mounted) setState(() => _step = _CaptureStep.idle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Curves.easeOutCubic.transform(_enter.value);

    return VaultPage(
      appBar: AppBar(
        title: const Text('Street-скан'),
        actions: [
          IconButton(
            tooltip: 'Как снимать',
            onPressed: () => _maybeShowTutorial(force: true),
            icon: const Icon(Icons.help_outline_rounded,
                color: VaultColors.purpleBright),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _enter,
        builder: (context, _) {
          return Opacity(
            opacity: t.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, (1 - t) * 24),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 5,
                      child: VaultHeroPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'ТОЛЬКО КАМЕРА',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    color: VaultColors.purpleBright,
                                    letterSpacing: 2.2,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Два ракурса — Street',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: VaultColors.cream,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Широкий кадр + крупный план. Без галереи и ручного ввода — доверие к улице.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: VaultColors.mist,
                                    height: 1.4,
                                  ),
                            ),
                            const Spacer(),
                            const Center(
                              child: PlateBadge(
                                text: 'МЕР777178',
                                countryCode: 'RU',
                                compact: true,
                              ),
                            ),
                            const Spacer(),
                            _AngleProgress(
                              wideDone: _widePath != null,
                              closeDone: _closePath != null,
                              active: _step,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_widePath != null || _closePath != null)
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            Expanded(
                              child: _Thumb(
                                path: _widePath,
                                label: 'Широкий',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _Thumb(
                                path: _closePath,
                                label: 'Крупный',
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_status != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _status!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: VaultColors.purpleBright,
                              height: 1.3,
                            ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    VaultCta(
                      label: _step == _CaptureStep.close
                          ? 'Снимаем крупный план…'
                          : _step == _CaptureStep.wide
                              ? 'Снимаем широкий кадр…'
                              : _step == _CaptureStep.processing
                                  ? 'Распознаём…'
                                  : 'Снять два ракурса',
                      icon: Icons.photo_camera_rounded,
                      busy: _busy,
                      onPressed: _busy ? null : _startDualCapture,
                    ),
                    const SizedBox(height: 10),
                    VaultCta(
                      label: 'Как снимать два ракурса',
                      icon: Icons.menu_book_rounded,
                      secondary: true,
                      onPressed: _busy
                          ? null
                          : () => _maybeShowTutorial(force: true),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TutorialStep extends StatelessWidget {
  const _TutorialStep({
    required this.n,
    required this.title,
    required this.body,
  });

  final String n;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: [VaultColors.purpleBright, VaultColors.purpleDim],
            ),
          ),
          child: Text(
            n,
            style: const TextStyle(
              color: VaultColors.voidBg,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: VaultColors.cream,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: VaultColors.mist,
                      height: 1.35,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AngleProgress extends StatelessWidget {
  const _AngleProgress({
    required this.wideDone,
    required this.closeDone,
    required this.active,
  });

  final bool wideDone;
  final bool closeDone;
  final _CaptureStep active;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Dot(
            label: '1 · Широкий',
            done: wideDone,
            active: active == _CaptureStep.wide,
          ),
        ),
        Container(
          width: 28,
          height: 2,
          color: VaultColors.purple.withValues(alpha: 0.4),
        ),
        Expanded(
          child: _Dot(
            label: '2 · Крупный',
            done: closeDone,
            active: active == _CaptureStep.close,
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({
    required this.label,
    required this.done,
    required this.active,
  });

  final String label;
  final bool done;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = done
        ? VaultColors.purpleBright
        : active
            ? VaultColors.magenta
            : VaultColors.mist.withValues(alpha: 0.5);
    return Column(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done || active ? color : Colors.transparent,
            border: Border.all(color: color, width: 2),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.55),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.path, required this.label});

  final String? path;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        color: VaultColors.slate,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (path != null && File(path!).existsSync())
              Image.file(File(path!), fit: BoxFit.cover)
            else
              Center(
                child: Icon(
                  Icons.image_outlined,
                  color: VaultColors.mist.withValues(alpha: 0.4),
                ),
              ),
            Positioned(
              left: 8,
              bottom: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
      ),
    );
  }
}
