import 'package:flutter/foundation.dart';

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
      if (kDebugMode) {
        print('Error fetching contact work experience: $e');
      }
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
      if (kDebugMode) {
        print('Error getting user job level: $e');
      }
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
      if (kDebugMode) {
        print('Error getting user direct leader: $e');
      }
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

  // Helper method to determine user role for order letters API
  // Returns: 'controller', 'analyst', 'indirect_leader', 'direct_leader', or 'staff'
  Future<String> getUserRoleForOrderLetters({
    required String token,
    required int userId,
  }) async {
    try {
      final data = await getContactWorkExperience(token: token, userId: userId);

      if (data != null && data['result'] != null) {
        final result = data['result'] as List<dynamic>;
        if (result.isNotEmpty) {
          final workExperience = result.first as Map<String, dynamic>;

          // Get work title (more reliable for analyst/controller detection)
          final workTitle = workExperience['work_title'] as String? ?? '';
          final normalizedWorkTitle = workTitle.toUpperCase().trim();

          // Get job level name
          final jobLevel = workExperience['job_level'] as Map<String, dynamic>?;
          final jobLevelName = jobLevel?['name'] as String? ?? '';
          final normalizedJobLevelName = jobLevelName.toUpperCase().trim();

          // Priority 1: Check work_title for Controller (contains "CONTROLLER")
          // Example: "Regional Budget Controller Supervisor" -> Controller
          if (normalizedWorkTitle.contains('CONTROLLER')) {
            return 'controller';
          }

          // Priority 2: Check work_title for Analyst (contains "ANALYST")
          // Example: "Corporate Analyst Manager" -> Analyst
          if (normalizedWorkTitle.contains('ANALYST')) {
            return 'analyst';
          }

          // Fallback: Check job_level.name for Controller
          if (normalizedJobLevelName == 'CONTROLLER') {
            return 'controller';
          }

          // Fallback: Check job_level.name for Analyst
          if (normalizedJobLevelName == 'ANALYST') {
            return 'analyst';
          }

          // Priority 3: Check if Regional Manager or Manager (indirect leader)
          // Note: Manager yang work_title mengandung ANALYST sudah terdeteksi di Priority 2
          if (normalizedJobLevelName == 'REGIONAL MANAGER' ||
              normalizedJobLevelName == 'MANAGER') {
            return 'indirect_leader';
          }

          // Priority 3.5: Check if Staff, Sleep Consultant (from work_title or job_level)
          // Sleep Consultant harus pakai STAFF endpoint meskipun punya direct_leader
          // Check work_title first (more flexible)
          if (normalizedWorkTitle.contains('SLEEP CONSULTANT')) {
            return 'staff';
          }
          // Then check job_level.name
          if (normalizedJobLevelName == 'STAFF' ||
              normalizedJobLevelName == 'SLEEP CONSULTANT REGULAR' ||
              normalizedJobLevelName == 'SLEEP CONSULTANT FREELANCE') {
            return 'staff';
          }

          // Priority 4: Check if has direct_leader entries (supervisor with subordinates)
          // Only check if not already detected as staff above
          final directLeader =
              workExperience['direct_leader'] as List<dynamic>?;
          if (directLeader != null && directLeader.isNotEmpty) {
            return 'direct_leader';
          }
        }
      }

      // Default: staff
      return 'staff';
    } catch (e) {
      // Default: staff on error
      return 'staff';
    }
  }
}
