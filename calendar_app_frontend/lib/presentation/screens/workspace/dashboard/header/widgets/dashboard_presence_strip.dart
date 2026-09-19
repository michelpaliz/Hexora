import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/services/user/presence_domain.dart';
import 'package:hexora/presentation/shared/widgets/avatars/user_status_row.dart';

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
    if (MediaQuery.sizeOf(context).width < 700) {
      return ExpansionTile(
        key: ValueKey(group.id),
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        dense: true,
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(
            es ? '${online.length} en línea' : '${online.length} online',
            style: Theme.of(context).textTheme.bodySmall),
        children: [details],
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(es ? 'En línea (${online.length})' : 'Online (${online.length})',
            style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        details,
      ]),
    );
  }
}
