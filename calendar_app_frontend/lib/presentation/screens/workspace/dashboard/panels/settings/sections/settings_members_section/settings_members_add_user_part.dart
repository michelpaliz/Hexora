part of '../settings_members_section.dart';

extension _SettingsMembersAddUserPart on _SettingsMembersSectionState {
  Widget _buildAddMembersTab(BuildContext context) {
    final currentUser = context.read<UserDomain?>()?.user;
    if (currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<GroupEditorViewModel>(
          create: (c) => GroupEditorViewModel(
            currentUser: currentUser,
            ui: MaterialUiMessenger(c),
            createGroup: c.read<CreateGroupUseCase>(),
            inviteMembers: c.read<InviteMembersUseCase>(),
            uploadPhoto: c.read<UploadGroupPhotoUseCase>(),
            searchUsersUseCase: c.read<SearchUsersUseCase>(),
            updateGroup: c.read<UpdateGroupUseCase>(),
          )..enterEditFrom(widget.group),
        ),
        ProxyProvider<GroupEditorViewModel, IGroupEditorPort>(
          update: (_, vm, __) => VmGroupEditorPort(vm),
        ),
        ChangeNotifierProvider<AddUserController>(
          create: (ctx) =>
              AddUserController(port: ctx.read<IGroupEditorPort>()),
        ),
      ],
      child: Builder(
        builder: (context) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _seedVmFromGroupOnce(context);
          });

          final ctrl = context.watch<AddUserController>();
          final l = AppLocalizations.of(context)!;
          final cs = Theme.of(context).colorScheme;

          return Stack(
            children: [
              AddUsersTab(
                openPicker: () async {
                  await showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    builder: (_) => ChangeNotifierProvider.value(
                      value: context.read<AddUserController>(),
                      child: const AddUsersBottomSheet(),
                    ),
                  );
                },
              ),
              if (ctrl.selectedUsers.isNotEmpty)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: FilledButton.icon(
                    onPressed: () {
                      ctrl.commitSelected(context);
                      _updateUi();
                    },
                    icon: const Icon(Icons.check_rounded, size: 20),
                    label: Text(l.done),
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
