// // Firebase Credentials Configuration
// // This file now uses environment variables for security
// // CRITICAL: Never commit actual credentials to version control

import 'env_config.dart';

/// Provides Firebase service account credentials sourced from environment variables.
class FirebaseCredentials {
  FirebaseCredentials._();

  static final EnvConfig _env = EnvConfig();

  /// Returns the Firebase project ID.
  static String get projectId => _env.get('FIREBASE_PROJECT_ID');

  /// Builds the service account credential map required by googleapis_auth.
  static Map<String, dynamic> get serviceAccount => {
        'type': 'service_account',
        'project_id': projectId,
        'private_key_id': _env.get('FIREBASE_PRIVATE_KEY_ID'),
        'private_key': _normalizePrivateKey(
          _env.get('FIREBASE_PRIVATE_KEY'),
        ),
        'client_email': _env.get('FIREBASE_CLIENT_EMAIL'),
        'client_id': _env.get('FIREBASE_CLIENT_ID'),
        'auth_uri': _env.get('FIREBASE_AUTH_URI'),
        'token_uri': _env.get('FIREBASE_TOKEN_URI'),
        'auth_provider_x509_cert_url':
            _env.get('FIREBASE_AUTH_PROVIDER_X509_CERT_URL'),
        'client_x509_cert_url': _env.get('FIREBASE_CLIENT_X509_CERT_URL'),
        'universe_domain': _env.get('FIREBASE_UNIVERSE_DOMAIN'),
      };

  /// Convert escaped newlines ("\n") into actual newline characters.
  static String _normalizePrivateKey(String key) => key.replaceAll(r'\n', '\n');
}
