import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/side_menu/nav_section.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/side_menu/section_label.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/side_menu/sub_menu_item.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class CalendarSideMenu extends StatelessWidget {
  static const double expandedWidth = 220;
  static const double collapsedWidth = 64;

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
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isEs = _isSpanish(context);
    final menuWidth = collapsed ? collapsedWidth : expandedWidth;
    const childIndent = 12.0;

    if (collapsed) {
      return _CollapsedCalendarMenu(
        width: menuWidth,
        selectedMenu: selectedMenu,
        onMenuChanged: onMenuChanged,
        onAddEvent: canAddEvents ? onAddEvent : null,
        onToggleCollapse: onToggleCollapse,
        showCollapseToggle: showCollapseToggle,
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: menuWidth,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.36)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 6, 8, 8),
            child: _CalendarModuleHeader(
              title: isEs ? 'Calendario' : 'Calendar',
              subtitle: isEs ? 'Menu de agenda' : 'Schedule menu',
              onToggleCollapse:
                  showCollapseToggle ? onToggleCollapse : null,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GroupInvoicesNavSection(
                    title: isEs ? 'Calendario' : 'Calendar',
                    icon: Icons.calendar_month_outlined,
                    expanded: viewsExpanded,
                    onToggle: onToggleViewsExpanded,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GroupInvoicesSubMenuItem(
                          icon: Icons.calendar_view_week_outlined,
                          label: l.tabWeek,
                          selected: selectedMenu == 'week',
                          indent: childIndent,
                          onPressed: () => onMenuChanged('week'),
                        ),
                        GroupInvoicesSubMenuItem(
                          icon: Icons.calendar_view_day_outlined,
                          label: l.tabDay,
                          selected: selectedMenu == 'day',
                          indent: childIndent,
                          onPressed: () => onMenuChanged('day'),
                        ),
                        GroupInvoicesSubMenuItem(
                          icon: Icons.view_agenda_outlined,
                          label: l.tabAgenda,
                          selected: selectedMenu == 'agenda',
                          indent: childIndent,
                          onPressed: () => onMenuChanged('agenda'),
                        ),
                        GroupInvoicesSubMenuItem(
                          icon: Icons.calendar_today_outlined,
                          label: l.tabMonth,
                          selected: selectedMenu == 'month',
                          indent: childIndent,
                          onPressed: () => onMenuChanged('month'),
                        ),
                        GroupInvoicesSubMenuItem(
                          icon: Icons.grid_view_rounded,
                          label: _overviewLabel(context),
                          selected: selectedMenu == 'mini_calendar',
                          indent: childIndent,
                          onPressed: () => onMenuChanged('mini_calendar'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  GroupInvoicesNavSection(
                    title: isEs ? 'Acciones' : 'Actions',
                    icon: Icons.bolt_outlined,
                    expanded: true,
                    onToggle: () {},
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GroupInvoicesSubMenuItem(
                          icon: Icons.add_rounded,
                          label: _newEventLabel(context),
                          selected: false,
                          primaryAction: true,
                          indent: childIndent,
                          onPressed: canAddEvents ? onAddEvent : null,
                        ),
                        GroupInvoicesSubMenuItem(
                          icon: Icons.alarm_add_rounded,
                          label: _newReminderLabel(context),
                          selected: false,
                          primaryAction: true,
                          indent: childIndent,
                          onPressed: canAddEvents ? onAddEvent : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _BusinessHoursInfo(
                    group: group,
                    canEdit: canEditBusinessHours,
                    onTap: canEditBusinessHours ? onEditBusinessHours : null,
                  ),
                  const SizedBox(height: 8),
                  GroupInvoicesNavSection(
                    title: isEs ? 'Eventos' : 'Events',
                    icon: Icons.event_available_outlined,
                    expanded: eventsExpanded,
                    onToggle: onToggleEventsExpanded,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GroupInvoicesSectionLabel(
                          isEs ? 'Seguimiento' : 'Tracking',
                        ),
                        GroupInvoicesSubMenuItem(
                          icon: Icons.upcoming_rounded,
                          label: l.sectionUpcoming,
                          count: upcomingCount > 0 ? upcomingCount : null,
                          selected: selectedMenu == 'upcoming',
                          indent: childIndent,
                          onPressed: () => onMenuChanged('upcoming'),
                        ),
                        GroupInvoicesSubMenuItem(
                          icon: Icons.task_alt_rounded,
                          label: l.completedEventsSectionTitle,
                          count: completedCount > 0 ? completedCount : null,
                          selected: selectedMenu == 'completed',
                          indent: childIndent,
                          onPressed: () => onMenuChanged('completed'),
                        ),
                        GroupInvoicesSubMenuItem(
                          icon: Icons.checklist_rounded,
                          label: _tasksLabel(context),
                          selected: selectedMenu == 'tasks',
                          indent: childIndent,
                          onPressed: () => onMenuChanged('tasks'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  GroupInvoicesNavSection(
                    title: isEs ? 'Analisis' : 'Analysis',
                    icon: Icons.insights_outlined,
                    expanded: insightsExpanded,
                    onToggle: onToggleInsightsExpanded,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GroupInvoicesSubMenuItem(
                          icon: Icons.analytics_outlined,
                          label: _reportsLabel(context),
                          selected: selectedMenu == 'insights',
                          indent: childIndent,
                          onPressed: () => onMenuChanged('insights'),
                        ),
                        GroupInvoicesSubMenuItem(
                          icon: Icons.query_stats_rounded,
                          label: _statsLabel(context),
                          selected: selectedMenu == 'insights',
                          indent: childIndent,
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
    );
  }
}

class _CalendarModuleHeader extends StatelessWidget {
  const _CalendarModuleHeader({
    required this.title,
    required this.subtitle,
    required this.onToggleCollapse,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onToggleCollapse;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.38)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.calendar_month_outlined,
              size: 18,
              color: cs.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          if (onToggleCollapse != null)
            Tooltip(
              message: l.groupInvoicesNavCollapse,
              child: IconButton.filledTonal(
                onPressed: onToggleCollapse,
                icon: const Icon(Icons.keyboard_double_arrow_left_rounded),
                iconSize: 18,
                style: IconButton.styleFrom(
                  minimumSize: const Size(40, 34),
                  fixedSize: const Size(40, 34),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
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
    required this.onToggleCollapse,
    required this.showCollapseToggle,
  });

  final double width;
  final String selectedMenu;
  final ValueChanged<String> onMenuChanged;
  final VoidCallback? onAddEvent;
  final VoidCallback onToggleCollapse;
  final bool showCollapseToggle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
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
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.42)),
        ),
      ),
      child: Column(
        children: [
          if (showCollapseToggle)
            Align(
              alignment: Alignment.center,
              child: IconButton.filledTonal(
                tooltip: l.groupInvoicesNavExpand,
                onPressed: onToggleCollapse,
                icon: const Icon(Icons.keyboard_double_arrow_right_rounded),
                style: IconButton.styleFrom(
                  minimumSize: const Size(42, 42),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final item = items[index];
                final selected = item.key == activeKey;
                return Tooltip(
                  message: item.label,
                  waitDuration: const Duration(milliseconds: 350),
                  child: Center(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
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
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        curve: Curves.easeOutCubic,
                        width: 48,
                        height: 44,
                        decoration: BoxDecoration(
                          color: selected
                              ? cs.primary.withValues(alpha: 0.13)
                              : cs.surfaceContainerHighest
                                  .withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                            color: selected
                                ? cs.primary.withValues(alpha: 0.25)
                                : cs.outlineVariant.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Icon(
                          item.icon,
                          size: 19,
                          color: selected ? cs.primary : cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
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
        color: cs.surfaceContainerHighest.withValues(alpha: 0.115),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.18)),
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

String _newReminderLabel(BuildContext context) {
  final l = AppLocalizations.of(context)!;
  return _isSpanish(context)
      ? 'Nuevo ${l.reminderLabel.toLowerCase()}'
      : 'New reminder';
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
