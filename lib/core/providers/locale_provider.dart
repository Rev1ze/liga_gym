import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'shared_preferences_provider.dart';

const _appLocalePreferenceKey = 'app_locale';

final initialAppLocaleProvider = Provider<Locale?>((ref) => null);

class AppLocaleController extends Notifier<Locale?> {
  @override
  Locale? build() => ref.read(initialAppLocaleProvider);

  void setLocale(Locale locale) {
    state = locale;
    ref
        .read(sharedPreferencesProvider)
        ?.setString(_appLocalePreferenceKey, locale.languageCode);
  }
}

final appLocaleProvider = NotifierProvider<AppLocaleController, Locale?>(
  AppLocaleController.new,
);

Locale? parseSavedLocale(String? languageCode) {
  if (languageCode == null || languageCode.isEmpty) {
    return null;
  }

  return Locale(languageCode);
}
