import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import 'shared_preferences_provider.dart';

const appThemePreferenceKey = 'app_theme_palette';

final initialAppThemeProvider = Provider<AppThemePalette>((ref) {
  final storedId = ref
      .read(sharedPreferencesProvider)
      ?.getString(appThemePreferenceKey);
  return storedId == null
      ? AppThemePalettes.graphiteEnergy
      : AppThemePalettes.byId(storedId);
});

class AppThemeController extends Notifier<AppThemePalette> {
  @override
  AppThemePalette build() => ref.read(initialAppThemeProvider);

  void setPalette(AppThemePalette palette) {
    state = palette;
    ref
        .read(sharedPreferencesProvider)
        ?.setString(appThemePreferenceKey, palette.id);
  }
}

final appThemeProvider = NotifierProvider<AppThemeController, AppThemePalette>(
  AppThemeController.new,
);
