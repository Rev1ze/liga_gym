import '../../../../core/navigation/app_routes.dart';
import '../../domain/entities/auth_status.dart';

String mapAuthStatusToRoute(AuthStatus status) {
  return switch (status) {
    AuthStatus.unauthenticated => AppRoutes.login,
    AuthStatus.profileIncomplete => AppRoutes.profileSetup,
    AuthStatus.authenticated => AppRoutes.dashboard,
  };
}
