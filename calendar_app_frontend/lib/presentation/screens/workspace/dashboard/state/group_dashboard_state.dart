import 'dart:async';

import 'package:hexora/presentation/shared/widgets/navigation_popup_menu_item.dart';
import 'package:flutter/material.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/models/user/user.dart';
import 'package:hexora/services/groups/domain/group_domain.dart';
import 'package:hexora/services/user/domain/user_domain.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/state/group_dashboard_actions.dart';
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

  // UI
  String activeSection = Sections.calendar;
  String? invoicesInitialMenu;
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

  static const _restorableSections = {
    Sections.calendar,
    Sections.maps,
    Sections.businessChat,
    Sections.notifications,
    ..._adminOnlySections,
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

  void selectSection(String section) {
    if (section == Sections.chat && !canSeeAdmin) return;
    if (section == Sections.services && !canSeeAdmin) return;
    if (section == Sections.workers && !canSeeAdmin) return;
    _sectionChosenSinceOpen = true;
    if (activeSection == section) return;
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
  }) {
    invoicesInitialMenu = initialMenu;
    invoicesInitialInvoiceId = initialInvoiceId;
    invoicesInitialReceiptId = initialReceiptId;
    invoicesInitialBudgetId = initialBudgetId;
    invoicesNavigationRevision += 1;
    _sectionChosenSinceOpen = true;
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
    if (!_sectionChosenSinceOpen && user != null) {
      try {
        final preferences = await SharedPreferences.getInstance();
        final savedSection = preferences.getString(_sectionKey(user!.id));
        if (savedSection != null &&
            _restorableSections.contains(savedSection)) {
          activeSection = savedSection;
        }
      } catch (_) {
        // Fall back to the calendar when browser storage is unavailable.
      }
    }
    if (_adminOnlySections.contains(activeSection) && !canSeeAdmin) {
      activeSection = Sections.calendar;
    }

    if (refreshed != null) group = refreshed;

    notifyListeners();
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
