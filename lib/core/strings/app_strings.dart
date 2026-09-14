/// Textos generales, compartidos por varias pantallas.
abstract final class AppStrings {
  static const appName = 'NOVA AI';
  static const brand = 'NOVA';
  static const tagline = 'Tu asistente inteligente';
  static const history = 'Historial';
  static const send = 'Enviar';
  static const directions = 'Cómo llegar';
  static const undo = 'Deshacer';
  static const soon = 'Pronto';

  static String comingSoon(String feature) =>
      '$feature estará disponible en próximas versiones.';
}
