import 'package:flutter/material.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/models/user/user.dart';
import 'package:hexora/services/groups/event/repository/i_event_repository.dart';
import 'package:hexora/services/user/domain/user_domain.dart';
import 'package:hexora/presentation/screens/workspace/sections/undone_events/group_undone_events/group_undone_events_screen.dart';
import 'package:hexora/presentation/utils/roles/group_role.dart';
import 'package:hexora/presentation/viewmodels/groups/group_view_model.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class GroupUndoneEventsSection extends StatelessWidget {
  const GroupUndoneEventsSection({
    super.key,
    required this.group,
    required this.user,
    required this.role,
    this.onSeeAll,
  });

  final Group group;
  final User user;
  final GroupRole role;
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
    this.onSeeAll,
  });

  final Group group;
  final User user;
  final GroupRole role;
  final VoidCallback? onSeeAll;

  Future<void> _openFullList(BuildContext context) async {
    if (onSeeAll != null && MediaQuery.sizeOf(context).width >= 900) {
      onSeeAll!();
      return;
    }
    final vm = context.read<GroupUndoneEventsViewModel>();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            GroupUndoneEventsScreen(group: group, user: user, role: role),
      ),
    );
    if (context.mounted) await vm.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final vm = context.watch<GroupUndoneEventsViewModel>();
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: cs.surfaceContainerLow,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(Icons.pending_actions_outlined, color: cs.primary),
        title: Text(loc.pendingEventsSectionTitle),
        subtitle: vm.errorMessage == null ? null : Text(loc.pendingEventsError),
        onTap: () => _openFullList(context),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (vm.isLoading)
              const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
            else if (vm.errorMessage != null)
              IconButton(
                  onPressed: vm.refresh,
                  tooltip: loc.tryAgain,
                  icon: const Icon(Icons.refresh_rounded))
            else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(12)),
                child: Text('${vm.pendingEvents.length}',
                    style: TextStyle(
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.w700)),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
