import 'package:hexora/models/user/user.dart';
import 'package:hexora/presentation/utils/roles/group_role.dart';
import 'package:share_plus/share_plus.dart';

const _unchangedImage = Object();

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
    Object? image = _unchangedImage,
    Map<String, User>? membersById,
    Map<String, GroupRole>? roles,
  }) =>
      GroupEditorState(
        name: name ?? this.name,
        description: description ?? this.description,
        image: identical(image, _unchangedImage) ? this.image : image as XFile?,
        membersById: membersById ?? this.membersById,
        roles: roles ?? this.roles,
      );
}
