part of '../../expense_upload_screen.dart';

class _StepRow extends StatelessWidget {
  final int index;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isActive;
  final bool isCompleted;
  final bool isReachable;
  final VoidCallback? onTap;
  final ColorScheme cs;
  final TextTheme ts;

  const _StepRow({
    required this.index,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isActive,
    required this.isCompleted,
    required this.isReachable,
    required this.onTap,
    required this.cs,
    required this.ts,
  });

  @override
  Widget build(BuildContext context) {
    final Color circleColor;
    final Color circleContent;
    final Color titleColor;

    if (isActive) {
      circleColor = cs.primary;
      circleContent = cs.onPrimary;
      titleColor = cs.primary;
    } else if (isCompleted) {
      circleColor = cs.primaryContainer.withValues(alpha: 0.6);
      circleContent = cs.primary;
      titleColor = cs.onSurface;
    } else {
      circleColor = cs.outlineVariant.withValues(alpha: 0.35);
      circleContent = cs.onSurfaceVariant.withValues(alpha: 0.5);
      titleColor = cs.onSurfaceVariant.withValues(alpha: 0.5);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: isActive
              ? cs.primaryContainer.withValues(alpha: 0.22)
              : Colors.transparent,
          border: Border.all(
            color: isActive
                ? cs.primary.withValues(alpha: 0.22)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 3,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: isActive ? cs.primary : Colors.transparent,
              ),
            ),
            const SizedBox(width: 7),
            // Circle indicator
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: circleColor,
              ),
              child: Center(
                child: isCompleted
                    ? Icon(Icons.check_rounded, size: 14, color: circleContent)
                    : Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: circleContent,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isActive
                        ? 'ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“Ãƒâ€šÃ‚Â¶ $title'
                        : title,
                    style: ts.bodySmall?.copyWith(
                      fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: ts.bodySmall?.copyWith(
                      fontSize: 11,
                      color: isActive
                          ? cs.primary.withValues(alpha: 0.75)
                          : cs.onSurfaceVariant
                              .withValues(alpha: isReachable ? 0.7 : 0.4),
                    ),
                  ),
                ],
              ),
            ),
            if (isActive)
              Icon(Icons.chevron_right_rounded,
                  size: 16, color: cs.primary.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }
}

class _StepDropZone extends StatefulWidget {
  final bool enabled;

  const _StepDropZone({required this.enabled});

  @override
  State<_StepDropZone> createState() => _StepDropZoneState();
}

class _StepDropZoneState extends State<_StepDropZone> {
  final bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;

    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: _dragging
            ? cs.primaryContainer.withValues(alpha: 0.16)
            : cs.surface.withValues(alpha: 0.2),
        border: Border.all(
          color: _dragging
              ? cs.primary.withValues(alpha: 0.8)
              : cs.outlineVariant.withValues(alpha: 0.3),
          width: _dragging ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _dragging
                ? Icons.file_download_done_outlined
                : Icons.move_to_inbox_outlined,
            size: 20,
            color: _dragging ? cs.primary : cs.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Text(
            _dragging ? l.expenseJsonLeftDropActive : l.expenseJsonLeftDropHint,
            style: ts.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: _dragging ? cs.primary : cs.onSurface,
            ),
          ),
        ],
      ),
    );

    return content;
  }
}

class _ManualCompactWorkflowIndicator extends StatelessWidget {
  final String? fileName;
  final Uint8List? fileBytes;
  final bool submitting;
  final bool hasGroupSelected;
  final VoidCallback onPickFile;
  final VoidCallback? onPreviewFile;
  final String? previewCtaLabel;

  const _ManualCompactWorkflowIndicator({
    required this.fileName,
    required this.fileBytes,
    required this.submitting,
    required this.hasGroupSelected,
    required this.onPickFile,
    required this.onPreviewFile,
    required this.previewCtaLabel,
  });

  @override
  Widget build(BuildContext context) {
    final selected = (fileName ?? '').trim().isNotEmpty &&
        fileBytes != null &&
        fileBytes!.isNotEmpty;
    return _CompactImportWorkflowShell(
      steps: const ['Documento', 'Datos', 'Revision', 'Guardado'],
      activeStep: selected ? 1 : 0,
      readyCount: selected ? 1 : 0,
      reviewCount: selected ? 1 : 0,
      duplicateCount: 0,
      hasGroupSelected: hasGroupSelected,
      actions: [
        OutlinedButton.icon(
          onPressed: submitting ? null : onPickFile,
          style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
          icon: const Icon(Icons.upload_file_outlined, size: 16),
          label: Text(selected ? 'Cambiar documento' : 'Elegir documento'),
        ),
        if (onPreviewFile != null && previewCtaLabel != null)
          OutlinedButton.icon(
            onPressed: onPreviewFile,
            style:
                OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
            icon: const Icon(Icons.visibility_outlined, size: 16),
            label: Text(previewCtaLabel!),
          ),
      ],
      helper: selected ? fileName!.trim() : 'Ningun documento seleccionado',
    );
  }
}

