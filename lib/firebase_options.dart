// Configuración de Firebase del proyecto `nova-ai-7b36c`.
//
// Estos valores identifican el proyecto y no son secretos: la API key de
// Gemini la gestiona Firebase AI Logic en el servidor. Android e iOS se
// añadirán al registrar esas apps en Firebase.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

abstract final class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      _ => throw UnsupportedError(
          'Firebase aún no está configurado para ${defaultTargetPlatform.name}.',
        ),
    };
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCkZtBh1VWuQohl8EtZeK5hc6nTaL28xzA',
    appId: '1:455117691211:android:e392ba04f2a9257fce30ce',
    messagingSenderId: '455117691211',
    projectId: 'nova-ai-7b36c',
    storageBucket: 'nova-ai-7b36c.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDuzDFK3HXCn4stwfMawhzo7YpGJ1P5iMo',
    appId: '1:455117691211:ios:74689fec85867315ce30ce',
    messagingSenderId: '455117691211',
    projectId: 'nova-ai-7b36c',
    storageBucket: 'nova-ai-7b36c.firebasestorage.app',
    iosBundleId: 'com.vmichael1999.novaai',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDr999K7Omfd6i8YEqk4Dg_Ojhaq7LilY8',
    appId: '1:455117691211:web:e6e28d083ef27f1fce30ce',
    messagingSenderId: '455117691211',
    projectId: 'nova-ai-7b36c',
    authDomain: 'nova-ai-7b36c.firebaseapp.com',
    storageBucket: 'nova-ai-7b36c.firebasestorage.app',
  );
}
