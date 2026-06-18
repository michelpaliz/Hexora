import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show KeyDownEvent, KeyEvent, LogicalKeyboardKey;
import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/group_mng_flow/event/repository/i_event_repository.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/members/presentation/widgets/shared/header_info.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/undone_events/group_undone_event_detail_sheet.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/undone_events/group_undone_events/widgets/group_undone_events_list_view.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/undone_events/group_undone_events/widgets/undone_events_segmented_tab_bar.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/event_screen/event_detail/event_detail_screen.dart';
import 'package:hexora/c-frontend/utils/roles/group_role/group_role.dart';
import 'package:hexora/c-frontend/viewmodels/group_vm/view_model/group_view_model.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class GroupUndoneEventsScreen extends StatelessWidget {
  const GroupUndoneEventsScreen({
    super.key,
    required this.group,
    required this.user,
    required this.role,
    this.embedded = false,
  });

  final Group group;
  final User user;
  final GroupRole role;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<GroupUndoneEventsViewModel>(
      create: (ctx) {
        final userDomain = ctx.read<UserDomain>();
        return GroupUndoneEventsViewModel(
          groupId: group.id,
          currentUserId: user.id,
          role: role,
          eventRepository: ctx.read<IEventRepository>(),
          userResolver: (ownerId) async {
            try {
              return await userDomain.getUserById(ownerId);
            } catch (_) {
              return null;
            }
          },
        )..refresh();
      },
      child: DefaultTabController(
        length: 2,
        child: _GroupUndoneEventsScreenBody(
          group: group,
          role: role,
          embedded: embedded,
        ),
      ),
    );
  }
}

// ── Mobile body (unchanged) ────────────────────────────────────────────────────

class _GroupUndoneEventsScreenBody extends StatelessWidget {
  const _GroupUndoneEventsScreenBody({
    required this.group,
    required this.role,
    required this.embedded,
  });

  final Group group;
  final GroupRole role;
  final bool embedded;

