import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_shapes.dart';

/// Design System de NOVA: papel cálido, tinta y un solo acento violeta.
///
/// Los titulares usan una serif editorial y el texto corrido la fuente del
/// sistema, para que la app se lea como algo hecho a mano y no como una
/// plantilla genérica. Los colores viven en `app_colors.dart`.
abstract final class AppTheme {
  static const seedColor = AppColors.violet;
  static const displayFont = 'DMSerifDisplay';

  static ThemeData light() => _build(
    ColorScheme.fromSeed(seedColor: seedColor).copyWith(
      primary: LightPalette.primary,
      onPrimary: LightPalette.onPrimary,
      primaryContainer: LightPalette.primaryContainer,
      onPrimaryContainer: LightPalette.onPrimaryContainer,
      tertiary: LightPalette.tertiary,
      onTertiary: LightPalette.onTertiary,
      surface: LightPalette.surface,
      onSurface: LightPalette.onSurface,
      onSurfaceVariant: LightPalette.onSurfaceVariant,
      surfaceContainerLowest: LightPalette.surfaceContainerLowest,
      surfaceContainerLow: LightPalette.surfaceContainerLow,
      surfaceContainer: LightPalette.surfaceContainer,
      surfaceContainerHigh: LightPalette.surfaceContainerHigh,
      surfaceContainerHighest: LightPalette.surfaceContainerHighest,
      outline: LightPalette.outline,
      outlineVariant: LightPalette.outlineVariant,
    ),
  );

  static ThemeData dark() => _build(
    ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    ).copyWith(
      primary: DarkPalette.primary,
      onPrimary: DarkPalette.onPrimary,
      primaryContainer: DarkPalette.primaryContainer,
      onPrimaryContainer: DarkPalette.onPrimaryContainer,
      tertiary: DarkPalette.tertiary,
      onTertiary: DarkPalette.onTertiary,
      surface: DarkPalette.surface,
      onSurface: DarkPalette.onSurface,
      onSurfaceVariant: DarkPalette.onSurfaceVariant,
      surfaceContainerLowest: DarkPalette.surfaceContainerLowest,
      surfaceContainerLow: DarkPalette.surfaceContainerLow,
      surfaceContainer: DarkPalette.surfaceContainer,
      surfaceContainerHigh: DarkPalette.surfaceContainerHigh,
      surfaceContainerHighest: DarkPalette.surfaceContainerHighest,
      outline: DarkPalette.outline,
      outlineVariant: DarkPalette.outlineVariant,
    ),
  );

  static ThemeData _build(ColorScheme scheme) {
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    final text = base.textTheme;

    TextStyle? display(TextStyle? style) => style?.copyWith(
      fontFamily: displayFont,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.4,
      color: scheme.onSurface,
    );

    final textTheme = text.copyWith(
      displayLarge: display(text.displayLarge),
      displayMedium: display(text.displayMedium),
      displaySmall: display(text.displaySmall),
      headlineLarge: display(text.headlineLarge),
      headlineMedium: display(text.headlineMedium),
      headlineSmall: display(text.headlineSmall),
    );

    OutlineInputBorder fieldBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.medium),
          borderSide: BorderSide(color: color, width: width),
        );

    return base.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.headlineSmall?.copyWith(fontSize: 22),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: fieldBorder(scheme.outlineVariant),
        enabledBorder: fieldBorder(scheme.outlineVariant),
        focusedBorder: fieldBorder(scheme.primary, 1.5),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          backgroundColor: scheme.onSurface,
          foregroundColor: scheme.surface,
          textStyle: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        side: BorderSide(color: scheme.outlineVariant),
        shape: const StadiumBorder(),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
