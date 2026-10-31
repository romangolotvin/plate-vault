import 'dart:io';
import 'dart:ui' as ui;

import 'frame_similarity.dart';

/// Decode a local image file and score similarity vs another file.
class FrameSimilarityIo {
  FrameSimilarityIo._();

  static Future<List<double>> lumaFromFile(
    String path, {
    int maxSide = 96,
  }) async {
    final bytes = await File(path).readAsBytes();
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: maxSide,
      targetHeight: maxSide,
    );
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final bd = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    codec.dispose();
    if (bd == null) return const [];
    return FrameSimilarity.lumaFromRgba(bd.buffer.asUint8List());
  }

  static Future<FrameSimilarityVerdict> compareFiles({
    required String pathA,
    required String pathB,
    double threshold = FrameSimilarity.defaultThreshold,
  }) async {
    final a = await lumaFromFile(pathA);
    final b = await lumaFromFile(pathB);
    final score = FrameSimilarity.scoreLuma(a, b);
    final bad = FrameSimilarity.tooSimilar(score, threshold: threshold);
    return FrameSimilarityVerdict(
      score: score,
      tooSimilar: bad,
      messageRu: bad
          ? 'Кадры слишком похожи (${(score * 100).round()}%). '
              'Смените угол / расстояние и снимите крупный план снова.'
          : 'Ракурсы отличаются — ок (${(score * 100).round()}%).',
    );
  }
}
