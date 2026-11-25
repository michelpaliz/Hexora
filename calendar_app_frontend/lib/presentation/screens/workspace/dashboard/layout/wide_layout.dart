import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/models/user/user.dart';
import 'package:hexora/models/user/user_preferences.dart';
import 'package:hexora/navigation/shell/hexora_app_shell.dart';
import 'package:hexora/navigation/shell/hexora_global_nav_bar.dart';
import 'package:hexora/navigation/shell/hexora_nav_components.dart';
import 'package:hexora/navigation/shell/worker_status_indicator.dart';
import 'package:hexora/presentation/routes/app_routes.dart';
import 'package:hexora/presentation/screens/agenda/agenda_screen.dart';
import 'package:hexora/presentation/screens/calendar/screens/calendar/screen/main_calendar_view.dart';
import 'package:hexora/presentation/screens/home/dashboard_preview/dashboard_preview_screen.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/layout/download_jobs_top_menu.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/layout/group_dashboard_content.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/navigation/dashboard_sections.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/panels/group_dashboard_right_panel.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/tabs/workspace_content.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/tabs/workspace_tab.dart';
import 'package:hexora/presentation/screens/workspace/premium/premium_feature_request_screen.dart';
import 'package:hexora/presentation/screens/workspace/sections/enable_banking/enable_banking_screen.dart';
import 'package:hexora/presentation/screens/workspace/sections/expenses/gastos_module_screen.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/group_invoices_screen.dart';
import 'package:hexora/presentation/screens/workspace/sections/mail/mail_console_screen.dart';
import 'package:hexora/presentation/screens/workspace/sections/maps/client_map_screen.dart';
import 'package:hexora/presentation/screens/workspace/sections/presupuestos/presupuestos_module_screen.dart';
import 'package:hexora/presentation/screens/workspace/sections/quick_notes/quick_notes_board_screen.dart';
import 'package:hexora/presentation/screens/workspace/sections/telegram/telegram_section_screen.dart';
import 'package:hexora/presentation/shared/utils/weather/weather_summary_localizer.dart';
import 'package:hexora/presentation/shared/widgets/collapsible_sidebar.dart';
import 'package:hexora/presentation/shared/widgets/sidebar_edge_shell.dart';
import 'package:hexora/presentation/shared/widgets/user_profile_popup.dart';
import 'package:hexora/presentation/utils/logo/hexora_brand.dart';
import 'package:hexora/services/groups/domain/group_domain.dart';
import 'package:hexora/services/notification/domain/notification_domain.dart';
import 'package:hexora/services/weather/weather_service.dart';
import 'package:hexora/state/user_preferences_provider.dart';
import 'package:hexora/theme/motion/hexora_motion.dart';
import 'package:hexora/theme/themes/navigation_tokens.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../state/group_dashboard_state.dart';

class WideLayout extends StatelessWidget {
  const WideLayout({super.key, required this.state});
  final GroupDashboardState state;

