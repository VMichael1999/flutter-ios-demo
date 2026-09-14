import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/assistant/presentation/bloc/chat_bloc.dart';
import '../../features/assistant/presentation/pages/chat_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../config/app_config.dart';
import '../di/injection.dart';
import 'app_routes.dart';

GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.chat,
        builder: (context, state) {
          final options = switch (state.extra) {
            final ChatLaunchOptions options => options,
            final String prompt => ChatLaunchOptions(prompt: prompt),
            _ => const ChatLaunchOptions(),
          };
          return BlocProvider(
            create: (_) => getIt<ChatBloc>(),
            child: ChatPage(
              mediaPicker: getIt(),
              initialPrompt: options.prompt,
              initialDraft: options.draft,
              pickImageOnOpen: options.pickImage,
              aiMode: getIt<AiMode>(),
            ),
          );
        },
      ),
    ],
  );
}
