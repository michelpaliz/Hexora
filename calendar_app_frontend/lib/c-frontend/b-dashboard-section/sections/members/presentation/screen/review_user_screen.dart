// lib/c-frontend/b-dashboard-section/sections/members/presentation/screen/review_user_screen.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/user/repository/i_user_repository.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/members/presentation/controller/add_user_controller.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/members/presentation/screen/tabs/add_user_tab.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/members/presentation/screen/tabs/update_role_tab.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/members/presentation/widgets/add_users_flow/add_user_bottom_sheet.dart';
import 'package:hexora/c-frontend/utils/roles/group_role/group_role.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class ReviewAndAddUsersScreen extends StatelessWidget {
  const ReviewAndAddUsersScreen({
    super.key,
    required this.currentUser,
    required this.group,
    required this.userRepository,
  });

  final User? currentUser;
  final Group group;
  final IUserRepository userRepository;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final l = AppLocalizations.of(context)!;

    return ChangeNotifierProvider(
      create: (_) => AddUserController(
        currentUser: currentUser,
        group: group,
        userRepositoryInterface: userRepository,
      ),
      child: DefaultTabController(
        length: 2,
        child: Builder(builder: (context) {
          final ctrl = context.watch<AddUserController>();

          final Color primary = cs.primary;
          final Color selectedText = ThemeColors.contrastOn(primary);
          final Color unselectedText =
              ThemeColors.textPrimary(context).withOpacity(0.7);
          final Color trackBg = ThemeColors.cardBg(context);

          return Scaffold(
            appBar: AppBar(
              title: Text(
                l.reviewUsersTitle,
                style: t.titleLarge.copyWith(fontWeight: FontWeight.w800),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).maybePop({
                      'users': ctrl.usersInGroup,
                      // ✅ send strings back to caller/backend
                      'roles': ctrl.rolesAsWire,
                    });
                  },
                  child: Text(
                    l.done,
                    style: t.bodyLarge.copyWith(
                      color: ThemeColors.contrastOn(cs.primary),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              backgroundColor: cs.surface,
              iconTheme: IconThemeData(color: ThemeColors.textPrimary(context)),
              elevation: 0,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: trackBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.onSurface.withOpacity(0.06)),
                    ),
                    child: TabBar(
                      tabs: [
                        Tab(text: l.tabUpdateRoles),
                        Tab(text: l.tabAddUsers),
                      ],
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: selectedText,
                      unselectedLabelColor: unselectedText,
                      labelStyle: t.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: .2,
                      ),
                      unselectedLabelStyle: t.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: .2,
                      ),
                      indicator: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      splashBorderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
            body: TabBarView(
              children: [
                // ===== Tab 1: Update roles =====
                UpdateRolesTab(
                  // ✅ pass enum map directly
                  rolesByUserId: ctrl.userRoles,
                  membersById: {
                    for (final u in ctrl.usersInGroup) u.id: u,
                  },
                  assignableRoles: const [
                    GroupRole.member,
                    GroupRole.coAdmin,
                    GroupRole.admin,
                    GroupRole.owner,
                  ],
                  canEditRole: (userId) => ctrl.canEditRole(userId),
                  // ✅ pass enum to controller (not wire)
                  setRole: (userId, r) => ctrl.changeRole(userId, r),
                ),

                // ===== Tab 2: Add users =====
                AddUsersTab(
                  openPicker: () async {
                    await showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      builder: (_) => ChangeNotifierProvider.value(
                        value: context.read<AddUserController>(),
                        child: const AddUsersBottomSheet(),
                      ),
                    );
                  },
                ),
              ],
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
            floatingActionButton: Builder(
              builder: (context) {
                final tCtrl = DefaultTabController.of(context);
                if (tCtrl.index == 1) {
                  return FloatingActionButton.extended(
                    icon: const Icon(Icons.person_add_alt_1),
                    label: Text(
                      l.addUsersCount(
                        context.watch<AddUserController>().usersInGroup.length,
                      ),
                      style: t.buttonText,
                    ),
                    onPressed: () async {
                      await showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        builder: (_) => ChangeNotifierProvider.value(
                          value: context.read<AddUserController>(),
                          child: const AddUsersBottomSheet(),
                        ),
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          );
        }),
      ),
    );
  }
}
