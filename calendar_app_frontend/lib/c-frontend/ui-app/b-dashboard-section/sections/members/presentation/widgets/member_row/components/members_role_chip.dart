import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/utils/roles/group_role/group_role.dart';
import 'package:hexora/c-frontend/utils/roles/group_role/group_role_labels.dart';
import 'package:hexora/l10n/app_localizations.dart';

class MemberRoleChip extends StatelessWidget {
  final GroupRole role;
  final bool hideForAdminLike; // set false to show owner/admin too

  const MemberRoleChip({
    super.key,
    required this.role,
    this.hideForAdminLike = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    final isAdminLike = role == GroupRole.admin ||
        role == GroupRole.coAdmin ||
        role == GroupRole.owner;

    if (hideForAdminLike && isAdminLike) return const SizedBox.shrink();

    // Ensure your GroupRoleX has: Color roleChipColor(ColorScheme cs)
    final color = role.roleChipColor(cs);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        role.label(l),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 10,
              height: 1.2,
            ),
      ),
    );
  }
}
