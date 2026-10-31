import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/update/update_service.dart';
import 'data/achievements/achievements.dart';
import 'data/leaderboard/leaderboard_service.dart';
import 'data/models/collection_item.dart';
import 'data/models/rarity.dart';
import 'data/models/trust_level.dart';
import 'data/models/user_profile.dart';
import 'data/ocr/plate_ocr_service.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/collection_repository.dart';
import 'data/repositories/local_store.dart';
import 'data/sightings/sighting_service.dart';
import 'data/valuation/currency.dart';
import 'data/valuation/plate_valuation_engine.dart';
import 'firebase_options.dart';

enum CollectionSort { newest, valueDesc, rarityDesc, streetFirst }

enum TrustFilter { all, street, unverified }

class AppState extends ChangeNotifier {
  AppState({UpdateService? updateService})
      : updateService = updateService ?? GithubReleaseUpdateService();

  final UpdateService updateService;
  final LocalStore localStore = LocalStore();
  final PlateOcrService ocrService = PlateOcrService();
  final AchievementsEngine achievementsEngine = const AchievementsEngine();

  late AuthRepository authRepository;
  late CollectionRepository collectionRepository;
  late LeaderboardService leaderboardService;
  late SightingService sightingService;

  bool ready = false;
  bool cloudEnabled = false;
  String? bootError;

  AppCurrency currency = AppCurrency.rub;

  String countryFilter = '';
  Rarity? rarityFilter;
  String searchQuery = '';
  CollectionSort sort = CollectionSort.newest;
  TrustFilter trustFilter = TrustFilter.all;
  bool favoritesOnly = false;
  bool showcaseOnly = false;

  List<CollectionItem> publicFeed = [];
  List<UserProfile> publicProfiles = [];
  List<LeaderboardEntry> streetBoard = [];

  UserProfile? get profile => authRepository.currentProfile;
  bool get isSignedIn => profile != null;

  List<CollectionItem> get myItems {
    var items = collectionRepository.filtered(
      country: countryFilter,
      rarity: rarityFilter,
      query: searchQuery,
    );
    if (trustFilter == TrustFilter.street) {
      items = items.where((e) => e.isStreet).toList();
    } else if (trustFilter == TrustFilter.unverified) {
      items = items.where((e) => !e.isStreet).toList();
    }
    if (favoritesOnly) {
      items = items.where((e) => e.isFavorite).toList();
    }
    if (showcaseOnly) {
      items = items.where((e) => e.isShowcase).toList();
    }
    return _sorted(items);
  }

  List<CollectionItem> _sorted(List<CollectionItem> items) {
    final copy = List<CollectionItem>.from(items);
    switch (sort) {
      case CollectionSort.newest:
        copy.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case CollectionSort.valueDesc:
        copy.sort((a, b) {
          final va = PlateValuationEngine.instance
              .estimate(countryCode: a.countryCode, rawText: a.rawText)
              .amountRub;
          final vb = PlateValuationEngine.instance
              .estimate(countryCode: b.countryCode, rawText: b.rawText)
              .amountRub;
          final c = vb.compareTo(va);
          return c != 0 ? c : b.createdAt.compareTo(a.createdAt);
        });
      case CollectionSort.rarityDesc:
        copy.sort((a, b) {
          final c = b.rarity.index.compareTo(a.rarity.index);
          return c != 0 ? c : b.createdAt.compareTo(a.createdAt);
        });
      case CollectionSort.streetFirst:
        copy.sort((a, b) {
          final c = (b.isStreet ? 1 : 0).compareTo(a.isStreet ? 1 : 0);
          return c != 0 ? c : b.createdAt.compareTo(a.createdAt);
        });
    }
    return copy;
  }

  double get collectionWorthRub => leaderboardService.portfolioWorth(
        collectionRepository.items,
        kind: LeaderboardKind.unverified,
      );

  double get streetWorthRub => leaderboardService.portfolioWorth(
        collectionRepository.items,
        kind: LeaderboardKind.street,
      );

  int get streetCount => leaderboardService.plateCount(
        collectionRepository.items,
        kind: LeaderboardKind.street,
      );

  List<Achievement> get achievements =>
      achievementsEngine.evaluate(collectionRepository.items);

  Future<void> init() async {
    try {
      cloudEnabled = await _tryInitFirebase();
      authRepository = AuthRepository(
        localStore: localStore,
        auth: cloudEnabled ? FirebaseAuth.instance : null,
        firestore: cloudEnabled ? FirebaseFirestore.instance : null,
        cloudEnabled: cloudEnabled,
      );
      collectionRepository = CollectionRepository(
        localStore: localStore,
        firestore: cloudEnabled ? FirebaseFirestore.instance : null,
        cloudEnabled: cloudEnabled,
      );
      leaderboardService = LeaderboardService(
        firestore: cloudEnabled ? FirebaseFirestore.instance : null,
        cloudEnabled: cloudEnabled,
      );
      sightingService = SightingService(
        localStore: localStore,
        firestore: cloudEnabled ? FirebaseFirestore.instance : null,
        cloudEnabled: cloudEnabled,
      );
      await collectionRepository.load();
      await authRepository.restoreSession();
      currency = await localStore.loadCurrency();
      await refreshPublic();
      await refreshLeaderboards();
    } catch (e, st) {
      bootError = '$e';
      debugPrint('AppState.init failed: $e\n$st');
      authRepository = AuthRepository(localStore: localStore);
      collectionRepository = CollectionRepository(localStore: localStore);
      leaderboardService = LeaderboardService();
      sightingService = SightingService(localStore: localStore);
      await collectionRepository.load();
      await authRepository.restoreSession();
      currency = await localStore.loadCurrency();
      cloudEnabled = false;
      await refreshLeaderboards();
    } finally {
      ready = true;
      notifyListeners();
    }
  }

