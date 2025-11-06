import 'package:flutter/material.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:hexora/b-backend/group_mng_flow/group/view_model/presentation/common/ui_messenger.dart';
import 'package:hexora/b-backend/group_mng_flow/group/view_model/presentation/group_editor_state.dart/group_editor_state.dart';
import 'package:hexora/b-backend/group_mng_flow/group/view_model/presentation/use_cases/create_group_usecase.dart';
import 'package:hexora/b-backend/group_mng_flow/group/view_model/presentation/use_cases/invite_members_usecase.dart';
import 'package:hexora/b-backend/group_mng_flow/group/view_model/presentation/use_cases/search_users_usecase.dart';
import 'package:hexora/b-backend/group_mng_flow/group/view_model/presentation/use_cases/upload_group_photo_usecase.dart';
import 'package:image_picker/image_picker.dart';

enum GroupEditorStatus { idle, loading, error, success }

/// The backtick character (`) in Dart is used to create a multi-line string. It allows you to write a
/// string that spans multiple lines without having to use escape characters like \n for new lines. This
/// can make your code more readable and maintainable when dealing with long strings or multiline text.

class GroupEditorViewModel extends ChangeNotifier {
  GroupEditorState _state = const GroupEditorState();
  GroupEditorStatus status = GroupEditorStatus.idle;

  final User currentUser;
  final UiMessenger ui;
  final CreateGroupUseCase createGroup;
  final InviteMembersUseCase inviteMembers;
  final UploadGroupPhotoUseCase uploadPhoto;
  final SearchUsersUseCase searchUsersUseCase; // <-- NEW

  GroupEditorViewModel({
    required this.currentUser,
    required this.ui,
    required this.createGroup,
    required this.inviteMembers,
    required this.uploadPhoto,
    required this.searchUsersUseCase,
  }) {
    _state = _state.copyWith(
      membersById: {currentUser.id: currentUser},
      roles: {currentUser.id: GroupRole.owner},
    );
  }

  GroupEditorState get state => _state;

  // Temporary alias so old widgets keep compiling
  Future<void> submitGroupFromUI() => submit();

  // setters
  void setName(String v) => _update(_state.copyWith(name: v.trim()));
  void setDescription(String v) =>
      _update(_state.copyWith(description: v.trim()));
  void setImage(XFile? f) => _update(_state.copyWith(image: f));

  bool canEditRole(String userId) {
    // cannot edit yourself; cannot edit the owner
    return userId != currentUser.id && _state.roles[userId] != GroupRole.owner;
  }

  // members
  void addMember(User u) {
    if (_state.membersById.containsKey(u.id)) return;
    final m = Map<String, User>.from(_state.membersById)..[u.id] = u;
    final r = Map<String, GroupRole>.from(_state.roles)
      ..putIfAbsent(u.id, () => GroupRole.member);
    _update(_state.copyWith(membersById: m, roles: r));
  }

  void removeMember(String userId) {
    if (userId == currentUser.id) {
      ui.showSnack("You can't remove yourself");
      return;
    }
    final m = Map<String, User>.from(_state.membersById)..remove(userId);
    final r = Map<String, GroupRole>.from(_state.roles)..remove(userId);
    _update(_state.copyWith(membersById: m, roles: r));
  }

  void setRole(String userId, GroupRole role) {
    if (userId == currentUser.id) return;
    if (_state.roles[userId] == GroupRole.owner) return;
    final r = Map<String, GroupRole>.from(_state.roles)..[userId] = role;
    _update(_state.copyWith(roles: r));
  }

  // <-- NEW: passthrough so your sheet can call vm.searchUsers(query)
  Future<List<User>> searchUsers(String query, {int limit = 20}) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    return await searchUsersUseCase(ApiConstants.baseUrl, q, limit: limit);
  }

  Future<void> submit() async {
    if (_state.name.isEmpty || _state.description.isEmpty) {
      await ui.showError('Name and description are required');
      return;
    }
    status = GroupEditorStatus.loading;
    notifyListeners();
    try {
      final created = await createGroup(
        name: _state.name,
        description: _state.description,
        owner: currentUser,
      );

      await inviteMembers(
        groupId: created.id,
        members: _state.membersById.values.toList(),
        owner: currentUser,
        roles: _state.roles,
      );

      if (_state.image != null) {
        await uploadPhoto(groupId: created.id, file: _state.image!);
      }

      status = GroupEditorStatus.success;
      notifyListeners();
      ui.showSnack('Group created!');
      ui.pop();
    } catch (e) {
      status = GroupEditorStatus.error;
      notifyListeners();
      await ui.showError('Failed to create group');
    }
  }

  void _update(GroupEditorState s) {
    _state = s;
    notifyListeners();
  }
}
