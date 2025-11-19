// lib/c-frontend/ui-app/b-dashboard-section/dashboard_screen/header/group_header_view.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/routes/appRoutes.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/header/widget/group_header_card.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/members/presentation/domain/models/members_count.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/group/show-groups/group_profile/dialog_choosement/action/edit_group_arg.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class GroupHeaderView extends StatefulWidget {
  final Group group;
  final VoidCallback? onEditGroup;

  const GroupHeaderView({
    super.key,
    required this.group,
    this.onEditGroup,
  });

  @override
  State<GroupHeaderView> createState() => _GroupHeaderViewState();
}

class _GroupHeaderViewState extends State<GroupHeaderView> {
  late GroupDomain _gm;
  late UserDomain _ud;
  MembersCount? _counts;
  bool _loading = false;
  bool _openingEditor = false;

  @override
  void initState() {
    super.initState();
    _gm = context.read<GroupDomain>();
    _ud = context.read<UserDomain>();
    _load();
  }

  Future<void> _handleEditGroup() async {
    if (_openingEditor) return;

    final custom = widget.onEditGroup;
    if (custom != null) {
      custom();
      return;
    }

    setState(() => _openingEditor = true);
    final rootNav = Navigator.of(context, rootNavigator: true);

    showDialog<void>(
      context: rootNav.context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final freshGroup =
          await _gm.groupRepository.getGroupById(widget.group.id);
      final users = await _ud.getUsersForGroup(freshGroup);

      if (rootNav.context.mounted) rootNav.pop();
      if (!mounted) return;

      Navigator.of(context).pushNamed(
        AppRoutes.editGroupData,
        arguments: EditGroupArguments(group: freshGroup, users: users),
      );
    } catch (e) {
      if (rootNav.context.mounted) rootNav.pop();
      if (!mounted) return;

      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l.failedToEditGroup} $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _openingEditor = false);
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final c = await _gm.groupRepository
          .getMembersCount(widget.group.id, mode: 'union');
      if (!mounted) return;
      setState(() => _counts = c);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.group;
    final l = AppLocalizations.of(context)!;
    final createdStr = DateFormat.yMMMd(l.localeName).format(g.createdTime);

    // Fallbacks + server-first
    final fallbackMembers = g.userIds.length;
    const fallbackPending = 0;
    final members = _counts?.accepted ?? fallbackMembers;
    final pending = _counts?.pending ?? fallbackPending;
    final total = _counts?.union ?? (fallbackMembers + fallbackPending);

    return GroupHeaderCard(
      photoUrl: g.photoUrl,
      title: g.name,
      description: g.description,
      createdLabel: l.createdOnDay(createdStr),
      members: members,
      pending: pending,
      total: total,
      localeName: l.localeName,
      isLoading: _loading || _openingEditor,
      onTap: _handleEditGroup, // 👈 whole header is the button
    );
  }
}
