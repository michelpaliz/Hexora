import 'package:hexora/presentation/shared/widgets/section_app_bar.dart';
import 'package:hexora/presentation/screens/workspace/sections/members/presentation/screen/group_members_screen.dart';
import 'package:hexora/presentation/screens/calendar/screens/group/show-groups/group_profile/dialog_choosement/action/edit_group_arg.dart';
import 'widgets/delete_group_dialog.dart';
import 'package:flutter/material.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/models/user/user.dart';
import 'package:hexora/services/groups/domain/group_domain.dart';
import 'package:hexora/services/user/domain/user_domain.dart';
import 'package:hexora/presentation/routes/app_routes.dart';
import 'package:hexora/presentation/screens/calendar/screens/group/group-settings/widgets/group_danger_zone_card.dart';
import 'package:hexora/presentation/screens/calendar/screens/group/group-settings/widgets/group_overview_card.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class GroupSettings extends StatefulWidget {
  final Group group;

  const GroupSettings({super.key, required this.group});

  @override
  State<GroupSettings> createState() => _GroupSettingsState();
}

class _GroupSettingsState extends State<GroupSettings> {
  late final GroupDomain _groupDomain;
  late final UserDomain _userDomain;
  User? _currentUser;
  bool _loadingUser = true;
  bool _isRemoving = false;
  final Map<String, String> _memberNames = {};
  bool _loadingMembers = true;
  bool _membersFailed = false;
  int? _pendingCount;
  late Group _group;

  @override
  void initState() {
    super.initState();
    _group = widget.group;
    _groupDomain = context.read<GroupDomain>();
    _userDomain = context.read<UserDomain>();
    _loadCurrentUser();
    _loadMemberNames();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    try {
      final counts = await _groupDomain.groupRepository
          .getMembersCount(_group.id, mode: 'union');
      if (mounted) setState(() => _pendingCount = counts.pending);
    } catch (_) {
      if (mounted) setState(() => _pendingCount = null);
    }
  }

  Future<void> _refreshGroup() async {
    try {
      final fresh = await _groupDomain.groupRepository.getGroupById(_group.id);
      if (!mounted) return;
      setState(() => _group = fresh);
      await Future.wait([_loadMemberNames(), _loadCounts()]);
    } catch (_) {
      if (mounted) _showSnack(AppLocalizations.of(context)!.failedToEditGroup);
    }
  }

