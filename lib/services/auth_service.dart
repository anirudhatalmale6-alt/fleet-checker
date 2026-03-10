import 'package:flutter/material.dart';
import '../models/user_model.dart';

/// Abstract auth service – screens depend on this type.
/// Concrete implementations: FirebaseAuthService, MockAuthService.
abstract class AuthService extends ChangeNotifier {
  AppUser? get currentUser;
  bool get isLoggedIn;
  bool get initialized;

  Future<String?> register({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? ownerId,
  });

  Future<String?> login(String email, String password);
  Future<void> logout();

  Future<String?> inviteDriver({
    required String email,
    required String name,
    required String ownerId,
  });

  /// Owner creates a driver account directly (no email invite needed)
  Future<String?> addDriver({
    required String name,
    required String email,
    required String password,
    required String ownerId,
  });

  Stream<List<AppUser>> watchDriversForOwner(String ownerId);
  Future<List<AppUser>> getDriversForOwner(String ownerId);
  Stream<List<Map<String, dynamic>>> watchInvitesForOwner(String ownerId);
  Future<AppUser?> getUserById(String id);
}
