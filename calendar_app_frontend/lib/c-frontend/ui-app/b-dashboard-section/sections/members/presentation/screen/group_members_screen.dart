import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_services/auth_provider.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/group_mng_flow/invite/repository/invite_repository.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/members/presentation/domain/models/members_vm.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/members/presentation/widgets/add_users_flow/screen/add_user_fab.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/members/presentation/widgets/member_list/members_section.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/members/presentation/widgets/shared/header_info.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class GroupMembersScreen extends StatelessWidget {
  const GroupMembersScreen({super.key, required this.group});
  final Group group;

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
        child: Builder(builder: (context) {
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

          return Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: Navigator.of(context).canPop(),
              title: Text(
                l.membersTitle,
                style: t.titleLarge.copyWith(fontWeight: FontWeight.w800),
              ),
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
              ),
            ),

            body: RefreshIndicator(
              color: cs.primary,
              backgroundColor: cs.surface,
              onRefresh: vm.refreshAll,
              child: Column(
                children: [
                  if (vm.isLoading) const LinearProgressIndicator(minHeight: 2),

                  // 🔹 Shared information header (sits above TabBarView)
                  InfoHeader(
                    title: l.membersTitle,
                    subtitle: l.membersHelperText,
                    stats: [
                      StatChip(
                          label: l.membersTitle,
                          count: vm.totalAccepted,
                          icon: Icons.groups_rounded),
                      StatChip(
                          label: l.statusPending,
                          count: vm.totalPending,
                          icon: Icons.hourglass_bottom_rounded),
                      StatChip(
                          label: l.statusNotAccepted,
                          count: vm.totalNotAccepted,
                          icon: Icons.block_rounded),
                    ],
                    // trailingAction: (optional) e.g., a filter/menu button
                    // bottom: (optional) e.g., a search or filters row
                  ),

                  Expanded(
                    child: TabBarView(
                      children: [
                        Members(
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
                        Members(
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
                        Members(
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

            // Existing FAB to add users
            floatingActionButton: AddUsersFab(group: group),
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          );
        }),
      ),
    );
  }
}
