import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/notification_model/userInvitation_status.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/auth_user/user/domain/user_domain.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/group_mng_flow/group/view_model/group_view_model.dart';
import 'package:hexora/b-backend/group_mng_flow/group/view_model/presentation/common/ui_messenger.dart';
// OLD VM import removed:

// NEW: use cases needed by the new VM
import 'package:hexora/b-backend/group_mng_flow/group/view_model/presentation/use_cases/create_group_usecase.dart';
import 'package:hexora/b-backend/group_mng_flow/group/view_model/presentation/use_cases/invite_members_usecase.dart';
import 'package:hexora/b-backend/group_mng_flow/group/view_model/presentation/use_cases/search_users_usecase.dart';
import 'package:hexora/b-backend/group_mng_flow/group/view_model/presentation/use_cases/upload_group_photo_usecase.dart';
import 'package:hexora/b-backend/notification/domain/notification_domain.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/group/create_edit/widgets/filters/admin_filter_sections.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/group/create_edit/widgets/lists/user_list_section.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/utils/shared/add_user_button/add_user_button.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

enum InviteFilter { accepted, pending, notAccepted, newUsers, expired }

class EditGroupPeople extends StatefulWidget {
  final Group group;
  final List<User> initialUsers;
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
  GroupEditorViewModel?
      _controller; // was `late`, now nullable until we build it

  // Local, temporary state (NOT persisted until Save)
  late List<User> _localUsers;
  late Map<String, String> _localRoles;
  final Map<String, User> _newUsers = {};

  Map<String, UserInviteStatus> _localInvitedUsers = const {};
  Map<String, UserInviteStatus> _invitesAtOpen = const {};

  bool showAccepted = true;
  bool showPending = true;
  bool showNotWantedToJoin = true;
  bool showNewUsers = true;
  bool showExpired = true;

  late User? _currentUser;
  late String _currentUserRawRole;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.userDomain.user;

    _localUsers = List<User>.from(widget.initialUsers);
    _localRoles = Map<String, String>.fromEntries(
      widget.group.userRoles.entries.map(
        (e) => MapEntry(e.key, e.value.toLowerCase()),
      ),
    );
    _localRoles[widget.group.ownerId] = 'owner';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Build the NEW VM here once, with required dependencies (no initialize()).
    if (_controller == null && _currentUser != null) {
      _controller = GroupEditorViewModel(
        currentUser: _currentUser!,
        ui: MaterialUiMessenger(context),
        createGroup: context.read<CreateGroupUseCase>(),
        inviteMembers: context.read<InviteMembersUseCase>(),
        uploadPhoto: context.read<UploadGroupPhotoUseCase>(),
        searchUsersUseCase: context.read<SearchUsersUseCase>(),
      );
    }

    final uid = _currentUser?.id ?? '';
    _currentUserRawRole = (uid == widget.group.ownerId)
        ? 'owner'
        : (widget.group.userRoles[uid]?.toLowerCase() ?? 'member');
  }

  void _onNewUserAdded(User user) {
    setState(() {
      final exists = _localUsers.any((u) => u.id == user.id) ||
          _newUsers.containsKey(user.userName);
      if (exists) return;
      _newUsers[user.userName] = user;
      _localRoles[user.id] = _localRoles[user.id] ?? 'member';
    });
  }

  Map<String, User> get _filteredNewUsers => showNewUsers ? _newUsers : {};

  List<User> getFinalUsers() => List<User>.from(_localUsers);
  Map<String, String> getFinalRoles() => Map<String, String>.from(_localRoles);
  Map<String, UserInviteStatus> getFinalInvites() =>
      Map<String, UserInviteStatus>.from(_localInvitedUsers);

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

    // If VM not ready yet, show a tiny loader
    if (_controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        AddUserButton(
          currentUser: widget.userDomain.user,
          group: widget.group,
          controller: _controller!, // ✅ new VM instance (has searchUsers)
          onUserAdded: _onNewUserAdded,
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
        UserListSection(
          newUsers: _filteredNewUsers,
          usersRoles: _localRoles,
          usersInvitations: _localInvitedUsers,
          usersInvitationAtFirst: _invitesAtOpen,
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
            });
          },
        ),
      ],
    );
  }
}