  @override
  Widget build(BuildContext context) {
    // Do not build the module sidebar from partially resolved permissions.
    // On a cold entry the dashboard briefly has no user/role yet, which made
    // the left navigation appear incomplete beside the loading/retry view.
    // Keep the whole workspace in one stable loading state until the session
    // data has been resolved.
    if (state.isLoading) {
      return ColoredBox(
        color: state.backdrop,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    final l = AppLocalizations.of(context)!;
    final preferences = context.watch<UserPreferencesProvider>();
    final destinations = _dashboardDestinations(
      l,
      canSeeAdmin: state.canSeeAdmin,
      canSeeWorkers: state.canSeeAdmin,
    );
    final workspace = WorkspaceContent(
      manager: state.workspaceTabs,
      builder: (context, tab) => _buildContent(state, context, l, tab),
    );

    return HexoraAppShell(
      globalNav: _DashboardTopNav(state: state, l: l, user: state.user),
      globalNavigationCollapsed: preferences.topNavCollapsed,
      onRestoreGlobalNavigation: () =>
          context.read<UserPreferencesProvider>().setTopNavCollapsed(false),
      globalNavigationRestoreLabel: state.group.name,
      body: ListenableBuilder(
        listenable: state.workspaceTabs,
        child: workspace,
        builder: (context, child) {
          final activeSection =
              state.workspaceTabs.activeTab?.section ?? state.activeSection;
          HexoraNavDestination? activeDestination;
          for (final destination in destinations) {
            if (destination.id == activeSection) {
              activeDestination = destination;
              break;
            }
          }
          final moduleLabel = activeDestination?.label;
          final unified =
              preferences.navigationLayout == NavigationLayout.unified;
          final usesContextualSidebar = _usesContextualSidebar(
            activeSection,
            MediaQuery.sizeOf(context).width,
          );
          final moduleContent = moduleLabel == null
              ? child!
              : HexoraNavContext(
                  moduleLabel: moduleLabel,
                  child: child!,
                );
          final moduleWorkspace = Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (unified && !usesContextualSidebar)
                _UnifiedModuleHeaderSidebar(
                  destinations: destinations,
                  destination: activeDestination,
                  fallbackLabel: moduleLabel,
                  showDestinationItem: activeSection == Sections.chat,
                  onDestinationSelected: state.openSection,
                )
              else
                const SizedBox.shrink(),
              Expanded(child: moduleContent),
            ],
          );
          final content = SidebarHeaderScope(
            // Chat already uses the module control in its left navigation.
            // Mounting this shared header too creates a second selector above
            // the conversation.
            enabled: unified && activeSection != Sections.chat,
            builder: (context, collapsed) => _UnifiedModuleSwitcher(
              destinations: destinations,
              activeDestination: activeDestination,
              collapsed: collapsed,
              onSelected: state.openSection,
            ),
            child: SecondarySidebarTopInsetScope(
              topInset: unified ? 0 : 48,
              title: moduleLabel,
              icon: activeDestination?.icon,
              child: moduleWorkspace,
            ),
          );
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!unified)
                _DashboardModuleSidebar(
                  destinations: destinations,
                  activeId: activeSection,
                  onSelected: state.openSection,
                )
              else
                const SizedBox.shrink(),
              Expanded(child: content),
            ],
          );
        },
      ),
    );
  }

  bool _usesContextualSidebar(String section, double viewportWidth) {
    // These modules switch to an inline/sidebar layout at their own wider
    // breakpoints. Until then, retain the primary rail so module navigation is
    // never lost in unified mode.
    if (section == Sections.notifications && viewportWidth < 1180) {
      return false;
    }
    if (section == Sections.telegram && viewportWidth < 1080) {
      return false;
    }
    return const {
      Sections.invoices,
      Sections.invoiceClients,
      Sections.expenses,
      Sections.enableBanking,
      Sections.budgets,
      Sections.calendar,
      Sections.businessChat,
      Sections.workers,
      Sections.settings,
      Sections.notifications,
      Sections.telegram,
      Sections.emails,
      Sections.maps,
    }.contains(section);
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
    final showInvoicesInline = kIsWeb &&
        (section == Sections.invoices || section == Sections.invoiceClients);
    final showBudgetsInline = kIsWeb && section == Sections.budgets;
    final showExpensesInline = kIsWeb && section == Sections.expenses;
    final showMapInline = section == Sections.maps;
    final showEmailsInline = section == Sections.emails;
    final showEnableBankingInline = kIsWeb && section == Sections.enableBanking;
    final showTelegramInline = section == Sections.telegram;
    final showQuickNotesInline = section == Sections.quickNotes;

    if (section == Sections.home) {
      return DashboardPreviewScreen(
        embedded: true,
        onOpenSection: state.openSection,
        onOpenBillingProfile: () =>
            state.openInvoicesWorkspace(initialMenu: 'billing_profile'),
        onAskHexora: state.canSeeAdmin ? state.askHexoraFromHome : null,
        onOpenAssistant:
            state.canSeeAdmin ? () => state.openSection(Sections.chat) : null,
      );
    }

    if (section == Sections.agenda) {
      return WorkspaceMainContent(
        child: AgendaScreen(groupId: state.group.id, embedded: true),
      );
    }

    if (showEmailsInline) {
      return PremiumFeatureGate(
        group: state.group,
        feature: PremiumFeatureRequest.email,
        child: const MailConsoleScreen(embedded: true),
      );
    }

    if (showTelegramInline) {
      return const TelegramSectionScreen();
    }

    if (showQuickNotesInline) {
      return QuickNotesBoardScreen(group: state.group, embedded: true);
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
                      initialMenu: tab.arguments['initialMenu'] ??
                          (section == Sections.invoiceClients
                              ? 'clients_flow'
                              : 'invoices_issued'),
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
        section == Sections.chat ||
        section == Sections.businessChat) {
      return panel;
    }
    return WorkspaceMainContent(child: panel);
  }
}

