import 'package:hexora/presentation/screens/agenda/agenda_screen.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hexora/navigation/shell/hexora_app_shell.dart';
import 'package:hexora/navigation/shell/hexora_global_nav_bar.dart';
import 'package:hexora/navigation/shell/hexora_nav_components.dart';
import 'package:hexora/navigation/shell/worker_status_indicator.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/models/user/user.dart';
import 'package:hexora/models/user/user_preferences.dart';
import 'package:hexora/presentation/routes/app_routes.dart';
import 'package:hexora/services/groups/domain/group_domain.dart';
import 'package:hexora/theme/themes/navigation_tokens.dart';
import 'package:hexora/services/notification/domain/notification_domain.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/navigation/dashboard_sections.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/layout/download_jobs_top_menu.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/layout/group_dashboard_content.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/panels/group_dashboard_right_panel.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/tabs/workspace_content.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/tabs/workspace_tab.dart';
import 'package:hexora/presentation/screens/workspace/sections/enable_banking/enable_banking_screen.dart';
import 'package:hexora/presentation/screens/workspace/sections/expenses/gastos_module_screen.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/group_invoices_screen.dart';
import 'package:hexora/presentation/screens/workspace/sections/presupuestos/presupuestos_module_screen.dart';
import 'package:hexora/presentation/screens/workspace/sections/mail/mail_console_screen.dart';
import 'package:hexora/presentation/screens/workspace/sections/maps/client_map_screen.dart';
import 'package:hexora/presentation/screens/workspace/sections/telegram/telegram_section_screen.dart';
import 'package:hexora/presentation/screens/calendar/screens/calendar/screen/main_calendar_view.dart';
import 'package:hexora/presentation/shared/widgets/user_profile_popup.dart';
import 'package:hexora/presentation/shared/widgets/sidebar_edge_shell.dart';
import 'package:hexora/presentation/utils/roles/group_role_labels.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/state/user_preferences_provider.dart';
import 'package:provider/provider.dart';

import '../state/group_dashboard_state.dart';

class WideLayout extends StatelessWidget {
  const WideLayout({super.key, required this.state});
  final GroupDashboardState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final preferences = context.watch<UserPreferencesProvider>();
    final destinations = _dashboardDestinations(
      l,
      canSeeAdmin: state.canSeeAdmin,
      canSeeWorkers: state.canSeeAdmin,
    );
    final workspace = SidebarFooterScope(
      builder: (footerContext, collapsed) => UserProfilePopup(
        user: state.user,
        onSettings: () => state.openSection(Sections.settings),
        placement: UserProfilePopupPlacement.sidebar,
        expanded: !collapsed,
        roleLabel:
            state.role == null ? null : roleLabelOf(footerContext, state.role!),
      ),
      child: WorkspaceContent(
        manager: state.workspaceTabs,
        builder: (context, tab) => _buildContent(state, context, l, tab),
      ),
    );

