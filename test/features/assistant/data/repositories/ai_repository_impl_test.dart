import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_ai/core/errors/failures.dart';
import 'package:nova_ai/features/assistant/data/datasources/ai_remote_datasource.dart';
import 'package:nova_ai/features/assistant/data/repositories/ai_repository_impl.dart';
import 'package:nova_ai/features/assistant/domain/entities/ai_reply_chunk.dart';

import '../../../../fixtures/places_fixtures.dart';

class _MockAiRemoteDataSource extends Mock implements AiRemoteDataSource {}

void main() {
  late _MockAiRemoteDataSource dataSource;
  late AiRepositoryImpl repository;

  setUpAll(() => registerFallbackValue(testImageAttachment));

  setUp(() {
    dataSource = _MockAiRemoteDataSource();
    repository = AiRepositoryImpl(dataSource);
  });

  void stubReply(Stream<AiReplyChunk> Function() reply) {
    when(
      () => dataSource.streamReply(any(), attachment: any(named: 'attachment')),
    ).thenAnswer((_) => reply());
  }

  test('reenvía texto y lugares en orden', () {
    stubReply(
      () => Stream.fromIterable(const [
        AiPlacesChunk([chifaPlace]),
        AiTextChunk('Hola, '),
        AiTextChunk('soy NOVA'),
      ]),
    );

    expect(
      repository.streamReply('Hola'),
      emitsInOrder([
        const AiPlacesChunk([chifaPlace]),
        const AiTextChunk('Hola, '),
        const AiTextChunk('soy NOVA'),
        emitsDone,
      ]),
    );
  });

  test('envía la imagen adjunta al datasource', () async {
    stubReply(() => Stream.value(const AiTextChunk('Un restaurante.')));

    await repository
        .streamReply('¿Qué es?', attachment: testImageAttachment)
        .drain<void>();

    verify(
      () => dataSource.streamReply('¿Qué es?', attachment: testImageAttachment),
    ).called(1);
  });

  test('convierte los errores del datasource en AiFailure', () {
    stubReply(() => Stream.error(Exception('Sin red')));

    expect(
      repository.streamReply('Hola'),
      emitsError(
        isA<AiFailure>()
            .having((f) => f.cause, 'cause', isA<Exception>())
            .having((f) => f.message, 'message', contains('conexión')),
      ),
    );
  });

  test('explica los errores de acceso como problema de configuración', () {
    stubReply(
      () => Stream.error(Exception('Firebase App Check token is invalid.')),
    );

    expect(
      repository.streamReply('Hola'),
      emitsError(
        isA<AiFailure>().having(
          (f) => f.message,
          'message',
          contains('no tiene acceso'),
        ),
      ),
    );
  });

  test('mantiene los AiFailure sin envolverlos otra vez', () {
    const failure = AiFailure('Sin conexión');
    stubReply(() => Stream.error(failure));

    expect(repository.streamReply('Hola'), emitsError(same(failure)));
  });

  test('reinicia la sesión del datasource', () {
    repository.resetConversation();

    verify(() => dataSource.reset()).called(1);
  });
}
