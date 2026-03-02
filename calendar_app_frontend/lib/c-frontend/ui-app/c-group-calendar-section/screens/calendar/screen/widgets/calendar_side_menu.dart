import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class CalendarSideMenu extends StatelessWidget {
  static const double expandedWidth = 208;
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
  final bool canAddEvents;
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
    required this.canAddEvents,
    this.upcomingCount = 0,
    this.completedCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final menuWidth = collapsed ? collapsedWidth : expandedWidth;

    return SizedBox(
      width: menuWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 6, 6, 4),
            child: Row(
              children: [
                if (showCollapseToggle)
                  IconButton(
                    tooltip: collapsed
                        ? l.groupInvoicesNavExpand
                        : l.groupInvoicesNavCollapse,
                    onPressed: onToggleCollapse,
                    icon: Icon(
                      collapsed ? Icons.chevron_right : Icons.chevron_left,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(0, 0, 8, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!collapsed) ...[
                    _CalendarNavSection(
                      title: l.calendarTitle,
                      icon: Icons.calendar_view_month_outlined,
                      expanded: viewsExpanded,
                      onToggle: onToggleViewsExpanded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _CalendarSubMenuItem(
                            icon: Icons.calendar_view_week_outlined,
                            label: l.tabWeek,
                            selected: selectedMenu == 'week',
                            onPressed: () => onMenuChanged('week'),
                          ),
                          const SizedBox(height: 6),
                          _CalendarSubMenuItem(
                            icon: Icons.calendar_view_day_outlined,
                            label: l.tabDay,
                            selected: selectedMenu == 'day',
                            onPressed: () => onMenuChanged('day'),
                          ),
                          const SizedBox(height: 6),
                          _CalendarSubMenuItem(
                            icon: Icons.view_agenda_outlined,
                            label: l.tabAgenda,
                            selected: selectedMenu == 'agenda',
                            onPressed: () => onMenuChanged('agenda'),
                          ),
                          const SizedBox(height: 6),
                          _CalendarSubMenuItem(
                            icon: Icons.calendar_today_outlined,
                            label: l.tabMonth,
                            selected: selectedMenu == 'month',
                            onPressed: () => onMenuChanged('month'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    _CalendarSubMenuItem(
                      icon: Icons.calendar_month_outlined,
                      label: 'Mini Calendar',
                      selected: selectedMenu == 'mini_calendar',
                      onPressed: () => onMenuChanged('mini_calendar'),
                    ),
                    const SizedBox(height: 8),
                    _CalendarNavSection(
                      title: 'Events',
                      icon: Icons.event_outlined,
                      expanded: eventsExpanded,
                      onToggle: onToggleEventsExpanded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (canAddEvents) ...[
                            _CalendarSubMenuItem(
                              icon: Icons.add_rounded,
                              label: l.addEvent,
                              selected: false,
                              onPressed: onAddEvent,
                            ),
                            const SizedBox(height: 6),
                          ],
                          _CalendarSubMenuItem(
                            icon: Icons.upcoming_rounded,
                            label: l.sectionUpcoming,
                            count: upcomingCount > 0 ? upcomingCount : null,
                            selected: selectedMenu == 'upcoming',
                            onPressed: () => onMenuChanged('upcoming'),
                          ),
                          const SizedBox(height: 6),
                          _CalendarSubMenuItem(
                            icon: Icons.task_alt_rounded,
                            label: l.completedEventsSectionTitle,
                            count: completedCount > 0 ? completedCount : null,
                            selected: selectedMenu == 'completed',
                            onPressed: () => onMenuChanged('completed'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _CalendarNavSection(
                      title: l.insightsTitle,
                      icon: Icons.insights_outlined,
                      expanded: insightsExpanded,
                      onToggle: onToggleInsightsExpanded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _CalendarSubMenuItem(
                            icon: Icons.analytics_outlined,
                            label: l.insightsTitle,
                            selected: selectedMenu == 'insights',
                            onPressed: () => onMenuChanged('insights'),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 16),
                    ...() {
                      final iconItems = <Widget>[
                        if (canAddEvents)
                          _CalendarMenuIconButton(
                            icon: Icons.add_rounded,
                            label: l.addEvent,
                            selected: false,
                            onPressed: onAddEvent ?? () {},
                          ),
                        _CalendarMenuIconButton(
                          icon: Icons.calendar_view_week_outlined,
                          label: l.tabWeek,
                          selected: selectedMenu == 'week',
                          onPressed: () => onMenuChanged('week'),
                        ),
                        _CalendarMenuIconButton(
                          icon: Icons.calendar_view_day_outlined,
                          label: l.tabDay,
                          selected: selectedMenu == 'day',
                          onPressed: () => onMenuChanged('day'),
                        ),
                        _CalendarMenuIconButton(
                          icon: Icons.view_agenda_outlined,
                          label: l.tabAgenda,
                          selected: selectedMenu == 'agenda',
                          onPressed: () => onMenuChanged('agenda'),
                        ),
                        _CalendarMenuIconButton(
                          icon: Icons.calendar_today_outlined,
                          label: l.tabMonth,
                          selected: selectedMenu == 'month',
                          onPressed: () => onMenuChanged('month'),
                        ),
                        _CalendarMenuIconButton(
                          icon: Icons.calendar_month_outlined,
                          label: 'Mini Calendar',
                          selected: selectedMenu == 'mini_calendar',
                          onPressed: () => onMenuChanged('mini_calendar'),
                        ),
                        _CalendarMenuIconButton(
                          icon: Icons.upcoming_rounded,
                          label: l.sectionUpcoming,
                          selected: selectedMenu == 'upcoming',
                          onPressed: () => onMenuChanged('upcoming'),
                        ),
                        _CalendarMenuIconButton(
                          icon: Icons.task_alt_rounded,
                          label: l.completedEventsSectionTitle,
                          selected: selectedMenu == 'completed',
                          onPressed: () => onMenuChanged('completed'),
                        ),
                        _CalendarMenuIconButton(
                          icon: Icons.insights_outlined,
                          label: l.insightsTitle,
                          selected: selectedMenu == 'insights',
                          onPressed: () => onMenuChanged('insights'),
                        ),
                      ];
                      return [
                        for (var i = 0; i < iconItems.length; i++) ...[
                          if (i > 0) const SizedBox(height: 8),
                          iconItems[i],
                        ],
                      ];
                    }(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarNavSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  const _CalendarNavSection({
    required this.title,
    required this.icon,
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 4, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: cs.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: t.bodySmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    color: cs.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const SizedBox(height: 4),
            child,
          ],
        ],
      ),
    );
  }
}

class _CalendarSubMenuItem extends StatelessWidget {
  const _CalendarSubMenuItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onPressed,
    this.count,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onPressed;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final enabled = onPressed != null;
    final fg = selected
        ? cs.onPrimaryContainer
        : (enabled ? cs.onSurfaceVariant : cs.outline);
    return SizedBox(
      height: 38,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 4),
          Expanded(
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: [
                    if (selected)
                      Container(
                        width: 3,
                        height: 18,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: cs.primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    Icon(icon, size: 16, color: fg),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        style: t.bodySmall.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (count != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          count.toString(),
                          style: t.bodySmall.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    if (!enabled)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Text(
                          'Pronto',
                          style: t.bodySmall.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarMenuIconButton extends StatelessWidget {
  const _CalendarMenuIconButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = selected ? cs.primaryContainer : cs.surface;
    final fg = selected ? cs.onPrimaryContainer : cs.onSurface;
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.7),
            ),
          ),
          child: Center(
            child: Icon(
              icon,
              color: fg,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}