class _UnifiedModuleSwitcher extends StatelessWidget {
  const _UnifiedModuleSwitcher({
    required this.destinations,
    required this.activeDestination,
    required this.collapsed,
    required this.onSelected,
  });

  final List<HexoraNavDestination> destinations;
  final HexoraNavDestination? activeDestination;
  final bool collapsed;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final active = activeDestination;
    final control = Container(
      height: collapsed ? 36 : 38,
      margin: EdgeInsetsDirectional.fromSTEB(
        collapsed ? 8 : 10,
        collapsed ? 6 : 7,
        collapsed ? 8 : 12,
        collapsed ? 6 : 7,
      ),
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: collapsed ? 0 : 10,
      ),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          cs.primary.withValues(alpha: .10),
          cs.surface,
        ),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisAlignment:
            collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          Icon(
            active?.icon ?? Icons.apps_rounded,
            size: 17,
            color: cs.primary,
          ),
          if (!collapsed) ...[
            const SizedBox(width: 9),
            // Expanded(
            //   child: Text(
            //     active?.label ?? (isEs ? 'Módulos' : 'Modules'),
            //     maxLines: 1,
            //     overflow: TextOverflow.ellipsis,
            //     style: NavigationTokens.label(context).copyWith(
            //       fontWeight: FontWeight.w700,
            //       color: cs.onSurface,
            //     ),
            //   ),
            // ),
            Icon(
              Icons.expand_more_rounded,
              size: 17,
              color: cs.onSurfaceVariant,
            ),
          ],
        ],
      ),
    );

    return _GroupedModuleMenu(
      destinations: destinations,
      activeId: active?.id,
      isSpanish: isEs,
      onSelected: onSelected,
      control: control,
    );
  }
}

class _GroupedModuleMenu extends StatefulWidget {
  const _GroupedModuleMenu({
    required this.destinations,
    required this.activeId,
    required this.isSpanish,
    required this.onSelected,
    required this.control,
  });

  final List<HexoraNavDestination> destinations;
  final String? activeId;
  final bool isSpanish;
  final ValueChanged<String> onSelected;
  final Widget control;

  @override
  State<_GroupedModuleMenu> createState() => _GroupedModuleMenuState();
}

class _GroupedModuleMenuState extends State<_GroupedModuleMenu> {
  final MenuController _controller = MenuController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final navigationColors = NavigationColors(cs);
    final groups = [
      for (final group in _dashboardNavigationGroups)
        if (_destinationsForGroup(group, widget.destinations).isNotEmpty)
          (
            group: group,
            destinations: _destinationsForGroup(group, widget.destinations),
          ),
    ];
    final destinationCount = groups.fold<int>(
      0,
      (total, entry) => total + entry.destinations.length,
    );
    final estimatedHeight = 12.0 +
        destinationCount * 38.0 +
        groups.length * 24.0 +
        math.max(0, groups.length - 1) * 7.0;
    final availableHeight = math.max(
      220.0,
      math.min(620.0, MediaQuery.sizeOf(context).height - 96.0),
    );
    final menuHeight = math.min(estimatedHeight, availableHeight);

