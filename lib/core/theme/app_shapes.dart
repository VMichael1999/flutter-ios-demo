import 'package:flutter/material.dart';

/// Radios de esquina usados en toda la app.
abstract final class AppRadii {
  static const small = 12.0;
  static const button = 16.0;
  static const medium = 18.0;
  static const large = 20.0;
  static const extraLarge = 24.0;
  static const pill = 99.0;
}

/// Formas repetidas: tarjetas claras con un borde suave.
abstract final class AppShapes {
  /// Para `Material` o `Card`: atajos, historial, tarjeta del lugar.
  static RoundedRectangleBorder outlinedCard(
    ColorScheme scheme, {
    double radius = AppRadii.large,
  }) => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(radius),
    side: BorderSide(color: scheme.outlineVariant),
  );

  /// Para `Container` o `DecoratedBox`. Sin [color] queda transparente.
  static BoxDecoration outlinedBox(
    ColorScheme scheme, {
    double radius = AppRadii.large,
    Color? color,
  }) => BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: scheme.outlineVariant),
  );
}
