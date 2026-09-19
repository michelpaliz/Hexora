part of '../../expense_upload_screen.dart';

extension _ExpensePredictionEditDialog on _ExpenseUploadImportTabsSection {
  Future<void> _showBatchPreviewEditDialog(
    _ExpenseBatchPreviewItem item,
  ) async {
    final prediction = item.prediction;
    final controllers = <String, TextEditingController>{
      for (final key in [
        'vendorName',
        'vendorTaxId',
        'invoiceNumber',
        'issueDate',
        'dueDate',
        'subtotal',
        'taxTotal',
        'total',
        'currency',
        'category',
        'description',
        'notes',
      ])
        key: TextEditingController(text: _batchJobText(prediction[key])),
    };

    await showSafeDialogOnActiveView<void>(
      context: context,
      builder: (dialogContext) {
        final cs = Theme.of(dialogContext).colorScheme;
        final ts = Theme.of(dialogContext).textTheme;
        final confidence = _batchJobDouble(item.confidence['overall']);
        final confidenceColor = _expensePreviewConfidenceColor(confidence, cs);
        final statusColor = _expensePreviewStatusColor(item, cs);
        final qualityColor =
            item.needsReview || item.isDuplicate || item.isFailed
                ? statusColor
                : confidenceColor;
        final statusLabel = _expensePreviewStatusLabel(item);
        void saveChanges() {
          final next = Map<String, dynamic>.from(item.prediction);
          for (final entry in controllers.entries) {
            final raw = entry.value.text.trim();
            if (raw.isEmpty) {
              next[entry.key] = null;
              continue;
            }
            if (const {'subtotal', 'taxTotal', 'total'}.contains(entry.key)) {
              next[entry.key] = num.tryParse(raw.replaceAll(',', '.')) ?? raw;
            } else {
              next[entry.key] = raw;
            }
          }
          _updateImportState(() {
            item.prediction = next;
            item.reviewed = true;
            if (item.canSelect && item.needsReview) {
              item.selected = true;
            }
          });
          Navigator.of(dialogContext).pop();
        }

        Widget field(
          String key,
          String label, {
          TextInputType? keyboardType,
          int maxLines = 1,
          bool primary = false,
          String? helper,
        }) {
          return TextField(
            controller: controllers[key],
            keyboardType: keyboardType,
            maxLines: maxLines,
            textInputAction:
                maxLines == 1 ? TextInputAction.next : TextInputAction.newline,
            onSubmitted: (_) {
              if (key == 'currency') saveChanges();
            },
            style: ts.bodyMedium?.copyWith(
              fontWeight: primary ? FontWeight.w800 : FontWeight.w600,
              color: cs.onSurface,
            ),
            decoration: InputDecoration(
              labelText: label,
              helperText: helper,
              floatingLabelBehavior: FloatingLabelBehavior.always,
              isDense: true,
              filled: true,
              fillColor: primary
                  ? cs.primaryContainer.withValues(alpha: 0.10)
                  : cs.surfaceContainerHighest.withValues(alpha: 0.18),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.24),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: primary
                      ? cs.primary.withValues(alpha: 0.28)
                      : cs.outlineVariant.withValues(alpha: 0.22),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cs.primary, width: 1.4),
              ),
            ),
          );
        }

        return AlertDialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          contentPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          content: Shortcuts(
            shortcuts: const {
              SingleActivator(LogicalKeyboardKey.enter, control: true):
                  _SaveIntent(),
            },
            child: Actions(
              actions: {
                _SaveIntent: CallbackAction<_SaveIntent>(
                  onInvoke: (_) {
                    saveChanges();
                    return null;
                  },
                ),
              },
              child: SizedBox(
                width: 820,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 22, 24, 14),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(13),
                              color: cs.primary.withValues(alpha: 0.1),
                              border: Border.all(
                                color: cs.primary.withValues(alpha: 0.18),
                              ),
                            ),
                            child: Icon(
                              Icons.document_scanner_outlined,
                              color: cs.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Editar predicci\u00f3n',
                                  style: ts.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Tooltip(
                                  message: item.fileName,
                                  child: Text(
                                    'Documento OCR adjunto',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: ts.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _OcrQualityBadge(
                            label: statusLabel,
                            confidence: confidence,
                            color: qualityColor,
                            icon: _expensePreviewStatusIcon(item),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: cs.outlineVariant.withValues(alpha: 0.22),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _PredictionEditSection(
                              title: 'Proveedor',
                              icon: Icons.storefront_outlined,
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: field(
                                      'vendorName',
                                      'Proveedor',
                                      primary: true,
                                      helper: 'Extra\u00eddo por OCR',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 2,
                                    child: field(
                                      'vendorTaxId',
                                      'NIF/CIF',
                                      helper: 'Validaci\u00f3n fiscal',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _PredictionEditSection(
                              title: 'Factura',
                              icon: Icons.receipt_long_outlined,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: field(
                                      'invoiceNumber',
                                      'N\u00famero factura',
                                      primary: true,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: field(
                                        'issueDate', 'Fecha emisi\u00f3n'),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child:
                                        field('dueDate', 'Fecha vencimiento'),
                                  ),
                                ],
                              ),
                            ),
                            _PredictionEditSection(
                              title: 'Importes',
                              icon: Icons.account_balance_wallet_outlined,
                              highlighted: true,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: field(
                                      'subtotal',
                                      'Base',
                                      keyboardType: TextInputType.number,
                                      primary: true,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: field(
                                      'taxTotal',
                                      'IVA',
                                      keyboardType: TextInputType.number,
                                      primary: true,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: field(
                                      'total',
                                      'Total',
                                      keyboardType: TextInputType.number,
                                      primary: true,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  SizedBox(
                                    width: 120,
                                    child: field('currency', 'Moneda'),
                                  ),
                                ],
                              ),
                            ),
                            _PredictionEditSection(
                              title: 'Clasificaci\u00f3n',
                              icon: Icons.auto_awesome_motion_outlined,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  field(
                                    'category',
                                    'Categor\u00eda',
                                    helper:
                                        'Preparado para sugerencias IA y recientes',
                                  ),
                                  const SizedBox(height: 8),
                                  const Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      _PredictionSuggestionChip(
                                          label: 'Mantenimiento'),
                                      _PredictionSuggestionChip(
                                          label: 'Suministros'),
                                      _PredictionSuggestionChip(
                                          label: 'Servicios'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            _PredictionEditSection(
                              title: 'Contenido OCR',
                              icon: Icons.notes_outlined,
                              initiallyExpanded: false,
                              child: Column(
                                children: [
                                  field(
                                    'description',
                                    'Descripci\u00f3n',
                                    maxLines: 2,
                                  ),
                                  const SizedBox(height: 10),
                                  field('notes', 'Notas', maxLines: 2),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: cs.outlineVariant.withValues(alpha: 0.22),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Ctrl + Enter para guardar. Esc para cerrar.',
                              style: ts.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: const Text('Cancelar'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: saveChanges,
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: const Text('Guardar cambios'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    for (final controller in controllers.values) {
      controller.dispose();
    }
  }
}
