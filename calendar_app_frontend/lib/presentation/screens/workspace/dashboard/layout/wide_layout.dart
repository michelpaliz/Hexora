import 'package:hexora/presentation/screens/agenda/agenda_screen.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hexora/navigation/shell/hexora_app_shell.dart';
import 'package:hexora/navigation/shell/hexora_global_nav_bar.dart';
import 'package:hexora/navigation/shell/hexora_nav_components.dart';
import 'package:hexora/navigation/shell/worker_status_indicator.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/models/user/user.dart';
import 'package:hexora/presentation/routes/app_routes.dart';
import 'package:hexora/services/groups/domain/group_domain.dart';
import 'package:hexora/theme/themes/navigation_tokens.dart';
import 'package:hexora/services/notification/domain/notification_domain.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/navigation/dashboard_sections.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/layout/group_dashboard_content.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/panels/group_dashboard_right_panel.dart';
import 'package:hexora/presentation/screens/workspace/sections/enable_banking/enable_banking_screen.dart';
import 'package:hexora/presentation/screens/workspace/sections/expenses/gastos_module_screen.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/group_invoices_screen.dart';
import 'package:hexora/presentation/screens/workspace/sections/presupuestos/presupuestos_module_screen.dart';
import 'package:hexora/presentation/screens/workspace/sections/mail/mail_console_screen.dart';
import 'package:hexora/presentation/screens/workspace/sections/maps/client_map_screen.dart';
import 'package:hexora/presentation/screens/workspace/sections/telegram/telegram_section_screen.dart';
import 'package:hexora/presentation/screens/calendar/screens/calendar/screen/main_calendar_view.dart';
import 'package:hexora/presentation/shared/widgets/user_profile_popup.dart';
import 'package:hexora/presentation/utils/roles/group_role_labels.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../state/group_dashboard_state.dart';

class WideLayout extends StatelessWidget {
  const WideLayout({super.key, required this.state});
  final GroupDashboardState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    String? moduleLabel;
    for (final d in _dashboardDestinations(l, canSeeAdmin: state.canSeeAdmin)) {
      if (d.id == state.activeSection) moduleLabel = d.label;
    }

