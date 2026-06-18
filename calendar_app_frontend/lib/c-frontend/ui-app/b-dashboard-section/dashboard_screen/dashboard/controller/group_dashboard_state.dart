import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/dashboard/controller/group_dasboard_actions.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/screens/group_dashboard_body_admin.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/screens/group_dashboard_body_member.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/screens/role_resolver.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/members/presentation/domain/models/members_count.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/calendar/screen/main_calendar_view.dart';
import 'package:hexora/c-frontend/utils/roles/group_role/group_role.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../controller/group_dashboard_sections.dart';

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
    _ud = context.read<UserDomain>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
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

    final ma = (!isWide && activeSection == Sections.emails) ? _mailBarActions : null;

    if (ma != null) {
      return AppBar(
        backgroundColor: topBarColor,
        elevation: 0.5,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: onTopBar),
        actionsIconTheme: IconThemeData(color: onTopBar),
        // Back arrow: detail view → back to thread list; list view → back to dashboard
        leading: IconButton(
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
                icon: const Icon(Icons.refresh_rounded),
                tooltip: l.refreshAction,
                onPressed: ma.onRefresh,
              ),
            // Hamburger moved to right side
            if (ma.onOpenFolderMenu != null)
              IconButton(
                icon: const Icon(Icons.menu_rounded),
                tooltip: l.mailConsoleFoldersTitle,
                onPressed: ma.onOpenFolderMenu,
              ),
          ],
          if (ma.isDetailView) ...[
            if (ma.onToggleRead != null)
              IconButton(
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
                    PopupMenuItem(
                      value: 'archive',
                      child: Row(children: [
                        const Icon(Icons.archive_outlined, size: 18),
                        const SizedBox(width: 10),
                        Text(l.mailDetailArchived),
                      ]),
                    ),
                  if (ma.onSpam != null)
                    PopupMenuItem(
                      value: 'spam',
                      child: Row(children: [
                        const Icon(Icons.report_gmailerrorred_outlined,
                            size: 18),
                        const SizedBox(width: 10),
                        Text(l.mailDetailSpammed),
                      ]),
                    ),
                  if (ma.onTrash != null)
                    PopupMenuItem(
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
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
      title: isWide
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
            tooltip: l.groupNotificationsSectionTitle,
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => openSection(Sections.notifications),
          ),
        if (!isWide && canSeeAdmin)
          IconButton(
            tooltip: l.groupSettingsTitle,
            icon: const Icon(Icons.tune_rounded),
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

