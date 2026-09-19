import 'package:hexora/models/groups/group.dart';
import 'package:hexora/models/user/user.dart';

class EditGroupArguments {
  final Group group;
  final List<User> users;

  EditGroupArguments({required this.group, required this.users});
}
