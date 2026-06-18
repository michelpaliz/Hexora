/// Model for the `GET /api/groups/:id/permissions` endpoint.
class RoleDefinition {
  final String wire;
  final String label;
  final String? description;
  final Map<String, bool> permissions;

  const RoleDefinition({
    required this.wire,
    required this.label,
    this.description,
    required this.permissions,
  });

  factory RoleDefinition.fromJson(Map<String, dynamic> json) {
    final rawPermissions = json['permissions'];
    return RoleDefinition(
      wire: json['wire'] as String? ?? '',
      label: json['label'] as String? ?? json['wire'] as String? ?? '',
      description: json['description'] as String?,
      permissions: rawPermissions is Map<String, dynamic>
          ? rawPermissions.map((k, v) => MapEntry(k, v == true))
          : const {},
    );
  }
}

class GroupPermissionsResponse {
  final String currentUserRole;
  final Map<String, bool> permissions;
  final List<RoleDefinition> roleDefinitions;

  const GroupPermissionsResponse({
    required this.currentUserRole,
    required this.permissions,
    required this.roleDefinitions,
  });

  factory GroupPermissionsResponse.fromJson(Map<String, dynamic> json) {
    final currentUser = json['currentUser'];
    final rawRole = json['currentUserRole'] ??
        (currentUser is Map<String, dynamic> ? currentUser['role'] : null) ??
        'member';
    final rawPermissions = json['permissions'] ?? json['permissionDetails'];
    final rawRoleDefinitions = json['roleDefinitions'];
    final roleDefinitions =
        rawRoleDefinitions is List<dynamic> ? rawRoleDefinitions : const [];

    return GroupPermissionsResponse(
      currentUserRole: rawRole.toString(),
      permissions: rawPermissions is Map<String, dynamic>
          ? rawPermissions.map((k, v) => MapEntry(k, v == true))
          : const {},
      roleDefinitions: roleDefinitions
          .whereType<Map<String, dynamic>>()
          .map(RoleDefinition.fromJson)
          .toList(),
    );
  }
}
