import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_ai/core/errors/failures.dart';
import 'package:nova_ai/features/assistant/data/datasources/ai_remote_datasource.dart';
import 'package:nova_ai/features/assistant/data/repositories/ai_repository_impl.dart';

class _MockAiRemoteDataSource extends Mock implements AiRemoteDataSource {}

void main() {
  late _MockAiRemoteDataSource dataSource;
  late AiRepositoryImpl repository;

  setUp(() {
    dataSource = _MockAiRemoteDataSource();
    repository = AiRepositoryImpl(dataSource);
  });

  test('reenvía los fragmentos de la respuesta', () {
    when(() => dataSource.streamReply('Hola'))
        .thenAnswer((_) => Stream.fromIterable(['Hola, ', 'soy NOVA']));

    expect(repository.streamReply('Hola'), emitsInOrder(['Hola, ', 'soy NOVA', emitsDone]));
  });

  test('convierte los errores del datasource en AiFailure', () {
    when(() => dataSource.streamReply('Hola'))
        .thenAnswer((_) => Stream.error(Exception('403 Forbidden')));

    expect(
      repository.streamReply('Hola'),
      emitsError(
        isA<AiFailure>().having((f) => f.cause, 'cause', isA<Exception>()),
      ),
    );
  });

  test('mantiene los AiFailure sin envolverlos otra vez', () {
    const failure = AiFailure('Sin conexión');
    when(() => dataSource.streamReply('Hola'))
        .thenAnswer((_) => Stream.error(failure));

    expect(repository.streamReply('Hola'), emitsError(same(failure)));
  });

  test('reinicia la sesión del datasource', () {
    repository.resetConversation();

    verify(() => dataSource.reset()).called(1);
  });
}
