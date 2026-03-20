import 'package:flutter_test/flutter_test.dart';
import 'package:alitapricelist/features/profile/data/models/user_profile.dart';

void main() {
  group('UserProfile.fromJson', () {
    test('parses full json correctly', () {
      final json = _fullJson();
      final profile = UserProfile.fromJson(json);

      expect(profile.id, 5);
      expect(profile.name, 'Syahrul');
      expect(profile.email, 'syahrul@test.com');
      expect(profile.workTitle, 'Sales Consultant');
      expect(profile.workPlaceName, 'Sleep Center Intercon');
      expect(profile.areaName, 'Jakarta');
      expect(profile.companyId, 2);
      expect(profile.areaId, 10);
      expect(profile.divisions, hasLength(2));
    });

    test('handles missing user map', () {
      final json = <String, dynamic>{};
      final profile = UserProfile.fromJson(json);

      expect(profile.id, 0);
      expect(profile.name, 'Unknown User');
      expect(profile.email, '-');
      expect(profile.workTitle, 'Staff');
      expect(profile.workPlaceName, '-');
      expect(profile.areaName, 'Nasional');
      expect(profile.companyId, 0);
      expect(profile.areaId, 0);
      expect(profile.divisions, isEmpty);
    });

    test('handles null nested values', () {
      final json = <String, dynamic>{
        'user': {'id': null, 'name': null, 'email': null},
        'work_place': {'name': null},
        'area': {'name': null, 'id': null},
        'company': {'id': null},
        'work_title': null,
        'divisions': null,
      };

      final profile = UserProfile.fromJson(json);
      expect(profile.id, 0);
      expect(profile.name, 'Unknown User');
      expect(profile.email, '-');
      expect(profile.workTitle, 'Staff');
      expect(profile.areaId, 0);
      expect(profile.companyId, 0);
      expect(profile.divisions, isEmpty);
    });

    test('parses numeric id as int from num', () {
      final json = <String, dynamic>{
        'user': {'id': 3.0, 'name': 'Test', 'email': 'a@b.com'},
      };

      final profile = UserProfile.fromJson(json);
      expect(profile.id, 3);
    });

    test('filters non-map items from divisions', () {
      final json = <String, dynamic>{
        'divisions': ['string-item', {'id': 1}, null, {'id': 2}],
      };

      final profile = UserProfile.fromJson(json);
      expect(profile.divisions, hasLength(2));
      expect(profile.divisions[0]['id'], 1);
      expect(profile.divisions[1]['id'], 2);
    });
  });
}

Map<String, dynamic> _fullJson() => {
      'user': {
        'id': 5,
        'name': 'Syahrul',
        'email': 'syahrul@test.com',
      },
      'work_title': 'Sales Consultant',
      'work_place': {'name': 'Sleep Center Intercon'},
      'area': {'name': 'Jakarta', 'id': 10},
      'company': {'id': 2},
      'divisions': [
        {'id': 1, 'name': 'Division A'},
        {'id': 2, 'name': 'Division B'},
      ],
    };
