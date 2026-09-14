import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/config/app_config.dart';
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
  } catch (error) {
    debugPrint('Firebase no está configurado, NOVA usa el modo demo: $error');
    return false;
  }

  await _activateAppCheck();
  return true;
}

/// Firebase AI Logic exige App Check: sin un token válido Gemini responde 401.
Future<void> _activateAppCheck() async {
  try {
    if (AppConfig.appCheckDebug) {
      await FirebaseAppCheck.instance.activate(
        providerWeb: WebDebugProvider(),
        providerAndroid: const AndroidDebugProvider(),
        providerApple: const AppleDebugProvider(),
      );
      return;
    }

    await FirebaseAppCheck.instance.activate(
      providerWeb:
          AppConfig.recaptchaSiteKey.isEmpty
              ? null
              : ReCaptchaEnterpriseProvider(AppConfig.recaptchaSiteKey),
      providerAndroid: const AndroidPlayIntegrityProvider(),
      providerApple: const AppleAppAttestWithDeviceCheckFallbackProvider(),
    );
  } catch (error) {
    debugPrint('No se pudo activar App Check: $error');
  }
}
