import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../plates/plate_fields.dart';
import '../plates/plate_registry.dart';
import '../plates/ru_plate.dart';
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
  TextRecognizer? _recognizer;

  TextRecognizer get _textRecognizer => _recognizer ??=
      TextRecognizer(script: TextRecognitionScript.latin);

  Future<String?> recognizeFromFile(String path) async {
    final rich = await recognizeRichFromFile(path);
    return rich?.text;
  }

  Future<PlateOcrResult?> recognizeRichFromFile(
    String path, {
    String? expectedCountry,
  }) async {
    final input = InputImage.fromFilePath(path);
    final result = await _textRecognizer.processImage(input);
    return interpretText(result.text, expectedCountry: expectedCountry);
  }

  /// OCR several frames and keep the highest-confidence candidate.
  ///
  /// [expectedCountry] is the Russia / US / other choice from the scan screen.
  /// A region read on one frame is combined with the body from another.
  Future<PlateOcrResult?> recognizeBestFromFiles(
    List<String> paths, {
    String? expectedCountry,
  }) async {
    PlateOcrResult? best;
    final texts = <String>[];
    for (final path in paths) {
      if (path.isEmpty) continue;
      try {
        final input = InputImage.fromFilePath(path);
        final result = await _textRecognizer.processImage(input);
        if (result.text.trim().isEmpty) continue;
        texts.add(result.text);
        final single = interpretText(
          result.text,
          expectedCountry: expectedCountry,
        );
        if (single == null) continue;
        if (best == null || single.confidence > best.confidence) {
          best = single;
        }
      } catch (_) {}
    }
    if (texts.length >= 2) {
      final joined = interpretText(
        texts.join('\n'),
        expectedCountry: expectedCountry,
      );
      final joinedRegion = joined == null ? null : RuPlate.read(joined.text);
      if (joined != null &&
          (joinedRegion?.knownRegion == true ||
              best == null ||
              joined.confidence > best.confidence)) {
        return joined;
      }
    }
    return best;
  }

  Future<String?> recognizeFromFileObject(File file) {
    return recognizeFromFile(file.path);
  }

  /// Plate text from an OCR dump, without calling the camera recognizer.
  PlateOcrResult? interpretText(String fullText, {String? expectedCountry}) {
    if (fullText.trim().isEmpty) return null;

    final stitched = RuPlate.combine(fullText);
    final lines = fullText
        .split(RegExp(r'[\r\n]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final candidates = <String>[];
    if (stitched != null && stitched.isNotEmpty) candidates.add(stitched);
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
      final detected = _registry.detectCountry(
        fallback,
        hintCountry: expectedCountry,
      );
      return PlateOcrResult(
        text: _present(fallback, detected),
        suggestedCountry: detected.code,
        confidence: detected.score,
      );
    }

    candidates.sort((a, b) {
      final scoreA = _scoreCandidate(a, expectedCountry);
      final scoreB = _scoreCandidate(b, expectedCountry);
      return scoreB.compareTo(scoreA);
    });

    var best = candidates.first;
    if (stitched != null) {
      final stitchedRead = RuPlate.read(stitched);
      if (stitchedRead != null && stitchedRead.knownRegion) best = stitched;
    }
    final detected = _registry.detectCountry(
      best,
      hintCountry: expectedCountry,
    );
    return PlateOcrResult(
      text: _present(best, detected),
      suggestedCountry: detected.code,
      confidence: detected.score,
    );
  }

  String _present(
    String raw,
    ({String code, int score, ParsedPlateFields fields}) detected,
  ) {
    if (detected.code == 'RU' && detected.fields.displayText.isNotEmpty) {
      return detected.fields.displayText;
    }
    return raw;
  }

  int _scoreCandidate(String text, String? expectedCountry) {
    var score = 0;
    if (RegExp(r'\d').hasMatch(text)) score += 5;
    if (RegExp(r'[A-ZА-Я]').hasMatch(text)) score += 5;
    if (text.length >= 6 && text.length <= 9) score += 8;

    // Country format catalog boosts (RU, DE, FR, …).
    final detected = _registry.detectCountry(
      text,
      hintCountry: expectedCountry,
    );
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

  Future<void> dispose() async {
    await _recognizer?.close();
    _recognizer = null;
  }
}
