import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/notification/domain/notification_domain.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/dashboard/controller/group_dashboard_sections.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/widgets/group_dashboard_content.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/widgets/right_panel/members_section/group_dashboard_right_panel.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/enable_banking/enable_banking_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/expenses/gastos_module_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/mail/mail_console_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/telegram/telegram_section_screen.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/calendar/screen/main_calendar_view.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/user_profile_popup.dart';
import 'package:hexora/f-themes/app_colors/palette/app_colors/app_colors.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

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
              _DashboardTopNav(state: state, l: l, user: state.user),
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
    final showExpensesInline =
        kIsWeb && state.activeSection == Sections.expenses;
    final showEmailsInline = state.activeSection == 'emails';
    final showEnableBankingInline =
        kIsWeb && state.activeSection == 'enableBanking';
    final showTelegramInline = state.activeSection == 'telegram';

    if (showEmailsInline) {
      return const MailConsoleScreen(embedded: true);
    }

    if (showTelegramInline) {
      return const TelegramSectionScreen();
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
                      key: ValueKey(
                        'group-invoices-${state.group.id}-${state.activeSection}',
                      ),
                      group: state.group,
                      embedded: true,
                    )
                  : showExpensesInline
                      ? GastosModuleScreen(
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
  const _DashboardTopNav({
    required this.state,
    required this.l,
    required this.user,
  });

  final GroupDashboardState state;
  final AppLocalizations l;
  final User? user;

  String _shortLabel(String section, String fullLabel) {
    switch (section) {
      case Sections.calendar:
        return l.calendar;
      case Sections.services:
        return 'Servicios';
      case Sections.invoices:
        return l.localeName.startsWith('es') ? 'Ingresos' : 'Income';
      case Sections.expenses:
        return l.localeName.startsWith('es') ? 'Gastos' : 'Expenses';
      case Sections.emails:
        return 'Emails';
      case Sections.chat:
        return 'Chat';
      case 'enableBanking':
        return 'Banco';
      case Sections.telegram:
        return 'Telegram';
      case Sections.workers:
        return 'Tiempo';
      case Sections.settings:
        return 'Ajustes';
      case Sections.notifications:
        return 'Notif.';
      default:
        return fullLabel;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppDarkColors.textPrimary : AppColors.textPrimary;
    final activeColor = isDark ? AppDarkColors.primary : AppColors.primary;
    final bg = ThemeColors.cardBg(context);
    final unreadNotifications = context
        .watch<NotificationDomain>()
        .notifications
        .where((n) => !n.isRead)
        .length;

    final sectionItems = [
      (
        icon: Icons.calendar_month_rounded,
        label: l.calendar,
        section: Sections.calendar,
        adminOnly: false,
      ),
      (
        icon: Icons.design_services_outlined,
        label: l.localeName.startsWith('es') ? 'Operaciones' : 'Operations',
        section: Sections.services,
        adminOnly: false,
      ),
      (
        icon: Icons.receipt_long_outlined,
        label: l.localeName.startsWith('es') ? 'Ingresos' : 'Income',
        section: Sections.invoices,
        adminOnly: true,
      ),
      (
        icon: Icons.trending_down_rounded,
        label: l.localeName.startsWith('es') ? 'Gastos' : 'Expenses',
        section: Sections.expenses,
        adminOnly: true,
      ),
      (
        icon: Icons.email_outlined,
        label: 'Emails',
        section: Sections.emails,
        adminOnly: true,
      ),
      (
        icon: Icons.chat_bubble_outline_rounded,
        label: 'Chat',
        section: Sections.chat,
        adminOnly: false,
      ),
      (
        icon: Icons.account_balance_outlined,
        label: l.statementsNavTitle,
        section: 'enableBanking',
        adminOnly: true,
      ),
      (
        icon: Icons.telegram,
        label: 'Telegram',
        section: Sections.telegram,
        adminOnly: true,
      ),
      (
        icon: Icons.access_time_rounded,
        label: l.localeName.startsWith('es') ? 'Trabajadores' : 'Workers',
        section: Sections.workers,
        adminOnly: false,
      ),
      (
        icon: Icons.tune_rounded,
        label: l.localeName.startsWith('es') ? 'Ajustes' : 'Settings',
        section: Sections.settings,
        adminOnly: true,
      ),
      (
        icon: unreadNotifications > 0
            ? Icons.notifications_active_rounded
            : Icons.notifications_none_rounded,
        label: l.notifications,
        section: Sections.notifications,
        adminOnly: false,
      ),
    ];

    final allowedItems =
        sectionItems.where((i) => !i.adminOnly || state.canSeeAdmin).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isMediumWidth = width >= 1180 && width < 1380;

        final mediumOverflowSections = <String>{
          Sections.settings,
          Sections.notifications,
        };

        final primaryItems = isMediumWidth
            ? allowedItems
                .where((i) => !mediumOverflowSections.contains(i.section))
                .map(
                  (i) => (
                    icon: i.icon,
                    label: _shortLabel(i.section, i.label),
                    section: i.section,
                    adminOnly: i.adminOnly,
                  ),
                )
                .toList()
            : allowedItems;

        final List<
                ({IconData icon, String label, String section, bool adminOnly})>
            overflowItems = isMediumWidth
                ? allowedItems
                    .where((i) => mediumOverflowSections.contains(i.section))
                    .toList()
                : <({
                    IconData icon,
                    String label,
                    String section,
                    bool adminOnly
                  })>[];

        return Card(
          elevation: 1,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          color: bg,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
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
                  padding: const EdgeInsets.symmetric(horizontal: 22),
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
                      children: <Widget>[
                        ...primaryItems.map(
                          (item) => _TopNavItem(
                            icon: item.icon,
                            label: item.label,
                            isSelected: state.activeSection == item.section,
                            activeColor: activeColor,
                            textColor: textColor,
                            unreadCount: item.section == Sections.notifications
                                ? unreadNotifications
                                : 0,
                            attention: item.section == Sections.notifications &&
                                unreadNotifications > 0,
                            onTap: () => state.openSection(item.section),
                          ),
                        ),
                        if (overflowItems.isNotEmpty)
                          _TopNavOverflowMenu(
                            items: overflowItems,
                            textColor: textColor,
                            activeColor: activeColor,
                            unreadNotifications: unreadNotifications,
                            activeSection: state.activeSection,
                            onOpenSection: state.openSection,
                          ),
                      ],
                    ),
                  ),
                ),
                // User profile avatar
                const SizedBox(width: 18),
                UserProfilePopup(user: user),
                const SizedBox(width: 12),
                // Back to groups
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
      },
    );
  }
}

