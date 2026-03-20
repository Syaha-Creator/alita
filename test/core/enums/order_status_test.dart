import 'package:flutter_test/flutter_test.dart';
import 'package:alitapricelist/core/enums/order_status.dart';

void main() {
  group('OrderStatusX.fromRaw', () {
    test('parses "approved"', () {
      expect(OrderStatusX.fromRaw('approved'), OrderStatus.approved);
    });

    test('parses "Approved" (case-insensitive)', () {
      expect(OrderStatusX.fromRaw('Approved'), OrderStatus.approved);
    });

    test('parses "true" as approved', () {
      expect(OrderStatusX.fromRaw('true'), OrderStatus.approved);
    });

    test('parses "1" as approved', () {
      expect(OrderStatusX.fromRaw('1'), OrderStatus.approved);
    });

    test('parses "pending"', () {
      expect(OrderStatusX.fromRaw('pending'), OrderStatus.pending);
    });

    test('parses empty string as pending', () {
      expect(OrderStatusX.fromRaw(''), OrderStatus.pending);
    });

    test('parses "rejected"', () {
      expect(OrderStatusX.fromRaw('rejected'), OrderStatus.rejected);
    });

    test('parses "ditolak" as rejected', () {
      expect(OrderStatusX.fromRaw('ditolak'), OrderStatus.rejected);
    });

    test('parses "false" as rejected', () {
      expect(OrderStatusX.fromRaw('false'), OrderStatus.rejected);
    });

    test('parses "0" as rejected', () {
      expect(OrderStatusX.fromRaw('0'), OrderStatus.rejected);
    });

    test('returns unknown for unrecognized value', () {
      expect(OrderStatusX.fromRaw('cancelled'), OrderStatus.unknown);
    });

    test('trims whitespace', () {
      expect(OrderStatusX.fromRaw('  approved  '), OrderStatus.approved);
    });
  });

  group('OrderStatusX.fromDynamic', () {
    test('null returns pending', () {
      expect(OrderStatusX.fromDynamic(null), OrderStatus.pending);
    });

    test('true returns approved', () {
      expect(OrderStatusX.fromDynamic(true), OrderStatus.approved);
    });

    test('false returns rejected', () {
      expect(OrderStatusX.fromDynamic(false), OrderStatus.rejected);
    });

    test('string delegates to fromRaw', () {
      expect(OrderStatusX.fromDynamic('ditolak'), OrderStatus.rejected);
    });

    test('int 1 returns approved', () {
      expect(OrderStatusX.fromDynamic(1), OrderStatus.approved);
    });

    test('int 0 returns rejected', () {
      expect(OrderStatusX.fromDynamic(0), OrderStatus.rejected);
    });
  });

  group('OrderStatusX.apiValue', () {
    test('approved returns "Approved"', () {
      expect(OrderStatus.approved.apiValue, 'Approved');
    });

    test('pending returns "Pending"', () {
      expect(OrderStatus.pending.apiValue, 'Pending');
    });

    test('rejected returns "Rejected"', () {
      expect(OrderStatus.rejected.apiValue, 'Rejected');
    });

    test('unknown returns "Unknown"', () {
      expect(OrderStatus.unknown.apiValue, 'Unknown');
    });
  });
}
