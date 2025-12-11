import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';

import '../controller/group_dashboard_state.dart';

class BottomBar extends StatelessWidget {
  final GroupDashboardState state;
  const BottomBar({super.key, required this.state});

  @override
/*************  ✨ Windsurf Command ⭐  *************/
/// Builds a bottom bar with a single button to navigate to the calendar.
///
/// The button is labeled with the localized text "Go to calendar".
///
/// The background color of the bar is determined by the [state.backdrop] property.
///
/// and 6px on the top and 22px on the bottom side.
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return DecoratedBox(
      decoration: BoxDecoration(color: state.backdrop),
      child: SafeArea(
        minimum: const EdgeInsets.fromLTRB(12, 6, 12, 22),
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                icon: const Icon(Icons.calendar_month_rounded),
                label: Text(l.goToCalendar),
                onPressed: () => state.openSection('calendar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
