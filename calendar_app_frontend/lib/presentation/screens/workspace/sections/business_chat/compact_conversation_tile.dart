import 'package:flutter/material.dart';

import 'widgets/channel_avatar.dart';

/// Compact messaging-style conversation row used in the chat inbox list.
///
/// Displays a channel icon, the channel name, a single-line message preview,
/// the latest-message timestamp and an unread badge when applicable.
class CompactConversationTile extends StatefulWidget {
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
    this.actions,
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
  final Widget? actions;
  final VoidCallback? onTap;

  @override
  State<CompactConversationTile> createState() =>
      _CompactConversationTileState();
}

class _CompactConversationTileState extends State<CompactConversationTile> {
  bool _hovering = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final hasUnread = widget.unreadCount > 0;
    const navyForeground = Color(0xFFF1F5FC);
    const navyMuted = Color(0xFFB8C7DB);
    final foreground = widget.navySurface ? navyForeground : cs.onSurface;
    final mutedForeground =
        widget.navySurface ? navyMuted : cs.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.title,
      child: Material(
        color: widget.selected
            ? (widget.navySurface
                ? cs.primary.withValues(alpha: .28)
                : cs.surface)
            : (_hovering || _focused)
                ? (widget.navySurface
                    ? Colors.white.withValues(alpha: .07)
                    : cs.surfaceContainerHighest.withValues(alpha: .35))
                : Colors.transparent,
        child: FocusableActionDetector(
          onShowFocusHighlight: (focused) => setState(() => _focused = focused),
          child: MouseRegion(
            onEnter: (_) => setState(() => _hovering = true),
            onExit: (_) => setState(() => _hovering = false),
            child: InkWell(
              onTap: widget.onTap,
              child: SizedBox(
                height: 64,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  child: Row(
                    children: [
                      ChannelAvatar(
                        icon: widget.icon,
                        muted: widget.muted,
                        circular: widget.circularAvatar,
                        navySurface: widget.navySurface,
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
                                    widget.title,
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
                                if (widget.timestamp != null) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.timestamp!,
                                    maxLines: 1,
                                    style: tt.bodySmall?.copyWith(
                                      fontSize: 11,
                                      color: hasUnread
                                          ? cs.primary
                                          : mutedForeground,
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
                                    widget.preview,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: tt.bodySmall?.copyWith(
                                      color: mutedForeground,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (hasUnread)
                                  _UnreadBadge(count: widget.unreadCount)
                                else if (widget.muted)
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
                      if (widget.actions != null)
                        AnimatedOpacity(
                          opacity: _hovering || _focused ? 1 : 0,
                          duration: const Duration(milliseconds: 120),
                          child: IgnorePointer(
                            ignoring: !(_hovering || _focused),
                            child: widget.actions,
                          ),
                        ),
                    ],
                  ),
                ),
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
