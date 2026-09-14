import 'package:flutter/widgets.dart';

/// Curvas y duraciones compartidas de NOVA.
///
/// Reglas: lo que entra o sale usa [easeOut]; lo que se mueve dentro de la
/// pantalla, [easeInOut]; los cambios de color, `Curves.ease`. Las animaciones
/// de interfaz se quedan por debajo de 300 ms.
abstract final class Motion {
  /// Arranca rápido y frena suave: responde en el instante en que se mira.
  static const easeOut = Cubic(0.23, 1, 0.32, 1);

  /// Para movimiento dentro de la pantalla, como pasar de página.
  static const easeInOut = Cubic(0.77, 0, 0.175, 1);

  static const press = Duration(milliseconds: 160);
  static const fast = Duration(milliseconds: 150);
  static const standard = Duration(milliseconds: 200);
  static const enter = Duration(milliseconds: 250);

  /// Separación entre elementos que entran juntos.
  static const stagger = Duration(milliseconds: 50);

  /// Cuánto se hunde un elemento al tocarlo.
  static const pressedScale = 0.97;

  /// Transición para cambiar un ícono o botón por otro: nunca desde cero,
  /// sino desde el 90 % de su tamaño y transparente.
  static Widget fadeScale(Widget child, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.9, end: 1).animate(animation),
        child: child,
      ),
    );
  }
}
