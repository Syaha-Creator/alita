import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/services/api_client.dart';
import '../../../core/utils/log.dart';
import '../../../core/utils/retry.dart';

/// Fetches product-type specs from all configured brand APIs (Comforta,
/// Spring Air, Therapedic — see [AppConfig.brandSpecApis]) and merges them.
///
/// Uses [ApiClient.getExternal] since these are third-party APIs with their
/// own credentials. One brand failing doesn't block the others — it just
/// contributes an empty list.
final brandSpecProvider = FutureProvider<List<dynamic>>((ref) async {
  final configs =
      AppConfig.brandSpecApis.where((c) => c.isConfigured).toList();
  if (configs.isEmpty) return const [];

  final results = await Future.wait(configs.map(_fetchOne));
  return results.expand((list) => list).toList();
});

Future<List<dynamic>> _fetchOne(BrandSpecApiConfig config) async {
  final url = Uri.https(config.host, '/api/types_with_features', {
    'access_token': config.accessToken,
    'client_id': config.clientId,
    'client_secret': config.clientSecret,
  }).toString();

  try {
    final response = await retry(
      () => ApiClient.instance.getExternal(url),
      maxAttempts: 2,
      tag: 'brandSpec_${config.brand}',
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded;
      }
    }
    return const [];
  } catch (e, st) {
    Log.error(e, st, reason: 'brandSpecProvider fetch (${config.brand})');
    return const [];
  }
}
