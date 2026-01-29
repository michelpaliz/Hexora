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
    final participants = _shortParticipants(thread.participants);
    final sender =
        participants.isEmpty ? l.mailDetailUnknownSender : participants;
    final snippet = thread.snippet?.trim();
    final preview = (snippet == null || snippet.isEmpty) ? '-' : snippet;
    final dateLabel = _formatRelativeDate(thread.latestDate);

    return Stack(
      children: [
        Material(
          color: selected
              ? cs.primaryContainer.withValues(alpha: 0.4)
              : cs.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            hoverColor: cs.primaryContainer.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (thread.unreadCount > 0)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        color: cs.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  if (thread.unreadCount > 0) const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sender,
                          style: t.bodySmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subject,
                          style: t.bodyMedium.copyWith(
                            fontWeight: FontWeight.w800,
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
                        dateLabel,
                        style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(height: 6),
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
                          if (thread.unreadCount > 0)
                            _CountBadge(
                              label: '${thread.unreadCount}',
                              color: cs.primary,
                              textColor: cs.onPrimary,
                            ),
                          if (thread.unreadCount > 0) const SizedBox(width: 6),
                          _CountBadge(
                            label: '${thread.messageCount}',
                            color: cs.surfaceContainerHighest,
                            textColor: cs.onSurfaceVariant,
                            border: BorderSide(color: cs.outlineVariant),
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
        if (selected)
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
    required this.color,
    required this.textColor,
    this.border,
  });

  final String label;
  final Color color;
  final Color textColor;
  final BorderSide? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: border == null ? null : Border.fromBorderSide(border!),
      ),
      child: Text(
        label,
        style: AppTypography.of(context)
            .bodySmall
            .copyWith(color: textColor, fontWeight: FontWeight.w700),
      ),
    );
  }
}
