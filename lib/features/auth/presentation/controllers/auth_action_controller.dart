import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../domain/entities/auth_status.dart';
import '../../domain/entities/gender.dart';
import '../providers/auth_providers.dart';
import '../utils/auth_status_route_mapper.dart';

part 'auth_action_controller.g.dart';

@riverpod
class AuthActionController extends _$AuthActionController {
  @override
  FutureOr<void> build() {}

  Future<String> loginWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();

    try {
      final authStatus = await ref
          .read(loginWithEmailUseCaseProvider)
          .call(email: email, password: password);

      _invalidateAuthUserState();
      state = const AsyncData(null);
      return _mapAuthStatusToRoleAwareRoute(authStatus);
    } on AppException catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<String> signInWithGoogle() async {
    state = const AsyncLoading();

    try {
      final authStatus = await ref.read(signInWithGoogleUseCaseProvider).call();

      _invalidateAuthUserState();
      state = const AsyncData(null);
      return _mapAuthStatusToRoleAwareRoute(authStatus);
    } on AppException catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<String> registerUser({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();

    try {
      final authStatus = await ref
          .read(registerUserUseCaseProvider)
          .call(email: email, password: password);

      _invalidateAuthUserState();
      state = const AsyncData(null);
      return mapAuthStatusToRoute(authStatus);
    } on AppException catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<String> saveUserProfile({
    required String name,
    required Gender? gender,
    required DateTime? birthDate,
  }) async {
    state = const AsyncLoading();

    try {
      final authStatus = await ref
          .read(saveUserProfileUseCaseProvider)
          .call(name: name, gender: gender, birthDate: birthDate);

      _invalidateAuthUserState();
      state = const AsyncData(null);
      return _mapAuthStatusToRoleAwareRoute(authStatus);
    } on AppException catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = const AsyncLoading();

    try {
      await ref.read(authRepositoryProvider).signOut();
      _invalidateAuthUserState();
      state = const AsyncData(null);
    } on AppException catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<String> _mapAuthStatusToRoleAwareRoute(AuthStatus authStatus) async {
    final route = mapAuthStatusToRoute(authStatus);
    if (route != AppRoutes.dashboard) {
      return route;
    }

    final currentUser = await ref.read(authRepositoryProvider).getCurrentUser();
    if (currentUser == null) {
      return route;
    }

    final profile = await ref
        .read(loadUserProfileUseCaseProvider)
        .call(currentUser.id);
    return profile.isTrainer ? AppRoutes.coachDashboard : route;
  }

  void _invalidateAuthUserState() {
    ref.invalidate(currentFirebaseUserProvider);
    ref.invalidate(currentAuthUserProvider);
    ref.invalidate(currentUserProfileProvider);
    ref.invalidate(authStateChangesProvider);
  }
}
