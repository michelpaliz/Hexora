import 'package:hexora/presentation/shared/widgets/section_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:hexora/models/group_model/group/group.dart';
import 'package:hexora/services/auth_user/auth/auth_services/auth_provider.dart';
import 'package:hexora/services/groups/domain/group_domain.dart';
import 'package:hexora/services/groups/invite/repository/invite_repository.dart';
import 'package:hexora/presentation/screens/workspace/sections/members/presentation/domain/models/members_vm.dart';
import 'package:hexora/presentation/screens/workspace/sections/members/presentation/widgets/add_users_flow/screen/add_user_fab.dart';
import 'package:hexora/presentation/screens/workspace/sections/members/presentation/widgets/member_list/members_section.dart';
import 'package:hexora/theme/colors/theme_colors.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
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
            appBar: SectionAppBar(
              title: l.membersTitle,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(64),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: trackBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.onSurface.withOpacity(0.06)),
                    ),
                    child: TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
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
