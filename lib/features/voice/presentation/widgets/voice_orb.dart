import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../shared/widgets/nova_logo.dart';
import '../cubit/voice_conversation_cubit.dart';

/// NOVA en el centro del modo voz, con ondas que cambian según escucha,
/// piensa o habla.
class VoiceOrb extends StatefulWidget {
  const VoiceOrb({super.key, required this.status, this.size = 220});

  final VoiceStatus status;
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

    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final bob = widget.status == VoiceStatus.thinking
                ? math.sin(_controller.value * 2 * math.pi) * 6
                : 0.0;
            return CustomPaint(
              painter: _OrbPainter(
                progress: _controller.value,
                status: widget.status,
                primary: scheme.primary,
                accent: scheme.tertiary,
                ring: scheme.outlineVariant,
              ),
              child: Center(
                child: Transform.translate(offset: Offset(0, bob), child: child),
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
    required this.primary,
    required this.accent,
    required this.ring,
  });

  final double progress;
  final VoiceStatus status;
  final Color primary;
  final Color accent;
  final Color ring;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxRadius = size.shortestSide / 2;

    switch (status) {
      case VoiceStatus.listening:
        _pulse(canvas, center, maxRadius, primary, progress);
      case VoiceStatus.speaking:
        _pulse(canvas, center, maxRadius, accent, (progress * 2) % 1);
      case VoiceStatus.thinking:
        for (var i = 0; i < 3; i++) {
          final angle = progress * 2 * math.pi + i * 2 * math.pi / 3;
          canvas.drawCircle(
            center + Offset(math.cos(angle), math.sin(angle)) * maxRadius * 0.72,
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
      oldDelegate.primary != primary ||
      oldDelegate.accent != accent ||
      oldDelegate.ring != ring;
}
