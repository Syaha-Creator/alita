import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/services/api_client.dart';

/// Fetches the full brand/product-type spec catalogue from the Comforta API.
///
/// Uses [ApiClient.getExternal] because this is a third-party API with its
/// own credentials (not the main on-premise backend).
final brandSpecProvider = FutureProvider<List<dynamic>>((ref) async {
  final url = Uri.https(AppConfig.comfortaHost, '/api/types_with_features', {
    'access_token': AppConfig.comfortaAccessToken,
    'client_id': AppConfig.comfortaClientId,
    'client_secret': AppConfig.comfortaClientSecret,
  }).toString();

  try {
    final response = await ApiClient.instance.getExternal(url);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded != null) {
        return decoded as List<dynamic>;
      }
    }
    return [];
  } catch (e) {
    return [];
  }
});
