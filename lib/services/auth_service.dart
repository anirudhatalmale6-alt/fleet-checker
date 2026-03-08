import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  AppUser? _currentUser;
  bool _initialized = false;

  AuthService({fb.FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? fb.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get initialized => _initialized;

  Future<void> _onAuthStateChanged(fb.User? firebaseUser) async {
    if (firebaseUser == null) {
      _currentUser = null;
    } else {
      await _loadUserProfile(firebaseUser.uid);
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> _loadUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      _currentUser = AppUser.fromMap({...doc.data()!, 'id': uid});
    }
  }

  Future<String?> register({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? ownerId,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check if this driver was invited by an owner
      if (role == UserRole.driver && ownerId == null) {
        final invites = await _firestore
            .collection('invites')
            .where('email', isEqualTo: email.toLowerCase())
            .limit(1)
            .get();
        if (invites.docs.isNotEmpty) {
          ownerId = invites.docs.first.data()['ownerId'];
          // Delete the invite
          await invites.docs.first.reference.delete();
        }
      }

      final user = AppUser(
        id: cred.user!.uid,
        email: email,
        name: name,
        role: role,
        ownerId: ownerId,
      );

      await _firestore.collection('users').doc(user.id).set(user.toMap());
      _currentUser = user;
      notifyListeners();
      return null;
    } on fb.FirebaseAuthException catch (e) {
      return e.message ?? 'Registration failed';
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on fb.FirebaseAuthException catch (e) {
      return e.message ?? 'Login failed';
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  /// Owner invites a driver by email. Driver can then self-register.
  Future<String?> inviteDriver({
    required String email,
    required String name,
    required String ownerId,
  }) async {
    try {
      await _firestore.collection('invites').add({
        'email': email.toLowerCase(),
        'name': name,
        'ownerId': ownerId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Stream<List<AppUser>> watchDriversForOwner(String ownerId) {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'driver')
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AppUser.fromMap({...d.data(), 'id': d.id}))
            .toList());
  }

  Future<List<AppUser>> getDriversForOwner(String ownerId) async {
    final snap = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'driver')
        .where('ownerId', isEqualTo: ownerId)
        .get();
    return snap.docs
        .map((d) => AppUser.fromMap({...d.data(), 'id': d.id}))
        .toList();
  }

  Stream<List<Map<String, dynamic>>> watchInvitesForOwner(String ownerId) {
    return _firestore
        .collection('invites')
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }

  Future<AppUser?> getUserById(String id) async {
    final doc = await _firestore.collection('users').doc(id).get();
    if (doc.exists) {
      return AppUser.fromMap({...doc.data()!, 'id': doc.id});
    }
    return null;
  }
}
