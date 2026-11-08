import 'dart:async';

import 'package:hexora/presentation/shared/widgets/navigation_popup_menu_item.dart';
import 'package:flutter/material.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/models/user/user.dart';
import 'package:hexora/services/groups/domain/group_domain.dart';
import 'package:hexora/services/user/domain/user_domain.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/state/group_dashboard_actions.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/layout/download_jobs_top_menu.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/panels/settings/sections/settings_generated_files_section.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/overview/group_dashboard_body_admin.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/overview/group_dashboard_body_member.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/access/role_resolver.dart';
import 'package:hexora/presentation/screens/workspace/sections/members/presentation/domain/models/members_count.dart';
import 'package:hexora/presentation/screens/calendar/screens/calendar/screen/main_calendar_view.dart';
import 'package:hexora/presentation/utils/roles/group_role.dart';
import 'package:hexora/theme/colors/theme_colors.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/theme/components/themed_buttons.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/tabs/workspace_tab.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/tabs/workspace_tab_manager.dart';

import '../navigation/dashboard_sections.dart';

/// Actions the mail console can inject into the parent AppBar on mobile.
class MailBarActions {
  const MailBarActions({
    required this.title,
    required this.isDetailView,
    this.onBack,
    this.onOpenFolderMenu,
    this.onRefresh,
    this.onCompose,
    this.hasUnread,
    this.onToggleRead,
    this.onArchive,
    this.onSpam,
    this.onTrash,
  });

  final String title;
  final bool isDetailView;
  final VoidCallback? onBack;
  final VoidCallback? onOpenFolderMenu;
  final VoidCallback? onRefresh;
  final VoidCallback? onCompose;
  final bool? hasUnread;
  final VoidCallback? onToggleRead;
  final VoidCallback? onArchive;
  final VoidCallback? onSpam;
  final VoidCallback? onTrash;
}

