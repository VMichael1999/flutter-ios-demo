import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// La cara de NOVA: una cabeza redonda con antena que mira hacia arriba,
/// curiosa. Se usa en el logo, en el modo voz y para generar el ícono.
class NovaMarkPainter extends CustomPainter {
  const NovaMarkPainter({
    this.head = AppColors.violet,
    this.face = AppColors.white,
    this.pupil = AppColors.ink,
    this.tip = AppColors.amber,
  });

  final Color head;
  final Color face;
  final Color pupil;
  final Color tip;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final radius = side * 0.34;
    final center = Offset(size.width / 2, size.height / 2 + side * 0.08);

    // Antena ligeramente inclinada con la punta encendida.
    final antennaBase = center.translate(0, -radius);
    final antennaTip = center.translate(radius * 0.42, -radius * 1.42);
    canvas
      ..drawLine(
        antennaBase,
        antennaTip,
        Paint()
          ..color = head
          ..strokeWidth = side * 0.045
          ..strokeCap = StrokeCap.round,
      )
      ..drawCircle(antennaTip, side * 0.07, Paint()..color = tip)
      ..drawCircle(center, radius, Paint()..color = head);

    for (final direction in const [-1, 1]) {
      final eye = center.translate(direction * radius * 0.36, -radius * 0.08);
      canvas
        ..drawOval(
          Rect.fromCenter(
            center: eye,
            width: radius * 0.36,
            height: radius * 0.46,
          ),
          Paint()..color = face,
        )
        ..drawCircle(
          eye.translate(radius * 0.05, -radius * 0.06),
          radius * 0.12,
          Paint()..color = pupil,
        );
    }

    canvas.drawArc(
      Rect.fromCenter(
        center: center.translate(radius * 0.04, radius * 0.36),
        width: radius * 0.44,
        height: radius * 0.26,
      ),
      0.15 * math.pi,
      0.7 * math.pi,
      false,
      Paint()
        ..color = face
        ..style = PaintingStyle.stroke
        ..strokeWidth = side * 0.035
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(NovaMarkPainter oldDelegate) =>
      oldDelegate.head != head ||
      oldDelegate.face != face ||
      oldDelegate.pupil != pupil ||
      oldDelegate.tip != tip;
}
