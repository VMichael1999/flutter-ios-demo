import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../shared/widgets/nova_logo.dart';
import '../cubit/voice_conversation_cubit.dart';

/// NOVA en el centro del modo voz, con ondas que cambian según escucha,
/// piensa o habla. Mientras escucha, crece con el volumen de la voz para que
/// se note que el micrófono está captando.
class VoiceOrb extends StatefulWidget {
  const VoiceOrb({
    super.key,
    required this.status,
    this.level,
    this.size = 220,
  });

  final VoiceStatus status;

  /// Volumen del micrófono, de 0 a 1.
  final ValueListenable<double>? level;
  final double size;

  @override
  State<VoiceOrb> createState() => _VoiceOrbState();
}

class _VoiceOrbState extends State<VoiceOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  /// Volumen suavizado: el micrófono salta de golpe y el dibujo no debe.
  double _level = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respeta la opción de accesibilidad "quitar animaciones".
    if (MediaQuery.of(context).disableAnimations) {
      _controller
        ..stop()
        ..value = 0.3;
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
    final scheme = Theme.of(context).colorScheme;
    final level = widget.level;

    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: Listenable.merge([_controller, if (level != null) level]),
          builder: (context, child) {
            final target =
                widget.status == VoiceStatus.listening
                    ? (level?.value ?? 0)
                    : 0.0;
            _level += (target - _level) * 0.2;
            final bob =
                widget.status == VoiceStatus.thinking
                    ? math.sin(_controller.value * 2 * math.pi) * 6
                    : 0.0;
            return CustomPaint(
              painter: _OrbPainter(
                progress: _controller.value,
                status: widget.status,
                level: _level,
                primary: scheme.primary,
                accent: scheme.tertiary,
                ring: scheme.outlineVariant,
              ),
              child: Center(
                child: Transform.translate(
                  offset: Offset(0, bob),
                  child: Transform.scale(
                    scale: 1 + 0.12 * _level,
                    child: child,
                  ),
                ),
              ),
            );
          },
          child: NovaLogo(size: widget.size * 0.46),
        ),
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  _OrbPainter({
    required this.progress,
    required this.status,
    required this.level,
    required this.primary,
    required this.accent,
    required this.ring,
  });

  final double progress;
  final VoiceStatus status;
  final double level;
  final Color primary;
  final Color accent;
  final Color ring;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxRadius = size.shortestSide / 2;

    switch (status) {
      case VoiceStatus.listening:
        // Halo que respira con la voz, más las ondas de siempre.
        canvas.drawCircle(
          center,
          maxRadius * (0.5 + 0.35 * level),
          Paint()..color = primary.withValues(alpha: 0.12 + 0.2 * level),
        );
        _pulse(canvas, center, maxRadius, primary, progress);
      case VoiceStatus.speaking:
        _pulse(canvas, center, maxRadius, accent, (progress * 2) % 1);
      case VoiceStatus.thinking:
        for (var i = 0; i < 3; i++) {
          final angle = progress * 2 * math.pi + i * 2 * math.pi / 3;
          canvas.drawCircle(
            center +
                Offset(math.cos(angle), math.sin(angle)) * maxRadius * 0.72,
            maxRadius * 0.045,
            Paint()..color = primary.withValues(alpha: 0.4 + 0.25 * i),
          );
        }
      case VoiceStatus.idle || VoiceStatus.failure:
        canvas.drawCircle(
          center,
          maxRadius * 0.62,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = ring,
        );
    }
  }

  /// Tres ondas que salen del centro y se desvanecen.
  void _pulse(
    Canvas canvas,
    Offset center,
    double maxRadius,
    Color color,
    double phase,
  ) {
    for (var i = 0; i < 3; i++) {
      final t = (phase + i / 3) % 1;
      canvas.drawCircle(
        center,
        maxRadius * (0.5 + 0.5 * t),
        Paint()..color = color.withValues(alpha: 0.28 * (1 - t)),
      );
    }
  }

  @override
  bool shouldRepaint(_OrbPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.status != status ||
      oldDelegate.level != level ||
      oldDelegate.primary != primary ||
      oldDelegate.accent != accent ||
      oldDelegate.ring != ring;
}
