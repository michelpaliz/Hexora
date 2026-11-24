import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/group_invoices/widgets/side_menu/sub_menu_item.dart';
import 'package:hexora/presentation/shared/widgets/sidebar_edge_shell.dart';
import 'package:hexora/presentation/shared/widgets/sidebar_item.dart';
import 'package:hexora/theme/colors/app_colors.dart';
import 'package:hexora/theme/themes/navigation_theme.dart';
import 'package:hexora/theme/typography/typography_extension.dart';

class CalendarSideMenu extends StatelessWidget {
  static const double expandedWidth = NavigationTokens.sidebarWidth;
  static const double collapsedWidth = NavigationTokens.railWidth;

  final Group group;
  final bool collapsed;
  final bool showCollapseToggle;
  final VoidCallback onToggleCollapse;
  final bool viewsExpanded;
  final bool eventsExpanded;
  final bool insightsExpanded;
  final VoidCallback onToggleViewsExpanded;
  final VoidCallback onToggleEventsExpanded;
  final VoidCallback onToggleInsightsExpanded;
  final String selectedMenu;
  final ValueChanged<String> onMenuChanged;
  final VoidCallback? onAddEvent;
  final VoidCallback? onEditBusinessHours;
  final bool canAddEvents;
  final bool canEditBusinessHours;
  final int upcomingCount;
  final int completedCount;
  final Widget? dateNavigator;
  final Widget? calendarFilters;

  const CalendarSideMenu({
    super.key,
    required this.group,
    required this.collapsed,
    this.showCollapseToggle = true,
    required this.onToggleCollapse,
    required this.viewsExpanded,
    required this.eventsExpanded,
    required this.insightsExpanded,
    required this.onToggleViewsExpanded,
    required this.onToggleEventsExpanded,
    required this.onToggleInsightsExpanded,
    required this.selectedMenu,
    required this.onMenuChanged,
    this.onAddEvent,
    this.onEditBusinessHours,
    required this.canAddEvents,
    this.canEditBusinessHours = false,
    this.upcomingCount = 0,
    this.completedCount = 0,
    this.dateNavigator,
    this.calendarFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: navigationTheme(Theme.of(context)),
      child: Builder(builder: _buildMenu),
    );
  }

