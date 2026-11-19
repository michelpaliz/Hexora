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
  final VoidCallback onRemove;
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
    required this.onRemove,
    required this.onReplace,
    required this.onConfirm,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;
    final totalEntries = files.length + skipped.length;
    final busy = inspecting || analyzing;

    // Validation status
    final Color statusColor;
    final IconData statusIcon;
    final String statusLabel;
    if (inspecting) {
      statusColor = cs.primary;
      statusIcon = Icons.hourglass_top_rounded;
      statusLabel = 'Inspeccionando…';
    } else if (inspectionError != null) {
      statusColor = cs.error;
      statusIcon = Icons.error_outline_rounded;
      statusLabel = 'Error de inspección';
    } else if (blocked) {
      statusColor = cs.error;
      statusIcon = Icons.block_rounded;
      statusLabel = 'Bloqueado';
    } else if (files.isNotEmpty) {
      statusColor = Colors.green.shade700;
      statusIcon = Icons.check_circle_outline_rounded;
      statusLabel = 'Listo para analizar';
    } else {
      statusColor = Colors.amber.shade800;
      statusIcon = Icons.warning_amber_rounded;
      statusLabel = 'Sin compatibles';
    }

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
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.folder_zip_outlined,
                      size: 17, color: cs.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Tooltip(
                        message: archiveName,
                        child: Text(
                          archiveName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ts.bodySmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            _formatBatchBytes(archiveSizeBytes),
                            style: ts.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                          if (totalEntries > 0) ...[
                            Text(
                              ' · $totalEntries detectados',
                              style: ts.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ],
                          const SizedBox(width: 6),
                          Icon(statusIcon, size: 12, color: statusColor),
                          const SizedBox(width: 3),
                          Text(
                            statusLabel,
                            style: ts.bodySmall?.copyWith(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                OutlinedButton.icon(
                  onPressed: busy ? null : onReplace,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 32),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: ts.bodySmall?.copyWith(
                        fontSize: 12, fontWeight: FontWeight.w600),
                    side: BorderSide(
                        color: cs.outlineVariant.withValues(alpha: 0.7)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.swap_horiz_rounded, size: 14),
                  label: const Text('Reemplazar'),
                ),
                const SizedBox(width: 4),
                Tooltip(
                  message: 'Eliminar ZIP',
                  child: IconButton(
                    onPressed: busy ? null : onRemove,
                    icon: const Icon(Icons.delete_outline_rounded, size: 17),
                    style: IconButton.styleFrom(
                      foregroundColor: cs.error,
                      minimumSize: const Size(32, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
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
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _BatchArchiveMetric(
                    icon: Icons.description_outlined,
                    label: '${files.length} compatibles',
                    color: Colors.green.shade700,
                  ),
                  if (skipped.isNotEmpty)
                    _BatchArchiveMetric(
                      icon: Icons.do_not_disturb_alt_outlined,
                      label: '${skipped.length} omitidos',
                      color: Colors.amber.shade800,
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton.icon(
                    onPressed: canAnalyze && !analyzing ? onConfirm : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 34),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: ts.bodySmall?.copyWith(
                          fontSize: 12, fontWeight: FontWeight.w700),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: analyzing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome_outlined, size: 15),
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

  static String _fileType(String name) {
    final ext = name.contains('.')
        ? name.substring(name.lastIndexOf('.') + 1).toUpperCase()
        : '';
    return ext.isEmpty ? '—' : ext;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;
    final rows = <({Map<String, dynamic> item, bool supported})>[
      for (final item in files) (item: item, supported: true),
      for (final item in skipped) (item: item, supported: false),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header row
        Container(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
          color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
          child: Row(
            children: [
              const SizedBox(width: 22),
              Expanded(
                flex: 5,
                child: Text(
                  'Archivo',
                  style: ts.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
              SizedBox(
                width: 42,
                child: Text(
                  'Tipo',
                  style: ts.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
              SizedBox(
                width: 62,
                child: Text(
                  'Tamaño',
                  textAlign: TextAlign.right,
                  style: ts.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
            itemCount: rows.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: cs.outlineVariant.withValues(alpha: 0.28),
            ),
            itemBuilder: (context, index) {
              final row = rows[index];
              final name = (row.item['name'] ?? '').toString();
              final reason = (row.item['reason'] ?? '').toString();
              final size = row.item['sizeBytes'] is num
                  ? (row.item['sizeBytes'] as num).toInt()
                  : 0;
              final fileType = _fileType(name);
              final rowColor = row.supported
                  ? Colors.green.shade600
                  : cs.error;
              return SizedBox(
                height: 38,
                child: Row(
                  children: [
                    Icon(
                      row.supported
                          ? Icons.check_circle_outline_rounded
                          : Icons.error_outline_rounded,
                      size: 15,
                      color: rowColor,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      flex: 5,
                      child: Tooltip(
                        message: reason.isNotEmpty ? '$name\n$reason' : name,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: ts.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 11.5,
                              ),
                            ),
                            if (!row.supported && reason.isNotEmpty)
                              Text(
                                reason,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: ts.labelSmall?.copyWith(
                                  color: cs.error,
                                  fontSize: 10,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 42,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          fileType,
                          textAlign: TextAlign.center,
                          style: ts.labelSmall?.copyWith(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 62,
                      child: Text(
                        _formatBatchBytes(size),
                        textAlign: TextAlign.right,
                        style: ts.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