    return MenuAnchor(
      controller: _controller,
      alignmentOffset: const Offset(0, 6),
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.transparent),
        surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
        elevation: WidgetStatePropertyAll(0),
        padding: WidgetStatePropertyAll(EdgeInsets.zero),
      ),
      menuChildren: [
        _DropdownEntranceTransition(
          width: 276,
          height: menuHeight,
          child: Scrollbar(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var groupIndex = 0;
                      groupIndex < groups.length;
                      groupIndex++) ...[
                    if (groupIndex > 0)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(6, 3, 6, 3),
                        child: Divider(
                          height: 1,
                          thickness: 1,
                          color: cs.outlineVariant.withValues(alpha: .45),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 5, 10, 3),
                      child: Text(
                        groups[groupIndex].group.label(widget.isSpanish),
                        style: NavigationTokens.section(context).copyWith(
                          color: navigationColors.sectionForeground,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    for (final destination in groups[groupIndex].destinations)
                      _GroupedModuleMenuItem(
                        destination: destination,
                        selected: destination.id == widget.activeId,
                        onPressed: () {
                          _controller.close();
                          widget.onSelected(destination.id);
                        },
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
      builder: (context, controller, _) => Tooltip(
        message: widget.isSpanish ? 'Cambiar módulo' : 'Switch module',
        child: Semantics(
          button: true,
          expanded: controller.isOpen,
          child: InkWell(
            borderRadius: BorderRadius.circular(9),
            onTap: () =>
                controller.isOpen ? controller.close() : controller.open(),
            child: widget.control,
          ),
        ),
      ),
    );
  }
}

class _DropdownEntranceTransition extends StatefulWidget {
  const _DropdownEntranceTransition({
    required this.width,
    required this.height,
    required this.child,
  });

  final double width;
  final double height;
  final Widget child;

  @override
  State<_DropdownEntranceTransition> createState() =>
      _DropdownEntranceTransitionState();
}

class _DropdownEntranceTransitionState
    extends State<_DropdownEntranceTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: HexoraMotion.popup,
  );
  late final CurvedAnimation _animation = CurvedAnimation(
    parent: _controller,
    curve: HexoraMotion.enter,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.duration = HexoraMotion.duration(context, HexoraMotion.popup);
    if (_started) return;
    _started = true;
    if (HexoraMotion.reduceMotion(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _animation,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: widget.child,
      ),
      builder: (context, child) => Opacity(
        opacity: _animation.value,
        child: Transform.translate(
          offset: Offset(0, 4 * (1 - _animation.value)),
          transformHitTests: false,
          child: Material(
            color: cs.surface,
            surfaceTintColor: Colors.transparent,
            elevation: 8,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: cs.outlineVariant.withValues(alpha: .55),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _GroupedModuleMenuItem extends StatelessWidget {
  const _GroupedModuleMenuItem({
    required this.destination,
    required this.selected,
    required this.onPressed,
  });

  final HexoraNavDestination destination;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final navigationColors = NavigationColors(cs);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: SizedBox(
        height: 36,
        child: MenuItemButton(
          onPressed: onPressed,
          leadingIcon: Icon(
            destination.icon,
            size: 17,
            color: selected ? cs.primary : navigationColors.itemForeground,
          ),
          trailingIcon: selected
              ? Icon(Icons.check_rounded, size: 17, color: cs.primary)
              : const SizedBox(width: 17),
          style: ButtonStyle(
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 10),
            ),
            minimumSize: const WidgetStatePropertyAll(Size(0, 36)),
            maximumSize: const WidgetStatePropertyAll(Size.infinite),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            foregroundColor: WidgetStatePropertyAll(
              selected ? cs.onSurface : navigationColors.itemForeground,
            ),
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (selected) return navigationColors.selectedBackground;
              if (states.contains(WidgetState.pressed)) {
                return navigationColors.pressed;
              }
              if (states.contains(WidgetState.focused)) {
                return navigationColors.focus;
              }
              if (states.contains(WidgetState.hovered)) {
                return navigationColors.hover;
              }
              return Colors.transparent;
            }),
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          ),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              destination.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: NavigationTokens.label(context, selected: selected),
            ),
          ),
        ),
      ),
    );
  }
}

/// Keeps the unified navigation surface for modules without contextual child
/// destinations. The active module already lives in [SidebarHeaderScope], so
/// adding it again as a selected row would duplicate the same destination.
class _UnifiedModuleHeaderSidebar extends StatefulWidget {
  const _UnifiedModuleHeaderSidebar({
    required this.destinations,
    required this.destination,
    required this.fallbackLabel,
    required this.showDestinationItem,
    required this.onDestinationSelected,
  });

  final List<HexoraNavDestination> destinations;
  final HexoraNavDestination? destination;
  final String? fallbackLabel;
  final bool showDestinationItem;
  final ValueChanged<String> onDestinationSelected;

  @override
  State<_UnifiedModuleHeaderSidebar> createState() =>
      _UnifiedModuleHeaderSidebarState();
}

