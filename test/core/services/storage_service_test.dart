import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:alitapricelist/core/services/storage_service.dart';

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

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockSecureStorage();
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
}
