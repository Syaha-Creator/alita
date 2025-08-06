import '../features/approval/data/models/approval_model.dart';
import 'api_client.dart';
import 'auth_service.dart';

class LeaderService {
  final ApiClient _apiClient;

  LeaderService(this._apiClient);

  /// Fetch leader data by user ID
  Future<LeaderByUserModel?> getLeaderByUser({int? userId}) async {
    try {
      final token = await AuthService.getToken();
      final currentUserId = userId ?? await AuthService.getCurrentUserId();

      if (token == null || currentUserId == null) {
        print('LeaderService: Token or current user ID is null');
        return null;
      }

      print('LeaderService: Getting leader data for user ID: $currentUserId');

      final response = await _apiClient.getLeaderByUser(
        token: token,
        userId: currentUserId,
      );

      print('LeaderService: API response: $response');

      if (response['result'] != null) {
        final leaderData = LeaderByUserModel.fromJson(response['result']);
        print('LeaderService: Parsed leader data: $leaderData');
        return leaderData;
      }

      print('LeaderService: No result found in response');
      return null;
    } catch (e) {
      print('LeaderService: Error getting leader data: $e');
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
      case 4: // Diskon 4 - Controller
        return leaderData.controller?.id;
      case 5: // Diskon 5 - Analyst
        return leaderData.analyst?.id;
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
      case 4: // Diskon 4 - Controller
        return leaderData.controller?.fullName;
      case 5: // Diskon 5 - Analyst
        return leaderData.analyst?.fullName;
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
      case 4: // Diskon 4 - Controller
        return leaderData.controller?.workTitle;
      case 5: // Diskon 5 - Analyst
        return leaderData.analyst?.workTitle;
      default:
        return null;
    }
  }
}
