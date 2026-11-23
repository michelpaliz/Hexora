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

// Legacy compatibility shell retained for older embedded callers.
// ignore: unused_element
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
  final bool inspecting;
  final bool selectionReady;
  final int readyCount;
  final int reviewCount;
  final int duplicateCount;
  final VoidCallback onImport;
  final VoidCallback? onClearSelection;
  final bool collapsed;
  final VoidCallback? onToggleCollapsed;
  final bool compact;

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
    required this.inspecting,
    required this.selectionReady,
    required this.readyCount,
    required this.reviewCount,
    required this.duplicateCount,
    required this.onImport,
    this.onClearSelection,
    this.collapsed = false,
    this.onToggleCollapsed,
    this.compact = false,
  });

  int get _activeStep {
    if (jobActive) return 2;
    if (jobCompleted || jobFailed) {
      return reviewCount > 0 || duplicateCount > 0 ? 3 : 4;
    }
    if (inspecting || selectionReady) return 1;
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
      isEs ? 'Confirmar' : 'Confirm',
      'OCR',
      isEs ? 'Revisi\u00f3n' : 'Review',
      isEs ? 'Importaci\u00f3n' : 'Import',
    ];

    Widget stepRow(int index) {
      final active = index == activeStep;
      final completed = !jobFailed && index < activeStep;
      final future = index > activeStep;
      final color = active || completed ? cs.primary : cs.onSurfaceVariant;
      return Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: active ? cs.primary.withValues(alpha: .09) : null,
          border: Border(
            left: BorderSide(
              width: 2,
              color: active ? cs.primary : Colors.transparent,
            ),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active
                      ? cs.primary
                      : completed
                          ? cs.primaryContainer
                          : cs.surfaceContainerHighest,
                ),
                child: Center(
                  child: completed
                      ? Icon(Icons.check_rounded, size: 13, color: cs.primary)
                      : Text(
                          '${index + 1}',
                          style: ts.bodySmall?.copyWith(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: active
                                ? cs.onPrimary
                                : color.withValues(alpha: future ? .55 : 1),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                steps[index],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ts.bodySmall?.copyWith(
                  fontSize: 11.5,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  color: color.withValues(alpha: future ? .58 : 1),
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget metric(String label, String value, {Color? valueColor}) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(label,
                    style: ts.bodySmall?.copyWith(
                      fontSize: 11,
                      color: cs.onSurfaceVariant,
                    )),
              ),
              Text(value,
                  style: ts.bodySmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: valueColor ?? cs.onSurface,
                  )),
            ],
          ),
        );

    final workflow = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 7),
          child: Text(
            isEs ? 'IMPORTACI\u00d3N MASIVA' : 'BULK IMPORT',
            style: ts.labelSmall?.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: .8,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        for (var i = 0; i < steps.length; i++) stepRow(i),
        Divider(height: 17, color: cs.outlineVariant.withValues(alpha: .35)),
        metric(
            isEs ? 'Documentos' : 'Documents', '$selectedCount / $maxDocuments',
            valueColor: cs.primary),
        metric(isEs ? 'Listos' : 'Ready', '$readyCount',
            valueColor: Colors.green.shade600),
        metric(isEs ? 'Revisi\u00f3n' : 'Review', '$reviewCount',
            valueColor: Colors.amber.shade700),
        metric(isEs ? 'Duplicados' : 'Duplicates', '$duplicateCount',
            valueColor: cs.error),
        metric(isEs ? 'Tama\u00f1o' : 'Size', _formatBatchBytes(totalBytes)),
        const SizedBox(height: 10),
        if (onClearSelection != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TextButton.icon(
              onPressed: submitting ? null : onClearSelection,
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(32),
                visualDensity: VisualDensity.compact,
              ),
              icon: const Icon(Icons.close_rounded, size: 14),
              label: Text(isEs ? 'Limpiar' : 'Clear'),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
          child: FilledButton.icon(
            onPressed: canImport ? onImport : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(36),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
            ),
            icon: submitting
                ? const SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome_outlined, size: 15),
            label: Text(
              jobCompleted
                  ? (isEs ? 'Completado' : 'Complete')
                  : jobActive
                      ? (isEs ? 'Procesando' : 'Processing')
                      : inspecting
                          ? (isEs ? 'Inspeccionando' : 'Inspecting')
                          : (isEs ? 'Confirmar y analizar' : 'Confirm'),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        if (!hasGroupSelected)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Text(
              isEs ? 'Selecciona un grupo.' : 'Select a group.',
              style: ts.bodySmall?.copyWith(fontSize: 10.5, color: cs.error),
            ),
          ),
      ],
    );

    if (compact) {
      return Container(
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border.all(color: cs.outlineVariant.withValues(alpha: .32)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: ExpansionTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          tilePadding: const EdgeInsets.symmetric(horizontal: 10),
          title: Text('${activeStep + 1}. ${steps[activeStep]}'),
          subtitle: Text(
            '$selectedCount / $maxDocuments \u00b7 $readyCount listos \u00b7 $reviewCount revisi\u00f3n',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          children: [workflow],
        ),
      );
    }

    return DocumentWizardRail(
      keyPrefix: 'expense-batch-wizard',
      steps: [
        DocumentWizardStep(label: steps[0], icon: Icons.description_outlined),
        DocumentWizardStep(label: steps[1], icon: Icons.checklist_rounded),
        DocumentWizardStep(
            label: steps[2], icon: Icons.document_scanner_outlined),
        DocumentWizardStep(label: steps[3], icon: Icons.fact_check_outlined),
        DocumentWizardStep(label: steps[4], icon: Icons.save_alt_rounded),
      ],
      currentStep: activeStep,
      selectedSectionId: null,
      groupExpanded: false,
      collapsed: collapsed,
      expandedWidth: 196,
      allowCollapse: onToggleCollapsed != null,
      title: isEs ? 'Importaci\u00f3n masiva' : 'Bulk import',
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      footer: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Divider(color: cs.outlineVariant.withValues(alpha: .35)),
            metric(isEs ? 'Documentos' : 'Documents',
                '$selectedCount / $maxDocuments',
                valueColor: cs.primary),
            metric(isEs ? 'Listos' : 'Ready', '$readyCount',
                valueColor: Colors.green.shade600),
            metric(isEs ? 'Revisi\u00f3n' : 'Review', '$reviewCount',
                valueColor: Colors.amber.shade700),
            metric(isEs ? 'Duplicados' : 'Duplicates', '$duplicateCount',
                valueColor: cs.error),
            if (onClearSelection != null)
              TextButton.icon(
                onPressed: submitting ? null : onClearSelection,
                style: TextButton.styleFrom(
                  minimumSize: const Size.fromHeight(30),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.close_rounded, size: 14),
                label: Text(isEs ? 'Limpiar' : 'Clear'),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: FilledButton.icon(
                onPressed: canImport ? onImport : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(36),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: VisualDensity.compact,
                ),
                icon: submitting
                    ? const SizedBox(
                        width: 13,
                        height: 13,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome_outlined, size: 15),
                label: Text(
                  jobCompleted
                      ? (isEs ? 'Completado' : 'Complete')
                      : jobActive
                          ? (isEs ? 'Procesando' : 'Processing')
                          : inspecting
                              ? (isEs ? 'Inspeccionando' : 'Inspecting')
                              : (isEs ? 'Confirmar' : 'Confirm'),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
      onStepSelected: (_) {},
      onSectionSelected: (_) {},
      onToggleGroup: () {},
      onToggleCollapsed: onToggleCollapsed ?? () {},
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
    final color = active || completed ? cs.primary : cs.onSurfaceVariant;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active
                  ? cs.primary
                  : completed
                      ? cs.primaryContainer
                      : cs.surfaceContainerHighest,
            ),
            child: completed
                ? Icon(Icons.check_rounded, size: 15, color: cs.primary)
                : Text(
                    '${index + 1}',
                    style: ts.bodySmall?.copyWith(
                      color: active
                          ? cs.onPrimary
                          : pending
                              ? color.withValues(alpha: 0.68)
                              : color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: ts.bodySmall?.copyWith(
              color: pending ? color.withValues(alpha: 0.64) : color,
              fontWeight: active ? FontWeight.w800 : FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
