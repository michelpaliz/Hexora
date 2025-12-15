import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_services/auth_provider.dart';
import 'package:hexora/b-backend/errorClases/error_classes/error_classes.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/group_mng_flow/invite/repository/invite_repository.dart';
import 'package:hexora/b-backend/group_mng_flow/group/repository/i_group_repository.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/members/presentation/domain/models/members_vm.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/members/presentation/widgets/member_list/members_section.dart'
    as members_section;
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/members/presentation/widgets/shared/header_info.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/members/presentation/screen/review_user_screen.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class MembersInlinePanel extends StatelessWidget {
  final Group group;
  final Color onSurface;

  const MembersInlinePanel({
    super.key,
    required this.group,
    required this.onSurface,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);

    return ChangeNotifierProvider(
      create: (ctx) => MembersVM(
        group: group,
        groupDomain: ctx.read<GroupDomain>(),
        inviteRepo: ctx.read<InvitationRepository>(),
        auth: ctx.read<AuthProvider>(),
      )..refreshAll(),
      child: DefaultTabController(
        length: 3,
        child: Builder(
          builder: (context) {
            final vm = context.watch<MembersVM>();

            final labelAccepted = '${l.membersTitle} · ${vm.totalAccepted}';
            final labelPending = '${l.statusPending} · ${vm.totalPending}';
            final labelNotAccept =
                '${l.statusNotAccepted} · ${vm.totalNotAccepted}';

            final Color primary = cs.primary;
            final Color selectedText = ThemeColors.contrastOn(primary);
            final Color unselectedText =
                ThemeColors.textPrimary(context).withOpacity(0.7);
            final Color trackBg = ThemeColors.cardBg(context);

            return Padding(
              padding: const EdgeInsets.all(12),
              child: Stack(
                children: [
                  RefreshIndicator(
                    color: cs.primary,
                    backgroundColor: cs.surface,
                    onRefresh: vm.refreshAll,
                    child: Column(
                      children: [
                        if (vm.isLoading)
                          const LinearProgressIndicator(minHeight: 2),
                        InfoHeader(
                          title: l.membersTitle,
                          subtitle: l.membersHelperText,
                          stats: [
                            StatChip(
                              label: l.membersTitle,
                              count: vm.totalAccepted,
                              icon: Icons.groups_rounded,
                            ),
                            StatChip(
                              label: l.statusPending,
                              count: vm.totalPending,
                              icon: Icons.hourglass_bottom_rounded,
                            ),
                            StatChip(
                              label: l.statusNotAccepted,
                              count: vm.totalNotAccepted,
                              icon: Icons.block_rounded,
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: trackBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: cs.onSurface.withOpacity(0.06),
                              ),
                            ),
                            child: TabBar(
                              tabs: [
                                Tab(text: labelAccepted),
                                Tab(text: labelPending),
                                Tab(text: labelNotAccept),
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
                        Expanded(
                          child: TabBarView(
                            children: [
                              members_section.Members(
                                accepted: vm.accepted,
                                pending: const [],
                                notAccepted: const [],
                                acceptedLabel: l.membersTitle,
                                pendingLabel: l.statusPending,
                                notAcceptedLabel: l.statusNotAccepted,
                                group: group,
                                useGradientBackground: true,
                                wrapInCard: false,
                              ),
                              members_section.Members(
                                accepted: const [],
                                pending: vm.pending,
                                notAccepted: const [],
                                acceptedLabel: l.membersTitle,
                                pendingLabel: l.statusPending,
                                notAcceptedLabel: l.statusNotAccepted,
                                group: group,
                                useGradientBackground: true,
                                wrapInCard: false,
                              ),
                              members_section.Members(
                                accepted: const [],
                                pending: const [],
                                notAccepted: vm.notAccepted,
                                acceptedLabel: l.membersTitle,
                                pendingLabel: l.statusPending,
                                notAcceptedLabel: l.statusNotAccepted,
                                group: group,
                                useGradientBackground: true,
                                wrapInCard: false,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: FloatingActionButton.extended(
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Add users'),
                      backgroundColor: cs.primary,
                      foregroundColor: ThemeColors.contrastOn(cs.primary),
                      onPressed: () => _openAddUsers(context, vm),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openAddUsers(BuildContext context, MembersVM vm) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: const ReviewAndAddUsersScreen(),
          ),
        );
      },
    );

    if (result == null) return;

    final users = result['users'] as List<User>?;
    final roles = result['roles'] as Map<String, String>?;

    if (users != null || roles != null) {
      final gd = context.read<GroupDomain>();
      final repo = gd.groupRepository;
      final groupRepo = context.read<IGroupRepository>();
      final userDomain = context.read<UserDomain>();

      final mergedRoles = {...group.userRoles, ...?roles};
      final mergedIds = <String>{
        ...group.userIds,
        if (users != null) ...users.map((u) => u.id),
      }.toList();
      final newUserIds = users?.map((u) => u.id).toSet() ?? const {};

      gd.currentGroup = group.copyWith(
        userIds: mergedIds,
        userRoles: mergedRoles,
      );
      gd.userRoles.value = mergedRoles;

      if (roles != null) {
        for (final entry in roles.entries) {
          final userId = entry.key;
          final desiredWire = entry.value;
          final currentWire = group.userRoles[userId];

          final wasMember = group.userIds.contains(userId);
          if (wasMember && currentWire != desiredWire) {
            try {
              await repo.setUserRoleInGroup(
                groupId: group.id,
                userId: userId,
                roleWire: desiredWire,
              );
            } on HttpFailure catch (e) {
              if (e.statusCode != 404) rethrow;
            }
          }
        }
      }

      if (users != null && users.isNotEmpty) {
        final updatedGroup = group.copyWith(
          userIds: mergedIds,
          userRoles: mergedRoles,
        );
        await repo.updateGroup(updatedGroup);
      }

      if (roles != null && newUserIds.isNotEmpty) {
        for (final entry in roles.entries) {
          final userId = entry.key;
          if (!newUserIds.contains(userId)) continue;
          final desiredWire = entry.value;
          try {
            await groupRepo.sendGroupInvitation(
              groupId: group.id,
              userId: userId,
              roleWire: desiredWire,
            );
          } on HttpFailure catch (e) {
            if (e.statusCode != 404 && e.statusCode != 409) rethrow;
          }
        }
      }

      if (roles != null && newUserIds.isNotEmpty) {
        for (final entry in roles.entries) {
          final userId = entry.key;
          if (!newUserIds.contains(userId)) continue;
          final desiredWire = entry.value;
          try {
            await repo.setUserRoleInGroup(
              groupId: group.id,
              userId: userId,
              roleWire: desiredWire,
            );
          } on HttpFailure catch (e) {
            if (e.statusCode != 404) rethrow;
          }
        }
      }

      await gd.refreshGroupsForCurrentUser(userDomain);
      try {
        final fresh = await repo.getGroupById(group.id);
        gd.currentGroup = fresh;
        gd.userRoles.value = Map<String, String>.from(fresh.userRoles);
        gd.usersInGroup.value = gd.usersInGroup.value;
      } catch (_) {
        gd.currentGroup = group.copyWith(
          userIds: mergedIds,
          userRoles: mergedRoles,
        );
        gd.userRoles.value = mergedRoles;
      }
    }

    await vm.refreshAll();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Members updated')),
    );
  }
}