class _TopNavOverflowMenu extends StatelessWidget {
  const _TopNavOverflowMenu({
    required this.items,
    required this.textColor,
    required this.activeColor,
    required this.unreadNotifications,
    required this.activeSection,
    required this.onOpenSection,
  });

  final List<({IconData icon, String label, String section, bool adminOnly})>
      items;
  final Color textColor;
  final Color activeColor;
  final int unreadNotifications;
  final String activeSection;
  final ValueChanged<String> onOpenSection;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    return PopupMenuButton<String>(
      tooltip: 'More',
      onSelected: onOpenSection,
      itemBuilder: (_) => items
          .map(
            (item) => PopupMenuItem<String>(
              value: item.section,
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(item.icon, size: 16),
                      if (item.section == Sections.notifications &&
                          unreadNotifications > 0)
                        Positioned(
                          right: -6,
                          top: -6,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Text(item.label),
                ],
              ),
            ),
          )
          .toList(),
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: items.any((i) => i.section == activeSection)
              ? activeColor.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.more_horiz_rounded, size: 16, color: textColor),
            const SizedBox(width: 4),
            Text(
              'More',
              style: t.bodySmall.copyWith(
                color: textColor.withValues(alpha: 0.75),
                fontWeight: FontWeight.w600,
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
    this.unreadCount = 0,
    this.attention = false,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final Color activeColor;
  final Color textColor;
  final int? unreadCount;
  final bool? attention;
  final VoidCallback onTap;

  @override
  State<_TopNavItem> createState() => _TopNavItemState();
}

class _TopNavItemState extends State<_TopNavItem>
    with TickerProviderStateMixin {
  bool _hovering = false;
  late final AnimationController _attentionController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _attentionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _syncAttentionAnimation();
  }

  @override
  void didUpdateWidget(covariant _TopNavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.attention != widget.attention ||
        oldWidget.unreadCount != widget.unreadCount ||
        oldWidget.isSelected != widget.isSelected) {
      _syncAttentionAnimation();
    }
  }

  void _syncAttentionAnimation() {
    final shouldAnimate = (widget.attention ?? false) &&
        (widget.unreadCount ?? 0) > 0 &&
        !widget.isSelected;
    if (shouldAnimate) {
      if (!_attentionController.isAnimating) {
        _attentionController.repeat();
      }
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
      return;
    }
    _attentionController.stop();
    _attentionController.value = 0;
    _pulseController.stop();
    _pulseController.value = 0;
  }

  @override
  void dispose() {
    _attentionController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final showHighlight = widget.isSelected || _hovering;
    final fg = widget.isSelected
        ? widget.activeColor
        : widget.textColor.withValues(alpha: _hovering ? 0.85 : 0.6);

    final cs = Theme.of(context).colorScheme;
    final hasUnread = (widget.unreadCount ?? 0) > 0;

    final icon = Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(widget.icon, size: 15, color: fg),
        if (hasUnread) ...[
          // Radiating ring
          Positioned(
            right: -9,
            top: -9,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) {
                final scale = Tween<double>(begin: 1.0, end: 1.8).evaluate(
                  CurvedAnimation(
                      parent: _pulseController, curve: Curves.easeOut),
                );
                final opacity = Tween<double>(begin: 0.45, end: 0.0).evaluate(
                  CurvedAnimation(
                      parent: _pulseController, curve: Curves.easeOut),
                );
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.error.withValues(alpha: opacity),
                    ),
                  ),
                );
              },
            ),
          ),
          // Badge with pulse scale
          Positioned(
            right: -7,
            top: -7,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (_, child) => Transform.scale(
                scale: Tween<double>(begin: 0.92, end: 1.08).evaluate(
                  CurvedAnimation(
                      parent: _pulseController, curve: Curves.easeInOut),
                ),
                child: child,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                decoration: BoxDecoration(
                  color: cs.error,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: cs.error.withValues(alpha: 0.45),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    (widget.unreadCount ?? 0) > 9
                        ? '9+'
                        : (widget.unreadCount ?? 0).toString(),
                    style: t.bodySmall.copyWith(
                      color: cs.onError,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: showHighlight
                  ? widget.activeColor.withValues(alpha: 0.10)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _attentionController,
                  builder: (_, child) {
                    final phase = _attentionController.value * 2 * math.pi;
                    final dx = math.sin(phase) * 1.8;
                    final rotation = math.sin(phase) * 0.06;
                    return Transform.translate(
                      offset: Offset(dx, 0),
                      child: Transform.rotate(
                        angle: rotation,
                        child: child,
                      ),
                    );
                  },
                  child: icon,
                ),
                const SizedBox(width: 7),
                Text(
                  widget.label,
                  style: t.bodySmall.copyWith(
                    color: fg,
                    fontWeight:
                        widget.isSelected ? FontWeight.w700 : FontWeight.w500,
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
