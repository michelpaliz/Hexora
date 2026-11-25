import 'package:flutter/material.dart';
import 'package:hexora/presentation/screens/workspace/sections/members/presentation/controller/add_user_controller.dart';
import 'package:hexora/presentation/screens/workspace/sections/members/presentation/controller/contract_for_controller/interface/i_group_editor_port.dart';
import 'package:hexora/presentation/screens/workspace/sections/members/presentation/widgets/add_users_flow/widgets/selected_users_list.dart';
import 'package:hexora/presentation/screens/workspace/sections/members/presentation/widgets/shared/header_info.dart';
import 'package:hexora/presentation/utils/roles/group_role.dart';
import 'package:hexora/presentation/utils/roles/group_role_labels.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class AddUsersTab extends StatelessWidget {
  const AddUsersTab({
    super.key,
    required this.openPicker,
    this.inviteByEmail,
  });

  final Future<void> Function() openPicker;
  final Future<void> Function()? inviteByEmail;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    final ctrl = context.watch<AddUserController>();
    final port = context.watch<IGroupEditorPort>();

    final Map<String, GroupRole> rolesByIdOrName = {
      ...port.roles,
      for (final u in ctrl.selectedUsers)
        u.id: ctrl.stagedRoleOf(u.id) ?? GroupRole.member,
    };

    final existingCount = port.membersById.length;
    final stagedCount = ctrl.selectedUsers.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24 + 72),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header info (no trailing action)
          InfoHeader(
            title: l.tabAddUsers,
            subtitle: l.addUsersHelperText,
            stats: [
              StatChip(
                  label: l.membersTitle,
                  count: existingCount,
                  icon: Icons.groups_rounded),
              StatChip(
                  label: l.selectedLabel,
                  count: stagedCount,
                  icon: Icons.person_add_alt_1_rounded),
            ],
          ),

          // Button below the header info
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                if (inviteByEmail != null)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.alternate_email_rounded),
                    onPressed: inviteByEmail,
                    label: Text(
                        Localizations.localeOf(context).languageCode == 'es'
                            ? 'Invitar por email'
                            : 'Invite by email'),
                  ),
                FilledButton.icon(
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  onPressed: openPicker,
                  label: Text(
                    l.addUsersCount(stagedCount),
                    style: t.buttonText.copyWith(
                      color: Theme.of(context).canvasColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          Divider(color: cs.outlineVariant.withValues(alpha: 0.5), height: 1),
          const SizedBox(height: 16),

          if (ctrl.selectedUsers.isNotEmpty) ...[
            const _InvitationRoleGuide(),
            const SizedBox(height: 16),
          ],

          // Selected chips/list
          Text(
            l.selectedLabel,
            style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          SelectedUsersList(
            users: ctrl.selectedUsers,
            rolesByIdOrName: rolesByIdOrName,
            onRemove: (username) => ctrl.unselect(username),
            onChangeRole: (username, newRole) {
              ctrl.setStagedRoleByUsername(username, newRole);
            },
          ),
        ],
      ),
    );
  }
}

class _InvitationRoleGuide extends StatelessWidget {
  const _InvitationRoleGuide();

  @override
  Widget build(BuildContext context) {
    final es = Localizations.localeOf(context).languageCode == 'es';
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final roles = <(GroupRole, String)>[
      (
        GroupRole.member,
        es
            ? 'Usa las herramientas del negocio que tenga disponibles.'
            : 'Uses the business tools made available to them.'
      ),
      (
        GroupRole.coAdmin,
        es
            ? 'Ayuda a gestionar el trabajo diario y las invitaciones.'
            : 'Helps manage daily work and invitations.'
      ),
      (
        GroupRole.admin,
        es
            ? 'Gestiona miembros, roles y la configuración del negocio.'
            : 'Manages members, roles, and business settings.'
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            es ? 'Elige el nivel de acceso' : 'Choose an access level',
            style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          for (final entry in roles)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(entry.$1.icon, size: 16, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${roleLabelOf(context, entry.$1)}: ',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(text: entry.$2),
                        ],
                      ),
                      style: t.caption.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
