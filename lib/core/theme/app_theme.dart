import 'package:flutter/material.dart';

import '../../shared/widgets/nova_mark.dart';

/// Design System de NOVA: papel cálido, tinta y un solo acento violeta.
///
/// Los titulares usan una serif editorial y el texto corrido la fuente del
/// sistema, para que la app se lea como algo hecho a mano y no como una
/// plantilla genérica.
abstract final class AppTheme {
  static const seedColor = NovaBrand.violet;
  static const displayFont = 'DMSerifDisplay';

  static ThemeData light() => _build(
        ColorScheme.fromSeed(seedColor: seedColor).copyWith(
          primary: const Color(0xFF5B3FE0),
          onPrimary: Colors.white,
          primaryContainer: const Color(0xFFE7E1FF),
          onPrimaryContainer: const Color(0xFF2A1A7A),
          tertiary: NovaBrand.amber,
          onTertiary: NovaBrand.ink,
          surface: NovaBrand.paper,
          onSurface: NovaBrand.ink,
          onSurfaceVariant: const Color(0xFF67636C),
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: const Color(0xFFFBF9F5),
          surfaceContainer: const Color(0xFFF0ECE5),
          surfaceContainerHigh: const Color(0xFFEAE5DC),
          surfaceContainerHighest: const Color(0xFFE3DDD2),
          outline: const Color(0xFFB3ACA2),
          outlineVariant: const Color(0xFFE2DCD2),
        ),
      );

  static ThemeData dark() => _build(
        ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ).copyWith(
          primary: const Color(0xFFA08CFF),
          onPrimary: const Color(0xFF1C1450),
          primaryContainer: const Color(0xFF2D2560),
          onPrimaryContainer: const Color(0xFFE7E1FF),
          tertiary: const Color(0xFFFFC76E),
          onTertiary: NovaBrand.ink,
          surface: const Color(0xFF141318),
          onSurface: const Color(0xFFF1EEE8),
          onSurfaceVariant: const Color(0xFFA7A2AC),
          surfaceContainerLowest: const Color(0xFF1A191F),
          surfaceContainerLow: const Color(0xFF1D1C22),
          surfaceContainer: const Color(0xFF222127),
          surfaceContainerHigh: const Color(0xFF29282F),
          surfaceContainerHighest: const Color(0xFF312F37),
          outline: const Color(0xFF5A5660),
          outlineVariant: const Color(0xFF34323A),
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

    final fieldRadius = BorderRadius.circular(18);
    OutlineInputBorder fieldBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: fieldRadius,
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
            borderRadius: BorderRadius.circular(16),
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
