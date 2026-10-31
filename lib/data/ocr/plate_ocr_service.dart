import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../plates/plate_registry.dart';
import '../rarity/rarity_engine.dart';

class PlateOcrResult {
  const PlateOcrResult({
    required this.text,
    required this.suggestedCountry,
    this.confidence = 0,
  });

  final String text;
  final String suggestedCountry;
  final int confidence;
}

class PlateOcrService {
  PlateOcrService({
    RarityEngine? rarityEngine,
    PlateRegistry? registry,
  })  : _rarity = rarityEngine ?? RarityEngine.instance,
        _registry = registry ?? PlateRegistry.instance;

  final RarityEngine _rarity;
  final PlateRegistry _registry;
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<String?> recognizeFromFile(String path) async {
    final rich = await recognizeRichFromFile(path);
    return rich?.text;
  }

  Future<PlateOcrResult?> recognizeRichFromFile(String path) async {
    final input = InputImage.fromFilePath(path);
    final result = await _recognizer.processImage(input);
    return _pickBestPlateCandidate(result.text);
  }

  /// OCR several frames and keep the highest-confidence candidate.
  Future<PlateOcrResult?> recognizeBestFromFiles(List<String> paths) async {
    PlateOcrResult? best;
    for (final path in paths) {
      if (path.isEmpty) continue;
      try {
        final r = await recognizeRichFromFile(path);
        if (r == null) continue;
        if (best == null || r.confidence > best.confidence) {
          best = r;
        }
      } catch (_) {}
    }
    return best;
  }

  Future<String?> recognizeFromFileObject(File file) {
    return recognizeFromFile(file.path);
  }

  PlateOcrResult? _pickBestPlateCandidate(String fullText) {
    if (fullText.trim().isEmpty) return null;

    final lines = fullText
        .split(RegExp(r'[\r\n]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final candidates = <String>[];
    for (final line in lines) {
      final normalized = _rarity.normalize(line);
      if (normalized.length >= 3 && normalized.length <= 12) {
        candidates.add(normalized);
      }
      final loose = line.toUpperCase().replaceAll(RegExp(r'[\s\-]'), '');
      if (loose.length >= 3 && loose.length <= 14) {
        candidates.add(loose);
      }
    }

    if (candidates.isEmpty) {
      final fallback = _rarity.normalize(fullText);
      if (fallback.isEmpty) return null;
      final detected = _registry.detectCountry(fallback);
      return PlateOcrResult(
        text: fallback,
        suggestedCountry: detected.code,
        confidence: detected.score,
      );
    }

    candidates.sort((a, b) {
      final scoreA = _scoreCandidate(a);
      final scoreB = _scoreCandidate(b);
      return scoreB.compareTo(scoreA);
    });

    final best = candidates.first;
    final detected = _registry.detectCountry(best);
    return PlateOcrResult(
      text: best,
      suggestedCountry: detected.code,
      confidence: _scoreCandidate(best),
    );
  }

  int _scoreCandidate(String text) {
    var score = 0;
    if (RegExp(r'\d').hasMatch(text)) score += 5;
    if (RegExp(r'[A-ZА-Я]').hasMatch(text)) score += 5;
    if (text.length >= 6 && text.length <= 9) score += 8;

    // Country format catalog boosts (RU, DE, FR, …).
    final detected = _registry.detectCountry(text);
    score += detected.score;

    // Prefer RU civilian when it clearly matches (legacy weight).
    if (RegExp(r'^[АВЕКМНОРСТУХ]\d{3}[АВЕКМНОРСТУХ]{2}\d{2,3}$')
        .hasMatch(text)) {
      score += 8;
    }
    if (RegExp(r'^[A-Z]{1,3}\d{1,4}[A-Z]{0,3}$').hasMatch(text)) {
      score += 10;
    }
    return score;
  }

  Future<void> dispose() => _recognizer.close();
}
