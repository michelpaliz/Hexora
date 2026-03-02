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

    final isUnread = thread.unreadCount > 0;
    final isSelected = selected;
    final background = isSelected
        ? cs.primaryContainer.withValues(alpha: 0.10)
        : isUnread
            ? cs.primaryContainer.withValues(alpha: 0.04)
            : Colors.transparent;

    return Stack(
      children: [
        Material(
          color: background,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            hoverColor: cs.onSurface.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: sender + date + badges
                  Row(
                    children: [
                      if (isUnread)
                        Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: cs.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          sender,
                          style: t.bodySmall.copyWith(
                            fontWeight:
                                isUnread ? FontWeight.w700 : FontWeight.w500,
                            color: cs.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dateLabel,
                        style: t.bodySmall.copyWith(
                          color: cs.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Row 2: subject + message count + attachment
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          subject,
                          style: t.bodySmall.copyWith(
                            fontWeight:
                                isUnread ? FontWeight.w800 : FontWeight.w600,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (thread.hasAttachments)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            Icons.attach_file,
                            size: 14,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      if (thread.messageCount > 1)
                        Text(
                          '${thread.messageCount}',
                          style: t.bodySmall.copyWith(
                            color: cs.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 1),
                  // Row 3: snippet
                  Text(
                    preview,
                    style: t.bodySmall.copyWith(
                      color: cs.onSurfaceVariant,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isSelected)
          Positioned(
            left: 0,
            top: 6,
            bottom: 6,
            child: Container(
              width: 3,
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

