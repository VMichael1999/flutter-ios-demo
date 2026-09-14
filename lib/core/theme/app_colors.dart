import 'package:flutter/painting.dart';

/// Colores de NOVA que no dependen del tema: la marca y el mapa.
///
/// Las pantallas usan `Theme.of(context).colorScheme` para casi todo; aquí
/// solo va lo que debe verse igual en modo claro y oscuro.
abstract final class AppColors {
  // Marca.
  static const ink = Color(0xFF1C1B22);
  static const violet = Color(0xFF7B61FF);
  static const amber = Color(0xFFFFB547);
  static const paper = Color(0xFFF5F2EC);
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);

  // Mapa.
  static const mapUserLocation = Color(0xFF2F80ED);
  static const mapMarkerBorder = white;
  static const mapMarkerShadow = Color(0x40000000);
  static const mapAttributionBackground = Color(0xD9FFFFFF);
  static const mapAttributionText = Color(0xFF333333);
}

/// Colores del tema claro.
abstract final class LightPalette {
  static const primary = Color(0xFF5B3FE0);
  static const onPrimary = AppColors.white;
  static const primaryContainer = Color(0xFFE7E1FF);
  static const onPrimaryContainer = Color(0xFF2A1A7A);
  static const tertiary = AppColors.amber;
  static const onTertiary = AppColors.ink;
  static const surface = AppColors.paper;
  static const onSurface = AppColors.ink;
  static const onSurfaceVariant = Color(0xFF67636C);
  static const surfaceContainerLowest = AppColors.white;
  static const surfaceContainerLow = Color(0xFFFBF9F5);
  static const surfaceContainer = Color(0xFFF0ECE5);
  static const surfaceContainerHigh = Color(0xFFEAE5DC);
  static const surfaceContainerHighest = Color(0xFFE3DDD2);
  static const outline = Color(0xFFB3ACA2);
  static const outlineVariant = Color(0xFFE2DCD2);
}

/// Colores del tema oscuro.
abstract final class DarkPalette {
  static const primary = Color(0xFFA08CFF);
  static const onPrimary = Color(0xFF1C1450);
  static const primaryContainer = Color(0xFF2D2560);
  static const onPrimaryContainer = Color(0xFFE7E1FF);
  static const tertiary = Color(0xFFFFC76E);
  static const onTertiary = AppColors.ink;
  static const surface = Color(0xFF141318);
  static const onSurface = Color(0xFFF1EEE8);
  static const onSurfaceVariant = Color(0xFFA7A2AC);
  static const surfaceContainerLowest = Color(0xFF1A191F);
  static const surfaceContainerLow = Color(0xFF1D1C22);
  static const surfaceContainer = Color(0xFF222127);
  static const surfaceContainerHigh = Color(0xFF29282F);
  static const surfaceContainerHighest = Color(0xFF312F37);
  static const outline = Color(0xFF5A5660);
  static const outlineVariant = Color(0xFF34323A);
}
