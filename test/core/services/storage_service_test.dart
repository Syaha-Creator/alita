import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:alitapricelist/core/services/storage_service.dart';

import '../../helpers/mock_app_support_dir.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Mock FlutterSecureStorage method channel so loadAccessToken etc. work.
  void mockSecureStorage([Map<String, String> store = const {}]) {
    final copy = Map<String, String>.from(store);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (MethodCall call) async {
        switch (call.method) {
          case 'read':
            return copy[call.arguments['key']];
          case 'write':
            copy[call.arguments['key'] as String] =
                call.arguments['value'] as String;
            return null;
          case 'delete':
            copy.remove(call.arguments['key']);
            return null;
          case 'deleteAll':
            copy.clear();
            return null;
          default:
            return null;
        }
      },
    );
  }

  late Directory testSupportDir;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockSecureStorage();
    StorageService.debugResetFileCacheForTests();
    testSupportDir = Directory.systemTemp.createTempSync('alita_storage_test_');
    setMockApplicationSupportDirectory(testSupportDir.path);
  });

  group('Cart persistence', () {
    test('saveCart + loadCart round-trip', () async {
      final data = [
        {'id': '1', 'qty': 2},
        {'id': '2', 'qty': 5},
      ];
      await StorageService.saveCart(data);
      final loaded = await StorageService.loadCart();
      expect(loaded, hasLength(2));
      expect(loaded.first['id'], '1');
      expect(loaded.last['qty'], 5);
    });

    test('loadCart returns empty on missing key', () async {
      final loaded = await StorageService.loadCart();
      expect(loaded, isEmpty);
    });

    test('loadCart returns empty on corrupt JSON', () async {
      SharedPreferences.setMockInitialValues({'cart_items': 'not-json'});
      final loaded = await StorageService.loadCart();
      expect(loaded, isEmpty);
    });

    test('loadCart skips non-Map elements instead of throwing', () async {
      SharedPreferences.setMockInitialValues({
        'cart_items': '[{"id":"1","qty":2},"not-a-map",{"id":"2","qty":5}]',
      });
      final loaded = await StorageService.loadCart();
      expect(loaded, hasLength(2));
      expect(loaded[0]['id'], '1');
      expect(loaded[1]['id'], '2');
    });

    test('loadCart returns empty when top-level JSON is not a List', () async {
      SharedPreferences.setMockInitialValues({'cart_items': '{"id":"1"}'});
      final loaded = await StorageService.loadCart();
      expect(loaded, isEmpty);
    });
  });

  group('Favorites persistence', () {
    test('saveFavorites + loadFavorites round-trip', () async {
      await StorageService.saveFavorites(['a', 'b', 'c']);
      final loaded = await StorageService.loadFavorites();
      expect(loaded, ['a', 'b', 'c']);
    });

    test('loadFavorites returns empty on missing key', () async {
      final loaded = await StorageService.loadFavorites();
      expect(loaded, isEmpty);
    });
  });

  group('Auth persistence', () {
    test('saveAuth + load methods round-trip', () async {
      await StorageService.saveAuth(
        isLoggedIn: true,
        email: 'test@x.com',
        defaultArea: 'Surabaya',
        userId: 42,
        userName: 'Alice',
        userImageUrl: 'https://img.png',
        accessToken: 'secret-tok',
      );

      expect(await StorageService.loadIsLoggedIn(), true);
      expect(await StorageService.loadUserEmail(), 'test@x.com');
      expect(await StorageService.loadDefaultArea(), 'Surabaya');
      expect(await StorageService.loadUserId(), 42);
      expect(await StorageService.loadUserName(), 'Alice');
      expect(await StorageService.loadUserImageUrl(), 'https://img.png');
      expect(await StorageService.loadAccessToken(), 'secret-tok');
    });

    test('loadDefaults when nothing saved', () async {
      expect(await StorageService.loadIsLoggedIn(), false);
      expect(await StorageService.loadUserEmail(), '');
      expect(await StorageService.loadDefaultArea(), 'Jakarta');
      expect(await StorageService.loadUserId(), 0);
      expect(await StorageService.loadUserName(), '');
      expect(await StorageService.loadUserImageUrl(), '');
    });

    test('clearAuth removes all auth keys', () async {
      await StorageService.saveAuth(
        isLoggedIn: true,
        email: 'x@y.com',
        defaultArea: 'A',
        accessToken: 'tok',
        userId: 1,
        userName: 'U',
      );
      await StorageService.clearAuth();

      expect(await StorageService.loadIsLoggedIn(), false);
      expect(await StorageService.loadUserEmail(), '');
      expect(await StorageService.loadUserId(), 0);
      expect(await StorageService.loadAccessToken(), '');
    });
  });

  group('Master data cache', () {
    test('saveMasterData + load round-trip', () async {
      await StorageService.saveMasterData(
        areas: '["Jabodetabek"]',
        channels: '["Indirect"]',
        brands: '["Comforta"]',
      );

      expect(await StorageService.loadCachedAreas(), '["Jabodetabek"]');
      expect(await StorageService.loadCachedChannels(), '["Indirect"]');
      expect(await StorageService.loadCachedBrands(), '["Comforta"]');
    });

    test('loadMasterDataLastSync returns DateTime after save', () async {
      final before = DateTime.now();
      await StorageService.saveMasterData(areas: '[]');
      final lastSync = await StorageService.loadMasterDataLastSync();
      expect(lastSync, isNotNull);
      expect(lastSync!.isAfter(before.subtract(const Duration(seconds: 1))),
          isTrue);
    });

    test('loadMasterDataLastSync returns null if never synced', () async {
      final lastSync = await StorageService.loadMasterDataLastSync();
      expect(lastSync, isNull);
    });

    test('partial save only updates specified keys', () async {
      await StorageService.saveMasterData(
        areas: '["A"]',
        channels: '["C"]',
        brands: '["B"]',
      );
      await StorageService.saveMasterData(brands: '["NewB"]');

      expect(await StorageService.loadCachedAreas(), '["A"]');
      expect(await StorageService.loadCachedChannels(), '["C"]');
      expect(await StorageService.loadCachedBrands(), '["NewB"]');
    });
  });

  group('Pricelist cache', () {
    test('pricelistCacheStorageKey is deterministic', () {
      final k1 = StorageService.pricelistCacheStorageKey('A', 'C', 'B');
      final k2 = StorageService.pricelistCacheStorageKey('A', 'C', 'B');
      expect(k1, k2);
    });

    test('pricelistCacheStorageKey is case-insensitive', () {
      final k1 = StorageService.pricelistCacheStorageKey('Area', 'Chan', 'Br');
      final k2 = StorageService.pricelistCacheStorageKey('area', 'chan', 'br');
      expect(k1, k2);
    });

    test('pricelistCacheStorageKey trims whitespace', () {
      final k1 = StorageService.pricelistCacheStorageKey('A', 'C', 'B');
      final k2 = StorageService.pricelistCacheStorageKey(' A ', ' C ', ' B ');
      expect(k1, k2);
    });

    test('savePricelist + loadPricelist round-trip', () async {
      const key = 'test_pl_key';
      final rows = [
        {'id': '1', 'name': 'Product A'},
        {'id': '2', 'name': 'Product B'},
      ];
      await StorageService.savePricelistProductRows(key, rows);
      final loaded = await StorageService.loadPricelistProductRows(key);
      expect(loaded, isNotNull);
      expect(loaded, hasLength(2));
      expect(loaded!.first['name'], 'Product A');
    });

    test('loadPricelist returns null for missing key', () async {
      final loaded =
          await StorageService.loadPricelistProductRows('nonexistent');
      expect(loaded, isNull);
    });

    test('loadPricelist returns null for corrupt data', () async {
      SharedPreferences.setMockInitialValues({'bad_key': 'not json'});
      final loaded = await StorageService.loadPricelistProductRows('bad_key');
      expect(loaded, isNull);
    });

    test('loadPricelist returns null when items key missing', () async {
      SharedPreferences.setMockInitialValues({
        'no_items': jsonEncode({'v': 1}),
      });
      final loaded = await StorageService.loadPricelistProductRows('no_items');
      expect(loaded, isNull);
    });

    test('loadPricelist skips non-Map rows instead of throwing', () async {
      const key = 'mixed_rows';
      final plCacheDir = Directory('${testSupportDir.path}/pl_cache');
      plCacheDir.createSync(recursive: true);
      File('${plCacheDir.path}/$key.json').writeAsStringSync(jsonEncode({
        'v': 1,
        'items': [
          {'id': '1', 'name': 'Product A'},
          'not-a-map',
          {'id': '2', 'name': 'Product B'},
        ],
      }));

      final loaded = await StorageService.loadPricelistProductRows(key);
      expect(loaded, isNotNull);
      expect(loaded, hasLength(2));
      expect(loaded!.first['name'], 'Product A');
    });
  });

  group('clearAll', () {
    test('removes all SharedPreferences and secure storage', () async {
      await StorageService.saveAuth(
        isLoggedIn: true,
        email: 'a@b.com',
        defaultArea: 'X',
        accessToken: 'tok',
      );
      await StorageService.saveFavorites(['1']);
      await StorageService.clearAll();

      expect(await StorageService.loadIsLoggedIn(), false);
      expect(await StorageService.loadFavorites(), isEmpty);
      expect(await StorageService.loadAccessToken(), '');
    });
  });

  group('Token migration', () {
    test('migrates plain-text token from SharedPreferences to secure storage',
        () async {
      SharedPreferences.setMockInitialValues({
        'access_token': 'legacy-tok',
      });
      mockSecureStorage();

      final token = await StorageService.loadAccessToken();
      expect(token, 'legacy-tok');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('access_token'), isNull);
      expect(prefs.getBool('token_migrated_v1'), true);
    });

    test('does not re-migrate after first migration', () async {
      SharedPreferences.setMockInitialValues({
        'token_migrated_v1': true,
      });
      mockSecureStorage({'access_token': 'secure-tok'});

      final token = await StorageService.loadAccessToken();
      expect(token, 'secure-tok');
    });
  });

  group('Email migration (PII → secure storage)', () {
    test('migrates plain-text email from SharedPreferences to secure storage',
        () async {
      SharedPreferences.setMockInitialValues({
        'user_email': 'legacy@example.com',
      });
      mockSecureStorage();

      final email = await StorageService.loadUserEmail();
      expect(email, 'legacy@example.com');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('user_email'), isNull);
      expect(prefs.getBool('email_migrated_v1'), true);
    });

    test('does not re-migrate after first migration', () async {
      SharedPreferences.setMockInitialValues({
        'email_migrated_v1': true,
      });
      mockSecureStorage({'user_email': 'secure@example.com'});

      final email = await StorageService.loadUserEmail();
      expect(email, 'secure@example.com');
    });

    test('saveAuth never leaves a plaintext copy in SharedPreferences',
        () async {
      await StorageService.saveAuth(
        isLoggedIn: true,
        email: 'fresh@example.com',
        defaultArea: 'Jakarta',
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('user_email'), isNull);
      expect(await StorageService.loadUserEmail(), 'fresh@example.com');
    });
  });

  group('Profile fields (user_id/nama/sales code → secure storage)', () {
    test('saveAuth never leaves user_id/nama/sales code in SharedPreferences',
        () async {
      await StorageService.saveAuth(
        isLoggedIn: true,
        email: 'a@b.com',
        defaultArea: 'Jakarta',
        accessToken: 'tok',
        userId: 99,
        userName: 'Budi',
        addressNumber: 'SC-01',
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('user_id'), isNull);
      expect(prefs.getString('user_name'), isNull);
      expect(prefs.getString('user_address_number'), isNull);

      expect(await StorageService.loadUserId(), 99);
      expect(await StorageService.loadUserName(), 'Budi');
      expect(await StorageService.loadUserAddressNumber(), 'SC-01');
    });

    test('migrates legacy plaintext user_id/nama/sales code once', () async {
      SharedPreferences.setMockInitialValues({
        'user_id': 7,
        'user_name': 'Legacy Name',
        'user_address_number': 'SC-LEGACY',
      });
      mockSecureStorage();

      expect(await StorageService.loadUserId(), 7);
      expect(await StorageService.loadUserName(), 'Legacy Name');
      expect(await StorageService.loadUserAddressNumber(), 'SC-LEGACY');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('user_id'), isNull);
      expect(prefs.getString('user_name'), isNull);
      expect(prefs.getString('user_address_number'), isNull);
      expect(prefs.getBool('profile_fields_migrated_v1'), true);
    });
  });

  group('Concurrent secure-storage read coalescing', () {
    test(
        'two concurrent loadAccessToken() calls trigger only one native read',
        () async {
      // Regression: checkout page fires fetchApprovers() + fetchAttendance
      // WorkPlace() concurrently, both needing access_token. Without
      // coalescing, this hits the Keystore/EncryptedSharedPreferences
      // plugin twice at once — a known trigger for platform-channel
      // deadlocks, especially right after long inactivity when the key
      // needs regeneration. Reported by user as "checkout pertama kali
      // setelah lama, approval card muter terus".
      var readCallCount = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        (MethodCall call) async {
          if (call.method == 'read') {
            readCallCount++;
            await Future<void>.delayed(const Duration(milliseconds: 30));
            return 'concurrent-tok';
          }
          return null;
        },
      );

      final results = await Future.wait([
        StorageService.loadAccessToken(),
        StorageService.loadAccessToken(),
      ]);

      expect(results, ['concurrent-tok', 'concurrent-tok']);
      expect(readCallCount, 1);
    });

    test('sequential reads after completion each hit the native layer again',
        () async {
      var readCallCount = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        (MethodCall call) async {
          if (call.method == 'read') readCallCount++;
          return 'seq-tok';
        },
      );

      await StorageService.loadAccessToken();
      await StorageService.loadAccessToken();

      expect(readCallCount, 2);
    });
  });

  group('Secure-storage write failure safety net', () {
    test('isLoggedIn stays false if access_token write to Keystore fails',
        () async {
      // Regression: token gagal ditulis (Keystore corrupt/full) tidak boleh
      // membuat sesi berikutnya "isLoggedIn=true" dengan token kosong.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        (MethodCall call) async {
          if (call.method == 'write' &&
              call.arguments['key'] == 'access_token') {
            throw PlatformException(code: 'write_error');
          }
          return null;
        },
      );

      await StorageService.saveAuth(
        isLoggedIn: true,
        email: 'a@b.com',
        defaultArea: 'Jakarta',
        accessToken: 'tok-that-fails-to-write',
      );

      expect(await StorageService.loadIsLoggedIn(), isFalse);
    });
  });
}
