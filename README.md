# NOVA AI

Asistente móvil inteligente desarrollado en Flutter. NOVA entiende al usuario
mediante lenguaje natural y, en próximas versiones, podrá usar la cámara, la
voz, documentos y la ubicación para ejecutar acciones reales en el dispositivo.

> El usuario dice lo que necesita, NOVA entiende la intención y el teléfono
> ejecuta la acción.

## Estado: Sprint 1 (MVP 0.1 en curso)

- [x] Proyecto Flutter y repositorio en GitHub
- [x] Clean Architecture organizada por features
- [x] Navegación con `go_router`
- [x] Theme y Design System (Material 3, claro y oscuro)
- [x] Splash, Onboarding y Home
- [x] Pantalla de chat con BLoC
- [x] Streaming de respuestas, indicador de escritura y cancelación
- [ ] Conectar Gemini mediante Firebase AI Logic (pendiente de configurar Firebase)

Mientras Firebase no esté configurado la app arranca en **modo demo** con
respuestas simuladas, así la interfaz y los tests funcionan sin credenciales.

## Stack

| Área | Tecnología |
| --- | --- |
| UI | Flutter, Material 3 |
| Estado | `flutter_bloc` |
| Navegación | `go_router` |
| Inyección de dependencias | `get_it` |
| IA | Gemini vía Firebase AI Logic (`firebase_ai`) |
| Tests | `flutter_test`, `bloc_test`, `mocktail` |
| Builds iOS sin Mac | [ios-builder](https://github.com/MobAI-App/ios-builder) + MobAI |

## Arquitectura

```text
lib/
├── core/            # config, DI, errores, router y theme
├── features/
│   ├── splash/
│   ├── onboarding/
│   ├── home/
│   └── assistant/
│       ├── data/          # datasources (Firebase AI, demo) y repositorio
│       ├── domain/        # entidades, contrato del repositorio y casos de uso
│       └── presentation/  # BLoC, páginas y widgets
├── shared/widgets/
├── app.dart
└── main.dart
```

Flujo de un mensaje:

```text
ChatPage → ChatBloc → SendMessage → AiRepository → AiRemoteDataSource → Gemini
```

## Ejecutar

```bash
flutter pub get
flutter run
```

Variables opcionales con `--dart-define`:

- `NOVA_ENV`: `dev` (por defecto), `qa` o `prod`.
- `NOVA_GEMINI_MODEL`: modelo de Gemini (por defecto `gemini-3.1-flash-lite`).

## Tests

```bash
flutter analyze
flutter test
```

## Conectar Firebase AI Logic

1. Crear un proyecto en la [consola de Firebase](https://console.firebase.google.com)
   y activar **AI Logic** con la **Gemini Developer API**.
2. Instalar las CLIs: `npm install -g firebase-tools` y
   `dart pub global activate flutterfire_cli`.
3. Iniciar sesión con `firebase login` y ejecutar `flutterfire configure`.
4. Pasar `DefaultFirebaseOptions.currentPlatform` a `Firebase.initializeApp`
   en `lib/main.dart`.

La API key de Gemini se queda en Firebase: nunca se incluye en el código de la app.

## Probar en iOS desde Windows

```bash
builder ios share
```

Compila en GitHub Actions y publica un simulador de iOS en MobAI (**CI Devices**).
