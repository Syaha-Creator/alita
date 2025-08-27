import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'push_notif_service.dart';

class SendNotificationService {
  static Future<bool> sendNotificationUsingApi({
    required String? token,
    required String? title,
    required String? body,
    required Map<String, dynamic>? data,
  }) async {
    try {
      String serverKey = await PushNotifService().getServerKeyToken();

      if (kDebugMode) {
        print("FCM Server Key: ${serverKey.substring(0, 20)}...");
      }

      String url =
          "https://fcm.googleapis.com/v1/projects/alita-pricelist/messages:send";

      var headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $serverKey',
      };

      // Message structure
      Map<String, dynamic> message = {
        "message": {
          "token": token,
          "notification": {"body": body, "title": title},
          "data": data,
          "android": {
            "priority": "high",
            "notification": {
              "channel_id": "alita_fcm_notifications",
              "default_sound": true,
              "default_vibrate_timings": true,
            },
          },
          "apns": {
            "headers": {
              "apns-priority": "10",
            },
            "payload": {
              "aps": {
                "sound": "default",
                "badge": 1,
              },
            },
          },
        }
      };

      if (kDebugMode) {
        print("FCM Message: $message");
      }

      // Hit API
      final Dio dio = Dio();
      final Response response = await dio.post(
        url,
        data: message,
        options: Options(
          headers: headers,
        ),
      );

      if (kDebugMode) {
        print("FCM Response Status: ${response.statusCode}");
        print("FCM Response Body: ${response.data}");
      }

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print("Notification Send Successfully!");
        }
        return true;
      } else {
        if (kDebugMode) {
          print("Notification not send! Status: ${response.statusCode}");
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error sending notification: $e");
      }
      return false;
    }
  }

  // Send to multiple devices
  static Future<bool> sendNotificationToMultipleDevices({
    required List<String> tokens,
    required String? title,
    required String? body,
    required Map<String, dynamic>? data,
  }) async {
    try {
      if (tokens.isEmpty) {
        if (kDebugMode) {
          print("No tokens provided");
        }
        return false;
      }

      // For multiple devices, we need to send individually or use batch
      // For now, let's send individually
      bool allSuccess = true;

      for (String token in tokens) {
        final success = await sendNotificationUsingApi(
          token: token,
          title: title,
          body: body,
          data: data,
        );

        if (!success) {
          allSuccess = false;
          if (kDebugMode) {
            print("Failed to send to token: ${token.substring(0, 20)}...");
          }
        }
      }

      if (kDebugMode) {
        if (allSuccess) {
          print(
              "All notifications sent successfully to ${tokens.length} devices");
        } else {
          print("Some notifications failed to send");
        }
      }

      return allSuccess;
    } catch (e) {
      if (kDebugMode) {
        print("Error sending notifications to multiple devices: $e");
      }
      return false;
    }
  }
}
