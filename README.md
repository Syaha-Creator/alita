# Alita Pricelist

A Flutter application for viewing, filtering, and managing price list data with discount calculation, installment options, and approval flows. The project uses **Riverpod** for state management and **GoRouter** for navigation.

## Requirements

- Flutter SDK (matching project constraint in `pubspec.yaml`, currently Dart ^3.6.1)
- Xcode / Android Studio toolchains for iOS/Android builds
- `.env` file with API credentials (see Setup below)
- Firebase (run `flutterfire configure` after clone)

## Setup

1. **Install dependencies**
   ```bash
   flutter pub get
   ```

2. **Prepare environment variables**
   - Copy `.env.example` to `.env` at project root
   - Fill in required keys (see `.env.example` for full list):
     - `API_BASE_URL` — Alita (Ruby) API base URL
     - `CLIENT_ID` — API client ID
     - `CLIENT_SECRET` — API client secret
     - Optional: Comforta, Region API, Firebase credentials
   - Tests load credentials via `dotenv.testLoad()` inline — no separate test env file needed

3. **Firebase (required after fresh clone)**
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   This generates `lib/firebase_options.dart`, `android/app/google-services.json`, and `ios/Runner/GoogleService-Info.plist`.

4. **Generate code (when modifying freezed/json_serializable)**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

## Running the app

```bash
flutter run
```

Use `-d <device_id>` to target a specific device.

## Release builds (secrets)

**Do not** bake real credentials from `.env` into release artifacts. Use `--dart-define` to inject secrets at build time (from CI secrets or a local script):

```bash
flutter build apk --dart-define=API_BASE_URL=https://api.example.com \
  --dart-define=CLIENT_ID=your_client_id \
  --dart-define=CLIENT_SECRET=your_client_secret
```

`AppConfig` reads `--dart-define` first, then falls back to `.env`. When all required vars are passed via `--dart-define`, `.env` is never used and is not bundled.

Required for production: `API_BASE_URL`, `CLIENT_ID`, `CLIENT_SECRET`. Optional: Comforta and Region API vars (see `.env.example`).

## Testing

```bash
# Run all tests
flutter test

# Run a single suite
flutter test test/<path_to_test>.dart

# Generate coverage (HTML)
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Test setup

- Unit/widget tests use `dotenv.testLoad(fileInput: '...')` with inline credentials where needed
- Integration tests run against the app shell with optional API mocking

### Accessibility

- Icon-only buttons use `tooltip` for screen readers
- Test checkout at maximum text scale: Settings → Display → Font size (largest), or use `MediaQuery.withClampedTextScaling`
- Key flows (login, product detail, checkout) use semantic labels on controls

### Troubleshooting

- **"command not found: genhtml"** — Install lcov (e.g. `brew install lcov`) then rerun coverage generation
- **Missing env vars** — Ensure `.env` exists with `API_BASE_URL`, `CLIENT_ID`, `CLIENT_SECRET` at minimum

## Architecture

- **State management:** Riverpod (`StateNotifierProvider`, `AsyncNotifierProvider`, etc.)
- **Navigation:** GoRouter
- **Structure:** Feature-first under `lib/features/` (auth, cart, checkout, pricelist, approval, history, quotation, profile, favorites)
- **Shared:** `lib/core/` — config, services, theme, widgets, router

### Key paths

- Config: `lib/core/config/app_config.dart`
- Router: `lib/core/router/app_router.dart`
- Auth: `lib/features/auth/logic/auth_provider.dart`
- Features: `lib/features/<feature>/data/`, `logic/`, `presentation/`

## Features (high level)

- Dynamic filtering by area, brand, channel, bed configuration
- Discount calculation and net price display
- Installment options
- Approvals monitoring and timelines
- Cart, checkout, order history
- Quotation management
- Profile and help center

## Useful paths

- Coverage report: `coverage/html/index.html` (after `flutter test --coverage`)
- Env template: `.env.example`
- Core widgets: `lib/core/widgets/`
- API client: `lib/core/services/api_client.dart`
