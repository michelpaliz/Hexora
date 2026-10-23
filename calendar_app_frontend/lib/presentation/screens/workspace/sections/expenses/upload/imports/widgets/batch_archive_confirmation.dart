part of '../../expense_upload_screen.dart';

class _BatchArchiveConfirmation extends StatelessWidget {
  final String archiveName;
  final int archiveSizeBytes;
  final bool inspecting;
  final List<Map<String, dynamic>> files;
  final List<Map<String, dynamic>> skipped;
  final List<String> warnings;
  final String? inspectionError;
  final bool blocked;
  final bool expanded;
  final bool canAnalyze;
  final bool analyzing;
  final VoidCallback onToggleExpanded;
  final VoidCallback onCancel;
  final VoidCallback onReplace;
  final VoidCallback onConfirm;
  final VoidCallback onRetry;

  const _BatchArchiveConfirmation({
    required this.archiveName,
    required this.archiveSizeBytes,
    required this.inspecting,
    required this.files,
    required this.skipped,
    required this.warnings,
    required this.inspectionError,
    required this.blocked,
    required this.expanded,
    required this.canAnalyze,
    required this.analyzing,
    required this.onToggleExpanded,
    required this.onCancel,
    required this.onReplace,
    required this.onConfirm,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;
    final totalEntries = files.length + skipped.length;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(Icons.folder_zip_outlined,
                      size: 19, color: cs.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        archiveName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ts.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatBatchBytes(archiveSizeBytes),
                        style: ts.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: inspecting || analyzing ? null : onReplace,
                  child: const Text('Reemplazar ZIP'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (inspecting)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Inspeccionando el contenido del ZIP…',
                      style: ts.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'El análisis OCR todavía no ha comenzado.',
                      style: ts.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (inspectionError != null)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline_rounded,
                          color: cs.error, size: 28),
                      const SizedBox(height: 8),
                      Text(
                        inspectionError!,
                        textAlign: TextAlign.center,
                        style: ts.bodySmall?.copyWith(color: cs.error),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Reintentar inspeccion'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _BatchArchiveMetric(
                    icon: Icons.description_outlined,
                    label: '${files.length} compatibles',
                    color: Colors.green.shade700,
                  ),
                  _BatchArchiveMetric(
                    icon: Icons.do_not_disturb_alt_outlined,
                    label: '${skipped.length} omitidos',
                    color: skipped.isEmpty
                        ? cs.onSurfaceVariant
                        : Colors.amber.shade800,
                  ),
                  _BatchArchiveMetric(
                    icon: Icons.inventory_2_outlined,
                    label: '$totalEntries archivos detectados',
                    color: cs.primary,
                  ),
                ],
              ),
            ),
            if (warnings.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.32),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 16, color: Colors.amber.shade800),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          warnings.join('\n'),
                          style: ts.bodySmall?.copyWith(height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (blocked)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                child: Text(
                  'El ZIP contiene entradas no seguras o danadas. Selecciona otro archivo.',
                  style: ts.bodySmall?.copyWith(
                    color: cs.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: totalEntries == 0 ? null : onToggleExpanded,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        expanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        expanded
                            ? 'Ocultar archivos detectados'
                            : 'Ver archivos detectados',
                        style: ts.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (expanded)
              Expanded(
                child: _BatchArchiveFileTable(files: files, skipped: skipped),
              )
            else
              const Spacer(),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton(
                    onPressed: analyzing ? null : onCancel,
                    child: const Text('Cancelar'),
                  ),
                  FilledButton.icon(
                    onPressed: canAnalyze && !analyzing ? onConfirm : null,
                    icon: analyzing
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome_outlined, size: 17),
                    label: Text(
                      analyzing
                          ? 'Iniciando análisis…'
                          : 'Confirmar y analizar',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BatchArchiveMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _BatchArchiveMetric({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      );
}

class _BatchArchiveFileTable extends StatelessWidget {
  final List<Map<String, dynamic>> files;
  final List<Map<String, dynamic>> skipped;

  const _BatchArchiveFileTable({required this.files, required this.skipped});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;
    final rows = <({Map<String, dynamic> item, bool supported})>[
      for (final item in files) (item: item, supported: true),
      for (final item in skipped) (item: item, supported: false),
    ];
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 2, 14, 10),
      itemCount: rows.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color: cs.outlineVariant.withValues(alpha: 0.35),
      ),
      itemBuilder: (context, index) {
        final row = rows[index];
        final name = (row.item['name'] ?? '').toString();
        final reason = (row.item['reason'] ?? '').toString();
        final size = row.item['sizeBytes'] is num
            ? (row.item['sizeBytes'] as num).toInt()
            : 0;
        return SizedBox(
          height: 42,
          child: Row(
            children: [
              Icon(
                row.supported
                    ? Icons.check_circle_outline_rounded
                    : Icons.error_outline_rounded,
                size: 16,
                color: row.supported ? Colors.green.shade600 : cs.error,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Tooltip(
                  message: name,
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ts.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              if (!row.supported) ...[
                const SizedBox(width: 8),
                Text(
                  reason,
                  style: ts.labelSmall?.copyWith(color: cs.error),
                ),
              ],
              const SizedBox(width: 12),
              Text(
                _formatBatchBytes(size),
                style: ts.labelSmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        );
      },
    );
  }
}
