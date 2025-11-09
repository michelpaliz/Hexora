import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/c-frontend/utils/enums/group_role/group_role.dart';
import 'package:share_plus/share_plus.dart';

class GroupEditorState {
  final String name;
  final String description;
  final XFile? image;
  final Map<String, User> membersById; // userId -> User
  final Map<String, GroupRole> roles; // userId -> role

  const GroupEditorState({
    this.name = '',
    this.description = '',
    this.image,
    this.membersById = const {},
    this.roles = const {},
  });

  GroupEditorState copyWith({
    String? name,
    String? description,
    XFile? image,
    Map<String, User>? membersById,
    Map<String, GroupRole>? roles,
  }) =>
      GroupEditorState(
        name: name ?? this.name,
        description: description ?? this.description,
        image: image ?? this.image,
        membersById: membersById ?? this.membersById,
        roles: roles ?? this.roles,
      );
}
