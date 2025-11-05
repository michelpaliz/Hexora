// lib/.../edit-group/widgets/edit_group_body/functions/edit_group_ppl.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/notification_model/userInvitation_status.dart'; // kept only for downstream widget compatibility
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/auth_user/user/domain/user_domain.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/group_mng_flow/group/view_model/group_view_model.dart';
import 'package:hexora/b-backend/group_mng_flow/invite/repository/invite_repository.dart';
import 'package:hexora/b-backend/notification/domain/notification_domain.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/group/edit-group/widgets/edit_group_body/functions/admin_filter_sections.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/utils/shared/add_user_button/add_user_button.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../user_list_section.dart';

/// Stable keys for the filter chips.
enum InviteFilter { accepted, pending, notAccepted, newUsers, expired }

class EditGroupPeople extends StatefulWidget {
  final Group group;
  final List<User> initialUsers; // incoming snapshot
  final UserDomain userDomain;
  final GroupDomain groupDomain;
  final NotificationDomain notificationDomain;

  const EditGroupPeople({
    Key? key,
    required this.group,
    required this.initialUsers,
    required this.userDomain,
    required this.groupDomain,
    required this.notificationDomain,
  }) : super(key: key);

  @override
  EditGroupPeopleState createState() => EditGroupPeopleState();
}

class EditGroupPeopleState extends State<EditGroupPeople> {
  // Controller only for AddUser dialog search/flow
  late GroupViewModel _controller;

  // Local, temporary state (NOT persisted until Save)
  late List<User> _localUsers; // working members
  late Map<String, String> _localRoles; // 🔑 userId -> role (lowercase)
  final Map<String, User> _newUsers = {}; // added in this session

  // We keep invites maps only to satisfy downstream widget params for now.
  // They are intentionally EMPTY because invites are now a separate collection.
  Map<String, UserInviteStatus> _localInvitedUsers = const {};
  Map<String, UserInviteStatus> _invitesAtOpen = const {};

  // Filters
  bool showAccepted = true;
  bool showPending = true;
  bool showNotWantedToJoin = true;
  bool showNewUsers = true;
  bool showExpired = true;

  late User? _currentUser;
  late String _currentUserRawRole; // 'owner' | 'admin' | 'co-admin' | 'member'

  @override
  void initState() {
    super.initState();
    _controller = GroupViewModel();

    _currentUser = widget.userDomain.user;

    // Clone incoming data into local working copies
    _localUsers = List<User>.from(widget.initialUsers);

    // 🔑 copy roles by userId and normalize to lowercase
    _localRoles = Map<String, String>.fromEntries(
      widget.group.userRoles.entries.map(
        (e) => MapEntry(e.key, e.value.toLowerCase()),
      ),
    );
    // Ensure owner is marked
    _localRoles[widget.group.ownerId] = 'owner';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // ✅ Initialize GroupViewModel *here* so Provider lookups are safe.
    if (_currentUser != null) {
      final invitationRepo =
          Provider.of<InvitationRepository>(context, listen: false);
      _controller.initialize(
        user: _currentUser!,
        userDomain: widget.userDomain,
        groupDomain: widget.groupDomain,
        notificationDomain: widget.notificationDomain,
        invitationRepository: invitationRepo, // 🔑 REQUIRED now
        context: context,
      );
    }

    // Compute raw role (by id) for admin gating
    final uid = _currentUser?.id ?? '';
    _currentUserRawRole = (uid == widget.group.ownerId)
        ? 'owner'
        : (widget.group.userRoles[uid]?.toLowerCase() ?? 'member');
  }

  // Called by AddUser dialog
  void _onNewUserAdded(User user) {
    setState(() {
      final exists = _localUsers.any((u) => u.id == user.id) ||
          _newUsers.containsKey(user.userName);
      if (exists) return;

      // Mark as "new user" for this edit session
      _newUsers[user.userName] = user;

      // Default role for newly added (to be invited later by update flow)
      _localRoles[user.id] = _localRoles[user.id] ?? 'member';

      // NOTE: We no longer create embedded invitation objects here.
      // Invitations are now a separate collection and should be created
      // by the update flow using InvitationDomain after saving the group.
    });
  }