class _UnifiedModuleHeaderSidebarState
    extends State<_UnifiedModuleHeaderSidebar> {
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final destination = widget.destination;
    final label = destination?.label ??
        widget.fallbackLabel ??
        (isEs ? 'Módulo' : 'Module');
    final icon = destination?.icon ?? Icons.apps_rounded;

    if (widget.showDestinationItem) {
      return CollapsibleSidebarShell(
        title: label,
        collapsed: _collapsed,
        onToggleCollapsed: () => setState(() => _collapsed = !_collapsed),
        expandTooltip: isEs ? 'Expandir menú' : 'Expand menu',
        collapseTooltip: isEs ? 'Contraer menú' : 'Collapse menu',
        builder: (context, layoutCollapsed) => Align(
          alignment: AlignmentDirectional.topCenter,
          child: _UnifiedModuleSwitcher(
            destinations: widget.destinations,
            activeDestination: destination,
            collapsed: layoutCollapsed,
            onSelected: widget.onDestinationSelected,
          ),
        ),
      );
    }

    return CollapsibleSidebar(
      title: label,
      headerIcon: icon,
      collapsed: _collapsed,
      onToggleCollapsed: () => setState(() => _collapsed = !_collapsed),
      expandTooltip: isEs ? 'Expandir menú' : 'Expand menu',
      collapseTooltip: isEs ? 'Contraer menú' : 'Collapse menu',
      items: const [],
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
  required bool canSeeWorkers,
}) {
  final es = l.localeName.startsWith('es');
  return [
    HexoraNavDestination(
      id: Sections.home,
      icon: LucideIcons.house,
      label: es ? 'Inicio' : 'Home',
    ),
    if (canSeeAdmin)
      HexoraNavDestination(
        id: Sections.chat,
        icon: LucideIcons.sparkles,
        label: es ? 'Asistente IA' : 'AI assistant',
      ),
    if (canSeeAdmin) ...[
      HexoraNavDestination(
        id: Sections.invoices,
        icon: LucideIcons.fileText,
        label: es ? 'Ingresos' : 'Income',
      ),
      HexoraNavDestination(
        id: Sections.invoiceClients,
        icon: LucideIcons.users,
        label: es ? 'Facturas por cliente' : 'Invoices by client',
      ),
    ],
    if (canSeeAdmin) ...[
      HexoraNavDestination(
        id: Sections.expenses,
        icon: LucideIcons.trendingDown,
        label: es ? 'Gastos' : 'Expenses',
      ),
      HexoraNavDestination(
        id: Sections.enableBanking,
        icon: LucideIcons.landmark,
        label: es ? 'Banco' : 'Bank',
      ),
    ],
    HexoraNavDestination(
      id: Sections.calendar,
      icon: LucideIcons.calendarDays,
      label: l.calendar,
    ),
    HexoraNavDestination(
      id: Sections.quickNotes,
      icon: LucideIcons.squareKanban,
      label: es ? 'Notas rápidas' : 'Quick notes',
    ),
    if (canSeeAdmin) ...[
      HexoraNavDestination(
        id: Sections.budgets,
        icon: LucideIcons.fileText,
        label: es ? 'Propuestas' : 'Proposals',
      ),
    ],
    const HexoraNavDestination(
      id: Sections.businessChat,
      icon: LucideIcons.messageCircle,
      label: 'Chat',
    ),
    HexoraNavDestination(
      id: Sections.maps,
      icon: LucideIcons.map,
      label: es ? 'Mapa' : 'Map',
      placement: HexoraNavPlacement.more,
    ),
    if (canSeeAdmin)
      const HexoraNavDestination(
        id: Sections.emails,
        icon: LucideIcons.mail,
        label: 'Emails',
        placement: HexoraNavPlacement.more,
      ),
    if (canSeeWorkers)
      HexoraNavDestination(
        id: Sections.workers,
        icon: LucideIcons.users,
        label: es ? 'Trabajadores' : 'Workers',
        placement: HexoraNavPlacement.more,
      ),
    if (canSeeAdmin) ...[
      const HexoraNavDestination(
        id: Sections.telegram,
        icon: LucideIcons.send,
        label: 'Telegram',
        placement: HexoraNavPlacement.more,
      ),
    ],
    if (canSeeAdmin)
      HexoraNavDestination(
        id: Sections.services,
        icon: LucideIcons.users,
        label: es ? 'Clientes' : 'Clients',
      ),
    if (canSeeAdmin)
      HexoraNavDestination(
        id: Sections.settings,
        icon: LucideIcons.settings,
        label: es ? 'Ajustes' : 'Settings',
      ),
    HexoraNavDestination(
      id: Sections.notifications,
      icon: Icons.notifications_none_rounded,
      label: l.notifications,
      placement: HexoraNavPlacement.searchOnly,
    ),
  ];
}

