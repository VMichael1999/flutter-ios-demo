import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nova_ai/core/errors/failures.dart';
import 'package:nova_ai/core/services/speech_service.dart';
import 'package:nova_ai/core/services/text_to_speech_service.dart';

/// Reconocedor de voz controlado desde el test: [say] simula lo que la
/// persona va diciendo y [finish] que dejó de hablar.
class FakeSpeechService implements SpeechService {
  StreamController<SpeechUpdate>? _session;
  int listenCalls = 0;
  int stopCalls = 0;
  int cancelCalls = 0;

  @override
  final ValueNotifier<double> soundLevel = ValueNotifier(0);

  @override
  Stream<SpeechUpdate> listen() {
    listenCalls++;
    final session = StreamController<SpeechUpdate>();
    _session = session;
    return session.stream;
  }

  void say(String text, {bool isFinal = false}) =>
      _session!.add(SpeechUpdate(text, isFinal: isFinal));

  Future<void> finish() => _session!.close();

  Future<void> fail(SpeechFailure failure) {
    _session!.addError(failure);
    return _session!.close();
  }

  @override
  Future<void> stop() async {
    stopCalls++;
    await _session?.close();
  }

  @override
  Future<void> cancel() async {
    cancelCalls++;
  }
}

/// Voz simulada: guarda lo que se leyó. Con [holdSpeech] no termina de
/// hablar hasta [finishSpeaking] o [stop]; con [fails] lanza un error.
class FakeTextToSpeech implements TextToSpeechService {
  FakeTextToSpeech({this.holdSpeech = false, this.fails = false});

  final bool holdSpeech;
  final bool fails;
  final spoken = <String>[];
  int stopCalls = 0;
  Completer<void>? _speaking;

  @override
  Future<void> speak(String text) {
    spoken.add(text);
    if (fails) return Future.error(Exception('Sin voz'));
    if (!holdSpeech) return Future.value();
    return (_speaking = Completer<void>()).future;
  }

  void finishSpeaking() => _speaking?.complete();

  @override
  Future<void> stop() async {
    stopCalls++;
    final speaking = _speaking;
    if (speaking != null && !speaking.isCompleted) speaking.complete();
  }
}
