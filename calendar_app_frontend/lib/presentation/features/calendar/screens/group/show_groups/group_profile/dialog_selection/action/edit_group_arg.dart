import 'package:hexora/models/group/group.dart';
import 'package:hexora/models/user/user.dart';

class EditGroupArguments {
  final Group group;
  final List<User> users;

  EditGroupArguments({required this.group, required this.users});
}