class _DashboardNavigationGroup {
  const _DashboardNavigationGroup({
    required this.englishLabel,
    required this.spanishLabel,
    required this.destinationIds,
  });

  final String englishLabel;
  final String spanishLabel;
  final List<String> destinationIds;

  String label(bool isSpanish) => isSpanish ? spanishLabel : englishLabel;
}

const _dashboardNavigationGroups = <_DashboardNavigationGroup>[
  _DashboardNavigationGroup(
    englishLabel: 'GENERAL',
    spanishLabel: 'GENERAL',
    destinationIds: [Sections.home, Sections.chat],
  ),
  _DashboardNavigationGroup(
    englishLabel: 'OPERATIONS',
    spanishLabel: 'OPERACIONES',
    destinationIds: [
      Sections.invoices,
      Sections.invoiceClients,
      Sections.expenses,
      Sections.enableBanking,
      Sections.budgets,
    ],
  ),
  _DashboardNavigationGroup(
    englishLabel: 'MANAGEMENT',
    spanishLabel: 'GESTIÓN',
    destinationIds: [
      Sections.services,
      Sections.workers,
      Sections.calendar,
      Sections.maps,
      Sections.quickNotes,
    ],
  ),
  _DashboardNavigationGroup(
    englishLabel: 'COMMUNICATION',
    spanishLabel: 'COMUNICACIÓN',
    destinationIds: [
      Sections.businessChat,
      Sections.emails,
      Sections.telegram,
      Sections.notifications,
    ],
  ),
  _DashboardNavigationGroup(
    englishLabel: 'SETTINGS',
    spanishLabel: 'CONFIGURACIÓN',
    destinationIds: [Sections.settings],
  ),
];

List<HexoraNavDestination> _destinationsForGroup(
  _DashboardNavigationGroup group,
  List<HexoraNavDestination> destinations,
) =>
    [
      for (final id in group.destinationIds)
        for (final destination in destinations)
          if (destination.id == id) destination,
    ];

class _DashboardModuleSidebar extends StatefulWidget {
  const _DashboardModuleSidebar({
    required this.destinations,
    required this.activeId,
    required this.onSelected,
  });

  final List<HexoraNavDestination> destinations;
  final String activeId;
  final ValueChanged<String> onSelected;

  @override
  State<_DashboardModuleSidebar> createState() =>
      _DashboardModuleSidebarState();
}

class _DashboardModuleSidebarState extends State<_DashboardModuleSidebar> {
  bool _collapsed = true;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  CollapsibleSidebarItem _item(HexoraNavDestination destination) =>
      CollapsibleSidebarItem(
        icon: destination.icon,
        label: destination.label,
        selected: destination.id == widget.activeId,
        onTap: () => widget.onSelected(destination.id),
      );

