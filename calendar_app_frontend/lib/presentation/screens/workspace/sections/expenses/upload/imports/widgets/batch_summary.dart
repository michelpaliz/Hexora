part of '../../expense_upload_screen.dart';

class _ResultRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final TextTheme ts;

  const _ResultRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.ts,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: ts.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _InlineMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InlineMetric({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ts = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: ts.bodySmall?.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _BatchCollapsibleSummary extends StatelessWidget {
  final bool collapsed;
  final VoidCallback onToggle;
  final int loadedCount;
  final int maxCount;
  final int totalBytes;
  final int remainingSlots;
  final double uploadRatio;
  final String status;
  final bool hasTrackedJob;
  final int totalFiles;
  final int processedFiles;
  final int importedCount;
  final int skippedCount;
  final int reviewCount;
  final int duplicateCount;
  final String currentStep;
  final String message;
  final bool loadingResult;
  final List<String> warningDetails;
  final bool warningsExpanded;
  final VoidCallback? onToggleWarnings;
  final VoidCallback? onCopyWarnings;

  const _BatchCollapsibleSummary({
    required this.collapsed,
    required this.onToggle,
    required this.loadedCount,
    required this.maxCount,
    required this.totalBytes,
    required this.remainingSlots,
    required this.uploadRatio,
    required this.status,
    required this.hasTrackedJob,
    required this.totalFiles,
    required this.processedFiles,
    required this.importedCount,
    required this.skippedCount,
    required this.reviewCount,
    required this.duplicateCount,
    required this.currentStep,
    required this.message,
    required this.loadingResult,
    required this.warningDetails,
    required this.warningsExpanded,
    required this.onToggleWarnings,
    required this.onCopyWarnings,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;
    final isCompleted = status == 'completed';
    final isFailed = status == 'failed';
    final accent = isCompleted
        ? Colors.green.shade600
        : isFailed
            ? cs.error
            : cs.primary;
    final title = isCompleted
        ? 'Importacion completada'
        : isFailed
            ? 'Importacion fallida'
            : 'Importacion masiva';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? Colors.green.shade600.withValues(alpha: 0.45)
              : isFailed
                  ? cs.error.withValues(alpha: 0.3)
                  : cs.outlineVariant.withValues(alpha: 0.28),
          width: isCompleted ? 1.5 : 1.0,
        ),
        color: isCompleted
            ? Colors.green.withValues(alpha: 0.07)
            : isFailed
                ? cs.error.withValues(alpha: 0.04)
                : cs.surface.withValues(alpha: 0.14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 7, 8, 7),
              child: Row(
                children: [
                  Icon(
                    isCompleted
                        ? Icons.check_circle_rounded
                        : isFailed
                            ? Icons.error_outline
                            : Icons.layers_outlined,
                    size: isCompleted ? 18 : 16,
                    color: accent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: ts.bodyMedium?.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (isCompleted && hasTrackedJob) ...[
                          const SizedBox(height: 1),
                          Text(
                            [
                              '$importedCount importados',
                              if (skippedCount > 0)
                                '$skippedCount incidencias'
                              else
                                'sin incidencias',
                            ].join(' · '),
                            style: ts.bodySmall?.copyWith(
                              color: accent.withValues(alpha: 0.72),
                              fontWeight: FontWeight.w500,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _BatchStatusChip(
                        label: '$loadedCount / $maxCount',
                        color: cs.primary,
                      ),
                      if (hasTrackedJob)
                        _BatchStatusChip(
                          label: '$processedFiles procesados',
                          color: accent,
                        ),
                      if (importedCount > 0)
                        _BatchStatusChip(
                          label: '$importedCount listos',
                          color: Colors.green.shade600,
                        ),
                      if (skippedCount > 0)
                        _BatchStatusChip(
                          label: '$skippedCount incidencias',
                          color: Colors.amber.shade700,
                        ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    collapsed
                        ? Icons.expand_more_rounded
                        : Icons.expand_less_rounded,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (hasTrackedJob)
                    _BatchJobProgressCard(
                      status: status,
                      totalFiles: totalFiles,
                      processedFiles: processedFiles,
                      importedCount: importedCount,
                      skippedCount: skippedCount,
                      reviewCount: reviewCount,
                      duplicateCount: duplicateCount,
                      progress: uploadRatio,
                      currentStep: currentStep,
                      message: message,
                      loadingResult: loadingResult,
                      warningDetails: warningDetails,
                      warningsExpanded: warningsExpanded,
                      onToggleWarnings: onToggleWarnings,
                      onCopyWarnings: onCopyWarnings,
                    )
                  else
                    _BatchMiniImportDetails(
                      loadedCount: loadedCount,
                      maxCount: maxCount,
                      totalBytes: totalBytes,
                      remainingSlots: remainingSlots,
                      uploadRatio: uploadRatio,
                    ),
                ],
              ),
            ),
            crossFadeState: collapsed
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 180),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }
}

class _BatchMiniImportDetails extends StatelessWidget {
  final int loadedCount;
  final int maxCount;
  final int totalBytes;
  final int remainingSlots;
  final double uploadRatio;

  const _BatchMiniImportDetails({
    required this.loadedCount,
    required this.maxCount,
    required this.totalBytes,
    required this.remainingSlots,
    required this.uploadRatio,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 4,
            value: uploadRatio.clamp(0, 1),
            backgroundColor: cs.surfaceContainerHighest,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            _InlineMetric(
              icon: Icons.insert_drive_file_outlined,
              label: '$loadedCount / $maxCount archivos',
              color: cs.primary,
            ),
            _InlineMetric(
              icon: Icons.data_usage_outlined,
              label: _formatBatchBytes(totalBytes),
              color: cs.onSurfaceVariant,
            ),
            _InlineMetric(
              icon: Icons.space_dashboard_outlined,
              label: '$remainingSlots libres',
              color: cs.onSurfaceVariant,
            ),
          ],
        ),
      ],
    );
  }
}

class _BatchJobProgressCard extends StatelessWidget {
  final String status;
  final int totalFiles;
  final int processedFiles;
  final int importedCount;
  final int skippedCount;
  final int reviewCount;
  final int duplicateCount;
  final double progress;
  final String currentStep;
  final String message;
  final bool loadingResult;
  final List<String> warningDetails;
  final bool warningsExpanded;
  final VoidCallback? onToggleWarnings;
  final VoidCallback? onCopyWarnings;

  const _BatchJobProgressCard({
    required this.status,
    required this.totalFiles,
    required this.processedFiles,
    required this.importedCount,
    required this.skippedCount,
    this.reviewCount = 0,
    this.duplicateCount = 0,
    required this.progress,
    required this.currentStep,
    required this.message,
    required this.loadingResult,
    this.warningDetails = const [],
    this.warningsExpanded = false,
    this.onToggleWarnings,
    this.onCopyWarnings,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final isCompleted = status == 'completed';
    final isFailed = status == 'failed';
    final isQueued = status == 'queued';
    final accent = isCompleted
        ? Colors.green.shade400
        : isFailed
            ? cs.error
            : cs.primary;

    final title = isCompleted
        ? l.expenseBatchProgressCompleted
        : isFailed
            ? l.expenseBatchProgressFailed
            : isQueued
                ? l.expenseBatchProgressQueued
                : l.expenseBatchProgressProcessing;
    final readyCount = importedCount.clamp(0, processedFiles);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: cs.surface.withValues(alpha: 0.18),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                isCompleted
                    ? Icons.check_circle_outline
                    : isFailed
                        ? Icons.error_outline
                        : Icons.timelapse_outlined,
                size: 16,
                color: accent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: ts.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ),
                ),
              ),
              if (currentStep.trim().isNotEmpty)
                Text(
                  currentStep.trim(),
                  style: ts.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 5,
              value: isCompleted ? 1.0 : progress.clamp(0, 1),
              backgroundColor: isCompleted
                  ? Colors.green.withValues(alpha: 0.15)
                  : cs.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                isCompleted ? Colors.green.shade400 : accent,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _BatchStatPill(
                label: totalFiles > 0
                    ? '$processedFiles / $totalFiles procesados'
                    : '$processedFiles procesados',
                icon: Icons.check_circle_outline,
                color: isCompleted ? Colors.green.shade500 : accent,
              ),
              _BatchStatPill(
                label: '$importedCount importados',
                icon: Icons.check_circle_rounded,
                color: Colors.green.shade500,
              ),
              _BatchStatPill(
                label:
                    '$skippedCount incidencia${skippedCount == 1 ? '' : 's'}',
                icon: Icons.warning_amber_rounded,
                color: skippedCount > 0
                    ? Colors.amber.shade600
                    : cs.onSurfaceVariant,
              ),
              if (loadingResult)
                _BatchStatPill(
                  label:
                      '${l.expenseBatchStatResult}: ${l.expenseBatchStatLoading}',
                  icon: Icons.sync,
                  color: cs.primary,
                ),
            ],
          ),
          if (isCompleted || message.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            if (isCompleted)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (readyCount > 0)
                    _BatchStatPill(
                      label: '$readyCount listas',
                      icon: Icons.task_alt_rounded,
                      color: Colors.green.shade600,
                    ),
                  if (reviewCount > 0)
                    _BatchStatPill(
                      label: '$reviewCount en revisi\u00f3n',
                      icon: Icons.rate_review_outlined,
                      color: Colors.amber.shade700,
                    ),
                  if (duplicateCount > 0)
                    _BatchStatPill(
                      label: '$duplicateCount duplicadas',
                      icon: Icons.content_copy_outlined,
                      color: cs.onSurfaceVariant,
                    ),
                ],
              )
            else
              Text(
                message.trim(),
                style: ts.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
          ],
          if (warningDetails.isNotEmpty) ...[
            const SizedBox(height: 6),
            InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: onToggleWarnings,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.32),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 14,
                      color: Colors.amber.shade700,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '$skippedCount incidencia${skippedCount == 1 ? '' : 's'}',
                        style: ts.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.amber.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      warningsExpanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 16,
                      color: cs.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              child: warningsExpanded
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.amber.withValues(alpha: 0.04),
                          border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (onCopyWarnings != null)
                              Align(
                                alignment: Alignment.centerRight,
                                child: IconButton(
                                  onPressed: onCopyWarnings,
                                  tooltip: 'Copiar lista',
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 28,
                                    minHeight: 28,
                                  ),
                                  icon: Icon(
                                    Icons.copy_all_outlined,
                                    size: 15,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            for (var i = 0; i < warningDetails.length; i++) ...[
                              _SkippedFileRow(
                                detail: warningDetails[i],
                                cs: cs,
                                ts: ts,
                              ),
                              if (i != warningDetails.length - 1)
                                Divider(
                                  height: 12,
                                  color:
                                      cs.outlineVariant.withValues(alpha: 0.18),
                                ),
                            ],
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
          if (!isCompleted && !isFailed) ...[
            const SizedBox(height: 8),
            Text(
              l.expenseBatchProgressBackgroundHint,
              style: ts.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BatchStateBanner extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  const _BatchStateBanner({
    required this.icon,
    required this.message,
    required this.color,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final ts = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: backgroundColor,
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: ts.bodySmall?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BatchStatPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _BatchStatPill({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: cs.surfaceContainerHighest.withValues(alpha: 0.16),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: ts.bodySmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
