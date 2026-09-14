// Genera los PNG del ícono de NOVA a partir de la misma marca que usa la app.
//
//   flutter test tool/generate_app_icon.dart
//   dart run flutter_launcher_icons
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_ai/shared/widgets/nova_mark.dart';

const _size = 1024.0;

void main() {
  test('genera assets/icon', () async {
    // iOS y web: cuadro de tinta sin transparencia.
    await _render(
      'assets/icon/app_icon.png',
      background: NovaBrand.ink,
      markScale: 0.7,
    );
    // Android adaptativo: solo la cara, dentro de la zona segura (66 %).
    await _render('assets/icon/app_icon_foreground.png', markScale: 0.56);
  });
}

Future<void> _render(
  String path, {
  required double markScale,
  Color? background,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  if (background != null) {
    canvas.drawRect(
      Offset.zero & const Size.square(_size),
      Paint()..color = background,
    );
  }
  final markSize = _size * markScale;
  canvas.translate((_size - markSize) / 2, (_size - markSize) / 2);
  const NovaMarkPainter().paint(canvas, Size.square(markSize));

  final image = await recorder
      .endRecording()
      .toImage(_size.toInt(), _size.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
}
