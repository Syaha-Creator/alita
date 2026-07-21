import 'dart:convert';

import '../../../../core/services/api_client.dart';
import '../../../../core/utils/safe_json_list.dart';
import '../models/approver_model.dart';

/// Fetches the list of approvers (SPV / ASM / Manager) for a given company + area
/// from the `approval_sales` endpoint.
class ApprovalService {
  static final ApiClient _api = ApiClient.instance;

  /// Calls `GET /approval_sales` and returns the parsed approver list.
  ///
  /// [companyId] and [areaId] must come from the logged-in user's CWE data.
  Future<List<Approver>> getApprovers(int companyId, int areaId) async {
    final response = await _api.get(
      '/approval_sales',
      queryParams: {
        'company_id': companyId.toString(),
        'area_id': areaId.toString(),
      },
      timeout: const Duration(seconds: 15),
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is! Map) {
        throw Exception('Format response approval_sales tidak valid.');
      }
      final body = Map<String, dynamic>.from(decoded);

      dynamic users;
      final result = body['result'];
      if (result is Map) {
        users = result['users'];
      } else if (result is List) {
        users = result;
      } else {
        users = body['data'];
      }

      return safeMapList(users, fieldName: 'approval_sales.users')
          .map(Approver.fromJson)
          .toList();
    }
    throw Exception(
      'HTTP ${response.statusCode}: ${response.body}',
    );
  }
}
