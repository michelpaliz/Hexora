import 'package:flutter/material.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/actions/add_screen/utils/dialog/user_animated_list_widget.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

import 'dialog_button_widget.dart';

class UserExpandableCard extends StatefulWidget {
  final List<User> usersAvailable;
  final ValueChanged<List<User>> onSelectedUsersChanged;
  final List<User>? initiallySelected;

  /// 👇 New: exclude the event owner
  final String? excludeUserId;

  const UserExpandableCard({
    Key? key,
    required this.usersAvailable,
    required this.onSelectedUsersChanged,
    this.initiallySelected,
    this.excludeUserId,
  }) : super(key: key);

  @override
  _UserExpandableCardState createState() => _UserExpandableCardState();
}

class _UserExpandableCardState extends State<UserExpandableCard> {
  late List<User> _selectedUsers;
  bool _isExpanded = false;

  List<User> get _filteredUsers {
    if (widget.excludeUserId == null) return widget.usersAvailable;
    return widget.usersAvailable
        .where((u) => u.id != widget.excludeUserId)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    // Ensure owner is not in initial selection
    final initSel = (widget.initiallySelected ?? [])
        .where((u) => u.id != widget.excludeUserId)
        .toList();
    _selectedUsers = initSel;
  }

  void _toggleExpansion() => setState(() => _isExpanded = !_isExpanded);

  // void _onUsersSelected(List<User> selectedUsers) {
  //   // Guard against owner being selected via dialog
  //   final cleaned =
  //       selectedUsers.where((u) => u.id != widget.excludeUserId).toList();
  //   setState(() => _selectedUsers = cleaned);
  //   widget.onSelectedUsersChanged(cleaned);
  // }

  void _onUsersSelected(List<User> selectedUsers) {
    final cleaned =
        selectedUsers.where((u) => u.id != widget.excludeUserId).toList();
    setState(() {
      _selectedUsers = cleaned;
      _isExpanded = false; // 👈 collapse after selection
    });
    widget.onSelectedUsersChanged(cleaned);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final typo = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    final canInvite = _filteredUsers.isNotEmpty;

    return Card(
      elevation: 5,
      margin: const EdgeInsets.all(10.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                loc.userExpandableCardTitle,
                style: typo.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              ),
              trailing: Icon(
                _isExpanded ? Icons.expand_less : Icons.expand_more,
                color: cs.onSurfaceVariant,
              ),
              onTap: canInvite ? _toggleExpansion : null,
            ),

            // If there’s no one to invite (owner is the only user or filter empties the list)
            if (!canInvite)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  loc.noInvitableUsers, // ARB: "noInvitableUsers": "No users available to invite"
                  style: typo.bodySmall.copyWith(color: cs.onSurfaceVariant),
                ),
              ),

            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _isExpanded && canInvite ? 100 : 0,
              child: _isExpanded && canInvite
                  ? SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: DialogButtonWidget(
                          selectedUsers: _selectedUsers,
                          usersAvailable: _filteredUsers, // 👈 filtered
                          onUsersSelected: _onUsersSelected,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            _selectedUsers.isNotEmpty
                ? AnimatedUsersList(users: _selectedUsers)
                : Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      loc.noUsersSelected, // already localized
                      style:
                          typo.bodySmall.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
