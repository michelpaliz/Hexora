import 'package:flutter/material.dart';
import 'package:hexora/b-backend/group_mng_flow/group/view_model/group_view_model.dart';
import 'package:hexora/b-backend/group_mng_flow/group/view_model/presentation/common/ui_messenger.dart';
import 'package:hexora/b-backend/group_mng_flow/group/view_model/presentation/use_cases/create_group_usecase.dart';
import 'package:hexora/b-backend/group_mng_flow/group/view_model/presentation/use_cases/invite_members_usecase.dart';
import 'package:hexora/b-backend/group_mng_flow/group/view_model/presentation/use_cases/search_users_usecase.dart';
import 'package:hexora/b-backend/group_mng_flow/group/view_model/presentation/use_cases/upload_group_photo_usecase.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/group/create_edit/models/group_data_body.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/group/create_edit/widgets/buttons/save_group_button.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class CreateGroupData extends StatefulWidget {
  const CreateGroupData({super.key});

  @override
  State<CreateGroupData> createState() => _CreateGroupDataState();
}

class _CreateGroupDataState extends State<CreateGroupData> {
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
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);

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
            appBar: AppBar(
              title: Text(
                l.createGroup,
                style: t.titleLarge.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            body: GroupDataBody(
              nameController: _nameC,
              descController: _descC,
              title: l.groupData,
              bottomSection: const SizedBox.shrink(), // optional extras
            ),
            bottomNavigationBar: SafeArea(
              minimum: const EdgeInsets.all(16),
              child: SaveGroupButton(controller: vm),
            ),
          );
        },
      ),
    );
  }
}
