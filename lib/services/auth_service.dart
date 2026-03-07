import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  AppUser? _currentUser;
  final Map<String, AppUser> _users = {};
  final Map<String, String> _passwords = {};

  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  Future<String?> register({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? ownerId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (_users.values.any((u) => u.email == email)) {
      return 'Email already registered';
    }

    final user = AppUser(
      id: const Uuid().v4(),
      email: email,
      name: name,
      role: role,
      ownerId: ownerId,
    );

    _users[user.id] = user;
    _passwords[email] = password;
    _currentUser = user;
    notifyListeners();
    return null;
  }

  Future<String?> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (_passwords[email] != password) {
      return 'Invalid email or password';
    }

    _currentUser = _users.values.firstWhere((u) => u.email == email);
    notifyListeners();
    return null;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  List<AppUser> getDriversForOwner(String ownerId) {
    return _users.values
        .where((u) => u.role == UserRole.driver && u.ownerId == ownerId)
        .toList();
  }

  AppUser? getUserById(String id) => _users[id];
}
