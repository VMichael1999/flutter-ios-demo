import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Comprueba que las configuraciones nativas siguen como NOVA las necesita;
/// un cambio accidental rompería la app en release.
void main() {
  group('AndroidManifest.xml', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

    const permissions = [
      'INTERNET',
      'ACCESS_NETWORK_STATE',
      'ACCESS_COARSE_LOCATION',
      'ACCESS_FINE_LOCATION',
      'RECORD_AUDIO',
      'POST_NOTIFICATIONS',
    ];
    for (final permission in permissions) {
      test('declara $permission', () {
        expect(manifest, contains('android.permission.$permission'));
      });
    }

    test('no declara CAMERA, que bloquearía la cámara de image_picker', () {
      expect(
        manifest,
        isNot(contains('<uses-permission android:name="android.permission.CAMERA"')),
      );
      expect(manifest, contains('android.hardware.camera'));
    });

    test('puede abrir enlaces https para "Cómo llegar"', () {
      expect(manifest, contains('android:scheme="https"'));
    });

    test('encuentra el reconocedor de voz y la voz del sistema', () {
      expect(manifest, contains('android.speech.RecognitionService'));
      expect(manifest, contains('android.intent.action.TTS_SERVICE'));
    });

    test('muestra NOVA AI como nombre de la app', () {
      expect(manifest, contains('android:label="NOVA AI"'));
    });
  });

  group('Info.plist de iOS', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();

    const usageDescriptions = [
      'NSLocationWhenInUseUsageDescription',
      'NSCameraUsageDescription',
      'NSPhotoLibraryUsageDescription',
      'NSMicrophoneUsageDescription',
      'NSSpeechRecognitionUsageDescription',
    ];
    for (final key in usageDescriptions) {
      test('explica al usuario el permiso $key', () {
        expect(plist, contains('<key>$key</key>'));
      });
    }

    test('muestra NOVA AI bajo el icono', () {
      expect(
        plist,
        matches(
          RegExp(r'<key>CFBundleDisplayName</key>\s*<string>NOVA AI</string>'),
        ),
      );
    });
  });
}
