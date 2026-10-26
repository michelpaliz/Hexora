import 'package:hexora/theme/themes/navigation_tokens.dart';
import 'package:hexora/presentation/shared/widgets/insights_chat_fab.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/theme/components/themed_buttons.dart';

import 'dashboard_sections.dart';
import '../state/group_dashboard_state.dart';

class BottomBar extends StatelessWidget {
  final GroupDashboardState state;
  const BottomBar({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isEmailSection = state.activeSection == Sections.emails;
    final compose = state.mailBarActions?.onCompose;
    final primaryButtonStyle = ThemedButtons.button(context);

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
                      style: primaryButtonStyle,
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(l.mailComposeTitle),
                      onPressed: compose,
                    )
                  : FilledButton.icon(
                      style: primaryButtonStyle,
                      icon: const Icon(Icons.calendar_month_rounded,
                          size: NavigationTokens.iconSize),
                      label: Text(l.goToCalendar),
                      onPressed: () => state.openSection('calendar'),
                    ),
            ),
            if (!kIsWeb) ...[
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
          ],
        ),
      ),
    );
  }
}
