import '../../../../core/utils/safe_json_list.dart';

/// Represents a single approver (SPV / ASM / Manager) returned by the approval_sales API.
class Approver {
  final int id;
  final String userName;
  final String fullName;
  final String jobLevelName;

  const Approver({
    required this.id,
    required this.userName,
    required this.fullName,
    required this.jobLevelName,
  });

  factory Approver.fromJson(Map<String, dynamic> json) {
    final contactRaw = json['contact'];
    final contact = contactRaw is Map
        ? Map<String, dynamic>.from(contactRaw)
        : <String, dynamic>{};
    final cweList = safeMapList(
      json['contact_work_experiences'],
      fieldName: 'contact_work_experiences',
    );
    final cwe = cweList.isNotEmpty ? cweList.first : <String, dynamic>{};

    return Approver(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userName: json['user_name'] as String? ?? '',
      fullName: contact['full_name'] as String? ??
          json['user_name'] as String? ??
          '',
      jobLevelName: cwe['job_level_name'] as String? ?? '',
    );
  }

  /// Display label shown in the dropdown — name only, no role suffix.
  String get displayLabel => fullName;

  @override
  bool operator ==(Object other) => other is Approver && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