    return HexoraAppShell(
      globalNav: _DashboardTopNav(state: state, l: l, user: state.user),
      moduleLabel: moduleLabel,
      body: _buildContent(state, context, l),
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
    final showMapInline = state.activeSection == Sections.maps;
    final showEmailsInline = state.activeSection == 'emails';
    final showEnableBankingInline =
        kIsWeb && state.activeSection == 'enableBanking';
    final showTelegramInline = state.activeSection == 'telegram';

    if (state.activeSection == Sections.agenda) {
      return AgendaScreen(groupId: state.group.id, embedded: true);
    }

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
                        'group-invoices-${state.group.id}-${state.invoicesNavigationRevision}',
                      ),
                      group: state.group,
                      embedded: true,
                      initialMenu: state.invoicesInitialMenu,
                      initialInvoiceId: state.invoicesInitialInvoiceId,
                      initialReceiptId: state.invoicesInitialReceiptId,
                      initialBudgetId: state.invoicesInitialBudgetId,
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
                          : showMapInline
                              ? ClientMapScreen(
                                  key: ValueKey(
                                    'group-map-${state.group.id}-${state.activeSection}',
                                  ),
                                  group: state.group,
                                  embedded: true,
                                  canEdit: state.canSeeAdmin,
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
                                          onOpenNotifications: () => state
                                              .openSection('notifications'),
                                          onOpenSettings: () =>
                                              state.openSection('settings'),
                                        ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Global navigation (adapter over the shared HexoraGlobalNavBar)
// ─────────────────────────────────────────────────────────────────────────────

/// Workspace modules shown in the global bar. Rarely used modules are grouped
/// under "More"; notifications get a dedicated bell but stay searchable.
List<HexoraNavDestination> _dashboardDestinations(
  AppLocalizations l, {
  required bool canSeeAdmin,
}) {
  final es = l.localeName.startsWith('es');
  return [
    HexoraNavDestination(
      id: Sections.calendar,
      icon: Icons.calendar_month_rounded,
      label: l.calendar,
    ),
    HexoraNavDestination(
      id: Sections.services,
      icon: Icons.design_services_outlined,
      label: es ? 'Operaciones' : 'Operations',
    ),
    HexoraNavDestination(
      id: Sections.maps,
      icon: Icons.map_outlined,
      label: es ? 'Mapa' : 'Map',
    ),
    if (canSeeAdmin) ...[
      HexoraNavDestination(
        id: Sections.invoices,
        icon: Icons.receipt_long_outlined,
        label: es ? 'Ingresos' : 'Income',
      ),
      HexoraNavDestination(
        id: Sections.budgets,
        icon: Icons.description_outlined,
        label: es ? 'Propuestas' : 'Proposals',
      ),
      HexoraNavDestination(
        id: Sections.expenses,
        icon: Icons.trending_down_rounded,
        label: es ? 'Gastos' : 'Expenses',
      ),
      const HexoraNavDestination(
        id: Sections.emails,
        icon: Icons.email_outlined,
        label: 'Emails',
      ),
    ],
    const HexoraNavDestination(
      id: Sections.chat,
      icon: Icons.chat_bubble_outline_rounded,
      label: 'Chat',
    ),
    HexoraNavDestination(
      id: Sections.workers,
      icon: Icons.access_time_rounded,
      label: es ? 'Trabajadores' : 'Workers',
    ),
    if (canSeeAdmin) ...[
      HexoraNavDestination(
        id: Sections.enableBanking,
        icon: Icons.account_balance_outlined,
        label: l.statementsNavTitle,
        placement: HexoraNavPlacement.more,
      ),
      const HexoraNavDestination(
        id: Sections.telegram,
        icon: Icons.telegram,
        label: 'Telegram',
        placement: HexoraNavPlacement.more,
      ),
      HexoraNavDestination(
        id: Sections.settings,
        icon: Icons.settings_outlined,
        label: es ? 'Ajustes' : 'Settings',
        placement: HexoraNavPlacement.more,
      ),
    ],
    HexoraNavDestination(
      id: Sections.notifications,
      icon: Icons.notifications_none_rounded,
      label: l.notifications,
      placement: HexoraNavPlacement.searchOnly,
    ),
  ];
}

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
  static const _compactPreferenceKey = 'dashboard_top_nav_compact_v2';
  bool _compact = false;

  @override
  void initState() {
    super.initState();
    _loadCompactPreference();
  }

  Future<void> _loadCompactPreference() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _compact = preferences.getBool(_compactPreferenceKey) ?? false;
    });
  }

  void _toggleCompact() {
    final next = !_compact;
    setState(() => _compact = next);
    SharedPreferences.getInstance().then(
      (preferences) => preferences.setBool(_compactPreferenceKey, next),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final l = widget.l;
    final user = widget.user;
    final es = l.localeName.startsWith('es');
    const textColor = HexoraGlobalNavColors.foreground;
    final unreadNotifications = context
        .watch<NotificationDomain>()
        .notifications
        .where((n) => n.groupId == state.group.id && !n.isRead)
        .length;
    final memberIds = {...state.group.userIds, state.group.ownerId}..remove('');

    return HexoraGlobalNavBar(
      destinations: _dashboardDestinations(l, canSeeAdmin: state.canSeeAdmin),
      activeId: state.activeSection,
      onSelected: state.openSection,
      onBrandTap:
          state.canSeeAdmin ? () => state.openSection(Sections.settings) : null,
      brandTooltip: es ? 'Ajustes del espacio' : 'Workspace settings',
      groupSwitcher: _GroupSwitcherChip(
        activeGroup: state.group,
        userId: user?.id ?? '',
        onOpenGroupSettings: () => state.openSection(Sections.settings),
      ),
      compact: _compact,
      onToggleCompact: _toggleCompact,
      notificationCount: unreadNotifications,
      notificationsSelected: state.activeSection == Sections.notifications,
      onOpenNotifications: () => state.openSection(Sections.notifications),
      onlineMembers: WorkerStatusIndicator(
        groupId: state.group.id,
        memberIds: memberIds.toList(),
        groupRoles: state.group.userRoles,
        onOpenWorkers: () {
          Navigator.pushNamed(
            context,
            AppRoutes.groupTimeTracking,
            arguments: state.group,
          );
        },
      ),
      profile: UserProfilePopup(
        user: user,
        onSettings: () => state.openSection('settings'),
      ),
      profileDetails: user == null
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user.displayName?.isNotEmpty == true
                      ? user.displayName!
                      : user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.of(context)
                      .bodySmall
                      .copyWith(color: textColor, fontWeight: FontWeight.w600),
                ),
                if (state.role != null)
                  Text(
                    roleLabelOf(context, state.role!),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.of(context)
                        .caption
                        .copyWith(color: textColor.withValues(alpha: 0.7)),
                  ),
              ],
            ),
      onBack: () => Navigator.of(context).maybePop(),
      backTooltip: l.groupSectionTitle,
    );
  }
}

