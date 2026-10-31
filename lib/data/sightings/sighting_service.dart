import 'package:cloud_firestore/cloud_firestore.dart';

import '../repositories/local_store.dart';
import '../rarity/rarity_engine.dart';

/// Global (or local) count of how many times a plate was submitted.
class SightingService {
  SightingService({
    required LocalStore localStore,
    FirebaseFirestore? firestore,
    bool cloudEnabled = false,
    RarityEngine? rarityEngine,
  })  : _local = localStore,
        _firestore = firestore,
        _cloudEnabled = cloudEnabled,
        _rarity = rarityEngine ?? RarityEngine.instance;

  final LocalStore _local;
  final FirebaseFirestore? _firestore;
  final bool _cloudEnabled;
  final RarityEngine _rarity;

  static String plateId({
    required String countryCode,
    required String rawOrNormalized,
    RarityEngine? engine,
  }) {
    final rarity = engine ?? RarityEngine.instance;
    final norm = rarity.normalize(rawOrNormalized);
    return '${countryCode.toUpperCase()}_$norm';
  }

  String idFor({required String countryCode, required String rawText}) =>
      plateId(
        countryCode: countryCode,
        rawOrNormalized: rawText,
        engine: _rarity,
      );

  /// Current count before recording a new sighting.
  Future<int> getCount({
    required String countryCode,
    required String rawText,
  }) async {
    final id = idFor(countryCode: countryCode, rawText: rawText);
    if (id.endsWith('_')) return 0;

    var local = await _local.getSightingCount(id);

    if (_cloudEnabled && _firestore != null) {
      try {
        final doc =
            await _firestore!.collection('plate_sightings').doc(id).get();
        final cloud = (doc.data()?['count'] as num?)?.toInt() ?? 0;
        if (cloud > local) {
          local = cloud;
          await _local.setSightingCount(id, local);
        }
      } catch (_) {}
    }
    return local;
  }

  /// Increment local (+ cloud when configured). Returns new total.
  Future<int> recordSighting({
    required String countryCode,
    required String rawText,
  }) async {
    final id = idFor(countryCode: countryCode, rawText: rawText);
    if (id.endsWith('_')) return 0;

    final before = await getCount(countryCode: countryCode, rawText: rawText);
    final next = before + 1;
    await _local.setSightingCount(id, next);

    if (_cloudEnabled && _firestore != null) {
      try {
        await _firestore!.collection('plate_sightings').doc(id).set({
          'count': FieldValue.increment(1),
          'countryCode': countryCode.toUpperCase(),
          'normalizedText': _rarity.normalize(rawText),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        final doc =
            await _firestore!.collection('plate_sightings').doc(id).get();
        final cloud = (doc.data()?['count'] as num?)?.toInt();
        if (cloud != null && cloud > next) {
          await _local.setSightingCount(id, cloud);
          return cloud;
        }
      } catch (_) {}
    }
    return next;
  }
}

String sightingLabelRu(int count) {
  if (count <= 0) return '';
  final n = count;
  // Russian pluralization for «раз».
  final mod10 = n % 10;
  final mod100 = n % 100;
  final word = (mod10 == 1 && mod100 != 11)
      ? 'раз'
      : (mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20))
          ? 'раза'
          : 'раз';
  return 'Этот номер уже находили $n $word';
}
