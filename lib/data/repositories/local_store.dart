import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/collection_item.dart';
import '../models/user_profile.dart';
import '../valuation/currency.dart';

class LocalStore {
  static const _itemsKey = 'collection_items_v1';
  static const _profileKey = 'user_profile_v1';
  static const _sessionKey = 'local_session_v1';
  static const _currencyKey = 'preferred_currency_v1';
  static const _sightingsKey = 'plate_sightings_v1';
  static const _dualAngleTutorialKey = 'dual_angle_tutorial_seen_v1';

  Future<List<CollectionItem>> loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_itemsKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => CollectionItem.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> saveItems(List<CollectionItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_itemsKey, encoded);
  }

  Future<UserProfile?> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey);
    if (raw == null) return null;
    return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  Future<void> clearProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileKey);
    await prefs.remove(_sessionKey);
  }

  Future<void> setLocalSession(bool active) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sessionKey, active);
  }

  Future<bool> hasLocalSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_sessionKey) ?? false;
  }

  Future<AppCurrency> loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    return AppCurrency.fromCode(prefs.getString(_currencyKey));
  }

  Future<void> saveCurrency(AppCurrency currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, currency.code);
  }

  Future<String> photosDir() async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory('${root.path}/plate_photos');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  Future<Map<String, int>> loadSightings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sightingsKey);
    if (raw == null || raw.isEmpty) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return {
      for (final e in map.entries) e.key: (e.value as num).toInt(),
    };
  }

  Future<int> getSightingCount(String plateId) async {
    final all = await loadSightings();
    return all[plateId] ?? 0;
  }

  Future<void> setSightingCount(String plateId, int count) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await loadSightings();
    all[plateId] = count;
    await prefs.setString(_sightingsKey, jsonEncode(all));
  }

  Future<bool> hasSeenDualAngleTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_dualAngleTutorialKey) ?? false;
  }

  Future<void> setDualAngleTutorialSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dualAngleTutorialKey, true);
  }
}
