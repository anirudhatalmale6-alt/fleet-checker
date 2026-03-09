import 'dart:async';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

class MockAuthService extends AuthService {
  AppUser? _currentUser;
  bool _initialized = false;
  final _uuid = const Uuid();

  // In-memory stores
  final Map<String, AppUser> _users = {};
  final Map<String, String> _passwords = {};
  final List<Map<String, dynamic>> _invites = [];

  final _driversController =
      StreamController<List<AppUser>>.broadcast();
  final _invitesController =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  MockAuthService() {
    // Seed demo data
    _seedData();
    Future.delayed(const Duration(milliseconds: 300), () {
      _initialized = true;
      notifyListeners();
    });
  }

  void _seedData() {
    // Demo owner
    final owner = AppUser(
      id: 'demo-owner-1',
      email: 'owner@demo.com',
      name: 'Gordon (Demo)',
      role: UserRole.owner,
    );
    _users[owner.id] = owner;
    _passwords['owner@demo.com'] = 'demo123';

    // Demo driver
    final driver = AppUser(
      id: 'demo-driver-1',
      email: 'driver@demo.com',
      name: 'James Wilson',
      role: UserRole.driver,
      ownerId: owner.id,
    );
    _users[driver.id] = driver;
    _passwords['driver@demo.com'] = 'demo123';
  }

  @override
  AppUser? get currentUser => _currentUser;
  @override
  bool get isLoggedIn => _currentUser != null;
  @override
  bool get initialized => _initialized;

  @override
  Future<String?> register({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? ownerId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (_passwords.containsKey(email.toLowerCase())) {
      return 'Email already registered';
    }

    // Check invites for driver auto-link
    if (role == UserRole.driver && ownerId == null) {
      final idx = _invites.indexWhere(
          (inv) => inv['email'] == email.toLowerCase());
      if (idx >= 0) {
        ownerId = _invites[idx]['ownerId'];
        _invites.removeAt(idx);
        _emitInvites(ownerId!);
      }
    }

    final user = AppUser(
      id: _uuid.v4(),
      email: email,
      name: name,
      role: role,
      ownerId: ownerId,
    );

    _users[user.id] = user;
    _passwords[email.toLowerCase()] = password;
    _currentUser = user;

    if (role == UserRole.driver && ownerId != null) {
      _emitDrivers(ownerId);
    }

    notifyListeners();
    return null;
  }

  @override
  Future<String?> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final storedPw = _passwords[email.toLowerCase()];
    if (storedPw == null || storedPw != password) {
      return 'Invalid email or password';
    }

    _currentUser = _users.values.firstWhere(
      (u) => u.email.toLowerCase() == email.toLowerCase(),
    );
    notifyListeners();
    return null;
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
    notifyListeners();
  }

  @override
  Future<String?> inviteDriver({
    required String email,
    required String name,
    required String ownerId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _invites.add({
      'id': _uuid.v4(),
      'email': email.toLowerCase(),
      'name': name,
      'ownerId': ownerId,
    });
    _emitInvites(ownerId);
    return null;
  }

  @override
  Stream<List<AppUser>> watchDriversForOwner(String ownerId) {
    // Emit current drivers immediately, then updates
    final initial = _users.values
        .where((u) => u.role == UserRole.driver && u.ownerId == ownerId)
        .toList();
    return _driversController.stream
        .where((_) => true) // all events
        .map((_) => _users.values
            .where(
                (u) => u.role == UserRole.driver && u.ownerId == ownerId)
            .toList())
        .transform(StreamTransformer.fromBind((stream) {
      return Stream.value(initial).asyncExpand((first) async* {
        yield first;
        yield* stream;
      });
    }));
  }

  @override
  Future<List<AppUser>> getDriversForOwner(String ownerId) async {
    return _users.values
        .where((u) => u.role == UserRole.driver && u.ownerId == ownerId)
        .toList();
  }

  @override
  Stream<List<Map<String, dynamic>>> watchInvitesForOwner(String ownerId) {
    final initial =
        _invites.where((inv) => inv['ownerId'] == ownerId).toList();
    return _invitesController.stream
        .map((_) =>
            _invites.where((inv) => inv['ownerId'] == ownerId).toList())
        .transform(StreamTransformer.fromBind((stream) {
      return Stream.value(initial).asyncExpand((first) async* {
        yield first;
        yield* stream;
      });
    }));
  }

  @override
  Future<AppUser?> getUserById(String id) async {
    return _users[id];
  }

  void _emitDrivers(String ownerId) {
    _driversController.add(_users.values
        .where((u) => u.role == UserRole.driver && u.ownerId == ownerId)
        .toList());
  }

  void _emitInvites(String ownerId) {
    _invitesController.add(
        _invites.where((inv) => inv['ownerId'] == ownerId).toList());
  }

  @override
  void dispose() {
    _driversController.close();
    _invitesController.close();
    super.dispose();
  }
}
