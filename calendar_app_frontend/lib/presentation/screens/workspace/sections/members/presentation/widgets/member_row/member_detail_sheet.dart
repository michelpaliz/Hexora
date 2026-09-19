import 'package:flutter/material.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/models/user/user.dart';
import 'package:hexora/services/groups/domain/group_domain.dart';
import 'package:hexora/presentation/screens/workspace/sections/members/presentation/domain/models/members_ref.dart';
import 'package:hexora/presentation/screens/workspace/sections/members/presentation/domain/models/members_vm.dart';
import 'package:hexora/presentation/screens/workspace/sections/members/presentation/widgets/member_row/components/role_chip.dart';
import 'package:hexora/presentation/utils/roles/group_role.dart';
import 'package:hexora/presentation/utils/roles/group_role_labels.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

Future<void> showMemberDetailSheet({
  required BuildContext context,
  required User user,
  required MemberRef ref,
  required bool isOwnerRowUser,
  required bool isAdminRowUser,
  required Group group,
  required String? currentUserId,
}) async {
  final gd = context.read<GroupDomain>();
  final vm = context.read<MembersVM>();
  final currentRole = GroupRole.fromWire(gd.userRoles.value[currentUserId] ??
      group.userRoles[currentUserId] ??
      '');
  final targetRole = isOwnerRowUser
      ? GroupRole.owner
      : GroupRole.fromWire(gd.userRoles.value[user.id] ?? ref.role);
  final canRemove = (currentRole == GroupRole.owner ||
          currentRole == GroupRole.admin ||
          currentRole == GroupRole.coAdmin) &&
      !isOwnerRowUser &&
      currentUserId != user.id;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (sheetContext) => MemberDetailContent(
      user: user,
      role: targetRole,
      onClose: () => Navigator.of(sheetContext).pop(),
      onChangeRole: currentUserId != group.ownerId || isOwnerRowUser
          ? null
          : () async {
              final l = AppLocalizations.of(sheetContext)!;
              final selected = await showDialog<GroupRole>(
                context: sheetContext,
                builder: (dialogContext) => SimpleDialog(
                  title: Text(l.changeRole),
                  children: [
                    for (final role in GroupRole.defaults
                        .where((r) => r != GroupRole.owner))
                      SimpleDialogOption(
                        onPressed: () => Navigator.pop(dialogContext, role),
                        child: Text(roleLabelOf(dialogContext, role)),
                      ),
                  ],
                ),
              );
              if (selected == null ||
                  selected.wire == targetRole.wire ||
                  !sheetContext.mounted) {
                return;
              }
              try {
                await gd.groupRepository.setUserRoleInGroup(
                    groupId: group.id,
                    userId: user.id,
                    roleWire: selected.wire);
                gd.userRoles.value = {
                  ...group.userRoles,
                  ...gd.userRoles.value,
                  user.id: selected.wire
                };
                gd.currentGroup = group.copyWith(userRoles: gd.userRoles.value);
                if (sheetContext.mounted) Navigator.of(sheetContext).pop();
              } catch (_) {
                if (sheetContext.mounted) {
                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                      SnackBar(content: Text(l.failedToEditGroup)));
                }
              }
            },
      onRemove: !canRemove
          ? null
          : () async {
              final l = AppLocalizations.of(sheetContext)!;
              final confirmed = await showDialog<bool>(
                context: sheetContext,
                builder: (dialogContext) => AlertDialog(
                  title: Text(l.remove),
                  content: Text(
                      '${l.remove} ${user.name.isNotEmpty ? user.name : user.userName}?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: Text(l.cancel)),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            Theme.of(dialogContext).colorScheme.error,
                        foregroundColor:
                            Theme.of(dialogContext).colorScheme.onError,
                      ),
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      child: Text(l.remove),
                    ),
                  ],
                ),
              );
              if (confirmed != true || !sheetContext.mounted) return;
              try {
                await gd.groupRepository.leaveGroup(user.id, group.id);
                final updatedRoles =
                    Map<String, String>.from(gd.userRoles.value)
                      ..remove(user.id);
                gd.userRoles.value = updatedRoles;
                gd.currentGroup = group.copyWith(
                  userIds: List<String>.from(group.userIds)..remove(user.id),
                  userRoles: updatedRoles,
                );
                await vm.refreshAll();
                if (sheetContext.mounted) Navigator.of(sheetContext).pop();
              } catch (_) {
                if (!sheetContext.mounted) return;
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  SnackBar(content: Text(l.pendingEventsError)),
                );
              }
            },
    ),
  );
}

