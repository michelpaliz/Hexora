import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/group_mng_flow/event/repository/i_event_repository.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/members/presentation/widgets/shared/header_info.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/undone_events/group_undone_event_detail_sheet.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/undone_events/group_undone_events_widgets.dart';
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
    final theme = Theme.of(context);
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: cs.surface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.pendingEventsSectionTitle,
                style: t.titleLarge.copyWith(fontWeight: FontWeight.w800)),
            // Text(
            //   group.name,
            //   style: t.titleLarge.copyWith(fontWeight: FontWeight.w800),
            // ),
          ],
        ),
        iconTheme: IconThemeData(color: ThemeColors.textPrimary(context)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Consumer<GroupUndoneEventsViewModel>(
            builder: (context, vm, _) {
              final pendingLabel =
                  '${loc.statusPending} · ${vm.pendingEvents.length}';
              final completedLabel =
                  '${loc.completedEventsSectionTitle} · ${vm.completedEvents.length}';
              final trackBg = ThemeColors.cardBg(context);
              final selectedText = ThemeColors.contrastOn(cs.primary);
              final unselectedText =
                  ThemeColors.textPrimary(context).withOpacity(0.7);

              return Padding(
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
                      Tab(text: pendingLabel),
                      Tab(text: completedLabel),
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
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    splashBorderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
          ),
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
                        child: _EventsListView(
                          events: vm.pendingEvents,
                          emptyIcon: Icons.checklist_rtl_rounded,
                          emptyMessage: loc.pendingEventsEmpty,
                          errorMessage:
                              vm.errorMessage ?? loc.pendingEventsError,
                          showError: vm.errorMessage != null &&
                              vm.pendingEvents.isEmpty,
                          allowAction: true,
                          viewModel: vm,
                        ),
                      ),
                      RefreshIndicator(
                        onRefresh: vm.refresh,
                        child: _EventsListView(
                          events: vm.completedEvents,
                          emptyIcon: Icons.task_alt_outlined,
                          emptyMessage: loc.completedEventsEmpty,
                          allowAction: false,
                          viewModel: vm,
                          doneList: true,
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

class _EventsListView extends StatelessWidget {
  const _EventsListView({
    required this.events,
    required this.emptyIcon,
    required this.emptyMessage,
    required this.allowAction,
    required this.viewModel,
    this.doneList = false,
    this.showError = false,
    this.errorMessage,
  });

  final List<Event> events;
  final IconData emptyIcon;
  final String emptyMessage;
  final bool allowAction;
  final bool doneList;
  final bool showError;
  final String? errorMessage;
  final GroupUndoneEventsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    if (events.isEmpty) {
      final placeholderMessage =
          showError ? (errorMessage ?? emptyMessage) : emptyMessage;
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        children: [
          UndoneEventsPlaceholder(
            icon: showError ? Icons.warning_amber_outlined : emptyIcon,
            message: placeholderMessage,
            actionLabel: showError ? loc.tryAgain : null,
            onAction: showError ? viewModel.refresh : null,
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 24),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Card(
          elevation: doneList ? 0 : 1,
          color: doneList
              ? theme.colorScheme.surfaceContainerHigh
              : theme.colorScheme.surface,
          child: PendingEventTile(
            event: event,
            enableAction: allowAction,
            isDone: doneList,
            owner: viewModel.ownerInfoOf(event.ownerId),
            viewModel: viewModel,
            onTap: () => showEventDetailSheet(
              context: context,
              event: event,
              viewModel: viewModel,
              allowMarkComplete: allowAction,
            ),
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 8),
    );
  }
}
