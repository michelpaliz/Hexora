import 'package:flutter/material.dart';
import 'package:hexora/b-backend/auth_user/user/domain/user_domain.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/group_mng_flow/group/view_model/group_view_model.dart';
import 'package:hexora/b-backend/group_mng_flow/invite/repository/invite_repository.dart';
import 'package:hexora/b-backend/notification/domain/notification_domain.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/group/create-group/search-bar/screens/page_group_role_list.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/group/create-group/search-bar/widgets/save_group_button.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/utils/shared/add_user_button/add_user_button.dart';
import 'package:hexora/f-themes/shape/solid/solid_header.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../widgets/group_image_picker.dart';
import '../widgets/group_text_fields.dart';

class CreateGroupData extends StatefulWidget {
  const CreateGroupData({super.key});

  @override
  State<CreateGroupData> createState() => _CreateGroupDataState();
}

class _CreateGroupDataState extends State<CreateGroupData> {
  final ImagePicker _imagePicker = ImagePicker();
  final GroupViewModel _controller = GroupViewModel();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final userDomain = Provider.of<UserDomain>(context, listen: false);
    final groupDomain = Provider.of<GroupDomain>(context, listen: false);
    final notificationDomain =
        Provider.of<NotificationDomain>(context, listen: false);
    final invitationRepo =
        Provider.of<InvitationRepository>(context, listen: false);
    final currentUser = userDomain.user;

    if (currentUser != null) {
      _controller.initialize(
        user: currentUser,
        userDomain: userDomain,
        groupDomain: groupDomain,
        notificationDomain: notificationDomain,
        invitationRepository: invitationRepo,
        context: context,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<GroupViewModel>.value(
      value: _controller,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.groupData)),
        body: Stack(
          children: [
            const SolidHeader(height: 180),
            SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 15.0, vertical: 30.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const GroupImagePicker(),
                  GroupTextFields(controller: _controller),
                  const SizedBox(height: 10),

                  // ⬇️ Refactored Add button (uses new component)
                  Align(
                    alignment: Alignment.centerRight,
                    child: AddUserButton(
                      currentUser: _controller.currentUser,
                      group: null, // optional here during creation
                      controller: _controller,
                      onUserAdded: (picked) => _controller.addMember(picked),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ⬇️ Rebuild this section when controller updates
                  Consumer<GroupViewModel>(
                    builder: (_, ctrl, __) => PagedGroupRoleList(
                      userRoles: ctrl.userRoles,
                      membersById: ctrl.membersById,
                      assignableRoles: ctrl.assignableRoles,
                      canEditRole: ctrl.canEditRole,
                      setRole: ctrl.setRole,
                      onRemoveUser: ctrl.removeUser,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.all(16),
          child: SaveGroupButton(controller: _controller),
        ),
      ),
    );
  }
}
