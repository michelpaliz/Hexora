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

    return AppBar(
      backgroundColor: topBarColor,
      elevation: 0.5,
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: onTopBar),
      actionsIconTheme: IconThemeData(color: onTopBar),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: Text(
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
        IconButton(
          tooltip: l.groupNotificationsSectionTitle,
          icon: const Icon(Icons.notifications_none_rounded),
          onPressed: () => openSection(Sections.notifications),
        ),
        if (canSeeAdmin)
          IconButton(
            tooltip: l.groupSettingsTitle,
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => openSection(Sections.settings),
          ),
      ],
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
