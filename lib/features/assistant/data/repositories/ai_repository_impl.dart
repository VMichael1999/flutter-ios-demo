import 'package:flutter/foundation.dart';

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
    } catch (error, stackTrace) {
      debugPrint('Error al contactar la IA: $error\n$stackTrace');
      throw AiFailure(_userMessageFor(error), cause: error);
    }
  }

  static String _userMessageFor(Object error) {
    final details = error.toString();
    const accessErrors = ['App Check', 'UNAUTHENTICATED', 'PERMISSION_DENIED'];
    if (accessErrors.any(details.contains)) {
      return 'NOVA no tiene acceso a la IA en este momento. '
          'Revisa la configuración de Firebase.';
    }
    return 'NOVA no pudo responder. Revisa tu conexión e inténtalo de nuevo.';
  }

  @override
  void resetConversation() => _dataSource.reset();
}
