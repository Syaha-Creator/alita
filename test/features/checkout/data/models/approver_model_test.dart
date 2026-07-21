import 'package:flutter_test/flutter_test.dart';

import 'package:alitapricelist/features/checkout/data/models/approver_model.dart';

void main() {
  group('Approver.fromJson', () {
    test('parses full valid payload', () {
      final approver = Approver.fromJson({
        'id': 5,
        'user_name': 'jdoe',
        'contact': {'full_name': 'John Doe'},
        'contact_work_experiences': [
          {'job_level_name': 'SPV'},
        ],
      });

      expect(approver.id, 5);
      expect(approver.userName, 'jdoe');
      expect(approver.fullName, 'John Doe');
      expect(approver.jobLevelName, 'SPV');
    });

    test('falls back to user_name when contact.full_name missing', () {
      final approver = Approver.fromJson({
        'id': 1,
        'user_name': 'jdoe',
      });

      expect(approver.fullName, 'jdoe');
      expect(approver.jobLevelName, '');
    });

    test('does not throw when contact is not a Map', () {
      final approver = Approver.fromJson({
        'id': 1,
        'user_name': 'jdoe',
        'contact': 'not-a-map',
      });

      expect(approver.fullName, 'jdoe');
    });

    test('does not throw when contact_work_experiences is not a List', () {
      final approver = Approver.fromJson({
        'id': 1,
        'user_name': 'jdoe',
        'contact_work_experiences': 'not-a-list',
      });

      expect(approver.jobLevelName, '');
    });

    test('does not throw when contact_work_experiences has non-Map elements', () {
      final approver = Approver.fromJson({
        'id': 1,
        'user_name': 'jdoe',
        'contact_work_experiences': ['not-a-map', 42],
      });

      expect(approver.jobLevelName, '');
    });
  });
}
