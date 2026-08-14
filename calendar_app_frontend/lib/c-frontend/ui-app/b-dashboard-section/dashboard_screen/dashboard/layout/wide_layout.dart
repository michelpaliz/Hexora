import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/notification/domain/notification_domain.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/dashboard/controller/group_dashboard_sections.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/widgets/group_dashboard_content.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/widgets/right_panel/members_section/group_dashboard_right_panel.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/enable_banking/enable_banking_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/expenses/gastos_module_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/presupuestos_module_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/mail/mail_console_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/telegram/telegram_section_screen.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/calendar/screen/main_calendar_view.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/user_profile_popup.dart';
import 'package:hexora/f-themes/app_colors/palette/app_colors/app_colors.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    final showBudgetsInline = kIsWeb && state.activeSection == Sections.budgets;
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
                  : showBudgetsInline
                      ? PresupuestosModuleScreen(
                          key: ValueKey(
                            'group-budgets-${state.group.id}-${state.activeSection}',
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

class _DashboardTopNav extends StatefulWidget {
  const _DashboardTopNav({
    required this.state,
    required this.l,
    required this.user,
  });

  final GroupDashboardState state;
  final AppLocalizations l;
  final User? user;

  @override
  State<_DashboardTopNav> createState() => _DashboardTopNavState();
}

class _DashboardTopNavState extends State<_DashboardTopNav> {
  static const _compactPreferenceKey = 'dashboard_top_nav_compact';
  bool _compact = true;

  @override
  void initState() {
    super.initState();
    _loadCompactPreference();
  }

  Future<void> _loadCompactPreference() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _compact = preferences.getBool(_compactPreferenceKey) ?? true;
    });
  }

  void _toggleCompact() {
    final next = !_compact;
    setState(() => _compact = next);
    SharedPreferences.getInstance().then(
      (preferences) => preferences.setBool(_compactPreferenceKey, next),
    );
  }

  String _shortLabel(String section, String fullLabel) {
    final l = widget.l;
    switch (section) {
      case Sections.calendar:
        return l.calendar;
      case Sections.services:
        return 'Servicios';
      case Sections.invoices:
        return l.localeName.startsWith('es') ? 'Ingresos' : 'Income';
      case Sections.budgets:
        return l.localeName.startsWith('es') ? 'Presup.' : 'Budgets';
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
    final state = widget.state;
    final l = widget.l;
    final user = widget.user;
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
        icon: Icons.description_outlined,
        label: l.localeName.startsWith('es') ? 'Presupuestos' : 'Budgets',
        section: Sections.budgets,
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

        final primaryItems = _compact
            ? allowedItems
                .map(
                  (i) => (
                    icon: i.icon,
                    label: _shortLabel(i.section, i.label),
                    section: i.section,
                    adminOnly: i.adminOnly,
                  ),
                )
                .toList()
            : isMediumWidth
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
            overflowItems = !_compact && isMediumWidth
                ? allowedItems
                    .where((i) => mediumOverflowSections.contains(i.section))
                    .toList()
                : <({
                    IconData icon,
                    String label,
                    String section,
                    bool adminOnly
                  })>[];

        return AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_compact ? 10 : 14),
            ),
            color: bg,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: _compact ? 12 : 26,
                vertical: _compact ? 4 : 12,
              ),
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
                          radius: _compact ? 14 : 16,
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
                        if (!_compact) ...[
                          const SizedBox(width: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 140),
                            child: Text(
                              state.group.name,
                              style:
                                  AppTypography.of(context).bodyMedium.copyWith(
                                        color: textColor,
                                        fontWeight: FontWeight.w800,
                                      ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Vertical divider
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: _compact ? 10 : 22),
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
                    child: _ScrollableTopNavItems(
                      isSpanish: l.localeName.startsWith('es'),
                      textColor: textColor,
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
                            compact: _compact,
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
                  Tooltip(
                    message: _compact
                        ? (l.localeName.startsWith('es')
                            ? 'Expandir navegacion'
                            : 'Expand navigation')
                        : (l.localeName.startsWith('es')
                            ? 'Compactar navegacion'
                            : 'Compact navigation'),
                    child: IconButton(
                      onPressed: _toggleCompact,
                      icon: Icon(
                        _compact
                            ? Icons.unfold_more_rounded
                            : Icons.unfold_less_rounded,
                        size: 18,
                        color: textColor.withValues(alpha: 0.62),
                      ),
                      visualDensity: VisualDensity.compact,
                      constraints:
                          const BoxConstraints.tightFor(width: 36, height: 36),
                    ),
                  ),
                  // User profile avatar
                  SizedBox(width: _compact ? 8 : 18),
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
          ),
        );
      },
    );
  }
}

