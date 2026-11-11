import 'package:flutter/material.dart';

/// Single compact header for the mobile chat inbox.
///
/// Combines the business title and the chat toolbar into one ~60px bar: an
/// optional back button, the chat name with a small connection dot, and the
/// trailing primary/overflow actions. Replaces the previous arrangement of an
/// outer app bar plus a separate toolbar row with a large Wi-Fi icon.
class MobileChatInboxHeader extends StatelessWidget {
  const MobileChatInboxHeader({
    super.key,
    required this.title,
    required this.connected,
    required this.statusLabel,
    required this.trailing,
    this.unreadTotal = 0,
    this.onBack,
  });

  final String title;
  final bool connected;
  final String statusLabel;
  final int unreadTotal;
  final VoidCallback? onBack;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return SizedBox(
      height: 60,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(children: [
          if (onBack != null)
            IconButton(
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, size: 22),
            )
          else
            const SizedBox(width: 4),
          Badge(
            isLabelVisible: unreadTotal > 0,
            label: Text(unreadTotal > 99 ? '99+' : '$unreadTotal'),
            child: Icon(Icons.forum_outlined, color: cs.primary, size: 24),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.titleSmall?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                Row(children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: connected ? Colors.green : cs.outline,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      statusLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodySmall
                          ?.copyWith(fontSize: 11, color: cs.onSurfaceVariant),
                    ),
                  ),
                ]),
              ],
            ),
          ),
          ...trailing,
        ]),
      ),
    );
  }
}
