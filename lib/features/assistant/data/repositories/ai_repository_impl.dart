import '../../../../core/errors/failures.dart';
import '../../domain/repositories/ai_repository.dart';
import '../datasources/ai_remote_datasource.dart';

class AiRepositoryImpl implements AiRepository {
  AiRepositoryImpl(this._dataSource);

  final AiRemoteDataSource _dataSource;

  @override
  Stream<String> streamReply(String message) async* {
    // `await for` en lugar de `yield*`: con `yield*` los errores del stream
    // interno se reenvían tal cual y este `try` no llega a traducirlos.
    try {
      await for (final chunk in _dataSource.streamReply(message)) {
        yield chunk;
      }
    } on AiFailure {
      rethrow;
    } catch (error) {
      throw AiFailure(
        'NOVA no pudo responder. Revisa tu conexión e inténtalo de nuevo.',
        cause: error,
      );
    }
  }

  @override
  void resetConversation() => _dataSource.reset();
}
