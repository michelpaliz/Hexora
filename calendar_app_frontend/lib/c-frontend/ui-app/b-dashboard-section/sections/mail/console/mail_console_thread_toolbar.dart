part of '../mail_console_screen.dart';

class _ThreadToolbar extends StatelessWidget {
  const _ThreadToolbar({
    required this.folder,
    required this.hasSelection,
    required this.hasUnread,
    required this.onRefresh,
    required this.onToggleRead,
    required this.onArchive,
    required this.onSpam,
    required this.onTrash,
  });

  final MailFolder folder;
  final bool hasSelection;
  final bool hasUnread;
  final VoidCallback onRefresh;
  final VoidCallback onToggleRead;
  final VoidCallback onArchive;
  final VoidCallback onSpam;
  final VoidCallback onTrash;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    const iconSize = 20.0;
    const iconConstraints = BoxConstraints(minWidth: 34, minHeight: 34);

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 32,
              child: TextField(
                enabled: false,
                decoration: InputDecoration(
                  hintText: l.mailConsoleSearchPlaceholder,
                  hintStyle: t.bodySmall.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: 12,
                  ),
                  prefixIcon: Icon(Icons.search, size: 18, color: cs.onSurfaceVariant),
                  prefixIconConstraints: const BoxConstraints(minWidth: 32),
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
                  ),
                ),
                style: t.bodySmall.copyWith(fontSize: 12),
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: l.refreshAction,
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
            iconSize: iconSize,
            constraints: iconConstraints,
            padding: EdgeInsets.zero,
          ),
          IconButton(
            tooltip: hasUnread ? l.mailDetailMarkRead : l.mailDetailMarkUnread,
            onPressed: hasSelection ? onToggleRead : null,
            icon: Icon(
              hasUnread
                  ? Icons.mark_email_read_outlined
                  : Icons.mark_email_unread_outlined,
            ),
            iconSize: iconSize,
            constraints: iconConstraints,
            padding: EdgeInsets.zero,
          ),
          IconButton(
            tooltip: l.mailDetailArchived,
            onPressed: hasSelection ? onArchive : null,
            icon: const Icon(Icons.archive_outlined),
            iconSize: iconSize,
            constraints: iconConstraints,
            padding: EdgeInsets.zero,
          ),
          IconButton(
            tooltip: l.mailDetailSpammed,
            onPressed: hasSelection ? onSpam : null,
            icon: const Icon(Icons.report_gmailerrorred_outlined),
            iconSize: iconSize,
            constraints: iconConstraints,
            padding: EdgeInsets.zero,
          ),
          IconButton(
            tooltip: l.mailDetailTrashed,
            onPressed: hasSelection ? onTrash : null,
            icon: const Icon(Icons.delete_outline),
            iconSize: iconSize,
            constraints: iconConstraints,
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
