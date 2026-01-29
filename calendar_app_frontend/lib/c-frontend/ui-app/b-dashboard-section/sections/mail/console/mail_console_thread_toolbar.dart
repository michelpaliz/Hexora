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

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          Text(
            _folderLabel(folder, l),
            style: t.bodyMedium.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              enabled: false,
              decoration: InputDecoration(
                hintText: l.mailConsoleSearchPlaceholder,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cs.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cs.outlineVariant),
                ),
              ),
              style: t.bodySmall,
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            tooltip: l.refreshAction,
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 6),
          IconButton(
            tooltip: hasUnread ? l.mailDetailMarkRead : l.mailDetailMarkUnread,
            onPressed: hasSelection ? onToggleRead : null,
            icon: Icon(
              hasUnread
                  ? Icons.mark_email_read_outlined
                  : Icons.mark_email_unread_outlined,
            ),
          ),
          IconButton(
            tooltip: l.mailDetailArchived,
            onPressed: hasSelection ? onArchive : null,
            icon: const Icon(Icons.archive_outlined),
          ),
          IconButton(
            tooltip: l.mailDetailSpammed,
            onPressed: hasSelection ? onSpam : null,
            icon: const Icon(Icons.report_gmailerrorred_outlined),
          ),
          IconButton(
            tooltip: l.mailDetailTrashed,
            onPressed: hasSelection ? onTrash : null,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}
