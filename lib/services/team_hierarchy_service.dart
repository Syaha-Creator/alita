import '../features/approval/data/models/team_hierarchy_model.dart';
import 'api_client.dart';
import 'auth_service.dart';

class TeamHierarchyService {
  final ApiClient _apiClient;

  // Cache for team hierarchy data
  TeamHierarchyModel? _cachedTeamHierarchy;
  String? _cachedUserId;
  DateTime? _cacheTimestamp;
  static const Duration _cacheValidDuration = Duration(minutes: 30);

  TeamHierarchyService(this._apiClient);

  /// Fetch team hierarchy data by user ID with caching
  Future<TeamHierarchyModel?> getTeamHierarchy(
      {String? userId, bool forceRefresh = false}) async {
    try {
      final currentUserId =
          userId ?? (await AuthService.getCurrentUserId())?.toString();

      if (currentUserId == null) {
        return null;
      }

      // Check cache first
      if (!forceRefresh &&
          _cachedTeamHierarchy != null &&
          _cachedUserId == currentUserId &&
          _cacheTimestamp != null) {
        final now = DateTime.now();
        final difference = now.difference(_cacheTimestamp!);
        if (difference.compareTo(_cacheValidDuration) < 0) {
          // Cache is still valid
          return _cachedTeamHierarchy;
        }
      }

      // Cache expired or force refresh, fetch new data
      final token = await AuthService.getToken();
      if (token == null) {
        return _cachedTeamHierarchy; // Return cached data if available
      }

      final response = await _apiClient.getTeamHierarchy(
        token: token,
        userId: currentUserId,
      );

      if (response['status'] == 'Success') {
        final teamData = TeamHierarchyModel.fromJson(response);

        // Update cache
        _cachedTeamHierarchy = teamData;
        _cachedUserId = currentUserId;
        _cacheTimestamp = DateTime.now();

        return teamData;
      }

      // Return cached data if API fails
      return _cachedTeamHierarchy;
    } catch (e) {
      // Return cached data if available, otherwise null
      return _cachedTeamHierarchy;
    }
  }

  /// Clear team hierarchy cache
  void clearCache() {
    _cachedTeamHierarchy = null;
    _cachedUserId = null;
    _cacheTimestamp = null;
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
