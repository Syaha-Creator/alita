class TeamHierarchyModel {
  final String status;
  final String supervisorId;
  final int totalDirectTeams;
  final int totalAllTeams;
  final List<TeamMember> teams;

  TeamHierarchyModel({
    required this.status,
    required this.supervisorId,
    required this.totalDirectTeams,
    required this.totalAllTeams,
    required this.teams,
  });

  factory TeamHierarchyModel.fromJson(Map<String, dynamic> json) {
    return TeamHierarchyModel(
      status: json['status'] as String? ?? '',
      supervisorId: json['supervisor_id'] as String? ?? '',
      totalDirectTeams: json['total_direct_teams'] as int? ?? 0,
      totalAllTeams: json['total_all_teams'] as int? ?? 0,
      teams: (json['teams'] as List<dynamic>?)
              ?.map((team) => TeamMember.fromJson(team as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'supervisor_id': supervisorId,
      'total_direct_teams': totalDirectTeams,
      'total_all_teams': totalAllTeams,
      'teams': teams.map((team) => team.toJson()).toList(),
    };
  }

  /// Get all subordinate user IDs (including nested teams)
  List<int> getAllSubordinateUserIds() {
    List<int> userIds = [];

    for (final team in teams) {
      // Add direct team member
      userIds.add(team.userId);

      // Add their direct teams (nested)
      for (final directTeam in team.directTeams) {
        userIds.add(directTeam.userId);
      }
    }

    return userIds;
  }

  /// Check if user has subordinates
  bool hasSubordinates() {
    return totalDirectTeams > 0;
  }
}

class TeamMember {
  final int userId;
  final String fullname;
  final List<DirectTeam> directTeams;

  TeamMember({
    required this.userId,
    required this.fullname,
    required this.directTeams,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      userId: json['user_id'] as int? ?? 0,
      fullname: json['fullname'] as String? ?? '',
      directTeams: (json['direct_teams'] as List<dynamic>?)
              ?.map((team) => DirectTeam.fromJson(team as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'fullname': fullname,
      'direct_teams': directTeams.map((team) => team.toJson()).toList(),
    };
  }
}

class DirectTeam {
  final int userId;
  final String fullname;

  DirectTeam({
    required this.userId,
    required this.fullname,
  });

  factory DirectTeam.fromJson(Map<String, dynamic> json) {
    return DirectTeam(
      userId: json['user_id'] as int? ?? 0,
      fullname: json['fullname'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'fullname': fullname,
    };
  }
}
