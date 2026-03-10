import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

class FirebaseAuthService extends AuthService {
  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  AppUser? _currentUser;
  bool _initialized = false;

  FirebaseAuthService({fb.FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? fb.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  @override
  AppUser? get currentUser => _currentUser;
  @override
  bool get isLoggedIn => _currentUser != null;
  @override
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

  @override
  Future<String?> register({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? ownerId,
    String? companyName,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (role == UserRole.driver && ownerId == null) {
        final invites = await _firestore
            .collection('invites')
            .where('email', isEqualTo: email.toLowerCase())
            .limit(1)
            .get();
        if (invites.docs.isNotEmpty) {
          ownerId = invites.docs.first.data()['ownerId'];
          await invites.docs.first.reference.delete();
        }
      }

      final user = AppUser(
        id: cred.user!.uid,
        email: email,
        name: name,
        role: role,
        ownerId: ownerId,
        companyName: role == UserRole.owner ? companyName : null,
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

  @override
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

  @override
  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  @override
  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (_currentUser == null) return;
    await _firestore.collection('users').doc(_currentUser!.id).update(data);
    await _loadUserProfile(_currentUser!.id);
    notifyListeners();
  }

  @override
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

  @override
  Future<String?> addDriver({
    required String name,
    required String email,
    required String password,
    required String ownerId,
  }) async {
    try {
      // Use a secondary Firebase App so the owner stays logged in
      FirebaseApp? secondaryApp;
      try {
        secondaryApp = Firebase.app('driverCreator');
      } catch (_) {
        secondaryApp = await Firebase.initializeApp(
          name: 'driverCreator',
          options: Firebase.app().options,
        );
      }

      final secondaryAuth = fb.FirebaseAuth.instanceFor(app: secondaryApp);
      final cred = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final driver = AppUser(
        id: cred.user!.uid,
        email: email,
        name: name,
        role: UserRole.driver,
        ownerId: ownerId,
      );

      await _firestore.collection('users').doc(driver.id).set(driver.toMap());
      await secondaryAuth.signOut();
      return null;
    } on fb.FirebaseAuthException catch (e) {
      return e.message ?? 'Failed to add driver';
    } catch (e) {
      return e.toString();
    }
  }

  @override
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

  @override
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

  @override
  Stream<List<Map<String, dynamic>>> watchInvitesForOwner(String ownerId) {
    return _firestore
        .collection('invites')
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }

  @override
  Future<AppUser?> getUserById(String id) async {
    final doc = await _firestore.collection('users').doc(id).get();
    if (doc.exists) {
      return AppUser.fromMap({...doc.data()!, 'id': doc.id});
    }
    return null;
  }
}
