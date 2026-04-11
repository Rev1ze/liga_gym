import '../entities/auth_status.dart';
import '../entities/auth_user.dart';
import '../entities/profile_setup_data.dart';
import '../entities/user_profile.dart';
import '../entities/user_profile_update_data.dart';
import '../entities/weight_history_entry.dart';

abstract interface class AuthRepository {
  Stream<AuthUser?> watchAuthState();

  Future<AuthUser?> getCurrentUser();

  Future<AuthStatus> checkUserAuthState();

  Future<AuthStatus> loginWithEmail({
    required String email,
    required String password,
  });

  Future<AuthStatus> signInWithGoogle();

  Future<AuthStatus> registerUser({
    required String email,
    required String password,
  });

  Future<AuthStatus> saveUserProfile(ProfileSetupData profile);

  Future<UserProfile> getUserProfile(String userId);

  Future<void> updateUserProfile(UserProfileUpdateData profile);

  Future<List<WeightHistoryEntry>> loadWeightHistory({
    required String userId,
    required DateTime from,
    required DateTime to,
  });

  Future<void> signOut();
}
