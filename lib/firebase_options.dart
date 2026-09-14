// Configuración de Firebase del proyecto `nova-ai-7b36c`.
//
// Estos valores identifican el proyecto y no son secretos: la API key de
// Gemini la gestiona Firebase AI Logic en el servidor. Android e iOS se
// añadirán al registrar esas apps en Firebase.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;

abstract final class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    throw UnsupportedError(
      'Firebase aún no está configurado para ${defaultTargetPlatform.name}.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDr999K7Omfd6i8YEqk4Dg_Ojhaq7LilY8',
    appId: '1:455117691211:web:e6e28d083ef27f1fce30ce',
    messagingSenderId: '455117691211',
    projectId: 'nova-ai-7b36c',
    authDomain: 'nova-ai-7b36c.firebaseapp.com',
    storageBucket: 'nova-ai-7b36c.firebasestorage.app',
  );
}
