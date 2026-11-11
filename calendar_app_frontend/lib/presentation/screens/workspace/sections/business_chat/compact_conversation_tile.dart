import 'package:flutter/material.dart';

import 'widgets/channel_avatar.dart';

/// Compact messaging-style conversation row used in the chat inbox list.
///
/// Displays a channel icon, the channel name, a single-line message preview,
/// the latest-message timestamp and an unread badge when applicable.
class CompactConversationTile extends StatelessWidget {
  const CompactConversationTile({
    super.key,
    required this.icon,
    required this.title,
    required this.preview,
    this.timestamp,
    this.unreadCount = 0,
    this.selected = false,
    this.muted = false,
    this.circularAvatar = false,
    this.navySurface = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String preview;
  final String? timestamp;
  final int unreadCount;
  final bool selected;
  final bool muted;

  /// Use a circular avatar (mobile inbox) instead of the rounded square.
  final bool circularAvatar;

  /// The desktop inbox lives on Hexora's persistent navy navigation surface.
  /// Keep this opt-in so the compact mobile inbox retains its normal surface.
  final bool navySurface;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final hasUnread = unreadCount > 0;
    const navyForeground = Color(0xFFF1F5FC);
    const navyMuted = Color(0xFFB8C7DB);
    final foreground = navySurface ? navyForeground : cs.onSurface;
    final mutedForeground = navySurface ? navyMuted : cs.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: Material(
        color: selected
            ? (navySurface
                ? cs.primary.withValues(alpha: .28)
                : cs.primary.withValues(alpha: .06))
            : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 64,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: Row(
                children: [
                  ChannelAvatar(
                    icon: icon,
                    muted: muted,
                    circular: circularAvatar,
                    navySurface: navySurface,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: tt.titleSmall?.copyWith(
                                  color: foreground,
                                  fontWeight: hasUnread
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                ),
                              ),
                            ),
                            if (timestamp != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                timestamp!,
                                maxLines: 1,
                                style: tt.bodySmall?.copyWith(
                                  fontSize: 11,
                                  color:
                                      hasUnread ? cs.primary : mutedForeground,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                preview,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: tt.bodySmall?.copyWith(
                                  color: mutedForeground,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (hasUnread)
                              _UnreadBadge(count: unreadCount)
                            else if (muted)
                              Icon(
                                Icons.notifications_off_outlined,
                                size: 16,
                                color: mutedForeground,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        maxLines: 1,
        style: TextStyle(
          color: cs.onPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}
