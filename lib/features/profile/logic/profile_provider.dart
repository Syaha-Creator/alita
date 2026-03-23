import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_client.dart';
import '../../../core/utils/log.dart';
import '../../../core/utils/network_error.dart';
import '../../auth/logic/auth_provider.dart';
import '../data/models/user_profile.dart';

/// Mengambil profil pengguna dari API contact_work_experiences.
final profileProvider = FutureProvider<UserProfile?>((ref) async {
  final auth = ref.watch(authProvider);
  if (auth.userId == 0) return null;

  try {
    final response = await ApiClient.instance.get(
      '/contact_work_experiences',
      queryParams: {'user_id': auth.userId.toString()},
      timeout: const Duration(seconds: 15),
    );

    final code = response.statusCode;

    if (code >= 500) {
      Log.warning('Profil: server error $code — skipped',
          tag: 'ProfileProvider');
      return null;
    }

    if (code != 200) {
      throw Exception('Gagal memuat profil ($code)');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final result = body['result'] as List?;

    if (result == null || result.isEmpty) return null;

    return UserProfile.fromJson(result[0] as Map<String, dynamic>);
  } catch (e) {
    if (isNetworkError(e)) {
      Log.warning('profileProvider: $e', tag: 'ProfileProvider');
      return null;
    }
    rethrow;
  }
});
