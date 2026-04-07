import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/utils/localization_extensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../controllers/splash_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUserAuthState();
    });
  }

  Future<void> _checkUserAuthState() async {
    try {
      final route = await ref
          .read(splashControllerProvider.notifier)
          .checkUserAuthState();

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacementNamed(route);
    } on AppException catch (error) {
      if (!mounted) {
        return;
      }

      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.code.localize(l10n))));
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final splashState = ref.watch(splashControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset(
                  'assets/lottie/liga_gym_logo.json',
                  key: AppKeys.splashLogo,
                  width: 180,
                  height: 180,
                  repeat: true,
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.splashTitle,
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  splashState.hasError
                      ? l10n.splashErrorMessage
                      : l10n.splashSubtitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (splashState.isLoading) const CircularProgressIndicator(),
                if (splashState.hasError) ...[
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _checkUserAuthState,
                    child: Text(l10n.commonRetry),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
