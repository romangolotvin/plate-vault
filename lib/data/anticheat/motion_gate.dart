import 'dart:async';
import 'dart:math' as math;

import 'package:sensors_plus/sensors_plus.dart';

/// Soft device-motion gate between dual-angle shots (optional sensors).
class MotionGate {
  MotionGate({this.minDelta = 1.35, this.window = const Duration(seconds: 2)});

  final double minDelta;
  final Duration window;

  /// Returns true if enough motion was observed, or sensors unavailable
  /// (fail-open so capture still works on desktop / broken sensors).
  Future<MotionGateResult> waitForMotion() async {
    final samples = <double>[];
    StreamSubscription<AccelerometerEvent>? sub;
    final done = Completer<MotionGateResult>();

    try {
      sub = accelerometerEventStream().listen(
        (e) {
          final mag = math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
          samples.add(mag);
          if (samples.length >= 4) {
            final minV = samples.reduce(math.min);
            final maxV = samples.reduce(math.max);
            if (maxV - minV >= minDelta && !done.isCompleted) {
              done.complete(
                const MotionGateResult(
                  ok: true,
                  skipped: false,
                  messageRu: 'Движение зафиксировано — можно снимать крупный план.',
                ),
              );
            }
          }
        },
        onError: (_) {
          if (!done.isCompleted) {
            done.complete(
              const MotionGateResult(
                ok: true,
                skipped: true,
                messageRu: 'Датчик недоступен — продолжаем без проверки движения.',
              ),
            );
          }
        },
      );

      Future<void>.delayed(window, () {
        if (done.isCompleted) return;
        if (samples.isEmpty) {
          done.complete(
            const MotionGateResult(
              ok: true,
              skipped: true,
              messageRu: 'Датчик тихий — продолжаем. Смените угол вручную.',
            ),
          );
          return;
        }
        final minV = samples.reduce(math.min);
        final maxV = samples.reduce(math.max);
        final delta = maxV - minV;
        if (delta >= minDelta) {
          done.complete(
            const MotionGateResult(
              ok: true,
              skipped: false,
              messageRu: 'Движение зафиксировано.',
            ),
          );
        } else {
          done.complete(
            MotionGateResult(
              ok: false,
              skipped: false,
              delta: delta,
              messageRu:
                  'Сдвиньте телефон и смените угол — кадры не должны быть почти одинаковыми.',
            ),
          );
        }
      });

      return await done.future;
    } catch (_) {
      return const MotionGateResult(
        ok: true,
        skipped: true,
        messageRu: 'Датчик недоступен — продолжаем.',
      );
    } finally {
      await sub?.cancel();
    }
  }
}

class MotionGateResult {
  const MotionGateResult({
    required this.ok,
    required this.skipped,
    required this.messageRu,
    this.delta = 0,
  });

  final bool ok;
  final bool skipped;
  final String messageRu;
  final double delta;
}
