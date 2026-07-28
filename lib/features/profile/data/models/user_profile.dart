import '../../../../core/utils/safe_json_list.dart';

Map<String, dynamic> _asMapOrEmpty(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : const {};

class UserProfile {
  final int id;
  final String name;
  final String email;
  final String workTitle;
  final String workPlaceName;
  final String areaName;
  final String imageUrl;
  /// ID dari `company` (bukan work_place). Digunakan untuk approval_sales API.
  /// Contoh: company.id = 2 (PT. MASSINDO KARYA PRIMA).
  final int companyId;
  /// Integer ID of the user's area. Used for approval API calls.
  final int areaId;
  /// Raw divisions list from the API. Each entry is a Map with at least an 'id' key.
  final List<Map<String, dynamic>> divisions;

  UserProfile({
    this.id = 0,
    required this.name,
    required this.email,
    required this.workTitle,
    required this.workPlaceName,
    required this.areaName,
    this.imageUrl = '',
    this.companyId = 0,
    this.areaId = 0,
    this.divisions = const [],
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final user = _asMapOrEmpty(json['user']);
    final workPlace = _asMapOrEmpty(json['work_place']);
    final area = _asMapOrEmpty(json['area']);
    // `company` di level CWE adalah entitas bisnis (PT), berbeda dengan
    // `work_place` yang merupakan lokasi fisik (mis. MASSINDO-INTERCON).
    // approval_sales API butuh company.id, bukan work_place.id.
    final company = _asMapOrEmpty(json['company']);

    return UserProfile(
      id: (user['id'] as num?)?.toInt() ?? 0,
      name: user['name']?.toString() ?? 'Unknown User',
      email: user['email']?.toString() ?? '-',
      workTitle: json['work_title']?.toString() ?? 'Staff',
      workPlaceName: workPlace['name']?.toString() ?? '-',
      areaName: area['name']?.toString() ?? '-',
      imageUrl: '',
      companyId: (company['id'] as num?)?.toInt() ?? 0,
      areaId: (area['id'] as num?)?.toInt() ?? 0,
      divisions: safeMapList(json['divisions'], fieldName: 'divisions'),
    );
  }
}
