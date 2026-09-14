part of '../../expense_upload_screen.dart';

class _BatchFileListView extends StatelessWidget {
  final List<_BatchExecutionFile> items;
  final int totalCount;
  final int warningCount;
  final int filterIndex;
  final bool hasAnyFiles;
  final ValueChanged<int> onFilterChanged;
  final VoidCallback? onRemoveWarnings;
  final ValueChanged<int>? onRemoveFile;
  final Future<void> Function(
    List<({String fileName, Uint8List fileBytes})> files, {
    required int selectedCount,
  })? onDropWebDocuments;

  const _BatchFileListView({
    required this.items,
    required this.totalCount,
    required this.warningCount,
    required this.filterIndex,
    this.hasAnyFiles = false,
    required this.onFilterChanged,
    required this.onRemoveWarnings,
    required this.onRemoveFile,
    required this.onDropWebDocuments,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: cs.surface.withValues(alpha: 0.16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.expenseBatchListTitle,
                        style: ts.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      l.expenseBatchListCount(totalCount),
                      style: ts.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  runSpacing: 6,
                  children: [
                    _FilterTab(
                        label: l.expenseBatchListFilterAll,
                        selected: filterIndex == 0,
                        onTap: () => onFilterChanged(0),
                        cs: cs,
                        ts: ts),
                    const SizedBox(width: 4),
                    _FilterTab(
                        label: l.expenseBatchListFilterReady,
                        selected: filterIndex == 1,
                        onTap: () => onFilterChanged(1),
                        cs: cs,
                        ts: ts),
                    const SizedBox(width: 4),
                    _FilterTab(
                        label: l.expenseBatchListFilterIssues,
                        selected: filterIndex == 2,
                        onTap: () => onFilterChanged(2),
                        cs: cs,
                        ts: ts),
                    if (onRemoveWarnings != null)
                      TextButton.icon(
                        onPressed: onRemoveWarnings,
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor: cs.error,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        ),
                        icon: const Icon(Icons.remove_circle_outline, size: 16),
                        label: Text(
                          l.expenseBatchListRemoveWarnings(warningCount),
                          style: ts.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: cs.outlineVariant.withValues(alpha: 0.25),
          ),
          Expanded(
            child: items.isEmpty
                ? (hasAnyFiles
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            l.expenseBatchListEmpty,
                            textAlign: TextAlign.center,
                            style: ts.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                    : _BatchOnboardingFlow(
                        cs: cs,
                        ts: ts,
                        onDropWebDocuments: onDropWebDocuments,
                      ))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: cs.outlineVariant.withValues(alpha: 0.16),
                    ),
                    itemBuilder: (context, index) => _BatchFileListItem(
                      item: items[index],
                      onRemove: onRemoveFile != null &&
                              items[index].status ==
                                  _BatchExecutionFileStatus.warning
                          ? () => onRemoveFile!(items[index].originalIndex)
                          : null,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme cs;
  final TextTheme ts;

  const _FilterTab({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.cs,
    required this.ts,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: selected
              ? cs.primary.withValues(alpha: 0.13)
              : cs.surfaceContainerHighest.withValues(alpha: 0.22),
          border: Border.all(
            color: selected
                ? cs.primary.withValues(alpha: 0.45)
                : cs.outlineVariant.withValues(alpha: 0.28),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.10),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: ts.bodySmall?.copyWith(
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? cs.primary : cs.onSurfaceVariant,
            letterSpacing: selected ? 0.1 : 0,
          ),
        ),
      ),
    );
  }
}

class _BatchFileListItem extends StatelessWidget {
  final _BatchExecutionFile item;
  final VoidCallback? onRemove;

  const _BatchFileListItem({
    required this.item,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;
    final statusColor = item.status == _BatchExecutionFileStatus.success
        ? Colors.green.shade500
        : item.status == _BatchExecutionFileStatus.error
            ? cs.error
            : Colors.amber.shade600;
    final statusIcon = item.status == _BatchExecutionFileStatus.success
        ? Icons.check_circle_rounded
        : item.status == _BatchExecutionFileStatus.error
            ? Icons.error_outline_rounded
            : Icons.warning_amber_rounded;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Icon(statusIcon, size: 13, color: statusColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ts.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  item.detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ts.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatBatchBytes(item.sizeBytes),
            style: ts.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 6),
            IconButton(
              tooltip: 'Quitar de la seleccion',
              onPressed: onRemove,
              visualDensity: VisualDensity.compact,
              iconSize: 16,
              color: cs.error,
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ],
      ),
    );
  }
}

class _BatchVerificationTabPanel extends StatelessWidget {
  final String title;
  final String message;
  final bool hasIssue;
  final bool looksOk;

  const _BatchVerificationTabPanel({
    required this.title,
    required this.message,
    required this.hasIssue,
    required this.looksOk,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;
    final icon = hasIssue
        ? Icons.error_outline
        : looksOk
            ? Icons.check_circle_outline
            : Icons.hourglass_bottom;
    final accent = hasIssue
        ? cs.error
        : looksOk
            ? Colors.green.shade600
            : cs.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: cs.surface.withValues(alpha: 0.18),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: 8),
              Text(
                title,
                style: ts.bodyMedium?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: ts.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _SkippedFileRow extends StatelessWidget {
  final String detail;
  final ColorScheme cs;
  final TextTheme ts;

  const _SkippedFileRow({
    required this.detail,
    required this.cs,
    required this.ts,
  });

  @override
  Widget build(BuildContext context) {
    // Parse "filename ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â reason"
    final sepIdx = detail.indexOf(' \u2014 ');
    final filename = sepIdx > 0 ? detail.substring(0, sepIdx).trim() : detail;
    final reason = sepIdx > 0 ? detail.substring(sepIdx + 3).trim() : '';

    final lower = reason.toLowerCase();
    final isFormatError = lower.contains('formato') ||
        lower.contains('soportado') ||
        lower.contains('format');

    final iconData = isFormatError ? Icons.block_outlined : Icons.error_outline;
    final iconColor = isFormatError
        ? Colors.amber.shade500
        : cs.error.withValues(alpha: 0.75);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(iconData, size: 12, color: iconColor),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  filename,
                  style: ts.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (reason.isNotEmpty)
                  Text(
                    reason,
                    style: ts.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontSize: 10,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
