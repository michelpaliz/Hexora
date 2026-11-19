import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/services/user/presence_domain.dart';
import 'package:hexora/presentation/shared/widgets/avatars/user_status_row.dart';

/// Shares the calendar's live presence information on the dashboard.
class DashboardPresenceStrip extends StatelessWidget {
  const DashboardPresenceStrip({super.key, required this.group});

  final Group group;

  @override
  Widget build(BuildContext context) {
    final presence = context.watch<PresenceDomain>();
    final memberIds = {...group.userIds, group.ownerId}..remove('');
    final online = presence
        .getPresenceForGroup(memberIds.toList(), group.userRoles)
        .where((user) => user.isOnline)
        .toList();
    final es = Localizations.localeOf(context).languageCode == 'es';

    if (MediaQuery.sizeOf(context).width < 700) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: online.isNotEmpty
                    ? const Color(0xFF36D78A)
                    : Colors.white.withValues(alpha: .6),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                online.isNotEmpty
                    ? (es
                        ? 'Estado del equipo: ${online.length} en línea'
                        : 'Team status: ${online.length} online')
                    : (es
                        ? 'Estado del equipo: sin miembros en línea'
                        : 'Team status: no members online'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: .9),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      );
    }

    final details = online.isNotEmpty
        ? UserStatusRow(userList: online, showAllOption: false)
        : Text(
            presence.hasReceivedPresence
                ? (es ? 'No hay miembros en línea' : 'No members online')
                : (es
                    ? 'Esperando estado de conexión…'
                    : 'Waiting for online status…'),
            style: Theme.of(context).textTheme.bodySmall,
          );

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            es ? 'En línea (${online.length})' : 'Online (${online.length})',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          details,
        ],
      ),
    );
  }
}
