import 'package:flutter_test/flutter_test.dart';

import 'package:alitapricelist/features/approval/logic/approval_inbox_provider.dart';

void main() {
  group('ApprovalInboxState', () {
    test('defaults', () {
      const s = ApprovalInboxState();
      expect(s.isLoading, true);
      expect(s.error, isNull);
      expect(s.pendingApprovals, isEmpty);
      expect(s.historyApprovals, isEmpty);
      expect(s.startDate, isNull);
      expect(s.endDate, isNull);
    });

    test('copyWith preserves unchanged fields', () {
      const s = ApprovalInboxState(
        isLoading: false,
        pendingApprovals: [1, 2, 3],
      );
      final copy = s.copyWith(error: 'network');
      expect(copy.isLoading, false);
      expect(copy.pendingApprovals, hasLength(3));
      expect(copy.error, 'network');
    });

    test('copyWith replaces loading + pending', () {
      const s = ApprovalInboxState();
      final updated = s.copyWith(
        isLoading: false,
        pendingApprovals: [{'id': 1}],
        historyApprovals: [{'id': 2}],
      );
      expect(updated.isLoading, false);
      expect(updated.pendingApprovals, hasLength(1));
      expect(updated.historyApprovals, hasLength(1));
    });

    test('copyWith can set date range', () {
      final start = DateTime(2026, 1, 1);
      final end = DateTime(2026, 1, 31);
      final s = const ApprovalInboxState().copyWith(
        startDate: start,
        endDate: end,
      );
      expect(s.startDate, start);
      expect(s.endDate, end);
    });

    test('copyWith clears error when clearError is true', () {
      const s = ApprovalInboxState(
        isLoading: false,
        error: 'network',
      );
      final cleared = s.copyWith(isLoading: true, clearError: true);
      expect(cleared.error, isNull);
      expect(cleared.isLoading, true);
    });

    test('copyWith(error: null) alone does not clear existing error', () {
      const s = ApprovalInboxState(error: 'stale');
      // Without clearError, null means "leave unchanged" (same as freezed).
      final copy = s.copyWith(error: null);
      expect(copy.error, 'stale');
    });
  });

  group('ApprovalLocation', () {
    test('stores address and coordinates', () {
      const loc = ApprovalLocation(
        address: 'Jakarta',
        latitude: -6.2,
        longitude: 106.8,
      );
      expect(loc.address, 'Jakarta');
      expect(loc.latitude, -6.2);
      expect(loc.longitude, 106.8);
    });
  });
}
