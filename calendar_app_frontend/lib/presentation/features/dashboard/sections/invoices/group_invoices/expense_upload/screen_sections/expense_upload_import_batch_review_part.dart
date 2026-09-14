part of '../../expense_upload_screen.dart';

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

class _SaveIntent extends Intent {
  const _SaveIntent();
}

class _OcrQualityBadge extends StatelessWidget {
  final String label;
  final double confidence;
  final Color color;
  final IconData icon;

  const _OcrQualityBadge({
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            '$label · OCR $confidenceLabel',
            style: ts.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PredictionEditSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final bool highlighted;
  final bool initiallyExpanded;

  const _PredictionEditSection({
    required this.title,
    required this.icon,
    required this.child,
    this.highlighted = false,
    this.initiallyExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;
    final borderColor = highlighted
        ? cs.primary.withValues(alpha: 0.24)
        : cs.outlineVariant.withValues(alpha: 0.22);
    final background = highlighted
        ? cs.primaryContainer.withValues(alpha: 0.07)
        : cs.surfaceContainerHighest.withValues(alpha: 0.10);

    Widget header() {
      return Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              color: highlighted
                  ? cs.primary.withValues(alpha: 0.12)
                  : cs.surfaceContainerHighest.withValues(alpha: 0.36),
            ),
            child: Icon(
              icon,
              size: 15,
              color: highlighted ? cs.primary : cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: ts.bodySmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: highlighted ? cs.primary : cs.onSurface,
              ),
            ),
          ),
        ],
      );
    }

    if (!initiallyExpanded) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: background,
          border: Border.all(color: borderColor),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: false,
            tilePadding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            title: header(),
            children: [child],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: background,
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header(),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _PredictionSuggestionChip extends StatelessWidget {
  final String label;

  const _PredictionSuggestionChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: cs.primary.withValues(alpha: 0.07),
        border: Border.all(color: cs.primary.withValues(alpha: 0.14)),
      ),
      child: Text(
        label,
        style: ts.bodySmall?.copyWith(
          color: cs.primary,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

enum _BatchExpensePreviewQueue {
  all,
  ready,
  review,
  duplicate,
  failed,
}

class _BatchExpensePreviewReviewPanel extends StatefulWidget {
  final List<_ExpenseBatchPreviewItem> items;
  final int selectedCount;
  final bool confirming;
  final Map<String, dynamic>? confirmResult;
  final bool canExportIncidents;
  final bool exportingIncidents;
  final void Function(_ExpenseBatchPreviewItem item, bool selected) onToggle;
  final ValueChanged<_ExpenseBatchPreviewItem> onEdit;
  final VoidCallback onConfirm;
  final VoidCallback onExportIncidents;

  const _BatchExpensePreviewReviewPanel({
    required this.items,
    required this.selectedCount,
    required this.confirming,
    required this.confirmResult,
    required this.canExportIncidents,
    required this.exportingIncidents,
    required this.onToggle,
    required this.onEdit,
    required this.onConfirm,
    required this.onExportIncidents,
  });

  @override
  State<_BatchExpensePreviewReviewPanel> createState() =>
      _BatchExpensePreviewReviewPanelState();
}

class _BatchExpensePreviewReviewPanelState
    extends State<_BatchExpensePreviewReviewPanel> {
  _BatchExpensePreviewQueue _queue = _BatchExpensePreviewQueue.all;

  List<_ExpenseBatchPreviewItem> _filteredItems() {
    return switch (_queue) {
      _BatchExpensePreviewQueue.ready => widget.items
          .where((item) => item.status == 'ready' && !item.isDuplicate)
          .toList(growable: false),
      _BatchExpensePreviewQueue.review =>
        widget.items.where((item) => item.needsReview).toList(growable: false),
      _BatchExpensePreviewQueue.duplicate =>
        widget.items.where((item) => item.isDuplicate).toList(growable: false),
      _BatchExpensePreviewQueue.failed =>
        widget.items.where((item) => item.isFailed).toList(growable: false),
      _BatchExpensePreviewQueue.all => widget.items,
    };
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;
    final readyCount = widget.items
        .where((item) => item.status == 'ready' && !item.isDuplicate)
        .length;
    final reviewCount = widget.items.where((item) => item.needsReview).length;
    final duplicateCount =
        widget.items.where((item) => item.isDuplicate).length;
    final failedCount = widget.items.where((item) => item.isFailed).length;
    final selectedItems = widget.items.where((item) => item.selected);
    final visibleItems = _filteredItems();
    final selectedTotal = selectedItems.fold<double>(
      0,
      (sum, item) => sum + _expensePreviewNumber(item.prediction['total']),
    );
    final selectedTax = selectedItems.fold<double>(
      0,
      (sum, item) => sum + _expensePreviewNumber(item.prediction['taxTotal']),
    );
    final selectedCurrency = _batchJobFirstText([
      for (final item in selectedItems) item.prediction['currency'],
      for (final item in widget.items) item.prediction['currency'],
    ]);
    final hasFinancialSummary = selectedTotal > 0 || selectedTax > 0;
    final ctaLabel = widget.selectedCount == 1
        ? 'Importar 1 gasto'
        : 'Importar ${widget.selectedCount} gastos';
    final queueOptions = [
      (
        queue: _BatchExpensePreviewQueue.all,
        label: 'Todos',
        count: widget.items.length,
        color: cs.primary,
      ),
      (
        queue: _BatchExpensePreviewQueue.ready,
        label: 'Listos',
        count: readyCount,
        color: Colors.green.shade600,
      ),
      (
        queue: _BatchExpensePreviewQueue.review,
        label: 'Revisi\u00f3n',
        count: reviewCount,
        color: Colors.amber.shade700,
      ),
      (
        queue: _BatchExpensePreviewQueue.duplicate,
        label: 'Duplicados',
        count: duplicateCount,
        color: cs.error,
      ),
      (
        queue: _BatchExpensePreviewQueue.failed,
        label: 'Fallidos',
        count: failedCount,
        color: cs.error,
      ),
    ];
    final activeQueue = queueOptions.firstWhere(
      (option) => option.queue == _queue,
      orElse: () => queueOptions.first,
    );

    Widget queueMenu() {
      return PopupMenuButton<_BatchExpensePreviewQueue>(
        tooltip: 'Filtrar previsualizaci\u00f3n',
        initialValue: _queue,
        onSelected: (value) => setState(() => _queue = value),
        itemBuilder: (context) => [
          for (final option in queueOptions)
            PopupMenuItem(
              value: option.queue,
              child: Row(
                children: [
                  Icon(
                    option.queue == _queue
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    size: 16,
                    color: option.queue == _queue
                        ? option.color
                        : cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(option.label)),
                  const SizedBox(width: 12),
                  Text(
                    option.count.toString(),
                    style: ts.bodySmall?.copyWith(
                      color: option.color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: activeQueue.color.withValues(alpha: 0.10),
            border: Border.all(
              color: activeQueue.color.withValues(alpha: 0.26),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.filter_list_rounded,
                size: 14,
                color: activeQueue.color,
              ),
              const SizedBox(width: 5),
              Text(
                '${activeQueue.label} ${activeQueue.count}',
                style: ts.bodySmall?.copyWith(
                  color: activeQueue.color,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.expand_more_rounded,
                size: 14,
                color: activeQueue.color,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: cs.surface.withValues(alpha: 0.18),
        border: Border.all(color: cs.primary.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                Icon(Icons.fact_check_outlined, size: 16, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Previsualizaci\u00f3n de gastos',
                        style: ts.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Revisa las predicciones antes de crear gastos. Nada se importa autom\u00e1ticamente.',
                        style: ts.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                queueMenu(),
                const SizedBox(width: 8),
                _BatchStatusChip(
                  label: '${widget.selectedCount} seleccionados',
                  color: cs.primary,
                  icon: Icons.checklist_rounded,
                ),
              ],
            ),
          ),
          if (hasFinancialSummary)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Text(
                '${widget.selectedCount} gastos seleccionados \u00b7 ${_expensePreviewCurrency(selectedTotal, selectedCurrency)} total \u00b7 ${_expensePreviewCurrency(selectedTax, selectedCurrency)} IVA',
                style: ts.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.22)),
          Flexible(
            fit: FlexFit.loose,
            child: visibleItems.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 22),
                    child: Center(
                      child: Text(
                        'No hay gastos en esta cola.',
                        style: ts.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: visibleItems.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      indent: 12,
                      endIndent: 12,
                      color: cs.outlineVariant.withValues(alpha: 0.13),
                    ),
                    itemBuilder: (context, index) {
                      final item = visibleItems[index];
                      return _BatchExpensePreviewItemTile(
                        item: item,
                        onToggle: (selected) => widget.onToggle(item, selected),
                        onEdit: () => widget.onEdit(item),
                      );
                    },
                  ),
          ),
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.22)),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Row(
              children: [
                if (widget.confirmResult != null)
                  Expanded(
                    child: Text(
                      'Importados: ${_batchJobInt(widget.confirmResult?['importedCount'])} \u00b7 Omitidos: ${_batchJobInt(widget.confirmResult?['skippedCount'])}',
                      style: ts.bodySmall?.copyWith(
                        color: Colors.green.shade600,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: Text(
                      'Duplicados y fallidos permanecen omitidos por defecto.',
                      style: ts.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ),
                if (widget.canExportIncidents) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: widget.exportingIncidents
                        ? null
                        : widget.onExportIncidents,
                    icon: widget.exportingIncidents
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.file_download_outlined, size: 17),
                    label: Text(
                      widget.exportingIncidents
                          ? 'Generando Excel...'
                          : 'Exportar incidencias',
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: widget.confirming || widget.selectedCount == 0
                      ? null
                      : widget.onConfirm,
                  icon: widget.confirming
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_done_outlined, size: 17),
                  label: Text(ctaLabel),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
