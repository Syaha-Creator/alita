import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../features/approval/data/models/device_token_model.dart';
import '../config/api_config.dart';
import 'api_client.dart';

class DeviceTokenService {
  static final DeviceTokenService _instance = DeviceTokenService._internal();
  factory DeviceTokenService() => _instance;
  DeviceTokenService._internal();

  final ApiClient _apiClient = ApiClient();

  // Get device tokens for specific user
  Future<List<DeviceTokenModel>> getDeviceTokens(String userId) async {
    try {
      // Get current auth token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        if (kDebugMode) {
          if (kDebugMode) {
            print('No auth token found');
          }
        }
        return [];
      }

      final url = ApiConfig.getDeviceTokensUrl(token: token, userId: userId);

      if (kDebugMode) {
        if (kDebugMode) {
          print('GET Device Tokens URL: $url');
        }
      }

      final response = await _apiClient.get(url);

      if (kDebugMode) {
        if (kDebugMode) {
          print('GET Device Tokens Response: ${response.statusCode}');
        }
        if (kDebugMode) {
          print('Response Body: ${response.data}');
        }
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = response.data;

        if (jsonData['result'] != null) {
          if (jsonData['result'] is List) {
            // Handle array response
            final List<dynamic> resultList = jsonData['result'];
            return resultList
                .map((json) => DeviceTokenModel.fromJson(json))
                .toList();
          } else if (jsonData['result'] is Map) {
            // Handle single object response
            final result = jsonData['result'];
            return [DeviceTokenModel.fromJson(result)];
          }
        }

        if (kDebugMode) {
          if (kDebugMode) {
            print('No result found in response or unexpected format');
          }
        }
        return [];
      } else {
        if (kDebugMode) {
          if (kDebugMode) {
            print('Error getting device tokens: ${response.statusCode}');
          }
        }
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) {
          print('Exception getting device tokens: $e');
        }
      }
      return [];
    }
  }

  // Post/Update device token
  Future<bool> postDeviceToken(String userId, String token) async {
    try {
      // Get current auth token
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token');

      if (authToken == null) {
        if (kDebugMode) {
          if (kDebugMode) {
            print('No auth token found');
          }
        }
        return false;
      }

      final url = ApiConfig.getCreateDeviceTokenUrl(token: authToken);

      if (kDebugMode) {
        print('POST Device Token URL: $url');
        print(
            'POST Device Token Body: {"user_id": "$userId", "token": "${token.substring(0, 20)}..."}');
      }

      final response = await _apiClient.post(url, data: {
        'user_id': int.parse(userId), // Convert String to int for API
        'token': token,
      });

      if (kDebugMode) {
        print('POST Device Token Response: ${response.statusCode}');
        print('Response Body: ${response.data}');
      }

      // Handle success (200, 201) and also 422 if token already exists
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else if (response.statusCode == 422) {
        // 422 might mean token already exists or validation error
        // Check response message to determine if it's actually a success
        final responseData = response.data;
        if (responseData is Map) {
          final message =
              responseData['message']?.toString().toLowerCase() ?? '';
          final error = responseData['error']?.toString().toLowerCase() ?? '';

          // Check for positive indicators (token exists/duplicate)
          final isTokenExists = message.contains('already') ||
              message.contains('duplicate') ||
              error.contains('exists') ||
              error.contains('already');

          // Check for negative indicators (save failed)
          final isSaveFailed = message.contains('not save') ||
              message.contains('failed') ||
              (message.contains('error') && !message.contains('already'));

          if (isTokenExists && !isSaveFailed) {
            if (kDebugMode) {
              print('Token already exists (422), treating as success');
            }
            return true;
          }
        }

        // 422 with "not save" or other errors should be treated as failure
        if (kDebugMode) {
          final errorMsg = responseData is Map
              ? responseData['message'] ?? 'Unknown error'
              : 'Unknown error';
          print('POST Device Token failed with 422: $errorMsg');
        }
        return false;
      } else {
        if (kDebugMode) {
          print('POST Device Token failed with status: ${response.statusCode}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Exception posting device token: $e');
      }

      // Handle DioException with 422 status
      if (e is DioException && e.response?.statusCode == 422) {
        final responseData = e.response?.data;
        if (responseData is Map) {
          final message =
              responseData['message']?.toString().toLowerCase() ?? '';
          final error = responseData['error']?.toString().toLowerCase() ?? '';

          // Check for positive indicators (token exists/duplicate)
          final isTokenExists = message.contains('already') ||
              message.contains('duplicate') ||
              error.contains('exists') ||
              error.contains('already');

          // Check for negative indicators (save failed)
          final isSaveFailed = message.contains('not save') ||
              message.contains('failed') ||
              (message.contains('error') && !message.contains('already'));

          if (isTokenExists && !isSaveFailed) {
            if (kDebugMode) {
              print('Token already exists (422), treating as success');
            }
            return true;
          }
        }

        // 422 with "not save" or other errors should be treated as failure
        if (kDebugMode) {
          print(
              'POST Device Token failed with 422: ${responseData?['message'] ?? 'Unknown error'}');
        }
      }

      return false;
    }
  }

  // Check if device token needs update
  Future<bool> checkAndUpdateToken(String userId, String currentToken) async {
    try {
      if (kDebugMode) {
        print('Checking device token for user: $userId');
        print('Current token: ${currentToken.substring(0, 20)}...');
      }

      final existingTokens = await getDeviceTokens(userId);

      if (existingTokens.isEmpty) {
        // No tokens found, create new one
        if (kDebugMode) {
          if (kDebugMode) {
            print('No existing tokens found, creating new one');
          }
        }
        return await postDeviceToken(userId, currentToken);
      }

      // Check if current token exists
      final tokenExists =
          existingTokens.any((token) => token.token == currentToken);

      if (!tokenExists) {
        // Token doesn't exist, update it
        if (kDebugMode) {
          print('Current token not found in API, updating...');
          print(
              'Existing tokens: ${existingTokens.map((t) => t.token.substring(0, 20)).toList()}');
        }
        return await postDeviceToken(userId, currentToken);
      }

      if (kDebugMode) {
        print('Token already exists in API, no update needed');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) {
          print('Exception checking/updating token: $e');
        }
      }
      return false;
    }
  }

  // Get leader user IDs (atasan, direct leader, analyst)
  Future<List<String>> getLeaderUserIds(String currentUserId) async {
    try {
      // Get current auth token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        if (kDebugMode) {
          if (kDebugMode) {
            print('No auth token found');
          }
        }
        return [];
      }

      final url =
          ApiConfig.getLeaderByUserUrl(token: token, userId: currentUserId);

      if (kDebugMode) {
        if (kDebugMode) {
          print('GET Leader User IDs URL: $url');
        }
      }

      final response = await _apiClient.get(url);

      if (kDebugMode) {
        if (kDebugMode) {
          print('GET Leader User IDs Response: ${response.statusCode}');
        }
        if (kDebugMode) {
          print('Response Body: ${response.data}');
        }
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = response.data;

        if (jsonData['result'] != null) {
          final result = jsonData['result'];
          List<String> leaderIds = [];

          // Extract user IDs from different leader types
          if (result['direct_leader'] != null &&
              result['direct_leader']['id'] != null) {
            leaderIds.add(result['direct_leader']['id'].toString());
          }
          if (result['indirect_leader'] != null &&
              result['indirect_leader']['id'] != null) {
            leaderIds.add(result['indirect_leader']['id'].toString());
          }
          if (result['controller'] != null &&
              result['controller']['id'] != null) {
            leaderIds.add(result['controller']['id'].toString());
          }
          if (result['analyst'] != null && result['analyst']['id'] != null) {
            leaderIds.add(result['analyst']['id'].toString());
          }

          if (kDebugMode) {
            if (kDebugMode) {
              print('Extracted leader IDs: $leaderIds');
            }
          }

          return leaderIds;
        }

        if (kDebugMode) {
          if (kDebugMode) {
            print('No result found in response');
          }
        }
        return [];
      } else {
        if (kDebugMode) {
          if (kDebugMode) {
            print('Error getting leader user IDs: ${response.statusCode}');
          }
        }
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) {
          print('Exception getting leader user IDs: $e');
        }
      }
      return [];
    }
  }
}
