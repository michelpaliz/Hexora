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
    required this.onPressed,
    this.selected = false,
  });

  final List<String> memberIds;
  final Map<String, String> groupRoles;
  final VoidCallback onPressed;
  final bool selected;

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

    final tooltip = onlineCount == null
        ? (_isSpanish
            ? 'Miembros · estado no disponible'
            : 'Members · status unavailable')
        : (_isSpanish
            ? 'Miembros · $onlineCount conectados'
            : 'Members · $onlineCount online');
    return HexoraNavTile(
      key: const ValueKey('workspace-members-button'),
      tooltip: tooltip,
      semanticLabel: tooltip,
      selected: widget.selected,
      padding: EdgeInsets.zero,
      onTap: widget.onPressed,
      builder: (context, fg) => Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(LucideIcons.users, size: NavigationTokens.iconSize, color: fg),
          if (onlineCount != null && onlineCount > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                key: const ValueKey('workspace-members-online-indicator'),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: HexoraGlobalNavColors.backgroundFor(context),
                    width: 1.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
