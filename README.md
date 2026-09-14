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
- [x] Gemini mediante Firebase AI Logic, protegido con App Check
- [x] Lugares cercanos desde el chat (function calling + GPS + OpenStreetMap)
- [x] Permisos nativos: Internet, ubicación, cámara, micrófono y notificaciones

## Fotos e imágenes

En el chat, el botón de imagen permite **tomar una foto** o **elegirla de la
galería** (también desde el acceso rápido **Cámara** de la home). La imagen se
envía a Gemini junto con tu pregunta; si no escribes nada, NOVA pregunta
*"¿Qué hay en esta imagen?"*.

- **Local en una foto**: Gemini lee el nombre del letrero y llama a
  `buscarLugaresCercanos` con ese nombre para ubicarlo a menos de 5 km y
  ofrecer **Cómo llegar**.
- **Facturas y recibos**: extrae monto, moneda, fechas y concepto, e indica si
  algún dato no se lee.
- Las fotos se reducen a 1600 px (calidad 85) antes de enviarse.
- En Android no se declara el permiso `CAMERA`: `image_picker` usa la app de
  cámara del sistema, y declararlo sin pedirlo haría fallar la cámara.

## Lugares cerca de mí

Si escribes en el chat algo como *"Busca restaurantes cerca de mí"*, Gemini
llama a la función `buscarLugaresCercanos` de NOVA:

```text
Usuario → Gemini → buscarLugaresCercanos(categoria, radioMetros)
        → GPS (geolocator) → Overpass/OpenStreetMap
        → 5 lugares más cercanos (máx. 5 km) → Gemini responde + tarjetas en el chat
```

- Busca primero a 1 km, luego a 2,5 km y hasta 5 km solo si faltan resultados.
- Ordena por distancia real (Haversine) y quita locales duplicados.
- Categorías: restaurantes, cafeterías, comida rápida, bares, farmacias,
  hospitales, bancos, cajeros, gasolineras, supermercados, parques y hoteles.
- Cada tarjeta muestra la distancia y un botón **Cómo llegar** (Google Maps).
- OpenStreetMap es gratuito y no necesita API key; si un servidor de Overpass
  está saturado se prueba el siguiente.

En plataformas sin configuración de Firebase la app arranca en **modo demo** con
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
cp .env.example .env   # en Windows: copy .env.example .env
flutter run --dart-define-from-file=.env
```

La configuración vive en `.env`, que **nunca se sube a GitHub** (está en
`.gitignore`); `.env.example` es la plantilla con todas las variables:

| Variable | Uso |
| --- | --- |
| `NOVA_ENV` | `dev`, `qa` o `prod` |
| `NOVA_GEMINI_MODEL` | Modelo de Gemini (por defecto `gemini-3.1-flash-lite`) |
| `NOVA_APP_CHECK_DEBUG` | `true` para usar tokens de depuración de App Check |
| `NOVA_RECAPTCHA_SITE_KEY` | Clave de sitio de reCAPTCHA Enterprise (web en producción) |

> Todo lo que se compila dentro de la app puede extraerse del APK. Las claves
> privadas de servicios de pago (OpenAI, Anthropic, Google Places) no van en
> `.env`: deben guardarse en un servidor, por ejemplo Cloud Functions.

## Tests

```bash
flutter analyze
flutter test
```

## Firebase AI Logic y App Check

NOVA usa el proyecto de Firebase `nova-ai-7b36c` con **AI Logic (Gemini Developer
API)**. La configuración de web, Android e iOS está en `lib/firebase_options.dart`;
la API key de Gemini se queda en Firebase y nunca se incluye en la app.

AI Logic exige **App Check**: sin un token válido Gemini responde `401`.

- **Desarrollo** (`flutter run` en debug o `--dart-define=NOVA_APP_CHECK_DEBUG=true`):
  se usan los proveedores de depuración. Al arrancar, la app imprime un
  *debug token*; regístralo en la consola en **App Check → Apps → ⋮ →
  Administrar tokens de depuración**. Nunca lo subas al repositorio y bórralo
  al terminar.
- **Producción**: Play Integrity (Android), App Attest con DeviceCheck de
  respaldo (iOS) y reCAPTCHA Enterprise en web con
  `--dart-define=NOVA_RECAPTCHA_SITE_KEY=<clave de sitio>`.

Probar la web en local con App Check en modo depuración:

```bash
flutter build web --release --dart-define=NOVA_APP_CHECK_DEBUG=true
python -m http.server 8080 --directory build/web
```

## Probar en iOS desde Windows

```bash
builder ios share
```

Compila en GitHub Actions y publica un simulador de iOS en MobAI (**CI Devices**).
