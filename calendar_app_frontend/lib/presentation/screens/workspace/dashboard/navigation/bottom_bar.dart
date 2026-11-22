import 'package:hexora/theme/themes/navigation_tokens.dart';
import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/theme/components/themed_buttons.dart';
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
      state.group,
      state.user?.id,
      PremiumFeature.email,
    );
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
                      icon: Icon(emailAllowed
                          ? Icons.edit_outlined
                          : Icons.lock_outline_rounded),
                      label: Text(emailAllowed
                          ? l.mailComposeTitle
                          : (l.localeName.startsWith('es')
                              ? 'Solicitar correo premium'
                              : 'Request premium email')),
                      onPressed: emailAllowed
                          ? compose
                          : () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => PremiumFeatureRequestScreen(
                                    group: state.group,
                                    feature: PremiumFeatureRequest.email,
                                  ),
                                ),
                              ),
                    )
                  : FilledButton.icon(
                      style: primaryButtonStyle,
                      icon: const Icon(Icons.calendar_month_rounded,
                          size: NavigationTokens.iconSize),
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
