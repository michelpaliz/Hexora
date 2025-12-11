import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/group_mng_flow/event/repository/i_event_repository.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/members/presentation/widgets/shared/header_info.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/undone_events/group_undone_event_detail_sheet.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/undone_events/group_undone_events/widgets/group_undone_events_list_view.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/undone_events/group_undone_events/widgets/undone_events_segmented_tab_bar.dart';
import 'package:hexora/c-frontend/utils/roles/group_role/group_role.dart';
import 'package:hexora/c-frontend/viewmodels/group_vm/view_model/group_view_model.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class GroupUndoneEventsScreen extends StatelessWidget {
  const GroupUndoneEventsScreen({
    super.key,
    required this.group,
    required this.user,
    required this.role,
  });

  final Group group;
  final User user;
  final GroupRole role;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<GroupUndoneEventsViewModel>(
      create: (ctx) {
        final userDomain = ctx.read<UserDomain>();
        return GroupUndoneEventsViewModel(
          groupId: group.id,
          currentUserId: user.id,
          role: role,
          eventRepository: ctx.read<IEventRepository>(),
          userResolver: (ownerId) async {
            try {
              return await userDomain.getUserById(ownerId);
            } catch (_) {
              return null;
            }
          },
        )..refresh();
      },
      child: DefaultTabController(
        length: 2,
        child: _GroupUndoneEventsScreenBody(group: group),
      ),
    );
  }
}

class _GroupUndoneEventsScreenBody extends StatelessWidget {
  const _GroupUndoneEventsScreenBody({required this.group});

  final Group group;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: cs.surface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.pendingEventsSectionTitle,
              style: t.titleLarge.copyWith(fontWeight: FontWeight.w800),
            ),
            // If you want to re-enable group name later:
            // Text(
            //   group.name,
            //   style: t.titleLarge.copyWith(fontWeight: FontWeight.w800),
            // ),
          ],
        ),
        iconTheme: IconThemeData(color: ThemeColors.textPrimary(context)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(56),
          child: UndoneEventsSegmentedTabBar(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: loc.refreshButton,
            onPressed: () =>
                context.read<GroupUndoneEventsViewModel>().refresh(),
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<GroupUndoneEventsViewModel>(
          builder: (context, vm, _) {
            return Column(
              children: [
                if (vm.isLoading) const LinearProgressIndicator(minHeight: 2),
                InfoHeader(
                  title: loc.pendingEventsSectionTitle,
                  subtitle:
                      '${loc.pendingEventsSectionSubtitle}\n${loc.completedEventsSectionSubtitle}',
                  stats: [
                    StatChip(
                      label: loc.statusPending,
                      count: vm.pendingEvents.length,
                      icon: Icons.pending_actions_outlined,
                    ),
                    StatChip(
                      label: loc.completedEventsSectionTitle,
                      count: vm.completedEvents.length,
                      icon: Icons.task_alt_rounded,
                    ),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      RefreshIndicator(
                        onRefresh: vm.refresh,
                        child: GroupUndoneEventsListView(
                          events: vm.pendingEvents,
                          emptyIcon: Icons.checklist_rtl_rounded,
                          emptyMessage: loc.pendingEventsEmpty,
                          errorMessage:
                              vm.errorMessage ?? loc.pendingEventsError,
                          showError: vm.errorMessage != null &&
                              vm.pendingEvents.isEmpty,
                          allowAction: true,
                          doneList: false,
                          viewModel: vm,
                          onTapEvent: (event) => showEventDetailSheet(
                            context: context,
                            event: event,
                            viewModel: vm,
                            allowMarkComplete: true,
                          ),
                        ),
                      ),
                      RefreshIndicator(
                        onRefresh: vm.refresh,
                        child: GroupUndoneEventsListView(
                          events: vm.completedEvents,
                          emptyIcon: Icons.task_alt_outlined,
                          emptyMessage: loc.completedEventsEmpty,
                          allowAction: false,
                          doneList: true,
                          viewModel: vm,
                          onTapEvent: (event) => showEventDetailSheet(
                            context: context,
                            event: event,
                            viewModel: vm,
                            allowMarkComplete: false,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
