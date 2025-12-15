// c-frontend/c-group-calendar-section/screens/calendar/screen/main_calendar_view.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/calendar/presentation/coordinator/calendar_screen_coordinator.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/calendar/screen/widgets/calendar_tabs.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/calendar/screen/widgets/calendar_topbar.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/calendar/screen/widgets/refresh_button.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/calendar/utils/add_event_cta.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/calendar/utils/group_permissions_helper.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/calendar/utils/presence_status_strip.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/actions/add_screen/screen/add_event_screen.dart';
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
  bool _weatherIconsEnabled = true;
  String? _selectedUserFilter;

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

  void _onTabChanged(int index) {
    CalendarTabs.handleTabChanged(_c, index);
    setState(() {});
  }

  void _toggleWeatherIcons(bool value) {
    _weatherIconsEnabled = value;
    _c.calendarUI?.setShowWeatherIcons(value);
    setState(() {});
  }

  Future<void> _openAddEvent(Group group) async {
    bool? added;

    if (kIsWeb) {
      // On web, keep the 3-column layout in place by showing a dialog instead of full navigation.
      added = await showDialog<bool>(
        context: context,
        builder: (dialogCtx) {
          final media = MediaQuery.of(dialogCtx).size;
          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
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

        Widget calendarContent({required bool verticalActions}) {
          return Column(
            children: [
              PresenceStatusStrip(
                group: currentGroup,
                controller: _c,
                selectedUserId: _selectedUserFilter,
                onUserSelected: _onUserFilterChanged,
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _c.calendarUI?.buildCalendar(context) ??
                    const SizedBox(),
              ),
              const SizedBox(height: 8),
              if (!verticalActions) actionButtons(vertical: false),
            ],
          );
        }

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
                showWeatherToggle: true,
                weatherIconsEnabled: _weatherIconsEnabled,
                onWeatherToggle: _toggleWeatherIcons,
              ),
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              body: SafeArea(
                child: isWide
                    ? Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1200),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: calendarContent(
                                      verticalActions: true),
                                ),
                                const SizedBox(width: 16),
                                SizedBox(
                                  width: 280,
                                  child: Card(
                                    elevation: 2,
                                    clipBehavior: Clip.antiAlias,
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 18, 16, 20),
                                      child: actionButtons(vertical: true),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : Padding(
                        padding:
                            const EdgeInsets.fromLTRB(10, 10, 10, 10),
                        child:
                            calendarContent(verticalActions: false),
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
