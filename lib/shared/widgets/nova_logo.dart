import 'package:flutter/material.dart';

import 'nova_mark.dart';

/// Logo de NOVA: la cara de la mascota sobre un cuadro de tinta, igual que el
/// ícono de la app.
class NovaLogo extends StatelessWidget {
  const NovaLogo({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.12),
      decoration: BoxDecoration(
        color: NovaBrand.ink,
        borderRadius: BorderRadius.circular(size * 0.28),
        // En modo oscuro el cuadro de tinta se perdería contra el fondo.
        border:
            isDark ? Border.all(color: theme.colorScheme.outlineVariant) : null,
      ),
      child: const CustomPaint(painter: NovaMarkPainter()),
    );
  }
}
