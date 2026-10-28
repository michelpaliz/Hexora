part of '../settings_members_section.dart';

extension _SettingsMembersActionsPart on _SettingsMembersSectionState {
  Future<void> _changeRole(User user, GroupRole newRole) async {
    final gd = context.read<GroupDomain>();
    final l = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    // Keep role changes staged until the backend confirms them.
    final oldRoles = <String, String>{
      ...widget.group.userRoles,
      ...gd.userRoles.value,
    };
    final updatedRoles = Map<String, String>.from(oldRoles)
      ..[user.id] = newRole.wire;

    try {
      final repo = gd.groupRepository;
      await repo.setUserRoleInGroup(
        groupId: widget.group.id,
        userId: user.id,
        roleWire: newRole.wire,
      );

      gd.userRoles.value = updatedRoles;
      gd.publishCurrentGroupUpdate(
        widget.group.copyWith(userRoles: updatedRoles),
      );
      _updateUi(() {
        _confirmedRoleOverrides[user.id] = newRole.wire;
        _pendingRole = null;
      });

      messenger.showSnackBar(
        SnackBar(content: Text(l.saveChanges)),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('No se pudo guardar el cambio de rol.')),
      );
    }
  }

  Future<bool> _confirmDiscardPendingRole(BuildContext context) async {
    if (_pendingRole == null) return true;

    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Descartar cambios'),
            content: const Text(
              'Tienes un cambio de rol sin guardar. ¿Quieres descartarlo?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Seguir editando'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Descartar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _confirmRemoveMember(BuildContext context, User user) async {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final gd = context.read<GroupDomain>();
    final messenger = ScaffoldMessenger.of(context);
    final displayName = user.name.isNotEmpty ? user.name : user.userName;

    final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(l.remove),
            content: Text(
              '${l.remove} $displayName?',
              style: t.bodySmall,
            ),
            actions: [
              TextButton(
                style: ThemedButtons.button(
                  context,
                  variant: ButtonVariant.ghost,
                ),
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l.cancel),
              ),
              FilledButton(
                style: ThemedButtons.button(
                  context,
                  variant: ButtonVariant.danger,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l.remove),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    try {
      final repo = gd.groupRepository;
      await repo.leaveGroup(user.id, widget.group.id);

      final updatedUserIds = List<String>.from(widget.group.userIds)
        ..remove(user.id);
      final updatedRoles = Map<String, String>.from(gd.userRoles.value)
        ..remove(user.id);
      gd.userRoles.value = updatedRoles;
      gd.publishCurrentGroupUpdate(
        widget.group.copyWith(
          userIds: updatedUserIds,
          userRoles: updatedRoles,
        ),
      );

      widget.membersVM.refreshAll();

      _updateUi(() {
        _selectedMember = null;
        _selectedUser = null;
      });
      messenger.showSnackBar(
        SnackBar(content: Text(l.remove)),
      );
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l.pendingEventsError)),
        );
      }
    }
  }
}
