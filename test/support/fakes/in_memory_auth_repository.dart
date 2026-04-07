import 'dart:async';

import 'package:liga_gym_app/core/errors/app_exception.dart';
import 'package:liga_gym_app/features/auth/domain/entities/auth_status.dart';
import 'package:liga_gym_app/features/auth/domain/entities/auth_user.dart';
import 'package:liga_gym_app/features/auth/domain/entities/profile_setup_data.dart';
import 'package:liga_gym_app/features/auth/domain/repositories/auth_repository.dart';

class InMemoryAuthRepository implements AuthRepository {
  InMemoryAuthRepository({this.googleEmail = 'google@ligagym.dev'});

  final String googleEmail;
  final StreamController<AuthUser?> _authStateController =
      StreamController<AuthUser?>.broadcast();

  final Map<String, String> _passwordsByEmail = <String, String>{};
  final Map<String, String> _userIdsByEmail = <String, String>{};
  final Set<String> _profiledUserIds = <String>{};

  AuthUser? _currentUser;

  @override
  Stream<AuthUser?> watchAuthState() async* {
    yield _currentUser;
    yield* _authStateController.stream;
  }

  @override
  Future<AuthUser?> getCurrentUser() async {
    return _currentUser;
  }

  @override
  Future<AuthStatus> checkUserAuthState() async {
    return _resolveStatus(_currentUser);
  }

  @override
  Future<AuthStatus> loginWithEmail({
    required String email,
    required String password,
  }) async {
    if (!_userIdsByEmail.containsKey(email)) {
      throw const AuthException(AppErrorCode.userNotFound);
    }

    if (_passwordsByEmail[email] != password) {
      throw const AuthException(AppErrorCode.wrongPassword);
    }

    _currentUser = AuthUser(id: _userIdsByEmail[email]!, email: email);
    _authStateController.add(_currentUser);

    return _resolveStatus(_currentUser);
  }

  @override
  Future<AuthStatus> signInWithGoogle() async {
    final userId = _userIdsByEmail.putIfAbsent(
      googleEmail,
      () => 'google_user',
    );
    _currentUser = AuthUser(id: userId, email: googleEmail);
    _authStateController.add(_currentUser);

    return _resolveStatus(_currentUser);
  }

  @override
  Future<AuthStatus> registerUser({
    required String email,
    required String password,
  }) async {
    if (_userIdsByEmail.containsKey(email)) {
      throw const AuthException(AppErrorCode.emailAlreadyInUse);
    }

    final userId = 'user_${_userIdsByEmail.length + 1}';
    _userIdsByEmail[email] = userId;
    _passwordsByEmail[email] = password;
    _currentUser = AuthUser(id: userId, email: email);
    _authStateController.add(_currentUser);

    return AuthStatus.profileIncomplete;
  }

  @override
  Future<AuthStatus> saveUserProfile(ProfileSetupData profile) async {
    final currentUser = _currentUser;

    if (currentUser == null) {
      throw const AuthException(AppErrorCode.unauthorized);
    }

    _profiledUserIds.add(currentUser.id);

    return AuthStatus.authenticated;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _authStateController.add(null);
  }

  void seedUser({
    required String email,
    required String password,
    bool hasProfile = true,
  }) {
    final userId = _userIdsByEmail.putIfAbsent(
      email,
      () => 'user_${_userIdsByEmail.length + 1}',
    );
    _passwordsByEmail[email] = password;

    if (hasProfile) {
      _profiledUserIds.add(userId);
    }
  }

  Future<void> dispose() {
    return _authStateController.close();
  }

  Future<AuthStatus> _resolveStatus(AuthUser? user) async {
    if (user == null) {
      return AuthStatus.unauthenticated;
    }

    return _profiledUserIds.contains(user.id)
        ? AuthStatus.authenticated
        : AuthStatus.profileIncomplete;
  }
}
