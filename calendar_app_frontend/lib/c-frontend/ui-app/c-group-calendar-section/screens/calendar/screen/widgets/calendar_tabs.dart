// c-frontend/c-group-calendar-section/screens/calendar/widgets/calendar_tabs.dart
import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
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
    final iconSize = large ? 20.0 : 18.0;
    return const [
      // We pass text; fonts/colors come from TabBarTheme above.
      Tab(text: '___DAY___', icon: Icon(Icons.today_outlined)),
      Tab(text: '___WEEK___', icon: Icon(Icons.view_week_outlined)),
      Tab(
          text: '___MONTH___',
          icon: Icon(Icons.calendar_month_outlined)),
      Tab(text: '___AGENDA___', icon: Icon(Icons.list_alt_outlined)),
    ].map((t) {
      // Replace placeholders with localized strings at build time
      String label;
      switch (t.text) {
        case '___DAY___':
          label = loc.tabDay;
          break;
        case '___WEEK___':
          label = loc.tabWeek;
          break;
        case '___MONTH___':
          label = loc.tabMonth;
          break;
        case '___AGENDA___':
          label = loc.tabAgenda;
          break;
        default:
          label = t.text ?? '';
      }
      return Tab(
        text: label,
        icon: t.icon != null
            ? Icon(
                (t.icon! as Icon).icon,
                size: iconSize,
              )
            : null,
      );
    }).toList(growable: false);
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
