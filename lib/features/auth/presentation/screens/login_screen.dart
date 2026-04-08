import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/firebase/firebase_bootstrap.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/utils/input_validators.dart';
import '../../../../core/utils/localization_extensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../controllers/auth_action_controller.dart';
import '../widgets/auth_page_scaffold.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailLogin() async {
    final l10n = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final route = await ref
          .read(authActionControllerProvider.notifier)
          .loginWithEmail(
            email: _emailController.text,
            password: _passwordController.text,
          );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacementNamed(route);
    } on AppException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.code.localize(l10n))));
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final l10n = AppLocalizations.of(context)!;

    try {
      final route = await ref
          .read(authActionControllerProvider.notifier)
          .signInWithGoogle();

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacementNamed(route);
    } on AppException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.code.localize(l10n))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLoading = ref.watch(authActionControllerProvider).isLoading;
    final firebaseBootstrap = ref.watch(firebaseBootstrapProvider);
    final isFirebaseConfigured = firebaseBootstrap.isConfigured;
    final isAuthEnabled = isFirebaseConfigured && !isLoading;
    final isGoogleSignInEnabled =
        firebaseBootstrap.supportsGoogleSignIn && !isLoading;

    return AuthPageScaffold(
      title: l10n.loginTitle,
      subtitle: l10n.loginSubtitle,
      isLoading: isLoading,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: AppKeys.loginEmailField,
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: InputDecoration(labelText: l10n.commonEmail),
              validator: (value) {
                final errorCode = InputValidators.validateEmail(value);
                return errorCode?.localize(l10n);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: AppKeys.loginPasswordField,
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              onFieldSubmitted: (_) => _handleEmailLogin(),
              decoration: InputDecoration(
                labelText: l10n.commonPassword,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                ),
              ),
              validator: (value) {
                final errorCode = InputValidators.validatePassword(value);
                return errorCode?.localize(l10n);
              },
            ),
            const SizedBox(height: 24),
            if (firebaseBootstrap.usesEmulator) ...[
              Text(
                'Локальный Firebase включён. Перед входом запусти '
                '`firebase emulators:start --project demo-liga-gym`.',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ] else if (!isFirebaseConfigured) ...[
              Text(
                l10n.errorFirebaseConfigurationMissing,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
            FilledButton(
              key: AppKeys.loginButton,
              onPressed: isAuthEnabled ? _handleEmailLogin : null,
              child: Text(l10n.loginButton),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: AppKeys.googleSignInButton,
              onPressed: isGoogleSignInEnabled ? _handleGoogleSignIn : null,
              icon: const Icon(Icons.login),
              label: Text(l10n.googleSignInButton),
            ),
            const SizedBox(height: 12),
            TextButton(
              key: AppKeys.goToRegisterButton,
              onPressed: isLoading
                  ? null
                  : () => Navigator.of(context).pushNamed(AppRoutes.register),
              child: Text(l10n.goToRegisterButton),
            ),
          ],
        ),
      ),
    );
  }
}
