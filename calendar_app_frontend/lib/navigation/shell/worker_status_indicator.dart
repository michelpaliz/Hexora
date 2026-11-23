import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:hexora/navigation/shell/hexora_nav_components.dart';
import 'package:hexora/services/user/presence_domain.dart';
import 'package:hexora/theme/themes/navigation_tokens.dart';
import 'package:provider/provider.dart';

/// Compact live connected-user indicator for the global navigation bar.
/// Presence is shown inline; the previous worker-status popover is kept out
/// of the main bar so it does not compete with navigation.
class WorkerStatusIndicator extends StatefulWidget {
  const WorkerStatusIndicator({
    super.key,
    required this.memberIds,
    required this.groupRoles,
  });

  final List<String> memberIds;
  final Map<String, String> groupRoles;

  @override
  State<WorkerStatusIndicator> createState() => _WorkerStatusIndicatorState();
}

class _WorkerStatusIndicatorState extends State<WorkerStatusIndicator> {
  bool get _isSpanish => Localizations.localeOf(context).languageCode == 'es';

  @override
  Widget build(BuildContext context) {
    final presence = context.watch<PresenceDomain>();
    final onlineMembers = presence
        .getPresenceForGroup(widget.memberIds, widget.groupRoles)
        .where((user) => user.isOnline)
        .toList(growable: false);
    // Only report a count once presence has been received; otherwise it is
    // "unavailable" and must not be shown as a confirmed zero.
    final int? onlineCount =
        presence.hasReceivedPresence ? onlineMembers.length : null;

    return HexoraNavTile(
      tooltip: _isSpanish ? 'Usuarios conectados' : 'Connected users',
      semanticLabel: onlineCount == null
          ? (_isSpanish ? 'Usuarios conectados' : 'Connected users')
          : (_isSpanish
              ? '$onlineCount usuarios conectados'
              : '$onlineCount connected users'),
      padding: const EdgeInsets.symmetric(
        horizontal: NavigationTokens.globalItemPadding,
      ),
      onTap: null,
      builder: (context, fg) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.users, size: NavigationTokens.iconSize, color: fg),
          const SizedBox(width: 6),
          Text(
            onlineCount?.toString() ?? '—',
            style: NavigationTokens.label(context)
                .copyWith(color: fg, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
