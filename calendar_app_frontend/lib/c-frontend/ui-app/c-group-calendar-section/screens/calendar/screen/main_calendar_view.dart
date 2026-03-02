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
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/calendar/screen/widgets/calendar_side_menu.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/calendar/screen/widgets/calendar_tabs.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/calendar/screen/widgets/calendar_topbar.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/calendar/screen/widgets/refresh_button.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/calendar/utils/add_event_cta.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/calendar/utils/group_permissions_helper.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/calendar/utils/presence_status_strip.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/actions/add_screen/screen/add_event_screen.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/actions/edit_screen/screen/edit_event_screen.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/event_screen/event_detail/event_detail_screen.dart';
import 'package:hexora/c-frontend/ui-app/g-agenda-section/agenda_screen.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/folder_panel.dart';
import 'package:hexora/c-frontend/utils/image/user_image/avatar_utils.dart';
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

enum _SidePanelView {
  upcoming,
  completed,
  insights,
  addEvent,
  viewEvent,
  editEvent,
  miniCalendar
}

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
  Event? _viewingEvent;
  bool _viewsExpanded = true;
  bool _eventsExpanded = true;
  bool _insightsExpanded = false;
  String _selectedSideMenu = 'week';
  DateTime? _pendingAddEventStart;
  DateTime? _pendingAddEventEnd;

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

    final isWideNow = MediaQuery.of(context).size.width >= 1000;
    if (isWideNow) {
      final now = DateTime.now();
      setState(() {
        _panelView = _SidePanelView.addEvent;
        _pendingAddEventStart = now;
        _pendingAddEventEnd = now.add(const Duration(hours: 1));
      });
      return;
    }

    if (widget.embedded && kIsWeb) {
      setState(() {
        _panelView = _SidePanelView.addEvent;
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
      await _refreshCalendarOnly();
    }
  }

  Future<void> _refreshCalendarOnly() async {
    if (!mounted) return;
    await context.read<EventDomain>().manualRefresh(context, silent: true);
  }

  void _openAddEventForSlot(DateTime slot) {
    final start = DateTime(
      slot.year,
      slot.month,
      slot.day,
      slot.hour,
      slot.minute,
    );
    setState(() {
      _panelView = _SidePanelView.addEvent;
      _pendingAddEventStart = start;
      _pendingAddEventEnd = start.add(const Duration(hours: 1));
    });
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

  void _onSideMenuChanged(String menu) {
    setState(() => _selectedSideMenu = menu);
    // Handle menu changes - switch views or navigate
    switch (menu) {
      case 'week':
      case 'day':
      case 'agenda':
        // These view modes are handled by the main calendar
        break;
      case 'month':
        // Month is still a calendar view in the main area.
        break;
      case 'upcoming':
        _setPanelView(_SidePanelView.upcoming);
        break;
      case 'completed':
        _setPanelView(_SidePanelView.completed);
        break;
      case 'insights':
        _setPanelView(_SidePanelView.insights);
        break;
      case 'mini_calendar':
        _setPanelView(_SidePanelView.miniCalendar);
        break;
    }
  }

  void _openViewEventInline(Event event) {
    setState(() {
      _viewingEvent = event;
      _panelView = _SidePanelView.viewEvent;
    });
  }

  void _openEditEventInline(Event event) {
    setState(() {
      _editingEvent = event;
      _panelView = _SidePanelView.editEvent;
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
      widget.embedded && kIsWeb ? _openViewEventInline : null,
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

        List<Widget> calendarHeaderActions() {
          final connectedUsers = _c.buildPresenceFor(currentGroup);
          final actions = <Widget>[
            Tooltip(
              message: 'All',
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => _onUserFilterChanged(null),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.secondaryContainer.withValues(alpha: 0.9),
                    border: Border.all(
                      color: _selectedUserFilter == null
                          ? cs.secondary
                          : cs.outlineVariant.withValues(alpha: 0.6),
                      width: 1.8,
                    ),
                  ),
                  child: Icon(
                    Icons.all_inclusive,
                    size: 16,
                    color: cs.onSecondaryContainer,
                  ),
                ),
              ),
            ),
          ];

          for (final user in connectedUsers) {
            final isSelected = _selectedUserFilter == user.userId;
            actions.add(
              Tooltip(
                message: user.userName,
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => _onUserFilterChanged(user.userId),
                  child: Container(
                    width: 30,
                    height: 30,
                    padding: const EdgeInsets.all(1.6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? cs.primary
                            : cs.outlineVariant.withValues(alpha: 0.55),
                        width: 1.8,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: cs.surfaceContainerHighest,
                      backgroundImage: AvatarUtils.profileImageProvider(
                        user.photoUrl,
                        assetFallback: 'assets/images/default_profile.png',
                      ),
                    ),
                  ),
                ),
              ),
            );
          }
          return actions;
        }

        Widget calendarContent({
          required bool showActions,
          bool showPresenceStrip = true,
        }) {
          final calendarUI = _c.calendarUI;

          // Determine the view mode based on side menu selection
          String viewMode = 'week'; // default
          if (_selectedSideMenu == 'day' ||
              _selectedSideMenu == 'week' ||
              _selectedSideMenu == 'agenda') {
            viewMode = _selectedSideMenu;
          }

          return Column(
            children: [
              if (showPresenceStrip) ...[
                PresenceStatusStrip(
                  group: currentGroup,
                  controller: _c,
                  selectedUserId: _selectedUserFilter,
                  onUserSelected: _onUserFilterChanged,
                ),
                const SizedBox(height: 6),
              ],
              Expanded(
                child: calendarUI?.buildCalendar(
                      context,
                      forcedViewMode: viewMode,
                      onTimeSlotTap: _openAddEventForSlot,
                    ) ??
                    const SizedBox(),
              ),
              const SizedBox(height: 4),
              if (showActions) actionButtons(vertical: false),
            ],
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
              const SizedBox(height: 6),
              Expanded(
                child: TabBarView(
                  children: [
                    calendarUI?.buildCalendar(
                          context,
                          forcedViewMode: 'day',
                          onTimeSlotTap: _openAddEventForSlot,
                        ) ??
                        const SizedBox(),
                    calendarUI?.buildCalendar(
                          context,
                          forcedViewMode: 'week',
                          onTimeSlotTap: _openAddEventForSlot,
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
              const SizedBox(height: 4),
              actionButtons(vertical: false),
            ],
          );
        }

        Widget calendarSidebar() {
          return CalendarSideMenu(
            group: currentGroup,
            collapsed: false,
            showCollapseToggle: false,
            onToggleCollapse: () {},
            viewsExpanded: _viewsExpanded,
            eventsExpanded: _eventsExpanded,
            insightsExpanded: _insightsExpanded,
            onToggleViewsExpanded: () =>
                setState(() => _viewsExpanded = !_viewsExpanded),
            onToggleEventsExpanded: () =>
                setState(() => _eventsExpanded = !_eventsExpanded),
            onToggleInsightsExpanded: () =>
                setState(() => _insightsExpanded = !_insightsExpanded),
            selectedMenu: _selectedSideMenu,
            onMenuChanged: _onSideMenuChanged,
            onAddEvent: canAddEvents ? () => _openAddEvent(currentGroup) : null,
            canAddEvents: canAddEvents,
            upcomingCount: 0, // TODO: Get actual count from events
            completedCount: 0, // TODO: Get actual count from completed events
          );
        }

        Widget miniCalendarPanel() {
          return SizedBox(
            width: 360,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Card(
                elevation: 0,
                color: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                  child: _c.calendarUI?.buildCalendar(
                        context,
                        forcedViewMode: 'month',
                      ) ??
                      Center(
                        child: Text(
                          loc.noGroupAvailable,
                          style: typo.bodyMedium.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                ),
              ),
            ),
          );
        }

        String calendarRightPanelTitle() {
          switch (_panelView) {
            case _SidePanelView.addEvent:
              return loc.addEvent;
            case _SidePanelView.viewEvent:
              return loc.details;
            case _SidePanelView.editEvent:
              return loc.edit;
            default:
              return loc.calendarTitle;
          }
        }

        Widget calendarRightPanelContent() {
          switch (_panelView) {
            case _SidePanelView.addEvent:
              return AddEventScreen(
                group: currentGroup,
                embedded: true,
                initialStartDate: _pendingAddEventStart,
                initialEndDate: _pendingAddEventEnd,
                onCreated: () async {
                  await _refreshCalendarOnly();
                },
              );
            case _SidePanelView.viewEvent:
              if (_viewingEvent == null) {
                return Center(
                  child: Text(
                    loc.noEventsFoundForDate,
                    style: typo.bodySmall.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                );
              }
              return EventDetailScreen(
                event: _viewingEvent!,
                onEdit: () => _openEditEventInline(_viewingEvent!),
              );
            case _SidePanelView.editEvent:
              if (_editingEvent == null) {
                return Center(
                  child: Text(
                    loc.noEventsFoundForDate,
                    style: typo.bodySmall.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                );
              }
              return Provider<EventDomain>.value(
                value: context.read<EventDomain>(),
                child: EditEventScreen(
                  event: _editingEvent!,
                  embedded: true,
                ),
              );
            default:
              return Center(
                child: Text(
                  loc.noEventsFoundForDate,
                  style: typo.bodySmall.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              );
          }
        }

        String sectionTitle() {
          switch (_selectedSideMenu) {
            case 'week':
              return loc.tabWeek;
            case 'day':
              return loc.tabDay;
            case 'agenda':
              return loc.tabAgenda;
            case 'month':
              return loc.tabMonth;
            case 'upcoming':
              return loc.sectionUpcoming;
            case 'completed':
              return loc.completedEventsSectionTitle;
            case 'insights':
              return loc.insightsTitle;
            case 'mini_calendar':
              return 'Mini Calendar';
            default:
              return loc.calendarTitle;
          }
        }

        Widget sectionContent() {
          switch (_selectedSideMenu) {
            case 'upcoming':
              return AgendaScreen(
                groupId: currentGroup.id,
                showBottomNav: false,
              );
            case 'completed':
              return GroupUndoneEventsScreen(
                group: currentGroup,
                user: currentUser,
                role: currentRole,
                embedded: true,
              );
            case 'insights':
              return InsightsInlinePanel(group: currentGroup);
            case 'mini_calendar':
              return miniCalendarPanel();
            default:
              return Center(
                child: Text(
                  loc.noEventsFoundForDate,
                  style: typo.bodySmall.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              );
          }
        }

        final isCalendarSection = _selectedSideMenu == 'week' ||
            _selectedSideMenu == 'day' ||
            _selectedSideMenu == 'agenda' ||
            _selectedSideMenu == 'month';

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
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: cs.outlineVariant
                                            .withValues(alpha: 0.6),
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
                                              .withValues(alpha: 0.6),
                                        ),
                                        TextButton.icon(
                                          onPressed: () =>
                                              _openAddEvent(currentGroup),
                                          icon: const Icon(Icons.add_rounded,
                                              size: 16),
                                          label: Text(
                                            loc.addEvent,
                                            style: typo.bodySmall.copyWith(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                            ),
                                          ),
                                          style: TextButton.styleFrom(
                                            foregroundColor: cs.onPrimary,
                                            backgroundColor: cs.primary,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
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
                  onToggleLeftPanel: null,
                  leftPanelCollapsed: false,
                  showWeatherToggle: true,
                  weatherIconsEnabled: _weatherIconsEnabled,
                  onWeatherToggle: _toggleWeatherIcons,
                )
              : null,
          backgroundColor: Theme.of(context).canvasColor,
          body: SafeArea(
            child: isWide
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        calendarSidebar(),
                        const SizedBox(width: 10),
                        Expanded(
                          child: isCalendarSection
                              ? Row(
                                  children: [
                                    Expanded(
                                      child: FolderPanel(
                                        title: sectionTitle(),
                                        showTab: true,
                                        actions: calendarHeaderActions(),
                                        child: calendarContent(
                                          showActions: false,
                                          showPresenceStrip: false,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    SizedBox(
                                      width: 360,
                                      child: FolderPanel(
                                        title: calendarRightPanelTitle(),
                                        showTab: true,
                                        child: calendarRightPanelContent(),
                                      ),
                                    ),
                                  ],
                                )
                              : FolderPanel(
                                  title: sectionTitle(),
                                  showTab: true,
                                  child: sectionContent(),
                                ),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
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
