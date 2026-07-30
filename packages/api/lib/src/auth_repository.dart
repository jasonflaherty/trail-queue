import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:trail_queue_models/trail_queue_models.dart';

import 'demo_store.dart';
import 'firebase_config.dart';
import 'firestore_paths.dart';

class AuthRepository {
  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth,
        _db = firestore;

  final FirebaseAuth? _auth;
  final FirebaseFirestore? _db;
  final _authController = StreamController<UserProfile?>.broadcast();
  final _googleSignIn = GoogleSignIn(scopes: const ['email']);

  bool get isConfigured =>
      FirebaseConfig.isConfigured && _auth != null;

  Stream<UserProfile?> get authStateChanges => _authController.stream;

  UserProfile? get currentUser {
    if (!isConfigured) return DemoStore.instance.currentUser;
    final user = _auth!.currentUser;
    if (user == null) return null;
    return _profileFromFirebaseUser(user);
  }

  Future<UserProfile> signInEmail(String email, String password) async {
    if (!isConfigured) {
      final profile = DemoData.currentUser.copyWith(email: email);
      DemoStore.instance.currentUser = profile;
      _authController.add(profile);
      return profile;
    }

    final cred = await _auth!.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final profile = await _ensureProfile(cred.user!);
    _authController.add(profile);
    return profile;
  }

  Future<UserProfile> signUpEmail(String email, String password) async {
    if (!isConfigured) {
      final profile = DemoData.currentUser.copyWith(
        email: email,
        displayName: email.split('@').first,
        roles: const [UserRole.volunteer],
        hasCompletedOnboarding: false,
      );
      DemoStore.instance.currentUser = profile;
      _authController.add(profile);
      return profile;
    }

    final cred = await _auth!.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final profile = await _ensureProfile(
      cred.user!,
      hasCompletedOnboarding: false,
    );
    _authController.add(profile);
    return profile;
  }

