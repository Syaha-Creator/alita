import '../config/api_config.dart';
import 'api_client.dart';

class ContactWorkExperienceService {
  final ApiClient _apiClient;

  ContactWorkExperienceService(this._apiClient);

  Future<Map<String, dynamic>?> getContactWorkExperience({
    required String token,
    required int userId,
  }) async {
    try {
      final url = ApiConfig.getContactWorkExperienceUrl(
        token: token,
        userId: userId,
      );

      final response = await _apiClient.get(url);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data;
      }

      return null;
    } catch (e) {
      print('Error fetching contact work experience: $e');
      return null;
    }
  }

  // Helper method to get user's job level
  Future<int?> getUserJobLevel({
    required String token,
    required int userId,
  }) async {
    try {
      final data = await getContactWorkExperience(token: token, userId: userId);

      if (data != null && data['result'] != null) {
        final result = data['result'] as List<dynamic>;
        if (result.isNotEmpty) {
          final workExperience = result.first as Map<String, dynamic>;
          final jobLevel = workExperience['job_level'] as Map<String, dynamic>?;
          return jobLevel?['id'] as int?;
        }
      }

      return null;
    } catch (e) {
      print('Error getting user job level: $e');
      return null;
    }
  }

  // Helper method to get user's direct leader
  Future<List<Map<String, dynamic>>> getUserDirectLeader({
    required String token,
    required int userId,
  }) async {
    try {
      final data = await getContactWorkExperience(token: token, userId: userId);

      if (data != null && data['result'] != null) {
        final result = data['result'] as List<dynamic>;
        if (result.isNotEmpty) {
          final workExperience = result.first as Map<String, dynamic>;
          final directLeader =
              workExperience['direct_leader'] as List<dynamic>?;
          return directLeader
                  ?.map((leader) => leader as Map<String, dynamic>)
                  .toList() ??
              [];
        }
      }

      return [];
    } catch (e) {
      print('Error getting user direct leader: $e');
      return [];
    }
  }

  // Helper method to check if user is staff level (job_level_id = 4)
  Future<bool> isUserStaffLevel({
    required String token,
    required int userId,
  }) async {
    final jobLevelId = await getUserJobLevel(token: token, userId: userId);
    return jobLevelId == 4;
  }
}
