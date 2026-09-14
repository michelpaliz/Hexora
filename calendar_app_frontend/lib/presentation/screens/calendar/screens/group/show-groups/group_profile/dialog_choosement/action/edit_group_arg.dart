import 'package:hexora/models/group_model/group/group.dart';
import 'package:hexora/models/user_model/user.dart';

class EditGroupArguments {
  final Group group;
  final List<User> users;

  EditGroupArguments({required this.group, required this.users});
}
