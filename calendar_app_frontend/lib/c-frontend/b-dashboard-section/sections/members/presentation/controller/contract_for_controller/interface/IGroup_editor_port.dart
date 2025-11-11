// lib/domain/ports/i_group_editor_port.dart
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/c-frontend/utils/roles/group_role/group_role.dart';

abstract class IGroupEditorPort {
  // Queries
  Future<List<User>> searchUsers(String query, {int limit});

  // Mutations (VM remains the source of truth)
  void addMember(User user);
  void removeMember(String userId);
  void setRole(String userId, GroupRole role);

  // Policies / helpers
  bool canEditRole(String userId);
  List<GroupRole> assignableRolesFor(String userId);

  // Snapshots for rendering (read-only views of VM state)
  Map<String, User> get membersById;
  Map<String, GroupRole> get roles;

  Future<void> seedMembers({
    required Map<String, User> membersById,
    required Map<String, GroupRole> roles,
  });
}