  Future<void> setCurrency(AppCurrency value) async {
    currency = value;
    await localStore.saveCurrency(value);
    notifyListeners();
  }

  Future<bool> _tryInitFirebase() async {
    if (!DefaultFirebaseOptions.isConfigured) {
      return false;
    }
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      return true;
    } catch (e) {
      debugPrint('Firebase init skipped: $e');
      return false;
    }
  }

  Future<void> signInLocal(String displayName) async {
    await authRepository.signInLocal(displayName: displayName);
    await refreshLeaderboards();
    notifyListeners();
  }

  Future<void> registerEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    await authRepository.registerEmail(
      email: email,
      password: password,
      displayName: displayName,
    );
    await refreshLeaderboards();
    notifyListeners();
  }

  Future<void> signInEmail({
    required String email,
    required String password,
  }) async {
    await authRepository.signInEmail(email: email, password: password);
    await refreshLeaderboards();
    notifyListeners();
  }

  Future<void> signOut() async {
    await authRepository.signOut();
    notifyListeners();
  }

  Future<void> updateProfile(UserProfile profile) async {
    await authRepository.updateProfile(profile);
    if (profile.publicCollectionEnabled) {
      for (final item in collectionRepository.items) {
        if (!item.isPublic) {
          await collectionRepository.setItemPublic(
            item.id,
            true,
            profile.uid,
          );
        }
      }
    }
    await refreshPublic();
    await refreshLeaderboards();
    notifyListeners();
  }

  Future<int> peekSightings({
    required String countryCode,
    required String rawText,
  }) {
    return sightingService.getCount(
      countryCode: countryCode,
      rawText: rawText,
    );
  }

  Future<CollectionItem> addPlate({
    required String countryCode,
    required String rawText,
    String? photoPath,
    String? photoPathAlt,
    String? notes,
    bool? isPublic,
    TrustLevel trust = TrustLevel.street,
    CaptureSource captureSource = CaptureSource.liveCamera,
  }) async {
    final user = profile!;
    final total = await sightingService.recordSighting(
      countryCode: countryCode,
      rawText: rawText,
    );
    final item = await collectionRepository.addPlate(
      userId: user.uid,
      countryCode: countryCode,
      rawText: rawText,
      photoPath: photoPath,
      photoPathAlt: photoPathAlt,
      notes: notes,
      isPublic: isPublic ?? user.publicCollectionEnabled,
      trust: trust,
      captureSource: captureSource,
      sightingCount: total,
    );
    await authRepository.updateProfile(
      user.copyWith(itemCount: collectionRepository.items.length),
    );
    await refreshLeaderboards();
    notifyListeners();
    return item;
  }

  CollectionItem? findDuplicate({
    required String countryCode,
    required String rawText,
    String? excludeId,
  }) {
    return collectionRepository.findDuplicate(
      countryCode: countryCode,
      rawText: rawText,
      excludeId: excludeId,
    );
  }

  Future<void> updatePlate(CollectionItem item) async {
    await collectionRepository.updateItem(item);
    await refreshLeaderboards();
    notifyListeners();
  }

  Future<void> toggleFavorite(CollectionItem item) async {
    await updatePlate(item.copyWith(isFavorite: !item.isFavorite));
  }

  Future<void> toggleShowcase(CollectionItem item) async {
    await updatePlate(item.copyWith(isShowcase: !item.isShowcase));
  }

  Future<void> deletePlate(String id) async {
    final user = profile!;
    await collectionRepository.deleteItem(id, user.uid);
    await authRepository.updateProfile(
      user.copyWith(itemCount: collectionRepository.items.length),
    );
    await refreshLeaderboards();
    notifyListeners();
  }

  void setFilters({
    String? country,
    Rarity? rarity,
    String? query,
    CollectionSort? sortBy,
    TrustFilter? trust,
    bool? favOnly,
    bool? showOnly,
    bool clearRarity = false,
  }) {
    if (country != null) countryFilter = country;
    if (clearRarity) {
      rarityFilter = null;
    } else if (rarity != null) {
      rarityFilter = rarity;
    }
    if (query != null) searchQuery = query;
    if (sortBy != null) sort = sortBy;
    if (trust != null) trustFilter = trust;
    if (favOnly != null) favoritesOnly = favOnly;
    if (showOnly != null) showcaseOnly = showOnly;
    notifyListeners();
  }

  Future<void> refreshPublic() async {
    publicFeed = await collectionRepository.fetchPublicFeed();
    publicProfiles = await authRepository.fetchPublicProfiles();
    notifyListeners();
  }

  Future<void> refreshLeaderboards() async {
    final me = profile;
    final mine = collectionRepository.items;
    final visible = [
      ...publicFeed,
      if (me != null) ...mine.where((e) => e.isPublic || true),
    ];
    // Dedupe by id
    final byId = <String, CollectionItem>{
      for (final i in visible) i.id: i,
    };
    streetBoard = await leaderboardService.build(
      kind: LeaderboardKind.street,
      profiles: publicProfiles,
      allVisibleItems: byId.values.toList(),
      me: me,
      myItems: mine,
    );
    if (me != null) {
      await leaderboardService.publishMine(me: me, myItems: mine);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    ocrService.dispose();
    super.dispose();
  }
}
