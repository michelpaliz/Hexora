import 'package:flutter/material.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/models/user/user.dart';
import 'package:hexora/services/groups/domain/group_domain.dart';
import 'package:hexora/services/user/domain/user_domain.dart';
import 'package:hexora/presentation/routes/appRoutes.dart';
import 'package:hexora/presentation/screens/calendar/screens/group/group-settings/widgets/group_danger_zone_card.dart';
import 'package:hexora/presentation/screens/calendar/screens/group/group-settings/widgets/group_invitations_card.dart';
import 'package:hexora/presentation/screens/calendar/screens/group/group-settings/widgets/group_overview_card.dart';
import 'package:hexora/presentation/screens/calendar/screens/group/group-settings/widgets/group_owner_banner.dart';
import 'package:hexora/presentation/screens/calendar/screens/group/group-settings/widgets/group_roles_card.dart';
import 'package:hexora/presentation/screens/calendar/screens/group/show-groups/group_profile/dialog_choosement/confirmation_dialog.dart';
import 'package:hexora/theme/colors/app_colors.dart';
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

  @override
  void initState() {
    super.initState();
    _groupDomain = context.read<GroupDomain>();
    _userDomain = context.read<UserDomain>();
    _loadCurrentUser();
    _loadMemberNames();
  }

  Future<void> _loadMemberNames() async {
    setState(() {
      _loadingMembers = true;
      _membersFailed = false;
    });
    try {
      final users = await _userDomain.getUsersForGroup(widget.group);
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
      _showSnack(AppLocalizations.of(context)!.failedToEditGroup);
      return;
    }
    final l = AppLocalizations.of(context)!;
    setState(() => _isRemoving = true);
    try {
      final freshGroup =
          await _groupDomain.groupRepository.getGroupById(widget.group.id);
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
      final confirm =
          await showConfirmationDialog(context, l.questionDeleteGroup);
      if (!confirm) return;

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
    final group = widget.group;
    final created = DateFormat.yMMMd().format(group.createdTime);
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;
    final topBarColor =
        isDark ? AppDarkColors.dashboardTopBar : AppColors.dashboardTopBar;
    final onTopBar = isDark ? AppDarkColors.textPrimary : AppColors.white;
    final isOwner = _currentUser?.id == group.ownerId;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: topBarColor,
        elevation: 0.5,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: onTopBar),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              group.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                    color: onTopBar,
                  ) ??
                  TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                    color: onTopBar,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              l.createdOnDay(created),
              style: theme.textTheme.bodySmall?.copyWith(
                color: onTopBar.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GroupOwnerBanner(isOwner: isOwner),
            const SizedBox(height: 16),
            GroupOverviewCard(
                group: group,
                createdFormatted: created,
                ownerName: _memberName(group.ownerId)),
            const SizedBox(height: 16),
            GroupRolesCard(group: group, memberNames: {
              for (final id in group.userRoles.keys) id: _memberName(id),
            }),
            if (_membersFailed)
              TextButton.icon(
                  onPressed: _loadMemberNames,
                  icon: const Icon(Icons.refresh),
                  label: Text(l.refresh)),
            const SizedBox(height: 16),
            GroupInvitationsCard(
              onViewInvitations: () {
                // TODO: hook up to your invitations route when ready.
              },
            ),
            const SizedBox(height: 24),
            GroupDangerZoneCard(
              isOwner: isOwner,
              isLoading: _loadingUser,
              isRemoving: _isRemoving,
              onRemove: _handleRemoveGroup,
            ),
          ],
        ),
      ),
    );
  }
}