    return HexoraAppShell(
      globalNav: _DashboardTopNav(state: state, l: l, user: state.user),
      globalNavigationCollapsed: preferences.topNavCollapsed,
      onRestoreGlobalNavigation: () =>
          context.read<UserPreferencesProvider>().setTopNavCollapsed(false),
      body: ListenableBuilder(
        listenable: state.workspaceTabs,
        child: workspace,
        builder: (context, child) {
          final activeSection =
              state.workspaceTabs.activeTab?.section ?? state.activeSection;
          String? moduleLabel;
          for (final destination in destinations) {
            if (destination.id == activeSection) {
              moduleLabel = destination.label;
              break;
            }
          }
          return moduleLabel == null
              ? child!
              : HexoraNavContext(
                  moduleLabel: moduleLabel,
                  child: child!,
                );
        },
      ),
    );
  }

  Widget _buildContent(
    GroupDashboardState state,
    BuildContext context,
    AppLocalizations l,
    WorkspaceTab tab,
  ) {
    final section = tab.section;
    const showMainBody = !kIsWeb;
    final showCalendarInline = kIsWeb && section == Sections.calendar;
    final showInvoicesInline = kIsWeb && section == Sections.invoices;
    final showBudgetsInline = kIsWeb && section == Sections.budgets;
    final showExpensesInline = kIsWeb && section == Sections.expenses;
    final showMapInline = section == Sections.maps;
    final showEmailsInline = section == Sections.emails;
    final showEnableBankingInline = kIsWeb && section == Sections.enableBanking;
    final showTelegramInline = section == Sections.telegram;

    if (section == Sections.agenda) {
      return WorkspaceMainContent(
        child: AgendaScreen(groupId: state.group.id, embedded: true),
      );
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
                        'group-invoices-${state.group.id}-${tab.identity.value}-${tab.arguments['navigationRevision'] ?? 'initial'}',
                      ),
                      group: state.group,
                      embedded: true,
                      initialMenu:
                          tab.arguments['initialMenu'] ?? 'invoices_issued',
                      initialInvoiceId: tab.arguments['initialInvoiceId'],
                      initialReceiptId: tab.arguments['initialReceiptId'],
                      initialBudgetId: tab.arguments['initialBudgetId'],
                      onOpenWorkspace: state.openInvoicesWorkspace,
                    )
                  : showBudgetsInline
                      ? PresupuestosModuleScreen(
                          key: ValueKey(
                            'group-budgets-${state.group.id}-${tab.identity.value}',
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
                                    'group-map-${state.group.id}-${tab.identity.value}',
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
                                      : _fallbackPanel(state, section),
        ),
      ],
    );
  }

  Widget _fallbackPanel(GroupDashboardState state, String section) {
    final panel = GroupDashboardRightPanel(
      activeAnchor: section,
      counts: state.counts,
      group: state.group,
      user: state.user,
      role: state.role,
      fetchReadSas: state.fetchReadSas,
      usersInGroup: const [],
      onOpenCalendar: () => state.openSection('calendar'),
      onOpenNotifications: () => state.openSection('notifications'),
      onOpenSettings: () => state.openSection('settings'),
    );
    if (section == Sections.settings ||
        section == Sections.workers ||
        section == Sections.notifications ||
        section == Sections.businessChat) {
      return panel;
    }
    return WorkspaceMainContent(child: panel);
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
  required bool canSeeWorkers,
}) {
  final es = l.localeName.startsWith('es');
  return [
    if (canSeeAdmin) ...[
      HexoraNavDestination(
        id: Sections.invoices,
        icon: Icons.receipt_long_outlined,
        label: es ? 'Ingresos' : 'Income',
      ),
      HexoraNavDestination(
        id: Sections.expenses,
        icon: Icons.trending_down_rounded,
        label: es ? 'Gastos' : 'Expenses',
      ),
      HexoraNavDestination(
        id: Sections.enableBanking,
        icon: Icons.account_balance_outlined,
        label: es ? 'Banco' : 'Bank',
      ),
    ],
    HexoraNavDestination(
      id: Sections.calendar,
      icon: Icons.calendar_month_rounded,
      label: l.calendar,
    ),
    if (canSeeAdmin) ...[
      HexoraNavDestination(
        id: Sections.budgets,
        icon: Icons.description_outlined,
        label: es ? 'Propuestas' : 'Proposals',
      ),
    ],
    const HexoraNavDestination(
      id: Sections.businessChat,
      icon: Icons.chat_bubble_outline_rounded,
      label: 'Chat',
    ),
    HexoraNavDestination(
      id: Sections.maps,
      icon: Icons.map_outlined,
      label: es ? 'Mapa' : 'Map',
      placement: HexoraNavPlacement.more,
    ),
    if (canSeeAdmin)
      const HexoraNavDestination(
        id: Sections.emails,
        icon: Icons.email_outlined,
        label: 'Emails',
        placement: HexoraNavPlacement.more,
      ),
    if (canSeeWorkers)
      HexoraNavDestination(
        id: Sections.workers,
        icon: Icons.access_time_rounded,
        label: es ? 'Trabajadores' : 'Workers',
        placement: HexoraNavPlacement.more,
      ),
    if (canSeeAdmin) ...[
      HexoraNavDestination(
        id: Sections.chat,
        icon: Icons.auto_awesome_outlined,
        label: es ? 'Asistente IA' : 'AI assistant',
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
  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final l = widget.l;
    final user = widget.user;
    final es = l.localeName.startsWith('es');
    final unreadNotifications = context
        .watch<NotificationDomain>()
        .notifications
        .where((n) => n.groupId == state.group.id && !n.isRead)
        .length;
    final memberIds = {...state.group.userIds, state.group.ownerId}..remove('');
    final preferences = context.watch<UserPreferencesProvider>();
    final navigationMode = preferences.navigationDisplayMode;

    return ListenableBuilder(
      listenable: state.workspaceTabs,
      builder: (context, _) {
        final activeSection =
            state.workspaceTabs.activeTab?.section ?? state.activeSection;
        return HexoraGlobalNavBar(
          destinations: _dashboardDestinations(
            l,
            canSeeAdmin: state.canSeeAdmin,
            canSeeWorkers: state.canSeeAdmin,
          ),
          activeId: activeSection,
          onSelected: state.openSection,
          onBrandTap: state.canSeeAdmin
              ? () => state.openSection(Sections.settings)
              : null,
          brandTooltip: es ? 'Ajustes del espacio' : 'Workspace settings',
          groupSwitcher: _GroupSwitcherChip(
            activeGroup: state.group,
            userId: user?.id ?? '',
            onOpenGroupSettings: () => state.openSection(Sections.settings),
          ),
          navigationDisplayMode: navigationMode,
          collapsed: preferences.topNavCollapsed,
          onToggleCollapsed: () {
            final provider = context.read<UserPreferencesProvider>();
            provider.setTopNavCollapsed(!provider.topNavCollapsed);
          },
          notificationCount: unreadNotifications,
          notificationsSelected: activeSection == Sections.notifications,
          onOpenNotifications: () => state.openSection(Sections.notifications),
          downloads: IconTheme(
            data: const IconThemeData(color: HexoraGlobalNavColors.foreground),
            child: DefaultTextStyle.merge(
              style: const TextStyle(color: HexoraGlobalNavColors.foreground),
              child: DownloadJobsTopMenu(
                groupId: state.group.id,
                onViewAllDownloads: () =>
                    state.openSection(Sections.notifications),
                compact: navigationMode == NavigationDisplayMode.iconsOnly,
              ),
            ),
          ),
          onlineMembers: state.canSeeAdmin
              ? WorkerStatusIndicator(
                  groupId: state.group.id,
                  memberIds: memberIds.toList(),
                  groupRoles: state.group.userRoles,
                  onOpenWorkers: () => state.openSection(Sections.workers),
                  compact: navigationMode == NavigationDisplayMode.iconsOnly,
                )
              : null,
          onBack: () => Navigator.of(context).maybePop(),
          backTooltip: l.groupSectionTitle,
        );
      },
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

  /// [bg]/[fg] let the dropdown rows use theme colors (legible on a light
  /// surface), while the trigger keeps its white-on-navy look by default.
  Widget _avatar(Group group, double size, {Color? bg, Color? fg}) {
    final photoUrl = group.computedPhotoUrl ?? group.photoUrl;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          photoUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initialsAvatar(group, size, bg, fg),
        ),
      );
    }
    return _initialsAvatar(group, size, bg, fg);
  }

  Widget _initialsAvatar(Group group, double size, [Color? bg, Color? fg]) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg ?? const Color(0x26FFFFFF), // foreground @ 15 % alpha
      ),
      alignment: Alignment.center,
      child: Text(
        _initials(group.name),
        style: TextStyle(
          fontSize: size * 0.38,
          fontWeight: FontWeight.w700,
          color: fg ?? HexoraGlobalNavColors.foreground,
          fontFamily: 'Inter',
        ),
      ),
    );
  }

  /// Theme-aware dropdown surface: clean white in light mode, a slate slightly
  /// lighter than the navy nav bar in dark mode — never the top-bar color.
  MenuStyle _menuStyle(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? cs.surfaceContainerHigh : cs.surface;
    return MenuStyle(
      backgroundColor: WidgetStatePropertyAll(surface),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      shadowColor: WidgetStatePropertyAll(Colors.black.withValues(alpha: 0.22)),
      elevation: const WidgetStatePropertyAll(8),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 6)),
      minimumSize: const WidgetStatePropertyAll(Size(264, 0)),
      maximumSize: const WidgetStatePropertyAll(Size(320, 440)),
      visualDensity: VisualDensity.compact,
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: cs.outlineVariant.withValues(alpha: isDark ? 0.4 : 0.6),
          ),
        ),
      ),
    );
  }

  /// Compact workspace row: avatar · name · selected checkmark.
  MenuItemButton _groupRow(
    BuildContext context,
    Group group,
    bool selected,
    VoidCallback onPressed,
  ) {
    final cs = Theme.of(context).colorScheme;
    return MenuItemButton(
      style: MenuItemButton.styleFrom(
        minimumSize: const Size(0, 42),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        backgroundColor:
            selected ? cs.primary.withValues(alpha: 0.10) : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onPressed,
      child: Row(
        children: [
          _avatar(group, 26,
              bg: cs.primary.withValues(alpha: 0.12), fg: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Tooltip(
              message: group.name,
              waitDuration: const Duration(milliseconds: 500),
              child: Text(
                group.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: NavigationTokens.label(context).copyWith(
                  color: cs.onSurface,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
          if (selected) ...[
            const SizedBox(width: 8),
            Icon(Icons.check_rounded, size: 16, color: cs.primary),
          ],
        ],
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

        void selectGroup(Group g) {
          if (g.id == activeGroup.id) return;
          groupDomain.currentGroup = g;
          Navigator.of(context).pushNamed(
            AppRoutes.groupDashboard,
            arguments: g,
          );
        }

        return MenuAnchor(
          alignmentOffset: const Offset(0, 6),
          style: _menuStyle(context),
          // A compact search appears only for users with many workspaces.
          menuChildren: groups.length > 7
              ? [
                  _SearchableWorkspaceList(
                    groups: groups,
                    activeId: activeGroup.id,
                    isSpanish: es,
                    onSelect: selectGroup,
                    avatarBuilder: (g, size) => _avatar(
                      g,
                      size,
                      bg: cs.primary.withValues(alpha: 0.12),
                      fg: cs.primary,
                    ),
                  ),
                ]
              : [
                  for (final g in groups)
                    _groupRow(
                      context,
                      g,
                      g.id == activeGroup.id,
                      () => selectGroup(g),
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
                    builder: (context, fg) => AnimatedRotation(
                      turns: controller.isOpen ? 0.5 : 0,
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 180),
                      child: Icon(
                        Icons.expand_more_rounded,
                        size: 14,
                        color: fg,
                      ),
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

class _SearchableWorkspaceList extends StatefulWidget {
  const _SearchableWorkspaceList({
    required this.groups,
    required this.activeId,
    required this.isSpanish,
    required this.onSelect,
    required this.avatarBuilder,
  });

  final List<Group> groups;
  final String activeId;
  final bool isSpanish;
  final ValueChanged<Group> onSelect;
  final Widget Function(Group group, double size) avatarBuilder;

  @override
  State<_SearchableWorkspaceList> createState() =>
      _SearchableWorkspaceListState();
}

class _SearchableWorkspaceListState extends State<_SearchableWorkspaceList> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final query = _search.text.trim().toLowerCase();
    final visible = query.isEmpty
        ? widget.groups
        : widget.groups
            .where((group) => group.name.toLowerCase().contains(query))
            .toList(growable: false);
    return SizedBox(
      width: 280,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 2, 10, 8),
            child: SizedBox(
              height: 36,
              child: TextField(
                controller: _search,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  hintText: widget.isSpanish
                      ? 'Buscar espacio...'
                      : 'Search workspace...',
                ),
              ),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 6),
              itemCount: visible.length,
              itemBuilder: (context, index) {
                final group = visible[index];
                final selected = group.id == widget.activeId;
                return MenuItemButton(
                  style: MenuItemButton.styleFrom(
                    backgroundColor: selected
                        ? cs.primary.withValues(alpha: 0.10)
                        : Colors.transparent,
                  ),
                  leadingIcon: widget.avatarBuilder(group, 20),
                  trailingIcon: selected
                      ? Icon(Icons.check_rounded, size: 16, color: cs.primary)
                      : null,
                  onPressed: () => widget.onSelect(group),
                  child: Text(
                    group.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: NavigationTokens.label(context),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
