import 'dart:async';

import 'package:liga_gym_app/core/errors/app_exception.dart';
import 'package:liga_gym_app/features/auth/domain/entities/auth_status.dart';
import 'package:liga_gym_app/features/auth/domain/entities/auth_user.dart';
import 'package:liga_gym_app/features/auth/domain/entities/gender.dart';
import 'package:liga_gym_app/features/auth/domain/entities/profile_setup_data.dart';
import 'package:liga_gym_app/features/auth/domain/entities/user_goal.dart';
import 'package:liga_gym_app/features/auth/domain/entities/user_profile.dart';
import 'package:liga_gym_app/features/auth/domain/entities/user_profile_update_data.dart';
import 'package:liga_gym_app/features/auth/domain/entities/weight_history_entry.dart';
import 'package:liga_gym_app/features/auth/domain/repositories/auth_repository.dart';

class InMemoryAuthRepository implements AuthRepository {
  InMemoryAuthRepository({this.googleEmail = 'google@ligagym.dev'});

  final String googleEmail;
  final StreamController<AuthUser?> _authStateController =
      StreamController<AuthUser?>.broadcast();

  final Map<String, String> _passwordsByEmail = <String, String>{};
  final Map<String, String> _userIdsByEmail = <String, String>{};
  final Set<String> _profiledUserIds = <String>{};
  final Map<String, UserProfile> _profilesByUserId = <String, UserProfile>{};
  final Map<String, List<WeightHistoryEntry>> _weightHistoryByUserId =
      <String, List<WeightHistoryEntry>>{};

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
    _profilesByUserId[currentUser.id] = UserProfile(
      userId: currentUser.id,
      email: currentUser.email,
      name: profile.name,
      gender: profile.gender,
      birthDate: profile.birthDate,
      goalType: UserGoalType.maintainWeight,
      dailyStepGoal: 10000,
      dailyCalorieGoal: 2200,
    );

    return AuthStatus.authenticated;
  }

  @override
  Future<UserProfile> getUserProfile(String userId) async {
    final profile = _profilesByUserId[userId];
    if (profile == null) {
      throw const ProfileException(AppErrorCode.profileSaveFailed);
    }

    return profile;
  }

  @override
  Future<void> updateUserProfile(UserProfileUpdateData profile) async {
    final currentUser = _currentUser;
    if (currentUser == null) {
      throw const AuthException(AppErrorCode.unauthorized);
    }

    final existingProfile =
        _profilesByUserId[currentUser.id] ??
        UserProfile(
          userId: currentUser.id,
          email: currentUser.email,
          name: profile.name,
          gender: profile.gender,
          birthDate: profile.birthDate,
        );
    final startWeight =
        existingProfile.startWeightKg ?? profile.currentWeightKg;
    _profilesByUserId[currentUser.id] = UserProfile(
      userId: currentUser.id,
      email: currentUser.email,
      name: profile.name,
      gender: profile.gender,
      birthDate: profile.birthDate,
      heightCm: profile.heightCm,
      startWeightKg: startWeight,
      currentWeightKg: profile.currentWeightKg,
      targetWeightKg: profile.targetWeightKg,
      goalType: profile.goalType,
      dailyStepGoal: profile.dailyStepGoal,
      dailyCalorieGoal: profile.dailyCalorieGoal,
    );

    if (profile.currentWeightKg != null) {
      final history = _weightHistoryByUserId.putIfAbsent(
        currentUser.id,
        () => <WeightHistoryEntry>[],
      );
      history.add(
        WeightHistoryEntry(
          userId: currentUser.id,
          recordedAt: DateTime.now(),
          weightKg: profile.currentWeightKg!,
        ),
      );
    }
  }

  @override
  Future<List<WeightHistoryEntry>> loadWeightHistory({
    required String userId,
    required DateTime from,
    required DateTime to,
  }) async {
    final history =
        _weightHistoryByUserId[userId] ?? const <WeightHistoryEntry>[];
    return history
        .where(
          (entry) =>
              !entry.recordedAt.isBefore(from) && !entry.recordedAt.isAfter(to),
        )
        .toList(growable: false);
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
      _profilesByUserId[userId] = UserProfile(
        userId: userId,
        email: email,
        name: 'User',
        gender: Gender.male,
        birthDate: DateTime(2000, 1, 1),
        goalType: UserGoalType.maintainWeight,
        dailyStepGoal: 10000,
        dailyCalorieGoal: 2200,
      );
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
