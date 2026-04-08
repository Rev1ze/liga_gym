import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/firebase/firebase_bootstrap.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/datasources/profile_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/check_user_auth_state_use_case.dart';
import '../../domain/usecases/login_with_email_use_case.dart';
import '../../domain/usecases/register_user_use_case.dart';
import '../../domain/usecases/save_user_profile_use_case.dart';
import '../../domain/usecases/sign_in_with_google_use_case.dart';

part 'auth_providers.g.dart';

@Riverpod(keepAlive: true)
FirebaseAuth firebaseAuth(Ref ref) {
  return FirebaseAuth.instance;
}

@Riverpod(keepAlive: true)
FirebaseFirestore firebaseFirestore(Ref ref) {
  return FirebaseFirestore.instance;
}

@Riverpod(keepAlive: true)
GoogleSignIn googleSignIn(Ref ref) {
  return GoogleSignIn.instance;
}

@Riverpod(keepAlive: true)
AuthRemoteDataSource authRemoteDataSource(Ref ref) {
  final firebaseBootstrap = ref.watch(firebaseBootstrapProvider);

  if (!firebaseBootstrap.isConfigured) {
    return const UnavailableAuthRemoteDataSource();
  }

  return FirebaseAuthRemoteDataSource(
    firebaseAuth: ref.watch(firebaseAuthProvider),
    googleSignIn: ref.watch(googleSignInProvider),
  );
}

@Riverpod(keepAlive: true)
ProfileRemoteDataSource profileRemoteDataSource(Ref ref) {
  final firebaseBootstrap = ref.watch(firebaseBootstrapProvider);

  if (!firebaseBootstrap.isConfigured) {
    return const UnavailableProfileRemoteDataSource();
  }

  return FirestoreProfileRemoteDataSource(
    firestore: ref.watch(firebaseFirestoreProvider),
  );
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return AuthRepositoryImpl(
    authRemoteDataSource: ref.watch(authRemoteDataSourceProvider),
    profileRemoteDataSource: ref.watch(profileRemoteDataSourceProvider),
  );
}

@Riverpod(keepAlive: true)
CheckUserAuthStateUseCase checkUserAuthStateUseCase(Ref ref) {
  return CheckUserAuthStateUseCase(ref.watch(authRepositoryProvider));
}

@Riverpod(keepAlive: true)
LoginWithEmailUseCase loginWithEmailUseCase(Ref ref) {
  return LoginWithEmailUseCase(ref.watch(authRepositoryProvider));
}

@Riverpod(keepAlive: true)
RegisterUserUseCase registerUserUseCase(Ref ref) {
  return RegisterUserUseCase(ref.watch(authRepositoryProvider));
}

@Riverpod(keepAlive: true)
SignInWithGoogleUseCase signInWithGoogleUseCase(Ref ref) {
  return SignInWithGoogleUseCase(ref.watch(authRepositoryProvider));
}

@Riverpod(keepAlive: true)
SaveUserProfileUseCase saveUserProfileUseCase(Ref ref) {
  return SaveUserProfileUseCase(ref.watch(authRepositoryProvider));
}

@riverpod
Stream<AuthUser?> authStateChanges(Ref ref) {
  return ref.watch(authRepositoryProvider).watchAuthState();
}

@riverpod
Future<AuthUser?> currentAuthUser(Ref ref) {
  return ref.watch(authRepositoryProvider).getCurrentUser();
}
