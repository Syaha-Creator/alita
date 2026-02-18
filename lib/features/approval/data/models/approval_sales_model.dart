import 'package:equatable/equatable.dart';

/// Model for a single approver from approval_sales API
class ApprovalSalesUserModel extends Equatable {
  final int id;
  final String userName;
  final String email;
  final String fullName;
  final List<ApprovalSalesWorkExperienceModel> workExperiences;

  const ApprovalSalesUserModel({
    required this.id,
    required this.userName,
    required this.email,
    required this.fullName,
    required this.workExperiences,
  });

  factory ApprovalSalesUserModel.fromJson(Map<String, dynamic> json) {
    final contact = json['contact'] as Map<String, dynamic>?;
    final workExpList =
        json['contact_work_experiences'] as List<dynamic>? ?? [];

    return ApprovalSalesUserModel(
      id: json['id'] ?? 0,
      userName: json['user_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: contact?['full_name']?.toString() ?? '',
      workExperiences: workExpList
          .map((e) => ApprovalSalesWorkExperienceModel.fromJson(
              e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Get display name (prefer full_name, fallback to user_name)
  String get displayName =>
      fullName.trim().isNotEmpty ? fullName.trim() : userName;

  /// Get primary job title (first work experience)
  String get primaryJobTitle =>
      workExperiences.isNotEmpty ? workExperiences.first.workTitle : '';

  /// Get primary job level name
  String get primaryJobLevelName =>
      workExperiences.isNotEmpty ? workExperiences.first.jobLevelName : '';

  @override
  List<Object?> get props => [id, userName, email, fullName, workExperiences];

  @override
  String toString() => displayName;
}

/// Model for work experience within approval sales
class ApprovalSalesWorkExperienceModel extends Equatable {
  final int id;
  final String workTitle;
  final int jobLevel;
  final String jobLevelName;
  final int department;
  final String departmentName;

  const ApprovalSalesWorkExperienceModel({
    required this.id,
    required this.workTitle,
    required this.jobLevel,
    required this.jobLevelName,
    required this.department,
    required this.departmentName,
  });

  factory ApprovalSalesWorkExperienceModel.fromJson(Map<String, dynamic> json) {
    return ApprovalSalesWorkExperienceModel(
      id: json['id'] ?? 0,
      workTitle: json['work_title']?.toString() ?? '',
      jobLevel: json['job_level'] ?? 0,
      jobLevelName: json['job_level_name']?.toString() ?? '',
      department: json['departement'] ?? 0,
      departmentName: json['departement_name']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props =>
      [id, workTitle, jobLevel, jobLevelName, department, departmentName];
}

/// Response model for approval_sales API
class ApprovalSalesResponse {
  final List<ApprovalSalesUserModel> users;

  const ApprovalSalesResponse({required this.users});

  factory ApprovalSalesResponse.fromJson(Map<String, dynamic> json) {
    final result = json['result'] as Map<String, dynamic>?;
    final usersList = result?['users'] as List<dynamic>? ?? [];

    return ApprovalSalesResponse(
      users: usersList
          .map((e) =>
              ApprovalSalesUserModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Check if response has users
  bool get hasUsers => users.isNotEmpty;
}
