import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/update/update_service.dart';
import 'data/models/collection_item.dart';
import 'data/models/rarity.dart';
import 'data/models/user_profile.dart';
import 'data/ocr/plate_ocr_service.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/collection_repository.dart';
import 'data/repositories/local_store.dart';
import 'firebase_options.dart';

class AppState extends ChangeNotifier {
  AppState({UpdateService? updateService})
      : updateService = updateService ?? GithubReleaseUpdateService();

  final UpdateService updateService;
  final LocalStore localStore = LocalStore();
  final PlateOcrService ocrService = PlateOcrService();

  late AuthRepository authRepository;
  late CollectionRepository collectionRepository;

  bool ready = false;
  bool cloudEnabled = false;
  String? bootError;

  String countryFilter = '';
  Rarity? rarityFilter;
  String searchQuery = '';

  List<CollectionItem> publicFeed = [];
  List<UserProfile> publicProfiles = [];

  UserProfile? get profile => authRepository.currentProfile;
  bool get isSignedIn => profile != null;
  List<CollectionItem> get myItems => collectionRepository.filtered(
        country: countryFilter,
        rarity: rarityFilter,
        query: searchQuery,
      );

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
      await collectionRepository.load();
      await authRepository.restoreSession();
      await refreshPublic();
    } catch (e, st) {
      bootError = '$e';
      debugPrint('AppState.init failed: $e\n$st');
      // Ensure local mode still works.
      authRepository = AuthRepository(localStore: localStore);
      collectionRepository = CollectionRepository(localStore: localStore);
      await collectionRepository.load();
      await authRepository.restoreSession();
      cloudEnabled = false;
    } finally {
      ready = true;
      notifyListeners();
    }
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
    notifyListeners();
  }

  Future<void> signInEmail({
    required String email,
    required String password,
  }) async {
    await authRepository.signInEmail(email: email, password: password);
    notifyListeners();
  }

  Future<void> signOut() async {
    await authRepository.signOut();
    notifyListeners();
  }

  Future<void> updateProfile(UserProfile profile) async {
    await authRepository.updateProfile(profile);
    // Mirror public flag onto items when enabling.
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
    notifyListeners();
  }

  Future<CollectionItem> addPlate({
    required String countryCode,
    required String rawText,
    String? photoPath,
    String? notes,
    bool? isPublic,
  }) async {
    final user = profile!;
    final item = await collectionRepository.addPlate(
      userId: user.uid,
      countryCode: countryCode,
      rawText: rawText,
      photoPath: photoPath,
      notes: notes,
      isPublic: isPublic ?? user.publicCollectionEnabled,
    );
    await authRepository.updateProfile(
      user.copyWith(itemCount: collectionRepository.items.length),
    );
    notifyListeners();
    return item;
  }

  Future<void> updatePlate(CollectionItem item) async {
    await collectionRepository.updateItem(item);
    notifyListeners();
  }

  Future<void> deletePlate(String id) async {
    final user = profile!;
    await collectionRepository.deleteItem(id, user.uid);
    await authRepository.updateProfile(
      user.copyWith(itemCount: collectionRepository.items.length),
    );
    notifyListeners();
  }

  void setFilters({
    String? country,
    Rarity? rarity,
    String? query,
    bool clearRarity = false,
  }) {
    if (country != null) countryFilter = country;
    if (clearRarity) {
      rarityFilter = null;
    } else if (rarity != null) {
      rarityFilter = rarity;
    }
    if (query != null) searchQuery = query;
    notifyListeners();
  }

  Future<void> refreshPublic() async {
    publicFeed = await collectionRepository.fetchPublicFeed();
    publicProfiles = await authRepository.fetchPublicProfiles();
    notifyListeners();
  }

  @override
  void dispose() {
    ocrService.dispose();
    super.dispose();
  }
}
