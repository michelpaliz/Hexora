part of '../mail_console_screen.dart';

/// Mobile inbox rows inherit the app's typography and semantic color roles.
class _MobileThreadRow extends StatelessWidget {
  const _MobileThreadRow({required this.thread, required this.onTap});
  final MailThread thread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final t = theme.textTheme;
    final l = AppLocalizations.of(context)!;
    final sender = _friendlySender(thread.participants, l);
    final unread = thread.unreadCount > 0;
    final subject = thread.subject.trim().isEmpty
        ? l.mailDetailNoSubject
        : thread.subject.trim();
    return Material(
      color: unread ? cs.surfaceContainerLow : cs.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleAvatar(
                radius: 21,
                backgroundColor: cs.primaryContainer,
                child: Text(
                    sender.isEmpty
                        ? '?'
                        : sender.characters.first.toUpperCase(),
                    style: t.titleMedium?.copyWith(
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.w700))),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(children: [
                    Expanded(
                        child: Text(sender,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.titleSmall?.copyWith(
                                color: cs.onSurface,
                                fontWeight: unread
                                    ? FontWeight.w700
                                    : FontWeight.w600))),
                    const SizedBox(width: 8),
                    Tooltip(
                        message: _formatFullDate(thread.latestDate),
                        child: Text(
                            _formatRelativeDate(thread.latestDate,
                                locale: l.localeName),
                            style: t.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant))),
                  ]),
                  const SizedBox(height: 4),
                  Text(subject,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodyMedium?.copyWith(
                          color: cs.onSurface,
                          fontWeight:
                              unread ? FontWeight.w600 : FontWeight.w400)),
                  if ((thread.snippet ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(thread.snippet!.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            t.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                  if (unread ||
                      thread.hasAttachments ||
                      thread.messageCount > 1) ...[
                    const SizedBox(height: 8),
                    Wrap(
                        spacing: 10,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (unread)
                            Text(
                                Localizations.localeOf(context).languageCode ==
                                        'es'
                                    ? 'Sin leer'
                                    : 'Unread',
                                style: t.labelMedium?.copyWith(
                                    color: cs.primary,
                                    fontWeight: FontWeight.w700)),
                          if (thread.hasAttachments)
                            Tooltip(
                                message: l.mailDetailAttachmentsLabel,
                                child: Icon(Icons.attach_file_rounded,
                                    size: 18, color: cs.onSurfaceVariant)),
                          if (thread.messageCount > 1)
                            Text(
                                Localizations.localeOf(context).languageCode ==
                                        'es'
                                    ? '${thread.messageCount} mensajes'
                                    : '${thread.messageCount} messages',
                                style: t.bodySmall
                                    ?.copyWith(color: cs.onSurfaceVariant)),
                        ]),
                  ],
                ])),
          ]),
        ),
      ),
    );
  }
}
