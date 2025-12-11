// lib/c-frontend/ui-app/b-dashboard-section/dashboard_screen/header/group_header_view.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/client/client_api.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/worker/repository/time_tracking_repository.dart';
import 'package:hexora/b-backend/group_mng_flow/event/repository/i_event_repository.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/routes/appRoutes.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/header/widget/group_header_card.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/members/presentation/domain/models/members_count.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/undone_events/group_undone_events/group_undone_events_screen.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/group/show-groups/group_profile/dialog_choosement/action/edit_group_arg.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/dashboard/controller/group_dashboard_state.dart';
import 'package:hexora/c-frontend/utils/roles/group_role/group_role.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class GroupHeaderView extends StatefulWidget {
  final Group group;
  final VoidCallback? onEditGroup;
  final bool allowEditing;

  const GroupHeaderView({
    super.key,
    required this.group,
    this.onEditGroup,
    this.allowEditing = true,
  });

  @override
  State<GroupHeaderView> createState() => _GroupHeaderViewState();
}

class _GroupHeaderViewState extends State<GroupHeaderView> {
  late GroupDomain _gm;
  late UserDomain _ud;
  ClientsApi? _clientsApi;
  ITimeTrackingRepository? _timeRepo;
  IEventRepository? _eventRepo;
  MembersCount? _counts;
  int? _clientCount;
  int? _workerCount;
  int? _pendingEventsCount;
  bool _membersLoading = false;
  bool _clientsLoading = false;
  bool _workersLoading = false;
  bool _pendingEventsLoading = false;
  bool _openingEditor = false;

  @override
  void initState() {
    super.initState();
    _gm = context.read<GroupDomain>();
    _ud = context.read<UserDomain>();
    _captureDependencies();
    _loadMembers();
    _loadClientCount();
    _loadWorkerCount();
    _loadPendingEventsCount();
  }

  @override
  void didUpdateWidget(covariant GroupHeaderView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.group.id != widget.group.id) {
      _loadMembers();
      _loadClientCount();
      _loadWorkerCount();
      _loadPendingEventsCount();
    }
  }

  void _captureDependencies() {
    _clientsApi = ClientsApi();
    try {
      _timeRepo = context.read<ITimeTrackingRepository>();
    } catch (_) {
      _timeRepo = null;
    }
    try {
      _eventRepo = context.read<IEventRepository>();
    } catch (_) {
      _eventRepo = null;
    }
  }

  Future<void> _handleEditGroup() async {
    if (_openingEditor) return;

    final custom = widget.onEditGroup;
    if (custom != null) {
      custom();
      return;
    }

    final isWide = MediaQuery.of(context).size.width >= 900;
    if (isWide) {
      final state = context.read<GroupDashboardState?>();
      if (state != null) {
        state.openSection('editGroup');
        return;
      }
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

  Future<void> _loadMembers() async {
    setState(() => _membersLoading = true);
    try {
      final c = await _gm.groupRepository
          .getMembersCount(widget.group.id, mode: 'union');
      if (!mounted) return;
      setState(() => _counts = c);
    } finally {
      if (mounted) setState(() => _membersLoading = false);
    }
  }

  Future<void> _loadClientCount() async {
    if (_clientsApi == null) return;
    setState(() => _clientsLoading = true);
    try {
      final clients =
          await _clientsApi!.list(groupId: widget.group.id, active: true);
      if (!mounted) return;
      setState(() => _clientCount = clients.length);
    } catch (_) {
      if (!mounted) return;
      setState(() => _clientCount = null);
    } finally {
      if (mounted) setState(() => _clientsLoading = false);
    }
  }

  Future<void> _loadWorkerCount() async {
    final repo = _timeRepo;
    if (repo == null) return;
    setState(() => _workersLoading = true);
    try {
      final token = await _ud.getAuthToken();
      final workers = await repo.getWorkers(widget.group.id, token);
      if (!mounted) return;
      setState(() => _workerCount = workers.length);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      if (msg.contains('403') || msg.contains('404')) {
        setState(() => _workerCount = 0);
      } else {
        setState(() => _workerCount = null);
      }
    } finally {
      if (mounted) setState(() => _workersLoading = false);
    }
  }

  Future<void> _loadPendingEventsCount() async {
    final repo = _eventRepo;
    if (repo == null) return;
    setState(() => _pendingEventsLoading = true);
    try {
      final events = await repo.getEventsByGroupId(widget.group.id);
      if (!mounted) return;
      final user = _ud.user;
      String? userId = user?.id;
      GroupRole? role;
      if (userId != null) {
        role = GroupRole.fromWire(widget.group.userRoles[userId]);
      }
      final canSeeAll = role == null || role != GroupRole.member;
      final visible = canSeeAll || userId == null
          ? events
          : events.where((event) => event.ownerId == userId).toList();
      final pending = visible.where((event) => event.isDone != true).length;
      setState(() => _pendingEventsCount = pending);
    } catch (_) {
      if (!mounted) return;
      setState(() => _pendingEventsCount = null);
    } finally {
      if (mounted) setState(() => _pendingEventsLoading = false);
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
    final statsLoading = _membersLoading ||
        _clientsLoading ||
        _workersLoading ||
        _pendingEventsLoading ||
        _openingEditor;

    void openMembers() {
      Navigator.pushNamed(
        context,
        AppRoutes.groupMembers,
        arguments: g,
      );
    }

    void openClients() {
      Navigator.pushNamed(
        context,
        AppRoutes.groupServicesClients,
        arguments: g,
      );
    }

    void openWorkers() {
      Navigator.pushNamed(
        context,
        AppRoutes.groupTimeTracking,
        arguments: g,
      );
    }

    void openPendingEvents() {
      _pushPendingEvents(context);
    }

    return GroupHeaderCard(
      photoUrl: g.photoUrl,
      title: g.name,
      description: g.description,
      createdLabel: l.createdOnDay(createdStr),
      members: members,
      pending: pending,
      total: total,
      localeName: l.localeName,
      isLoading: statsLoading,
      onTap: widget.allowEditing ? _handleEditGroup : null,
      clientCount: _clientCount,
      workerCount: _workerCount,
      pendingEventsCount: _pendingEventsCount,
      onMembersTap: openMembers,
      onPendingEventsTap: openPendingEvents,
      onClientsTap: openClients,
      onWorkersTap: openWorkers,
      editTooltip: l.editGroup,
    );
  }

  Future<void> _pushPendingEvents(BuildContext context) async {
    User? resolvedUser = _ud.user;
    resolvedUser ??= await _ud.getUser();
    if (!mounted || resolvedUser == null) return;
    final roleWire = widget.group.userRoles[resolvedUser.id];
    final role = GroupRole.fromWire(roleWire);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GroupUndoneEventsScreen(
          group: widget.group,
          user: resolvedUser!,
          role: role,
        ),
      ),
    );
  }
}
