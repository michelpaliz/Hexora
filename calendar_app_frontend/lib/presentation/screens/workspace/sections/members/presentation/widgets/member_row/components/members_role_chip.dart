import 'package:flutter/material.dart';
import 'package:hexora/presentation/utils/roles/group_role.dart';
import 'package:hexora/presentation/utils/roles/group_role_labels.dart';

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

    final key = role.wire.toLowerCase().replaceAll('-', '').replaceAll('_', '');
    final isAdminLike = key == 'admin' || key == 'coadmin' || key == 'owner';

    if (hideForAdminLike && isAdminLike) return const SizedBox.shrink();

    // Ensure your GroupRoleX has: Color roleChipColor(ColorScheme cs)
    final color = cs.onSecondaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: cs.outlineVariant, width: 1),
      ),
      child: Text(
        roleLabelOf(context, role),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              height: 1.2,
            ),
      ),
    );
  }
}
