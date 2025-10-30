import '../features/approval/data/models/team_hierarchy_model.dart';
import 'api_client.dart';
import 'auth_service.dart';

class TeamHierarchyService {
  final ApiClient _apiClient;

  TeamHierarchyService(this._apiClient);

  /// Fetch team hierarchy data by user ID
  Future<TeamHierarchyModel?> getTeamHierarchy({String? userId}) async {
    try {
      final token = await AuthService.getToken();
      final currentUserId =
          userId ?? (await AuthService.getCurrentUserId())?.toString();

      if (token == null || currentUserId == null) {
        return null;
      }

      final response = await _apiClient.getTeamHierarchy(
        token: token,
        userId: currentUserId,
      );

      if (response['status'] == 'Success') {
        final teamData = TeamHierarchyModel.fromJson(response);
        return teamData;
      }

      return null;
    } catch (e) {
      // Don't rethrow the exception, just return null to prevent app crash
      return null;
    }
  }

  /// Get all subordinate user IDs for the current user
  Future<List<int>> getSubordinateUserIds({String? userId}) async {
    try {
      final teamData = await getTeamHierarchy(userId: userId);
      if (teamData != null) {
        return teamData.getAllSubordinateUserIds();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Check if current user has subordinates
  Future<bool> hasSubordinates({String? userId}) async {
    try {
      final teamData = await getTeamHierarchy(userId: userId);
      return teamData?.hasSubordinates() ?? false;
    } catch (e) {
      return false;
    }
  }
}
