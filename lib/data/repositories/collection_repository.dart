import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/collection_item.dart';
import '../models/rarity.dart';
import '../models/trust_level.dart';
import '../rarity/rarity_engine.dart';
import 'local_store.dart';

class CollectionRepository {
  CollectionRepository({
    required LocalStore localStore,
    RarityEngine? rarityEngine,
    FirebaseFirestore? firestore,
    bool cloudEnabled = false,
  })  : _local = localStore,
        _rarity = rarityEngine ?? RarityEngine.instance,
        _firestore = firestore,
        _cloudEnabled = cloudEnabled;

  final LocalStore _local;
  final RarityEngine _rarity;
  final FirebaseFirestore? _firestore;
  final bool _cloudEnabled;
  final _uuid = const Uuid();

  List<CollectionItem> _cache = [];

  List<CollectionItem> get items => List.unmodifiable(_cache);

  Future<void> load() async {
    _cache = await _local.loadItems();
  }

  Future<CollectionItem> addPlate({
    required String userId,
    required String countryCode,
    required String rawText,
    String? photoPath,
    String? notes,
    bool isPublic = false,
    List<String> tags = const [],
    TrustLevel trust = TrustLevel.unverified,
    CaptureSource captureSource = CaptureSource.manual,
    bool isFavorite = false,
    bool isShowcase = false,
  }) async {
    final normalized = _rarity.normalize(rawText);
    final result = _rarity.evaluate(
      countryCode: countryCode,
      rawText: rawText,
    );
    final meaningTags = result.meaningLabels;
    final mergedTags = {
      ...tags,
      ...meaningTags,
    }.toList(growable: false);
    // Street only via live camera; gallery/manual forced Unverified.
    final effectiveTrust = captureSource.qualifiesStreet
        ? trust
        : TrustLevel.unverified;
    final item = CollectionItem(
      id: _uuid.v4(),
      userId: userId,
      type: CollectionType.licensePlate,
      countryCode: countryCode.toUpperCase(),
      rawText: rawText.trim(),
      normalizedText: normalized,
      rarity: result.rarity,
      rarityReason: result.reason,
      createdAt: DateTime.now(),
      tags: mergedTags,
      photoPath: photoPath,
      isPublic: isPublic,
      notes: notes,
      trust: effectiveTrust,
      captureSource: captureSource,
      isFavorite: isFavorite,
      isShowcase: isShowcase,
    );
    _cache = [item, ..._cache];
    await _persist(userId);
    return item;
  }

  /// Duplicate = same country + normalized text (already in vault).
  CollectionItem? findDuplicate({
    required String countryCode,
    required String rawText,
    String? excludeId,
  }) {
    final norm = _rarity.normalize(rawText);
    final cc = countryCode.toUpperCase();
    for (final item in _cache) {
      if (excludeId != null && item.id == excludeId) continue;
      if (item.countryCode == cc && item.normalizedText == norm) {
        return item;
      }
    }
    return null;
  }

  Future<CollectionItem> updateItem(CollectionItem item) async {
    final normalized = _rarity.normalize(item.rawText);
    final result = _rarity.evaluate(
      countryCode: item.countryCode,
      rawText: item.rawText,
    );
    final meaningTags = result.meaningLabels;
    final updated = item.copyWith(
      normalizedText: normalized,
      rarity: result.rarity,
      rarityReason: result.reason,
      tags: meaningTags.isEmpty ? item.tags : meaningTags,
    );
    _cache = _cache.map((e) => e.id == updated.id ? updated : e).toList();
    await _persist(updated.userId);
    return updated;
  }

  Future<void> deleteItem(String id, String userId) async {
    _cache = _cache.where((e) => e.id != id).toList();
    await _persist(userId);
  }

  Future<void> setItemPublic(String id, bool isPublic, String userId) async {
    _cache = _cache
        .map((e) => e.id == id ? e.copyWith(isPublic: isPublic) : e)
        .toList();
    await _persist(userId);
  }

  List<CollectionItem> filtered({
    String? country,
    Rarity? rarity,
    String query = '',
  }) {
    final q = query.trim().toUpperCase();
    return _cache.where((item) {
      if (country != null &&
          country.isNotEmpty &&
          item.countryCode != country.toUpperCase()) {
        return false;
      }
      if (rarity != null && item.rarity != rarity) return false;
      if (q.isNotEmpty) {
        final inTags =
            item.tags.any((t) => t.toUpperCase().contains(q));
        if (!item.normalizedText.contains(q) &&
            !item.rawText.toUpperCase().contains(q) &&
            !inTags) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Future<List<CollectionItem>> fetchPublicFeed({int limit = 50}) async {
    if (!_cloudEnabled || _firestore == null) {
      return _cache.where((e) => e.isPublic).toList();
    }
    final snap = await _firestore!
        .collection('plates')
        .where('isPublic', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((d) => CollectionItem.fromJson({...d.data(), 'id': d.id}))
        .toList();
  }

  Future<void> _persist(String userId) async {
    await _local.saveItems(_cache);
    if (!_cloudEnabled || _firestore == null) return;

    final batch = _firestore!.batch();
    final col = _firestore!.collection('plates');
    for (final item in _cache.where((e) => e.userId == userId)) {
      batch.set(col.doc(item.id), item.toJson(), SetOptions(merge: true));
    }
    await batch.commit();
  }
}
