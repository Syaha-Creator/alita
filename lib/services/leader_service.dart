import 'package:flutter/foundation.dart';
import '../features/approval/data/models/approval_model.dart';
import 'api_client.dart';
import 'auth_service.dart';

class LeaderService {
  final ApiClient _apiClient;

  LeaderService(this._apiClient);

  /// Fetch leader data by user ID
  Future<LeaderByUserModel?> getLeaderByUser({String? userId}) async {
    try {
      final token = await AuthService.getToken();
      final currentUserId =
          userId ?? (await AuthService.getCurrentUserId())?.toString();

      if (token == null || currentUserId == null) {
        if (kDebugMode) {
          print(
              '[DEBUG] LeaderService.getLeaderByUser: Token or userId is null');
        }
        return null;
      }

      if (kDebugMode) {
        print(
            '[DEBUG] LeaderService.getLeaderByUser: Fetching leader data for userId: $currentUserId');
      }

      final response = await _apiClient.getLeaderByUser(
        token: token,
        userId: currentUserId,
      );

      if (kDebugMode) {
        print('[DEBUG] LeaderService.getLeaderByUser: RAW API Response:');
        print('  - response[result]: ${response['result']}');
        if (response['result'] != null) {
          final result = response['result'];
          print('  - RAW user: ${result['user']}');
          print('  - RAW direct_leader: ${result['direct_leader']}');
          print('  - RAW indirect_leader: ${result['indirect_leader']}');
          print('  - RAW analyst: ${result['analyst']}');
          print('  - RAW controller: ${result['controller']}');
        }
      }

      if (response['result'] != null) {
        final leaderData = LeaderByUserModel.fromJson(response['result']);
        if (kDebugMode) {
          print(
              '[DEBUG] LeaderService.getLeaderByUser: Successfully fetched leader data:');
          print(
              '  - User: ${leaderData.user.fullName} (ID: ${leaderData.user.id}, Title: ${leaderData.user.workTitle})');
          if (leaderData.directLeader != null) {
            print(
                '  - Direct Leader: ${leaderData.directLeader!.fullName} (ID: ${leaderData.directLeader!.id}, Title: ${leaderData.directLeader!.workTitle})');
          } else {
            print('  - Direct Leader: null');
          }
          if (leaderData.indirectLeader != null) {
            print(
                '  - Indirect Leader: ${leaderData.indirectLeader!.fullName} (ID: ${leaderData.indirectLeader!.id}, Title: ${leaderData.indirectLeader!.workTitle})');
          } else {
            print('  - Indirect Leader: null');
          }
          if (leaderData.analyst != null) {
            print(
                '  - Analyst: ${leaderData.analyst!.fullName} (ID: ${leaderData.analyst!.id}, Title: ${leaderData.analyst!.workTitle})');
          } else {
            print('  - Analyst: null');
          }
          if (leaderData.controller != null) {
            print(
                '  - Controller: ${leaderData.controller!.fullName} (ID: ${leaderData.controller!.id}, Title: ${leaderData.controller!.workTitle})');
          } else {
            print('  - Controller: null');
          }

          // Validation: Check if direct_leader and indirect_leader are the same (potential data issue)
          if (leaderData.directLeader != null &&
              leaderData.indirectLeader != null) {
            if (leaderData.directLeader!.id == leaderData.indirectLeader!.id) {
              print(
                  '  - [WARNING] Direct Leader dan Indirect Leader memiliki ID yang sama! '
                  'ID: ${leaderData.directLeader!.id}. '
                  'Ini mungkin masalah data di backend.');
            }
            if (leaderData.directLeader!.fullName ==
                leaderData.indirectLeader!.fullName) {
              print(
                  '  - [WARNING] Direct Leader dan Indirect Leader memiliki nama yang sama! '
                  'Nama: ${leaderData.directLeader!.fullName}. '
                  'Cek data work_experience user di backend.');
            }
          }
        }
        return leaderData;
      }

      if (kDebugMode) {
        print('[DEBUG] LeaderService.getLeaderByUser: Response result is null');
      }
      return null;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print(
            '[DEBUG] LeaderService.getLeaderByUser: Error fetching leader data: $e');
        print('[DEBUG] StackTrace: $stackTrace');
      }
      // Don't rethrow the exception, just return null to prevent app crash
      return null;
    }
  }

  /// Get leader ID based on discount level
  int? getLeaderIdByDiscountLevel(
      LeaderByUserModel? leaderData, int discountLevel) {
    if (leaderData == null) return null;

    switch (discountLevel) {
      case 1: // Diskon 1 - User sendiri
        return leaderData.user.id;
      case 2: // Diskon 2 - Direct Leader
        return leaderData.directLeader?.id;
      case 3: // Diskon 3 - Indirect Leader
        return leaderData.indirectLeader?.id;
      case 4: // Diskon 4 - Analyst
        return leaderData.analyst?.id; // analyst from JSON
      case 5: // Diskon 5 - Controller
        return leaderData.controller?.id; // controller from JSON
      default:
        return null;
    }
  }

  /// Get leader name based on discount level
  String? getLeaderNameByDiscountLevel(
      LeaderByUserModel? leaderData, int discountLevel) {
    if (leaderData == null) return null;

    switch (discountLevel) {
      case 1: // Diskon 1 - User sendiri
        return leaderData.user.fullName;
      case 2: // Diskon 2 - Direct Leader
        return leaderData.directLeader?.fullName;
      case 3: // Diskon 3 - Indirect Leader
        return leaderData.indirectLeader?.fullName;
      case 4: // Diskon 4 - Analyst
        return leaderData.analyst?.fullName; // analyst from JSON
      case 5: // Diskon 5 - Controller
        return leaderData.controller?.fullName; // controller from JSON
      default:
        return null;
    }
  }

  /// Get leader work title based on discount level
  String? getLeaderWorkTitleByDiscountLevel(
      LeaderByUserModel? leaderData, int discountLevel) {
    if (leaderData == null) return null;

    switch (discountLevel) {
      case 1: // Diskon 1 - User sendiri
        return leaderData.user.workTitle;
      case 2: // Diskon 2 - Direct Leader
        return leaderData.directLeader?.workTitle;
      case 3: // Diskon 3 - Indirect Leader
        return leaderData.indirectLeader?.workTitle;
      case 4: // Diskon 4 - Analyst
        return leaderData.analyst?.workTitle; // analyst from JSON
      case 5: // Diskon 5 - Controller
        return leaderData.controller?.workTitle; // controller from JSON
      default:
        return null;
    }
  }
}
