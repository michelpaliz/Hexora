// c-frontend/c-group-calendar-section/screens/calendar/screen/main_calendar_view.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/b-backend/group_mng_flow/event/domain/event_domain.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/widgets/right_panel/services_section/right_panel_insights_inline.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/undone_events/group_undone_events/group_undone_events_screen.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/calendar/presentation/coordinator/calendar_screen_coordinator.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/calendar/screen/widgets/calendar_tabs.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/calendar/screen/widgets/calendar_topbar.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/calendar/screen/widgets/refresh_button.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/calendar/utils/add_event_cta.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/calendar/utils/group_permissions_helper.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/calendar/utils/presence_status_strip.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/actions/add_screen/screen/add_event_screen.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/actions/edit_screen/screen/edit_event_screen.dart';
import 'package:hexora/c-frontend/ui-app/g-agenda-section/agenda_screen.dart';
import 'package:hexora/c-frontend/utils/roles/group_role/group_role.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class CalendarDashboardActions {
  final Future<void> Function() onAddEvent;
  final VoidCallback onToggleLeftPanel;
  final ValueNotifier<bool> leftPanelCollapsed;
  final bool canAddEvents;

  const CalendarDashboardActions({
    required this.onAddEvent,
    required this.onToggleLeftPanel,
    required this.leftPanelCollapsed,
    required this.canAddEvents,
  });
}

class MainCalendarView extends StatefulWidget {
  final Group? group;
  final bool embedded;
  final ValueChanged<CalendarDashboardActions?>? onActionsReady;

  const MainCalendarView({
    super.key,
    this.group,
    this.embedded = false,
    this.onActionsReady,
  });

  @override
  State<MainCalendarView> createState() => _MainCalendarViewState();
}

enum _SidePanelView { upcoming, completed, insights, addEvent, editEvent }

class _MainCalendarViewState extends State<MainCalendarView> {
  late final CalendarScreenCoordinator _c;
  bool _isBootstrapped = false;
  bool _weatherIconsEnabled = true;
  String? _selectedUserFilter;
  _SidePanelView _panelView = _SidePanelView.upcoming;
  bool _rightCollapsed = false;
  bool _leftCollapsed = false;
  final ValueNotifier<bool> _leftCollapsedNotifier = ValueNotifier(false);
  bool _canAddEvents = false;
  Event? _editingEvent;

  @override
  void initState() {
    super.initState();
    _c = CalendarScreenCoordinator(context: context);
    _emitActions();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    if (_isBootstrapped) return;
    try {
      _selectedUserFilter = null;
      await _c.initSockets();
      await _c.loadData(initialGroup: widget.group);
      _c.calendarUI?.setShowWeatherIcons(_weatherIconsEnabled);
      _c.calendarUI?.setEventFilter(userId: _selectedUserFilter);
      // If your coordinator exposes current view, you can map it to initialIndex here.
      _isBootstrapped = true;
    } finally {
      if (mounted) setState(() {});
    }
  }

