import 'package:hexora/presentation/shared/widgets/insights_chat_fab.dart';
import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/presentation/screens/workspace/premium/premium_feature_access.dart';
import 'package:hexora/presentation/screens/workspace/premium/premium_feature_request_screen.dart';

import 'dashboard_sections.dart';
import '../state/group_dashboard_state.dart';

class BottomBar extends StatelessWidget {
  final GroupDashboardState state;
  const BottomBar({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isEmailSection = state.activeSection == Sections.emails;
    final emailAllowed = canManagePremiumFeature(
      state.group, state.user?.id, PremiumFeature.email);
    final compose = state.mailBarActions?.onCompose;

    return DecoratedBox(
      decoration: BoxDecoration(color: state.backdrop),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: isEmailSection && !emailAllowed
                  ? FilledButton.icon(
                      icon: const Icon(Icons.lock_outline_rounded),
                      label: Text(l.localeName.startsWith('es')
                          ? 'Solicitar correo premium' : 'Request premium email'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PremiumFeatureRequestScreen(
                            group: state.group,
                            feature: PremiumFeatureRequest.email,
                          ),
                        ),
                      ),
                    )
                  : isEmailSection
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
            if (state.canSeeAdmin) ...[
              const SizedBox(width: 12),
              SizedBox(
                width: 48,
                height: 48,
                child: InsightsChatFab(
                  groupId: state.group.id,
                  group: state.group,
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
