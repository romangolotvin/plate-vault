import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../models/user_profile.dart';
import 'local_store.dart';

class AuthRepository {
  AuthRepository({
    required LocalStore localStore,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    bool cloudEnabled = false,
  })  : _local = localStore,
        _auth = auth,
        _firestore = firestore,
        _cloudEnabled = cloudEnabled;

  final LocalStore _local;
  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;
  final bool _cloudEnabled;
  final _uuid = const Uuid();

  UserProfile? currentProfile;

  Future<UserProfile?> restoreSession() async {
    if (_cloudEnabled && _auth?.currentUser != null) {
      final user = _auth!.currentUser!;
      currentProfile = await _loadOrCreateCloudProfile(user);
      await _local.saveProfile(currentProfile!);
      return currentProfile;
    }

    if (await _local.hasLocalSession()) {
      currentProfile = await _local.loadProfile();
      return currentProfile;
    }
    return null;
  }

  Future<UserProfile> signInLocal({
    required String displayName,
  }) async {
    final existing = await _local.loadProfile();
    final profile = (existing ??
            UserProfile(
              uid: 'local_${_uuid.v4()}',
              displayName: displayName.trim().isEmpty
                  ? 'Коллекционер'
                  : displayName.trim(),
              isLocalOnly: true,
            ))
        .copyWith(
          displayName: displayName.trim().isEmpty
              ? (existing?.displayName ?? 'Коллекционер')
              : displayName.trim(),
          isLocalOnly: true,
        );
    currentProfile = profile;
    await _local.saveProfile(profile);
    await _local.setLocalSession(true);
    return profile;
  }

  Future<UserProfile> registerEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _ensureCloud();
    final cred = await _auth!.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await cred.user!.updateDisplayName(displayName.trim());
    final profile = UserProfile(
      uid: cred.user!.uid,
      displayName: displayName.trim().isEmpty ? 'Collector' : displayName.trim(),
      email: email.trim(),
      isLocalOnly: false,
    );
    await _saveCloudProfile(profile);
    currentProfile = profile;
    await _local.saveProfile(profile);
    await _local.setLocalSession(false);
    return profile;
  }

  Future<UserProfile> signInEmail({
    required String email,
    required String password,
  }) async {
    _ensureCloud();
    final cred = await _auth!.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final profile = await _loadOrCreateCloudProfile(cred.user!);
    currentProfile = profile;
    await _local.saveProfile(profile);
    await _local.setLocalSession(false);
    return profile;
  }

  Future<UserProfile> updateProfile(UserProfile profile) async {
    currentProfile = profile;
    await _local.saveProfile(profile);
    if (_cloudEnabled && _firestore != null && !profile.isLocalOnly) {
      await _saveCloudProfile(profile);
    }
    return profile;
  }

  Future<void> signOut() async {
    if (_cloudEnabled) {
      await _auth?.signOut();
    }
    await _local.setLocalSession(false);
    currentProfile = null;
  }

  Future<List<UserProfile>> fetchPublicProfiles({int limit = 40}) async {
    if (!_cloudEnabled || _firestore == null) {
      final me = currentProfile;
      if (me != null && me.publicCollectionEnabled) return [me];
      return [];
    }
    final snap = await _firestore!
        .collection('profiles')
        .where('publicCollectionEnabled', isEqualTo: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => UserProfile.fromJson(d.data())).toList();
  }

  void _ensureCloud() {
    if (!_cloudEnabled || _auth == null) {
      throw StateError(
        'Firebase не настроен. Используйте локальный вход или выполните flutterfire configure.',
      );
    }
  }

  Future<UserProfile> _loadOrCreateCloudProfile(User user) async {
    final doc = await _firestore!.collection('profiles').doc(user.uid).get();
    if (doc.exists) {
      return UserProfile.fromJson(doc.data()!);
    }
    final profile = UserProfile(
      uid: user.uid,
      displayName: user.displayName ?? 'Collector',
      email: user.email,
      isLocalOnly: false,
    );
    await _saveCloudProfile(profile);
    return profile;
  }

  Future<void> _saveCloudProfile(UserProfile profile) async {
    await _firestore!
        .collection('profiles')
        .doc(profile.uid)
        .set(profile.toJson(), SetOptions(merge: true));
  }
}