  @override
  Widget build(BuildContext context) {
    final es = Localizations.localeOf(context).languageCode == 'es';
    final query = _searchController.text.trim().toLowerCase();
    final colors = Theme.of(context).colorScheme;
    final light = colors.brightness == Brightness.light;
    bool matches(HexoraNavDestination destination) =>
        query.isEmpty || destination.label.toLowerCase().contains(query);
    List<CollapsibleSidebarItem> entries(_DashboardNavigationGroup group) => [
          for (final destination
              in _destinationsForGroup(group, widget.destinations))
            if (matches(destination)) _item(destination),
        ];
    final groupedEntries = [
      for (final group in _dashboardNavigationGroups)
        (group: group, items: entries(group)),
    ];

    final sidebar = CollapsibleSidebar(
      title: es ? 'Módulos' : 'Modules',
      headerIcon: Icons.apps_rounded,
      menuExpandedWidth: 176,
      collapsedToggleInRail: true,
      collapsed: _collapsed,
      onToggleCollapsed: () => setState(() => _collapsed = !_collapsed),
      topContent: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: double.infinity,
            height: 38,
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _collapsed = true),
              icon: const Icon(Icons.keyboard_double_arrow_left_rounded,
                  size: 18),
              label: Text(es ? 'Compactar' : 'Compact'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(38),
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: colors.onSurface,
                iconColor: colors.onSurfaceVariant,
                backgroundColor: light
                    ? Color.alphaBlend(
                        colors.primary.withValues(alpha: 0.06), colors.surface)
                    : colors.surfaceContainerHigh,
                side: BorderSide(
                  color: colors.primary.withValues(alpha: light ? 0.22 : 0.4),
                ),
                overlayColor: NavigationColors(Theme.of(context).colorScheme)
                    .compactControlHover,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
                textStyle: NavigationTokens.label(context).copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _MenuSearchField(
            controller: _searchController,
            isSpanish: es,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      items: groupedEntries.first.items,
      groups: [
        for (final entry in groupedEntries.skip(1))
          if (entry.items.isNotEmpty)
            CollapsibleSidebarGroup(
              label: entry.group.label(es),
              items: entry.items,
            ),
      ],
      secondaryHeader: false,
      expandTooltip: es ? 'Expandir módulos' : 'Expand modules',
      collapseTooltip: es ? 'Contraer módulos' : 'Collapse modules',
    );
    return sidebar;
  }
}

class _MenuSearchField extends StatelessWidget {
  const _MenuSearchField({
    required this.controller,
    required this.isSpanish,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool isSpanish;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      height: 38,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        textAlignVertical: TextAlignVertical.center,
        style: NavigationTokens.label(context).copyWith(fontSize: 13),
        decoration: InputDecoration(
          hintText: isSpanish ? 'Buscar...' : 'Search...',
          hintStyle: NavigationTokens.label(context).copyWith(
            fontSize: 13,
            color: colors.onSurfaceVariant.withValues(alpha: 0.72),
          ),
          prefixIcon: Icon(Icons.search_rounded,
              size: 18, color: colors.onSurfaceVariant),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: isSpanish ? 'Limpiar búsqueda' : 'Clear search',
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                  icon: const Icon(Icons.close_rounded, size: 16),
                ),
          prefixIconConstraints:
              const BoxConstraints.tightFor(width: 36, height: 38),
          suffixIconConstraints:
              const BoxConstraints.tightFor(width: 34, height: 38),
          contentPadding: const EdgeInsets.only(right: 8),
          filled: true,
          fillColor: colors.brightness == Brightness.light
              ? Color.alphaBlend(
                  colors.primary.withValues(alpha: 0.04), colors.surface)
              : colors.surfaceContainerHigh,
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: colors.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: colors.outlineVariant.withValues(alpha: .85),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: colors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
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
        // The AI assistant has its own compact toolbar (Guiado/Preguntar).
        // Keep that toolbar at the top of the pane instead of repeating the
        // workspace selector directly above it. Other modules still retain
        // the selector in the global navigation bar.
        final showGroupSwitcher = activeSection != Sections.chat;
        return HexoraGlobalNavBar(
          destinations: const <HexoraNavDestination>[],
          activeId: activeSection,
          onSelected: state.openSection,
          onBrandTap: state.canSeeAdmin
              ? () => state.openSection(Sections.settings)
              : null,
          brandTooltip: es ? 'Ajustes del espacio' : 'Workspace settings',
          groupSwitcher: showGroupSwitcher
              ? _GroupSwitcherChip(
                  activeGroup: state.group,
                  userId: user?.id ?? '',
                  onOpenGroupSettings: () =>
                      state.openSection(Sections.settings),
                )
              : null,
          workspaceStatus: _TopWeatherChip(location: user?.location),
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
            data: IconThemeData(
                color: HexoraGlobalNavColors.foregroundFor(context)),
            child: DefaultTextStyle.merge(
              style: TextStyle(
                  color: HexoraGlobalNavColors.foregroundFor(context)),
              child: DownloadJobsTopMenu(
                groupId: state.group.id,
                onViewAllDownloads: () =>
                    state.openSection(Sections.notifications),
                compact: true,
              ),
            ),
          ),
          onlineMembers: state.canSeeAdmin
              ? WorkerStatusIndicator(
                  memberIds: memberIds.toList(),
                  groupRoles: state.group.userRoles,
                )
              : null,
          profile: UserProfilePopup(
            user: user,
            onSettings: () => state.openSection(Sections.settings),
          ),
          onBack: () => Navigator.of(context).maybePop(),
          backTooltip: l.groupSectionTitle,
        );
      },
    );
  }
}

// ── Group / workspace switcher ────────────────────────────────────────────────

class _TopWeatherChip extends StatefulWidget {
  const _TopWeatherChip({this.location});

  final String? location;