// ── Group / workspace switcher ────────────────────────────────────────────────

class _GroupSwitcherChip extends StatelessWidget {
  const _GroupSwitcherChip({
    required this.activeGroup,
    required this.userId,
    required this.onOpenGroupSettings,
  });

  final Group activeGroup;
  final String userId;
  final VoidCallback onOpenGroupSettings;

  static const double _nameBreakpoint = 1100;
  static const double _chipMaxNameWidth = 140.0;

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    return parts.length == 1
        ? parts.first[0].toUpperCase()
        : (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Widget _avatar(Group group, double size) {
    final photoUrl = group.computedPhotoUrl ?? group.photoUrl;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          photoUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initialsAvatar(group, size),
        ),
      );
    }
    return _initialsAvatar(group, size);
  }

  Widget _initialsAvatar(Group group, double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0x26FFFFFF), // foreground @ 15 % alpha
      ),
      alignment: Alignment.center,
      child: Text(
        _initials(group.name),
        style: TextStyle(
          fontSize: size * 0.38,
          fontWeight: FontWeight.w700,
          color: HexoraGlobalNavColors.foreground,
          fontFamily: 'Inter',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showName = MediaQuery.sizeOf(context).width >= _nameBreakpoint;
    final groupDomain = context.watch<GroupDomain>();
    final es = Localizations.localeOf(context).languageCode == 'es';

    return StreamBuilder<List<Group>>(
      stream: userId.isNotEmpty
          ? groupDomain.watchGroupsForUser(userId)
          : const Stream.empty(),
      builder: (context, snap) {
        final groups = snap.data ?? [activeGroup];
        final cs = Theme.of(context).colorScheme;

        return MenuAnchor(
          alignmentOffset: const Offset(0, 6),
          style: hexoraDropdownMenuStyle(),
          menuChildren: [
            for (final g in groups)
              MenuItemButton(
                style: MenuItemButton.styleFrom(
                  backgroundColor: g.id == activeGroup.id
                      ? cs.primary.withValues(alpha: 0.10)
                      : null,
                ),
                leadingIcon: _avatar(g, 20),
                trailingIcon: g.id == activeGroup.id
                    ? Icon(Icons.check_rounded, size: 16, color: cs.primary)
                    : null,
                onPressed: g.id == activeGroup.id
                    ? () {}
                    : () {
                        groupDomain.currentGroup = g;
                        Navigator.of(context).pushNamed(
                          AppRoutes.groupDashboard,
                          arguments: g,
                        );
                      },
                child: Tooltip(
                  message: g.name,
                  waitDuration: const Duration(milliseconds: 500),
                  child: Text(
                    g.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: NavigationTokens.label(context),
                  ),
                ),
              ),
          ],
          builder: (context, controller, _) {
            void switchWorkspace() {
              if (controller.isOpen) {
                controller.close();
              } else {
                controller.open();
              }
            }

            final switchLabel =
                es ? 'Cambiar espacio de trabajo' : 'Switch workspace';
            final settingsLabel = es ? 'Configurar grupo' : 'Configure group';

            // Keep the two actions separate: the avatar opens the workspace
            // picker, while the group name takes the user to its settings.
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                HexoraNavTile(
                  selected: false,
                  semanticLabel: switchLabel,
                  tooltip: switchLabel,
                  minWidth: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  onTap: switchWorkspace,
                  builder: (context, fg) => _avatar(activeGroup, 24),
                ),
                if (showName) ...[
                  const SizedBox(width: 2),
                  HexoraNavTile(
                    selected: false,
                    semanticLabel: settingsLabel,
                    tooltip: settingsLabel,
                    minWidth: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    onTap: onOpenGroupSettings,
                    builder: (context, fg) => ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: _chipMaxNameWidth,
                      ),
                      child: Text(
                        activeGroup.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: NavigationTokens.label(context).copyWith(
                          color: fg,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  HexoraNavTile(
                    selected: false,
                    semanticLabel: switchLabel,
                    tooltip: switchLabel,
                    minWidth: 24,
                    padding: EdgeInsets.zero,
                    onTap: switchWorkspace,
                    builder: (context, fg) => Icon(
                      Icons.expand_more_rounded,
                      size: 14,
                      color: fg,
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }
}
