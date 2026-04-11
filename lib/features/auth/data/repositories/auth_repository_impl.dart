import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/auth_status.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/entities/profile_setup_data.dart';
import '../../domain/entities/user_goal.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/user_profile_update_data.dart';
import '../../domain/entities/weight_history_entry.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../datasources/profile_remote_data_source.dart';
import '../models/user_profile_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required AuthRemoteDataSource authRemoteDataSource,
    required ProfileRemoteDataSource profileRemoteDataSource,
  }) : _authRemoteDataSource = authRemoteDataSource,
       _profileRemoteDataSource = profileRemoteDataSource;

  final AuthRemoteDataSource _authRemoteDataSource;
  final ProfileRemoteDataSource _profileRemoteDataSource;

  @override
  Stream<AuthUser?> watchAuthState() {
    return _authRemoteDataSource.watchAuthState();
  }

  @override
  Future<AuthUser?> getCurrentUser() {
    return _authRemoteDataSource.getCurrentUser();
  }

  @override
  Future<AuthStatus> checkUserAuthState() async {
    final currentUser = await _authRemoteDataSource.getCurrentUser();

    return _resolveAuthStatus(currentUser);
  }

  @override
  Future<AuthStatus> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final authenticatedUser = await _authRemoteDataSource.loginWithEmail(
      email: email,
      password: password,
    );

    return _resolveAuthStatus(authenticatedUser);
  }

  @override
  Future<AuthStatus> signInWithGoogle() async {
    final authenticatedUser = await _authRemoteDataSource.signInWithGoogle();

    return _resolveAuthStatus(authenticatedUser);
  }

  @override
  Future<AuthStatus> registerUser({
    required String email,
    required String password,
  }) async {
    await _authRemoteDataSource.registerUser(email: email, password: password);

    // После регистрации всегда отправляем пользователя на заполнение профиля.
    return AuthStatus.profileIncomplete;
  }

  @override
  Future<AuthStatus> saveUserProfile(ProfileSetupData profile) async {
    final currentUser = await _authRemoteDataSource.getCurrentUser();

    if (currentUser == null) {
      throw const AuthException(AppErrorCode.unauthorized);
    }

    await _profileRemoteDataSource.saveUserProfile(
      UserProfileModel(
        userId: currentUser.id,
        email: currentUser.email,
        name: profile.name,
        gender: profile.gender,
        birthDate: profile.birthDate,
        city: null,
        goalType: UserGoalType.maintainWeight,
      ),
    );

    return AuthStatus.authenticated;
  }

  @override
  Future<UserProfile> getUserProfile(String userId) async {
    final profile = await _profileRemoteDataSource.getUserProfile(userId);
    if (profile == null) {
      throw const ProfileException(AppErrorCode.profileSaveFailed);
    }

    return profile;
  }

  @override
  Future<void> updateUserProfile(UserProfileUpdateData profile) async {
    final currentUser = await _authRemoteDataSource.getCurrentUser();
    final resolvedUserId = currentUser?.id ?? profile.userId;
    final resolvedEmail = currentUser?.email ?? profile.email;

    if (resolvedUserId.isEmpty || resolvedEmail.isEmpty) {
      throw const AuthException(AppErrorCode.unauthorized);
    }

    final existingProfile = await _profileRemoteDataSource.getUserProfile(
      resolvedUserId,
    );
    final startWeightKg = switch (profile.goalType) {
      UserGoalType.maintainWeight => null,
      _ => profile.startWeightKg ?? existingProfile?.startWeightKg,
    };
    final targetWeightKg = profile.goalType == UserGoalType.maintainWeight
        ? null
        : profile.targetWeightKg;

    await _profileRemoteDataSource.saveUserProfile(
      UserProfileModel(
        userId: resolvedUserId,
        email: resolvedEmail,
        name: profile.name,
        gender: profile.gender,
        birthDate: profile.birthDate,
        city: profile.city,
        heightCm: profile.heightCm,
        startWeightKg: startWeightKg,
        currentWeightKg: profile.currentWeightKg,
        targetWeightKg: targetWeightKg,
        goalType: profile.goalType,
        dailyStepGoal: profile.dailyStepGoal,
        dailyCalorieGoal: profile.dailyCalorieGoal,
      ),
    );
  }

  @override
  Future<List<WeightHistoryEntry>> loadWeightHistory({
    required String userId,
    required DateTime from,
    required DateTime to,
  }) {
    return _profileRemoteDataSource.loadWeightHistory(
      userId: userId,
      from: from,
      to: to,
    );
  }

  @override
  Future<void> signOut() {
    return _authRemoteDataSource.signOut();
  }

  Future<AuthStatus> _resolveAuthStatus(AuthUser? user) async {
    if (user == null) {
      return AuthStatus.unauthenticated;
    }

    final hasProfile = await _profileRemoteDataSource.hasUserProfile(user.id);

    return hasProfile ? AuthStatus.authenticated : AuthStatus.profileIncomplete;
  }
}