/// Compact member details with explicit surface colors and separate actions.
class MemberDetailContent extends StatefulWidget {
  const MemberDetailContent(
      {super.key,
      required this.user,
      required this.role,
      required this.onClose,
      this.onRemove,
      this.onChangeRole});
  final User user;
  final GroupRole role;
  final VoidCallback onClose;
  final Future<void> Function()? onRemove;
  final Future<void> Function()? onChangeRole;

  @override
  State<MemberDetailContent> createState() => _MemberDetailContentState();
}

class _MemberDetailContentState extends State<MemberDetailContent> {
  bool _removing = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final user = widget.user;
    final name = user.name.trim().isNotEmpty ? user.name : user.userName;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: l.close,
                  onPressed: _removing ? null : widget.onClose,
                  icon: Icon(Icons.close, color: cs.onSurface),
                )),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: cs.primaryContainer,
                foregroundColor: cs.onPrimaryContainer,
                backgroundImage: user.photoUrl?.isNotEmpty == true
                    ? NetworkImage(user.photoUrl!)
                    : null,
                child: user.photoUrl?.isNotEmpty == true
                    ? null
                    : Text(_initials(name)),
              ),
              const SizedBox(width: 16),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(name,
                        style: text.titleLarge?.copyWith(
                            color: cs.onSurface, fontWeight: FontWeight.w700)),
                    if (user.userName.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('@${user.userName}',
                          style: text.bodyMedium
                              ?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                    const SizedBox(height: 10),
                    RoleChip(
                        label: roleLabelOf(context, widget.role),
                        color: cs.primaryContainer),
                  ])),
            ]),
            if (user.email.trim().isNotEmpty ||
                user.phoneNumber?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 20),
              Divider(color: cs.outlineVariant),
              if (user.email.trim().isNotEmpty)
                _contact(Icons.alternate_email, user.email, cs, text),
              if (user.phoneNumber?.trim().isNotEmpty == true)
                _contact(Icons.phone_outlined, user.phoneNumber!, cs, text),
            ],
            if (widget.onChangeRole != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _removing
                    ? null
                    : () async {
                        setState(() => _removing = true);
                        try {
                          await widget.onChangeRole!();
                        } finally {
                          if (mounted) setState(() => _removing = false);
                        }
                      },
                icon: const Icon(Icons.manage_accounts_outlined),
                label: Text(l.changeRole),
              ),
            ],
            if (widget.onRemove != null) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.error,
                  minimumSize: const Size(0, 48),
                  side: BorderSide(color: cs.error),
                ),
                onPressed: _removing
                    ? null
                    : () async {
                        setState(() => _removing = true);
                        try {
                          await widget.onRemove!();
                        } finally {
                          if (mounted) setState(() => _removing = false);
                        }
                      },
                icon: _removing
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.person_remove_outlined),
                label: Text(l.remove),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _contact(
          IconData icon, String value, ColorScheme cs, TextTheme text) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 22, color: cs.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
              child: SelectableText(value,
                  style: text.bodyLarge?.copyWith(color: cs.onSurface))),
        ]),
      );
}

String _initials(String text) {
  final parts = text.trim().split(RegExp(r'\s+'));
  if (parts.first.isEmpty) return '?';
  return (parts.first[0] + (parts.length > 1 ? parts.last[0] : ''))
      .toUpperCase();
}