class _JsonCompactWorkflowIndicator extends StatelessWidget {
  final bool submitting;
  final bool hasGroupSelected;
  final int activeStep;
  final bool hasPayload;
  final bool hasInvoiceFile;
  final void Function(int) onStepTapped;
  final VoidCallback onImport;

  const _JsonCompactWorkflowIndicator({
    required this.submitting,
    required this.hasGroupSelected,
    required this.activeStep,
    required this.hasPayload,
    required this.hasInvoiceFile,
    required this.onStepTapped,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    return _CompactImportWorkflowShell(
      steps: const ['Documento', 'Extraccion', 'Revision', 'Importacion'],
      activeStep: activeStep,
      readyCount: hasPayload ? 1 : 0,
      reviewCount: activeStep >= 2 ? 1 : 0,
      duplicateCount: 0,
      hasGroupSelected: hasGroupSelected,
      onStepTapped: onStepTapped,
      actions: [
        FilledButton.icon(
          onPressed: submitting || !hasGroupSelected || activeStep < 3
              ? null
              : onImport,
          style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
          icon: submitting
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.arrow_forward_rounded, size: 16),
          label: const Text('Importar JSON'),
        ),
      ],
      helper: [
        if (hasPayload) 'JSON listo' else 'JSON pendiente',
        if (hasInvoiceFile) 'factura adjunta',
      ].join(' Â· '),
    );
  }
}

class _CompactImportWorkflowShell extends StatelessWidget {
  final List<String> steps;
  final int activeStep;
  final int readyCount;
  final int reviewCount;
  final int duplicateCount;
  final bool hasGroupSelected;
  final List<Widget> actions;
  final String helper;
  final void Function(int)? onStepTapped;

  const _CompactImportWorkflowShell({
    required this.steps,
    required this.activeStep,
    required this.readyCount,
    required this.reviewCount,
    required this.duplicateCount,
    required this.hasGroupSelected,
    required this.actions,
    required this.helper,
    this.onStepTapped,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: cs.surface.withValues(alpha: 0.18),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.28)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 860;
          final stepper = Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (var i = 0; i < steps.length; i++) ...[
                InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: onStepTapped == null ? null : () => onStepTapped!(i),
                  child: _CompactWorkflowStep(
                    label: steps[i],
                    index: i,
                    activeIndex: activeStep,
                    failed: false,
                  ),
                ),
                if (i < steps.length - 1)
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: i < activeStep
                        ? cs.primary.withValues(alpha: 0.55)
                        : cs.onSurfaceVariant.withValues(alpha: 0.34),
                  ),
              ],
            ],
          );
          final summary = Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _BatchStatusChip(
                label: '$readyCount listo${readyCount == 1 ? '' : 's'}',
                color: Colors.green.shade600,
              ),
              _BatchStatusChip(
                label: '$reviewCount revision',
                color: Colors.amber.shade700,
              ),
              _BatchStatusChip(
                label: '$duplicateCount duplicados',
                color: cs.error,
              ),
              if (helper.trim().isNotEmpty)
                Text(
                  helper.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ts.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          );
          final actionWrap = Wrap(spacing: 8, runSpacing: 6, children: actions);
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                stepper,
                const SizedBox(height: 8),
                summary,
                const SizedBox(height: 8),
                actionWrap,
                if (!hasGroupSelected) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Selecciona un grupo antes de importar.',
                    style: ts.bodySmall?.copyWith(color: cs.error),
                  ),
                ],
              ],
            );
          }
          return Row(
            children: [
              Expanded(flex: 5, child: stepper),
              const SizedBox(width: 12),
              Expanded(flex: 4, child: summary),
              const SizedBox(width: 12),
              actionWrap,
            ],
          );
        },
      ),
    );
  }
}

class _BatchCompactWorkflowIndicator extends StatelessWidget {
  final int selectedCount;
  final int maxDocuments;
  final int totalBytes;
  final bool submitting;
  final bool hasGroupSelected;
  final bool canImport;
  final bool jobActive;
  final bool jobCompleted;
  final bool jobFailed;
  final int readyCount;
  final int reviewCount;
  final int duplicateCount;
  final VoidCallback onPickDocuments;
  final VoidCallback onImport;
  final VoidCallback? onClearSelection;

