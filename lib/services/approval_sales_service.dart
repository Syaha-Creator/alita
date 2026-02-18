import '../features/approval/data/models/approval_sales_model.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'contact_work_experience_service.dart';

/// Service for fetching approval sales (potential approvers) list
class ApprovalSalesService {
  final ApiClient _apiClient;
  final ContactWorkExperienceService _cweService;

  ApprovalSalesService(this._apiClient, this._cweService);

  /// Cache for approval sales data
  ApprovalSalesResponse? _cachedResponse;
  int? _cachedCompanyId;
  int? _cachedAreaId;

  /// Fetch approval sales list based on user's company_id and area_id from CWE
  Future<ApprovalSalesResponse?> getApprovalSales() async {
    try {
      final token = await AuthService.getToken();
      final userId = await AuthService.getCurrentUserId();

      if (token == null || userId == null) {
        return null;
      }

      // Get company_id and area_id from CWE
      final companyId = await _cweService.getUserCompanyId(
        token: token,
        userId: userId,
      );
      final areaId = await _cweService.getUserAreaId(
        token: token,
        userId: userId,
      );

      if (companyId == null || areaId == null) {
        return null;
      }

      // Check cache
      if (_cachedResponse != null &&
          _cachedCompanyId == companyId &&
          _cachedAreaId == areaId) {
        return _cachedResponse;
      }

      final response = await _apiClient.getApprovalSales(
        token: token,
        companyId: companyId,
        areaId: areaId,
      );

      final parsedResponse = ApprovalSalesResponse.fromJson(response);

      // Cache the response
      _cachedResponse = parsedResponse;
      _cachedCompanyId = companyId;
      _cachedAreaId = areaId;

      return parsedResponse;
    } catch (e) {
      return null;
    }
  }

  /// Clear the cache (useful when user changes or logs out)
  void clearCache() {
    _cachedResponse = null;
    _cachedCompanyId = null;
    _cachedAreaId = null;
  }

  /// Get users filtered by job level name (for display purposes only)
  /// Note: User can still select any person from the full list
  List<ApprovalSalesUserModel> filterUsersByJobLevel(
    List<ApprovalSalesUserModel> users,
    List<String> jobLevelNames,
  ) {
    return users.where((user) {
      return user.workExperiences.any((exp) =>
          jobLevelNames.any((level) =>
              exp.jobLevelName.toLowerCase().contains(level.toLowerCase())));
    }).toList();
  }

  /// Get supervisors from the list (job_level_name contains "supervisor")
  List<ApprovalSalesUserModel> getSupervisors(
      List<ApprovalSalesUserModel> users) {
    return filterUsersByJobLevel(users, ['supervisor']);
  }

  /// Get regional managers from the list (job_level_name contains "regional manager")
  List<ApprovalSalesUserModel> getRegionalManagers(
      List<ApprovalSalesUserModel> users) {
    return filterUsersByJobLevel(users, ['regional manager']);
  }
}
