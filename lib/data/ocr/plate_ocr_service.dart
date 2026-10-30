import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../rarity/rarity_engine.dart';

class PlateOcrService {
  PlateOcrService({RarityEngine? rarityEngine})
      : _rarity = rarityEngine ?? RarityEngine.instance;

  final RarityEngine _rarity;
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<String?> recognizeFromFile(String path) async {
    final input = InputImage.fromFilePath(path);
    final result = await _recognizer.processImage(input);
    return _pickBestPlateCandidate(result.text);
  }

  Future<String?> recognizeFromFileObject(File file) {
    return recognizeFromFile(file.path);
  }

  String? _pickBestPlateCandidate(String fullText) {
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
      // Also keep lightly cleaned original for Cyrillic plates.
      final loose = line.toUpperCase().replaceAll(RegExp(r'[\s\-]'), '');
      if (loose.length >= 3 && loose.length <= 14) {
        candidates.add(loose);
      }
    }

    if (candidates.isEmpty) {
      final fallback = _rarity.normalize(fullText);
      return fallback.isEmpty ? null : fallback;
    }

    candidates.sort((a, b) {
      final scoreA = _scoreCandidate(a);
      final scoreB = _scoreCandidate(b);
      return scoreB.compareTo(scoreA);
    });
    return candidates.first;
  }

  int _scoreCandidate(String text) {
    var score = 0;
    if (RegExp(r'\d').hasMatch(text)) score += 5;
    if (RegExp(r'[A-ZА-Я]').hasMatch(text)) score += 5;
    if (text.length >= 6 && text.length <= 9) score += 8;
    if (RegExp(r'^[АВЕКМНОРСТУХ]\d{3}[АВЕКМНОРСТУХ]{2}\d{2,3}$')
        .hasMatch(text)) {
      score += 30;
    }
    if (RegExp(r'^[A-Z]{1,3}\d{1,4}[A-Z]{0,3}$').hasMatch(text)) {
      score += 15;
    }
    return score;
  }

  Future<void> dispose() => _recognizer.close();
}
