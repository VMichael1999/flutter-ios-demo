import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

import '../../features/assistant/data/datasources/ai_remote_datasource.dart';
import '../../features/assistant/data/datasources/fake_ai_datasource.dart';
import '../../features/assistant/data/datasources/firebase_ai_datasource.dart';
import '../../features/assistant/data/repositories/ai_repository_impl.dart';
import '../../features/assistant/data/tools/nova_toolbox.dart';
import '../../features/assistant/domain/repositories/ai_repository.dart';
import '../../features/assistant/domain/usecases/reset_conversation.dart';
import '../../features/assistant/domain/usecases/send_message.dart';
import '../../features/assistant/presentation/bloc/chat_bloc.dart';
import '../../features/places/data/datasources/places_remote_datasource.dart';
import '../../features/places/data/repositories/places_repository_impl.dart';
import '../../features/places/domain/repositories/places_repository.dart';
import '../../features/places/domain/usecases/search_nearby_places.dart';
import '../config/app_config.dart';
import '../services/location_service.dart';

final getIt = GetIt.instance;

/// Registra las dependencias de la app.
///
/// Con [useFirebaseAi] en `false` NOVA usa respuestas simuladas, lo que
/// permite ejecutar la app y los tests sin un proyecto de Firebase.
Future<void> configureDependencies({required bool useFirebaseAi}) async {
  await getIt.reset();

  getIt
    ..registerSingleton<AiMode>(useFirebaseAi ? AiMode.firebase : AiMode.demo)
    // Ubicación y lugares.
    ..registerLazySingleton<http.Client>(http.Client.new)
    ..registerLazySingleton<LocationService>(
      () => const GeolocatorLocationService(),
    )
    ..registerLazySingleton<PlacesRemoteDataSource>(
      () => OverpassPlacesDataSource(getIt()),
    )
    ..registerLazySingleton<PlacesRepository>(
      () => PlacesRepositoryImpl(getIt()),
    )
    ..registerLazySingleton(
      () => SearchNearbyPlaces(locationService: getIt(), repository: getIt()),
    )
    // Cada chat recibe su propia sesión, por eso la cadena se registra como
    // factory: el historial de una conversación no se mezcla con otra.
    ..registerFactory<AiRemoteDataSource>(
      () => useFirebaseAi
          ? FirebaseAiDataSource(toolbox: NovaToolbox(getIt()))
          : FakeAiDataSource(),
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
