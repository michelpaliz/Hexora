import 'package:hexora/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:hexora/models/user/user.dart';
import 'package:hexora/presentation/shared/widgets/avatars/avatar_utils.dart';
import 'package:hexora/presentation/utils/roles/group_role.dart';
import 'package:hexora/presentation/utils/roles/group_role_labels.dart';
import 'package:hexora/presentation/utils/username/username_tag.dart';
import 'package:hexora/theme/typography/typography_extension.dart';

class MemberRoleTile extends StatelessWidget {
  final String userId;
  final User? user;
  final GroupRole role;
  final Map<String, GroupRole>? rolesByUserId; // optional live map

  /// If true, tapping the tile shows the inline role picker
  final bool editable;

  /// Which roles can be chosen (required when editable)
  final List<GroupRole> assignableRoles;

  /// Called when a new role is selected
  final void Function(GroupRole newRole)? onRoleChanged;

  /// Optional long-press action (e.g., remove user)
  final VoidCallback? onRemove;

  const MemberRoleTile({
    super.key,
    required this.userId,
    required this.user,
    required this.role,
    this.rolesByUserId,
    required this.editable,
    required this.assignableRoles,
    this.onRoleChanged,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final typo = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    final displayName = (user?.name.isNotEmpty ?? false)
        ? user!.name
        : (user?.userName ?? 'Unknown');

    final username = user?.userName ?? '';
    final avatar =
        AvatarUtils.profileAvatar(context, user?.photoUrl, radius: 22);

    final effectiveRole = rolesByUserId?[userId] ?? role;
    final chipColor = effectiveRole.roleChipColor(cs);
    final roleText = roleLabelOf(context, effectiveRole);

    Future<void> _pickRole() async {
      if (!editable) return;
      final selected = await showModalBottomSheet<GroupRole>(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        showDragHandle: true,
        backgroundColor: cs.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        builder: (ctx) {
          return SingleChildScrollView(
              child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            AppLocalizations.of(context)!.changeRole,
                            style: typo.bodyMedium.copyWith(
                                fontWeight: FontWeight.w800,
                                color: cs.onSurface),
                          ),
                        ),
                      ),
                      for (final r in assignableRoles)
                        ListTile(
                          leading: Radio<GroupRole>(
                            value: r,
                            groupValue: effectiveRole,
                            onChanged: (_) {
                              Navigator.of(ctx).pop(r);
                            },
                          ),
                          title: Text(roleLabelOf(context, r),
                              style: typo.bodyMedium.copyWith(
                                  color: cs.onSurface,
                                  fontWeight: r == effectiveRole
                                      ? FontWeight.w700
                                      : null)),
                          onTap: () => Navigator.of(ctx).pop(r),
                        ),
                      const SizedBox(height: 10),
                    ],
                  )));
        },
      );
      if (selected != null && selected.wire != effectiveRole.wire) {
        onRoleChanged?.call(selected);
      }
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: editable ? _pickRole : null,
        onLongPress: onRemove,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Avatar
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: chipColor.withOpacity(.28),
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.all(2),
                child: avatar,
              ),

              const SizedBox(width: 12),

              // Texts
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayName,
                        style: typo.bodyLarge.copyWith(
                            fontWeight: FontWeight.w700, color: cs.onSurface)),
                    const SizedBox(height: 4),
                    // Username (or fallback)
                    if (username.isNotEmpty)
                      UsernameTag(username: username)
                    else
                      Text(
                        userId,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: typo.bodySmall.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: cs.secondaryContainer,
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(roleText,
                          style: typo.bodySmall.copyWith(
                              color: cs.onSecondaryContainer,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),

              if (editable) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: cs.onSurfaceVariant,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
