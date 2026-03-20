import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

/// Registers a no-op handler for FlutterSecureStorage's method channel
/// so tests can run headlessly without MissingPluginException.
void mockSecureStorageChannel() {
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async => null);
}

/// Sets up SharedPreferences for a logged-out user.
void initLoggedOutState() {
  SharedPreferences.setMockInitialValues({
    'token_migrated_v1': true,
  });
}

/// Sets up SharedPreferences for a logged-in user (mirroring real API data).
void initLoggedInState() {
  SharedPreferences.setMockInitialValues({
    'is_logged_in': true,
    'user_email': 'msyahrul090@gmail.com',
    'default_area': 'Jabodetabek',
    'user_id': 5206,
    'user_name': 'Mochammad Syahrul Azhar',
    'user_image_url':
        'https://alitav2.massindo.com/uploads/user/image/5206/Mochammad_Syahrul_Azhar.jpg',
    'token_migrated_v1': true,
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
      approvalInboxProvider.overrideWith(
        (ref) => _NoOpApprovalInboxNotifier(ref),
      ),
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
  _NoOpApprovalInboxNotifier(super.ref);

  @override
  Future<void> fetchInbox() async {}
}
