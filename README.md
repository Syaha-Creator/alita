# Alitapricelist

A Flutter application for viewing, filtering, and managing price list data with discount calculation, installment options, and approval flows. The project uses Clean Architecture with BLoC and GetIt for dependency injection.

## Requirements
- Flutter SDK (matching project constraint in `pubspec.yaml`, currently Dart ^3.6.1)
- Xcode / Android Studio toolchains for iOS/Android builds
- `.env` file with API credentials:
  - `API_CLIENT_ID`
  - `API_CLIENT_SECRET`

## Setup
1) Install dependencies  
   `flutter pub get`

2) Prepare environment variables  
   - Create `.env` at project root with required keys (see above).
   - For tests, a stub file exists at `test/.env_test` (already used by tests; no change needed unless keys differ).

3) Generate mock files (when modifying mockito annotations)  
   `flutter pub run build_runner build --delete-conflicting-outputs`

## Running the app
```
flutter run
```
You may set a specific device with `-d <device_id>`.

## Testing
- Run all tests:  
  `flutter test test/`

- Run a single suite:  
  `flutter test test/<path_to_test>.dart`

- Generate coverage (HTML):  
  ```
  flutter test --coverage
  genhtml coverage/lcov.info -o coverage/html
  open coverage/html/index.html
  ```

### Notable test notes
- Repository tests:
  - `ProductRepository` tests rely on SharedPreferences mocks; some “happy-path” cases are skipped in CI due to env/prefs variability.
  - `AuthRepository` tests load `test/.env_test` to satisfy ApiConfig credentials.
  - `ApprovalRepository` uses constructor injection for `OrderLetterService` to allow mocking.
- Widget/integration tests: all previously skipped widget tests are now active; background timers are advanced in tests to avoid pending timers.

## Architecture & DI
- **State management**: BLoC
- **DI container**: GetIt (`lib/config/dependency_injection.dart`)
- **Key refactors**: `ProductBloc`, `ApprovalBloc`, and `ApprovalRepository` use constructor injection for testability.

## Features (high level)
- Dynamic filtering by area, brand, channel, bed configuration
- Discount calculation and net price display
- Installment options
- Approvals monitoring and timelines

## Useful paths
- Coverage report: `coverage/html/index.html` (after running coverage command)
- Env for tests: `test/.env_test`
- DI setup: `lib/config/dependency_injection.dart`
- Repositories: `lib/features/**/data/repositories/`
- BLoC: `lib/features/**/presentation/bloc/`

## Troubleshooting
- “command not found: genhtml”: install lcov (e.g., `brew install lcov`) then rerun coverage generation.
- Missing env vars: ensure `.env` exists with API keys; tests use `test/.env_test`.