  @override
  void didUpdateWidget(MainCalendarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.group?.id != widget.group?.id) {
      _isBootstrapped = false;
      _bootstrap();
    }
  }

  void _toggleWeatherIcons(bool value) {
    _weatherIconsEnabled = value;
    _c.calendarUI?.setShowWeatherIcons(value);
    setState(() {});
  }

  Future<void> _openAddEvent(Group group) async {
    bool? added;

    if (widget.embedded && kIsWeb) {
      setState(() {
        _panelView = _SidePanelView.addEvent;
        _rightCollapsed = false;
      });
      return;
    }

    if (kIsWeb) {
      // On web, keep the 3-column layout in place by showing a dialog instead of full navigation.
      added = await showDialog<bool>(
        context: context,
        builder: (dialogCtx) {
          final media = MediaQuery.of(dialogCtx).size;
          return Dialog(
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 980,
                maxHeight: media.height * 0.9,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: media.width * 0.8,
                  height: media.height * 0.86,
                  child: AddEventScreen(group: group),
                ),
              ),
            ),
          );
        },
      );
    } else {
      added = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => AddEventScreen(group: group),
        ),
      );
    }

    if (added == true) {
      await _c.loadData(initialGroup: group);
      if (mounted) setState(() {});
    }
  }

  void _onUserFilterChanged(String? userId) {
    setState(() => _selectedUserFilter = userId);
    _c.calendarUI?.setEventFilter(userId: userId);
  }

  void _setPanelView(_SidePanelView view) {
    if (_panelView == view) return;
    setState(() => _panelView = view);
  }

  void _toggleRightPanel() {
    setState(() => _rightCollapsed = !_rightCollapsed);
  }

  void _toggleLeftPanel() {
    setState(() => _leftCollapsed = !_leftCollapsed);
    _leftCollapsedNotifier.value = _leftCollapsed;
  }

  void _openEditEventInline(Event event) {
    setState(() {
      _editingEvent = event;
      _panelView = _SidePanelView.editEvent;
      _rightCollapsed = false;
    });
  }

  void _emitActions() {
    widget.onActionsReady?.call(
      CalendarDashboardActions(
        onAddEvent: _openAddEventFromMenu,
        onToggleLeftPanel: _toggleLeftPanel,
        leftPanelCollapsed: _leftCollapsedNotifier,
        canAddEvents: _canAddEvents,
      ),
    );
  }

  Future<void> _openAddEventFromMenu() async {
    final groupDomain = context.read<GroupDomain>();
    final targetGroup = widget.group ?? groupDomain.currentGroup;
    if (targetGroup == null) return;
    await _openAddEvent(targetGroup);
  }

  void _syncInlineEditHandler() {
    _c.setInlineEditHandler(
      widget.embedded && kIsWeb ? _openEditEventInline : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupDomain = context.watch<GroupDomain>();
    final userDomain = context.watch<UserDomain>();
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);
    final loc = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 1000;

    return ValueListenableBuilder<bool>(
      valueListenable: _c.loading,
      builder: (_, isLoading, __) {
        if (isLoading) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final currentUser = userDomain.user;
        final currentGroup = groupDomain.currentGroup;

        // No group/user case
        if (currentUser == null || currentGroup == null) {
          return CalendarTabsTheme(
            child: Scaffold(
              appBar: CalendarTopBar(
                title: loc.calendarTitle, // localized
                showTabs: false,
              ),
              body: SafeArea(
                child: Center(
                  child: Text(
                    loc.noGroupAvailable, // localized
                    style: typo.bodyMedium.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
              ),
            ),
          );
        }

        final canAddEvents =
            GroupPermissionHelper.canAddEvents(currentUser, currentGroup);
        if (canAddEvents != _canAddEvents) {
          _canAddEvents = canAddEvents;
          WidgetsBinding.instance.addPostFrameCallback((_) => _emitActions());
        }
        _syncInlineEditHandler();
        final currentRole =
            GroupRole.fromWire(currentGroup.userRoles[currentUser.id]);

        Widget actionButtons({required bool vertical}) {
          final buttons = <Widget>[
            RefreshCta(
              isLoading: _c.loading.value,
              onPressed: () async {
                await _c.loadData(initialGroup: currentGroup);
                if (mounted) setState(() {});
              },
            ),
            if (canAddEvents)
              AddEventCta(
                onPressed: () => _openAddEvent(currentGroup),
              ),
          ];

          if (vertical) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < buttons.length; i++) ...[
                  SizedBox(
                    width: double.infinity,
                    child: buttons[i],
                  ),
                  if (i != buttons.length - 1) const SizedBox(height: 12),
                ],
              ],
            );
          }

          return IntrinsicHeight(
            child: Row(
              children: [
                Expanded(child: buttons.first),
                if (buttons.length > 1) ...[
                  const SizedBox(width: 10),
                  Expanded(child: buttons[1]),
                ],
              ],
            ),
          );
        }

        Widget calendarContent({required bool showActions}) {
          final calendarUI = _c.calendarUI;
          final midTabs = [
            Tab(text: loc.tabWeek),
            Tab(text: loc.tabDay),
            Tab(text: loc.tabAgenda),
          ];
          return DefaultTabController(
            initialIndex: 0,
            length: midTabs.length,
            child: Column(
              children: [
                PresenceStatusStrip(
                  group: currentGroup,
                  controller: _c,
                  selectedUserId: _selectedUserFilter,
                  onUserSelected: _onUserFilterChanged,
                ),
                const SizedBox(height: 10),
                TabBar(
                  tabs: midTabs,
                  isScrollable: false,
                  labelStyle:
                      typo.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                  unselectedLabelStyle: typo.bodySmall,
                  labelColor: cs.primary,
                  unselectedLabelColor: cs.onSurfaceVariant,
                  indicator: const UnderlineTabIndicator(
                    borderSide: BorderSide(width: 3),
                  ),
                  indicatorColor: cs.primary,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: TabBarView(
                    children: [
                      calendarUI?.buildCalendar(
                            context,
                            forcedViewMode: 'week',
                          ) ??
                          const SizedBox(),
                      calendarUI?.buildCalendar(
                            context,
                            forcedViewMode: 'day',
                          ) ??
                          const SizedBox(),
                      calendarUI?.buildCalendar(
                            context,
                            forcedViewMode: 'agenda',
                          ) ??
                          const SizedBox(),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (showActions) actionButtons(vertical: false),
              ],
            ),
          );
        }

        Widget compactCalendarContent() {
          final calendarUI = _c.calendarUI;
          return Column(
            children: [
              PresenceStatusStrip(
                group: currentGroup,
                controller: _c,
                selectedUserId: _selectedUserFilter,
                onUserSelected: _onUserFilterChanged,
                showAllOption: false,
              ),
              const SizedBox(height: 10),
              Expanded(
                child: TabBarView(
                  children: [
                    calendarUI?.buildCalendar(
                          context,
                          forcedViewMode: 'day',
                        ) ??
                        const SizedBox(),
                    calendarUI?.buildCalendar(
                          context,
                          forcedViewMode: 'week',
                        ) ??
                        const SizedBox(),
                    calendarUI?.buildCalendar(
                          context,
                          forcedViewMode: 'month',
                        ) ??
                        const SizedBox(),
                    calendarUI?.buildCalendar(
                          context,
                          forcedViewMode: 'agenda',
                        ) ??
                        const SizedBox(),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              actionButtons(vertical: false),
            ],
          );
        }

        Widget calendarSidebar() {
          final calendarUI = _c.calendarUI;
          if (_leftCollapsed) {
            return const Card(
              elevation: 2,
              clipBehavior: Clip.antiAlias,
              child: SizedBox.shrink(),
            );
          }
          return Card(
            elevation: 2,
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: calendarUI?.buildCalendar(
                            context,
                            forcedViewMode: 'month',
                          ) ??
                          Center(
                            child: Text(
                              loc.noGroupAvailable,
                              style: typo.bodyMedium
                                  .copyWith(color: cs.onSurfaceVariant),
                            ),
                          ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        Widget eventsSidebar() {
          final selectedColor = cs.primary;
          final selectedBg = cs.primary.withOpacity(0.12);
          final iconRail = Container(
            width: 56,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withOpacity(0.35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 6),
                IconButton(
                  tooltip: loc.sectionUpcoming,
                  icon: Icon(
                    Icons.upcoming_rounded,
                    color: _panelView == _SidePanelView.upcoming
                        ? selectedColor
                        : cs.onSurfaceVariant,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: _panelView == _SidePanelView.upcoming
                        ? selectedBg
                        : Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => _setPanelView(_SidePanelView.upcoming),
                ),
                IconButton(
                  tooltip: loc.completedEventsSectionTitle,
                  icon: Icon(
                    Icons.task_alt_rounded,
                    color: _panelView == _SidePanelView.completed
                        ? selectedColor
                        : cs.onSurfaceVariant,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: _panelView == _SidePanelView.completed
                        ? selectedBg
                        : Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => _setPanelView(_SidePanelView.completed),
                ),
                IconButton(
                  tooltip: loc.insightsTitle,
                  icon: Icon(
                    Icons.insights_rounded,
                    color: _panelView == _SidePanelView.insights
                        ? selectedColor
                        : cs.onSurfaceVariant,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: _panelView == _SidePanelView.insights
                        ? selectedBg
                        : Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => _setPanelView(_SidePanelView.insights),
                ),
                if (canAddEvents)
                  IconButton(
                    tooltip: loc.addEvent,
                    icon: Icon(
                      Icons.add_circle_outline,
                      color: _panelView == _SidePanelView.addEvent
                          ? selectedColor
                          : cs.onSurfaceVariant,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: _panelView == _SidePanelView.addEvent
                          ? selectedBg
                          : Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => _setPanelView(_SidePanelView.addEvent),
                  ),
                const SizedBox(height: 8),
                Divider(
                  height: 1,
                  color: cs.outlineVariant.withOpacity(0.4),
                ),
                IconButton(
                  tooltip: _rightCollapsed ? 'Expand' : 'Collapse',
                  icon: Icon(
                    _rightCollapsed
                        ? Icons.chevron_left_rounded
                        : Icons.chevron_right_rounded,
                  ),
                  onPressed: _toggleRightPanel,
                ),
              ],
            ),
          );

          return SizedBox(
            width: _rightCollapsed ? 56 : 420,
            child: Row(
              children: [
                iconRail,
                if (!_rightCollapsed) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: switch (_panelView) {
                        _SidePanelView.upcoming => AgendaScreen(
                            groupId: currentGroup.id,
                            showBottomNav: false,
                          ),
                        _SidePanelView.completed => GroupUndoneEventsScreen(
                            group: currentGroup,
                            user: currentUser,
                            role: currentRole,
                            embedded: true,
                          ),
                        _SidePanelView.insights =>
                          InsightsInlinePanel(group: currentGroup),
                        _SidePanelView.addEvent => Navigator(
                            onPopPage: (route, result) {
                              if (!route.didPop(result)) return false;
                              if (mounted) {
                                setState(
                                  () => _panelView = _SidePanelView.upcoming,
                                );
                              }
                              return true;
                            },
                            pages: [
                              MaterialPage(
                                child: AddEventScreen(group: currentGroup),
                              ),
                            ],
                          ),
                        _SidePanelView.editEvent => _editingEvent == null
                            ? Center(
                                child: Text(
                                  loc.noEventsFoundForDate,
                                  style: typo.bodySmall.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              )
                            : Navigator(
                                onPopPage: (route, result) {
                                  if (!route.didPop(result)) return false;
                                  if (mounted) {
                                    setState(
                                      () =>
                                          _panelView = _SidePanelView.upcoming,
                                    );
                                  }
                                  return true;
                                },
                                pages: [
                                  MaterialPage(
                                    child: Provider<EventDomain>.value(
                                      value: context.read<EventDomain>(),
                                      child: EditEventScreen(
                                        event: _editingEvent!,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      },
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        final showCalendarTopBar = !(widget.embedded && kIsWeb);
        final scaffold = Scaffold(
          appBar: showCalendarTopBar
              ? CalendarTopBar(
                  title: currentGroup.name,
                  showTabs: !isWide,
                  tabs: isWide
                      ? const []
                      : CalendarTabs.build(context, large: true),
                  onTabChanged: isWide
                      ? null
                      : (index) => CalendarTabs.handleTabChanged(_c, index),
                  actions: isWide
                      ? [
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: canAddEvents
                                ? Container(
                                    decoration: BoxDecoration(
                                      color: cs.surfaceContainerHighest
                                          .withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color:
                                            cs.outlineVariant.withOpacity(0.6),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon:
                                              const Icon(Icons.refresh_rounded),
                                          tooltip: loc.refreshButton,
                                          onPressed: _c.loading.value
                                              ? null
                                              : () async {
                                                  await _c.loadData(
                                                      initialGroup:
                                                          currentGroup);
                                                  if (mounted) setState(() {});
                                                },
                                        ),
                                        Container(
                                          width: 1,
                                          height: 24,
                                          color: cs.outlineVariant
                                              .withOpacity(0.6),
                                        ),
                                        TextButton.icon(
                                          onPressed: () =>
                                              _openAddEvent(currentGroup),
                                          icon: const Icon(Icons.add_rounded,
                                              size: 18),
                                          label: Text(
                                            loc.addEvent,
                                            style: typo.bodySmall.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          style: TextButton.styleFrom(
                                            foregroundColor: cs.onPrimary,
                                            backgroundColor: cs.primary,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 10,
                                            ),
                                            shape: const StadiumBorder(),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                      ],
                                    ),
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.refresh_rounded),
                                    tooltip: loc.refreshButton,
                                    onPressed: _c.loading.value
                                        ? null
                                        : () async {
                                            await _c.loadData(
                                                initialGroup: currentGroup);
                                            if (mounted) setState(() {});
                                          },
                                  ),
                          ),
                        ]
                      : null,
                  onToggleLeftPanel: isWide ? _toggleLeftPanel : null,
                  leftPanelCollapsed: _leftCollapsed,
                  showWeatherToggle: true,
                  weatherIconsEnabled: _weatherIconsEnabled,
                  onWeatherToggle: _toggleWeatherIcons,
                )
              : null,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: isWide
                ? Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1500),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: _leftCollapsed ? 56 : 420,
                              child: Align(
                                alignment: Alignment.topLeft,
                                child: calendarSidebar(),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: calendarContent(
                                showActions: false,
                              ),
                            ),
                            const SizedBox(width: 16),
                            eventsSidebar(),
                          ],
                        ),
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                    child: compactCalendarContent(),
                  ),
          ),
        );

        return CalendarTabsTheme(
          child: isWide
              ? scaffold
              : DefaultTabController(
                  length: 4,
                  initialIndex: 1,
                  child: scaffold,
                ),
        );
      },
    );
  }

  @override
  void dispose() {
    widget.onActionsReady?.call(null);
    _leftCollapsedNotifier.dispose();
    _c.dispose();
    super.dispose();
  }
}
