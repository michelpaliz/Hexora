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
import 'package:hexora/f-themes/app_colors/palette/app_colors/app_colors.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../controller/group_dashboard_sections.dart';

class GroupDashboardState extends ChangeNotifier {
  GroupDashboardState(this.context, this.group) {
    _gm = context.read<GroupDomain>();
    _ud = context.read<UserDomain>();
    _loadAll();
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
    calendarActions = actions;
    notifyListeners();
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
    final isDark = theme.brightness == Brightness.dark;

    final topBarColor =
        isDark ? AppDarkColors.dashboardTopBar : AppColors.dashboardTopBar;
    final onTopBar = isDark ? AppDarkColors.textPrimary : AppColors.white;

    final menuItems = [
      (l.goToCalendar, Icons.calendar_month_rounded, Sections.calendar),
      (
        l.servicesClientsTitle,
        Icons.design_services_outlined,
        Sections.services
      ),
      if (canSeeAdmin)
        (l.invoicesNavLabel, Icons.receipt_long_outlined, Sections.invoices),
      if (canSeeAdmin)
        ('Enable Banking', Icons.account_balance_outlined, 'enableBanking'),
      (l.insightsTitle, Icons.insights_outlined, Sections.insights),
      (l.timeTrackingTitle, Icons.access_time_rounded, Sections.workers),
    ];

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
      bottom: isWide
          ? PreferredSize(
              preferredSize: const Size.fromHeight(55),
              child: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.black.withOpacity(0.2),
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.14),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: canSeeAdmin
                          ? () => openSection(Sections.settings)
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundImage:
                              group.photoUrl?.trim().isNotEmpty == true
                                  ? NetworkImage(group.photoUrl!.trim())
                                  : null,
                          backgroundColor: onTopBar.withOpacity(0.2),
                          child: group.photoUrl?.trim().isNotEmpty == true
                              ? null
                              : Icon(
                                  Icons.business_rounded,
                                  color: onTopBar,
                                  size: 20,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: menuItems
                              .map(
                                (item) => _DashboardTopMenuItem(
                                  label: item.$1,
                                  icon: item.$2,
                                  selected: activeSection == item.$3,
                                  onTap: () => openSection(item.$3),
                                  color: onTopBar,
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                    if (activeSection == Sections.calendar &&
                        calendarActions != null) ...[
                      const SizedBox(width: 8),
                      ValueListenableBuilder<bool>(
                        valueListenable: calendarActions!.leftPanelCollapsed,
                        builder: (_, collapsed, __) {
                          return IconButton(
                            tooltip: collapsed
                                ? 'Expand left panel'
                                : 'Collapse left panel',
                            icon: Icon(
                              collapsed
                                  ? Icons.chevron_right_rounded
                                  : Icons.chevron_left_rounded,
                              color: onTopBar,
                            ),
                            onPressed: calendarActions!.onToggleLeftPanel,
                          );
                        },
                      ),
                      if (calendarActions!.canAddEvents) ...[
                        const SizedBox(width: 4),
                        FilledButton.icon(
                          onPressed: calendarActions!.onAddEvent,
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: Text(
                            l.addEvent,
                            style: t.bodySmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: onTopBar,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: onTopBar.withOpacity(0.2),
                            foregroundColor: onTopBar,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            )
          : null,
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

class _DashboardTopMenuItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  const _DashboardTopMenuItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final bg = selected ? color.withOpacity(0.18) : Colors.transparent;
    final fg = selected ? color : color.withOpacity(0.85);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: t.bodySmall.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
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
