import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'core/update/update_service.dart';
import 'data/appeals/appeal_client.dart';
import 'data/appeals/plate_appeal.dart';
import 'data/achievements/achievements.dart';
import 'data/clans/clan_models.dart';
import 'data/daily/daily_contract.dart';
import 'data/duel/weekly_duel.dart';
import 'data/leaderboard/leaderboard_service.dart';
import 'data/models/collection_item.dart';
import 'data/models/rarity.dart';
import 'data/models/trust_level.dart';
import 'data/models/user_profile.dart';
import 'data/museum/museum_picker.dart';
import 'data/ocr/plate_ocr_service.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/collection_repository.dart';
import 'data/repositories/local_store.dart';
import 'data/seasons/season.dart';
import 'data/sets/plate_sets.dart';
import 'data/sightings/sighting_service.dart';
import 'data/streak/hunt_streak.dart';
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
  List<LeaderboardEntry> seasonBoard = [];
  Season currentSeason = Season.current();

  /// Normalized plateId -> last capture epoch millis (Street cooldown).
  Map<String, int> plateCooldowns = {};

  /// Normalized plateId -> local complaint count.
  Map<String, int> plateReports = {};

  /// Appeals waiting on the owner's desktop program.
  List<PlateAppeal> appeals = [];
  String appealDesktopUrl = '';
  String appealDesktopToken = '';
  final AppealClient appealClient = AppealClient();
  final Uuid _appealIds = const Uuid();

  DailyContractState? dailyState;
  HuntStreak huntStreak = const HuntStreak(current: 0, best: 0);
  WeeklyDuel? weeklyDuel;
  Clan? myClan;
  final _duelMatcher = const DuelMatcher();
  final _clanService = ClanService();

  UserProfile? get profile => authRepository.currentProfile;
  bool get isSignedIn => profile != null;
  HuntStreak get streakUi => huntStreak.resolved();

  double get seasonWorthRub => leaderboardService.portfolioWorth(
    collectionRepository.items,
    kind: LeaderboardKind.street,
    seasonId: currentSeason.id,
  );

  static const plateCooldown = Duration(hours: 12);

  String? cooldownMessageFor({
    required String countryCode,
    required String rawText,
  }) {
    final id = SightingService.plateId(
      countryCode: countryCode,
      rawOrNormalized: rawText,
    );
    final last = plateCooldowns[id];
    if (last == null) return null;
    final elapsed = DateTime.now().millisecondsSinceEpoch - last;
    final left = plateCooldown.inMilliseconds - elapsed;
    if (left <= 0) return null;
    final hours = (left / (1000 * 60 * 60)).ceil();
    return 'Этот номер уже снимали недавно. Подождите ~$hours ч.';
  }

  int reportCountFor(CollectionItem item) {
    final id = SightingService.plateId(
      countryCode: item.countryCode,
      rawOrNormalized: item.rawText,
    );
    return plateReports[id] ?? 0;
  }

  Future<void> reportPlate(CollectionItem item) async {
    final id = SightingService.plateId(
      countryCode: item.countryCode,
      rawOrNormalized: item.rawText,
    );
    plateReports[id] = (plateReports[id] ?? 0) + 1;
    await localStore.saveReports(plateReports);
    notifyListeners();
  }

  String? appealStatusLabelFor(String plateItemId) {
    final latest = latestAppeal(appeals, plateItemId);
    if (latest == null) return null;
    return appealDeliveryLabel(latest.delivery);
  }

  Future<void> _loadAppeals() async {
    appeals = await localStore.loadAppeals();
    appealDesktopUrl = await localStore.loadAppealDesktopUrl();
    appealDesktopToken = await localStore.loadAppealDesktopToken();
    await refreshAppealDecisions();
  }

  Future<void> setAppealDesktop({
    required String url,
    required String token,
  }) async {
    appealDesktopUrl = url.trim();
    appealDesktopToken = token.trim();
    await localStore.saveAppealDesktopUrl(appealDesktopUrl);
    await localStore.saveAppealDesktopToken(appealDesktopToken);
    notifyListeners();
  }

  /// Sends the scanned number, the corrected number, and the plate photos.
  /// Returns a Russian error, or null when the desktop program accepted it.
  Future<String?> submitPlateAppeal({
    required CollectionItem item,
    required String correctedNumber,
  }) async {
    final corrected = correctedNumber.trim();
    if (corrected.isEmpty) {
      return 'Введите номер в поле «Скорректировать номер».';
    }
    final blocked = appealBlockReason(appeals, item.id);
    if (blocked != null) return blocked;
    final me = profile;
    if (me == null || item.userId != me.uid) {
      return 'Обжаловать можно только свой номер.';
    }
    if (appealDesktopUrl.isEmpty) {
      return 'Укажите адрес программы владельца.';
    }
    final appeal = PlateAppeal(
      id: _appealIds.v4(),
      plateItemId: item.id,
      countryCode: item.countryCode,
      scannedNumber: item.rawText,
      correctedNumber: corrected,
      photoPaths: item.allPhotoPaths,
      createdAt: DateTime.now(),
      delivery: AppealDelivery.queued,
    );
    appeals = upsertAppeal(appeals, appeal);
    await localStore.saveAppeals(appeals);
    notifyListeners();
    return _deliverAppeal(appeal);
  }

  Future<String?> retryAppeal(String id) async {
    PlateAppeal? appeal;
    for (final candidate in appeals) {
      if (candidate.id == id) appeal = candidate;
    }
    if (appeal == null) return 'Заявление не найдено.';
    if (appeal.delivery != AppealDelivery.queued) return null;
    if (appealDesktopUrl.isEmpty) {
      return 'Укажите адрес программы владельца.';
    }
    return _deliverAppeal(appeal);
  }

  Future<void> refreshAppealDecisions() async {
    if (appealDesktopUrl.isEmpty) return;
    final snapshot = List<PlateAppeal>.from(appeals);
    for (final appeal in snapshot) {
      if (appeal.delivery == AppealDelivery.queued) {
        await _deliverAppeal(appeal);
        continue;
      }
      if (appeal.delivery != AppealDelivery.sent) continue;
      try {
        final remote = await appealClient.fetchStatus(
          baseUrl: appealDesktopUrl,
          token: appealDesktopToken,
          id: appeal.id,
        );
        if (remote == null) continue;
        final delivery = deliveryFromServer(remote.status);
        if (delivery == appeal.delivery) continue;
        final next = appeal.copyWith(delivery: delivery, clearError: true);
        appeals = upsertAppeal(appeals, next);
        await localStore.saveAppeals(appeals);
        if (delivery == AppealDelivery.approved) {
          await _applyApprovedCorrection(next);
        }
        notifyListeners();
      } on AppealTransportException {
        // The owner's computer is off. Keep the copy on the phone.
      }
    }
  }

  Future<String?> _deliverAppeal(PlateAppeal appeal) async {
    try {
      final photos = await appealClient.readPhotos(appeal.photoPaths);
      final result = await appealClient.submit(
        baseUrl: appealDesktopUrl,
        token: appealDesktopToken,
        appeal: appeal,
        photos: photos,
      );
      final delivery = deliveryFromServer(result.status);
      final next = appeal.copyWith(delivery: delivery, clearError: true);
      appeals = upsertAppeal(appeals, next);
      await localStore.saveAppeals(appeals);
      if (delivery == AppealDelivery.approved) {
        await _applyApprovedCorrection(next);
      }
      notifyListeners();
      return null;
    } on AppealTransportException catch (e) {
      final next = appeal.copyWith(error: e.messageRu);
      appeals = upsertAppeal(appeals, next);
      await localStore.saveAppeals(appeals);
      notifyListeners();
      return e.messageRu;
    }
  }

  Future<void> _applyApprovedCorrection(PlateAppeal appeal) async {
    CollectionItem? item;
    for (final candidate in collectionRepository.items) {
      if (candidate.id == appeal.plateItemId) {
        item = candidate;
        break;
      }
    }
    if (item == null) return;
    if (item.rawText.trim() == appeal.correctedNumber.trim()) return;
    await updatePlate(item.copyWith(rawText: appeal.correctedNumber));
  }

  List<PlateSetProgress> get setProgress =>
      PlateSetsCatalog.progressFor(collectionRepository.items);

  List<CollectionItem> get museumPlates =>
      MuseumPicker.pick(collectionRepository.items);

  double get dailyBonusRub => dailyState?.lifetimeBonusRub ?? 0;

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

  double get streetWorthRub =>
      leaderboardService.portfolioWorth(
        collectionRepository.items,
        kind: LeaderboardKind.street,
      ) +
      dailyBonusRub;

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
      await _loadDailyState();
      await _loadSocialState();
      plateCooldowns = await localStore.loadCooldowns();
      plateReports = await localStore.loadReports();
      await _loadAppeals();
      currentSeason = Season.current();
      await refreshPublic();
      await refreshLeaderboards();
      await ensureWeeklyDuel();
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
      await _loadDailyState();
      await _loadSocialState();
      plateCooldowns = await localStore.loadCooldowns();
      plateReports = await localStore.loadReports();
      await _loadAppeals();
      currentSeason = Season.current();
      cloudEnabled = false;
      await refreshLeaderboards();
      await ensureWeeklyDuel();
    } finally {
      ready = true;
      notifyListeners();
    }
  }

  Future<void> _loadDailyState() async {
    final contract = DailyContract.forDay();
    final completed = await localStore.loadDailyCompletedDay();
    final bonus = await localStore.loadDailyLifetimeBonus();
    final badges = await localStore.loadDailyBadges();
    dailyState = DailyContractState(
      contract: contract,
      completedDayKey: completed,
      lifetimeBonusRub: bonus,
      badges: badges,
    );
  }

  /// Called after a Street plate is saved. Returns true if today's contract completed.
  Future<bool> tryCompleteDailyContract(CollectionItem item) async {
    final current =
        dailyState ??
        DailyContractState(
          contract: DailyContract.forDay(),
          completedDayKey: null,
          lifetimeBonusRub: 0,
          badges: const [],
        );
    if (current.isCompleteToday) return false;
    if (!current.contract.matchesItem(item)) return false;

    final badges = [...current.badges];
    if (!badges.contains(current.contract.badgeRu)) {
      badges.add(current.contract.badgeRu);
    }
    final bonus = current.lifetimeBonusRub + current.contract.bonusRub;
    await localStore.saveDailyCompletedDay(current.contract.dayKey);
    await localStore.saveDailyLifetimeBonus(bonus);
    await localStore.saveDailyBadges(badges);
    dailyState = DailyContractState(
      contract: current.contract,
      completedDayKey: current.contract.dayKey,
      lifetimeBonusRub: bonus,
      badges: badges,
    );
    notifyListeners();
    return true;
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
          await collectionRepository.setItemPublic(item.id, true, profile.uid);
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
    return sightingService.getCount(countryCode: countryCode, rawText: rawText);
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
    final coolMsg = cooldownMessageFor(
      countryCode: countryCode,
      rawText: rawText,
    );
    if (coolMsg != null) {
      throw StateError(coolMsg);
    }
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
    await tryCompleteDailyContract(item);
    final pid = SightingService.plateId(
      countryCode: countryCode,
      rawOrNormalized: rawText,
    );
    plateCooldowns[pid] = DateTime.now().millisecondsSinceEpoch;
    await localStore.saveCooldowns(plateCooldowns);
    if (item.isStreet) {
      await _recordStreetStreak();
      await _syncClanPortfolio();
      await ensureWeeklyDuel(forceRefreshPortfolio: true);
    }
    await refreshLeaderboards();
    notifyListeners();
    return item;
  }

  Future<void> _loadSocialState() async {
    huntStreak = HuntStreak.fromJson(await localStore.loadStreakJson())
        .resolved();
    final duelJson = await localStore.loadDuelJson();
    if (duelJson != null) {
      weeklyDuel = WeeklyDuel.fromJson(duelJson);
    }
    final clanJson = await localStore.loadClanJson();
    if (clanJson != null) {
      myClan = Clan.fromJson(clanJson);
    }
  }

  Future<void> _recordStreetStreak() async {
    huntStreak = huntStreak.recordStreetSave();
    await localStore.saveStreakJson(huntStreak.toJson());
    notifyListeners();
  }

  Future<void> ensureWeeklyDuel({bool forceRefreshPortfolio = false}) async {
    final me = profile;
    if (me == null) return;
    final week = duelWeekId();
    final mine = streetWorthRub + dailyBonusRub;
    if (weeklyDuel == null ||
        weeklyDuel!.weekId != week ||
        forceRefreshPortfolio) {
      if (weeklyDuel != null &&
          weeklyDuel!.weekId == week &&
          forceRefreshPortfolio) {
        weeklyDuel = weeklyDuel!.withMyPortfolio(mine);
      } else {
        weeklyDuel = _duelMatcher.match(
          myUserId: me.uid,
          myPortfolioRub: mine,
          board: streetBoard,
        );
      }
      await localStore.saveDuelJson(weeklyDuel!.toJson());
      notifyListeners();
    }
  }

  Future<Clan> createClan(String name) async {
    final me = profile!;
    final clan = _clanService.create(
      clanName: name,
      ownerId: me.uid,
      ownerName: me.displayName,
      ownerStreetRub: streetWorthRub + dailyBonusRub,
    );
    myClan = clan;
    await localStore.saveClanJson(clan.toJson());
    final known = await localStore.loadKnownClans();
    known.removeWhere((e) => e['id'] == clan.id);
    known.add(clan.toJson());
    await localStore.saveKnownClans(known);
    notifyListeners();
    return clan;
  }

  Future<Clan?> joinClan(String inviteCode) async {
    final me = profile!;
    final known = await localStore.loadKnownClans();
    final clans = known.map(Clan.fromJson).toList();
    final joined = _clanService.join(
      knownClans: clans,
      inviteCode: inviteCode,
      userId: me.uid,
      displayName: me.displayName,
      streetRub: streetWorthRub + dailyBonusRub,
    );
    if (joined == null) return null;
    myClan = joined;
    await localStore.saveClanJson(joined.toJson());
    final idx = known.indexWhere((e) => e['id'] == joined.id);
    if (idx >= 0) {
      known[idx] = joined.toJson();
    } else {
      known.add(joined.toJson());
    }
    await localStore.saveKnownClans(known);
    notifyListeners();
    return joined;
  }

  Future<void> leaveClan() async {
    myClan = null;
    await localStore.clearClan();
    notifyListeners();
  }

  Future<void> _syncClanPortfolio() async {
    final me = profile;
    final clan = myClan;
    if (me == null || clan == null) return;
    final updated = _clanService.refreshMemberPortfolio(
      clan,
      me.uid,
      streetWorthRub + dailyBonusRub,
    );
    myClan = updated;
    await localStore.saveClanJson(updated.toJson());
    final known = await localStore.loadKnownClans();
    final idx = known.indexWhere((e) => e['id'] == updated.id);
    if (idx >= 0) {
      known[idx] = updated.toJson();
      await localStore.saveKnownClans(known);
    }
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
    if (!item.isShowcase) {
      if (!item.isStreet) {
        // Museum is Street-only.
        return;
      }
      if (!MuseumPicker.canAddShowcase(collectionRepository.items)) {
        return;
      }
    }
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
    final byId = <String, CollectionItem>{for (final i in visible) i.id: i};
    currentSeason = Season.current();
    streetBoard = await leaderboardService.build(
      kind: LeaderboardKind.street,
      profiles: publicProfiles,
      allVisibleItems: byId.values.toList(),
      me: me,
      myItems: mine,
    );
    seasonBoard = await leaderboardService.build(
      kind: LeaderboardKind.street,
      profiles: publicProfiles,
      allVisibleItems: byId.values.toList(),
      me: me,
      myItems: mine,
      seasonId: currentSeason.id,
    );
    // Inject daily-contract flex bonus into local "me" row.
    if (me != null && dailyBonusRub > 0) {
      streetBoard =
          [
            for (final e in streetBoard)
              if (e.isMe)
                LeaderboardEntry(
                  rank: e.rank,
                  userId: e.userId,
                  displayName: e.displayName,
                  portfolioRub: e.portfolioRub + dailyBonusRub,
                  plateCount: e.plateCount,
                  kind: e.kind,
                  isMe: true,
                )
              else
                e,
          ]..sort((a, b) {
            final c = b.portfolioRub.compareTo(a.portfolioRub);
            if (c != 0) return c;
            return b.plateCount.compareTo(a.plateCount);
          });
      streetBoard = [
        for (var i = 0; i < streetBoard.length; i++)
          LeaderboardEntry(
            rank: i + 1,
            userId: streetBoard[i].userId,
            displayName: streetBoard[i].displayName,
            portfolioRub: streetBoard[i].portfolioRub,
            plateCount: streetBoard[i].plateCount,
            kind: streetBoard[i].kind,
            isMe: streetBoard[i].isMe,
          ),
      ];
    }
    if (me != null) {
      await leaderboardService.publishMine(
        me: me,
        myItems: mine,
        dailyBonusRub: dailyBonusRub,
      );
    }
    notifyListeners();
  }

  @override
  void dispose() {
    ocrService.dispose();
    super.dispose();
  }
}
