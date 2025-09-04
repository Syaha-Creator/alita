import 'package:googleapis_auth/auth_io.dart';
import '../config/firebase_credentials.dart';

class PushNotificationService {
  static Future<String> getAccessToken() async {
    try {
      final scopes = [
        "https://www.googleapis.com/auth/userinfo.email",
        "https://www.googleapis.com/auth/firebase.database",
        "https://www.googleapis.com/auth/firebase.messaging"
      ];

      final client = await clientViaServiceAccount(
        ServiceAccountCredentials.fromJson(FirebaseCredentials.serviceAccount),
        scopes,
      );

      final accessServerKey = client.credentials.accessToken.data;
      return accessServerKey;
    } catch (e) {
      print('PushNotificationService: Error getting access token: $e');
      rethrow;
    }
  }
}
