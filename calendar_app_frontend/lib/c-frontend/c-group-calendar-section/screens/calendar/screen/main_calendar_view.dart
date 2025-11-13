// c-frontend/c-group-calendar-section/screens/calendar/screen/main_calendar_view.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/calendar/presentation/coordinator/calendar_screen_coordinator.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/calendar/screen/widgets/calendar_tabs.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/calendar/screen/widgets/calendar_topbar.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/calendar/screen/widgets/refresh_button.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/calendar/utils/add_event_cta.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/calendar/utils/group_permissions_helper.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/calendar/utils/presence_status_strip.dart';
import 'package:hexora/c-frontend/d-event-section/screens/actions/add_screen/screen/add_event_screen.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class MainCalendarView extends StatefulWidget {
  final Group? group;
  const MainCalendarView({super.key, this.group});

  @override
  State<MainCalendarView> createState() => _MainCalendarViewState();
}

class _MainCalendarViewState extends State<MainCalendarView> {
  late final CalendarScreenCoordinator _c;
  bool _isBootstrapped = false;

  // Default to Week view (using new CalTab enum)
  int _initialIndex = CalTab.week.index;

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

  void _onTabChanged(int index) {
    CalendarTabs.handleTabChanged(_c, index);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final groupDomain = context.watch<GroupDomain>();
    final userDomain = context.watch<UserDomain>();
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);
    final loc = AppLocalizations.of(context)!;

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
                tabs: CalendarTabs.build(context), // themed & localized tabs
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

        return DefaultTabController(
          length: CalTab.values.length,
          initialIndex: _initialIndex,
          child: CalendarTabsTheme(
            child: Scaffold(
              appBar: CalendarTopBar(
                title: currentGroup.name,
                tabs: CalendarTabs.build(context), // themed & localized tabs
                onTabChanged: _onTabChanged,
                actions: const [],
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
                      // Bottom actions
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: IntrinsicHeight(
                          child: Row(
                            children: [
                              Expanded(
                                child: RefreshCta(
                                  isLoading: _c.loading.value,
                                  onPressed: () async {
                                    await _c.loadData(
                                        initialGroup: currentGroup);
                                    if (mounted) setState(() {});
                                  },
                                ),
                              ),
                              if (canAddEvents) ...[
                                const SizedBox(width: 10),
                                Expanded(
                                  child: AddEventCta(
                                    onPressed: () async {
                                      final added = await Navigator.of(context)
                                          .push<bool>(
                                        MaterialPageRoute(
                                          builder: (_) => AddEventScreen(
                                              group: currentGroup),
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
                      ),
                    ],
                  ),
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
