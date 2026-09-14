part of '../settings_members_section.dart';

extension _SettingsMembersActionsPart on _SettingsMembersSectionState {
  Future<void> _changeRole(User user, GroupRole newRole) async {
    final gd = context.read<GroupDomain>();
    final l = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    // Optimistic local update
    final oldRoles = Map<String, String>.from(gd.userRoles.value);
    final updatedRoles = Map<String, String>.from(oldRoles)
      ..[user.id] = newRole.wire;
    gd.userRoles.value = updatedRoles;
    gd.currentGroup = widget.group.copyWith(userRoles: updatedRoles);
    _updateUi();

    try {
      final repo = gd.groupRepository;
      await repo.setUserRoleInGroup(
        groupId: widget.group.id,
        userId: user.id,
        roleWire: newRole.wire,
      );

      messenger.showSnackBar(
        SnackBar(content: Text(l.saveChanges)),
      );
    } catch (e) {
      // Revert on failure
      gd.userRoles.value = oldRoles;
      gd.currentGroup = widget.group.copyWith(userRoles: oldRoles);
      _updateUi();

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
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
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l.cancel),
              ),
              FilledButton(
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
      gd.currentGroup = widget.group.copyWith(
        userIds: updatedUserIds,
        userRoles: updatedRoles,
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
