// main_calendar_view.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/b-backend/auth_user/user/domain/user_domain.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/calendar/presentation/coordinator/calendar_screen_coordinator.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/calendar/screen/calendar_topbar.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/calendar/utils/add_event_cta.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/calendar/utils/group_permissions_helper.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/calendar/utils/presence_status_strip.dart';
import 'package:hexora/c-frontend/d-event-section/screens/actions/add_screen/screen/add_event_screen.dart';
import 'package:hexora/f-themes/app_colors/themes/text_styles/typography_extension.dart';
import 'package:provider/provider.dart';

enum _CalTab { day, week, month, agenda }

class MainCalendarView extends StatefulWidget {
  final Group? group;
  const MainCalendarView({super.key, this.group});

  @override
  State<MainCalendarView> createState() => _MainCalendarViewState();
}

class _MainCalendarViewState extends State<MainCalendarView> {
  late final CalendarScreenCoordinator _c;
  bool _isBootstrapped = false;
  // Default to Week view
  int _initialIndex = _CalTab.week.index;

  @override
  void initState() {
    super.initState();
    _c = CalendarScreenCoordinator(context: context);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    if (_isBootstrapped) return;
    try {
      await _c.initSockets();
      await _c.loadData(initialGroup: widget.group);
      // OPTIONAL: if your coordinator exposes current view, set initial tab accordingly:
      // _initialIndex = _tabIndexFromCoordinator(_c.currentView);
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

  void _onTabChanged(int index) {
    switch (_CalTab.values[index]) {
      case _CalTab.day:
        _c.setViewMode('day');
        break;
      case _CalTab.week:
        _c.setViewMode('week');
        break;
      case _CalTab.month:
        _c.setViewMode('month');
        break;
      case _CalTab.agenda:
        _c.setViewMode('agenda');
        break;
    }
    setState(() {});
  }

  List<Tab> _tabs(BuildContext context) {
    return const [
      Tab(text: 'Day', icon: Icon(Icons.today_outlined, size: 18)),
      Tab(text: 'Week', icon: Icon(Icons.view_week_outlined, size: 18)),
      Tab(text: 'Month', icon: Icon(Icons.calendar_month_outlined, size: 18)),
      Tab(text: 'Agenda', icon: Icon(Icons.list_alt_outlined, size: 18)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final groupDomain = context.watch<GroupDomain>();
    final userDomain = context.watch<UserDomain>();
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);

    return ValueListenableBuilder<bool>(
      valueListenable: _c.loading,
      builder: (_, isLoading, __) {
        if (isLoading) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final currentUser = userDomain.user;
        final currentGroup = groupDomain.currentGroup;

        if (currentUser == null || currentGroup == null) {
          return Scaffold(
            appBar: CalendarTopBar(title: 'Calendar', tabs: _tabs(context)),
            body: SafeArea(
              child: Center(
                child: Text(
                  'No group available',
                  style: typo.bodyMedium.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            ),
          );
        }

        final canAddEvents =
            GroupPermissionHelper.canAddEvents(currentUser, currentGroup);

        return DefaultTabController(
          length: _CalTab.values.length,
          initialIndex: _initialIndex,
          child: Scaffold(
            appBar: CalendarTopBar(
              title: currentGroup.name,
              tabs: _tabs(context),
              onTabChanged: _onTabChanged,
              actions: const [], // add filters, overflow, etc. if you like
            ),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: Column(
                  children: [
                    // Presence strip
                    PresenceStatusStrip(group: currentGroup, controller: _c),
                    const SizedBox(height: 10),

                    // Calendar content
                    Expanded(
                      child: _c.calendarUI?.buildCalendar(context) ??
                          const SizedBox(),
                    ),

                    // Bottom actions
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: Text('Refresh', style: typo.bodySmall),
                              onPressed: () async {
                                await _c.loadData(initialGroup: currentGroup);
                              },
                            ),
                          ),
                          if (canAddEvents) ...[
                            const SizedBox(width: 10),
                            Expanded(
                              child: AddEventCta(
                                onPressed: () async {
                                  final added =
                                      await Navigator.of(context).push<bool>(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          AddEventScreen(group: currentGroup),
                                    ),
                                  );
                                  if (added == true) {
                                    _c.loadData(initialGroup: currentGroup);
                                  }
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }
}
