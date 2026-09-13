import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/b-backend/user/presence_domain.dart';
import 'package:hexora/c-frontend/utils/image/user_image/widgets/user_status_row.dart';

/// Shares the calendar's live presence avatars and pulsing online indicator.
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
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(es ? 'En línea (${online.length})' : 'Online (${online.length})',
              style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          if (online.isNotEmpty)
            UserStatusRow(userList: online, showAllOption: false)
          else
            Text(
              presence.hasReceivedPresence
                  ? (es ? 'No hay miembros en línea' : 'No members online')
                  : (es
                      ? 'Esperando estado de conexión…'
                      : 'Waiting for online status…'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}
