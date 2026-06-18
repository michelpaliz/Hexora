// create_group_data.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/viewmodels/group_vm/view_model/group_view_model.dart';
import 'package:hexora/c-frontend/viewmodels/group_vm/presentation/common/ui_messenger.dart';
import 'package:hexora/c-frontend/viewmodels/group_vm/presentation/use_cases/create_group_usecase.dart';
import 'package:hexora/c-frontend/viewmodels/group_vm/presentation/use_cases/update_group_usecase.dart';
import 'package:hexora/c-frontend/viewmodels/group_vm/presentation/use_cases/invite_members_usecase.dart';
import 'package:hexora/c-frontend/viewmodels/group_vm/presentation/use_cases/search_users_usecase.dart';
import 'package:hexora/c-frontend/viewmodels/group_vm/presentation/use_cases/upload_group_photo_usecase.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/group/create_edit/models/group_data_body.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/group/create_edit/widgets/buttons/save_group_button.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
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
    final isWide = kIsWeb || MediaQuery.of(context).size.width >= 900;

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
        updateGroup: c.read<UpdateGroupUseCase>(),
      ),
      child: Builder(
        builder: (context) {
          final vm = context.watch<GroupEditorViewModel>();

          if (isWide) {
            // ── Web / wide layout ────────────────────────────────────────
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  color: ThemeColors.cardBg(context),
                  margin: const EdgeInsets.symmetric(vertical: 24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header bar
                        Container(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.06),
                            border: Border(
                              bottom: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.group_add_outlined,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                l.createGroup,
                                style: t.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Form body + save button
                        Flexible(
                          child: GroupDataBody(
                            nameController: _nameC,
                            descController: _descC,
                            title: null,
                            onNameChanged: vm.setName,
                            onDescChanged: vm.setDescription,
                            onPicked: vm.setImage,
                            bottomSection: Padding(
                              padding: const EdgeInsets.only(top: 4, bottom: 4),
                              child: SaveGroupButton(controller: vm),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          // ── Mobile layout ────────────────────────────────────────────
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
              onNameChanged: vm.setName,
              onDescChanged: vm.setDescription,
              onPicked: vm.setImage,
              bottomSection: const SizedBox.shrink(),
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
