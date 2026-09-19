/// Metadata for a member's current role assignment.
class RoleMeta {
  final String role;
  final DateTime? roleAssignedAt;
  final String? roleAssignedBy;

  const RoleMeta({
    required this.role,
    this.roleAssignedAt,
    this.roleAssignedBy,
  });

  factory RoleMeta.fromJson(Map<String, dynamic> json) {
    return RoleMeta(
      role: (json['role'] ?? '').toString(),
      roleAssignedAt: _parseDate(json['roleAssignedAt']),
      roleAssignedBy: json['roleAssignedBy']?.toString(),
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is String) return DateTime.tryParse(v);
    if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
    return null;
  }
}

/// A single entry in a member's role-change history.
class RoleHistoryEntry {
  final String role;
  final DateTime assignedAt;
  final String? assignedBy;

  const RoleHistoryEntry({
    required this.role,
    required this.assignedAt,
    this.assignedBy,
  });

  factory RoleHistoryEntry.fromJson(Map<String, dynamic> json) {
    return RoleHistoryEntry(
      role: (json['role'] ?? '').toString(),
      assignedAt:
          DateTime.tryParse((json['assignedAt'] ?? '').toString()) ??
              DateTime.now(),
      assignedBy: json['assignedBy']?.toString(),
    );
  }
}
