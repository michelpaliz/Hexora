// presentation/c-group-calendar-section/screens/calendar/widgets/calendar_tabs.dart
import 'package:flutter/material.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

import '../../presentation/coordinator/calendar_screen_coordinator.dart';

/// Public (non-underscored) enum so other files can refer to it if needed.
enum CalTab { day, week, month, agenda }

/// A tiny wrapper to provide consistent TabBar fonts/colors using context theme.
class CalendarTabsTheme extends StatelessWidget {
  final Widget child;
  const CalendarTabsTheme({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);
    final base = Theme.of(context);

    return Theme(
      data: base.copyWith(
        tabBarTheme: base.tabBarTheme.copyWith(
          labelStyle: typo.bodySmall.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: .2,
            color: cs.primary,
          ),
          unselectedLabelStyle: typo.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: .1,
            color: cs.onSurfaceVariant,
          ),
          indicatorColor: cs.primary,
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurfaceVariant,
        ),
      ),
      child: child,
    );
  }
}

/// Factory for localized tabs + a coordinator-aware onChanged.
class CalendarTabs {
  static List<Tab> build(BuildContext context, {bool large = false}) {
    final loc = AppLocalizations.of(context)!;
    final iconSize = large ? 16.0 : 14.0;

    Tab buildTab(String label, IconData icon) => Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: iconSize),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );

    return [
      buildTab(loc.tabDay, Icons.today_outlined),
      buildTab(loc.tabWeek, Icons.view_week_outlined),
      buildTab(loc.tabMonth, Icons.calendar_month_outlined),
      buildTab(loc.tabAgenda, Icons.list_alt_outlined),
    ];
  }

  /// Pipe Tab index → coordinator view mode
  static void handleTabChanged(CalendarScreenCoordinator c, int index) {
    switch (CalTab.values[index]) {
      case CalTab.day:
        c.setViewMode('day');
        break;
      case CalTab.week:
        c.setViewMode('week');
        break;
      case CalTab.month:
        c.setViewMode('month');
        break;
      case CalTab.agenda:
        c.setViewMode('agenda');
        break;
    }
  }
}
