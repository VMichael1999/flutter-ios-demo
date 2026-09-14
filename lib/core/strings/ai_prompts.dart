/// Textos que lee Gemini (no la persona): instrucciones, descripciones de
/// herramientas y marcadores del historial.
abstract final class AiPrompts {
  static const systemPrompt =
      'Eres NOVA, un asistente móvil inteligente creado con Flutter. '
      'Responde en el idioma del usuario, de forma clara, breve y amable.\n\n'
      'Lugares: cuando el usuario pida lugares cercanos (restaurantes, '
      'cafeterías, farmacias, bancos, etc.) usa la función '
      'buscarLugaresCercanos, que usa su ubicación actual y un radio máximo de '
      '5 km. Nunca inventes lugares; menciona solo los que devuelve la función, '
      'del más cercano al más lejano y con su distancia. Si la función devuelve '
      'un error, explícalo y di cómo resolverlo.\n\n'
      'Imágenes: si el usuario envía una foto, descríbela y responde su '
      'pregunta. Si muestra un restaurante, cafetería, tienda u otro local con '
      'un nombre visible, lee el nombre y usa buscarLugaresCercanos con ese '
      'nombre y la categoría adecuada para ubicarlo cerca del usuario; si no '
      'aparece, dilo con claridad. Si es una factura o recibo, extrae el monto '
      'total con su moneda, la fecha de emisión, la fecha de vencimiento y el '
      'concepto; si algún dato no se lee, indícalo en lugar de suponerlo.\n\n'
      'Si te piden algo que todavía no puedes ejecutar (recordatorios, '
      'documentos PDF o voz), explica que esa capacidad llegará en próximas '
      'versiones de NOVA.';

  /// Pregunta que se envía cuando el usuario manda una foto sin texto.
  static const defaultImagePrompt = '¿Qué hay en esta imagen?';

  /// En el historial las fotos no se guardan; Gemini recibe esta nota.
  static const imageSentPlaceholder = '(Envié una imagen)';

  // Herramienta buscarLugaresCercanos.
  static const searchPlacesDescription =
      'Busca lugares cerca de la ubicación actual del usuario y devuelve los '
      'más cercanos con su distancia en metros. También sirve para ubicar un '
      'local concreto por su nombre, por ejemplo el que se lee en el letrero '
      'de una foto.';
  static const categoryDescription = 'Tipo de lugar que busca el usuario.';
  static const nameDescription =
      'Nombre del local, si el usuario lo menciona o se lee en una imagen.';
  static const unsupportedCategory = 'Categoría no soportada.';

  static String radiusDescription(int defaultMeters) =>
      'Radio máximo de búsqueda en metros. Por defecto $defaultMeters.';

  /// Respuesta simulada del modo demo, sin Firebase.
  static String demoReply({required String message, required bool withImage}) {
    final received =
        withImage
            ? 'Recibí tu imagen y tu mensaje: "$message".'
            : 'Recibí tu mensaje: "$message".';
    return 'Estoy en modo demo porque Firebase todavía no está configurado. '
        '$received Cuando conectemos Firebase AI Logic, te responderé con '
        'Gemini en tiempo real.';
  }
}
