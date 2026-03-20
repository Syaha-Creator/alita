import 'package:flutter_test/flutter_test.dart';
import 'package:alitapricelist/features/checkout/data/utils/take_away_splitter.dart';

void main() {
  group('TakeAwaySplitter.split', () {
    test('all take-away returns single take-away segment', () {
      final result = TakeAwaySplitter.split(totalQty: 5, takeAwayQty: 5);
      expect(result, hasLength(1));
      expect(result[0].qty, 5);
      expect(result[0].isTakeAway, isTrue);
      expect(result[0].note, 'Bawa Langsung');
    });

    test('all delivery returns single delivery segment', () {
      final result = TakeAwaySplitter.split(totalQty: 5, takeAwayQty: 0);
      expect(result, hasLength(1));
      expect(result[0].qty, 5);
      expect(result[0].isTakeAway, isFalse);
      expect(result[0].note, 'Dikirim');
    });

    test('mixed split returns two segments', () {
      final result = TakeAwaySplitter.split(totalQty: 10, takeAwayQty: 3);
      expect(result, hasLength(2));

      expect(result[0].qty, 3);
      expect(result[0].isTakeAway, isTrue);

      expect(result[1].qty, 7);
      expect(result[1].isTakeAway, isFalse);
    });

    test('zero total returns empty list', () {
      final result = TakeAwaySplitter.split(totalQty: 0, takeAwayQty: 0);
      expect(result, isEmpty);
    });

    test('negative total treated as zero', () {
      final result = TakeAwaySplitter.split(totalQty: -5, takeAwayQty: 2);
      expect(result, isEmpty);
    });

    test('takeAway clamped to total when exceeding', () {
      final result = TakeAwaySplitter.split(totalQty: 3, takeAwayQty: 10);
      expect(result, hasLength(1));
      expect(result[0].qty, 3);
      expect(result[0].isTakeAway, isTrue);
    });

    test('negative takeAway clamped to zero', () {
      final result = TakeAwaySplitter.split(totalQty: 5, takeAwayQty: -2);
      expect(result, hasLength(1));
      expect(result[0].qty, 5);
      expect(result[0].isTakeAway, isFalse);
    });
  });
}
