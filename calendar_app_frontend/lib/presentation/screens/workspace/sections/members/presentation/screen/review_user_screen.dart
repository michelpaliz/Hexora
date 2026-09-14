import 'package:flutter/material.dart';
import 'package:hexora/models/user_model/user.dart';
import 'package:hexora/services/groups/domain/group_domain.dart';
import 'package:hexora/services/user/domain/user_domain.dart';
import 'package:hexora/services/user/repository/i_user_repository.dart';
import 'package:hexora/presentation/screens/workspace/sections/members/presentation/controller/add_user_controller.dart';
import 'package:hexora/presentation/screens/workspace/sections/members/presentation/controller/contract_for_controller/interface/IGroup_editor_port.dart';
import 'package:hexora/presentation/screens/workspace/sections/members/presentation/controller/contract_for_controller/service/vm_group_editor_port.dart';
import 'package:hexora/presentation/screens/workspace/sections/members/presentation/screen/tabs/add_user_tab.dart';
import 'package:hexora/presentation/screens/workspace/sections/members/presentation/screen/tabs/update_role_tab.dart';
import 'package:hexora/presentation/screens/workspace/sections/members/presentation/widgets/add_users_flow/widgets/add_user_bottom_sheet.dart';
import 'package:hexora/presentation/utils/roles/group_role/group_role.dart';
import 'package:hexora/presentation/viewmodels/group_vm/view_model/group_view_model.dart';
import 'package:hexora/theme/colors/theme_colors.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
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
  late Future<List<GroupRole>> _rolesFuture;

  Future<void> _seedVmFromGroupOnce(BuildContext context) async {
    if (_seeded) return;

    final group = context.read<GroupDomain>().currentGroup;
    if (group == null) return;

    final repo = context.read<IUserRepository>();
    final port = context.read<IGroupEditorPort>();

    // 1) Wait for backend roles (or fall back to defaults)
    final availableRoles = await _rolesFuture
        .catchError((_) => <GroupRole>[])
        .then((v) => v.isNotEmpty ? v : GroupRole.defaults);

    // 2) Build members map
    final Map<String, User> membersById = {};
    for (final id in group.userIds) {
      try {
        final u = await repo.getUserById(id);
        membersById[u.id] = u;
      } catch (_) {}
    }

    // 3) Build roles map using the same availableRoles
    final Map<String, GroupRole> roles = {};
    group.userRoles.forEach((userId, wire) {
      roles[userId] = GroupRole.fromWire(
        wire,
        available: availableRoles,
      );
    });

    await port.seedMembers(membersById: membersById, roles: roles);
    if (mounted) setState(() => _seeded = true);
  }

  @override
  void initState() {
    super.initState();
    _rolesFuture =
        context.read<GroupDomain>().fetchGroupRoles().then((roles) => roles);
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
        ProxyProvider<GroupEditorViewModel, IGroupEditorPort>(
          update: (_, vm, __) => VmGroupEditorPort(vm),
        ),
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
            final gd = context.watch<GroupDomain>();

            final Color primary = cs.primary;
            final Color selectedText = ThemeColors.contrastOn(primary);
            final Color unselectedText =
                ThemeColors.textPrimary(context).withOpacity(0.7);
            final Color trackBg = ThemeColors.cardBg(context);

            return Scaffold(
              appBar: AppBar(
                title: Text(
                  l.membersTitle,
                  style: t.titleLarge.copyWith(fontWeight: FontWeight.w800),
                ),
                // 🔻 Removed the AppBar "Done" text button
                backgroundColor: cs.surface,
                iconTheme:
                    IconThemeData(color: ThemeColors.textPrimary(context)),
                elevation: 0,
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(64),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: trackBg,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: cs.onSurface.withOpacity(0.06)),
                      ),
                      child: TabBar(
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
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
                  FutureBuilder<List<GroupRole>>(
                    future: _rolesFuture,
                    builder: (context, snapshot) {
                      final roles = snapshot.data ??
                          const [
                            GroupRole.member,
                            GroupRole.coAdmin,
                            GroupRole.admin,
                            GroupRole.owner,
                          ];
                      final currentUserId = context.read<UserDomain>().user?.id;
                      final actorIsOwner = (() {
                        final g = gd.currentGroup;
                        if (g == null || currentUserId == null) return false;
                        final wire = g.userRoles[currentUserId] ?? '';
                        return wire.toLowerCase().replaceAll('-', '') ==
                            'owner';
                      })();
                      return ValueListenableBuilder<Map<String, String>>(
                        valueListenable: gd.userRoles,
                        builder: (_, rolesMap, __) {
                          final mappedRoles = rolesMap.isNotEmpty
                              ? rolesMap.map(
                                  (k, v) => MapEntry(k, GroupRole.fromWire(v)))
                              : port.roles;
                          return UpdateRolesTab(
                            rolesByUserId: mappedRoles,
                            membersById: port.membersById,
                            assignableRoles: roles,
                            canEditRole: (userId) => port.canEditRole(userId),
                            setRole: (userId, r) => port.setRole(userId, r),
                            actorIsOwner: actorIsOwner,
                          );
                        },
                      );
                    },
                  ),
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

              // 🔹 Floating commit button (visible on both tabs)
              bottomNavigationBar: _CommitChangesButton(
                label: l.done,
                onPressed: () {
                  // Apply staged selections to the VM
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
              ),
            );
          },
        ),
      ),
    );
  }
}

// --- Floating commit button using your ButtonStyles ---
class _CommitChangesButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _CommitChangesButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            foregroundColor: cs.onPrimary,
            backgroundColor: cs.primary),
        icon: const Icon(Icons.check_rounded),
        label: Text(label),
        onPressed: onPressed,
      ),
    );
  }
}
