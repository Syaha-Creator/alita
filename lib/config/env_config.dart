import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized helper to load and access values from the .env file.
class EnvConfig {
  EnvConfig._internal();

  static final EnvConfig _instance = EnvConfig._internal();
  factory EnvConfig() => _instance;

  bool _isLoaded = false;

  /// Load environment variables from the .env file (idempotent).
  Future<void> load({String fileName = '.env'}) async {
    if (_isLoaded) return;
    await dotenv.load(fileName: fileName);
    _isLoaded = true;
  }

  /// Retrieve a required environment variable.
  ///
  /// Throws [StateError] if variable is missing and no fallback provided.
  String get(String key, {String? fallback, bool required = true}) {
    final value = dotenv.maybeGet(key) ?? fallback;
    if (value == null || value.isEmpty) {
      if (required) {
        throw StateError('Environment variable "$key" is missing.');
      }
      return '';
    }
    return value;
  }

  /// Convenience method to check whether a key exists.
  bool containsKey(String key) => dotenv.maybeGet(key) != null;
}
