import 'package:flutter/material.dart';

import '../../core/theme/motion.dart';

/// Respuesta física al tocar: el elemento se hunde un poco mientras se
/// presiona, así se siente que la app escuchó el toque.
///
/// [builder] debe pasar `onHighlightChanged` a su `InkWell`: así el efecto se
/// cancela solo si el toque termina siendo un desplazamiento.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.builder});

  final Widget Function(
    BuildContext context,
    ValueChanged<bool> onHighlightChanged,
  )
  builder;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  var _pressed = false;

  void _onHighlightChanged(bool pressed) {
    if (pressed != _pressed) setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return AnimatedScale(
      scale: _pressed && !reduceMotion ? Motion.pressedScale : 1,
      duration: Motion.press,
      curve: Motion.easeOut,
      child: widget.builder(context, _onHighlightChanged),
    );
  }
}