  Future<UserProfile> signInGoogle() async {
    if (!isConfigured) {
      final profile = DemoData.currentUser.copyWith(
        displayName: 'Google User',
        email: 'google@trailqueue.dev',
        roles: const [UserRole.volunteer],
        hasCompletedOnboarding: false,
      );
      DemoStore.instance.currentUser = profile;
      _authController.add(profile);
      return profile;
    }

    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'aborted',
        message: 'Google sign-in cancelled',
      );
    }
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final cred = await _auth!.signInWithCredential(credential);
    final profile = await _ensureProfile(
      cred.user!,
      hasCompletedOnboarding: false,
    );
    _authController.add(profile);
    return profile;
  }

  Future<UserProfile> signInApple() async {
    if (!isConfigured) {
      final profile = DemoData.currentUser.copyWith(
        displayName: 'Apple User',
        email: 'apple@trailqueue.dev',
        hasCompletedOnboarding: false,
      );
      DemoStore.instance.currentUser = profile;
      _authController.add(profile);
      return profile;
    }

    final provider = AppleAuthProvider();
    final cred = await _auth!.signInWithProvider(provider);
    final profile = await _ensureProfile(
      cred.user!,
      hasCompletedOnboarding: false,
    );
    _authController.add(profile);
    return profile;
  }

  Future<UserProfile> signInFacebook() async {
    if (!isConfigured) {
      final profile = DemoData.currentUser.copyWith(
        displayName: 'Facebook User',
        email: 'facebook@trailqueue.dev',
        roles: const [UserRole.volunteer],
        hasCompletedOnboarding: false,
      );
      DemoStore.instance.currentUser = profile;
      _authController.add(profile);
      return profile;
    }

    final provider = FacebookAuthProvider();
    provider.addScope('email');
    provider.addScope('public_profile');
    final cred = await _auth!.signInWithProvider(provider);
    final profile = await _ensureProfile(
      cred.user!,
      hasCompletedOnboarding: false,
    );
    _authController.add(profile);
    return profile;
  }

  Future<UserProfile> signInMicrosoft() async {
    if (!isConfigured) {
      final profile = DemoData.currentUser.copyWith(
        displayName: 'Microsoft User',
        email: 'microsoft@trailqueue.dev',
        roles: const [UserRole.volunteer],
        hasCompletedOnboarding: false,
      );
      DemoStore.instance.currentUser = profile;
      _authController.add(profile);
      return profile;
    }

    final provider = MicrosoftAuthProvider();
    provider.addScope('email');
    provider.addScope('openid');
    provider.addScope('profile');
    final cred = await _auth!.signInWithProvider(provider);
    final profile = await _ensureProfile(
      cred.user!,
      hasCompletedOnboarding: false,
    );
    _authController.add(profile);
    return profile;
  }

  Future<UserProfile> signInAnonymously() async {
    if (!isConfigured) {
      final profile = UserProfile(
        id: 'anon-${DateTime.now().millisecondsSinceEpoch}',
        displayName: 'Guest',
        isAnonymous: true,
        roles: const [UserRole.volunteer],
        hasCompletedOnboarding: false,
      );
      DemoStore.instance.currentUser = profile;
      _authController.add(profile);
      return profile;
    }

    final cred = await _auth!.signInAnonymously();
    final profile = await _ensureProfile(
      cred.user!,
      isAnonymous: true,
      hasCompletedOnboarding: false,
    );
    _authController.add(profile);
    return profile;
  }

  Future<void> signOut() async {
    if (!isConfigured) {
      DemoStore.instance.currentUser = null;
      _authController.add(null);
      return;
    }
    await _googleSignIn.signOut();
    await _auth!.signOut();
    _authController.add(null);
  }

  Future<UserProfile> completeOnboarding(UserRole role) async {
    final current = currentUser;
    if (current == null) throw StateError('Not signed in');

    final roles = switch (role) {
      UserRole.volunteer => [UserRole.volunteer],
      UserRole.crewLeader => [UserRole.volunteer, UserRole.crewLeader],
      UserRole.organization => [UserRole.organization, UserRole.volunteer],
      UserRole.landManager => [UserRole.landManager, UserRole.volunteer],
      UserRole.administrator => [UserRole.administrator],
    };

    final updated = current.copyWith(
      roles: roles,
      hasCompletedOnboarding: true,
    );

    if (!isConfigured) {
      DemoStore.instance.currentUser = updated;
      _authController.add(updated);
      return updated;
    }

    await _db!.collection(FirestorePaths.profiles).doc(updated.id).set({
      'display_name': updated.displayName,
      'email': updated.email,
      'has_completed_onboarding': true,
      'roles': roles.map((r) => r.toDb()).toList(),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    _authController.add(updated);
    return updated;
  }

  Future<UserProfile> joinOrganization(String organizationId) async {
    final current = currentUser;
    if (current == null) throw StateError('Not signed in');

    final ids = {...current.organizationIds, organizationId}.toList();
    final updated = current.copyWith(organizationIds: ids);

    if (!isConfigured) {
      DemoStore.instance.currentUser = updated;
      final orgs = DemoStore.instance.organizations;
      final index = orgs.indexWhere((o) => o.id == organizationId);
      if (index >= 0) {
        final o = orgs[index];
        orgs[index] = Organization(
          id: o.id,
          name: o.name,
          description: o.description,
          approved: o.approved,
          memberCount: o.memberCount + 1,
          trailCount: o.trailCount,
          openWorkCount: o.openWorkCount,
          website: o.website,
          kind: o.kind,
          region: o.region,
          acceptingVolunteers: o.acceptingVolunteers,
        );
      }
      _authController.add(updated);
      return updated;
    }

    await _db!.collection(FirestorePaths.organizationMembers).doc(
      '${organizationId}_${updated.id}',
    ).set({
      'organization_id': organizationId,
      'user_id': updated.id,
      'role': 'member',
      'joined_at': FieldValue.serverTimestamp(),
    });

    await _db.collection(FirestorePaths.profiles).doc(updated.id).set({
      'organization_ids': ids,
    }, SetOptions(merge: true));

    _authController.add(updated);
    return updated;
  }

  void emitCurrentUser() {
    _authController.add(currentUser);
  }

  Future<UserProfile> _ensureProfile(
    User user, {
    bool isAnonymous = false,
    bool hasCompletedOnboarding = true,
  }) async {
    final ref = _db!.collection(FirestorePaths.profiles).doc(user.uid);
    final snap = await ref.get();
    if (!snap.exists) {
      final profile = _profileFromFirebaseUser(
        user,
        isAnonymous: isAnonymous,
        hasCompletedOnboarding: hasCompletedOnboarding,
      );
      await ref.set({
        'display_name': profile.displayName,
        'email': profile.email,
        'avatar_url': profile.avatarUrl,
        'is_anonymous': isAnonymous,
        'has_completed_onboarding': hasCompletedOnboarding,
        'roles': ['volunteer'],
        'organization_ids': <String>[],
        'volunteer_hours': 0,
        'created_at': FieldValue.serverTimestamp(),
      });
      return profile;
    }

    final data = snap.data()!;
    return UserProfile(
      id: user.uid,
      displayName: data['display_name'] as String? ??
          user.displayName ??
          user.email?.split('@').first ??
          'Volunteer',
      email: data['email'] as String? ?? user.email,
      avatarUrl: data['avatar_url'] as String? ?? user.photoURL,
      isAnonymous: data['is_anonymous'] as bool? ?? user.isAnonymous,
      hasCompletedOnboarding:
          data['has_completed_onboarding'] as bool? ?? hasCompletedOnboarding,
      volunteerHours: (data['volunteer_hours'] as num?)?.toDouble() ?? 0,
      organizationIds:
          (data['organization_ids'] as List?)?.cast<String>() ?? const [],
      roles: ((data['roles'] as List?)?.cast<String>() ?? const ['volunteer'])
          .map(UserRole.fromString)
          .toList(),
    );
  }

  UserProfile _profileFromFirebaseUser(
    User user, {
    bool isAnonymous = false,
    bool hasCompletedOnboarding = true,
  }) {
    return UserProfile(
      id: user.uid,
      displayName: user.displayName ??
          user.email?.split('@').first ??
          (user.isAnonymous ? 'Guest' : 'Volunteer'),
      email: user.email,
      avatarUrl: user.photoURL,
      isAnonymous: isAnonymous || user.isAnonymous,
      hasCompletedOnboarding: hasCompletedOnboarding,
    );
  }

  void dispose() {
    _authController.close();
  }
}