  @override
  State<_TopWeatherChip> createState() => _TopWeatherChipState();
}

class _TopWeatherChipState extends State<_TopWeatherChip> {
  final WeatherService _weatherService = WeatherService();
  late Future<WeatherBundle> _weather;

  String? get _location {
    final value = widget.location?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  @override
  void didUpdateWidget(covariant _TopWeatherChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location?.trim() != widget.location?.trim()) {
      _loadWeather();
    }
  }

  void _loadWeather() {
    final location = _location;
    _weather = location == null
        ? Future.value(const WeatherBundle(today: null, forecast: []))
        : _weatherService.fetchWeatherBundle(location: location, days: 1);
  }

  @override
  void dispose() {
    _weatherService.dispose();
    super.dispose();
  }

  IconData _weatherIcon(WeatherSnapshot weather) {
    final summary = weather.summary.summary.toLowerCase();
    if (summary.contains('storm')) return Icons.thunderstorm_outlined;
    if (summary.contains('rain')) return Icons.grain_rounded;
    if (summary.contains('cloud')) return Icons.wb_cloudy_outlined;
    return weather.isDay ? Icons.wb_sunny_rounded : Icons.nightlight_round;
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width < 1050) {
      return const SizedBox.shrink();
    }
    if (_location == null) return const SizedBox.shrink();

    final foreground = HexoraGlobalNavColors.foregroundFor(context);
    final l = AppLocalizations.of(context)!;

    return FutureBuilder<WeatherBundle>(
      future: _weather,
      builder: (context, snapshot) {
        final weather = snapshot.data?.today;
        if (snapshot.connectionState != ConnectionState.done) {
          return SizedBox(
            width: 36,
            height: 36,
            child: Center(
              child: SizedBox.square(
                dimension: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: foreground.withValues(alpha: 0.7),
                ),
              ),
            ),
          );
        }
        if (weather == null) return const SizedBox.shrink();

        final condition = localizeWeatherSummary(l, weather.summary.summary);
        final place = weather.cityName?.trim().isNotEmpty == true
            ? weather.cityName!.trim()
            : _location!;
        final temperature = '${weather.tempMax.round()}\u00b0C';

        return Tooltip(
          message:
              '$condition \u00b7 ${weather.tempMin.round()}\u00b0C\u2013${weather.tempMax.round()}\u00b0C',
          waitDuration: const Duration(milliseconds: 500),
          child: Container(
            height: 42,
            constraints: const BoxConstraints(minWidth: 170, maxWidth: 220),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: foreground.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: foreground.withValues(alpha: 0.05),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _weatherIcon(weather),
                  size: 24,
                  color: const Color(0xFFFFC83D),
                ),
                const SizedBox(width: 9),
                Flexible(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$temperature  $condition',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: NavigationTokens.label(context).copyWith(
                          color: foreground,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        place,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: NavigationTokens.label(context).copyWith(
                          color: foreground.withValues(alpha: 0.78),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          height: 1.1,
                        ),
                      ),
                    ],
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

class _GroupSwitcherChip extends StatelessWidget {
  const _GroupSwitcherChip({
    required this.activeGroup,
    required this.userId,
    required this.onOpenGroupSettings,
  });

  final Group activeGroup;
  final String userId;
  final VoidCallback onOpenGroupSettings;

  static const double _nameBreakpoint = 850;
  static const double _chipMaxNameWidth = 320.0;

  /// The group photo is shown when available; otherwise use the branded asset.
  Widget _avatar(Group group, double size, {Color? bg, Color? fg}) {
    final photoUrl = group.displayPhotoUrl;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          photoUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _defaultAvatar(size, bg),
        ),
      );
    }
    return _defaultAvatar(size, bg);
  }

  Widget _defaultAvatar(double size, [Color? bg]) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        image: const DecorationImage(
          image: AssetImage(HexoraBrandAssets.defaultBusinessImage),
          fit: BoxFit.cover,
        ),
        color: bg ?? const Color(0x26FFFFFF), // foreground @ 15 % alpha
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
                  builder: (context, fg) => _avatar(
                    activeGroup,
                    28,
                    fg: HexoraGlobalNavColors.foregroundFor(context),
                  ),
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
                    builder: (context, fg) => Tooltip(
                      message: activeGroup.name,
                      waitDuration: const Duration(milliseconds: 500),
                      child: ConstrainedBox(
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
