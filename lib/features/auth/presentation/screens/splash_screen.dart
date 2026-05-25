import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/utils/localization_extensions.dart';
import '../../../../core/widgets/animated_theme_background.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/themed_liga_logo.dart';
import '../../../../l10n/app_localizations.dart';
import '../controllers/splash_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _introController;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUserAuthState();
    });
  }

  @override
  void dispose() {
    _introController.dispose();
    super.dispose();
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

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: AnimatedThemeBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: _introController,
                  curve: Curves.easeOutCubic,
                ),
                child: SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: const Offset(0, 0.06),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: _introController,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: colorScheme.surface.withValues(alpha: 0.82),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withValues(
                                alpha: 0.22,
                              ),
                              blurRadius: 20,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: ThemedLigaLogo(
                            key: AppKeys.splashLogo,
                            width: 180,
                            height: 180,
                            repeat: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.splashTitle,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        child: Text(
                          splashState.hasError
                              ? l10n.splashErrorMessage
                              : l10n.splashSubtitle,
                          key: ValueKey<bool>(splashState.hasError),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        child: splashState.isLoading
                            ? const AppLoadingIndicator()
                            : splashState.hasError
                            ? FilledButton.icon(
                                onPressed: _checkUserAuthState,
                                icon: const Icon(Icons.refresh_rounded),
                                label: Text(l10n.commonRetry),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
