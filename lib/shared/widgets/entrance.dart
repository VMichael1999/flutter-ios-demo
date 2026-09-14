import 'package:flutter/material.dart';

import '../../core/theme/motion.dart';

/// Hace aparecer [child] con un fundido y subiendo unos píxeles, una sola vez
/// al montarse. Evita que el contenido nuevo aparezca de golpe.
///
/// Con "quitar animaciones" activado solo queda el fundido, sin movimiento.
class Entrance extends StatefulWidget {
  const Entrance({
    super.key,
    required this.child,
    this.enabled = true,
    this.delay = Duration.zero,
    this.offset = 8,
  });

  final Widget child;

  /// Si es `false` el contenido aparece directamente.
  final bool enabled;

  /// Espera antes de entrar, para escalonar varios elementos.
  final Duration delay;

  /// Píxeles que sube mientras entra.
  final double offset;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    final total = widget.delay + Motion.enter;
    _controller = AnimationController(
      vsync: this,
      duration: total,
      value: widget.enabled ? 0 : 1,
    );
    // La espera va dentro de la misma animación: no hacen falta temporizadores.
    final start = widget.delay.inMicroseconds / total.inMicroseconds;
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, 1, curve: Motion.easeOut),
    );
    if (widget.enabled) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return FadeTransition(
      opacity: _progress,
      // Los lectores de pantalla no esperan a que termine la animación.
      alwaysIncludeSemantics: true,
      child:
          reduceMotion
              ? widget.child
              : AnimatedBuilder(
                animation: _progress,
                child: widget.child,
                builder:
                    (context, child) => Transform.translate(
                      offset: Offset(0, widget.offset * (1 - _progress.value)),
                      child: child,
                    ),
              ),
    );
  }
}
