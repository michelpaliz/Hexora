import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/group_model/invite/invite.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/c-frontend/enums/invitation/invitation_status.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/b-backend/user/repository/i_user_repository.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/enable_banking/widgets/folder_section_card.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/members/presentation/controller/add_user_controller.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/members/presentation/controller/contract_for_controller/interface/IGroup_editor_port.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/members/presentation/controller/contract_for_controller/service/vm_group_editor_port.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/members/presentation/domain/models/members_ref.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/members/presentation/domain/models/members_vm.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/members/presentation/screen/tabs/add_user_tab.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/members/presentation/widgets/add_users_flow/widgets/add_user_bottom_sheet.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/members/presentation/widgets/member_row/components/members_role_chip.dart';
import 'package:hexora/c-frontend/utils/image/user_image/avatar_utils.dart';
import 'package:hexora/c-frontend/utils/roles/group_role/group_role.dart';
import 'package:hexora/c-frontend/utils/roles/group_role/group_role_labels.dart';
import 'package:hexora/c-frontend/utils/roles/role_policy/role_policy.dart';
import 'package:hexora/c-frontend/viewmodels/group_vm/presentation/common/ui_messenger.dart';
import 'package:hexora/c-frontend/viewmodels/group_vm/presentation/use_cases/create_group_usecase.dart';
import 'package:hexora/c-frontend/viewmodels/group_vm/presentation/use_cases/invite_members_usecase.dart';
import 'package:hexora/c-frontend/viewmodels/group_vm/presentation/use_cases/search_users_usecase.dart';
import 'package:hexora/c-frontend/viewmodels/group_vm/presentation/use_cases/update_group_usecase.dart';
import 'package:hexora/c-frontend/viewmodels/group_vm/presentation/use_cases/upload_group_photo_usecase.dart';
import 'package:hexora/c-frontend/viewmodels/group_vm/view_model/group_view_model.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

part 'settings_members_section/settings_members_actions_part.dart';
part 'settings_members_section/settings_members_add_user_part.dart';
part 'settings_members_section/settings_members_detail_part.dart';
part 'settings_members_section/settings_members_list_part.dart';
part 'settings_members_section/settings_members_models_part.dart';
part 'settings_members_section/settings_members_tabs_part.dart';

class SettingsMembersSection extends StatefulWidget {
  final Group group;
  final MembersVM membersVM;
  final bool isLoading;

  const SettingsMembersSection({
    super.key,
    required this.group,
    required this.membersVM,
    required this.isLoading,
  });

  @override
  State<SettingsMembersSection> createState() => _SettingsMembersSectionState();
}

class _SettingsMembersSectionState extends State<SettingsMembersSection> {
  bool _seeded = false;
  late Future<List<GroupRole>> _rolesFuture;
  int _selectedTab = 0; // 0=accepted, 1=pending, 2=notAccepted, 3=addUser
  MemberRef? _selectedMember;
  User? _selectedUser;
  Invitation? _selectedInvitation;
  bool _loadingUser = false;

  @override
  void initState() {
    super.initState();
    _rolesFuture = Future.value(<GroupRole>[]);
  }

  Future<void> _seedVmFromGroupOnce(BuildContext context) async {
    if (_seeded) return;

    final repo = context.read<IUserRepository>();
    final port = context.read<IGroupEditorPort>();

    final availableRoles = await _rolesFuture
        .catchError((_) => <GroupRole>[])
        .then((v) => v.isNotEmpty ? v : GroupRole.defaults);

    final Map<String, User> membersById = {};
    for (final id in widget.group.userIds) {
      try {
        final u = await repo.getUserById(id);
        membersById[u.id] = u;
      } catch (_) {}
    }

    final Map<String, GroupRole> roles = {};
    widget.group.userRoles.forEach((userId, wire) {
      roles[userId] = GroupRole.fromWire(wire, available: availableRoles);
    });

    await port.seedMembers(membersById: membersById, roles: roles);
    if (mounted) setState(() => _seeded = true);
  }

  List<MemberRef> get _currentMembers {
    switch (_selectedTab) {
      case 0:
        return widget.membersVM.accepted;
      case 1:
        return widget.membersVM.pending;
      case 2:
        return widget.membersVM.notAccepted;
      default:
        return [];
    }
  }

  Future<void> _selectMember(MemberRef ref) async {
    setState(() {
      _selectedMember = ref;
      _selectedUser = null;
      _selectedInvitation = null;
      _loadingUser = true;
    });

    // Look up matching invitation by userId or email
    final invitations = widget.membersVM.invitations;
    final inv = invitations.cast<Invitation?>().firstWhere(
          (i) =>
              i!.userId == ref.username ||
              i.email == ref.username,
          orElse: () => null,
        );

    try {
      final repo = context.read<IUserRepository>();
      final user = await repo.getUserBySelector(ref.username);
      if (mounted) {
        setState(() {
          _selectedUser = user;
          _selectedInvitation = inv;
          _loadingUser = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _selectedInvitation = inv;
          _loadingUser = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: FolderSectionCard(
        label: l.membersTitle,
        leftTabOffset: 0,
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (widget.isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: CircularProgressIndicator(color: cs.primary),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTabChips(context),
          const SizedBox(height: 12),
          if (_selectedTab == 3)
            LimitedBox(
              maxHeight: 400,
              child: _buildAddMembersTab(context),
            )
          else
            _buildSplitPanel(context),
        ],
      ),
    );
  }

  String _initials(String text) {
    final t = text.trim();
    if (t.isEmpty) return '?';
    final parts = t.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  void _updateUi([VoidCallback? updater]) {
    if (!mounted) return;
    setState(updater ?? () {});
  }
}