  Future<void> _openMembers({int initialTab = 0}) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => GroupMembersScreen(group: _group, initialTab: initialTab),
    ));
    if (mounted) await _refreshGroup();
  }

  Future<void> _editInformation() async {
    try {
      final users = await _userDomain.getUsersForGroup(_group);
      if (!mounted) return;
      await Navigator.pushNamed(context, AppRoutes.editGroupData,
          arguments: EditGroupArguments(group: _group, users: users));
      if (mounted) await _refreshGroup();
    } catch (_) {
      if (mounted) _showSnack(AppLocalizations.of(context)!.failedToEditGroup);
    }
  }

  Future<void> _loadMemberNames() async {
    setState(() {
      _loadingMembers = true;
      _membersFailed = false;
    });
    try {
      final users = await _userDomain.getUsersForGroup(_group);
      if (!mounted) return;
      setState(() {
        for (final user in users) {
          final name = (user.displayName ?? '').trim();
          _memberNames[user.id] = name.isNotEmpty
              ? name
              : user.name.trim().isNotEmpty
                  ? user.name.trim()
                  : user.userName;
        }
      });
    } catch (_) {
      if (mounted) setState(() => _membersFailed = true);
    } finally {
      if (mounted) setState(() => _loadingMembers = false);
    }
  }

  String _memberName(String id) =>
      _memberNames[id] ??
      (_currentUser?.id == id
          ? _currentUser!.name
          : _loadingMembers
              ? '…'
              : (Localizations.localeOf(context).languageCode == 'es'
                  ? 'Nombre no disponible'
                  : 'Name unavailable'));

  Future<void> _loadCurrentUser() async {
    final user = await _getCurrentUserSafe();
    if (!mounted) return;
    setState(() {
      _currentUser = user;
      _loadingUser = false;
    });
  }

  Future<User?> _getCurrentUserSafe() async {
    try {
      final u = await _userDomain.getUser();
      if (u != null) return u;
    } catch (_) {}
    try {
      final dynamic maybe = (_userDomain as dynamic).currentUser;
      if (maybe is User) return maybe;
    } catch (_) {}
    try {
      final dynamic me = (_userDomain as dynamic).me;
      if (me is Future<User?> Function()) {
        return await me();
      }
    } catch (_) {}
    return null;
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleRemoveGroup() async {
    if (_isRemoving) return;
    final user = _currentUser ?? await _getCurrentUserSafe();
    if (user == null) {
      if (!mounted) return;
      _showSnack(AppLocalizations.of(context)!.failedToEditGroup);
      return;
    }
    if (!mounted) return;
    final l = AppLocalizations.of(context)!;
    setState(() => _isRemoving = true);
    try {
      final freshGroup =
          await _groupDomain.groupRepository.getGroupById(_group.id);
      final members = await _userDomain.getUsersForGroup(freshGroup);

      if (freshGroup.ownerId != user.id) {
        _showSnack(l.permissionDeniedInf);
        return;
      }

      final hasOtherMembers =
          members.any((member) => member.id != freshGroup.ownerId);
      if (hasOtherMembers) {
        _showSnack(l.removeMembersFirst);
        return;
      }

      if (!mounted) return;
      final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => DeleteGroupDialog(groupName: freshGroup.name));
      if (confirm != true) return;

      final ok = await _groupDomain.removeGroup(freshGroup, _userDomain);
      if (ok) {
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.homePage,
          (route) => false,
        );
      } else {
        _showSnack(l.failedToEditGroup);
      }
    } catch (e) {
      _showSnack('${l.failedToEditGroup} $e');
    } finally {
      if (mounted) {
        setState(() => _isRemoving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = _group;
    final created = DateFormat.yMMMd(Localizations.localeOf(context).toString())
        .format(group.createdTime);
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final isOwner = _currentUser?.id == group.ownerId;
    final canEdit = isOwner ||
        const ['admin', 'co-admin'].contains(group.userRoles[_currentUser?.id]);

    return Scaffold(
      appBar: SectionAppBar(title: l.groupSettingsTitle),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshGroup,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                  child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l.groupSettingsInformation,
                        style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    GroupOverviewCard(
                      group: group,
                      createdFormatted: created,
                      ownerName: _memberName(group.ownerId),
                      onEdit: canEdit ? _editInformation : null,
                    ),
                    const SizedBox(height: 20),
                    Text(l.groupSettingsMembersPermissions,
                        style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 0,
                      child: Column(children: [
                        ListTile(
                          leading: Icon(Icons.people_outline,
                              color: theme.colorScheme.primary),
                          title: Text(l.groupSettingsMembersRoles),
                          subtitle: Text(
                              '${group.userIds.length} ${l.membersTitle.toLowerCase()}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _openMembers,
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        ListTile(
                          leading: Icon(Icons.mail_outline,
                              color: theme.colorScheme.primary),
                          title: Text(l.groupSettingsInvitationsTitle),
                          subtitle: _pendingCount == null
                              ? null
                              : Text(
                                  l.groupSettingsPendingCount(_pendingCount!)),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _openMembers(initialTab: 1),
                        ),
                      ]),
                    ),
                    if (_membersFailed)
                      TextButton.icon(
                          onPressed: _loadMemberNames,
                          icon: const Icon(Icons.refresh),
                          label: Text(l.refresh)),
                    const SizedBox(height: 24),
                    GroupDangerZoneCard(
                      isOwner: isOwner,
                      isLoading: _loadingUser,
                      isRemoving: _isRemoving,
                      onRemove: _handleRemoveGroup,
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
