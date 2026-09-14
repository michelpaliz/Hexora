import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';

import '../controller/group_dashboard_sections.dart';
import '../controller/group_dashboard_state.dart';

class BottomBar extends StatelessWidget {
  final GroupDashboardState state;
  const BottomBar({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isEmailSection = state.activeSection == Sections.emails;
    final compose = state.mailBarActions?.onCompose;

    return DecoratedBox(
      decoration: BoxDecoration(color: state.backdrop),
      child: SafeArea(
        minimum: const EdgeInsets.fromLTRB(12, 6, 12, 22),
        child: Row(
          children: [
            Expanded(
              child: isEmailSection
                  ? FilledButton.icon(
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(l.mailComposeTitle),
                      onPressed: compose,
                    )
                  : FilledButton.icon(
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
