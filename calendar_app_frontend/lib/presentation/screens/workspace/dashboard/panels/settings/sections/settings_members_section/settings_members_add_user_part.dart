part of '../settings_members_section.dart';

extension _SettingsMembersAddUserPart on _SettingsMembersSectionState {
  Future<void> _sendSelectedInvitations(
    BuildContext context,
    AddUserController ctrl,
  ) async {
    if (_sendingInvitations || ctrl.selectedUsers.isEmpty) return;

    final selected = List<User>.from(ctrl.selectedUsers);
    final messenger = ScaffoldMessenger.of(context);
    final groupRepo = context.read<GroupDomain>().groupRepository;
    _updateUi(() => _sendingInvitations = true);

    try {
      for (final user in selected) {
        final role = ctrl.stagedRoleOf(user.id) ?? GroupRole.member;
        try {
          await groupRepo.sendGroupInvitation(
            groupId: widget.group.id,
            userId: user.id,
            roleWire: role.wire,
          );
        } on HttpFailure catch (error) {
          // A retry after a partial success can legitimately find the invite.
          if (error.statusCode != 409) rethrow;
        }
      }

      if (!mounted) return;
      ctrl.clearSelection();
      await widget.membersVM.refreshAll();
      if (!mounted) return;
      _updateUi(() {
        _selectedTab = 1;
        _selectedMember = null;
        _selectedUser = null;
      });
      messenger.showSnackBar(
        SnackBar(content: Text('${selected.length} invitación(es) enviada(s)')),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('No se pudo enviar la invitación: $error')),
      );
    } finally {
      _updateUi(() => _sendingInvitations = false);
    }
  }

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
          return Stack(
            children: [
              AddUsersTab(
                openPicker: () async {
                  final useDialog = MediaQuery.sizeOf(context).width >= 720;
                  if (useDialog) {
                    await showDialog<void>(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => ChangeNotifierProvider.value(
                        value: context.read<AddUserController>(),
                        child: const AddUsersPickerDialog(),
                      ),
                    );
                    return;
                  }

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
                    style: ThemedButtons.button(context),
                    onPressed: _sendingInvitations
                        ? null
                        : () => _sendSelectedInvitations(context, ctrl),
                    icon: _sendingInvitations
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded, size: 20),
                    label: Text(l.done),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
