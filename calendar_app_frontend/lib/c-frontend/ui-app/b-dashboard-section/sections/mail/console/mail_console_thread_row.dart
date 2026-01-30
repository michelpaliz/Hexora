part of '../mail_console_screen.dart';

class _ThreadRow extends StatelessWidget {
  const _ThreadRow({
    required this.thread,
    required this.selected,
    required this.onTap,
  });

  final MailThread thread;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final subject = thread.subject.trim().isEmpty
        ? l.mailDetailNoSubject
        : thread.subject.trim();
    final sender = _friendlySender(thread.participants, l);
    final snippet = thread.snippet?.trim();
    final preview = (snippet == null || snippet.isEmpty) ? '-' : snippet;
    final dateLabel = _formatRelativeDate(thread.latestDate);
    final unread = thread.unreadCount > 0;

    final isUnread = thread.unreadCount > 0;
    final isSelected = selected;
    final background = isSelected
        ? cs.primaryContainer.withValues(alpha: 0.08)
        : isUnread
            ? cs.primaryContainer.withValues(alpha: 0.04)
            : cs.surface;
    final hover = cs.onSurface.withValues(alpha: 0.04);

    return Stack(
      children: [
        Material(
          color: background,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            hoverColor: hover,
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sender,
                          style: t.bodySmall.copyWith(
                            fontWeight:
                                isUnread ? FontWeight.w700 : FontWeight.w600,
                            color: cs.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subject,
                          style: t.bodyMedium.copyWith(
                            fontWeight:
                                isUnread ? FontWeight.w800 : FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          preview,
                          style: t.bodySmall.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Última actividad · $dateLabel',
                        style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${thread.messageCount} ${l.mailThreadMessageCountLabel.toLowerCase()}',
                        style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (thread.hasAttachments)
                            Icon(
                              Icons.attach_file,
                              size: 16,
                              color: cs.onSurfaceVariant,
                            ),
                          if (thread.hasAttachments) const SizedBox(width: 6),
                          if (thread.messageCount > 1)
                            _CountBadge(
                              label: '${thread.messageCount}',
                              filled: isUnread,
                              color: cs.primary,
                              textColor: cs.onPrimary,
                              borderColor: cs.outlineVariant,
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isSelected)
          Positioned(
            left: 0,
            top: 8,
            bottom: 8,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
      ],
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({
    required this.label,
    required this.filled,
    required this.color,
    required this.textColor,
    required this.borderColor,
  });

  final String label;
  final bool filled;
  final Color color;
  final Color textColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: filled ? color : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: filled ? color : borderColor),
      ),
      child: Text(
        label,
        style: AppTypography.of(context)
            .bodySmall
            .copyWith(
              color: filled ? textColor : borderColor,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
