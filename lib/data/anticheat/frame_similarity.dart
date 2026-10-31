import 'dart:math' as math;
import 'dart:typed_data';

/// Lightweight dual-angle anti-cheat: average-hash + luma histogram.
/// Pure Dart — unit-testable without Flutter bindings.
class FrameSimilarity {
  FrameSimilarity._();

  /// Default: frames with similarity ≥ this are «too alike».
  static const defaultThreshold = 0.88;

  /// Build 8×8 average hash from row-major luma samples (0..255).
  static List<bool> averageHash(List<double> luma, {int size = 8}) {
    if (luma.isEmpty) return List<bool>.filled(size * size, false);
    final n = size * size;
    final samples = _resample(luma, n);
    final mean = samples.reduce((a, b) => a + b) / samples.length;
    return [for (final v in samples) v >= mean];
  }

  /// 16-bin luma histogram, normalized to sum 1.
  static List<double> lumaHistogram(List<double> luma, {int bins = 16}) {
    final hist = List<double>.filled(bins, 0);
    if (luma.isEmpty) return hist;
    for (final v in luma) {
      final t = (v.clamp(0, 255) / 255 * (bins - 1)).round();
      hist[t] += 1;
    }
    final sum = hist.reduce((a, b) => a + b);
    if (sum <= 0) return hist;
    return [for (final h in hist) h / sum];
  }

  /// Hamming similarity of two equal-length bit hashes (1 = identical).
  static double hashSimilarity(List<bool> a, List<bool> b) {
    if (a.isEmpty || b.isEmpty) return 0;
    final len = math.min(a.length, b.length);
    var same = 0;
    for (var i = 0; i < len; i++) {
      if (a[i] == b[i]) same++;
    }
    return same / len;
  }

  /// Histogram intersection similarity (1 = identical).
  static double histogramSimilarity(List<double> a, List<double> b) {
    final len = math.min(a.length, b.length);
    if (len == 0) return 0;
    var inter = 0.0;
    for (var i = 0; i < len; i++) {
      inter += math.min(a[i], b[i]);
    }
    return inter.clamp(0.0, 1.0);
  }

  /// Combined score in 0..1 (weighted hash + histogram).
  static double combinedScore({
    required List<bool> hashA,
    required List<bool> hashB,
    required List<double> histA,
    required List<double> histB,
  }) {
    final h = hashSimilarity(hashA, hashB);
    final g = histogramSimilarity(histA, histB);
    return (0.55 * h) + (0.45 * g);
  }

  static bool tooSimilar(
    double score, {
    double threshold = defaultThreshold,
  }) =>
      score >= threshold;

  /// Convenience: score two luma buffers of any length (resampled).
  static double scoreLuma(List<double> a, List<double> b) {
    return combinedScore(
      hashA: averageHash(a),
      hashB: averageHash(b),
      histA: lumaHistogram(a),
      histB: lumaHistogram(b),
    );
  }

  /// Decode packed RGBA bytes (length = w*h*4) into luma list.
  static List<double> lumaFromRgba(Uint8List rgba, {int step = 4}) {
    final out = <double>[];
    for (var i = 0; i + 2 < rgba.length; i += step) {
      final r = rgba[i].toDouble();
      final g = rgba[i + 1].toDouble();
      final b = rgba[i + 2].toDouble();
      out.add(0.299 * r + 0.587 * g + 0.114 * b);
    }
    return out;
  }

  static List<double> _resample(List<double> src, int n) {
    if (src.length == n) return List<double>.from(src);
    if (src.isEmpty) return List<double>.filled(n, 0);
    final out = List<double>.filled(n, 0);
    for (var i = 0; i < n; i++) {
      final t = i / (n - 1).clamp(1, n);
      final idx = (t * (src.length - 1)).round().clamp(0, src.length - 1);
      out[i] = src[idx];
    }
    return out;
  }
}

class FrameSimilarityVerdict {
  const FrameSimilarityVerdict({
    required this.score,
    required this.tooSimilar,
    this.messageRu =
        'Кадры слишком похожи — отойдите или смените угол и снимите снова.',
  });

  final double score;
  final bool tooSimilar;
  final String messageRu;
}