  /// The secondary calendar column is a white content surface. The workspace
  /// canvas remains visible around it, while the compact month picker below
  /// provides the light-blue accent surface.
  static Color sidebarBackground(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  Widget _buildMenu(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isEs = _isSpanish(context);
    final menuWidth = collapsed ? collapsedWidth : expandedWidth;
    final colors = Theme.of(context).colorScheme;
    final light = colors.brightness == Brightness.light;
    // Keep the secondary column white so it reads as a focused content panel.
    // The mini calendar below uses the light-blue workspace canvas as its
    // accent surface; selected rows remain white for emphasis.
    final shellBackground = sidebarBackground(context);
    final miniCalendarDecoration = BoxDecoration(
      color: light ? AppColors.workspaceCanvas : colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: colors.outlineVariant.withValues(alpha: .7)),
    );
    Widget item({
      required IconData icon,
      required String label,
      required bool selected,
      required VoidCallback onPressed,
      int? count,
      double indent = 0,
    }) =>
        GroupInvoicesSubMenuItem(
          compact: true,
          icon: icon,
          label: label,
          count: count,
          selected: selected,
          indent: indent,
          onPressed: onPressed,
          selectedBackgroundColor: light ? colors.surface : null,
          selectedBorderColor:
              light ? colors.outlineVariant.withValues(alpha: .7) : null,
        );
    Widget section(
        String title, bool expanded, VoidCallback toggle, Widget child) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: 6),
        Divider(height: 1, color: colors.outlineVariant.withValues(alpha: .3)),
        InkWell(
          onTap: toggle,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            child: Row(children: [
              Expanded(
                  child: Text(title,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface))),
              Icon(expanded ? Icons.expand_less : Icons.expand_more,
                  size: 16, color: colors.onSurfaceVariant),
            ]),
          ),
        ),
        if (expanded) child,
      ]);
    }

    if (collapsed) {
      return SizedBox(
        width: menuWidth,
        child: SidebarEdgeShell(
          backgroundColor: shellBackground,
          collapsed: true,
          onToggle: onToggleCollapse,
          showHandle: showCollapseToggle,
          child: _CollapsedCalendarMenu(
            width: menuWidth,
            selectedMenu: selectedMenu,
            onMenuChanged: onMenuChanged,
            onAddEvent: canAddEvents ? onAddEvent : null,
          ),
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: menuWidth,
      child: SidebarEdgeShell(
        backgroundColor: shellBackground,
        collapsed: false,
        onToggle: onToggleCollapse,
        showHandle: showCollapseToggle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (canAddEvents)
                      FilledButton.icon(
                        onPressed: onAddEvent,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: Text(_newEventLabel(context)),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(34),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9)),
                        ),
                      ),
                    if (dateNavigator != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        key: const ValueKey('calendar-mini-calendar-card'),
                        padding: const EdgeInsets.all(2),
                        clipBehavior: Clip.antiAlias,
                        decoration: miniCalendarDecoration,
                        child: dateNavigator!,
                      ),
                    ],
                    if (calendarFilters != null)
                      section(
                          isEs ? 'Mis calendarios' : 'My calendars',
                          viewsExpanded,
                          onToggleViewsExpanded,
                          calendarFilters!),
                    section(
                      isEs ? 'Eventos y tareas' : 'Events and tasks',
                      eventsExpanded,
                      onToggleEventsExpanded,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          item(
                            icon: Icons.upcoming_rounded,
                            label: l.sectionUpcoming,
                            count: upcomingCount > 0 ? upcomingCount : null,
                            selected: selectedMenu == 'upcoming',
                            onPressed: () => onMenuChanged('upcoming'),
                          ),
                          item(
                            icon: Icons.task_alt_rounded,
                            label: isEs ? 'Completados' : 'Completed',
                            count: completedCount > 0 ? completedCount : null,
                            selected: selectedMenu == 'completed',
                            onPressed: () => onMenuChanged('completed'),
                          ),
                          item(
                            icon: Icons.checklist_rounded,
                            label: _tasksLabel(context),
                            selected: selectedMenu == 'tasks',
                            onPressed: () => onMenuChanged('tasks'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    section(
                      isEs ? 'Configuración' : 'Settings',
                      insightsExpanded,
                      onToggleInsightsExpanded,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _BusinessHoursInfo(
                            group: group,
                            canEdit: canEditBusinessHours,
                            onTap: canEditBusinessHours
                                ? onEditBusinessHours
                                : null,
                          ),
                          item(
                            icon: Icons.grid_view_rounded,
                            label: _overviewLabel(context),
                            selected: selectedMenu == 'mini_calendar',
                            onPressed: () => onMenuChanged('mini_calendar'),
                          ),
                          item(
                            icon: Icons.analytics_outlined,
                            label: _reportsLabel(context),
                            selected: selectedMenu == 'insights',
                            onPressed: () => onMenuChanged('insights'),
                          ),
                          item(
                            icon: Icons.query_stats_rounded,
                            label: _statsLabel(context),
                            selected: selectedMenu == 'insights',
                            onPressed: () => onMenuChanged('insights'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CollapsedCalendarMenu extends StatelessWidget {
  const _CollapsedCalendarMenu({
    required this.width,
    required this.selectedMenu,
    required this.onMenuChanged,
    required this.onAddEvent,
  });

  final double width;
  final String selectedMenu;
  final ValueChanged<String> onMenuChanged;
  final VoidCallback? onAddEvent;

  @override
  Widget build(BuildContext context) {
    final isEs = _isSpanish(context);
    final activeKey = selectedMenu == 'upcoming' ||
            selectedMenu == 'completed' ||
            selectedMenu == 'tasks'
        ? 'events'
        : selectedMenu == 'insights'
            ? 'insights'
            : 'calendar';
    final items = <({String key, IconData icon, String label})>[
      (
        key: 'calendar',
        icon: Icons.calendar_month_outlined,
        label: isEs ? 'Calendario' : 'Calendar'
      ),
      (
        key: 'actions',
        icon: Icons.add_circle_outline_rounded,
        label: isEs ? 'Acciones' : 'Actions'
      ),
      (
        key: 'events',
        icon: Icons.event_available_outlined,
        label: isEs ? 'Eventos' : 'Events'
      ),
      (
        key: 'insights',
        icon: Icons.insights_outlined,
        label: isEs ? 'Analisis' : 'Analysis'
      ),
    ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: width,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      child: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final item = items[index];
                final selected = item.key == activeKey;
                return SidebarItem(
                  icon: item.icon,
                  label: item.label,
                  isSelected: selected,
                  collapsed: true,
                  onTap: () {
                    switch (item.key) {
                      case 'actions':
                        onAddEvent?.call();
                        break;
                      case 'events':
                        onMenuChanged('upcoming');
                        break;
                      case 'insights':
                        onMenuChanged('insights');
                        break;
                      case 'calendar':
                      default:
                        onMenuChanged('week');
                        break;
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BusinessHoursInfo extends StatefulWidget {
  const _BusinessHoursInfo({
    required this.group,
    this.onTap,
    this.canEdit = false,
  });

  final Group group;
  final VoidCallback? onTap;
  final bool canEdit;

  @override
  State<_BusinessHoursInfo> createState() => _BusinessHoursInfoState();
}

class _BusinessHoursInfoState extends State<_BusinessHoursInfo> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final hours = widget.group.businessHours;
    final hasWindow = hours?.isConfigured ?? false;
    final rangeLabel = hasWindow
        ? l.businessHoursRange(
            hours!.start ?? '--:--',
            hours.end ?? '--:--',
            hours.timezone,
          )
        : l.businessHoursUnset;
    final timezone = hours?.timezone ?? 'Europe/Madrid';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.fromLTRB(7, 5, 7, 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.schedule_rounded,
                      size: 15,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.sectionBusinessHours,
                      style: t.bodySmall.copyWith(
                        fontSize: 12.5,
                        color: cs.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => setState(() => _expanded = !_expanded),
                    borderRadius: BorderRadius.circular(999),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 19,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 34, top: 5, right: 4),
                child: AnimatedCrossFade(
                  duration: const Duration(milliseconds: 180),
                  crossFadeState: _expanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: Text(
                    rangeLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodySmall.copyWith(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.86),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  secondChild: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rangeLabel,
                        style: t.bodySmall.copyWith(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.92),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        timezone,
                        style: t.bodySmall.copyWith(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.72),
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
    );
  }
}

bool _isSpanish(BuildContext context) {
  return Localizations.localeOf(context).languageCode.toLowerCase().startsWith(
        'es',
      );
}

String _overviewLabel(BuildContext context) {
  final l = AppLocalizations.of(context)!;
  return _isSpanish(context) ? l.sectionOverview : 'Overview';
}

String _newEventLabel(BuildContext context) {
  return _isSpanish(context) ? 'Nuevo evento' : 'New event';
}

String _tasksLabel(BuildContext context) {
  final l = AppLocalizations.of(context)!;
  return _isSpanish(context) ? l.tasks : 'Tasks';
}

String _reportsLabel(BuildContext context) {
  return _isSpanish(context) ? 'Informes' : 'Reports';
}

String _statsLabel(BuildContext context) {
  return _isSpanish(context) ? 'Estadisticas' : 'Statistics';
}
