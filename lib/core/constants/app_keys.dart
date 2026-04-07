import 'package:flutter/widgets.dart';

abstract final class AppKeys {
  static const splashLogo = ValueKey<String>('splashLogo');
  static const loginEmailField = ValueKey<String>('loginEmailField');
  static const loginPasswordField = ValueKey<String>('loginPasswordField');
  static const loginButton = ValueKey<String>('loginButton');
  static const googleSignInButton = ValueKey<String>('googleSignInButton');
  static const goToRegisterButton = ValueKey<String>('goToRegisterButton');
  static const registerEmailField = ValueKey<String>('registerEmailField');
  static const registerPasswordField = ValueKey<String>(
    'registerPasswordField',
  );
  static const registerConfirmPasswordField = ValueKey<String>(
    'registerConfirmPasswordField',
  );
  static const registerButton = ValueKey<String>('registerButton');
  static const goToLoginButton = ValueKey<String>('goToLoginButton');
  static const profileNameField = ValueKey<String>('profileNameField');
  static const profileGenderField = ValueKey<String>('profileGenderField');
  static const profileBirthDateField = ValueKey<String>(
    'profileBirthDateField',
  );
  static const saveProfileButton = ValueKey<String>('saveProfileButton');
  static const signOutButton = ValueKey<String>('signOutButton');
}
