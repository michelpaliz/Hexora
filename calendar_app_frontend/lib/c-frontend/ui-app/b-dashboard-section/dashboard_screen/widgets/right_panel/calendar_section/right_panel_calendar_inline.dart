import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/widgets/right_panel/calendar_section/widgets/calendar_inline_error_view.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/widgets/right_panel/calendar_section/widgets/calendar_inline_footer_actions.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/widgets/right_panel/calendar_section/widgets/calendar_inline_header.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/widgets/right_panel/calendar_section/widgets/calendar_no_group_placeholder.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/calendar/presentation/coordinator/calendar_screen_coordinator.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/calendar/screen/widgets/calendar_tabs.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/calendar/utils/group_permissions_helper.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/calendar/utils/presence_status_strip.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class CalendarInlinePanel extends StatefulWidget {
  final Group group;

  const CalendarInlinePanel({super.key, required this.group});

  @override
  State<CalendarInlinePanel> createState() => _CalendarInlinePanelState();
}

class _CalendarInlinePanelState extends State<CalendarInlinePanel>
    with SingleTickerProviderStateMixin {
  late final CalendarScreenCoordinator _coordinator;
  late final TabController _tabs;

  bool _bootstrapped = false;
  String? _error;
  String? _selectedUserFilter;

  @override
  void initState() {
    super.initState();
    _coordinator = CalendarScreenCoordinator(context: context);
    _tabs = TabController(
      length: CalTab.values.length,
      vsync: this,
      initialIndex: CalTab.agenda.index,
    )..addListener(() {
        if (!_tabs.indexIsChanging) {
          _onTabChanged(_tabs.index);
        }
      });
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void didUpdateWidget(CalendarInlinePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.group.id != widget.group.id) {
      _bootstrapped = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
    }
  }

  Future<void> _bootstrap() async {
    setState(() {
      _error = null;
      _bootstrapped = false;
    });
    try {
      await _coordinator.initSockets();
      await _coordinator.loadData(initialGroup: widget.group);
      _coordinator.calendarUI?.setShowWeatherIcons(false);
      CalendarTabs.handleTabChanged(_coordinator, _tabs.index);
      _bootstrapped = true;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() {});
    }
  }

  void _onTabChanged(int index) {
    CalendarTabs.handleTabChanged(_coordinator, index);
    setState(() {});
  }

  void _onUserFilterChanged(String? userId) {
    setState(() => _selectedUserFilter = userId);
    _coordinator.calendarUI?.setEventFilter(userId: userId);
  }

  Future<void> _refresh() async {
    await _coordinator.loadData(initialGroup: widget.group);
  }

  Future<void> _addEvent() async {
    await _coordinator.handleAddEventPressed(context, widget.group);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _coordinator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final user = context.read<UserDomain>().user;
    final canAddEvents =
        user != null && GroupPermissionHelper.canAddEvents(user, widget.group);

    if (!widget.group.hasCalendar) {
      return const CalendarNoGroupPlaceholder();
    }

    return CalendarTabsTheme(
      child: ValueListenableBuilder<bool>(
        valueListenable: _coordinator.loading,
        builder: (_, loading, __) {
          if (_error != null) {
            return CalendarInlineErrorView(
              error: _error!,
              onRetry: _bootstrap,
            );
          }

          if (loading && !_bootstrapped) {
            return const Center(child: CircularProgressIndicator());
          }

          return Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CalendarInlineHeader(
                  groupName: widget.group.name,
                  isLoading: loading,
                  onRefresh: _refresh,
                  onJumpToToday: _coordinator.jumpToToday,
                ),
                const SizedBox(height: 8),
                TabBar(
                  controller: _tabs,
                  tabs: CalendarTabs.build(context),
                  isScrollable: true,
                  indicatorSize: TabBarIndicatorSize.tab,
                ),
                const SizedBox(height: 8),
                PresenceStatusStrip(
                  group: widget.group,
                  controller: _coordinator,
                  selectedUserId: _selectedUserFilter,
                  onUserSelected: _onUserFilterChanged,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _coordinator.calendarUI?.buildCalendar(context) ??
                        Center(
                          child: Text(
                            l.noGroupAvailable,
                            style: t.bodyMedium
                                .copyWith(color: cs.onSurfaceVariant),
                          ),
                        ),
                  ),
                ),
                const SizedBox(height: 10),
                CalendarInlineFooterActions(
                  isLoading: loading,
                  canAddEvents: canAddEvents,
                  onRefresh: _refresh,
                  onAddEvent: _addEvent,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
