// lib/c-frontend/b-dashboard-section/sections/members/presentation/screen/review_user_screen.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/group_mng_flow/group/view_model/group_view_model.dart';
import 'package:hexora/b-backend/user/repository/i_user_repository.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/members/presentation/controller/add_user_controller.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/members/presentation/controller/contract_for_controller/interface/IGroup_editor_port.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/members/presentation/controller/contract_for_controller/service/vm_group_editor_port.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/members/presentation/screen/tabs/add_user_tab.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/members/presentation/screen/tabs/update_role_tab.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/members/presentation/widgets/add_users_flow/add_user_bottom_sheet.dart';
import 'package:hexora/c-frontend/utils/roles/group_role/group_role.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class ReviewAndAddUsersScreen extends StatefulWidget {
  const ReviewAndAddUsersScreen({super.key});

  @override
  State<ReviewAndAddUsersScreen> createState() =>
      _ReviewAndAddUsersScreenState();
}

class _ReviewAndAddUsersScreenState extends State<ReviewAndAddUsersScreen> {
  bool _seeded = false;

  Future<void> _seedVmFromGroupOnce(BuildContext context) async {
    if (_seeded) return;

    final group = context.read<GroupDomain>().currentGroup;
    if (group == null) return;

    final repo = context.read<IUserRepository>();
    final port = context.read<IGroupEditorPort>();

    // Build members map (id -> User)
    final Map<String, User> membersById = {};
    for (final id in group.userIds) {
      try {
        final u = await repo.getUserById(id);
        membersById[u.id] = u;
      } catch (_) {
        // ignore a failing user; continue seeding others
      }
    }

    // Build roles map (id -> GroupRole)
    final Map<String, GroupRole> roles = {};
    group.userRoles.forEach((userId, wire) {
      roles[userId] = GroupRoleX.from(wire);
    });

    await port.seedMembers(membersById: membersById, roles: roles);
    if (mounted) setState(() => _seeded = true);
  }

  @override
  void initState() {
    super.initState();
    // Run seeding after first frame so Providers are available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _seedVmFromGroupOnce(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final l = AppLocalizations.of(context)!;

    return MultiProvider(
      providers: [
        // Port backed by the GroupEditorViewModel
        ProxyProvider<GroupEditorViewModel, IGroupEditorPort>(
          update: (_, vm, __) => VmGroupEditorPort(vm),
        ),
        // Screen-scoped controller that stages added users before commit
        ChangeNotifierProvider<AddUserController>(
          create: (ctx) =>
              AddUserController(port: ctx.read<IGroupEditorPort>()),
        ),
      ],
      child: DefaultTabController(
        length: 2,
        child: Builder(
          builder: (context) {
            final port = context.watch<IGroupEditorPort>();
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
                      // Make sure staged selections are applied to the VM
                      ctrl.commitSelected(context);

                      // Return VM truth to caller
                      final members = port.membersById.values.toList();
                      final rolesWire = {
                        for (final e in port.roles.entries) e.key: e.value.wire,
                      };

                      Navigator.of(context).maybePop({
                        'users': members, // List<User>
                        'roles': rolesWire, // Map<String, String>
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
                iconTheme:
                    IconThemeData(color: ThemeColors.textPrimary(context)),
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
                        border:
                            Border.all(color: cs.onSurface.withOpacity(0.06)),
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
                  // Tab 1 — roles from VM via Port (now seeded with real members)
                  UpdateRolesTab(
                    rolesByUserId: port.roles,
                    membersById: port.membersById,
                    assignableRoles: const [
                      GroupRole.member,
                      GroupRole.coAdmin,
                      GroupRole.admin,
                      GroupRole.owner,
                    ],
                    canEditRole: (userId) => port.canEditRole(userId),
                    setRole: (userId, r) => port.setRole(userId, r),
                  ),

                  // Tab 2 — stage additions, then commit to VM
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
              // FAB intentionally removed; use the FilledButton in AddUsersTab
            );
          },
        ),
      ),
    );
  }
}
