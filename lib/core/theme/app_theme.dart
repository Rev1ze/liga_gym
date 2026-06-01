import 'package:flutter/material.dart';

class AppThemePalette {
  const AppThemePalette({
    required this.id,
    required this.ruName,
    required this.enName,
    required this.ruDescription,
    required this.enDescription,
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.background,
    this.brightness = Brightness.light,
  });

  final String id;
  final String ruName;
  final String enName;
  final String ruDescription;
  final String enDescription;
  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Color background;
  final Brightness brightness;

  String name(Locale locale) => locale.languageCode == 'ru' ? ruName : enName;

  String description(Locale locale) =>
      locale.languageCode == 'ru' ? ruDescription : enDescription;

  bool get isDark => brightness == Brightness.dark;
}

abstract final class AppThemePalettes {
  static const pulseBlue = AppThemePalette(
    id: 'pulse_blue',
    ruName: 'Slate Lime',
    enName: 'Slate Lime',
    ruDescription:
        'Светлая premium-тема: мягкий графит, спокойный лайм и холодный синий акцент.',
    enDescription: 'Soft graphite, refined lime, and a clean blue accent.',
    primary: Color(0xFF172033),
    secondary: Color(0xFF8BCB2F),
    tertiary: Color(0xFF2F80ED),
    background: Color(0xFFF7F8FB),
  );

  static const voltCoral = AppThemePalette(
    id: 'volt_coral',
    ruName: 'Coral Mint',
    enName: 'Coral Mint',
    ruDescription:
        'Теплая premium-тема: коралл, глубокая мята и фиолетовый tech-акцент.',
    enDescription: 'Warm coral, deep mint, and a violet tech accent.',
    primary: Color(0xFFE0523F),
    secondary: Color(0xFF12A594),
    tertiary: Color(0xFF725CFF),
    background: Color(0xFFFFF8F5),
  );

  static const graphiteEnergy = AppThemePalette(
    id: 'graphite_energy',
    ruName: 'Graphite Pro',
    enName: 'Graphite Pro',
    ruDescription:
        'Темная luxury-тема: premium black, electric lime и cyan glow.',
    enDescription: 'Dark luxury premium black, electric lime, and cyan glow.',
    primary: Color(0xFFB8FF2C),
    secondary: Color(0xFF00E5FF),
    tertiary: Color(0xFFFF4FD8),
    background: Color(0xFF050608),
    brightness: Brightness.dark,
  );

  static const all = <AppThemePalette>[pulseBlue, voltCoral, graphiteEnergy];

  static AppThemePalette byId(String? id) {
    return all.firstWhere(
      (palette) => palette.id == id,
      orElse: () => pulseBlue,
    );
  }
}

ThemeData buildLigaGymTheme(AppThemePalette palette) {
  final isDark = palette.isDark;
  final lightSurfaceContainer = switch (palette.id) {
    'volt_coral' => const Color(0xFFFFF0EA),
    _ => const Color(0xFFF1F4F7),
  };
  final lightSurfaceContainerHighest = switch (palette.id) {
    'volt_coral' => const Color(0xFFFFE5DA),
    _ => const Color(0xFFE5EBF0),
  };
  final lightOutline = switch (palette.id) {
    'volt_coral' => const Color(0xFFE8D3CA),
    _ => const Color(0xFFD8E0E7),
  };

  final scheme =
      ColorScheme.fromSeed(
        seedColor: palette.primary,
        brightness: palette.brightness,
      ).copyWith(
        primary: palette.primary,
        secondary: palette.secondary,
        tertiary: palette.tertiary,
        surface: isDark ? const Color(0xFF101217) : Colors.white,
        surfaceContainerLowest: isDark
            ? const Color(0xFF07090D)
            : const Color(0xFFFFFFFF),
        surfaceContainer: isDark
            ? const Color(0xFF151922)
            : lightSurfaceContainer,
        surfaceContainerHighest: isDark
            ? const Color(0xFF202532)
            : lightSurfaceContainerHighest,
        outlineVariant: isDark ? const Color(0xFF303743) : lightOutline,
      );

  final textTheme =
      Typography.material2021(
        platform: TargetPlatform.android,
        colorScheme: scheme,
      ).black.apply(
        fontFamily: 'Arial',
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      );

  return ThemeData(
    useMaterial3: true,
    brightness: palette.brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: palette.background,
    visualDensity: VisualDensity.compact,
    splashFactory: InkRipple.splashFactory,
    textTheme: textTheme.copyWith(
      displaySmall: textTheme.displaySmall?.copyWith(
        fontWeight: FontWeight.w900,
      ),
      headlineMedium: textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w900,
      ),
      titleLarge: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      labelLarge: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 58,
      actionsPadding: const EdgeInsetsDirectional.only(end: 8),
      backgroundColor: palette.background.withValues(alpha: 0.94),
      foregroundColor: scheme.onSurface,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w900,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: scheme.surface.withValues(alpha: isDark ? 0.7 : 0.96),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.68),
      side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.46)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      labelStyle: textTheme.labelMedium,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 46),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        backgroundColor: scheme.primary,
        foregroundColor: isDark ? Colors.black : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 46),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        foregroundColor: scheme.onSurface,
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: scheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.secondary, width: 1.6),
      ),
      filled: true,
      fillColor: scheme.surfaceContainerLowest.withValues(alpha: 0.88),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size.square(44),
        padding: const EdgeInsets.all(8),
        tapTargetSize: MaterialTapTargetSize.padded,
        visualDensity: VisualDensity.standard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    listTileTheme: ListTileThemeData(
      dense: true,
      minLeadingWidth: 28,
      horizontalTitleGap: 10,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant.withValues(alpha: 0.55),
      space: 18,
      thickness: 1,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    bottomAppBarTheme: BottomAppBarThemeData(
      color: scheme.surface.withValues(alpha: isDark ? 0.72 : 0.92),
      elevation: 0,
    ),
  );
}
