import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/di/injection.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebaseReady = await _initializeFirebase();
  await configureDependencies(useFirebaseAi: firebaseReady);
  runApp(const NovaApp());
}

/// En plataformas que aún no están registradas en Firebase NOVA arranca en
/// modo demo con respuestas simuladas.
Future<bool> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return true;
  } catch (error) {
    debugPrint('Firebase no está configurado, NOVA usa el modo demo: $error');
    return false;
  }
}
