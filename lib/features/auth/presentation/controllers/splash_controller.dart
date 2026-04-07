import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/navigation/app_routes.dart';
import '../providers/auth_providers.dart';
import '../utils/auth_status_route_mapper.dart';

part 'splash_controller.g.dart';

@riverpod
class SplashController extends _$SplashController {
  @override
  FutureOr<String> build() => AppRoutes.splash;

  Future<String> checkUserAuthState() async {
    state = const AsyncLoading();

    try {
      final authStatus = await ref
          .read(checkUserAuthStateUseCaseProvider)
          .call();
      final route = mapAuthStatusToRoute(authStatus);
      state = AsyncData(route);

      return route;
    } on AppException catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}
