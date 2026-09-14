import 'package:flutter/material.dart';
import 'package:hexora/models/group/group.dart';
import 'package:hexora/models/user/user.dart';
import 'package:hexora/data/user/domain/user_domain.dart';
import 'package:hexora/presentation/features/calendar/screens/group/create_edit/models/edit_group_data.dart';
import 'package:hexora/presentation/viewmodels/group/common/ui_messenger.dart';
import 'package:hexora/presentation/viewmodels/group/use_cases/create_group_usecase.dart';
import 'package:hexora/presentation/viewmodels/group/use_cases/invite_members_usecase.dart';
import 'package:hexora/presentation/viewmodels/group/use_cases/search_users_usecase.dart';
import 'package:hexora/presentation/viewmodels/group/use_cases/update_group_usecase.dart';
import 'package:hexora/presentation/viewmodels/group/use_cases/upload_group_photo_usecase.dart';
import 'package:hexora/presentation/viewmodels/group/group_view_model.dart';
import 'package:hexora/theme/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

/// Inline edit group panel for the right column (web/wide layout).
class EditGroupInlinePanel extends StatelessWidget {
  final Group group;
  final List<User> users;

  const EditGroupInlinePanel({
    super.key,
    required this.group,
    required this.users,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<UserDomain?>()?.user;
    if (currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ChangeNotifierProvider<GroupEditorViewModel>(
      create: (c) => GroupEditorViewModel(
        currentUser: currentUser,
        ui: MaterialUiMessenger(c),
        createGroup: c.read<CreateGroupUseCase>(),
        inviteMembers: c.read<InviteMembersUseCase>(),
        uploadPhoto: c.read<UploadGroupPhotoUseCase>(),
        searchUsersUseCase: c.read<SearchUsersUseCase>(),
        updateGroup: c.read<UpdateGroupUseCase>(),
      )..enterEditFrom(group),
      child: Builder(
        builder: (context) {
          final l = AppLocalizations.of(context)!;
          final t = AppTypography.of(context);
          return Scaffold(
            appBar: AppBar(
              title: Text(
                l.editGroup,
                style: t.titleLarge.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            body: EditGroupData(group: group, users: users),
          );
        },
      ),
    );
  }
}
