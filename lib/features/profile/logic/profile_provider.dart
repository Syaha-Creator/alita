import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_client.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/approver_access.dart';
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

    final decodedBody = jsonDecode(response.body);
    if (decodedBody is! Map) {
      throw Exception('Format respons profil tidak valid.');
    }
    final body = Map<String, dynamic>.from(decodedBody);
    final result = body['result'] as List?;

    if (result == null || result.isEmpty) return null;
    final first = result[0];
    if (first is! Map) {
      throw Exception('Format data profil tidak valid.');
    }

    final profile = UserProfile.fromJson(Map<String, dynamic>.from(first));
    if (profile.workTitle.isNotEmpty) {
      await StorageService.saveWorkTitle(profile.workTitle);
      ApproverAccess.updateCache(profile.workTitle);
    }
    return profile;
  } catch (e) {
    if (isNetworkError(e)) {
      Log.warning('profileProvider: $e', tag: 'ProfileProvider');
      return null;
    }
    rethrow;
  }
});
