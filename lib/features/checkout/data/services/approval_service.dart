import 'dart:convert';

import '../../../../core/services/api_client.dart';
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
      final body = json.decode(response.body) as Map<String, dynamic>;

      List<dynamic>? users;
      final result = body['result'];
      if (result is Map) {
        users = result['users'] as List?;
      } else if (result is List) {
        users = result;
      } else {
        users = body['data'] as List?;
      }

      return (users ?? [])
          .map((e) => Approver.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(
      'HTTP ${response.statusCode}: ${response.body}',
    );
  }
}