class GroupDashboardState extends ChangeNotifier {
  GroupDashboardState(this.context, this.group) {
    workspaceTabs = WorkspaceTabManager(businessId: group.id)
      ..addListener(_onWorkspaceTabChanged);
    _gm = context.read<GroupDomain>();
    _gm.addListener(_onGroupUpdated);
    _ud = context.read<UserDomain>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  Group? _observedGroupUpdate;

  void _onGroupUpdated() {
    final updated = _gm.lastUpdatedGroup;
    if (updated != null &&
        updated.id == group.id &&
        !identical(updated, _observedGroupUpdate)) {
      _observedGroupUpdate = updated;
      updateGroup(updated);
    }
  }

  @override
  void dispose() {
    _gm.removeListener(_onGroupUpdated);
    workspaceTabs.removeListener(_onWorkspaceTabChanged);
    workspaceTabs.dispose();
    super.dispose();
  }

  // Dependencies
  final BuildContext context;
  late final GroupDomain _gm;
  late final UserDomain _ud;

  // Data
  Group group;
  MembersCount? counts;
  GroupRole? role;
  User? user;
  late final WorkspaceTabManager workspaceTabs;

  // UI
  String activeSection = Sections.calendar;
  String? invoicesInitialMenu = 'invoices_issued';
  String? invoicesInitialInvoiceId;
  String? invoicesInitialReceiptId;
  String? invoicesInitialBudgetId;
  int invoicesNavigationRevision = 0;
  bool _sectionChosenSinceOpen = false;

  static const _adminOnlySections = {
    Sections.services,
    Sections.invoices,
    Sections.budgets,
    Sections.expenses,
    Sections.emails,
    Sections.chat,
    Sections.enableBanking,
    Sections.telegram,
    Sections.settings,
    Sections.workers,
  };

  static const _workspaceSections = {
    Sections.agenda,
    Sections.calendar,
    Sections.notifications,
    Sections.settings,
    Sections.members,
    Sections.services,
    Sections.maps,
    Sections.workers,
    Sections.invoices,
    Sections.budgets,
    Sections.expenses,
    Sections.emails,
    Sections.chat,
    Sections.businessChat,
    Sections.enableBanking,
    Sections.telegram,
  };

  String _sectionKey(String userId) =>
      'hexora.dashboard_section.$userId.${group.id}';

  Future<void> _rememberSection(String userId, String section) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_sectionKey(userId), section);
    } catch (_) {
      // Browser storage can be unavailable without blocking navigation.
    }
  }

  void _onWorkspaceTabChanged() {
    final active = workspaceTabs.activeTab;
    activeSection = active?.section ?? '';
    final userId = user?.id;
    if (userId != null && active != null) {
      unawaited(_rememberSection(userId, active.section));
    }
    // Desktop workspace consumers listen to workspaceTabs directly. Notifying
    // the root dashboard provider here rebuilt the complete Scaffold whenever
    // a tab was activated or closed, producing a visible full-screen refresh.
    // Mobile navigation still relies on the dashboard notifier.
    if (!isWide) notifyListeners();
  }

  void selectSection(String section) {
    if (section == Sections.chat && !canSeeAdmin) return;
    if (section == Sections.services && !canSeeAdmin) return;
    if (section == Sections.workers && !canSeeAdmin) return;
    _sectionChosenSinceOpen = true;
    if (isWide) {
      workspaceTabs.openOrActivateTab(_tabForSection(section));
      return;
    }
    if (activeSection == section) return;
    if (section == Sections.invoices) {
      invoicesInitialMenu = 'invoices_issued';
      invoicesInitialInvoiceId = null;
      invoicesInitialReceiptId = null;
      invoicesInitialBudgetId = null;
      invoicesNavigationRevision += 1;
    }
    activeSection = section;
    final userId = user?.id;
    if (userId != null) unawaited(_rememberSection(userId, section));
    notifyListeners();
  }

  void openInvoicesWorkspace({
    required String initialMenu,
    String? initialInvoiceId,
    String? initialReceiptId,
    String? initialBudgetId,
    String? tabTitle,
  }) {
    invoicesInitialMenu = initialMenu;
    invoicesInitialInvoiceId = initialInvoiceId;
    invoicesInitialReceiptId = initialReceiptId;
    invoicesInitialBudgetId = initialBudgetId;
    invoicesNavigationRevision += 1;
    _sectionChosenSinceOpen = true;
    if (isWide) {
      final identity = initialInvoiceId != null
          ? 'invoice:$initialInvoiceId'
          : initialReceiptId != null
              ? 'receipt:$initialReceiptId'
              : initialBudgetId != null
                  ? 'budget:$initialBudgetId'
                  : _invoiceMenuIdentity(initialMenu);
      final workspaceIdentity = WorkspaceTabIdentity(identity);
      if (workspaceTabs.isDirty(workspaceIdentity)) {
        workspaceTabs.activateTab(workspaceIdentity);
        return;
      }
      workspaceTabs.openOrActivateTab(
        _tabForSection(
          Sections.invoices,
          identity: identity,
          title: tabTitle ??
              _invoiceTabTitle(
                initialMenu,
                invoiceId: initialInvoiceId,
                receiptId: initialReceiptId,
                budgetId: initialBudgetId,
              ),
          arguments: <String, String>{
            'initialMenu': initialMenu,
            'navigationRevision': invoicesNavigationRevision.toString(),
            if (initialInvoiceId != null) 'initialInvoiceId': initialInvoiceId,
            if (initialReceiptId != null) 'initialReceiptId': initialReceiptId,
            if (initialBudgetId != null) 'initialBudgetId': initialBudgetId,
          },
        ),
      );
      return;
    }
    activeSection = Sections.invoices;
    final userId = user?.id;
    if (userId != null) {
      unawaited(_rememberSection(userId, Sections.invoices));
    }
    notifyListeners();
  }

  CalendarDashboardActions? calendarActions;

  void setCalendarActions(CalendarDashboardActions? actions) {
    if (calendarActions == actions) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (calendarActions == actions) return;
      calendarActions = actions;
      notifyListeners();
    });
  }

  MailBarActions? _mailBarActions;
  MailBarActions? get mailBarActions => _mailBarActions;

  void setMailBarActions(MailBarActions? actions) {
    _mailBarActions = actions;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        notifyListeners();
      } catch (_) {}
    });
  }

  // Breakpoints
  double get wideBreakpoint => 900;
  double get ultraWideBreakpoint => 1300;

  bool get isWide => MediaQuery.of(context).size.width >= wideBreakpoint;

  bool get isUltraWide =>
      MediaQuery.of(context).size.width >= ultraWideBreakpoint;

  bool get isLoading => role == null || user == null;
  Future<String?> Function(String) get fetchReadSas => _fetchReadSas;
  Future<String?> _fetchReadSas(String blobName) async {
    try {
      return await _ud.userRepository.getFreshAvatarUrl(blobName: blobName);
    } catch (_) {
      return null;
    }
  }

  // ---------------- LOAD DATA ----------------

  Future<void> _loadAll() async {
    counts = await _gm.groupRepository.getMembersCount(group.id, mode: 'union');

    Group? refreshed;
    try {
      refreshed = await _gm.groupRepository.getGroupById(group.id);
    } catch (_) {}

    final target = refreshed ?? group;

    role = await RoleResolver.resolve(group: target, userDomain: _ud);
    user = await _getSafeUser();
    if (isWide && user != null && workspaceTabs.tabs.isEmpty) {
      await workspaceTabs.configureSession(user!.id);
      final restored = await workspaceTabs.restore(
        resolver: _restoreWorkspaceTab,
      );
      if (!restored) {
        workspaceTabs.openOrActivateTab(
          _tabForSection(canSeeAdmin ? Sections.invoices : Sections.calendar),
        );
      }
    }
    if (!_sectionChosenSinceOpen && canSeeAdmin) {
      if (!isWide) activeSection = Sections.invoices;
      invoicesInitialMenu = 'invoices_issued';
    }
    if (_adminOnlySections.contains(activeSection) && !canSeeAdmin) {
      activeSection = Sections.calendar;
    }

    if (refreshed != null) group = refreshed;

    notifyListeners();
  }

  WorkspaceTab? _restoreWorkspaceTab(WorkspaceTabSnapshot snapshot) {
    if (!_workspaceSections.contains(snapshot.section)) return null;
    if (_adminOnlySections.contains(snapshot.section) && !canSeeAdmin) {
      return null;
    }

    // Workspace persistence deliberately excludes unsaved form state. An
    // editor tab without the document it was editing cannot be restored into
    // a useful workflow: it opens a blank form and immediately presents
    // validation such as “Select a client to continue”. Restore the durable
    // invoices landing view instead. Existing invoice, receipt and budget
    // editor tabs retain their IDs and continue to restore normally.
    if (snapshot.section == Sections.invoices &&
        _isTransientInvoiceEditorSnapshot(snapshot)) {
      return _tabForSection(
        Sections.invoices,
        identity: Sections.invoices,
        arguments: const {'initialMenu': 'invoices_issued'},
      );
    }
    var restoredTitle = snapshot.title;
    if (snapshot.section == Sections.invoices) {
      final documentIds = <String>[
        snapshot.arguments['initialInvoiceId'] ?? '',
        snapshot.arguments['initialReceiptId'] ?? '',
        snapshot.arguments['initialBudgetId'] ?? '',
      ].where((id) => id.isNotEmpty);
      if (documentIds.any(restoredTitle.contains)) {
        restoredTitle = _invoiceTabTitle(
          snapshot.arguments['initialMenu'] ?? '',
          invoiceId: snapshot.arguments['initialInvoiceId'],
          receiptId: snapshot.arguments['initialReceiptId'],
          budgetId: snapshot.arguments['initialBudgetId'],
        );
      }
    }
    return _tabForSection(
      snapshot.section,
      identity: snapshot.identity,
      title: restoredTitle,
      arguments: snapshot.arguments,
    );
  }

  bool _isTransientInvoiceEditorSnapshot(WorkspaceTabSnapshot snapshot) {
    final menu = (snapshot.arguments['initialMenu'] ?? '').trim();
    if (menu == 'invoice_editor') {
      return (snapshot.arguments['initialInvoiceId'] ?? '').trim().isEmpty;
    }
    if (menu == 'receipt_editor') {
      return (snapshot.arguments['initialReceiptId'] ?? '').trim().isEmpty;
    }
    if (menu == 'budgets_new') {
      return (snapshot.arguments['initialBudgetId'] ?? '').trim().isEmpty;
    }
    return snapshot.identity == 'invoice:new';
  }

  WorkspaceTab _tabForSection(
    String section, {
    String? identity,
    String? title,
    Map<String, String> arguments = const <String, String>{},
  }) {
    final l = AppLocalizations.of(context)!;
    final es = l.localeName.startsWith('es');
    final defaults = switch (section) {
      Sections.invoices => (
          Icons.receipt_long_outlined,
          es ? 'Ingresos' : 'Income'
        ),
      Sections.expenses => (
          Icons.trending_down_rounded,
          es ? 'Gastos' : 'Expenses'
        ),
      Sections.enableBanking => (
          Icons.account_balance_outlined,
          es ? 'Banco' : 'Bank'
        ),
      Sections.calendar => (Icons.calendar_month_rounded, l.calendar),
      Sections.budgets => (
          Icons.description_outlined,
          es ? 'Propuestas' : 'Proposals'
        ),
      Sections.businessChat => (Icons.chat_bubble_outline_rounded, 'Chat'),
      Sections.maps => (Icons.map_outlined, es ? 'Mapa' : 'Map'),
      Sections.emails => (Icons.email_outlined, 'Emails'),
      Sections.workers => (
          Icons.access_time_rounded,
          es ? 'Trabajadores' : 'Workers'
        ),
      Sections.chat => (
          Icons.auto_awesome_outlined,
          es ? 'Asistente IA' : 'AI assistant'
        ),
      Sections.telegram => (Icons.telegram, 'Telegram'),
      Sections.settings => (
          Icons.settings_outlined,
          es ? 'Ajustes' : 'Settings'
        ),
      Sections.notifications => (
          Icons.notifications_none_rounded,
          l.notifications
        ),
      Sections.agenda => (Icons.event_note_outlined, es ? 'Agenda' : 'Agenda'),
      Sections.services => (
          Icons.people_outline_rounded,
          es ? 'Clientes' : 'Clients'
        ),
      Sections.members => (Icons.groups_outlined, es ? 'Miembros' : 'Members'),
      _ => (Icons.dashboard_outlined, section),
    };
    return WorkspaceTab(
      identity: WorkspaceTabIdentity(identity ?? section),
      section: section,
      title: title?.trim().isNotEmpty == true ? title!.trim() : defaults.$2,
      icon: defaults.$1,
      arguments: Map.unmodifiable(arguments),
    );
  }

  String _invoiceMenuIdentity(String menu) {
    final normalized = menu.toLowerCase();
    if (normalized.contains('create') || normalized.contains('new')) {
      return 'invoice:new';
    }
    if (normalized == 'invoices_issued' || normalized.isEmpty) {
      return Sections.invoices;
    }
    return 'invoices:$normalized';
  }

  String _invoiceTabTitle(
    String menu, {
    String? invoiceId,
    String? receiptId,
    String? budgetId,
  }) {
    final es = Localizations.localeOf(context).languageCode == 'es';
    final normalized = menu.toLowerCase();
    // Document IDs remain part of the stable workspace identity and routing,
    // but are not meaningful labels for users. Callers pass a document number
    // through tabTitle when it is already available; otherwise use a localized
    // fallback until the loaded editor updates the title from its metadata.
    if (invoiceId != null) {
      if (normalized.contains('draft')) {
        return es ? 'Borrador de factura' : 'Invoice draft';
      }
      return es ? 'Factura' : 'Invoice';
    }
    if (receiptId != null) return es ? 'Recibo' : 'Receipt';
    if (budgetId != null) return es ? 'Presupuesto' : 'Proposal';
    if (normalized.contains('create') || normalized.contains('new')) {
      return es ? 'Nueva factura' : 'New invoice';
    }
    if (normalized.contains('receipt') || normalized.contains('recibo')) {
      return es ? 'Recibos' : 'Receipts';
    }
    if (normalized.contains('budget') || normalized.contains('presupuesto')) {
      return es ? 'Presupuestos' : 'Proposals';
    }
    if (normalized.contains('recurring')) {
      return es ? 'Facturas recurrentes' : 'Recurring invoices';
    }
    return es ? 'Ingresos' : 'Income';
  }

  Future<User?> _getSafeUser() async {
    try {
      final u = await _ud.getUser();
      if (u != null) return u;
    } catch (_) {}

    try {
      final dynamic u = (_ud as dynamic).currentUser;
      if (u is User) return u;
    } catch (_) {}

    return null;
  }

  // ---------------- ACTIONS ----------------

  void openSection(String section) =>
      DashboardActions.openSection(this, section);

  Future<void> refreshCounts() async {
    counts = await _gm.groupRepository.getMembersCount(group.id, mode: 'union');
    notifyListeners();
  }

  void updateGroup(Group updated) {
    group = updated;
    notifyListeners();
  }

  // ---------------- UI HELPERS ----------------

  bool get canSeeAdmin =>
      role == GroupRole.owner ||
      role == GroupRole.admin ||
      role == GroupRole.coAdmin;

  bool get showBottomBar => !isWide;

  Color get backdrop => ThemeColors.containerBg(context);

  // Builds the top app bar (previously inside build())
  AppBar buildAppBar() {
    final t = AppTypography.of(context);
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final topBarColor = backdrop;
    final onTopBar = theme.colorScheme.onSurface;
    final iconButtonStyle = ThemedButtons.iconAction(context);

    final ma =
        (!isWide && activeSection == Sections.emails) ? _mailBarActions : null;

    if (ma != null) {
      return AppBar(
        backgroundColor: topBarColor,
        elevation: 0.5,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: onTopBar),
        actionsIconTheme: IconThemeData(color: onTopBar),
        // Back arrow: detail view → back to thread list; list view → back to dashboard
        leading: IconButton(
          style: iconButtonStyle,
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: ma.isDetailView
              ? ma.onBack
              : () {
                  activeSection = Sections.calendar;
                  notifyListeners();
                },
        ),
        title: Text(
          ma.title,
          style: t.bodyLarge.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
            color: onTopBar,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (!ma.isDetailView) ...[
            if (ma.onRefresh != null)
              IconButton(
                style: iconButtonStyle,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: l.refreshAction,
                onPressed: ma.onRefresh,
              ),
            // Hamburger moved to right side
            if (ma.onOpenFolderMenu != null)
              IconButton(
                style: iconButtonStyle,
                icon: const Icon(Icons.menu_rounded),
                tooltip: l.mailConsoleFoldersTitle,
                onPressed: ma.onOpenFolderMenu,
              ),
          ],
          if (ma.isDetailView) ...[
            if (ma.onToggleRead != null)
              IconButton(
                style: iconButtonStyle,
                icon: Icon(
                  ma.hasUnread == true
                      ? Icons.mark_email_read_outlined
                      : Icons.mark_email_unread_outlined,
                ),
                tooltip: ma.hasUnread == true
                    ? l.mailDetailMarkRead
                    : l.mailDetailMarkUnread,
                onPressed: ma.onToggleRead,
              ),
            if (ma.onArchive != null || ma.onTrash != null)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (v) {
                  if (v == 'archive') ma.onArchive?.call();
                  if (v == 'spam') ma.onSpam?.call();
                  if (v == 'trash') ma.onTrash?.call();
                },
                itemBuilder: (_) => [
                  if (ma.onArchive != null)
                    NavigationPopupMenuItem(
                      value: 'archive',
                      child: Row(children: [
                        const Icon(Icons.archive_outlined, size: 18),
                        const SizedBox(width: 10),
                        Text(l.mailDetailArchived),
                      ]),
                    ),
                  if (ma.onSpam != null)
                    NavigationPopupMenuItem(
                      value: 'spam',
                      child: Row(children: [
                        const Icon(Icons.report_gmailerrorred_outlined,
                            size: 18),
                        const SizedBox(width: 10),
                        Text(l.mailDetailSpammed),
                      ]),
                    ),
                  if (ma.onTrash != null)
                    NavigationPopupMenuItem(
                      value: 'trash',
                      child: Row(children: [
                        const Icon(Icons.delete_outline_rounded, size: 18),
                        const SizedBox(width: 10),
                        Text(l.mailDetailTrashed),
                      ]),
                    ),
                ],
              ),
          ],
        ],
        bottom: null,
      );
    }

    return AppBar(
      backgroundColor: topBarColor,
      elevation: 0.5,
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: onTopBar),
      actionsIconTheme: IconThemeData(color: onTopBar),
      toolbarHeight: isWide ? 0 : null,
      titleSpacing: isWide ? 0 : null,
      automaticallyImplyLeading: !isWide,
      leadingWidth: isWide ? 0 : null,
      leading: isWide
          ? const SizedBox.shrink()
          : IconButton(
              style: iconButtonStyle,
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
      title: isWide || activeSection == Sections.calendar
          ? null
          : Text(
              group.name,
              style: t.bodyLarge.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
                color: onTopBar,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      actions: [
        if (!isWide)
          DownloadJobsTopMenu(
            groupId: group.id,
            onViewAllDownloads: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (routeContext) => Scaffold(
                  appBar: AppBar(
                    title: Text(
                      Localizations.localeOf(routeContext).languageCode == 'es'
                          ? 'Descargas'
                          : 'Downloads',
                    ),
                  ),
                  body: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: SettingsGeneratedFilesSection(group: group),
                  ),
                ),
              ),
            ),
            compact: true,
            openInNotifications: false,
          ),
        if (!isWide)
          IconButton(
            style: iconButtonStyle,
            tooltip: l.groupNotificationsSectionTitle,
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => openSection(Sections.notifications),
          ),
        if (!isWide && canSeeAdmin)
          IconButton(
            style: iconButtonStyle,
            tooltip: l.groupSettingsTitle,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => openSection(Sections.settings),
          ),
      ],
      bottom: null,
    );
  }

  // dashboardBody abstraction
  Widget get dashboardBody {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    return canSeeAdmin
        ? GroupDashboardBodyAdmin(
            group: group,
            counts: counts,
            onRefresh: refreshCounts,
            user: user!,
            role: role!,
            onGroupChanged: updateGroup,
            fetchReadSas: _fetchReadSas,
          )
        : GroupDashboardBodyMember(
            group: group,
            user: user!,
            role: role!,
            fetchReadSas: _fetchReadSas,
          );
  }
}
