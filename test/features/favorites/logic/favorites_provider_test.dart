import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:alitapricelist/features/favorites/logic/favorites_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('FavoritesNotifier', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
      container.read(favoritesProvider); // trigger lazy build()
      // Allow async _loadFavorites to complete before interacting
      await Future.delayed(const Duration(milliseconds: 50));
    });

    tearDown(() => container.dispose());

    test('starts with empty favorites', () {
      expect(container.read(favoritesProvider), isEmpty);
    });

    test('toggleFavorite adds product id', () async {
      await container.read(favoritesProvider.notifier).toggleFavorite('prod-1');
      expect(container.read(favoritesProvider), contains('prod-1'));
    });

    test('toggleFavorite again removes product id', () async {
      final notifier = container.read(favoritesProvider.notifier);
      await notifier.toggleFavorite('prod-1');
      await notifier.toggleFavorite('prod-1');
      expect(container.read(favoritesProvider), isNot(contains('prod-1')));
    });

    test('multiple favorites tracked independently', () async {
      final notifier = container.read(favoritesProvider.notifier);
      await notifier.toggleFavorite('a');
      await notifier.toggleFavorite('b');
      await notifier.toggleFavorite('c');
      expect(container.read(favoritesProvider), hasLength(3));
      await notifier.toggleFavorite('b');
      expect(container.read(favoritesProvider), hasLength(2));
      expect(container.read(favoritesProvider), isNot(contains('b')));
    });

    test('isFavorite returns correct boolean', () async {
      final notifier = container.read(favoritesProvider.notifier);
      await notifier.toggleFavorite('x');
      expect(notifier.isFavorite('x'), isTrue);
      expect(notifier.isFavorite('y'), isFalse);
    });

    test('clearFavorites empties state', () async {
      final notifier = container.read(favoritesProvider.notifier);
      await notifier.toggleFavorite('a');
      await notifier.toggleFavorite('b');
      await notifier.clearFavorites();
      expect(container.read(favoritesProvider), isEmpty);
    });

    test('favoritesCount returns correct count', () async {
      final notifier = container.read(favoritesProvider.notifier);
      expect(notifier.favoritesCount, 0);
      await notifier.toggleFavorite('a');
      await notifier.toggleFavorite('b');
      expect(notifier.favoritesCount, 2);
    });
  });

  group('FavoritesNotifier race with initial load', () {
    test('toggleFavorite called before initial load finishes does not get '
        'clobbered by the in-flight load', () async {
      SharedPreferences.setMockInitialValues({
        'favorite_ids': ['p1', 'p2'],
      });

      final racing = ProviderContainer();
      addTearDown(racing.dispose);
      // No delay — toggleFavorite() must itself await the in-flight load.
      // Reading `.notifier` triggers build() (kicking off `_loadFavorites()`)
      // AND gives us the instance to call toggleFavorite() on, same tick.
      final racingNotifier = racing.read(favoritesProvider.notifier);
      await racingNotifier.toggleFavorite('p3');

      expect(racing.read(favoritesProvider), containsAll(['p1', 'p2', 'p3']));
      expect(racing.read(favoritesProvider), hasLength(3));

      // Confirm the toggle was actually persisted, not just clobbered back
      // in-memory by the late-finishing _loadFavorites().
      final verify = ProviderContainer();
      addTearDown(verify.dispose);
      verify.read(favoritesProvider); // trigger lazy build()
      await Future.delayed(const Duration(milliseconds: 50));
      expect(verify.read(favoritesProvider), containsAll(['p1', 'p2', 'p3']));
    });
  });

  group('FavoritesNotifier persistence', () {
    test('loads persisted favorites on init', () async {
      SharedPreferences.setMockInitialValues({
        'favorite_ids': ['p1', 'p2', 'p3'],
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(favoritesProvider.notifier);
      // Allow async _loadFavorites to complete
      await Future.delayed(const Duration(milliseconds: 50));

      expect(container.read(favoritesProvider), hasLength(3));
      expect(notifier.isFavorite('p1'), isTrue);
      expect(notifier.isFavorite('p2'), isTrue);
    });
  });
}
