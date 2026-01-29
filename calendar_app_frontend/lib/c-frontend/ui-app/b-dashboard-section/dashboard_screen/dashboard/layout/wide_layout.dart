import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/widgets/group_dashboard_content.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/widgets/right_panel/members_section/group_dashboard_right_panel.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/enable_banking/enable_banking_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/mail/mail_console_screen.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/calendar/screen/main_calendar_view.dart';

import '../controller/group_dashboard_state.dart';

class WideLayout extends StatelessWidget {
  final GroupDashboardState state;
  const WideLayout({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final state = this.state;
    final rightFlex = state.isUltraWide ? 3 : 2;
    final showMainBody = !kIsWeb;
    final showCalendarInline = kIsWeb && state.activeSection == 'calendar';
    final showInvoicesInline = kIsWeb && state.activeSection == 'invoices';
    final showEmailsInline = state.activeSection == 'emails';
    final showEnableBankingInline =
        kIsWeb && state.activeSection == 'enableBanking';

    if (showEmailsInline) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1800),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: const MailConsoleScreen(embedded: true),
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1800),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showMainBody) ...[
                Expanded(
                  flex: 2,
                  child: GroupDashboardContent(
                    panelBg: state.backdrop,
                    child: state.dashboardBody,
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                flex: showMainBody ? rightFlex : 1,
                child: showCalendarInline
                    ? MainCalendarView(
                        group: state.group,
                        embedded: true,
                        onActionsReady: state.setCalendarActions,
                      )
                    : showInvoicesInline
                        ? GroupInvoicesScreen(
                            group: state.group,
                            embedded: true,
                          )
                        : showEmailsInline
                            ? const MailConsoleScreen(embedded: true)
                            : showEnableBankingInline
                                ? EnableBankingScreen(
                                    group: state.group,
                                    embedded: true,
                                  )
                                : GroupDashboardRightPanel(
                                    activeAnchor: state.activeSection,
                                    counts: state.counts,
                                    group: state.group,
                                    user: state.user,
                                    role: state.role,
                                    fetchReadSas: state.fetchReadSas,
                                    usersInGroup: const [],
                                    onOpenCalendar: () =>
                                        state.openSection('calendar'),
                                    onOpenNotifications: () =>
                                        state.openSection('notifications'),
                                    onOpenSettings: () =>
                                        state.openSection('settings'),
                                  ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
