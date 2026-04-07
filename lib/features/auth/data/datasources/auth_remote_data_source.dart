import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/errors/app_exception.dart';
import '../models/auth_user_model.dart';

abstract interface class AuthRemoteDataSource {
  Stream<AuthUserModel?> watchAuthState();

  Future<AuthUserModel?> getCurrentUser();

  Future<AuthUserModel> loginWithEmail({
    required String email,
    required String password,
  });

  Future<AuthUserModel> registerUser({
    required String email,
    required String password,
  });

  Future<AuthUserModel> signInWithGoogle();

  Future<void> signOut();
}

class FirebaseAuthRemoteDataSource implements AuthRemoteDataSource {
  FirebaseAuthRemoteDataSource({
    required FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
  }) : _firebaseAuth = firebaseAuth,
       _googleSignIn = googleSignIn;

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  Future<void>? _googleInitializationFuture;

  @override
  Stream<AuthUserModel?> watchAuthState() {
    return _firebaseAuth.authStateChanges().map(
      AuthUserModel.fromFirebaseUserOrNull,
    );
  }

  @override
  Future<AuthUserModel?> getCurrentUser() async {
    return AuthUserModel.fromFirebaseUserOrNull(_firebaseAuth.currentUser);
  }

  @override
  Future<AuthUserModel> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;

      if (user == null) {
        throw const AuthException(AppErrorCode.unknown);
      }

      return AuthUserModel.fromFirebaseUser(user);
    } on FirebaseAuthException catch (error) {
      // Преобразуем технические коды Firebase в доменные ошибки, понятные UI.
      throw AuthException(_mapFirebaseAuthError(error.code));
    } on FirebaseException catch (error) {
      throw AuthException(_mapFirebaseCoreError(error.code));
    }
  }

  @override
  Future<AuthUserModel> registerUser({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;

      if (user == null) {
        throw const AuthException(AppErrorCode.unknown);
      }

      return AuthUserModel.fromFirebaseUser(user);
    } on FirebaseAuthException catch (error) {
      throw AuthException(_mapFirebaseAuthError(error.code));
    } on FirebaseException catch (error) {
      throw AuthException(_mapFirebaseCoreError(error.code));
    }
  }

  @override
  Future<AuthUserModel> signInWithGoogle() async {
    try {
      await _ensureGoogleInitialized();

      if (!_googleSignIn.supportsAuthenticate()) {
        throw const AuthException(AppErrorCode.googleSignInNotSupported);
      }

      final googleAccount = await _googleSignIn.authenticate();
      final idToken = googleAccount.authentication.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw const AuthException(AppErrorCode.googleSignInFailed);
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );
      final user = userCredential.user;

      if (user == null) {
        throw const AuthException(AppErrorCode.unknown);
      }

      return AuthUserModel.fromFirebaseUser(user);
    } on GoogleSignInException catch (error) {
      // Отдельно обрабатываем ошибки Google Sign-In, чтобы показать точное сообщение пользователю.
      throw AuthException(_mapGoogleSignInError(error.code));
    } on FirebaseAuthException catch (error) {
      throw AuthException(_mapFirebaseAuthError(error.code));
    } on FirebaseException catch (error) {
      throw AuthException(_mapFirebaseCoreError(error.code));
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await Future.wait<void>([
        _firebaseAuth.signOut(),
        _signOutGoogleSafely(),
      ]);
    } on FirebaseAuthException catch (error) {
      throw AuthException(_mapFirebaseAuthError(error.code));
    } on FirebaseException catch (error) {
      throw AuthException(_mapFirebaseCoreError(error.code));
    }
  }

  Future<void> _ensureGoogleInitialized() {
    return _googleInitializationFuture ??= _googleSignIn.initialize();
  }

  Future<void> _signOutGoogleSafely() async {
    try {
      await _ensureGoogleInitialized();
      await _googleSignIn.signOut();
    } catch (_) {
      // Игнорируем ошибку выхода из Google, потому что основное состояние хранит Firebase.
    }
  }

  AppErrorCode _mapFirebaseAuthError(String code) {
    return switch (code) {
      'user-not-found' => AppErrorCode.userNotFound,
      'wrong-password' => AppErrorCode.wrongPassword,
      'invalid-credential' => AppErrorCode.invalidCredential,
      'email-already-in-use' => AppErrorCode.emailAlreadyInUse,
      'network-request-failed' => AppErrorCode.networkRequestFailed,
      'too-many-requests' => AppErrorCode.tooManyRequests,
      _ => AppErrorCode.unknown,
    };
  }

  AppErrorCode _mapFirebaseCoreError(String code) {
    return switch (code) {
      'core/no-app' => AppErrorCode.firebaseConfigurationMissing,
      _ => AppErrorCode.unknown,
    };
  }

  AppErrorCode _mapGoogleSignInError(GoogleSignInExceptionCode code) {
    return switch (code) {
      GoogleSignInExceptionCode.canceled => AppErrorCode.googleSignInCancelled,
      GoogleSignInExceptionCode.clientConfigurationError =>
        AppErrorCode.googleSignInConfigurationError,
      GoogleSignInExceptionCode.providerConfigurationError =>
        AppErrorCode.googleSignInConfigurationError,
      GoogleSignInExceptionCode.uiUnavailable =>
        AppErrorCode.googleSignInNotSupported,
      _ => AppErrorCode.googleSignInFailed,
    };
  }
}
