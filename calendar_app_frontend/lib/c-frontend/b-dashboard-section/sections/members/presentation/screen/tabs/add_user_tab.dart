import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/members/presentation/controller/add_user_controller.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/members/presentation/widgets/add_users_flow/selected_users_list.dart';
// ✅ Use your centralized enum file
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class AddUsersTab extends StatelessWidget {
  const AddUsersTab({
    super.key,
    required this.openPicker,
  });

  final Future<void> Function() openPicker;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    final ctrl = context.watch<AddUserController>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              l.selectedLabel,
              style: t.titleLarge.copyWith(fontWeight: FontWeight.w700),
            ),
          ),

          // Selected Users display
          SelectedUsersList(
            users: ctrl.usersInGroup,
            // ✅ pass enum map directly (userId -> GroupRole)
            rolesByIdOrName: ctrl.userRoles,
            onRemove: (u) => ctrl.removeUser(u),
            // ✅ pass enum to controller; it handles storage and wire conversions
            onChangeRole: (u, r) => ctrl.changeRole(u, r),
          ),

          const Spacer(),

          // Open the picker / bottom sheet
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              icon: const Icon(Icons.person_add_alt_1),
              label: Text(
                l.addUsersCount(ctrl.usersInGroup.length),
                style: t.buttonText.copyWith(
                  color: Theme.of(context).canvasColor,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary,
              ),
              onPressed: openPicker,
            ),
          ),
        ],
      ),
    );
  }
}
