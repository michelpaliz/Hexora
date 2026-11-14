import 'package:flutter/material.dart';
import 'package:hexora/presentation/shared/widgets/mobile_navigation_components.dart';
import 'package:hexora/presentation/shared/widgets/section_app_bar.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/services/auth/auth_provider.dart';
import 'package:hexora/services/groups/domain/group_domain.dart';
import 'package:hexora/services/groups/invite/repository/invite_repository.dart';
import 'package:hexora/presentation/screens/workspace/sections/members/presentation/domain/models/members_vm.dart';
import 'package:hexora/presentation/screens/workspace/sections/members/presentation/widgets/add_users_flow/screen/add_user_fab.dart';
import 'package:hexora/presentation/screens/workspace/sections/members/presentation/widgets/member_list/members_section.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class GroupMembersScreen extends StatelessWidget {
  const GroupMembersScreen(
      {super.key, required this.group, this.initialTab = 0});
  final Group group;
  final int initialTab;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return ChangeNotifierProvider(
      create: (ctx) => MembersVM(
        group: group,
        groupDomain: ctx.read<GroupDomain>(),
        inviteRepo: ctx.read<InvitationRepository>(),
        auth: ctx.read<AuthProvider>(),
      )..refreshAll(),
      child: DefaultTabController(
        length: 3,
        initialIndex: initialTab,
        child: Builder(builder: (context) {
          final vm = context.watch<MembersVM>();

          final labelAccepted = '${l.membersTitle} · ${vm.totalAccepted}';
          final labelPending = '${l.statusPending} · ${vm.totalPending}';
          final labelNotAccept =
              '${l.statusNotAccepted} · ${vm.totalNotAccepted}';

          return Scaffold(
            appBar: SectionAppBar(
              title: l.membersTitle,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: HexoraMobileTabs(
                  tabs: [
                    Tab(text: labelAccepted),
                    Tab(text: labelPending),
                    Tab(text: labelNotAccept),
                  ],
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
