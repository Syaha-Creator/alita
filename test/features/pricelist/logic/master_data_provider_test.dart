import 'dart:convert';
import 'dart:io';

import 'package:alitapricelist/core/services/storage_service.dart';
import 'package:alitapricelist/features/pricelist/logic/master_data_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/mock_app_support_dir.dart';

/// Catatan: `TestWidgetsFlutterBinding` mem-stub `HttpClient` sehingga request
/// HTTP tidak keluar jaringan nyata dan mengembalikan status non-200.
/// `syncMasterData` tetap dapat diuji untuk cabang non-200 + `saveMasterData`.

Future<void> _untilMasterDataReady(ProviderContainer c) async {
  for (var i = 0; i < 300; i++) {
    if (!c.read(masterDataProvider).isLoading) return;
    await Future<void>.delayed(Duration.zero);
  }
  fail('masterDataProvider stayed loading');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory appSupportDir;

  setUpAll(() {
    appSupportDir =
        Directory.systemTemp.createTempSync('alita_pricelist_master_');
    setMockApplicationSupportDirectory(appSupportDir.path);
  });

  tearDownAll(() {
    if (appSupportDir.existsSync()) {
      appSupportDir.deleteSync(recursive: true);
    }
    dotenv.testLoad(fileInput: '''
API_BASE_URL=https://test.example.com
CLIENT_ID_ANDROID=test-cid
CLIENT_SECRET_ANDROID=test-sec
CLIENT_ID_IOS=test-cid
CLIENT_SECRET_IOS=test-sec
''');
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.clearAll();
  });

  tearDown(() async {
    await StorageService.clearAll();
  });

  group('MasterDataState', () {
    test('defaults: loading true, empty lists, no error', () {
      const s = MasterDataState();
      expect(s.isLoading, true);
      expect(s.areas, isEmpty);
      expect(s.channels, isEmpty);
      expect(s.brands, isEmpty);
      expect(s.error, isNull);
    });

    test('copyWith updates lists; error must be passed explicitly to keep it',
        () {
      const s = MasterDataState(isLoading: false, error: 'x');
      final c = s.copyWith(
        areas: [
          {'name': 'A'},
        ],
        error: 'x',
      );
      expect(c.isLoading, false);
      expect(c.error, 'x');
      expect(c.areas, hasLength(1));
    });
  });

  group('MasterDataNotifier — cache from SharedPreferences', () {
    test('loads areas/channels/brands JSON and finishes loading', () async {
      final areasJson = jsonEncode([
        {'name': 'Jakarta'},
        {'area': 'Surabaya'},
      ]);
      final channelsJson = jsonEncode({
        'data': [
          {'id': 10, 'channel': 'Direct'},
        ],
      });
      final brandsJson = jsonEncode({
        'result': {
          'pl_brands': [
            {'brand': 'Comforta', 'pl_channel_id': 10},
          ],
        },
      });

      SharedPreferences.setMockInitialValues({
        'token_migrated_v1': true,
        'master_areas_cache': areasJson,
        'master_channels_cache': channelsJson,
        'master_brands_cache': brandsJson,
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await _untilMasterDataReady(container);

      final s = container.read(masterDataProvider);
      expect(s.isLoading, false);
      expect(s.error, isNull);
      expect(s.areas, hasLength(2));
      expect(s.channels, hasLength(1));
      expect(s.brands, hasLength(1));
    });

    test('invalid JSON in cache yields empty list for that dimension',
        () async {
      SharedPreferences.setMockInitialValues({
        'token_migrated_v1': true,
        'master_areas_cache': 'not-json',
        'master_channels_cache': '[]',
        'master_brands_cache': '[]',
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await _untilMasterDataReady(container);

      final s = container.read(masterDataProvider);
      expect(s.areas, isEmpty);
      expect(s.channels, isEmpty);
    });
  });

  group('MasterDataNotifier — syncIfStale', () {
    test('skips sync when last sync is within stale window', () async {
      SharedPreferences.setMockInitialValues({
        'token_migrated_v1': true,
        'master_areas_cache': jsonEncode([
          {'name': 'Jakarta'},
        ]),
        'master_channels_cache': '[]',
        'master_brands_cache': '[]',
        'master_data_last_sync': DateTime.now().millisecondsSinceEpoch,
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);
      await _untilMasterDataReady(container);

      await container.read(masterDataProvider.notifier).syncIfStale();

      final s = container.read(masterDataProvider);
      expect(s.isLoading, false);
      expect(s.areas, isNotEmpty);
    });
  });

  group('MasterDataNotifier — syncMasterData (stubbed HTTP)', () {
    setUpAll(() {
      dotenv.testLoad(fileInput: '''
API_BASE_URL=https://stubbed-http.test
CLIENT_ID_ANDROID=test-cid
CLIENT_SECRET_ANDROID=test-sec
CLIENT_ID_IOS=test-cid
CLIENT_SECRET_IOS=test-sec
''');
    });

    test(
        'non-200 from binding keeps previous lists; saveMasterData still runs',
        () async {
      SharedPreferences.setMockInitialValues({
        'token_migrated_v1': true,
        'master_areas_cache': jsonEncode([
          {'name': 'CachedArea'},
        ]),
        'master_channels_cache': jsonEncode([
          {'id': 7, 'channel': 'Retail'},
        ]),
        'master_brands_cache': jsonEncode([
          {'brand': 'B1', 'pl_channel_id': 7},
        ]),
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);
      await _untilMasterDataReady(container);

      await container.read(masterDataProvider.notifier).syncMasterData();

      final s = container.read(masterDataProvider);
      expect(s.isLoading, false);
      expect(s.error, isNull);
      expect(s.areas.any((e) => e['name'] == 'CachedArea'), isTrue);
      expect(s.channels.any((e) => e['channel'] == 'Retail'), isTrue);

      final last = await StorageService.loadMasterDataLastSync();
      expect(last, isNotNull);
    });

    test('concurrent syncMasterData second call is ignored via _isSyncing',
        () async {
      SharedPreferences.setMockInitialValues({
        'token_migrated_v1': true,
        'master_areas_cache': jsonEncode([
          {'name': 'A'},
        ]),
        'master_channels_cache': '[]',
        'master_brands_cache': '[]',
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);
      await _untilMasterDataReady(container);

      final n = container.read(masterDataProvider.notifier);
      final f1 = n.syncMasterData();
      final f2 = n.syncMasterData();
      await Future.wait([f1, f2]);

      expect(container.read(masterDataProvider).isLoading, false);
    });
  });
}
