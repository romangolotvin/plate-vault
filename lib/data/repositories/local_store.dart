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
  static const _dailyCompletedKey = 'daily_contract_completed_day_v1';
  static const _dailyBonusKey = 'daily_contract_lifetime_bonus_v1';
  static const _dailyBadgesKey = 'daily_contract_badges_v1';
  static const _streakKey = 'hunt_streak_v1';
  static const _duelKey = 'weekly_duel_v1';
  static const _clanKey = 'my_clan_v1';
  static const _clansDirKey = 'known_clans_v1';
  static const _cooldownsKey = 'plate_cooldowns_v1';
  static const _reportsKey = 'plate_reports_v1';

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

  Future<String?> loadDailyCompletedDay() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_dailyCompletedKey);
  }

  Future<void> saveDailyCompletedDay(String dayKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dailyCompletedKey, dayKey);
  }

  Future<double> loadDailyLifetimeBonus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_dailyBonusKey) ?? 0;
  }

  Future<void> saveDailyLifetimeBonus(double rub) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_dailyBonusKey, rub);
  }

  Future<List<String>> loadDailyBadges() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_dailyBadgesKey) ?? const [];
  }

  Future<void> saveDailyBadges(List<String> badges) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_dailyBadgesKey, badges);
  }

  Future<Map<String, dynamic>?> loadJsonMap(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> saveJsonMap(String key, Map<String, dynamic> value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(value));
  }

  Future<Map<String, dynamic>?> loadStreakJson() => loadJsonMap(_streakKey);
  Future<void> saveStreakJson(Map<String, dynamic> json) =>
      saveJsonMap(_streakKey, json);

  Future<Map<String, dynamic>?> loadDuelJson() => loadJsonMap(_duelKey);
  Future<void> saveDuelJson(Map<String, dynamic> json) =>
      saveJsonMap(_duelKey, json);

  Future<Map<String, dynamic>?> loadClanJson() => loadJsonMap(_clanKey);
  Future<void> saveClanJson(Map<String, dynamic> json) =>
      saveJsonMap(_clanKey, json);
  Future<void> clearClan() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_clanKey);
  }

  Future<List<Map<String, dynamic>>> loadKnownClans() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_clansDirKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> saveKnownClans(List<Map<String, dynamic>> clans) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clansDirKey, jsonEncode(clans));
  }

  Future<Map<String, int>> loadCooldowns() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cooldownsKey);
    if (raw == null || raw.isEmpty) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return {for (final e in map.entries) e.key: (e.value as num).toInt()};
  }

  Future<void> saveCooldowns(Map<String, int> map) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cooldownsKey, jsonEncode(map));
  }

  /// plateId -> report count (local anti-cheat complaints).
  Future<Map<String, int>> loadReports() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_reportsKey);
    if (raw == null || raw.isEmpty) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return {for (final e in map.entries) e.key: (e.value as num).toInt()};
  }

  Future<void> saveReports(Map<String, int> map) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_reportsKey, jsonEncode(map));
  }
}
