import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/dashboard/controller/group_dashboard_sections.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/widgets/group_dashboard_content.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/widgets/right_panel/members_section/group_dashboard_right_panel.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/enable_banking/enable_banking_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/mail/mail_console_screen.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/calendar/screen/main_calendar_view.dart';
import 'package:hexora/f-themes/app_colors/palette/app_colors/app_colors.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

import '../controller/group_dashboard_state.dart';

class WideLayout extends StatelessWidget {
  const WideLayout({super.key, required this.state});
  final GroupDashboardState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1800),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
          child: Column(
            children: [
              // ── Horizontal top nav ───────────────────────
              _DashboardTopNav(state: state, l: l),
              const SizedBox(height: 10),
              // ── Content ──────────────────────────────────
              Expanded(child: _buildContent(state, context, l)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
      GroupDashboardState state, BuildContext context, AppLocalizations l) {
    const showMainBody = !kIsWeb;
    final showCalendarInline = kIsWeb && state.activeSection == 'calendar';
    final showInvoicesInline = kIsWeb && state.activeSection == 'invoices';
    final showEmailsInline = state.activeSection == 'emails';
    final showEnableBankingInline =
        kIsWeb && state.activeSection == 'enableBanking';

    if (showEmailsInline) {
      return const MailConsoleScreen(embedded: true);
    }

    return Row(
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
          flex: showMainBody ? (state.isUltraWide ? 3 : 2) : 1,
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Horizontal top navigation bar
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardTopNav extends StatelessWidget {
  const _DashboardTopNav({required this.state, required this.l});

  final GroupDashboardState state;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppDarkColors.textPrimary : AppColors.textPrimary;
    final activeColor = isDark ? AppDarkColors.primary : AppColors.primary;
    final bg = ThemeColors.cardBg(context);

    final sectionItems = [
      (
        icon: Icons.calendar_month_rounded,
        label: l.calendar,
        section: Sections.calendar,
        adminOnly: false,
      ),
      (
        icon: Icons.design_services_outlined,
        label: l.servicesClientsTitle,
        section: Sections.services,
        adminOnly: false,
      ),
      (
        icon: Icons.receipt_long_outlined,
        label: l.invoicesNavLabel,
        section: Sections.invoices,
        adminOnly: true,
      ),
      (
        icon: Icons.email_outlined,
        label: 'Emails',
        section: Sections.emails,
        adminOnly: true,
      ),
      (
        icon: Icons.account_balance_outlined,
        label: l.statementsNavTitle,
        section: 'enableBanking',
        adminOnly: true,
      ),
      (
        icon: Icons.access_time_rounded,
        label: l.timeTrackingTitle,
        section: Sections.workers,
        adminOnly: false,
      ),
      (
        icon: Icons.tune_rounded,
        label: l.groupSettingsTitle,
        section: Sections.settings,
        adminOnly: true,
      ),
    ];

    final visibleItems = sectionItems
        .where((i) => !i.adminOnly || state.canSeeAdmin)
        .toList();

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: bg,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            // Group avatar + name
            GestureDetector(
              onTap: state.canSeeAdmin
                  ? () => state.openSection(Sections.settings)
                  : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: textColor.withValues(alpha: 0.12),
                    backgroundImage:
                        state.group.photoUrl?.trim().isNotEmpty == true
                            ? NetworkImage(state.group.photoUrl!.trim())
                            : null,
                    child: state.group.photoUrl?.trim().isNotEmpty == true
                        ? null
                        : Icon(
                            Icons.business_rounded,
                            color: textColor.withValues(alpha: 0.65),
                            size: 16,
                          ),
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 140),
                    child: Text(
                      state.group.name,
                      style: AppTypography.of(context).bodyMedium.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w800,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Vertical divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                height: 28,
                child: VerticalDivider(
                  thickness: 1,
                  color: textColor.withValues(alpha: 0.15),
                ),
              ),
            ),
            // Scrollable nav items
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: visibleItems
                      .map(
                        (item) => _TopNavItem(
                          icon: item.icon,
                          label: item.label,
                          isSelected: state.activeSection == item.section,
                          activeColor: activeColor,
                          textColor: textColor,
                          onTap: () => state.openSection(item.section),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            // Back to groups
            const SizedBox(width: 4),
            Tooltip(
              message: l.groupSectionTitle,
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  size: 18,
                  color: textColor.withValues(alpha: 0.5),
                ),
                splashRadius: 18,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single nav item in the horizontal bar
// ─────────────────────────────────────────────────────────────────────────────

class _TopNavItem extends StatefulWidget {
  const _TopNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.textColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final Color activeColor;
  final Color textColor;
  final VoidCallback onTap;

  @override
  State<_TopNavItem> createState() => _TopNavItemState();
}

class _TopNavItemState extends State<_TopNavItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final showHighlight = widget.isSelected || _hovering;
    final fg = widget.isSelected
        ? widget.activeColor
        : widget.textColor.withValues(alpha: _hovering ? 0.85 : 0.6);

    return Padding(
      padding: const EdgeInsets.only(right: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: showHighlight
                  ? widget.activeColor.withValues(alpha: 0.10)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 15, color: fg),
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  style: t.bodySmall.copyWith(
                    color: fg,
                    fontWeight: widget.isSelected
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
