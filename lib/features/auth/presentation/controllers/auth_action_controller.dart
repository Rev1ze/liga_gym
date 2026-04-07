import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/app_exception.dart';
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

      state = const AsyncData(null);
      return mapAuthStatusToRoute(authStatus);
    } on AppException catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<String> signInWithGoogle() async {
    state = const AsyncLoading();

    try {
      final authStatus = await ref.read(signInWithGoogleUseCaseProvider).call();

      state = const AsyncData(null);
      return mapAuthStatusToRoute(authStatus);
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

      state = const AsyncData(null);
      return mapAuthStatusToRoute(authStatus);
    } on AppException catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = const AsyncLoading();

    try {
      await ref.read(authRepositoryProvider).signOut();
      state = const AsyncData(null);
    } on AppException catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}
