import 'package:flutter/material.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/c-frontend/utils/image/user_image/avatar_utils.dart';
import 'package:hexora/c-frontend/utils/roles/group_role/group_role.dart';
import 'package:hexora/c-frontend/utils/roles/group_role/group_role_labels.dart';
import 'package:hexora/c-frontend/utils/username/username_tag.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';

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
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        builder: (ctx) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Change role',
                    style:
                        typo.bodyMedium.copyWith(fontWeight: FontWeight.w800),
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
                          fontWeight:
                              r == effectiveRole ? FontWeight.w700 : null)),
                  onTap: () => Navigator.of(ctx).pop(r),
                ),
              const SizedBox(height: 10),
            ],
          );
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
                    // Name + role chip
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: typo.bodyLarge.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                              height: 1.15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: chipColor.withOpacity(.14),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: chipColor.withOpacity(.35),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            roleText,
                            style: typo.bodySmall.copyWith(
                              color: chipColor,
                              fontWeight: FontWeight.w700,
                              letterSpacing: .2,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

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
