import 'dart:math' as math;

import 'package:flutter/material.dart';

/// NOVA pensando: un personaje animado que flota, parpadea y hace burbujas de
/// pensamiento mientras llega la respuesta.
class NovaThinkingIndicator extends StatefulWidget {
  const NovaThinkingIndicator({
    super.key,
    this.label = 'NOVA está pensando…',
    this.size = 64,
  });

  final String label;

  /// Alto aproximado del personaje.
  final double size;

  @override
  State<NovaThinkingIndicator> createState() => _NovaThinkingIndicatorState();
}

class _NovaThinkingIndicatorState extends State<NovaThinkingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respeta la opción de accesibilidad "quitar animaciones".
    if (MediaQuery.of(context).disableAnimations) {
      _controller
        ..stop()
        ..value = 0.25;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Semantics(
      label: widget.label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: widget.size * 1.4,
            height: widget.size * 1.25,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => CustomPaint(
                painter: _NovaMascotPainter(
                  progress: _controller.value,
                  primary: scheme.primary,
                  secondary: scheme.tertiary,
                  face: scheme.onPrimary,
                  bubble: scheme.surfaceContainerHighest,
                  dots: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: ExcludeSemantics(
              child: Text(
                widget.label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NovaMascotPainter extends CustomPainter {
  _NovaMascotPainter({
    required this.progress,
    required this.primary,
    required this.secondary,
    required this.face,
    required this.bubble,
    required this.dots,
  });

  /// Avance del ciclo de animación, de 0 a 1.
  final double progress;
  final Color primary;
  final Color secondary;
  final Color face;
  final Color bubble;
  final Color dots;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.height / 10;
    final bob = math.sin(progress * 2 * math.pi);
    final headRadius = unit * 3;
    final head = Offset(
      headRadius + unit * 0.5,
      size.height - headRadius - unit * 0.8 + bob * unit * 0.25,
    );

    _paintShadow(canvas, size, head, headRadius, unit, bob);
    _paintAntenna(canvas, head, headRadius, unit);
    _paintHead(canvas, head, headRadius, bob);
    _paintBubbles(canvas, size, head, headRadius, unit);
  }

  void _paintShadow(
    Canvas canvas,
    Size size,
    Offset head,
    double headRadius,
    double unit,
    double bob,
  ) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(head.dx, size.height - unit * 0.35),
        width: headRadius * (1.5 - bob * 0.08),
        height: unit * 0.6,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.18 - bob * 0.04),
    );
  }

  void _paintAntenna(Canvas canvas, Offset head, double headRadius, double unit) {
    final base = head.translate(0, -headRadius);
    final tip = base.translate(unit * 0.6, -unit * 1.2);
    canvas.drawLine(
      base,
      tip,
      Paint()
        ..color = primary
        ..strokeWidth = unit * 0.35
        ..strokeCap = StrokeCap.round,
    );
    final glow = 0.55 + 0.45 * math.sin(progress * 4 * math.pi);
    canvas
      ..drawCircle(
        tip,
        unit * 0.9 * glow,
        Paint()..color = secondary.withValues(alpha: 0.35 * glow),
      )
      ..drawCircle(tip, unit * 0.45, Paint()..color = secondary);
  }

  void _paintHead(Canvas canvas, Offset head, double headRadius, double bob) {
    final headRect = Rect.fromCircle(center: head, radius: headRadius);
    canvas.drawCircle(
      head,
      headRadius,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, secondary],
        ).createShader(headRect),
    );

    // Ojos mirando hacia arriba, como quien piensa, con parpadeo.
    final blink = _blinkAmount(progress);
    final pupil = Color.lerp(primary, Colors.black, 0.55)!;
    for (final side in const [-1, 1]) {
      final eye = head.translate(side * headRadius * 0.38, -headRadius * 0.12);
      canvas.drawOval(
        Rect.fromCenter(
          center: eye,
          width: headRadius * 0.42,
          height: headRadius * 0.52 * (1 - blink * 0.9),
        ),
        Paint()..color = face,
      );
      if (blink < 0.5) {
        final look = Offset(
          headRadius * (0.06 + bob * 0.03),
          -headRadius * 0.12,
        );
        canvas.drawCircle(eye + look, headRadius * 0.11, Paint()..color = pupil);
      }
    }

    // Boca pequeña en "o", pensativa.
    canvas.drawOval(
      Rect.fromCenter(
        center: head.translate(headRadius * 0.2, headRadius * 0.42),
        width: headRadius * 0.22,
        height: headRadius * 0.16 * (1 + 0.2 * bob),
      ),
      Paint()..color = face.withValues(alpha: 0.9),
    );
  }

  void _paintBubbles(
    Canvas canvas,
    Size size,
    Offset head,
    double headRadius,
    double unit,
  ) {
    final bubbles = [
      (
        head.translate(headRadius * 1.05, -headRadius * 1.05),
        unit * 0.45,
      ),
      (
        head.translate(headRadius * 1.25, -headRadius * 1.4),
        unit * 0.6,
      ),
      (Offset(size.width - unit * 1.9, unit * 1.9), unit * 1.55),
    ];

    for (var i = 0; i < bubbles.length; i++) {
      final (center, radius) = bubbles[i];
      final appear = _wave(progress, delay: i * 0.18);
      canvas.drawCircle(
        center.translate(0, -appear * unit * 0.2),
        radius * (0.85 + 0.15 * appear),
        Paint()..color = bubble.withValues(alpha: 0.35 + 0.65 * appear),
      );
    }

    // Puntos suspensivos dentro de la burbuja grande.
    final (bigCenter, bigRadius) = bubbles.last;
    for (var i = 0; i < 3; i++) {
      final dot = _wave((progress * 2) % 1.0, delay: i * 0.2);
      canvas.drawCircle(
        bigCenter.translate((i - 1) * bigRadius * 0.45, 0),
        bigRadius * 0.14,
        Paint()..color = dots.withValues(alpha: 0.35 + 0.65 * dot),
      );
    }
  }

  /// Onda suave entre 0 y 1, desplazada por [delay].
  static double _wave(double t, {double delay = 0}) =>
      (math.sin((t - delay) * 2 * math.pi) + 1) / 2;

  /// Dos parpadeos rápidos por ciclo: 0 abierto, 1 cerrado.
  static double _blinkAmount(double t) {
    for (final moment in const [0.3, 0.8]) {
      final distance = (t - moment).abs();
      if (distance < 0.03) return 1 - distance / 0.03;
    }
    return 0;
  }

  @override
  bool shouldRepaint(_NovaMascotPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.primary != primary ||
      oldDelegate.secondary != secondary ||
      oldDelegate.face != face ||
      oldDelegate.bubble != bubble ||
      oldDelegate.dots != dots;
}
