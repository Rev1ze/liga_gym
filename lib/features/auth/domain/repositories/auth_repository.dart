import '../entities/auth_status.dart';
import '../entities/auth_user.dart';
import '../entities/profile_setup_data.dart';

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

  Future<void> signOut();
}
