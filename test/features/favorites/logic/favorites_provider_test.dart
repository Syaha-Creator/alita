import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:alitapricelist/features/favorites/logic/favorites_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('FavoritesNotifier', () {
    late FavoritesNotifier notifier;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      notifier = FavoritesNotifier();
      // Allow async _loadFavorites to complete before interacting
      await Future.delayed(const Duration(milliseconds: 50));
    });

    test('starts with empty favorites', () {
      expect(notifier.state, isEmpty);
    });

    test('toggleFavorite adds product id', () async {
      await notifier.toggleFavorite('prod-1');
      expect(notifier.state, contains('prod-1'));
    });

    test('toggleFavorite again removes product id', () async {
      await notifier.toggleFavorite('prod-1');
      await notifier.toggleFavorite('prod-1');
      expect(notifier.state, isNot(contains('prod-1')));
    });

    test('multiple favorites tracked independently', () async {
      await notifier.toggleFavorite('a');
      await notifier.toggleFavorite('b');
      await notifier.toggleFavorite('c');
      expect(notifier.state, hasLength(3));
      await notifier.toggleFavorite('b');
      expect(notifier.state, hasLength(2));
      expect(notifier.state, isNot(contains('b')));
    });

    test('isFavorite returns correct boolean', () async {
      await notifier.toggleFavorite('x');
      expect(notifier.isFavorite('x'), isTrue);
      expect(notifier.isFavorite('y'), isFalse);
    });

    test('clearFavorites empties state', () async {
      await notifier.toggleFavorite('a');
      await notifier.toggleFavorite('b');
      await notifier.clearFavorites();
      expect(notifier.state, isEmpty);
    });

    test('favoritesCount returns correct count', () async {
      expect(notifier.favoritesCount, 0);
      await notifier.toggleFavorite('a');
      await notifier.toggleFavorite('b');
      expect(notifier.favoritesCount, 2);
    });
  });

  group('FavoritesNotifier persistence', () {
    test('loads persisted favorites on init', () async {
      SharedPreferences.setMockInitialValues({
        'favorite_ids': ['p1', 'p2', 'p3'],
      });

      final notifier = FavoritesNotifier();
      // Allow async _loadFavorites to complete
      await Future.delayed(const Duration(milliseconds: 50));

      expect(notifier.state, hasLength(3));
      expect(notifier.isFavorite('p1'), isTrue);
      expect(notifier.isFavorite('p2'), isTrue);
    });
  });
}
