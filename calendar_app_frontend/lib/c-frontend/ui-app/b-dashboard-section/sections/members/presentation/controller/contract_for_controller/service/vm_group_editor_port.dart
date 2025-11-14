// lib/adapters/vm_group_editor_port.dart
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/c-frontend/viewmodels/group_vm/view_model/group_view_model.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/members/presentation/controller/contract_for_controller/interface/IGroup_editor_port.dart';
import 'package:hexora/c-frontend/utils/roles/group_role/group_role.dart';

class VmGroupEditorPort implements IGroupEditorPort {
  final GroupEditorViewModel vm;
  VmGroupEditorPort(this.vm);

  @override
  Future<List<User>> searchUsers(String q, {int limit = 20}) =>
      vm.searchUsers(q, limit: limit);

  @override
  void addMember(User user) => vm.addMember(user);

  @override
  void removeMember(String userId) => vm.removeMember(userId);

  @override
  void setRole(String userId, GroupRole role) => vm.setRole(userId, role);

  @override
  bool canEditRole(String userId) => vm.canEditRole(userId);

  @override
  List<GroupRole> assignableRolesFor(String userId) =>
      vm.assignableRolesFor(userId);

  @override
  Map<String, User> get membersById => vm.state.membersById;

  @override
  Map<String, GroupRole> get roles => vm.state.roles;

  @override
  Future<void> seedMembers({
    required Map<String, User> membersById,
    required Map<String, GroupRole> roles,
  }) async {
    // directly update VM state through its public methods
    for (final u in membersById.values) {
      vm.addMember(u);
    }
    roles.forEach((userId, role) {
      vm.setRole(userId, role);
    });
  }
}
