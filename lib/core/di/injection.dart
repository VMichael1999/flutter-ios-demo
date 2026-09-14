import 'package:get_it/get_it.dart';

import '../../features/assistant/data/datasources/ai_remote_datasource.dart';
import '../../features/assistant/data/datasources/fake_ai_datasource.dart';
import '../../features/assistant/data/datasources/firebase_ai_datasource.dart';
import '../../features/assistant/data/repositories/ai_repository_impl.dart';
import '../../features/assistant/domain/repositories/ai_repository.dart';
import '../../features/assistant/domain/usecases/reset_conversation.dart';
import '../../features/assistant/domain/usecases/send_message.dart';
import '../../features/assistant/presentation/bloc/chat_bloc.dart';
import '../config/app_config.dart';

final getIt = GetIt.instance;

/// Registra las dependencias de la app.
///
/// Con [useFirebaseAi] en `false` NOVA usa respuestas simuladas, lo que
/// permite ejecutar la app y los tests sin un proyecto de Firebase.
Future<void> configureDependencies({required bool useFirebaseAi}) async {
  await getIt.reset();

  getIt
    ..registerSingleton<AiMode>(useFirebaseAi ? AiMode.firebase : AiMode.demo)
    // Cada chat recibe su propia sesión, por eso la cadena se registra como
    // factory: el historial de una conversación no se mezcla con otra.
    ..registerFactory<AiRemoteDataSource>(
      () => useFirebaseAi ? FirebaseAiDataSource() : FakeAiDataSource(),
    )
    ..registerFactory<AiRepository>(() => AiRepositoryImpl(getIt()))
    ..registerFactory<ChatBloc>(() {
      final repository = getIt<AiRepository>();
      return ChatBloc(
        sendMessage: SendMessage(repository),
        resetConversation: ResetConversation(repository),
      );
    });
}
