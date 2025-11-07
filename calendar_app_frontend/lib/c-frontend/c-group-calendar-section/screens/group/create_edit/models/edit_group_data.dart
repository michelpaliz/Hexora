import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/b-backend/notification/domain/notification_domain.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/group/create_edit/widgets/edit_group/edit_group_body.dart';
import 'package:provider/provider.dart';
class EditGroupData extends StatefulWidget {
  final Group group;
  final List<User> users;

  const EditGroupData({required this.group, required this.users, Key? key})
      : super(key: key);

  @override
  _EditGroupDataState createState() => _EditGroupDataState();
}

class _EditGroupDataState extends State<EditGroupData> {
  late UserDomain? _userDomain;
  late GroupDomain _groupDomain;
  late NotificationDomain _notificationDomain;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _userDomain = Provider.of<UserDomain>(context, listen: false);
    _groupDomain = Provider.of<GroupDomain>(context, listen: false);
    _notificationDomain = Provider.of<NotificationDomain>(
      context,
      listen: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return EditGroupBody(
      group: widget.group,
      users: widget.users,
      userDomain: _userDomain!,
      groupDomain: _groupDomain,
      notificationDomain: _notificationDomain,
    );
  }
}