  Widget _buildContent(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Consumer<GroupUndoneEventsViewModel>(
      builder: (context, vm, _) {
        return Column(
          children: [
            if (vm.isLoading) const LinearProgressIndicator(minHeight: 2),
            InfoHeader(
              title: loc.pendingEventsSectionTitle,
              subtitle:
                  '${loc.pendingEventsSectionSubtitle}\n${loc.completedEventsSectionSubtitle}',
              stats: [
                StatChip(
                  label: loc.statusPending,
                  count: vm.pendingEvents.length,
                  icon: Icons.pending_actions_outlined,
                ),
                StatChip(
                  label: loc.completedEventsSectionTitle,
                  count: vm.completedEvents.length,
                  icon: Icons.task_alt_rounded,
                ),
              ],
            ),
            if (role != GroupRole.member)
              Consumer<GroupUndoneEventsViewModel>(
                builder: (context, vm, __) {
                  final chips = vm.participantInfos;
                  if (chips.isEmpty) return const SizedBox.shrink();
                  return SingleChildScrollView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: Text(loc.all),
                          selected: vm.filterUserId == null,
                          onSelected: (v) =>
                              vm.setFilterUser(v ? null : vm.filterUserId),
                        ),
                        const SizedBox(width: 8),
                        ...chips.map(
                          (info) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(info.displayName),
                              selected: vm.filterUserId == info.id,
                              onSelected: (_) => vm.setFilterUser(info.id),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            Expanded(
              child: TabBarView(
                children: [
                  RefreshIndicator(
                    onRefresh: vm.refresh,
                    child: GroupUndoneEventsListView(
                      events: vm.pendingEvents,
                      emptyIcon: Icons.checklist_rtl_rounded,
                      emptyMessage: loc.pendingEventsEmpty,
                      errorMessage: vm.errorMessage ?? loc.pendingEventsError,
                      showError:
                          vm.errorMessage != null && vm.pendingEvents.isEmpty,
                      allowAction: true,
                      doneList: false,
                      viewModel: vm,
                      onTapEvent: (event) => showEventDetailSheet(
                        context: context,
                        event: event,
                        viewModel: vm,
                        allowMarkComplete: vm.canManageEvent(event),
                      ),
                    ),
                  ),
                  RefreshIndicator(
                    onRefresh: vm.refresh,
                    child: GroupUndoneEventsListView(
                      events: vm.completedEvents,
                      emptyIcon: Icons.task_alt_outlined,
                      emptyMessage: loc.completedEventsEmpty,
                      allowAction: false,
                      doneList: true,
                      viewModel: vm,
                      onTapEvent: (event) => showEventDetailSheet(
                        context: context,
                        event: event,
                        viewModel: vm,
                        allowMarkComplete: false,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900 && !embedded;
    final useEmbeddedDesktopLayout = embedded && width >= 1100;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: cs.surface,
        body: SafeArea(
          child: _UndoneEventsDesktopLayout(group: group, role: role),
        ),
      );
    }

    if (useEmbeddedDesktopLayout) {
      return _UndoneEventsDesktopLayout(group: group, role: role);
    }

    if (embedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    loc.pendingEventsSectionTitle,
                    style: t.titleLarge.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: loc.refreshButton,
                  onPressed:
                      context.read<GroupUndoneEventsViewModel>().refresh,
                ),
              ],
            ),
          ),
          const UndoneEventsSegmentedTabBar(),
          Expanded(child: _buildContent(context)),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: cs.surface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.pendingEventsSectionTitle,
              style: t.titleLarge.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        iconTheme: IconThemeData(color: ThemeColors.textPrimary(context)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(56),
          child: UndoneEventsSegmentedTabBar(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: loc.refreshButton,
            onPressed: () =>
                context.read<GroupUndoneEventsViewModel>().refresh(),
          ),
        ],
      ),
      body: SafeArea(child: _buildContent(context)),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Desktop layout — full 2-column redesign
// ═══════════════════════════════════════════════════════════════════════════════

class _UndoneEventsDesktopLayout extends StatefulWidget {
  const _UndoneEventsDesktopLayout({
    required this.group,
    required this.role,
  });

  final Group group;
  final GroupRole role;

  @override
  State<_UndoneEventsDesktopLayout> createState() =>
      _UndoneEventsDesktopLayoutState();
}

class _UndoneEventsDesktopLayoutState
    extends State<_UndoneEventsDesktopLayout> {
  Event? _selectedEvent;
  bool _showDone = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  final _listFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _listFocusNode.dispose();
    super.dispose();
  }

  List<Event> _filter(List<Event> events) {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return events;
    return events
        .where((e) =>
            e.title.toLowerCase().contains(q) ||
            (e.description?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  void _select(Event? e) => setState(() => _selectedEvent = e);

  void _onKey(KeyEvent ev, List<Event> events) {
    if (ev is! KeyDownEvent || events.isEmpty) return;
    final idx = _selectedEvent == null ? -1 : events.indexOf(_selectedEvent!);
    if (ev.logicalKey == LogicalKeyboardKey.arrowDown) {
      _select(events[(idx + 1).clamp(0, events.length - 1)]);
    } else if (ev.logicalKey == LogicalKeyboardKey.arrowUp) {
      _select(events[(idx - 1).clamp(0, events.length - 1)]);
    } else if (ev.logicalKey == LogicalKeyboardKey.escape) {
      _select(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final loc = AppLocalizations.of(context)!;
    final isEs = loc.localeName.startsWith('es');

    return Consumer<GroupUndoneEventsViewModel>(
      builder: (context, vm, _) {
        final rawList = _showDone ? vm.completedEvents : vm.pendingEvents;
        final events = _filter(rawList);
        final totalPending = vm.pendingEvents.length;
        final totalDone = vm.completedEvents.length;
        final total = totalPending + totalDone;
        final donePct = total == 0 ? 0.0 : totalDone / total;
        final participants = widget.role != GroupRole.member
            ? vm.participantInfos
            : <EventOwnerInfo>[];

        // Deselect if selected event filtered out
        if (_selectedEvent != null &&
            !events.any((e) => e.id == _selectedEvent!.id)) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _select(null));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Top header bar ──────────────────────────────────────────────
            _DesktopWorkbenchHeader(
              title: loc.pendingEventsSectionTitle,
              pendingCount: totalPending,
              completedCount: totalDone,
              donePct: donePct,
              isLoading: vm.isLoading,
              onRefresh: vm.refresh,
              showDone: _showDone,
              onTabChanged: (v) => setState(() {
                _showDone = v;
                _selectedEvent = null;
              }),
              searchController: _searchController,
              onSearchChanged: (q) => setState(() {
                _searchQuery = q;
                _selectedEvent = null;
              }),
              isEs: isEs,
              cs: cs,
              t: t,
            ),

            // ── Body: 70/30 split ───────────────────────────────────────────
            Expanded(
              child: KeyboardListener(
                focusNode: _listFocusNode,
                onKeyEvent: (e) => _onKey(e, events),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Left: event list (70%) ──────────────────────────────
                    Expanded(
                      flex: 7,
                      child: _DesktopWorkbenchEventList(
                        events: events,
                        viewModel: vm,
                        selectedId: _selectedEvent?.id,
                        isDoneList: _showDone,
                        onSelect: _select,
                        emptyMessage: _showDone
                            ? loc.completedEventsEmpty
                            : loc.pendingEventsEmpty,
                        onRefresh: vm.refresh,
                        isEs: isEs,
                        totalPending: totalPending,
                        totalDone: totalDone,
                      ),
                    ),

                    // Divider
                    const SizedBox(width: 24),

                    // ── Right: sidebar (30%) ────────────────────────────────
                    SizedBox(
                      width: 360,
                      child: _DesktopSidebar(
                        viewModel: vm,
                        selectedEvent: _selectedEvent,
                        showDone: _showDone,
                        participants: participants,
                        totalPending: totalPending,
                        totalDone: totalDone,
                        donePct: donePct,
                        onCloseDetail: () => _select(null),
                        onMarkedDone: () => _select(null),
                        isEs: isEs,
                        cs: cs,
                        t: t,
                        loc: loc,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Desktop header ─────────────────────────────────────────────────────────────

class _DesktopWorkbenchHeader extends StatelessWidget {
  const _DesktopWorkbenchHeader({
    required this.title,
    required this.pendingCount,
    required this.completedCount,
    required this.donePct,
    required this.isLoading,
    required this.onRefresh,
    required this.showDone,
    required this.onTabChanged,
    required this.searchController,
    required this.onSearchChanged,
    required this.isEs,
    required this.cs,
    required this.t,
  });

  final String title;
  final int pendingCount;
  final int completedCount;
  final double donePct;
  final bool isLoading;
  final VoidCallback onRefresh;
  final bool showDone;
  final ValueChanged<bool> onTabChanged;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final bool isEs;
  final ColorScheme cs;
  final AppTypography t;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.18)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: t.titleLarge.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isEs
                      ? 'Revisa, filtra y completa las visitas pendientes desde una sola vista.'
                      : 'Review, filter, and complete pending visits from a single workspace.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.72),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _WorkbenchStatCard(
                        label: isEs ? 'Pendientes' : 'Pending',
                        value: '$pendingCount',
                        icon: Icons.pending_actions_outlined,
                        color: cs.primary,
                        cs: cs,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _WorkbenchStatCard(
                        label: isEs ? 'Completados' : 'Completed',
                        value: '$completedCount',
                        icon: Icons.task_alt_rounded,
                        color: cs.secondary,
                        cs: cs,
                      ),
                    ),
                    if (pendingCount + completedCount > 0) ...[
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 180,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${(donePct * 100).round()}% ${isEs ? 'completado' : 'done'}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color:
                                    cs.onSurfaceVariant.withValues(alpha: 0.72),
                              ),
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: donePct,
                                minHeight: 6,
                                backgroundColor: cs.surfaceContainerHighest,
                                valueColor:
                                    AlwaysStoppedAnimation(cs.secondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      isEs ? 'Vista' : 'View',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _HeaderTabToggle(
                      label: isEs ? 'Pendientes' : 'Pending',
                      count: pendingCount,
                      selected: !showDone,
                      onTap: () => onTabChanged(false),
                      cs: cs,
                    ),
                    const SizedBox(width: 8),
                    _HeaderTabToggle(
                      label: isEs ? 'Completados' : 'Completed',
                      count: completedCount,
                      selected: showDone,
                      onTap: () => onTabChanged(true),
                      cs: cs,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          SizedBox(
            width: 300,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  style: TextStyle(fontSize: 13, color: cs.onSurface),
                  decoration: InputDecoration(
                    hintText: isEs
                        ? 'Buscar evento o cliente...'
                        : 'Search event or client...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.45),
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 16,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.45),
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.35),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: cs.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: cs.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: cs.primary.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: 38,
                    height: 38,
                    child: IconButton(
                      icon: Icon(
                        Icons.refresh_rounded,
                        size: 18,
                        color: cs.onSurfaceVariant,
                      ),
                      tooltip: isEs ? 'Actualizar' : 'Refresh',
                      onPressed: isLoading ? null : onRefresh,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      style: IconButton.styleFrom(
                        backgroundColor:
                            cs.surfaceContainerHighest.withValues(alpha: 0.28),
                        side: BorderSide(
                          color: cs.outlineVariant.withValues(alpha: 0.22),
                        ),
                      ),
                    ),
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

class _WorkbenchStatCard extends StatelessWidget {
  const _WorkbenchStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.cs,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: cs.onSurface,
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

class _DesktopWorkbenchEventList extends StatelessWidget {
  const _DesktopWorkbenchEventList({
    required this.events,
    required this.viewModel,
    required this.selectedId,
    required this.isDoneList,
    required this.onSelect,
    required this.emptyMessage,
    required this.onRefresh,
    required this.isEs,
    required this.totalPending,
    required this.totalDone,
  });

  final List<Event> events;
  final GroupUndoneEventsViewModel viewModel;
  final String? selectedId;
  final bool isDoneList;
  final ValueChanged<Event?> onSelect;
  final String emptyMessage;
  final Future<void> Function() onRefresh;
  final bool isEs;
  final int totalPending;
  final int totalDone;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isDoneList
                            ? (isEs ? 'Eventos completados' : 'Completed events')
                            : (isEs ? 'Eventos pendientes' : 'Pending events'),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isDoneList
                            ? '${isEs ? 'Mostrando' : 'Showing'} $totalDone ${isEs ? 'eventos completados' : 'completed events'}'
                            : '${isEs ? 'Mostrando' : 'Showing'} $totalPending ${isEs ? 'eventos pendientes' : 'pending events'}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.68),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Text(
                    '${events.length} ${isEs ? 'resultados' : 'results'}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: cs.outlineVariant.withValues(alpha: 0.12),
          ),
          Expanded(
            child: events.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isDoneList
                                ? Icons.task_alt_outlined
                                : Icons.checklist_rtl_rounded,
                            size: 28,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          emptyMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: onRefresh,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
                      itemCount: events.length,
                      itemBuilder: (context, i) {
                        final event = events[i];
                        final isSelected = event.id == selectedId;
                        final owner = viewModel.ownerInfoOf(event.ownerId);
                        final canManage = viewModel.canManageEvent(event);
                        return _DesktopWorkbenchEventRow(
                          event: event,
                          viewModel: viewModel,
                          owner: owner,
                          isSelected: isSelected,
                          isDone: isDoneList,
                          canMarkDone: !isDoneList && canManage,
                          onTap: () => onSelect(isSelected ? null : event),
                          onMarkDone: canManage && !isDoneList
                              ? () => viewModel.markEventAsDone(event.id)
                              : null,
                          isEs: isEs,
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _DesktopWorkbenchEventRow extends StatefulWidget {
  const _DesktopWorkbenchEventRow({
    required this.event,
    required this.viewModel,
    required this.owner,
    required this.isSelected,
    required this.isDone,
    required this.canMarkDone,
    required this.onTap,
    required this.isEs,
    this.onMarkDone,
  });

  final Event event;
  final GroupUndoneEventsViewModel viewModel;
  final EventOwnerInfo? owner;
  final bool isSelected;
  final bool isDone;
  final bool canMarkDone;
  final VoidCallback onTap;
  final VoidCallback? onMarkDone;
  final bool isEs;

  @override
  State<_DesktopWorkbenchEventRow> createState() => _DesktopWorkbenchEventRowState();
}

class _DesktopWorkbenchEventRowState extends State<_DesktopWorkbenchEventRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ml = MaterialLocalizations.of(context);
    final e = widget.event;
    final isBusy = widget.viewModel.isProcessing(e.id);
    final start = e.startDate.toLocal();
    final end = e.endDate.toLocal();
    final locale = Localizations.localeOf(context).toString();
    final dateFmt = DateFormat.MMMEd(locale).format(start);
    final timeStr =
        '${ml.formatTimeOfDay(TimeOfDay.fromDateTime(start), alwaysUse24HourFormat: true)}'
        ' - '
        '${ml.formatTimeOfDay(TimeOfDay.fromDateTime(end), alwaysUse24HourFormat: true)}';
    final durMin = end.difference(start).inMinutes;
    final durStr = durMin <= 0
        ? ''
        : durMin < 60
            ? '${durMin}m'
            : durMin % 60 == 0
                ? '${durMin ~/ 60}h'
                : '${durMin ~/ 60}h ${durMin % 60}m';

    final accentColor = widget.isDone ? cs.secondary : cs.primary;
    final bgColor = widget.isSelected
        ? cs.primaryContainer.withValues(alpha: 0.12)
        : _hovered
            ? cs.surfaceContainerHighest.withValues(alpha: 0.22)
            : cs.surface;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isSelected
                  ? cs.primary.withValues(alpha: 0.32)
                  : _hovered
                      ? cs.outlineVariant.withValues(alpha: 0.28)
                      : cs.outlineVariant.withValues(alpha: 0.14),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: widget.isDone ? 0.08 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.isDone ? Icons.task_alt_rounded : _desktopEventIcon(e),
                  size: 18,
                  color: accentColor.withValues(alpha: widget.isDone ? 0.56 : 0.9),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.title.isEmpty
                          ? (widget.isEs ? 'Sin titulo' : 'Untitled')
                          : e.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: widget.isDone
                            ? cs.onSurface.withValues(alpha: 0.45)
                            : cs.onSurface,
                        decoration:
                            widget.isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      (e.description?.trim().isNotEmpty ?? false)
                          ? e.description!.trim()
                          : (widget.owner?.displayName ??
                              (widget.isEs ? 'Sin asignar' : 'Unassigned')),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.68),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateFmt,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface.withValues(alpha: 0.82),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.72),
                        ),
                      ),
                      if (durStr.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            durStr,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: 170,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (widget.owner != null)
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 9,
                                backgroundColor: accentColor.withValues(alpha: 0.16),
                                child: Text(
                                  widget.owner!.displayName.isNotEmpty
                                      ? widget.owner!.displayName[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: accentColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  widget.owner!.displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: IconButton(
                        tooltip: widget.isEs ? 'Ver detalle' : 'View details',
                        onPressed: widget.onTap,
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        style: IconButton.styleFrom(
                          backgroundColor:
                              cs.surfaceContainerHighest.withValues(alpha: 0.24),
                          side: BorderSide(
                            color: cs.outlineVariant.withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 42,
                      height: 42,
                      child: isBusy
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : FilledButton(
                              onPressed: widget.canMarkDone ? widget.onMarkDone : null,
                              style: FilledButton.styleFrom(
                                padding: EdgeInsets.zero,
                                backgroundColor: cs.secondary,
                                foregroundColor: cs.onSecondary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Icon(Icons.check_rounded, size: 20),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _desktopEventIcon(Event e) {
  final type = e.type.toLowerCase();
  if (type.contains('work') || type.contains('visit')) {
    return Icons.build_circle_outlined;
  }
  if (e.allDay) return Icons.event_rounded;
  return Icons.pending_actions_outlined;
}

// ignore: unused_element
class _DesktopHeader extends StatelessWidget {
  const _DesktopHeader({
    required this.title,
    required this.pendingCount,
    required this.completedCount,
    required this.donePct,
    required this.isLoading,
    required this.onRefresh,
    required this.showDone,
    required this.onTabChanged,
    required this.searchController,
    required this.onSearchChanged,
    required this.isEs,
    required this.cs,
    required this.t,
  });

  final String title;
  final int pendingCount;
  final int completedCount;
  final double donePct;
  final bool isLoading;
  final VoidCallback onRefresh;
  final bool showDone;
  final ValueChanged<bool> onTabChanged;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final bool isEs;
  final ColorScheme cs;
  final AppTypography t;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.18)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Title + tab toggles ─────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: t.titleLarge.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Pending badge
                    _HeaderBadge(
                      count: pendingCount,
                      label: isEs ? 'pendientes' : 'pending',
                      color: cs.primary,
                      cs: cs,
                    ),
                    const SizedBox(width: 6),
                    // Done badge
                    _HeaderBadge(
                      count: completedCount,
                      label: isEs ? 'completados' : 'done',
                      color: cs.secondary,
                      cs: cs,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Tabs + search in same row
                Row(
                  children: [
                    // Tab toggles
                    _HeaderTabToggle(
                      label: isEs ? 'Pendientes' : 'Pending',
                      count: pendingCount,
                      selected: !showDone,
                      onTap: () => onTabChanged(false),
                      cs: cs,
                    ),
                    const SizedBox(width: 6),
                    _HeaderTabToggle(
                      label: isEs ? 'Completados' : 'Completed',
                      count: completedCount,
                      selected: showDone,
                      onTap: () => onTabChanged(true),
                      cs: cs,
                    ),
                    const SizedBox(width: 16),
                    // Progress bar
                    if (pendingCount + completedCount > 0) ...[
                      SizedBox(
                        width: 120,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${(donePct * 100).round()}% ${isEs ? 'completado' : 'done'}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurfaceVariant
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 3),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: donePct,
                                minHeight: 4,
                                backgroundColor: cs.surfaceContainerHighest,
                                valueColor: AlwaysStoppedAnimation(
                                    cs.secondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // ── Search ──────────────────────────────────────────────────────
          SizedBox(
            width: 220,
            height: 36,
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              style: TextStyle(fontSize: 13, color: cs.onSurface),
              decoration: InputDecoration(
                hintText: isEs ? 'Buscar evento…' : 'Search event…',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.45),
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 16,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.45),
                ),
                isDense: true,
                filled: true,
                fillColor:
                    cs.surfaceContainerHighest.withValues(alpha: 0.4),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: cs.primary.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Refresh
          SizedBox(
            width: 34,
            height: 34,
            child: IconButton(
              icon: Icon(
                Icons.refresh_rounded,
                size: 17,
                color: cs.onSurfaceVariant,
              ),
              tooltip: isEs ? 'Actualizar' : 'Refresh',
              onPressed: isLoading ? null : onRefresh,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({
    required this.count,
    required this.label,
    required this.color,
    required this.cs,
  });
  final int count;
  final String label;
  final Color color;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            '$count $label',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderTabToggle extends StatelessWidget {
  const _HeaderTabToggle({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    required this.cs,
  });
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: selected ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? cs.primaryContainer.withValues(alpha: 0.7)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? cs.primary.withValues(alpha: 0.45)
                : cs.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          '$label  $count',
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected
                ? cs.onPrimaryContainer
                : cs.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

// ── Desktop event list ─────────────────────────────────────────────────────────

// ignore: unused_element
class _DesktopEventList extends StatelessWidget {
  const _DesktopEventList({
    required this.events,
    required this.viewModel,
    required this.selectedId,
    required this.isDoneList,
    required this.onSelect,
    required this.emptyMessage,
    required this.onRefresh,
    required this.isEs,
  });

  final List<Event> events;
  final GroupUndoneEventsViewModel viewModel;
  final String? selectedId;
  final bool isDoneList;
  final ValueChanged<Event?> onSelect;
  final String emptyMessage;
  final Future<void> Function() onRefresh;
  final bool isEs;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDoneList
                    ? Icons.task_alt_outlined
                    : Icons.checklist_rtl_rounded,
                size: 28,
                color: cs.onSurfaceVariant.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              emptyMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: events.length,
        itemBuilder: (context, i) {
          final event = events[i];
          final isSelected = event.id == selectedId;
          final owner = viewModel.ownerInfoOf(event.ownerId);
          final canManage = viewModel.canManageEvent(event);
          return _DesktopEventRow(
            event: event,
            viewModel: viewModel,
            owner: owner,
            isSelected: isSelected,
            isDone: isDoneList,
            canMarkDone: !isDoneList && canManage,
            onTap: () => onSelect(isSelected ? null : event),
            onMarkDone: canManage && !isDoneList
                ? () => viewModel.markEventAsDone(event.id)
                : null,
            isEs: isEs,
          );
        },
      ),
    );
  }
}

// ── Desktop event row — 3-column grid ─────────────────────────────────────────

class _DesktopEventRow extends StatefulWidget {
  const _DesktopEventRow({
    required this.event,
    required this.viewModel,
    required this.owner,
    required this.isSelected,
    required this.isDone,
    required this.canMarkDone,
    required this.onTap,
    required this.isEs,
    this.onMarkDone,
  });

  final Event event;
  final GroupUndoneEventsViewModel viewModel;
  final EventOwnerInfo? owner;
  final bool isSelected;
  final bool isDone;
  final bool canMarkDone;
  final VoidCallback onTap;
  final VoidCallback? onMarkDone;
  final bool isEs;

  @override
  State<_DesktopEventRow> createState() => _DesktopEventRowState();
}

class _DesktopEventRowState extends State<_DesktopEventRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ml = MaterialLocalizations.of(context);
    final e = widget.event;
    final isBusy = widget.viewModel.isProcessing(e.id);

    final start = e.startDate.toLocal();
    final end = e.endDate.toLocal();
    final locale = Localizations.localeOf(context).toString();
    final dateFmt = DateFormat.MMMEd(locale).format(start);
    final timeStr =
        '${ml.formatTimeOfDay(TimeOfDay.fromDateTime(start), alwaysUse24HourFormat: true)}'
        ' – '
        '${ml.formatTimeOfDay(TimeOfDay.fromDateTime(end), alwaysUse24HourFormat: true)}';
    final durMin = end.difference(start).inMinutes;
    final durStr = durMin <= 0
        ? ''
        : durMin < 60
            ? '${durMin}m'
            : durMin % 60 == 0
                ? '${durMin ~/ 60}h'
                : '${durMin ~/ 60}h ${durMin % 60}m';

    final accentColor = widget.isDone ? cs.secondary : cs.primary;
    final bgColor = widget.isSelected
        ? cs.primaryContainer.withValues(alpha: 0.12)
        : _hovered
            ? cs.surfaceContainerHighest.withValues(alpha: 0.22)
            : Colors.transparent;

    final showActions = (_hovered || widget.isSelected) && widget.canMarkDone;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(11),
            border: widget.isSelected
                ? Border.all(
                    color: cs.primary.withValues(alpha: 0.28), width: 1)
                : _hovered
                    ? Border.all(
                        color:
                            cs.outlineVariant.withValues(alpha: 0.3),
                        width: 1)
                    : null,
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left accent stripe
                Container(
                  width: 3,
                  margin:
                      const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: (widget.isSelected || _hovered)
                        ? accentColor.withValues(
                            alpha: widget.isDone ? 0.4 : 0.7)
                        : Colors.transparent,
                    borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(3)),
                  ),
                ),
                const SizedBox(width: 8),

                // ── Column 1: Icon + Title + subtitle ──────────────────
                Expanded(
                  flex: 45,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Icon box
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(
                                alpha: widget.isDone ? 0.07 : 0.1),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(
                            widget.isDone
                                ? Icons.task_alt_rounded
                                : _eventIcon(e),
                            size: 16,
                            color: accentColor.withValues(
                                alpha: widget.isDone ? 0.5 : 0.85),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                e.title.isEmpty
                                    ? (widget.isEs
                                        ? 'Sin título'
                                        : 'Untitled')
                                    : e.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: widget.isDone
                                      ? cs.onSurface
                                          .withValues(alpha: 0.4)
                                      : cs.onSurface,
                                  decoration: widget.isDone
                                      ? TextDecoration.lineThrough
                                      : null,
                                  decorationColor: cs.onSurface
                                      .withValues(alpha: 0.35),
                                  height: 1.2,
                                ),
                              ),
                              if ((e.description?.trim().isNotEmpty ??
                                  false))
                                Padding(
                                  padding: const EdgeInsets.only(
                                      top: 2),
                                  child: Text(
                                    e.description!.trim(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: cs.onSurfaceVariant
                                          .withValues(alpha: 0.55),
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Column 2: Date + time + duration ───────────────────
                Expanded(
                  flex: 35,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 11,
                              color: cs.onSurfaceVariant
                                  .withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                e.allDay
                                    ? dateFmt
                                    : dateFmt,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface
                                      .withValues(alpha: 0.75),
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (!e.allDay) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule_outlined,
                                size: 11,
                                color: cs.onSurfaceVariant
                                    .withValues(alpha: 0.4),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '$timeStr${durStr.isNotEmpty ? '  ·  $durStr' : ''}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: cs.onSurfaceVariant
                                        .withValues(alpha: 0.6),
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // ── Column 3: User + action ─────────────────────────────
                SizedBox(
                  width: 140,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Owner chip
                        if (widget.owner != null)
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest
                                    .withValues(alpha: 0.55),
                                borderRadius:
                                    BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 8,
                                    backgroundColor:
                                        accentColor.withValues(
                                            alpha: 0.15),
                                    child: Text(
                                      widget.owner!.displayName
                                          .isNotEmpty
                                          ? widget.owner!.displayName[0]
                                              .toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: accentColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      widget.owner!.displayName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: cs.onSurfaceVariant
                                            .withValues(alpha: 0.75),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(width: 6),

                        // Mark done button
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 130),
                          opacity: showActions ? 1.0 : 0.0,
                          child: isBusy
                              ? const SizedBox(
                                  width: 26,
                                  height: 26,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : Tooltip(
                                  message: widget.isEs
                                      ? 'Marcar completado'
                                      : 'Mark as done',
                                  child: GestureDetector(
                                    onTap: widget.onMarkDone,
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                          milliseconds: 130),
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: cs.secondary
                                            .withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: cs.secondary
                                              .withValues(alpha: 0.4),
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.check_rounded,
                                        size: 14,
                                        color: cs.secondary,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _eventIcon(Event e) {
    final type = e.type.toLowerCase();
    if (type.contains('work') || type.contains('visit')) {
      return Icons.build_circle_outlined;
    }
    if (e.allDay) return Icons.event_rounded;
    return Icons.pending_actions_outlined;
  }
}

// ── Desktop sidebar ────────────────────────────────────────────────────────────

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.viewModel,
    required this.selectedEvent,
    required this.showDone,
    required this.participants,
    required this.totalPending,
    required this.totalDone,
    required this.donePct,
    required this.onCloseDetail,
    required this.onMarkedDone,
    required this.isEs,
    required this.cs,
    required this.t,
    required this.loc,
  });

  final GroupUndoneEventsViewModel viewModel;
  final Event? selectedEvent;
  final bool showDone;
  final List<EventOwnerInfo> participants;
  final int totalPending;
  final int totalDone;
  final double donePct;
  final VoidCallback onCloseDetail;
  final VoidCallback onMarkedDone;
  final bool isEs;
  final ColorScheme cs;
  final AppTypography t;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: cs.surfaceContainerLowest.withValues(alpha: 0.4),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Stats section ─────────────────────────────────────────
            _SidebarSection(
              title: isEs ? 'Resumen' : 'Summary',
              icon: Icons.bar_chart_rounded,
              cs: cs,
              t: t,
              child: Column(
                children: [
                  _StatRow(
                    icon: Icons.pending_actions_outlined,
                    label: isEs ? 'Pendientes' : 'Pending',
                    value: '$totalPending',
                    color: cs.primary,
                    cs: cs,
                  ),
                  const SizedBox(height: 8),
                  _StatRow(
                    icon: Icons.task_alt_rounded,
                    label: isEs ? 'Completados' : 'Completed',
                    value: '$totalDone',
                    color: cs.secondary,
                    cs: cs,
                  ),
                  if (totalPending + totalDone > 0) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEs ? 'Progreso' : 'Progress',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant
                                .withValues(alpha: 0.6),
                          ),
                        ),
                        Text(
                          '${(donePct * 100).round()}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: donePct >= 1.0
                                ? cs.secondary
                                : cs.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: donePct,
                        minHeight: 6,
                        backgroundColor:
                            cs.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation(
                          donePct >= 1.0 ? cs.secondary : cs.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Employee filter ───────────────────────────────────────
            if (participants.isNotEmpty) ...[
              _SidebarSection(
                title:
                    isEs ? 'Filtrar empleado' : 'Filter by employee',
                icon: Icons.people_alt_outlined,
                cs: cs,
                t: t,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _EmployeePill(
                      label: isEs ? 'Todos' : 'All',
                      selected: viewModel.filterUserId == null,
                      color: cs.primary,
                      onTap: () => viewModel.setFilterUser(null),
                      cs: cs,
                    ),
                    ...participants.map((p) => _EmployeePill(
                          label: p.displayName,
                          selected: viewModel.filterUserId == p.id,
                          color: cs.primary,
                          onTap: () => viewModel.setFilterUser(
                              viewModel.filterUserId == p.id
                                  ? null
                                  : p.id),
                          cs: cs,
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── Próximo evento (next event card) ──────────────────────
            if (!showDone && viewModel.pendingEvents.isNotEmpty) ...[
              _SidebarSection(
                title:
                    isEs ? 'Próximo evento' : 'Next event',
                icon: Icons.upcoming_rounded,
                cs: cs,
                t: t,
                child: _NextEventCard(
                  event: viewModel.pendingEvents.first,
                  owner: viewModel
                      .ownerInfoOf(viewModel.pendingEvents.first.ownerId),
                  isEs: isEs,
                  cs: cs,
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── Event detail (when selected) ──────────────────────────
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: selectedEvent != null
                  ? _SidebarEventDetail(
                      event: selectedEvent!,
                      viewModel: viewModel,
                      onClose: onCloseDetail,
                      allowMarkComplete:
                          !showDone &&
                          viewModel.canManageEvent(selectedEvent!),
                      onMarkedDone: onMarkedDone,
                      isEs: isEs,
                      cs: cs,
                      t: t,
                      loc: loc,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sidebar components ─────────────────────────────────────────────────────────

class _SidebarSection extends StatelessWidget {
  const _SidebarSection({
    required this.title,
    required this.icon,
    required this.child,
    required this.cs,
    required this.t,
  });
  final String title;
  final IconData icon;
  final Widget child;
  final ColorScheme cs;
  final AppTypography t;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: cs.outlineVariant.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding:
                const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                Icon(icon,
                    size: 13,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.55)),
                const SizedBox(width: 6),
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color:
                        cs.onSurfaceVariant.withValues(alpha: 0.55),
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          Divider(
              height: 1,
              thickness: 1,
              color: cs.outlineVariant.withValues(alpha: 0.15)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.cs,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: color,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _EmployeePill extends StatelessWidget {
  const _EmployeePill({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
    required this.cs,
  });
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        padding:
            const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.12)
              : cs.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.45)
                : cs.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              Icon(Icons.check_rounded,
                  size: 11, color: color),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? color
                    : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextEventCard extends StatelessWidget {
  const _NextEventCard({
    required this.event,
    required this.owner,
    required this.isEs,
    required this.cs,
  });
  final Event event;
  final EventOwnerInfo? owner;
  final bool isEs;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final ml = MaterialLocalizations.of(context);
    final start = event.startDate.toLocal();
    final end = event.endDate.toLocal();
    final timeStr =
        ml.formatTimeOfDay(TimeOfDay.fromDateTime(start),
            alwaysUse24HourFormat: true);
    final durMin = end.difference(start).inMinutes;
    final durStr = durMin <= 0
        ? ''
        : durMin < 60
            ? '${durMin}m'
            : '${durMin ~/ 60}h${durMin % 60 > 0 ? ' ${durMin % 60}m' : ''}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primaryContainer.withValues(alpha: 0.4),
            cs.primaryContainer.withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(11),
        border:
            Border.all(color: cs.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                Icon(Icons.build_circle_outlined, size: 18, color: cs.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title.isEmpty
                      ? (isEs ? 'Sin título' : 'Untitled')
                      : event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$timeStr${durStr.isNotEmpty ? '  ·  $durStr' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.primary.withValues(alpha: 0.85),
                  ),
                ),
                if (owner != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    owner!.displayName,
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          cs.onSurfaceVariant.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sidebar event detail ───────────────────────────────────────────────────────

class _SidebarEventDetail extends StatelessWidget {
  const _SidebarEventDetail({
    required this.event,
    required this.viewModel,
    required this.onClose,
    required this.allowMarkComplete,
    required this.onMarkedDone,
    required this.isEs,
    required this.cs,
    required this.t,
    required this.loc,
  });

  final Event event;
  final GroupUndoneEventsViewModel viewModel;
  final VoidCallback onClose;
  final bool allowMarkComplete;
  final VoidCallback onMarkedDone;
  final bool isEs;
  final ColorScheme cs;
  final AppTypography t;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GroupUndoneEventsViewModel>();
    final ml = MaterialLocalizations.of(context);
    final isBusy = vm.isProcessing(event.id);
    final alreadyDone = event.isDone == true;
    final owner = vm.ownerInfoOf(event.ownerId);
    final locale = Localizations.localeOf(context).toString();

    final start = event.startDate.toLocal();
    final end = event.endDate.toLocal();
    final dateStr = DateFormat.MMMMEEEEd(locale).format(start);
    final timeStr = event.allDay
        ? (isEs ? 'Todo el día' : 'All day')
        : '${ml.formatTimeOfDay(TimeOfDay.fromDateTime(start), alwaysUse24HourFormat: true)} – '
            '${ml.formatTimeOfDay(TimeOfDay.fromDateTime(end), alwaysUse24HourFormat: true)}';
    final description = (event.description?.trim().isNotEmpty ?? false)
        ? event.description!.trim()
        : null;

    return _SidebarSection(
      title: isEs ? 'Detalle' : 'Detail',
      icon: Icons.info_outline_rounded,
      cs: cs,
      t: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Close + title row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  event.title.isEmpty
                      ? (isEs ? 'Sin título' : 'Untitled')
                      : event.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 26,
                height: 26,
                child: IconButton(
                  icon: Icon(Icons.close_rounded,
                      size: 14,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                  onPressed: onClose,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Meta
          _DetailMeta(
              icon: Icons.calendar_today_outlined,
              text: dateStr,
              cs: cs),
          const SizedBox(height: 6),
          _DetailMeta(
              icon: Icons.schedule_outlined, text: timeStr, cs: cs),
          if (owner != null) ...[
            const SizedBox(height: 6),
            _DetailMeta(
                icon: Icons.person_outline_rounded,
                text:
                    '${owner.displayName}${owner.username != null ? '  ·  ${owner.username}' : ''}',
                cs: cs),
          ],
          if (description != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    cs.surfaceContainerHighest.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withValues(alpha: 0.7),
                  height: 1.5,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),

          // Actions
          if (allowMarkComplete)
            SizedBox(
              height: 36,
              child: FilledButton.icon(
                icon:
                    const Icon(Icons.check_circle_outline, size: 15),
                label: Text(
                  loc.pendingEventsMarkDone,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700),
                ),
                onPressed: isBusy || alreadyDone
                    ? null
                    : () async {
                        await vm.markEventAsDone(event.id);
                        if (context.mounted) onMarkedDone();
                      },
              ),
            ),
          const SizedBox(height: 6),
          SizedBox(
            height: 34,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.open_in_new_rounded, size: 13),
              label: Text(
                loc.viewDetails,
                style: const TextStyle(fontSize: 12),
              ),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => EventDetailScreen(event: event),
                ));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailMeta extends StatelessWidget {
  const _DetailMeta({
    required this.icon,
    required this.text,
    required this.cs,
  });
  final IconData icon;
  final String text;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon,
            size: 13, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.5,
              color: cs.onSurface.withValues(alpha: 0.75),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
