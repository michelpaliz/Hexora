import 'package:flutter/material.dart';

/// Single compact header for the active conversation.
///
/// Shows one channel identity — icon/avatar, name and a discreet status or
/// member line — with no redundant title, then a row of consistently sized
/// trailing actions. Height is kept to ~58px with vertically aligned icons.
class ChatChannelHeader extends StatelessWidget {
  const ChatChannelHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.trailing,
    this.subtitle,
    this.subtitleActionLabel,
    this.onSubtitleActionTap,
    this.connected,
    this.onBack,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? subtitleActionLabel;
  final VoidCallback? onSubtitleActionTap;

  /// When non-null, renders a small presence dot (green connected / grey not).
  final bool? connected;
  final VoidCallback? onBack;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SizedBox(
      height: 58,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(children: [
          if (onBack != null)
            IconButton(
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, size: 20),
            ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: .55),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 20, color: cs.primary),
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
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                if ((subtitle != null && subtitle!.isNotEmpty) ||
                    subtitleActionLabel != null)
                  Row(children: [
                    if (connected != null) ...[
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: connected! ? Colors.green : cs.outline,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                    ],
                    if (subtitle != null && subtitle!.isNotEmpty)
                      Flexible(
                        child: Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.bodySmall?.copyWith(
                            fontSize: 11.5,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    if (subtitle != null &&
                        subtitle!.isNotEmpty &&
                        subtitleActionLabel != null)
                      const SizedBox(width: 6),
                    if (subtitleActionLabel != null)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onSubtitleActionTap,
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest
                                  .withValues(alpha: .55),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child:
                                Row(mainAxisSize: MainAxisSize.min, children: [
                              Text(
                                subtitleActionLabel!,
                                style: tt.labelSmall?.copyWith(
                                  fontSize: 11,
                                  color: cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(Icons.keyboard_arrow_down_rounded,
                                  size: 14, color: cs.onSurfaceVariant),
                            ]),
                          ),
                        ),
                      ),
                  ]),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ...trailing,
        ]),
      ),
    );
  }
}
