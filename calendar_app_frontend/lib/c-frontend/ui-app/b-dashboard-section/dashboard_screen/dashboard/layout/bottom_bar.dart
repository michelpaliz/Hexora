import 'package:hexora/c-frontend/ui-app/shared/widgets/insights_chat_fab.dart';
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
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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
                      style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48)),
                      icon: const Icon(Icons.calendar_month_rounded),
                      label: Text(l.goToCalendar),
                      onPressed: () => state.openSection('calendar'),
                    ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 48,
              height: 48,
              child: InsightsChatFab(
                groupId: state.group.id,
                heroTag: 'group-dashboard-insights-chat-fab',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
