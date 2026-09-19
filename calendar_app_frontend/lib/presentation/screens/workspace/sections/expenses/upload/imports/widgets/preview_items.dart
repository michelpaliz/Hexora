part of '../../expense_upload_screen.dart';

class _BatchExpensePreviewItemTile extends StatelessWidget {
  final _ExpenseBatchPreviewItem item;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;

  const _BatchExpensePreviewItemTile({
    required this.item,
    required this.onToggle,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;
    final prediction = item.prediction;
    final statusColor = _expensePreviewStatusColor(item, cs);
    final statusIcon = _expensePreviewStatusIcon(item);
    final confidence = _batchJobDouble(item.confidence['overall']);
    final reviewColor = item.needsReview || item.isDuplicate || item.isFailed
        ? statusColor
        : _expensePreviewConfidenceColor(confidence, cs);
    final vendor = _batchJobText(prediction['vendorName']);
    final invoiceNumber = _batchJobText(prediction['invoiceNumber']);
    final issueDate = _batchJobText(prediction['issueDate']);
    final total = _expensePreviewMoney(prediction['total']);
    final currency = _batchJobText(prediction['currency']);
    final duplicateReason = _batchJobFirstText([
      item.duplicate['reason'],
      item.duplicate['existingExpenseId'] == null
          ? null
          : 'Ya existe: ${item.duplicate['existingExpenseId']}',
    ]);
    final issueText = [
      ...item.warnings,
      if (duplicateReason.isNotEmpty) duplicateReason,
      if ((item.error ?? '').trim().isNotEmpty) item.error!.trim(),
    ].join(' \u00b7 ');
    final hasIssue = issueText.trim().isNotEmpty;
    final issueColor =
        item.isFailed || item.isDuplicate ? cs.error : Colors.amber.shade700;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          color: (item.needsReview || item.isDuplicate || item.isFailed)
              ? statusColor.withValues(alpha: 0.035)
              : Colors.transparent,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 34,
              height: 34,
              child: Checkbox(
                value: item.selected,
                onChanged:
                    item.canSelect ? (value) => onToggle(value ?? false) : null,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vendor.isEmpty ? 'Proveedor sin identificar' : vendor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ts.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 3,
                          children: [
                            _PreviewMeta(
                              label: 'Factura',
                              value: invoiceNumber,
                              priority: _PreviewMetaPriority.secondary,
                            ),
                            _PreviewMeta(
                              label: 'Fecha',
                              value: issueDate,
                              priority: _PreviewMetaPriority.secondary,
                            ),
                          ],
                        ),
                      ),
                      if (hasIssue) ...[
                        const SizedBox(width: 8),
                        Tooltip(
                          message: issueText,
                          waitDuration: const Duration(milliseconds: 350),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: issueColor.withValues(alpha: 0.10),
                              border: Border.all(
                                color: issueColor.withValues(alpha: 0.22),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  item.isFailed
                                      ? Icons.error_outline_rounded
                                      : item.isDuplicate
                                          ? Icons.copy_all_rounded
                                          : Icons.warning_amber_rounded,
                                  size: 12,
                                  color: issueColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  item.isDuplicate
                                      ? 'Duplicado'
                                      : item.isFailed
                                          ? 'Fallido'
                                          : 'Revisar',
                                  style: ts.bodySmall?.copyWith(
                                    color: issueColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  [total, currency].where((e) => e.isNotEmpty).join(' '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ts.bodySmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                _ReviewSignalPill(
                  label: _expensePreviewStatusLabel(item),
                  confidence: confidence,
                  color: reviewColor,
                  icon: statusIcon,
                ),
                const SizedBox(height: 4),
                IconButton(
                  onPressed: item.canSelect ? onEdit : null,
                  tooltip: 'Editar predicción',
                  icon: const Icon(Icons.tune_rounded, size: 16),
                  color: cs.primary,
                  disabledColor: cs.onSurfaceVariant.withValues(alpha: 0.35),
                  style: IconButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    minimumSize: const Size(30, 30),
                    fixedSize: const Size(30, 30),
                    padding: EdgeInsets.zero,
                    backgroundColor: cs.primary.withValues(alpha: 0.06),
                    hoverColor: cs.primary.withValues(alpha: 0.12),
                    disabledBackgroundColor:
                        cs.surfaceContainerHighest.withValues(alpha: 0.16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewSignalPill extends StatelessWidget {
  final String label;
  final double confidence;
  final Color color;
  final IconData icon;

  const _ReviewSignalPill({
    required this.label,
    required this.confidence,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final ts = Theme.of(context).textTheme;
    final confidenceLabel = confidence > 0
        ? '${(confidence * 100).clamp(0, 100).toStringAsFixed(0)}%'
        : 'N/A';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            '$label $confidenceLabel',
            style: ts.bodySmall?.copyWith(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

enum _PreviewMetaPriority { secondary, tertiary }

class _PreviewMeta extends StatelessWidget {
  final String label;
  final String value;
  final _PreviewMetaPriority priority;

  const _PreviewMeta({
    required this.label,
    required this.value,
    this.priority = _PreviewMetaPriority.secondary,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;
    final isTertiary = priority == _PreviewMetaPriority.tertiary;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '$label: '),
          TextSpan(
            text: value.isEmpty ? '-' : value,
            style: TextStyle(
              fontWeight: isTertiary ? FontWeight.w500 : FontWeight.w700,
            ),
          ),
        ],
      ),
      style: ts.bodySmall?.copyWith(
        color: cs.onSurfaceVariant.withValues(alpha: isTertiary ? 0.72 : 0.9),
        fontSize: isTertiary ? 10.5 : 11,
      ),
    );
  }
}

class _BatchStatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _BatchStatusChip({
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final ts = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: ts.bodySmall?.copyWith(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
