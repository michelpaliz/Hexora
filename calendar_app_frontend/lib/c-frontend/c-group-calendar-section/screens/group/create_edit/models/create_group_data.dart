// lib/.../create_group_data.dart

import 'package:flutter/material.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/b-backend/group_mng_flow/group/view_model/group_view_model.dart';
import 'package:hexora/b-backend/group_mng_flow/group/view_model/presentation/common/ui_messenger.dart';
import 'package:hexora/b-backend/group_mng_flow/group/view_model/presentation/group_editor_state.dart/group_editor_state.dart';
import 'package:hexora/b-backend/group_mng_flow/group/view_model/presentation/use_cases/create_group_usecase.dart';
import 'package:hexora/b-backend/group_mng_flow/group/view_model/presentation/use_cases/invite_members_usecase.dart';
import 'package:hexora/b-backend/group_mng_flow/group/view_model/presentation/use_cases/search_users_usecase.dart';
import 'package:hexora/b-backend/group_mng_flow/group/view_model/presentation/use_cases/upload_group_photo_usecase.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/group/create_edit/widgets/buttons/save_group_button.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/group/create_edit/widgets/fields/group_description_field.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/group/create_edit/widgets/fields/group_name_field.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/group/create_edit/widgets/images/group_image.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/group/create_edit/widgets/lists/page_group_role_list.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/utils/shared/add_user_button/add_user_button.dart';
import 'package:hexora/f-themes/shapes/solid/solid_header.dart';
import 'package:hexora/c-frontend/utils/enums/group_role/group_role.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class CreateGroupData extends StatefulWidget {
  const CreateGroupData({super.key});

  @override
  State<CreateGroupData> createState() => _CreateGroupDataState();
}

class _CreateGroupDataState extends State<CreateGroupData> {
  final ImagePicker _imagePicker = ImagePicker();

  // move text controllers to the widget
  late final TextEditingController _nameC;
  late final TextEditingController _descC;

  @override
  void initState() {
    super.initState();
    _nameC = TextEditingController();
    _descC = TextEditingController();
  }

  @override
  void dispose() {
    _nameC.dispose();
    _descC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userDomain = context.read<UserDomain>();
    final currentUser = userDomain.user;
    if (currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return ChangeNotifierProvider<GroupEditorViewModel>(
      create: (c) => GroupEditorViewModel(
        currentUser: currentUser,
        ui: MaterialUiMessenger(context),
        createGroup: c.read<CreateGroupUseCase>(),
        inviteMembers: c.read<InviteMembersUseCase>(),
        uploadPhoto: c.read<UploadGroupPhotoUseCase>(),
        searchUsersUseCase: c.read<SearchUsersUseCase>(),
      ),
      child: Builder(
        builder: (context) {
          final vm = context.watch<GroupEditorViewModel>();

          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            appBar:
                AppBar(title: Text(AppLocalizations.of(context)!.groupData)),
            body: Stack(
              children: [
                const SolidHeader(height: 180),
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 15.0, vertical: 30.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      const GroupImage(), // keep as-is; hook into vm.setImage from inside if needed

                      // name
                      GroupNameField(
                        controller: _nameC,
                        onChanged: vm.setName, // tell VM the text
                      ),
                      const SizedBox(height: 10),

                      // description
                      GroupDescriptionField(
                        controller: _descC,
                        onChanged: vm.setDescription, // tell VM the text
                      ),
                      const SizedBox(height: 10),

                      Align(
                        alignment: Alignment.centerRight,
                        child: AddUserButton(
                          currentUser: currentUser,
                          group: null,
                          // pass the new VM
                          controller: vm,
                          onUserAdded: (picked) => vm.addMember(picked),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // legacy role list – feed compat props
                      PagedGroupRoleList(
                        roles: vm.state.roles, // Map<String, GroupRole>
                        membersById: vm.state.membersById, // Map<String, User>
                        assignableRoles: const [
                          // what users can assign
                          GroupRole.member,
                          GroupRole.coAdmin,
                        ],
                        canEditRole: vm.canEditRole, // (String) -> bool
                        setRole: vm.setRole, // (String, GroupRole) -> void
                        onRemoveUser: vm.removeMember, // (String) -> void
                      ),
                    ],
                  ),
                ),
              ],
            ),
            bottomNavigationBar: SafeArea(
              minimum: const EdgeInsets.all(16),
              child: SaveGroupButton(
                  controller: vm), // button calls submit()/alias
            ),
          );
        },
      ),
    );
  }
}
