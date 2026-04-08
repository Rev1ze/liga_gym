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

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final l10n = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final route = await ref
          .read(authActionControllerProvider.notifier)
          .registerUser(
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLoading = ref.watch(authActionControllerProvider).isLoading;
    final firebaseBootstrap = ref.watch(firebaseBootstrapProvider);
    final isFirebaseConfigured = firebaseBootstrap.isConfigured;
    final isRegistrationEnabled = isFirebaseConfigured && !isLoading;

    return AuthPageScaffold(
      title: l10n.registerTitle,
      subtitle: l10n.registerSubtitle,
      isLoading: isLoading,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: AppKeys.registerEmailField,
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: InputDecoration(labelText: l10n.commonEmail),
              validator: (value) {
                final errorCode = InputValidators.validateEmail(value);
                return errorCode?.localize(l10n);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: AppKeys.registerPasswordField,
              controller: _passwordController,
              obscureText: _obscurePassword,
              autovalidateMode: AutovalidateMode.onUserInteraction,
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
            const SizedBox(height: 16),
            TextFormField(
              key: AppKeys.registerConfirmPasswordField,
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              onFieldSubmitted: (_) => _handleRegister(),
              decoration: InputDecoration(
                labelText: l10n.commonConfirmPassword,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                ),
              ),
              validator: (value) {
                final errorCode = InputValidators.validateConfirmPassword(
                  password: _passwordController.text,
                  confirmPassword: value,
                );
                return errorCode?.localize(l10n);
              },
            ),
            const SizedBox(height: 24),
            if (firebaseBootstrap.usesEmulator) ...[
              Text(
                'Локальный Firebase включён. Перед регистрацией запусти '
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
              key: AppKeys.registerButton,
              onPressed: isRegistrationEnabled ? _handleRegister : null,
              child: Text(l10n.registerButton),
            ),
            const SizedBox(height: 12),
            TextButton(
              key: AppKeys.goToLoginButton,
              onPressed: isLoading
                  ? null
                  : () => Navigator.of(
                      context,
                    ).pushReplacementNamed(AppRoutes.login),
              child: Text(l10n.goToLoginButton),
            ),
          ],
        ),
      ),
    );
  }
}