  Map<String, User> get _filteredNewUsers => showNewUsers ? _newUsers : {};

  // ✅ Expose final values to parent (EditGroupBody reads these on Save)
  List<User> getFinalUsers() => List<User>.from(_localUsers);

  /// Returns roles keyed by **userId**.
  Map<String, String> getFinalRoles() => Map<String, String>.from(_localRoles);

  /// Kept only for backwards compatibility with downstream widget signature.
  Map<String, UserInviteStatus> getFinalInvites() =>
      Map<String, UserInviteStatus>.from(_localInvitedUsers);

  /// Accept either an InviteFilter enum OR a localized label String and resolve to the enum.
  InviteFilter? _resolveFilter(dynamic filter) {
    if (filter is InviteFilter) return filter;
    if (filter is! String) return null;

    final loc = AppLocalizations.of(context)!;
    String norm(String s) =>
        s.trim().toLowerCase().replaceAll(RegExp(r'[\s_\-]'), '');

    final f = norm(filter);

    if (f == norm(loc.accepted) || f == 'accepted')
      return InviteFilter.accepted;
    if (f == norm(loc.pending) || f == 'pending') return InviteFilter.pending;
    if (f == norm(loc.notAccepted) || f == 'notaccepted' || f == 'declined') {
      return InviteFilter.notAccepted;
    }
    if (f == norm(loc.newUsers) || f == 'newusers')
      return InviteFilter.newUsers;
    if (f == norm(loc.expired) || f == 'expired') return InviteFilter.expired;

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _currentUserRawRole == 'owner' ||
        _currentUserRawRole == 'admin' ||
        _currentUserRawRole == 'co-admin';

    return Column(
      children: [
        AddUserButton(
          currentUser: widget.userDomain.user,
          group: widget.group,
          controller: _controller, // ✅ use local controller
          onUserAdded: _onNewUserAdded, // ✅ wire callback
        ),
        const SizedBox(height: 12),

        if (isAdmin)
          AdminWithFiltersSection(
            currentUser: _currentUser!,
            showAccepted: showAccepted,
            showPending: showPending,
            showNotWantedToJoin: showNotWantedToJoin,
            showNewUsers: showNewUsers,
            showExpired: showExpired,
            onFilterChange: (filter, isSelected) {
              final resolved = _resolveFilter(filter);
              if (resolved == null) return;
              setState(() {
                switch (resolved) {
                  case InviteFilter.accepted:
                    showAccepted = isSelected;
                    break;
                  case InviteFilter.pending:
                    showPending = isSelected;
                    break;
                  case InviteFilter.notAccepted:
                    showNotWantedToJoin = isSelected;
                    break;
                  case InviteFilter.newUsers:
                    showNewUsers = isSelected;
                    break;
                  case InviteFilter.expired:
                    showExpired = isSelected;
                    break;
                }
              });
            },
          ),

        const SizedBox(height: 12),

        // Render from LOCAL working copies
        UserListSection(
          newUsers: _filteredNewUsers,
          usersRoles: _localRoles, // 🔑 userId -> role
          usersInvitations: _localInvitedUsers, // kept empty
          usersInvitationAtFirst: _invitesAtOpen, // kept empty
          group: widget.group,
          usersInGroup: _localUsers,
          userDomain: widget.userDomain,
          groupDomain: widget.groupDomain,
          notificationDomain: widget.notificationDomain,
          showPending: showPending,
          showAccepted: showAccepted,
          showNotWantedToJoin: showNotWantedToJoin,
          showNewUsers: showNewUsers,
          showExpired: showExpired,
          // role changes are now keyed by **userId**
          onChangeRole: (userIdOrName, newRole) {
            setState(() => _localRoles[userIdOrName] = newRole.toLowerCase());
          },
          onUserRemoved: (userIdOrName) {
            setState(() {
              _newUsers.removeWhere(
                  (k, v) => v.id == userIdOrName || k == userIdOrName);
              _localUsers.removeWhere(
                  (u) => u.id == userIdOrName || u.userName == userIdOrName);
              _localRoles.remove(userIdOrName);
              // invites are separate now; local invite maps remain empty
              _localInvitedUsers = _localInvitedUsers; // no-op
            });
          },
        ),
      ],
    );
  }
}
