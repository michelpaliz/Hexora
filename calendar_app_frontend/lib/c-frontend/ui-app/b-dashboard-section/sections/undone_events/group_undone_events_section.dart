import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/group_mng_flow/event/repository/i_event_repository.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/undone_events/group_undone_event_detail_sheet.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/undone_events/group_undone_events/group_undone_events_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/undone_events/group_undone_events_widgets.dart';
import 'package:hexora/c-frontend/utils/roles/group_role/group_role.dart';
import 'package:hexora/c-frontend/viewmodels/group_vm/view_model/group_view_model.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class GroupUndoneEventsSection extends StatelessWidget {
  const GroupUndoneEventsSection({
    super.key,
    required this.group,
    required this.user,
    required this.role,
    this.limit = 3,
    this.onSeeAll,
  });

  final Group group;
  final User user;
  final GroupRole role;
  final int limit;
  final VoidCallback? onSeeAll;

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
      child: _GroupUndoneEventsSectionBody(
        group: group,
        user: user,
        role: role,
        limit: limit,
        onSeeAll: onSeeAll,
      ),
    );
  }
}

class _GroupUndoneEventsSectionBody extends StatelessWidget {
  const _GroupUndoneEventsSectionBody({
    required this.group,
    required this.user,
    required this.role,
    required this.limit,
    this.onSeeAll,
  });

  final Group group;
  final User user;
  final GroupRole role;
  final int limit;
  final VoidCallback? onSeeAll;

  void _openFullList(BuildContext context) {
    if (onSeeAll != null) {
      onSeeAll!();
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => GroupUndoneEventsScreen(
            group: group,
            user: user,
            role: role,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    final vm = context.watch<GroupUndoneEventsViewModel>();
    final cs = theme.colorScheme;

    // ✅ same background as ProfileRoleCard & GroupUpcomingEventsCard
    final cardColor = cs.surface;

    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: cs.outlineVariant.withOpacity(0.35)),
    );
    final shadow = Colors.black.withOpacity(
      theme.brightness == Brightness.dark ? 0.3 : 0.12,
    );

    Widget styledCard(Widget child) => Card(
          color: cardColor,
          surfaceTintColor: Colors.transparent,
          elevation: 6,
          shadowColor: shadow,
          shape: cardShape,
          child: child,
        );

    final hasItems = vm.pendingEvents.isNotEmpty;
    final visibleItems = vm.pendingEvents.take(limit).toList();

    return styledCard(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.pending_actions_outlined),
            title: Text(
              loc.pendingEventsSectionTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                color: cs.primary, // 🔵 blue title (already good)
                fontWeight: FontWeight.w800,
              ),
            ),
            subtitle: Text(
              loc.pendingEventsSectionSubtitle,
              style: theme.textTheme.bodySmall?.copyWith(color: color),
            ),
            onTap: () => _openFullList(context),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: loc.refreshButton,
                  onPressed: vm.isLoading ? null : vm.refresh,
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
          const Divider(height: 1),
          if (vm.isLoading && !hasItems)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (vm.errorMessage != null && !hasItems)
            UndoneEventsPlaceholder(
              icon: Icons.warning_amber_outlined,
              message: vm.errorMessage ?? loc.pendingEventsError,
              actionLabel: loc.tryAgain,
              onAction: vm.refresh,
            )
          else if (!hasItems)
            UndoneEventsPlaceholder(
              icon: Icons.check_circle_outline,
              message: loc.pendingEventsEmpty,
            )
          else ...[
            if (vm.isLoading) const LinearProgressIndicator(minHeight: 2),
            ...visibleItems
                .map(
                  (event) => PendingEventTile(
                    event: event,
                    viewModel: vm,
                    owner: vm.ownerInfoOf(event.ownerId),
                    onTap: () => showEventDetailSheet(
                      context: context,
                      event: event,
                      viewModel: vm,
                      allowMarkComplete: vm.canManageEvent(event),
                    ),
                  ),
                )
                .toList(),
          ],
        ],
      ),
    );
  }
}
