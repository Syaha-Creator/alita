import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:alitapricelist/core/router/app_router.dart';
import 'package:alitapricelist/core/services/connectivity_service.dart';
import 'package:alitapricelist/core/theme/app_theme.dart';
import 'package:alitapricelist/features/approval/logic/approval_inbox_provider.dart';
import 'package:alitapricelist/features/history/logic/order_history_provider.dart';
import 'package:alitapricelist/features/pricelist/logic/product_provider.dart';
import 'package:alitapricelist/features/profile/logic/profile_provider.dart';

import 'test_data.dart';

/// Registers an in-memory fake for FlutterSecureStorage's platform interface
/// so tests can run headlessly without MissingPluginException.
///
/// IMPORTANT: this must actually round-trip values (unlike a MethodChannel
/// mock that just returns null for every call) because `StorageService`
/// stores access_token/user_id/user_name/user_address_number in secure
/// storage (PII hardening — see docs). A stateless null-returning mock made
/// [initLoggedInState] silently ineffective: `AuthNotifier` would always see
/// an empty token/profile and treat the session as logged out, regardless of
/// what SharedPreferences held. Use [TestFlutterSecureStoragePlatform]
/// (shipped by the plugin itself for exactly this purpose) with a real
/// backing map instead.
void mockSecureStorageChannel() {
  FlutterSecureStoragePlatform.instance =
      TestFlutterSecureStoragePlatform(<String, String>{});
}

/// Sets up SharedPreferences for a logged-out user.
void initLoggedOutState() {
  SharedPreferences.setMockInitialValues({
    'token_migrated_v1': true,
    'email_migrated_v1': true,
    'profile_fields_migrated_v1': true,
  });
  FlutterSecureStoragePlatform.instance =
      TestFlutterSecureStoragePlatform(<String, String>{});
}

/// Sets up SharedPreferences + secure storage for a logged-in user (mirroring
/// real API data). `access_token`/`user_id`/`user_name`/`user_email` live in
/// secure storage in the real app (see [StorageService]) — seed them there
/// directly and mark all migrations as already-done so `StorageService`
/// never tries to read stale legacy values from SharedPreferences.
void initLoggedInState() {
  SharedPreferences.setMockInitialValues({
    'is_logged_in': true,
    'default_area': 'Jabodetabek',
    'user_image_url': '',
    'token_migrated_v1': true,
    'email_migrated_v1': true,
    'profile_fields_migrated_v1': true,
  });
  // NOTE: user_id intentionally NOT a real user id — see [TestData.testUserId]
  // for why (it used to be 5206, which silently collided with the real
  // TelemetryAccess admin allowlist and redirected every logged-in test to
  // /sales_hub instead of the product list).
  FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform({
    'access_token': 'test-access-token',
    'user_id': '900001',
    'user_name': 'Test Sales User',
    'user_email': 'test.sales@alita.test',
  });
}

/// Builds the test app wrapped in ProviderScope with all necessary overrides.
///
/// [loggedIn] pre-populates SharedPreferences so AuthNotifier reads a valid
/// session. [withProducts] supplies the product list and filter selections
/// so ProductListPage renders data without hitting the real API.
Widget buildTestApp({
  bool loggedIn = true,
  bool withProducts = true,
  List<Override> extraOverrides = const [],
}) {
  if (loggedIn) {
    initLoggedInState();
  } else {
    initLoggedOutState();
  }

  return ProviderScope(
    overrides: [
      connectivityProvider.overrideWith(
        (ref) => Stream.value(true),
      ),
      // Prevent API calls from providers that fire on navigation
      orderHistoryProvider.overrideWith((ref) async => []),
      profileProvider.overrideWith((ref) async => null),
      approvalInboxProvider.overrideWith(_NoOpApprovalInboxNotifier.new),
      if (withProducts) ...[
        selectedChannelProvider.overrideWith((ref) => 'Indirect'),
        selectedBrandProvider.overrideWith((ref) => 'Comforta'),
        productListProvider.overrideWith(
          (ref) async => ProductListLoadResult(
            products: TestData.sampleProducts,
          ),
        ),
      ],
      ...extraOverrides,
    ],
    child: const _TestApp(),
  );
}

class _TestApp extends ConsumerWidget {
  const _TestApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}

/// No-op approval inbox notifier that skips [fetchInbox] to avoid
/// hitting real API in integration tests.
class _NoOpApprovalInboxNotifier extends ApprovalInboxNotifier {
  @override
  Future<void> fetchInbox({bool force = false}) async {}
}