  const _BatchCompactWorkflowIndicator({
    required this.selectedCount,
    required this.maxDocuments,
    required this.totalBytes,
    required this.submitting,
    required this.hasGroupSelected,
    required this.canImport,
    required this.jobActive,
    required this.jobCompleted,
    required this.jobFailed,
    required this.readyCount,
    required this.reviewCount,
    required this.duplicateCount,
    required this.onPickDocuments,
    required this.onImport,
    this.onClearSelection,
  });

  int get _activeStep {
    if (jobActive) return 1;
    if (jobCompleted || jobFailed) {
      return reviewCount > 0 || duplicateCount > 0 ? 2 : 3;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final activeStep = _activeStep;
    final steps = [
      isEs ? 'Documentos' : 'Documents',
      'OCR',
      isEs ? 'Revisi\u00f3n' : 'Review',
      isEs ? 'Importaci\u00f3n' : 'Import',
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: cs.surface.withValues(alpha: 0.18),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.28)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 860;
          final stepper = Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (var i = 0; i < steps.length; i++) ...[
                _CompactWorkflowStep(
                  label: steps[i],
                  index: i,
                  activeIndex: activeStep,
                  failed: jobFailed,
                ),
                if (i < steps.length - 1)
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: i < activeStep
                        ? cs.primary.withValues(alpha: 0.55)
                        : cs.onSurfaceVariant.withValues(alpha: 0.34),
                  ),
              ],
            ],
          );

          final summary = Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _BatchStatusChip(
                label: '$readyCount gastos listos',
                color: Colors.green.shade600,
              ),
              _BatchStatusChip(
                label: '$reviewCount revisi\u00f3n',
                color: Colors.amber.shade700,
              ),
              _BatchStatusChip(
                label: '$duplicateCount duplicados',
                color: cs.error,
              ),
              _InlineMetric(
                icon: Icons.insert_drive_file_outlined,
                label: '$selectedCount / $maxDocuments',
                color: cs.primary,
              ),
              _InlineMetric(
                icon: Icons.data_usage_outlined,
                label: _formatBatchBytes(totalBytes),
                color: cs.onSurfaceVariant,
              ),
            ],
          );

          final actions = Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: submitting ? null : onPickDocuments,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(
                    color: cs.primary.withValues(alpha: 0.45),
                  ),
                  foregroundColor: cs.primary,
                ),
                icon: const Icon(Icons.upload_file_outlined, size: 16),
                label: Text(
                  isEs ? 'Documentos' : 'Documents',
                  style: ts.bodySmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              if (onClearSelection != null)
                IconButton.outlined(
                  tooltip: isEs ? 'Limpiar seleccion' : 'Clear selection',
                  onPressed: submitting ? null : onClearSelection,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close_rounded, size: 16),
                ),
              FilledButton.icon(
                onPressed: canImport ? onImport : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: submitting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome_outlined, size: 16),
                label: Text(
                  jobCompleted
                      ? (isEs ? 'Lote completado' : 'Batch complete')
                      : jobActive
                          ? (isEs ? 'Procesando...' : 'Processing...')
                          : (isEs ? 'Analizar documentos' : 'Analyze'),
                  style: ts.bodySmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                stepper,
                const SizedBox(height: 8),
                summary,
                const SizedBox(height: 8),
                actions,
                if (!hasGroupSelected) ...[
                  const SizedBox(height: 6),
                  Text(
                    isEs
                        ? 'Selecciona un grupo antes de importar.'
                        : 'Select a group before importing.',
                    style: ts.bodySmall?.copyWith(color: cs.error),
                  ),
                ],
              ],
            );
          }

          return Row(
            children: [
              Expanded(flex: 5, child: stepper),
              const SizedBox(width: 12),
              Expanded(flex: 4, child: summary),
              const SizedBox(width: 12),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _CompactWorkflowStep extends StatelessWidget {
  final String label;
  final int index;
  final int activeIndex;
  final bool failed;

  const _CompactWorkflowStep({
    required this.label,
    required this.index,
    required this.activeIndex,
    required this.failed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;
    final completed = !failed && index < activeIndex;
    final active = index == activeIndex;
    final pending = index > activeIndex;
    final color = active
        ? cs.primary
        : completed
            ? Colors.green.shade600
            : cs.onSurfaceVariant;
    final icon = completed
        ? Icons.check_rounded
        : active
            ? Icons.play_arrow_rounded
            : Icons.circle_outlined;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: active
            ? cs.primaryContainer.withValues(alpha: 0.22)
            : Colors.transparent,
        border: Border.all(
          color:
              active ? cs.primary.withValues(alpha: 0.28) : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: active ? 16 : 14,
            color: pending ? color.withValues(alpha: 0.55) : color,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: ts.bodySmall?.copyWith(
              color: pending ? color.withValues(alpha: 0.64) : color,
              fontWeight: active ? FontWeight.w900 : FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