class _ScrollableTopNavItems extends StatefulWidget {
  const _ScrollableTopNavItems({
    required this.children,
    required this.textColor,
    required this.isSpanish,
  });

  final List<Widget> children;
  final Color textColor;
  final bool isSpanish;

  @override
  State<_ScrollableTopNavItems> createState() => _ScrollableTopNavItemsState();
}

class _ScrollableTopNavItemsState extends State<_ScrollableTopNavItems> {
  final ScrollController _controller = ScrollController();
  bool _hasOverflow = false;
  bool _canScrollLeft = false;
  bool _canScrollRight = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_syncScrollState);
    _scheduleScrollStateSync();
  }

  @override
  void didUpdateWidget(covariant _ScrollableTopNavItems oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleScrollStateSync();
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_syncScrollState)
      ..dispose();
    super.dispose();
  }

  void _scheduleScrollStateSync() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncScrollState();
    });
  }

  void _syncScrollState() {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    final hasOverflow = position.maxScrollExtent > 0.5;
    final canScrollLeft = position.pixels > 0.5;
    final canScrollRight = position.pixels < position.maxScrollExtent - 0.5;
    if (_hasOverflow == hasOverflow &&
        _canScrollLeft == canScrollLeft &&
        _canScrollRight == canScrollRight) {
      return;
    }
    setState(() {
      _hasOverflow = hasOverflow;
      _canScrollLeft = canScrollLeft;
      _canScrollRight = canScrollRight;
    });
  }

  void _scrollBy(double delta) {
    if (!_controller.hasClients) return;
    final target = (_controller.offset + delta)
        .clamp(0.0, _controller.position.maxScrollExtent)
        .toDouble();
    _controller.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !_controller.hasClients) return;
    if (event.scrollDelta.dy.abs() <= event.scrollDelta.dx.abs()) return;
    _scrollBy(event.scrollDelta.dy);
  }

  @override
  Widget build(BuildContext context) {
    _scheduleScrollStateSync();
    return Row(
      children: [
        if (_hasOverflow)
          _scrollButton(
            icon: Icons.chevron_left_rounded,
            tooltip: widget.isSpanish
                ? 'Ver opciones anteriores'
                : 'View previous options',
            enabled: _canScrollLeft,
            onPressed: () => _scrollBy(-260),
          ),
        Expanded(
          child: Listener(
            onPointerSignal: _handlePointerSignal,
            child: SingleChildScrollView(
              controller: _controller,
              scrollDirection: Axis.horizontal,
              child: Row(children: widget.children),
            ),
          ),
        ),
        if (_hasOverflow)
          _scrollButton(
            icon: Icons.chevron_right_rounded,
            tooltip:
                widget.isSpanish ? 'Ver mas opciones' : 'View more options',
            enabled: _canScrollRight,
            onPressed: () => _scrollBy(260),
          ),
      ],
    );
  }

  Widget _scrollButton({
    required IconData icon,
    required String tooltip,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 18),
      color: widget.textColor.withValues(alpha: 0.72),
      disabledColor: widget.textColor.withValues(alpha: 0.20),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 30, height: 36),
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
    this.compact = false,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final Color activeColor;
  final Color textColor;
  final int? unreadCount;
  final bool? attention;
  final bool compact;
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
      padding: EdgeInsets.only(right: widget.compact ? 4 : 8),
      child: TooltipVisibility(
        visible: widget.compact,
        child: Tooltip(
          message: widget.label,
          child: MouseRegion(
            onEnter: (_) => setState(() => _hovering = true),
            onExit: (_) => setState(() => _hovering = false),
            child: GestureDetector(
              onTap: widget.onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOut,
                padding: EdgeInsets.symmetric(
                  horizontal: widget.compact ? 10 : 12,
                  vertical: widget.compact ? 7 : 8,
                ),
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
                    if (!widget.compact || widget.isSelected) ...[
                      const SizedBox(width: 7),
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
