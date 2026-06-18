part of '../../expense_upload_screen.dart';

// ignore_for_file: dead_code

class _ExpenseImportTypeScale {
  static const sectionLabel = 10.5;
  static const fieldLabel = 12.0;
  static const fieldValue = 13.0;
  static const helper = 12.0;
  static const code = 12.0;
}

mixin _ExpenseUploadImportTabsSection on _ExpenseUploadScreenStateBase {
  @override
  BuildContext get context;
  String? get batchVerifyMessage;
  bool get jsonSubmitting;
  bool get jsonPromptLoading;
  String? get jsonPromptMessage;
  String? get jsonPromptText;
  String? get jsonFileName;
  String? get jsonInvoiceFileName;
  String? get selectedFileName;
  TextEditingController get jsonPayloadController;
  bool get jsonAdvancedExpanded;
  set jsonAdvancedExpanded(bool value);
  TextEditingController get jsonProviderIdOverrideController;
  TextEditingController get jsonGroupIdOverrideController;
  TextEditingController get jsonStatementEntryController;
  TextEditingController get jsonClientController;
  String? get jsonError;
  bool get batchSubmitting;
  bool get batchGeneratingJson;
  TextEditingController get batchJsonController;
  int get batchDetectedInvoices;
  set batchDetectedInvoices(int value);
  List<Uint8List> get batchDocumentBytes;
  List<String> get batchDocumentNames;
  String? get batchError;
  @override
  List<String> get batchSkippedDetails;
  @override
  Future<void> pickJsonPayloadFile();
  @override
  Future<void> pickJsonInvoiceFile();
  @override
  Future<void> fetchExpenseJsonPrompt();
  @override
  Future<void> copyPromptToClipboard();
  @override
  Future<void> submitExpenseJsonImport();
  Future<void> pickBatchJsonFile();
  @override
  Future<void> pickBatchDocuments();
  @override
  Future<void> submitBatchImport();
  Future<void> confirmBatchPreviewImport();
  Future<void> exportBatchIncidentExcel();
  Future<void> generateBatchJsonWithAi();
  List<Map<String, dynamic>> extractBatchInvoices(Map<String, dynamic> payload);
  @override
  String resolveGroupId();

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
        final qualityColor = item.needsReview || item.isDuplicate || item.isFailed
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
          setState(() {
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
                                    child: field('issueDate', 'Fecha emisi\u00f3n'),
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
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(),
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

  Widget _buildBatchFileListView({
    required List<_BatchExecutionFile> filteredFiles,
    required int totalCount,
    required int warningCount,
    required Set<int> warningIndexes,
    required int selectedCount,
    required bool hasTrackedJob,
    required bool jobActive,
  }) {
    return _BatchFileListView(
      items: filteredFiles,
      totalCount: totalCount,
      warningCount: warningCount,
      filterIndex: _batchFileFilterIndex,
      hasAnyFiles: selectedCount > 0 || hasTrackedJob,
      onFilterChanged: (value) => setState(() {
        _batchFileFilterIndex = value;
      }),
      onRemoveWarnings: jobActive || warningIndexes.isEmpty
          ? null
          : () => setState(() {
                _resetBatchJobTracking(
                  clearResult: true,
                  clearCache: true,
                );
                final ordered = warningIndexes.toList()
                  ..sort((a, b) => b.compareTo(a));
                for (final index in ordered) {
                  if (index >= 0 && index < batchDocumentNames.length) {
                    batchDocumentNames.removeAt(index);
                  }
                  if (index >= 0 && index < batchDocumentBytes.length) {
                    batchDocumentBytes.removeAt(index);
                  }
                }
                batchSkippedDetails.clear();
                batchDetectedInvoices = 0;
                _batchVerifyMessage = null;
                _batchError = null;
              }),
      onRemoveFile: jobActive
          ? null
          : (originalIndex) => setState(() {
                _resetBatchJobTracking(
                  clearResult: true,
                  clearCache: true,
                );
                if (originalIndex >= 0 &&
                    originalIndex < batchDocumentNames.length) {
                  batchDocumentNames.removeAt(originalIndex);
                }
                if (originalIndex >= 0 &&
                    originalIndex < batchDocumentBytes.length) {
                  batchDocumentBytes.removeAt(originalIndex);
                }
                batchSkippedDetails.clear();
                batchDetectedInvoices = 0;
                _batchVerifyMessage = null;
                _batchError = null;
              }),
      onDropWebDocuments: jobActive ? null : applyBatchDocumentData,
    );
  }

  @override
  Widget _buildJsonImportTab(AppLocalizations l,
      {bool showInlineControls = true}) {
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final jsonAdvanceOptions = _buildAdvanceOptions(
      providerId: _jsonProviderIdOverrideController.text.trim(),
      vendorName: _jsonProviderIdOverrideController.text.trim().isNotEmpty
          ? ''
          : _vendorController.text.trim(),
    );
    final jsonSettlementFields = ExpenseSettlementFields(
      settlement: _jsonSettlement,
      advanceOptions: jsonAdvanceOptions,
      enabled: !jsonSubmitting,
      onTypeChanged: (type) => setState(() {
        _jsonSettlement.setExpenseType(type);
      }),
      onAdvanceExpenseChanged: (id) => setState(() {
        _jsonSettlement.selectedAdvanceExpenseId = id;
      }),
      onChanged: () => setState(() {}),
    );
    final jsonDiscountPreview = _jsonDiscountPreview();
    final jsonDiscountFields = ExpenseDocumentDiscountFields(
      discount: _jsonDocumentDiscount,
      enabled: !jsonSubmitting,
      preview: jsonDiscountPreview,
      compactSummary: true,
      onChanged: () => setState(() {}),
    );
    final jsonSummaryValidationError = _jsonUseSummaryTotals
        ? ExpenseFormHelpers.validateSummaryTotals(
            base: _parseControllerAmount(_jsonBaseController),
            tax: _parseControllerAmount(_jsonTaxController),
            total: _parseControllerAmount(_jsonTotalController),
          )
        : null;
    final jsonTotalsFields = ExpenseDocumentTotalsFields(
      baseController: _jsonBaseController,
      taxController: _jsonTaxController,
      totalController: _jsonTotalController,
      enabled: !jsonSubmitting,
      useSummaryTotals: _jsonUseSummaryTotals,
      lockToLines: false,
      validationError: jsonSummaryValidationError,
      onSummaryModeChanged: (value) => setState(() {
        _jsonUseSummaryTotals = value;
        if (_jsonUseSummaryTotals) {
          _syncJsonSummaryControllers(_ExpenseDocumentTotalField.total);
        }
      }),
      onBaseChanged: (_) {
        _syncJsonSummaryControllers(_ExpenseDocumentTotalField.base);
        setState(() {});
      },
      onTaxChanged: (_) {
        _syncJsonSummaryControllers(_ExpenseDocumentTotalField.tax);
        setState(() {});
      },
      onTotalChanged: (_) {
        _syncJsonSummaryControllers(_ExpenseDocumentTotalField.total);
        setState(() {});
      },
    );

    Widget sectionLabel(
      String text,
      IconData icon, {
      required String help,
    }) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Icon(
                icon,
                size: 12,
                color: cs.onSurfaceVariant.withValues(alpha: 0.55),
              ),
              const SizedBox(width: 5),
              Text(
                text.toUpperCase(),
                style: ts.bodySmall?.copyWith(
                  fontSize: _ExpenseImportTypeScale.sectionLabel,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.55),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(width: 6),
              _ExpenseImportInfoButton(message: help),
            ],
          ),
        );

    final hasPrompt = (jsonPromptText ?? '').trim().isNotEmpty;
    final hasFiles = (jsonFileName ?? '').isNotEmpty ||
        (jsonInvoiceFileName ?? '').isNotEmpty ||
        (selectedFileName ?? '').isNotEmpty;
    final payloadLength = jsonPayloadController.text.trim().length;
    final hasPayload = payloadLength > 0;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: showInlineControls ? 4 : 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ Compact mode: quick action buttons ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬
          if (showInlineControls) ...[
            Text(
              l.expenseJsonTabFlowHint,
              style: ts.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _CompactOutlinedButton(
                  onPressed: jsonSubmitting ? null : pickJsonPayloadFile,
                  icon: Icons.upload_file_outlined,
                  label: l.expenseJsonTabPickJsonFile,
                ),
                _CompactOutlinedButton(
                  onPressed: jsonSubmitting ? null : pickJsonInvoiceFile,
                  icon: Icons.picture_as_pdf_outlined,
                  label: l.expenseJsonTabPickInvoiceFile,
                ),
                _CompactOutlinedButton(
                  onPressed: jsonPromptLoading ? null : fetchExpenseJsonPrompt,
                  icon: Icons.auto_awesome_outlined,
                  label: l.expenseJsonTabGetAiPrompt,
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],

          // ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ Prompt card ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬
          if (jsonPromptLoading) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: cs.surfaceContainerHighest.withValues(alpha: 0.18),
                border:
                    Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l.expenseJsonTabGeneratingPrompt,
                    style: ts.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          if ((jsonPromptMessage ?? '').trim().isNotEmpty &&
              !jsonPromptLoading) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: cs.primaryContainer.withValues(alpha: 0.18),
                border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
              ),
              child: Text(
                jsonPromptMessage!,
                style: ts.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (hasPrompt) ...[
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.35)),
                color: cs.surfaceContainerHighest.withValues(alpha: 0.1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header row
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(10)),
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.22),
                      border: Border(
                        bottom: BorderSide(
                            color: cs.outlineVariant.withValues(alpha: 0.25)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.auto_awesome_outlined,
                            size: 13, color: cs.primary),
                        const SizedBox(width: 6),
                        Text(
                          l.expenseJsonTabPromptLabel,
                          style: ts.bodySmall?.copyWith(
                            fontSize: _ExpenseImportTypeScale.code,
                            fontWeight: FontWeight.w800,
                            color: cs.primary,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: copyPromptToClipboard,
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.copy_rounded,
                                    size: 12, color: cs.primary),
                                const SizedBox(width: 4),
                                Text(
                                  l.expenseJsonTabCopyPrompt,
                                  style: ts.bodySmall?.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: cs.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Prompt body
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 130),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(10),
                      child: SelectableText(
                        jsonPromptText!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ File badges ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬
          if (hasFiles) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if ((jsonFileName ?? '').isNotEmpty)
                  _JsonFileBadge(
                    icon: Icons.data_object_rounded,
                    label: jsonFileName!,
                    color: cs.tertiary,
                    cs: cs,
                  ),
                if ((jsonInvoiceFileName ?? '').isNotEmpty)
                  _JsonFileBadge(
                    icon: Icons.picture_as_pdf_outlined,
                    label: jsonInvoiceFileName!,
                    color: cs.error,
                    cs: cs,
                  )
                else if ((selectedFileName ?? '').isNotEmpty)
                  _JsonFileBadge(
                    icon: Icons.attach_file_rounded,
                    label: selectedFileName!,
                    color: cs.onSurfaceVariant,
                    cs: cs,
                  ),
              ],
            ),
            const SizedBox(height: 10),
          ],

          // ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ JSON payload editor ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬
          sectionLabel(
            l.expenseJsonTabPayloadLabel,
            Icons.data_object_rounded,
            help: _expenseImportHelpText(context, 'jsonPayload'),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasPayload
                    ? cs.primary.withValues(alpha: 0.35)
                    : cs.outlineVariant.withValues(alpha: 0.35),
              ),
              color: cs.surfaceContainerHighest.withValues(alpha: 0.08),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Editor header
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(10)),
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.2),
                    border: Border(
                      bottom: BorderSide(
                        color: cs.outlineVariant.withValues(alpha: 0.22),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color:
                              cs.surfaceContainerHighest.withValues(alpha: 0.4),
                        ),
                        child: const Text(
                          'json',
                          style: TextStyle(
                            fontSize: _ExpenseImportTypeScale.helper,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (hasPayload)
                        Text(
                          '$payloadLength chars',
                          style: ts.bodySmall?.copyWith(
                            fontSize: 10,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                          ),
                        ),
                      const Spacer(),
                      if (hasPayload)
                        InkWell(
                          onTap: jsonSubmitting
                              ? null
                              : () {
                                  jsonPayloadController.clear();
                                  _tryLoadJsonSummaryControllersFromPayload('');
                                  setState(() {});
                                },
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Text field body (no outer border ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â container provides it)
                TextField(
                  controller: jsonPayloadController,
                  enabled: !jsonSubmitting,
                  minLines: 6,
                  maxLines: 12,
                  style: TextStyle(
                    fontSize: _ExpenseImportTypeScale.code,
                    fontFamily: 'monospace',
                    height: 1.55,
                    color: cs.onSurface,
                  ),
                  onChanged: (value) {
                    _tryLoadJsonSummaryControllersFromPayload(value);
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    hintText: l.expenseJsonTabPayloadHint,
                    hintStyle: TextStyle(
                      fontSize: _ExpenseImportTypeScale.code,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ Advanced options ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬
          GestureDetector(
            onTap: () =>
                setState(() => jsonAdvancedExpanded = !jsonAdvancedExpanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: cs.surfaceContainerHighest.withValues(alpha: 0.14),
                border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.28)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 13,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l.expenseJsonTabAdvancedOptions,
                    style: ts.bodySmall?.copyWith(
                      fontSize: _ExpenseImportTypeScale.sectionLabel,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(width: 6),
                  _ExpenseImportInfoButton(
                    message: _expenseImportHelpText(context, 'advanced'),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: jsonAdvancedExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: jsonAdvancedExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.1),
                  border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.22)),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _AdvancedField(
                      width: 220,
                      controller: jsonProviderIdOverrideController,
                      enabled: !jsonSubmitting,
                      label: 'providerId override',
                    ),
                    _AdvancedField(
                      width: 190,
                      controller: jsonGroupIdOverrideController,
                      enabled: !jsonSubmitting,
                      label: 'groupId override',
                    ),
                    _AdvancedField(
                      width: 190,
                      controller: jsonStatementEntryController,
                      enabled: !jsonSubmitting,
                      label: 'statementEntryId',
                    ),
                    _AdvancedField(
                      width: 190,
                      controller: jsonClientController,
                      enabled: !jsonSubmitting,
                      label: 'clientId',
                    ),
                  ],
                ),
              ),
            ),
            secondChild: const SizedBox.shrink(),
          ),
          const SizedBox(height: 14),

          // ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ Importes ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬
          sectionLabel(
            l.expenseJsonTabSectionExpenseType,
            Icons.receipt_long_outlined,
            help: _expenseImportHelpText(context, 'expenseType'),
          ),
          jsonSettlementFields,
          const SizedBox(height: 14),
          sectionLabel(
            l.expenseJsonTabSectionDiscount,
            Icons.discount_outlined,
            help: _expenseImportHelpText(context, 'discount'),
          ),
          jsonDiscountFields,
          const SizedBox(height: 14),
          sectionLabel(
            l.expenseJsonTabSectionTotal,
            Icons.calculate_outlined,
            help: _expenseImportHelpText(context, 'totals'),
          ),
          jsonTotalsFields,

          // ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ Error ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬
          if ((jsonError ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: cs.errorContainer.withValues(alpha: 0.2),
                border: Border.all(color: cs.error.withValues(alpha: 0.35)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline_rounded, size: 14, color: cs.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      jsonError!,
                      style: ts.bodySmall?.copyWith(color: cs.onErrorContainer),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ Compact submit ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬
          if (showInlineControls) ...[
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: (jsonSubmitting ||
                      resolveGroupId().trim().isEmpty ||
                      (_jsonSettlement.isFinal &&
                          (_jsonSettlement.selectedAdvanceExpenseId ?? '')
                              .trim()
                              .isEmpty))
                  ? null
                  : submitExpenseJsonImport,
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                textStyle: const TextStyle(fontSize: 13),
              ),
              icon: jsonSubmitting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.playlist_add_check_circle_outlined,
                      size: 18),
              label: const Text('Importar JSON'),
            ),
            const SizedBox(height: 4),
            Text(
              'Requiere JSON y archivo de factura adjunto.',
              style: ts.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontSize: _ExpenseImportTypeScale.helper,
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ Guided step right panel (wide layout only) ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬

  @override
  Widget _buildJsonStepRightContent(AppLocalizations l) {
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final step = _jsonImportStep;

    Widget stepHeader({
      required IconData icon,
      required String title,
      required String subtitle,
    }) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 19, color: cs.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: ts.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: ts.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

    Widget continueBtn({VoidCallback? onPressed}) => Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.arrow_forward_rounded, size: 17),
              label: Text(isEs ? 'Continuar' : 'Continue'),
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
            ),
          ),
        );

    // ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ Step 0: Documento ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬
    if (step == 0) {
      final hasPayload = _jsonPayloadController.text.trim().isNotEmpty;
      final payloadLength = _jsonPayloadController.text.trim().length;
      final hasFiles = (_jsonFileName ?? '').isNotEmpty ||
          (_jsonInvoiceFileName ?? '').isNotEmpty ||
          (_fileName ?? '').isNotEmpty;
      final hasPrompt = (_jsonPromptText ?? '').trim().isNotEmpty;

      return SingleChildScrollView(
        padding: const EdgeInsets.only(right: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            stepHeader(
              icon: Icons.upload_file_outlined,
              title: isEs ? 'Subir archivos' : 'Upload files',
              subtitle: isEs
                  ? 'Adjunta la factura, selecciona el JSON o genera el prompt de IA'
                  : 'Attach the invoice, select the JSON, or generate the AI prompt',
            ),
            _StepDropZone(
              enabled: !jsonSubmitting,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: jsonSubmitting ? null : pickJsonPayloadFile,
                    icon: const Icon(Icons.data_object_rounded, size: 16),
                    label: Text(
                      isEs ? 'Seleccionar JSON' : 'Select JSON',
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: jsonSubmitting ? null : pickJsonInvoiceFile,
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                    label: Text(
                      isEs ? 'Adjuntar factura' : 'Attach invoice',
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: cs.surfaceContainerHighest.withValues(alpha: 0.14),
                border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.22)),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome_outlined,
                      size: 15, color: cs.primary.withValues(alpha: 0.8)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hasPrompt
                          ? (isEs
                              ? 'Prompt generado ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â· CÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â³pialo a tu asistente de IA'
                              : 'Prompt ready ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â· Copy it to your AI assistant')
                          : (isEs
                              ? 'Genera el prompt para tu asistente de IA'
                              : 'Generate the prompt for your AI assistant'),
                      style: ts.bodySmall?.copyWith(
                        color: hasPrompt ? cs.primary : cs.onSurfaceVariant,
                        fontWeight: hasPrompt ? FontWeight.w600 : null,
                      ),
                    ),
                  ),
                  if (jsonPromptLoading)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 1.5),
                    )
                  else ...[
                    _CompactIconActionButton(
                      icon: Icons.auto_awesome_outlined,
                      tooltip: isEs ? 'Generar prompt' : 'Generate prompt',
                      onPressed: jsonSubmitting ? null : fetchExpenseJsonPrompt,
                    ),
                    if (hasPrompt) ...[
                      const SizedBox(width: 4),
                      _CompactIconActionButton(
                        icon: Icons.copy_outlined,
                        tooltip: isEs ? 'Copiar prompt' : 'Copy prompt',
                        onPressed:
                            jsonSubmitting ? null : copyPromptToClipboard,
                      ),
                    ],
                  ],
                ],
              ),
            ),
            if (hasPrompt) ...[
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.3)),
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.08),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 110),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(10),
                    child: SelectableText(
                      jsonPromptText!,
                      style: const TextStyle(
                          fontSize: 11, fontFamily: 'monospace', height: 1.5),
                    ),
                  ),
                ),
              ),
            ],
            if (hasFiles) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if ((_jsonFileName ?? '').isNotEmpty)
                    _JsonFileBadge(
                      icon: Icons.data_object_rounded,
                      label: _jsonFileName!,
                      color: cs.tertiary,
                      cs: cs,
                    ),
                  if ((_jsonInvoiceFileName ?? '').isNotEmpty)
                    _JsonFileBadge(
                      icon: Icons.picture_as_pdf_outlined,
                      label: _jsonInvoiceFileName!,
                      color: cs.error,
                      cs: cs,
                    )
                  else if ((_fileName ?? '').isNotEmpty)
                    _JsonFileBadge(
                      icon: Icons.attach_file_rounded,
                      label: _fileName!,
                      color: cs.onSurfaceVariant,
                      cs: cs,
                    ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.data_object_rounded,
                    size: 12,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.55)),
                const SizedBox(width: 5),
                Text(
                  (isEs ? 'DATOS JSON' : 'JSON DATA'),
                  style: ts.bodySmall?.copyWith(
                    fontSize: _ExpenseImportTypeScale.sectionLabel,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.55),
                    letterSpacing: 0.8,
                  ),
                ),
                if (hasPayload) ...[
                  const SizedBox(width: 6),
                  Text(
                    '$payloadLength chars',
                    style: ts.bodySmall?.copyWith(
                      fontSize: 10,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.45),
                    ),
                  ),
                ],
                const Spacer(),
                if (hasPayload)
                  InkWell(
                    onTap: jsonSubmitting
                        ? null
                        : () {
                            jsonPayloadController.clear();
                            _tryLoadJsonSummaryControllersFromPayload('');
                            setState(() {});
                          },
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.close_rounded,
                          size: 14,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: hasPayload
                      ? cs.primary.withValues(alpha: 0.35)
                      : cs.outlineVariant.withValues(alpha: 0.35),
                ),
                color: cs.surfaceContainerHighest.withValues(alpha: 0.08),
              ),
              child: TextField(
                controller: jsonPayloadController,
                enabled: !jsonSubmitting,
                minLines: 8,
                maxLines: 14,
                style: TextStyle(
                  fontSize: _ExpenseImportTypeScale.code,
                  fontFamily: 'monospace',
                  height: 1.55,
                  color: cs.onSurface,
                ),
                onChanged: (value) {
                  _tryLoadJsonSummaryControllersFromPayload(value);
                  setState(() {});
                },
                decoration: InputDecoration(
                  hintText: l.expenseJsonTabPayloadHint,
                  hintStyle: TextStyle(
                    fontSize: _ExpenseImportTypeScale.code,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
            continueBtn(
              onPressed:
                  hasPayload ? () => setState(() => _jsonImportStep = 1) : null,
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    }

    // ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ Step 1: ExtracciÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â³n ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬
    if (step == 1) {
      Map<String, dynamic>? payload;
      try {
        final raw = _jsonPayloadController.text.trim();
        if (raw.isNotEmpty) {
          final decoded = jsonDecode(raw);
          if (decoded is Map) {
            final p = Map<String, dynamic>.from(decoded);
            payload = p['expense'] is Map
                ? Map<String, dynamic>.from(p['expense'] as Map)
                : p;
          }
        }
      } catch (_) {}

      String? extractStr(dynamic v) =>
          v is String && v.trim().isNotEmpty ? v.trim() : null;

      final vendorName = extractStr(payload?['vendor']) ??
          extractStr(payload?['vendorName']) ??
          extractStr(payload?['providerName']);
      final invoiceNumber = extractStr(payload?['invoice']) ??
          extractStr(payload?['invoiceNumber']) ??
          extractStr(payload?['invoiceId']);
      final dateStr = extractStr(payload?['date']) ??
          extractStr(payload?['issuedAt']) ??
          extractStr(payload?['issueDate']);
      final totalStr = _jsonTotalController.text.trim();
      final taxStr = _jsonTaxController.text.trim();
      final baseStr = _jsonBaseController.text.trim();

      Widget extractedRow(String label, String? value, IconData icon) {
        if ((value ?? '').trim().isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(icon,
                  size: 13, color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
              const SizedBox(width: 8),
              SizedBox(
                width: 90,
                child: Text(
                  label,
                  style: ts.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value!,
                  style: ts.bodySmall?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }

      final hasAnyData = vendorName != null ||
          invoiceNumber != null ||
          dateStr != null ||
          totalStr.isNotEmpty;

      return SingleChildScrollView(
        padding: const EdgeInsets.only(right: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            stepHeader(
              icon: Icons.search_rounded,
              title: isEs ? 'Datos detectados' : 'Extracted data',
              subtitle: isEs
                  ? 'Verifica y ajusta los datos identificados en el JSON'
                  : 'Review and adjust the data identified in the JSON',
            ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: cs.surfaceContainerHighest.withValues(alpha: 0.12),
                border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.receipt_long_outlined,
                          size: 14, color: cs.primary),
                      const SizedBox(width: 6),
                      Text(
                        isEs ? 'Resumen del documento' : 'Document summary',
                        style: ts.bodySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: cs.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  extractedRow(isEs ? 'Proveedor' : 'Vendor', vendorName,
                      Icons.business_outlined),
                  extractedRow(
                      isEs ? 'NÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Âº factura' : 'Invoice #',
                      invoiceNumber,
                      Icons.tag_rounded),
                  extractedRow(isEs ? 'Fecha' : 'Date', dateStr,
                      Icons.calendar_today_outlined),
                  extractedRow(
                      isEs ? 'Total' : 'Total',
                      totalStr.isNotEmpty ? totalStr : null,
                      Icons.euro_rounded),
                  extractedRow(
                      isEs ? 'Base imp.' : 'Net amount',
                      baseStr.isNotEmpty ? baseStr : null,
                      Icons.calculate_outlined),
                  extractedRow(isEs ? 'IVA' : 'Tax',
                      taxStr.isNotEmpty ? taxStr : null, Icons.percent_rounded),
                  if (!hasAnyData)
                    Text(
                      isEs
                          ? 'No se detectaron datos en el JSON'
                          : 'No data detected in the JSON',
                      style: ts.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.tune_rounded,
                    size: 12,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.55)),
                const SizedBox(width: 5),
                Text(
                  isEs ? 'ASIGNACIÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…â€œN' : 'ASSIGNMENT',
                  style: ts.bodySmall?.copyWith(
                    fontSize: _ExpenseImportTypeScale.sectionLabel,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.55),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(width: 6),
                _ExpenseImportInfoButton(
                  message: _expenseImportHelpText(context, 'advanced'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: cs.surfaceContainerHighest.withValues(alpha: 0.1),
                border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.22)),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _AdvancedField(
                    width: 220,
                    controller: jsonProviderIdOverrideController,
                    enabled: !jsonSubmitting,
                    label: isEs
                        ? 'Proveedor detectado (ID)'
                        : 'Detected provider (ID)',
                  ),
                  _AdvancedField(
                    width: 190,
                    controller: jsonGroupIdOverrideController,
                    enabled: !jsonSubmitting,
                    label: isEs
                        ? 'AgrupaciÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â³n (ID)'
                        : 'Group (ID)',
                  ),
                  _AdvancedField(
                    width: 190,
                    controller: jsonStatementEntryController,
                    enabled: !jsonSubmitting,
                    label: isEs ? 'Entrada contable' : 'Statement entry',
                  ),
                  _AdvancedField(
                    width: 190,
                    controller: jsonClientController,
                    enabled: !jsonSubmitting,
                    label: isEs ? 'ID de cliente' : 'Client ID',
                  ),
                ],
              ),
            ),
            continueBtn(onPressed: () => setState(() => _jsonImportStep = 2)),
            const SizedBox(height: 8),
          ],
        ),
      );
    }

    // ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ Step 2: RevisiÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â³n ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬
    if (step == 2) {
      final jsonAdvanceOptions = _buildAdvanceOptions(
        providerId: _jsonProviderIdOverrideController.text.trim(),
        vendorName: _jsonProviderIdOverrideController.text.trim().isNotEmpty
            ? ''
            : _vendorController.text.trim(),
      );
      final jsonSettlementFields = ExpenseSettlementFields(
        settlement: _jsonSettlement,
        advanceOptions: jsonAdvanceOptions,
        enabled: !jsonSubmitting,
        onTypeChanged: (type) =>
            setState(() => _jsonSettlement.setExpenseType(type)),
        onAdvanceExpenseChanged: (id) =>
            setState(() => _jsonSettlement.selectedAdvanceExpenseId = id),
        onChanged: () => setState(() {}),
      );
      final jsonDiscountPreview = _jsonDiscountPreview();
      final jsonDiscountFields = ExpenseDocumentDiscountFields(
        discount: _jsonDocumentDiscount,
        enabled: !jsonSubmitting,
        preview: jsonDiscountPreview,
        compactSummary: true,
        onChanged: () => setState(() {}),
      );
      final jsonSummaryValidationError = _jsonUseSummaryTotals
          ? ExpenseFormHelpers.validateSummaryTotals(
              base: _parseControllerAmount(_jsonBaseController),
              tax: _parseControllerAmount(_jsonTaxController),
              total: _parseControllerAmount(_jsonTotalController),
            )
          : null;
      final jsonTotalsFields = ExpenseDocumentTotalsFields(
        baseController: _jsonBaseController,
        taxController: _jsonTaxController,
        totalController: _jsonTotalController,
        enabled: !jsonSubmitting,
        useSummaryTotals: _jsonUseSummaryTotals,
        lockToLines: false,
        validationError: jsonSummaryValidationError,
        onSummaryModeChanged: (value) => setState(() {
          _jsonUseSummaryTotals = value;
          if (_jsonUseSummaryTotals) {
            _syncJsonSummaryControllers(_ExpenseDocumentTotalField.total);
          }
        }),
        onBaseChanged: (_) {
          _syncJsonSummaryControllers(_ExpenseDocumentTotalField.base);
          setState(() {});
        },
        onTaxChanged: (_) {
          _syncJsonSummaryControllers(_ExpenseDocumentTotalField.tax);
          setState(() {});
        },
        onTotalChanged: (_) {
          _syncJsonSummaryControllers(_ExpenseDocumentTotalField.total);
          setState(() {});
        },
      );

      Widget sectionLbl(String text, IconData icon, {required String help}) =>
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(icon,
                    size: 12,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.55)),
                const SizedBox(width: 5),
                Text(
                  text.toUpperCase(),
                  style: ts.bodySmall?.copyWith(
                    fontSize: _ExpenseImportTypeScale.sectionLabel,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.55),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(width: 6),
                _ExpenseImportInfoButton(message: help),
              ],
            ),
          );

      return SingleChildScrollView(
        padding: const EdgeInsets.only(right: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            stepHeader(
              icon: Icons.rate_review_outlined,
              title: isEs ? 'Revisar importes' : 'Review amounts',
              subtitle: isEs
                  ? 'Verifica el tipo de gasto, descuentos e importes'
                  : 'Verify the expense type, discounts, and amounts',
            ),
            sectionLbl(
              l.expenseJsonTabSectionExpenseType,
              Icons.receipt_long_outlined,
              help: _expenseImportHelpText(context, 'expenseType'),
            ),
            jsonSettlementFields,
            const SizedBox(height: 14),
            sectionLbl(
              l.expenseJsonTabSectionDiscount,
              Icons.discount_outlined,
              help: _expenseImportHelpText(context, 'discount'),
            ),
            jsonDiscountFields,
            const SizedBox(height: 14),
            sectionLbl(
              l.expenseJsonTabSectionTotal,
              Icons.calculate_outlined,
              help: _expenseImportHelpText(context, 'totals'),
            ),
            jsonTotalsFields,
            continueBtn(
              onPressed: jsonSummaryValidationError == null
                  ? () => setState(() => _jsonImportStep = 3)
                  : null,
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    }

    // ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ Step 3: ConfirmaciÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â³n ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬
    final hasGroup = resolveGroupId().trim().isNotEmpty;
    final canImport = hasGroup &&
        !jsonSubmitting &&
        !(_jsonSettlement.isFinal &&
            (_jsonSettlement.selectedAdvanceExpenseId ?? '').trim().isEmpty);
    final invoiceLabel = (_jsonInvoiceFileName ?? _fileName ?? '').trim();

    return SingleChildScrollView(
      padding: const EdgeInsets.only(right: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          stepHeader(
            icon: Icons.check_circle_outline_rounded,
            title: isEs ? 'Listo para importar' : 'Ready to import',
            subtitle: isEs
                ? 'Revisa el resumen y confirma la importaciÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â³n'
                : 'Review the summary and confirm the import',
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: cs.primaryContainer.withValues(alpha: 0.1),
              border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.summarize_outlined, size: 14, color: cs.primary),
                    const SizedBox(width: 6),
                    Text(
                      isEs ? 'Resumen' : 'Summary',
                      style: ts.bodySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _JsonImportSummaryRow(
                  icon: Icons.data_object_outlined,
                  text: (_jsonFileName ?? '').trim().isEmpty
                      ? l.expenseJsonLeftJsonPending
                      : 'JSON: $_jsonFileName',
                ),
                const SizedBox(height: 6),
                _JsonImportSummaryRow(
                  icon: Icons.receipt_long_outlined,
                  text: invoiceLabel.isEmpty
                      ? l.expenseJsonLeftInvoicePending
                      : '${isEs ? 'Factura' : 'Invoice'}: $invoiceLabel',
                ),
                if (_jsonTotalController.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _JsonImportSummaryRow(
                    icon: Icons.euro_rounded,
                    text: 'Total: ${_jsonTotalController.text}',
                  ),
                ],
              ],
            ),
          ),
          if ((jsonError ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: cs.errorContainer.withValues(alpha: 0.2),
                border: Border.all(color: cs.error.withValues(alpha: 0.35)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline_rounded, size: 14, color: cs.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      jsonError!,
                      style: ts.bodySmall?.copyWith(color: cs.onErrorContainer),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: canImport ? submitExpenseJsonImport : null,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: jsonSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.playlist_add_check_circle_outlined,
                      size: 22),
              label: Text(
                isEs ? 'Importar documento' : 'Import document',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          if (!hasGroup) ...[
            const SizedBox(height: 8),
            Text(
              isEs
                  ? 'Selecciona un grupo antes de importar'
                  : 'Select a group before importing',
              textAlign: TextAlign.center,
              style: ts.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  @override
  Widget _buildBatchImportTab(AppLocalizations l,
      {bool showInlineControls = true}) {
    {
      final cs = Theme.of(context).colorScheme;
      final hasGroup = resolveGroupId().trim().isNotEmpty;
      final selectedCount = batchDocumentNames.length;
      const maxBatchDocs = _ExpenseUploadScreenStateBase._maxBatchDocuments;
      final jobStatusName = _expenseBatchJobStatusFromPayload(_batchJobStatus);
      final hasTrackedJob = (_batchJobId ?? '').trim().isNotEmpty;
      final jobActive =
          hasTrackedJob && !_isExpenseBatchJobTerminal(jobStatusName);
      final jobCompleted = jobStatusName == 'completed';
      final jobFailed = jobStatusName == 'failed';
      final jobTotalFiles = _batchJobInt(_batchJobStatus?['totalFiles']);
      final jobProcessedFiles =
          _batchJobInt(_batchJobStatus?['processedFiles']);
      final jobImportedCount = _batchJobInt(_batchJobStatus?['readyCount']);
      final jobSkippedCount = _batchJobInt(_batchJobStatus?['warningCount']) +
          _batchJobInt(_batchJobStatus?['duplicateCount']) +
          _batchJobInt(_batchJobStatus?['failedCount']);
      final hasPreviewItems = _batchPreviewItems.isNotEmpty;
      final selectedPreviewCount =
          _batchPreviewItems.where((item) => item.selected).length;
      final hasIncidentExport = hasTrackedJob &&
          _hasIncidentItems(
            _batchPreviewItems,
            skippedCount: jobSkippedCount,
            duplicateCount: _batchJobInt(_batchJobStatus?['duplicateCount']) +
                _batchJobInt(_batchConfirmResult?['duplicateCount']),
            failedCount: _batchJobInt(_batchJobStatus?['failedCount']),
            warningCount: _batchJobInt(_batchJobStatus?['warningCount']) +
                _batchJobInt(_batchConfirmResult?['skippedCount']),
          );
      final headerLoadedCount =
          hasTrackedJob && jobTotalFiles > 0 ? jobTotalFiles : selectedCount;
      final remainingSlots =
          (maxBatchDocs - headerLoadedCount).clamp(0, maxBatchDocs);
      final totalBytes = batchDocumentBytes.fold<int>(
        0,
        (sum, bytes) => sum + bytes.length,
      );
      final backendProgress = _batchJobDouble(_batchJobStatus?['progress']);
      final uploadRatio = hasTrackedJob
          ? (backendProgress > 0
              ? backendProgress.clamp(0.0, 1.0).toDouble()
              : (jobTotalFiles > 0
                  ? (jobProcessedFiles / jobTotalFiles)
                      .clamp(0.0, 1.0)
                      .toDouble()
                  : 0.0))
          : (maxBatchDocs == 0
              ? 0.0
              : (selectedCount / maxBatchDocs).clamp(0.0, 1.0).toDouble());
      final verifyText = hasTrackedJob
          ? _expenseBatchJobUiMessage(_batchJobStatus)
          : batchVerifyMessage ?? l.expenseUploadBatchWaiting;
      final verifyLower = verifyText.toLowerCase();
      final verifyLooksOk = jobCompleted ||
          (verifyLower.contains('verific') && verifyLower.contains('ok'));
      final verifyHasIssue = jobFailed ||
          verifyLower.contains('no ') ||
          verifyLower.contains('error') ||
          verifyLower.contains('invalid');

      final uploadedFileNames = recentUploads
          .map((e) => (e['file'] ?? '').toLowerCase().trim())
          .where((n) => n.isNotEmpty)
          .toSet();
      final selectionNameCounts = <String, int>{};
      for (final raw in batchDocumentNames) {
        final key = raw.toLowerCase().trim();
        if (key.isEmpty) continue;
        selectionNameCounts[key] = (selectionNameCounts[key] ?? 0) + 1;
      }
      final warningKeys = <String>{
        ...selectionNameCounts.entries
            .where((entry) => entry.value > 1)
            .map((entry) => entry.key),
        ...uploadedFileNames.where(selectionNameCounts.containsKey),
      };
      final resultIssueMap = <String, String>{
        ..._expenseBatchFileIssueMapFromPayload(_batchJobStatus),
        ..._expenseBatchFileIssueMapFromPayload(_batchJobResult),
      };

      final files = <_BatchExecutionFile>[
        for (var index = 0; index < batchDocumentNames.length; index++)
          _BatchExecutionFile(
            originalIndex: index,
            name: batchDocumentNames[index],
            sizeBytes: index < batchDocumentBytes.length
                ? batchDocumentBytes[index].length
                : 0,
            status: (() {
              final key = batchDocumentNames[index].toLowerCase().trim();
              if (resultIssueMap.containsKey(key)) {
                return _BatchExecutionFileStatus.error;
              }
              if (warningKeys.contains(key)) {
                return _BatchExecutionFileStatus.warning;
              }
              return _BatchExecutionFileStatus.success;
            })(),
            detail: (() {
              final key = batchDocumentNames[index].toLowerCase().trim();
              final jobIssue = resultIssueMap[key];
              if (jobIssue != null && jobIssue.isNotEmpty) {
                return jobIssue;
              }
              if (uploadedFileNames.contains(key)) {
                return 'Ya existe en gastos recientes';
              }
              if ((selectionNameCounts[key] ?? 0) > 1) {
                return 'Nombre duplicado en la seleccion';
              }
              if (jobCompleted) {
                return 'Procesado correctamente';
              }
              if (jobActive) {
                return 'En cola para importar';
              }
              if (jobFailed) {
                return 'Listo para reintentar';
              }
              return 'Listo para importar';
            })(),
          ),
      ];
      final warningIndexes = files
          .where((file) => file.status == _BatchExecutionFileStatus.warning)
          .map((file) => file.originalIndex)
          .toSet();
      final filteredFiles = files.where((file) {
        switch (_batchFileFilterIndex) {
          case 1:
            return file.status == _BatchExecutionFileStatus.success;
          case 2:
            return file.status != _BatchExecutionFileStatus.success;
          default:
            return true;
        }
      }).toList(growable: false);

      final copyIssuesText = [
        'Archivos con incidencia',
        if ((batchError ?? '').trim().isNotEmpty)
          'Error: ${batchError!.trim()}',
        '',
        ...batchSkippedDetails.map((detail) => '- $detail'),
      ].join('\n');

      Widget executionPanel = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BatchCollapsibleSummary(
            collapsed: _batchSummaryCollapsed,
            onToggle: () => setState(() {
              _batchSummaryCollapsed = !_batchSummaryCollapsed;
            }),
            loadedCount: headerLoadedCount,
            maxCount: maxBatchDocs,
            totalBytes: totalBytes,
            remainingSlots: remainingSlots,
            uploadRatio: uploadRatio,
            status: jobStatusName,
            hasTrackedJob: hasTrackedJob,
            totalFiles: jobTotalFiles > 0 ? jobTotalFiles : headerLoadedCount,
            processedFiles: jobProcessedFiles,
            importedCount: jobImportedCount,
            skippedCount: jobSkippedCount,
            reviewCount: _batchJobInt(_batchJobStatus?['warningCount']) +
                _batchJobInt(_batchJobStatus?['failedCount']),
            duplicateCount: _batchJobInt(_batchJobStatus?['duplicateCount']),
            currentStep: _batchJobText(_batchJobStatus?['currentStep']),
            message: _batchJobText(_batchJobStatus?['message']),
            loadingResult: _batchResultLoading,
            warningDetails: batchSkippedDetails,
            warningsExpanded: _batchErrorsExpanded,
            onToggleWarnings: () => setState(() {
              _batchErrorsExpanded = !_batchErrorsExpanded;
            }),
            onCopyWarnings: batchSkippedDetails.isEmpty
                ? null
                : () => copyTextWithManualFallbackDialog(
                      context,
                      text: copyIssuesText,
                      successMessage: 'Lista copiada',
                      dialogTitle: 'Copiar incidencias manualmente',
                      dialogMessage:
                          'Tu navegador bloqueo la copia automatica. Selecciona la lista y copiala manualmente.',
                    ),
          ),
          if ((batchError ?? '').trim().isNotEmpty &&
              batchSkippedDetails.isEmpty) ...[
            const SizedBox(height: 6),
            _BatchStateBanner(
              icon: Icons.info_outline,
              message: batchError!.trim(),
              color: cs.error,
              backgroundColor: cs.errorContainer.withValues(alpha: 0.22),
              borderColor: cs.error.withValues(alpha: 0.32),
              textColor: cs.onErrorContainer,
            ),
          ],
          const SizedBox(height: 6),
          Expanded(
            child: hasPreviewItems
                ? DefaultTabController(
                    length: 3,
                    initialIndex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _BatchReviewTabHeader(
                          fileCount: files.length,
                          selectedCount: selectedPreviewCount,
                          hasIssue: verifyHasIssue,
                          looksOk: verifyLooksOk,
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildBatchFileListView(
                                filteredFiles: filteredFiles,
                                totalCount: files.length,
                                warningCount: warningIndexes.length,
                                warningIndexes: warningIndexes,
                                selectedCount: selectedCount,
                                hasTrackedJob: hasTrackedJob,
                                jobActive: jobActive,
                              ),
                              _BatchExpensePreviewReviewPanel(
                                items: _batchPreviewItems,
                                selectedCount: selectedPreviewCount,
                                confirming: batchSubmitting,
                                confirmResult: _batchConfirmResult,
                                canExportIncidents: hasIncidentExport,
                                exportingIncidents: _batchExportingIncidents,
                                onExportIncidents: exportBatchIncidentExcel,
                                onToggle: (item, selected) => setState(() {
                                  if (!item.canSelect) return;
                                  item.selected = selected;
                                }),
                                onEdit: (item) =>
                                    _showBatchPreviewEditDialog(item),
                                onConfirm: confirmBatchPreviewImport,
                              ),
                              _BatchVerificationTabPanel(
                                title: l.expenseUploadBatchVerificationTitle,
                                message: verifyText,
                                hasIssue: verifyHasIssue,
                                looksOk: verifyLooksOk,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : _buildBatchFileListView(
                    filteredFiles: filteredFiles,
                    totalCount: files.length,
                    warningCount: warningIndexes.length,
                    warningIndexes: warningIndexes,
                    selectedCount: selectedCount,
                    hasTrackedJob: hasTrackedJob,
                    jobActive: jobActive,
                  ),
          ),
          if (!hasGroup) ...[
            const SizedBox(height: 10),
            Text(
              l.expenseUploadBatchGroupRequired,
              style: TextStyle(color: cs.error, fontSize: 12),
            ),
          ],
        ],
      );

      if (!showInlineControls) {
        return executionPanel;
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BatchLeftControlPanel(
            selectedCount: headerLoadedCount,
            maxDocuments: maxBatchDocs,
            totalBytes: totalBytes,
            submitting: batchSubmitting ||
                batchGeneratingJson ||
                jobActive ||
                _batchStartingJob,
            hasGroupSelected: hasGroup,
            canImport: !jobActive &&
                !batchSubmitting &&
                !batchGeneratingJson &&
                !jobCompleted &&
                !hasPreviewItems &&
                hasGroup &&
                batchDocumentNames.isNotEmpty,
            jobActive: jobActive,
            jobCompleted: jobCompleted,
            jobFailed: jobFailed,
            statusMessage: hasTrackedJob ? verifyText : null,
            warningCount: warningIndexes.length,
            importedCount: jobImportedCount,
            skippedCount: jobSkippedCount,
            onPickDocuments: pickBatchDocuments,
            onImport: submitBatchImport,
            onClearSelection: batchDocumentNames.isEmpty
                ? null
                : () => setState(() {
                      _resetBatchJobTracking(
                        clearResult: true,
                        clearCache: true,
                      );
                      batchDocumentBytes.clear();
                      batchDocumentNames.clear();
                      _batchSkippedDetails.clear();
                      _batchVerifyMessage = null;
                      _batchError = null;
                      _batchDetectedInvoices = 0;
                      _batchFileFilterIndex = 0;
                    }),
          ),
          const SizedBox(height: 16),
          Expanded(child: executionPanel),
        ],
      );
    }
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;
    final hasGroup = resolveGroupId().trim().isNotEmpty;
    final selectedCount = batchDocumentNames.length;
    const maxBatchDocs = _ExpenseUploadScreenStateBase._maxBatchDocuments;
    final remainingSlots =
        (maxBatchDocs - selectedCount).clamp(0, maxBatchDocs);
    final totalBytes = batchDocumentBytes.fold<int>(
      0,
      (sum, bytes) => sum + bytes.length,
    );
    final totalSizeMb = (totalBytes / (1024 * 1024)).toStringAsFixed(2);
    final uploadRatio = maxBatchDocs == 0 ? 0.0 : selectedCount / maxBatchDocs;
    final verifyText = batchVerifyMessage ?? l.expenseUploadBatchWaiting;
    final verifyLower = verifyText.toLowerCase();
    final verifyLooksOk =
        verifyLower.contains('verific') && verifyLower.contains('ok');
    final verifyHasIssue = verifyLower.contains('no ') ||
        verifyLower.contains('error') ||
        verifyLower.contains('invalid');
    final showInlineUploader = MediaQuery.of(context).size.width < 920;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.layers_outlined, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                'Batch import',
                style: ts.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l.expenseUploadBatchFlow,
            style: ts.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          if (showInlineUploader) ...[
            _CompactOutlinedButton(
              onPressed: (batchSubmitting || batchGeneratingJson)
                  ? null
                  : pickBatchDocuments,
              icon: Icons.picture_as_pdf_outlined,
              label: l.expenseUploadBatchUploadDocsCta,
            ),
            const SizedBox(height: 6),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  selectedCount == 0
                      ? l.expenseUploadBatchLimits
                      : l.expenseUploadBatchSelectedCount(selectedCount),
                  style: ts.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
              if (selectedCount > 0)
                Text(
                  '${(uploadRatio * 100).toStringAsFixed(0)}%',
                  style: ts.bodySmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: uploadRatio.clamp(0, 1),
              backgroundColor: cs.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resumen de carga',
                  style: ts.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final tileWidth = constraints.maxWidth >= 660
                        ? (constraints.maxWidth - 8) / 2
                        : constraints.maxWidth;
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MetricTile(
                          width: tileWidth,
                          icon: Icons.insert_drive_file_outlined,
                          label: 'Archivos cargados',
                          value: '$selectedCount / $maxBatchDocs',
                          valueColor: selectedCount > 0 ? cs.primary : null,
                        ),
                        _MetricTile(
                          width: tileWidth,
                          icon: Icons.space_dashboard_outlined,
                          label: 'Espacios disponibles',
                          value: '$remainingSlots',
                          valueColor: remainingSlots == 0
                              ? cs.error
                              : remainingSlots < 20
                                  ? Colors.amber.shade700
                                  : null,
                        ),
                        _MetricTile(
                          width: tileWidth,
                          icon: Icons.data_usage_outlined,
                          label: 'TamaÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â±o total',
                          value: '$totalSizeMb MB',
                        ),
                        _MetricTile(
                          width: tileWidth,
                          icon: Icons.receipt_long_outlined,
                          label: 'Facturas detectadas en JSON',
                          value: batchDetectedInvoices > 0
                              ? '$batchDetectedInvoices'
                              : 'ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â',
                          valueColor:
                              batchDetectedInvoices > 0 ? cs.primary : null,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          if (batchDocumentNames.isNotEmpty) ...[
            const SizedBox(height: 8),
            _BatchDocumentList(
              names: batchDocumentNames,
              bytes: batchDocumentBytes,
              uploadedFileNames: recentUploads
                  .map((e) => (e['file'] ?? '').toLowerCase().trim())
                  .where((n) => n.isNotEmpty)
                  .toSet(),
              disabled: batchSubmitting || batchGeneratingJson,
              onRemoveAt: (i) => setState(() {
                batchDocumentBytes.removeAt(i);
                batchDocumentNames.removeAt(i);
              }),
              onClearAll: () => setState(() {
                batchDocumentBytes.clear();
                batchDocumentNames.clear();
              }),
            ),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: verifyHasIssue
                    ? cs.error.withValues(alpha: 0.5)
                    : cs.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  verifyHasIssue
                      ? Icons.error_outline
                      : (verifyLooksOk
                          ? Icons.check_circle_outline
                          : Icons.hourglass_bottom),
                  size: 16,
                  color: verifyHasIssue
                      ? cs.error
                      : (verifyLooksOk ? cs.primary : cs.onSurfaceVariant),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.expenseUploadBatchVerificationTitle,
                        style:
                            ts.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        verifyText,
                        style:
                            ts.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l.expenseUploadBatchImportTitle,
            style: ts.bodySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          if (!hasGroup)
            Text(
              l.expenseUploadBatchGroupRequired,
              style: TextStyle(color: cs.error, fontSize: 12),
            ),
          if ((batchError ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: cs.errorContainer.withValues(alpha: 0.25),
                border: Border.all(
                  color: cs.error.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      size: 14, color: cs.error.withValues(alpha: 0.8)),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      batchError!,
                      style: ts.bodySmall?.copyWith(
                        color: cs.onErrorContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (batchSkippedDetails.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.amber.withValues(alpha: 0.06),
                border: Border.all(
                  color: Colors.amber.withValues(alpha: 0.38),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ Header ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            size: 14, color: Colors.amber.shade600),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${batchSkippedDetails.length} archivos con incidencia',
                            style: ts.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.amber.shade200,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Copiar lista',
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints:
                              const BoxConstraints(minWidth: 28, minHeight: 28),
                          icon: Icon(Icons.copy_all_outlined,
                              size: 15,
                              color:
                                  cs.onSurfaceVariant.withValues(alpha: 0.7)),
                          onPressed: () => copyTextWithManualFallbackDialog(
                            context,
                            text: [
                              'Archivos con incidencia',
                              if ((batchError ?? '').trim().isNotEmpty)
                                'Error: ${batchError!.trim()}',
                              '',
                              ...batchSkippedDetails.map(
                                  (d) => 'ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¢ $d'),
                            ].join('\n'),
                            successMessage: 'Lista copiada',
                            dialogTitle: 'Copiar incidencias manualmente',
                            dialogMessage:
                                'Tu navegador bloqueÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â³ la copia automÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¡tica. Selecciona la lista y cÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â³piala manualmente.',
                          ),
                        ),
                        if (batchSkippedDetails.length > 6)
                          IconButton(
                            tooltip:
                                'Ver todos (${batchSkippedDetails.length})',
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 28, minHeight: 28),
                            icon: Icon(Icons.open_in_new,
                                size: 15,
                                color:
                                    cs.onSurfaceVariant.withValues(alpha: 0.7)),
                            onPressed: () => showSafeDialogOnActiveView<void>(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded,
                                        size: 18, color: Colors.amber.shade600),
                                    const SizedBox(width: 8),
                                    Text(
                                        '${batchSkippedDetails.length} archivos con incidencia'),
                                  ],
                                ),
                                content: SizedBox(
                                  width: 720,
                                  child: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxHeight: 420),
                                    child: Scrollbar(
                                      thumbVisibility: true,
                                      child: ListView.separated(
                                        shrinkWrap: true,
                                        itemCount: batchSkippedDetails.length,
                                        separatorBuilder: (_, __) => Divider(
                                          height: 1,
                                          color: cs.outlineVariant
                                              .withValues(alpha: 0.25),
                                        ),
                                        itemBuilder: (context, index) =>
                                            _SkippedFileRow(
                                          detail: batchSkippedDetails[index],
                                          cs: cs,
                                          ts: ts,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(dialogContext).pop(),
                                    child: const Text('Cerrar'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: Colors.amber.withValues(alpha: 0.25),
                  ),
                  // ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ Scrollable list ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 210),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ...batchSkippedDetails.take(6).map(
                                (detail) => _SkippedFileRow(
                                  detail: detail,
                                  cs: cs,
                                  ts: ts,
                                ),
                              ),
                          if (batchSkippedDetails.length > 6)
                            TextButton.icon(
                              onPressed: () => showSafeDialogOnActiveView<void>(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: Row(
                                    children: [
                                      Icon(Icons.warning_amber_rounded,
                                          size: 18,
                                          color: Colors.amber.shade600),
                                      const SizedBox(width: 8),
                                      Text(
                                          '${batchSkippedDetails.length} archivos con incidencia'),
                                    ],
                                  ),
                                  content: SizedBox(
                                    width: 720,
                                    child: ConstrainedBox(
                                      constraints:
                                          const BoxConstraints(maxHeight: 420),
                                      child: Scrollbar(
                                        thumbVisibility: true,
                                        child: ListView.separated(
                                          shrinkWrap: true,
                                          itemCount: batchSkippedDetails.length,
                                          separatorBuilder: (_, __) => Divider(
                                            height: 1,
                                            color: cs.outlineVariant
                                                .withValues(alpha: 0.25),
                                          ),
                                          itemBuilder: (context, index) =>
                                              _SkippedFileRow(
                                            detail: batchSkippedDetails[index],
                                            cs: cs,
                                            ts: ts,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(dialogContext).pop(),
                                      child: const Text('Cerrar'),
                                    ),
                                  ],
                                ),
                              ),
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                foregroundColor: cs.onSurfaceVariant,
                                textStyle: const TextStyle(fontSize: 11),
                              ),
                              icon: const Icon(Icons.visibility_outlined,
                                  size: 13),
                              label: Text(
                                'Ver ${batchSkippedDetails.length - 6} mÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¡s',
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: (batchSubmitting || batchGeneratingJson || !hasGroup)
                ? null
                : submitBatchImport,
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              textStyle: const TextStyle(fontSize: 13),
            ),
            icon: batchSubmitting
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.playlist_add_check_circle_outlined,
                    size: 18),
            label: Text(l.expenseUploadBatchImportCta),
          ),
        ],
      ),
    );
  }
}

// ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ Skipped file row ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬

enum _BatchExecutionFileStatus { success, warning, error }

class _BatchExecutionFile {
  final int originalIndex;
  final String name;
  final int sizeBytes;
  final _BatchExecutionFileStatus status;
  final String detail;

  const _BatchExecutionFile({
    required this.originalIndex,
    required this.name,
    required this.sizeBytes,
    required this.status,
    required this.detail,
  });
}

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

class _BatchLeftControlPanel extends StatefulWidget {
  final int selectedCount;
  final int maxDocuments;
  final int totalBytes;
  final bool submitting;
  final bool hasGroupSelected;
  final bool canImport;
  final bool jobActive;
  final bool jobCompleted;
  final bool jobFailed;
  final String? statusMessage;
  final int warningCount;
  final int importedCount;
  final int skippedCount;
  final VoidCallback onPickDocuments;
  final VoidCallback onImport;
  final VoidCallback? onClearSelection;

  const _BatchLeftControlPanel({
    required this.selectedCount,
    required this.maxDocuments,
    required this.totalBytes,
    required this.submitting,
    required this.hasGroupSelected,
    required this.canImport,
    required this.jobActive,
    required this.jobCompleted,
    required this.jobFailed,
    required this.statusMessage,
    this.warningCount = 0,
    this.importedCount = 0,
    this.skippedCount = 0,
    required this.onPickDocuments,
    required this.onImport,
    this.onClearSelection,
  });

  @override
  State<_BatchLeftControlPanel> createState() => _BatchLeftControlPanelState();
}

class _BatchLeftControlPanelState extends State<_BatchLeftControlPanel> {
  final bool _dragging = false;

  // Derive the active workflow step from job state.
  int get _activeStep {
    if (widget.jobActive) return 1;
    if (widget.jobCompleted || widget.jobFailed) {
      return widget.warningCount > 0 ? 2 : 3;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final step = _activeStep;

    final steps = [
      (
        icon: Icons.cloud_upload_outlined,
        title: isEs ? 'Subir documentos' : 'Upload documents',
        subtitle: isEs
            ? 'Hasta ${widget.maxDocuments} archivos'
            : 'Up to ${widget.maxDocuments} files',
      ),
      (
        icon: Icons.auto_awesome_outlined,
        title: isEs
            ? 'Verificaci\u00f3n autom\u00e1tica'
            : 'Automatic verification',
        subtitle: isEs ? 'OCR e IA' : 'OCR and AI',
      ),
      (
        icon: Icons.warning_amber_rounded,
        title: isEs ? 'Revisar incidencias' : 'Review issues',
        subtitle: widget.warningCount > 0
            ? (isEs
                ? '${widget.warningCount} detectadas'
                : '${widget.warningCount} found')
            : (isEs ? 'Sin incidencias' : 'No issues'),
      ),
      (
        icon: Icons.playlist_add_check_circle_outlined,
        title: isEs ? 'Confirmar importaci\u00f3n' : 'Confirm import',
        subtitle: isEs ? 'Importar gastos' : 'Import expenses',
      ),
    ];

    bool stepCompleted(int i) {
      if (widget.jobFailed) return false;
      return i < step;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: cs.surface.withValues(alpha: 0.18),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.28)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    (constraints.maxHeight - 32).clamp(0, double.infinity),
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ Step navigator ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬
                    for (int i = 0; i < steps.length; i++) ...[
                      if (i > 0)
                        Padding(
                          padding: const EdgeInsets.only(left: 15),
                          child: SizedBox(
                            height: 12,
                            width: 1,
                            child: VerticalDivider(
                              color: i <= step
                                  ? cs.primary.withValues(alpha: 0.35)
                                  : cs.outlineVariant.withValues(alpha: 0.35),
                              thickness: 1,
                              width: 1,
                            ),
                          ),
                        ),
                      _StepRow(
                        index: i,
                        icon: steps[i].icon,
                        title: steps[i].title,
                        subtitle: steps[i].subtitle,
                        isActive: step == i,
                        isCompleted: stepCompleted(i),
                        isReachable: i <= step,
                        onTap: null,
                        cs: cs,
                        ts: ts,
                      ),
                    ],
                    const SizedBox(height: 16),
                    // ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ Step content ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬
                    if (step == 0) ...[
                      // Upload zone
                      Builder(
                        builder: (context) {
                          final uploadZone = AnimatedContainer(
                            duration: const Duration(milliseconds: 140),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _dragging
                                    ? cs.primary.withValues(alpha: 0.8)
                                    : cs.outlineVariant.withValues(alpha: 0.38),
                                width: _dragging ? 1.5 : 1,
                              ),
                              color: _dragging
                                  ? cs.primaryContainer.withValues(alpha: 0.16)
                                  : cs.surface.withValues(alpha: 0.26),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Icon(
                                  _dragging
                                      ? Icons.file_download_done_outlined
                                      : Icons.cloud_upload_outlined,
                                  size: 28,
                                  color: cs.primary,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _dragging
                                      ? l.expenseBatchLeftDropActive
                                      : l.expenseBatchLeftDropHint,
                                  textAlign: TextAlign.center,
                                  style: ts.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: _dragging ? cs.primary : null,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  l.expenseBatchLeftFileTypes,
                                  textAlign: TextAlign.center,
                                  style: ts.bodySmall
                                      ?.copyWith(color: cs.onSurfaceVariant),
                                ),
                                const SizedBox(height: 12),
                                FilledButton.tonalIcon(
                                  onPressed: widget.submitting
                                      ? null
                                      : widget.onPickDocuments,
                                  icon: const Icon(Icons.upload_file_outlined,
                                      size: 17),
                                  label: Text(l.expenseBatchLeftPickCta),
                                ),
                              ],
                            ),
                          );

                          return uploadZone;
                        },
                      ),
                      if (widget.selectedCount > 0) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: cs.primaryContainer.withValues(alpha: 0.12),
                            border: Border.all(
                              color: cs.primary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.insert_drive_file_outlined,
                                  size: 14, color: cs.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isEs
                                      ? '${widget.selectedCount} archivo${widget.selectedCount == 1 ? '' : 's'} seleccionado${widget.selectedCount == 1 ? '' : 's'}'
                                      : '${widget.selectedCount} file${widget.selectedCount == 1 ? '' : 's'} selected',
                                  style: ts.bodySmall?.copyWith(
                                    color: cs.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (widget.onClearSelection != null)
                                InkWell(
                                  onTap: widget.submitting
                                      ? null
                                      : widget.onClearSelection,
                                  borderRadius: BorderRadius.circular(4),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Icon(Icons.close_rounded,
                                        size: 14,
                                        color:
                                            cs.primary.withValues(alpha: 0.7)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ] else if (step == 1) ...[
                      // Processing pipeline visualization
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: cs.primaryContainer.withValues(alpha: 0.08),
                          border: Border.all(
                            color: cs.primary.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: cs.primary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isEs
                                      ? 'Procesando lote...'
                                      : 'Processing batch...',
                                  style: ts.bodySmall?.copyWith(
                                    color: cs.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            if ((widget.statusMessage ?? '')
                                .trim()
                                .isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                widget.statusMessage!.trim(),
                                style: ts.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  height: 1.4,
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            _BatchPipelineStages(isEs: isEs, cs: cs, ts: ts),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Results summary
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: widget.jobFailed
                              ? cs.errorContainer.withValues(alpha: 0.12)
                              : widget.warningCount > 0
                                  ? Colors.amber.withValues(alpha: 0.08)
                                  : Colors.green.withValues(alpha: 0.08),
                          border: Border.all(
                            color: widget.jobFailed
                                ? cs.error.withValues(alpha: 0.28)
                                : widget.warningCount > 0
                                    ? Colors.amber.withValues(alpha: 0.35)
                                    : Colors.green.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  widget.jobFailed
                                      ? Icons.error_outline_rounded
                                      : widget.warningCount > 0
                                          ? Icons.warning_amber_rounded
                                          : Icons.check_circle_outline_rounded,
                                  size: 14,
                                  color: widget.jobFailed
                                      ? cs.error
                                      : widget.warningCount > 0
                                          ? Colors.amber.shade700
                                          : Colors.green.shade600,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  widget.jobFailed
                                      ? (isEs
                                          ? 'Importaci\u00f3n fallida'
                                          : 'Import failed')
                                      : widget.warningCount > 0
                                          ? (isEs
                                              ? 'Revisi\u00f3n necesaria'
                                              : 'Review needed')
                                          : (isEs
                                              ? '${widget.importedCount} gastos listos'
                                              : '${widget.importedCount} expenses ready'),
                                  style: ts.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: widget.jobFailed
                                        ? cs.error
                                        : widget.warningCount > 0
                                            ? Colors.amber.shade700
                                            : Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                            if ((widget.statusMessage ?? '')
                                .trim()
                                .isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                widget.statusMessage!.trim(),
                                style: ts.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant, height: 1.4),
                              ),
                            ],
                            if (!widget.jobFailed) ...[
                              const SizedBox(height: 10),
                              if (widget.importedCount > 0)
                                _ResultRow(
                                  icon: Icons.check_circle_outline_rounded,
                                  label: isEs
                                      ? '${widget.importedCount} listos'
                                      : '${widget.importedCount} ready',
                                  color: Colors.green.shade600,
                                  ts: ts,
                                ),
                              if (widget.warningCount > 0) ...[
                                const SizedBox(height: 4),
                                _ResultRow(
                                  icon: Icons.warning_amber_rounded,
                                  label: isEs
                                      ? '${widget.warningCount} requieren revisi\u00f3n'
                                      : '${widget.warningCount} need review',
                                  color: Colors.amber.shade700,
                                  ts: ts,
                                ),
                              ],
                              if (widget.skippedCount > 0) ...[
                                const SizedBox(height: 4),
                                _ResultRow(
                                  icon: Icons.remove_circle_outline_rounded,
                                  label: isEs
                                      ? '${widget.skippedCount} duplicados omitidos'
                                      : '${widget.skippedCount} duplicates omitted',
                                  color: cs.onSurfaceVariant,
                                  ts: ts,
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ],
                    const Spacer(),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: widget.canImport ? widget.onImport : null,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: widget.submitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              Icons.playlist_add_check_circle_outlined),
                      label: Text(
                        widget.jobCompleted
                            ? l.expenseBatchLeftCompleted
                            : widget.jobActive
                                ? l.expenseBatchLeftProcessing
                                : (isEs
                                    ? 'Analizar documentos'
                                    : 'Analyze documents'),
                      ),
                    ),
                    if (!widget.hasGroupSelected) ...[
                      const SizedBox(height: 8),
                      Text(
                        l.expenseBatchLeftGroupRequired,
                        style: ts.bodySmall?.copyWith(color: cs.error),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BatchPipelineStages extends StatelessWidget {
  final bool isEs;
  final ColorScheme cs;
  final TextTheme ts;

  const _BatchPipelineStages(
      {required this.isEs, required this.cs, required this.ts});

  @override
  Widget build(BuildContext context) {
    final stages = [
      (
        icon: Icons.check_circle_outline_rounded,
        label: isEs ? 'Documentos subidos' : 'Documents uploaded',
        done: true
      ),
      (
        icon: Icons.document_scanner_outlined,
        label: isEs ? 'OCR extrayendo texto' : 'OCR extracting text',
        done: false
      ),
      (
        icon: Icons.auto_awesome_outlined,
        label: isEs ? 'IA analizando datos' : 'AI analysing data',
        done: false
      ),
      (
        icon: Icons.price_check_outlined,
        label: isEs ? 'Validando importes' : 'Validating amounts',
        done: false
      ),
    ];

    return Column(
      children: [
        for (int i = 0; i < stages.length; i++) ...[
          if (i > 0) const SizedBox(height: 6),
          Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: stages[i].done
                    ? Icon(Icons.check_circle_rounded,
                        size: 14, color: Colors.green.shade600)
                    : SizedBox(
                        width: 13,
                        height: 13,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: cs.primary.withValues(alpha: 0.6),
                        ),
                      ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  stages[i].label,
                  style: ts.bodySmall?.copyWith(
                    fontSize: 11,
                    color: stages[i].done
                        ? cs.onSurface
                        : cs.onSurfaceVariant.withValues(alpha: 0.7),
                    fontWeight: stages[i].done ? FontWeight.w600 : null,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

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

class _BatchReviewTabHeader extends StatelessWidget {
  final int fileCount;
  final int selectedCount;
  final bool hasIssue;
  final bool looksOk;

  const _BatchReviewTabHeader({
    required this.fileCount,
    required this.selectedCount,
    required this.hasIssue,
    required this.looksOk,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: cs.surfaceContainerHighest.withValues(alpha: 0.18),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.28)),
      ),
      child: TabBar(
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          color: cs.primary.withValues(alpha: 0.14),
          border: Border.all(color: cs.primary.withValues(alpha: 0.24)),
        ),
        labelColor: cs.primary,
        unselectedLabelColor: cs.onSurfaceVariant,
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        tabs: [
          Tab(
            height: 34,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.folder_open_outlined, size: 15),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Archivos cargados \u00b7 $fileCount',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Tab(
            height: 34,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.fact_check_outlined, size: 15),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Previsualizaci\u00f3n \u00b7 $selectedCount seleccionados',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Tab(
            height: 34,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  hasIssue
                      ? Icons.error_outline
                      : looksOk
                          ? Icons.check_circle_outline
                          : Icons.hourglass_bottom,
                  size: 15,
                ),
                const SizedBox(width: 6),
                const Flexible(
                  child: Text(
                    'Verificaci\u00f3n',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
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
                _BatchStatusChip(
                  label: '${widget.selectedCount} seleccionados',
                  color: cs.primary,
                  icon: Icons.checklist_rounded,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _BatchPreviewQueueChip(
                        label: 'Todos',
                        count: widget.items.length,
                        selected: _queue == _BatchExpensePreviewQueue.all,
                        color: cs.primary,
                        onTap: () => setState(
                          () => _queue = _BatchExpensePreviewQueue.all,
                        ),
                      ),
                      _BatchPreviewQueueChip(
                        label: 'Listos',
                        count: readyCount,
                        selected: _queue == _BatchExpensePreviewQueue.ready,
                        color: Colors.green.shade600,
                        onTap: () => setState(
                          () => _queue = _BatchExpensePreviewQueue.ready,
                        ),
                      ),
                      _BatchPreviewQueueChip(
                        label: 'Revisi\u00f3n',
                        count: reviewCount,
                        selected: _queue == _BatchExpensePreviewQueue.review,
                        color: Colors.amber.shade700,
                        onTap: () => setState(
                          () => _queue = _BatchExpensePreviewQueue.review,
                        ),
                      ),
                      _BatchPreviewQueueChip(
                        label: 'Duplicados',
                        count: duplicateCount,
                        selected: _queue == _BatchExpensePreviewQueue.duplicate,
                        color: cs.error,
                        onTap: () => setState(
                          () => _queue = _BatchExpensePreviewQueue.duplicate,
                        ),
                      ),
                      _BatchPreviewQueueChip(
                        label: 'Fallidos',
                        count: failedCount,
                        selected: _queue == _BatchExpensePreviewQueue.failed,
                        color: cs.error,
                        onTap: () => setState(
                          () => _queue = _BatchExpensePreviewQueue.failed,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasFinancialSummary) ...[
                  const SizedBox(height: 7),
                  Text(
                    '${widget.selectedCount} gastos seleccionados \u00b7 ${_expensePreviewCurrency(selectedTotal, selectedCurrency)} total \u00b7 ${_expensePreviewCurrency(selectedTax, selectedCurrency)} IVA',
                    style: ts.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
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
                        onToggle: (selected) =>
                            widget.onToggle(item, selected),
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
                  onPressed:
                      widget.confirming || widget.selectedCount == 0
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
    final taxId = _batchJobText(prediction['vendorTaxId']);
    final invoiceNumber = _batchJobText(prediction['invoiceNumber']);
    final issueDate = _batchJobText(prediction['issueDate']);
    final subtotal = _expensePreviewMoney(prediction['subtotal']);
    final tax = _expensePreviewMoney(prediction['taxTotal']);
    final total = _expensePreviewMoney(prediction['total']);
    final currency = _batchJobText(prediction['currency']);
    final description = _batchJobFirstText([
      prediction['category'],
      prediction['description'],
      prediction['notes'],
    ]);
    final duplicateReason = _batchJobFirstText([
      item.duplicate['reason'],
      item.duplicate['existingExpenseId'] == null
          ? null
          : 'Ya existe: ${item.duplicate['existingExpenseId']}',
    ]);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
            Checkbox(
              value: item.selected,
              onChanged:
                  item.canSelect ? (value) => onToggle(value ?? false) : null,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 4),
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
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 11,
                    runSpacing: 4,
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
                      _FinancialPreviewMeta(
                        subtotal: subtotal,
                        tax: tax,
                      ),
                      if (taxId.isNotEmpty)
                        _PreviewMeta(
                          label: 'NIF/CIF',
                          value: taxId,
                          priority: _PreviewMetaPriority.tertiary,
                        ),
                      _DocumentPreviewMeta(fileName: item.fileName),
                    ],
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ts.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                  if (item.warnings.isNotEmpty ||
                      duplicateReason.isNotEmpty ||
                      (item.error ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      [
                        ...item.warnings,
                        if (duplicateReason.isNotEmpty) duplicateReason,
                        if ((item.error ?? '').trim().isNotEmpty)
                          item.error!.trim(),
                      ].join(' \u00b7 '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: ts.bodySmall?.copyWith(
                        color: item.isFailed || item.isDuplicate
                            ? cs.error
                            : Colors.amber.shade700,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
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

class _BatchPreviewQueueChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _BatchPreviewQueueChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: selected
                ? color.withValues(alpha: 0.14)
                : cs.surfaceContainerHighest.withValues(alpha: 0.18),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.34)
                  : cs.outlineVariant.withValues(alpha: 0.34),
            ),
          ),
          child: Text(
            '$label $count',
            style: ts.bodySmall?.copyWith(
              color: selected ? color : cs.onSurfaceVariant,
              fontSize: 10.5,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
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

class _FinancialPreviewMeta extends StatelessWidget {
  final String subtotal;
  final String tax;

  const _FinancialPreviewMeta({
    required this.subtotal,
    required this.tax,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;
    return Text(
      'Base ${subtotal.isEmpty ? '-' : subtotal} \u00b7 IVA ${tax.isEmpty ? '-' : tax}',
      style: ts.bodySmall?.copyWith(
        color: cs.onSurfaceVariant.withValues(alpha: 0.82),
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _DocumentPreviewMeta extends StatelessWidget {
  final String fileName;

  const _DocumentPreviewMeta({required this.fileName});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;
    return Tooltip(
      message: fileName,
      waitDuration: const Duration(milliseconds: 350),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.attach_file_rounded,
            size: 12,
            color: cs.onSurfaceVariant.withValues(alpha: 0.58),
          ),
          const SizedBox(width: 3),
          Text(
            'Ver documento',
            style: ts.bodySmall?.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.68),
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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

class _BatchOnboardingFlow extends StatefulWidget {
  final ColorScheme cs;
  final TextTheme ts;
  final Future<void> Function(
    List<({String fileName, Uint8List fileBytes})> files, {
    required int selectedCount,
  })? onDropWebDocuments;

  const _BatchOnboardingFlow({
    required this.cs,
    required this.ts,
    required this.onDropWebDocuments,
  });

  @override
  State<_BatchOnboardingFlow> createState() => _BatchOnboardingFlowState();
}

class _BatchOnboardingFlowState extends State<_BatchOnboardingFlow> {
  bool _dragging = false;
  bool _webDropProcessing = false;
  DropzoneViewController? _webDropController;

  Future<void> _handleWebDropFile(DropzoneFileInterface file) async {
    await _handleWebDropFiles([file]);
  }

  Future<void> _handleWebDropFiles(List<DropzoneFileInterface>? files) async {
    final controller = _webDropController;
    final onDrop = widget.onDropWebDocuments;
    if (controller == null ||
        onDrop == null ||
        files == null ||
        files.isEmpty) {
      if (mounted && _dragging) setState(() => _dragging = false);
      return;
    }
    if (_webDropProcessing) return;
    _webDropProcessing = true;

    final droppedFiles = <({String fileName, Uint8List fileBytes})>[];
    try {
      for (final file in files) {
        try {
          final fileName = await controller.getFilename(file);
          final fileBytes = await controller.getFileData(file);
          if (fileName.trim().isEmpty || fileBytes.isEmpty) continue;
          droppedFiles.add((fileName: fileName, fileBytes: fileBytes));
        } catch (_) {
          // The shared batch validation handles readable supported files;
          // unreadable browser drops are skipped here.
        }
      }

      if (mounted && _dragging) setState(() => _dragging = false);
      if (droppedFiles.isEmpty) return;
      await onDrop(droppedFiles, selectedCount: files.length);
    } finally {
      _webDropProcessing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.cs;
    final ts = widget.ts;
    final steps = [
      (icon: Icons.upload_file_outlined, label: 'Sube tus documentos'),
      (icon: Icons.auto_awesome_outlined, label: 'Hexora analiza con IA'),
      (icon: Icons.checklist_rounded, label: 'Revisa incidencias'),
      (icon: Icons.check_circle_outline_rounded, label: 'Importa al instante'),
    ];
    final webDropEnabled = kIsWeb &&
        widget.onDropWebDocuments != null &&
        FlutterDropzonePlatform.instance.runtimeType.toString() ==
            'FlutterDropzonePlugin';

    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: _dragging
            ? cs.primaryContainer.withValues(alpha: 0.18)
            : cs.surfaceContainerHighest.withValues(alpha: 0.07),
        border: Border.all(
          color: _dragging
              ? cs.primary.withValues(alpha: 0.7)
              : cs.outlineVariant.withValues(alpha: 0.38),
          width: _dragging ? 2 : 1.5,
          strokeAlign: BorderSide.strokeAlignCenter,
        ),
        boxShadow: _dragging
            ? [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.12),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _dragging
                  ? cs.primary.withValues(alpha: 0.22)
                  : cs.primaryContainer.withValues(alpha: 0.38),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: cs.primary.withValues(
                  alpha: _dragging ? 0.45 : 0.18,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(
                    alpha: _dragging ? 0.25 : 0.08,
                  ),
                  blurRadius: 18,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              _dragging
                  ? Icons.file_download_done_outlined
                  : Icons.cloud_upload_outlined,
              size: 32,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            child: Text(
              _dragging
                  ? 'Suelta los documentos para cargarlos'
                  : 'Arrastra tus facturas aqu\u00ed',
              key: ValueKey(_dragging),
              style: ts.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'PDF, JPG, PNG o WEBP \u2022 hasta 200 documentos por lote',
            style: ts.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontSize: 12.5,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < steps.length; i++) ...[
                  _OnboardingStep(
                    icon: steps[i].icon,
                    label: steps[i].label,
                    index: i + 1,
                    cs: cs,
                    ts: ts,
                  ),
                  if (i < steps.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 13,
                        color: cs.primary.withValues(alpha: 0.35),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (webDropEnabled) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: DropzoneView(
              operation: DragOperation.copy,
              onCreated: (controller) => _webDropController = controller,
              onHover: () {
                if (!mounted || _dragging) return;
                setState(() => _dragging = true);
              },
              onLeave: () {
                if (!mounted || !_dragging) return;
                setState(() => _dragging = false);
              },
              onDropFile: _handleWebDropFile,
              onDropFiles: _handleWebDropFiles,
            ),
          ),
          IgnorePointer(child: content),
        ],
      );
    }

    return content;
  }
}

class _OnboardingStep extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final ColorScheme cs;
  final TextTheme ts;

  const _OnboardingStep({
    required this.icon,
    required this.label,
    required this.index,
    required this.cs,
    required this.ts,
  });

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: cs.primaryContainer.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: cs.primary.withValues(alpha: 0.18),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 15, color: cs.primary),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: ts.bodySmall?.copyWith(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
                height: 1.25,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
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

String _formatBatchBytes(int bytes) {
  if (bytes <= 0) return '0 KB';
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
  return '${(bytes / 1024).toStringAsFixed(0)} KB';
}

String _expensePreviewMoney(dynamic value) {
  if (value == null) return '';
  if (value is num) return value.toStringAsFixed(value % 1 == 0 ? 0 : 2);
  return _batchJobText(value);
}

double _expensePreviewNumber(dynamic value) {
  if (value is num) return value.toDouble();
  var text = _batchJobText(value).replaceAll(RegExp(r'[^0-9,\.\-]'), '');
  if (text.contains(',') && text.contains('.')) {
    text = text.replaceAll('.', '').replaceAll(',', '.');
  } else if (text.contains(',')) {
    text = text.replaceAll(',', '.');
  }
  return double.tryParse(text) ?? 0;
}

String _expensePreviewCurrency(double value, String currency) {
  final trimmedCurrency = currency.trim().toUpperCase();
  final symbol = trimmedCurrency == 'EUR'
      ? 'ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬'
      : trimmedCurrency == 'USD'
          ? r'$'
          : trimmedCurrency.isEmpty
              ? ''
              : trimmedCurrency;
  final normalizedSymbol = trimmedCurrency == 'EUR' ? '€' : symbol;
  return NumberFormat.currency(
    locale: 'es_ES',
    symbol: normalizedSymbol,
    decimalDigits: 2,
  ).format(value);
}

String _expensePreviewStatusLabel(_ExpenseBatchPreviewItem item) {
  if (item.isDuplicate) return 'Duplicado';
  if (item.isFailed) return 'Fallido';
  if (item.needsReview) return item.reviewed ? 'Revisado' : 'Revisar';
  if (item.status == 'ready') return 'Listo';
  return item.status.isEmpty ? 'Pendiente' : item.status;
}

IconData _expensePreviewStatusIcon(_ExpenseBatchPreviewItem item) {
  if (item.isDuplicate) return Icons.content_copy_outlined;
  if (item.isFailed) return Icons.error_outline;
  if (item.needsReview && !item.reviewed) return Icons.rate_review_outlined;
  if (item.status == 'ready' || item.reviewed) {
    return Icons.verified_outlined;
  }
  return Icons.hourglass_empty_rounded;
}

Color _expensePreviewStatusColor(
  _ExpenseBatchPreviewItem item,
  ColorScheme cs,
) {
  if (item.isDuplicate || item.isFailed) return cs.error;
  if (item.needsReview && !item.reviewed) return Colors.amber.shade700;
  if (item.status == 'ready' || item.reviewed) return Colors.green.shade600;
  return cs.onSurfaceVariant;
}

Color _expensePreviewConfidenceColor(double confidence, ColorScheme cs) {
  if (confidence <= 0) return cs.onSurfaceVariant;
  if (confidence >= 0.86) return Colors.green.shade600;
  if (confidence >= 0.72) return Colors.amber.shade700;
  return cs.error;
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

// ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ Compact helper widgets ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬

String _expenseImportHelpText(BuildContext context, String key) {
  final isSpanish = Localizations.localeOf(context)
      .languageCode
      .toLowerCase()
      .startsWith('es');
  final messages = <String, ({String es, String en})>{
    'jsonWorkflow': (
      es: 'Importa gastos desde un JSON: adjunta el JSON, la factura original y revisa los importes antes de guardar.',
      en: 'Import expenses from JSON: attach the JSON, the original invoice and review totals before saving.',
    ),
    'promptAi': (
      es: 'Genera una guia para que la IA devuelva el JSON con el formato esperado por Hexora.',
      en: 'Generate guidance so AI returns JSON in the format Hexora expects.',
    ),
    'jsonPayload': (
      es: 'Pega aqui el JSON del gasto. Si adjuntas un archivo JSON, se cargara automaticamente en este editor.',
      en: 'Paste the expense JSON here. If you attach a JSON file, it will load into this editor automatically.',
    ),
    'advanced': (
      es: 'Usa estas opciones solo si necesitas forzar proveedor, grupo, movimiento bancario o cliente concretos.',
      en: 'Use these options only when you need to force a specific provider, group, bank entry or client.',
    ),
    'expenseType': (
      es: 'Define como se tratara el gasto: estandar, anticipo o liquidacion contra un anticipo existente.',
      en: 'Define how the expense is handled: standard, advance payment or settlement against an existing advance.',
    ),
    'discount': (
      es: 'Aplica un descuento al documento completo. Puedes indicar importe o porcentaje; el otro valor se sincroniza.',
      en: 'Apply a discount to the whole document. Enter either amount or percentage; the other value stays in sync.',
    ),
    'totals': (
      es: 'Activa el resumen si quieres validar el total del documento contra los importes que aparecen en la factura.',
      en: 'Enable the summary when you want to validate document totals against the amounts shown on the invoice.',
    ),
  };
  final message = messages[key];
  if (message == null) return '';
  return isSpanish ? message.es : message.en;
}

class _ExpenseImportInfoButton extends StatelessWidget {
  final String message;

  const _ExpenseImportInfoButton({required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.trim().isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: message,
      waitDuration: const Duration(milliseconds: 250),
      showDuration: const Duration(seconds: 6),
      child: MouseRegion(
        cursor: SystemMouseCursors.help,
        child: Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: cs.primaryContainer.withValues(alpha: 0.42),
            border: Border.all(color: cs.primary.withValues(alpha: 0.24)),
          ),
          child: Icon(
            Icons.info_outline_rounded,
            size: 13,
            color: cs.primary,
          ),
        ),
      ),
    );
  }
}

class _JsonFileBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final ColorScheme cs;

  const _JsonFileBadge({
    required this.icon,
    required this.label,
    required this.color,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final ts = Theme.of(context).textTheme;
    final display = label.length > 28
        ? 'ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦${label.substring(label.length - 26)}'
        : label;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        color: color.withValues(alpha: 0.08),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color.withValues(alpha: 0.8)),
          const SizedBox(width: 5),
          Text(
            display,
            style: ts.bodySmall?.copyWith(
              fontSize: 11,
              color: cs.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactOutlinedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;

  const _CompactOutlinedButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        textStyle: const TextStyle(fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      icon: Icon(icon, size: 16),
      label: Text(label),
    );
  }
}

class _CompactIconActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String tooltip;

  const _CompactIconActionButton({
    required this.onPressed,
    required this.icon,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton.outlined(
        onPressed: onPressed,
        icon: Icon(icon, size: 17),
        visualDensity: VisualDensity.compact,
        style: IconButton.styleFrom(
          minimumSize: const Size(36, 36),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class _JsonImportSummaryRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _JsonImportSummaryRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: cs.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: ts.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}

class _AdvancedField extends StatelessWidget {
  final double width;
  final TextEditingController controller;
  final bool enabled;
  final String label;

  const _AdvancedField({
    required this.width,
    required this.controller,
    required this.enabled,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        enabled: enabled,
        style: const TextStyle(fontSize: _ExpenseImportTypeScale.fieldValue),
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
              const TextStyle(fontSize: _ExpenseImportTypeScale.fieldLabel),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: cs.outlineVariant.withValues(alpha: 0.42),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: cs.outlineVariant.withValues(alpha: 0.34),
            ),
          ),
          filled: true,
          fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.14),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        ),
      ),
    );
  }
}

// ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ Batch document list ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬

class _BatchDocumentList extends StatelessWidget {
  final List<String> names;
  final List<Uint8List> bytes;
  final Set<String> uploadedFileNames;
  final bool disabled;
  final void Function(int index) onRemoveAt;
  final VoidCallback onClearAll;

  const _BatchDocumentList({
    required this.names,
    required this.bytes,
    required this.uploadedFileNames,
    required this.disabled,
    required this.onRemoveAt,
    required this.onClearAll,
  });

  bool _isDuplicate(String name) =>
      uploadedFileNames.contains(name.toLowerCase().trim());

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;
    final duplicateCount = names.where(_isDuplicate).length;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ Header ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
            child: Row(
              children: [
                Icon(Icons.folder_open_outlined,
                    size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${names.length} archivos',
                    style: ts.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                if (duplicateCount > 0) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: Colors.amber.withValues(alpha: 0.15),
                      border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.45)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            size: 10, color: Colors.amber.shade600),
                        const SizedBox(width: 3),
                        Text(
                          '$duplicateCount ya subido${duplicateCount == 1 ? '' : 's'}',
                          style: ts.bodySmall?.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.amber.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                TextButton.icon(
                  onPressed: disabled ? null : onClearAll,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    foregroundColor: cs.error,
                    textStyle: const TextStyle(fontSize: 11),
                  ),
                  icon: const Icon(Icons.clear_all, size: 14),
                  label: const Text('Limpiar todo'),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.35)),
          // ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ Scrollable file list ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: names.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                indent: 10,
                endIndent: 10,
                color: cs.outlineVariant.withValues(alpha: 0.2),
              ),
              itemBuilder: (_, i) => _BatchDocFileRow(
                name: names[i],
                sizeBytes: i < bytes.length ? bytes[i].length : 0,
                isDuplicate: _isDuplicate(names[i]),
                disabled: disabled,
                onRemove: () => onRemoveAt(i),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BatchDocFileRow extends StatelessWidget {
  final String name;
  final int sizeBytes;
  final bool isDuplicate;
  final bool disabled;
  final VoidCallback onRemove;

  const _BatchDocFileRow({
    required this.name,
    required this.sizeBytes,
    required this.isDuplicate,
    required this.disabled,
    required this.onRemove,
  });

  String get _sizeLabel {
    if (sizeBytes >= 1024 * 1024) {
      return '${(sizeBytes / 1024 / 1024).toStringAsFixed(1)} MB';
    }
    return '${(sizeBytes / 1024).toStringAsFixed(0)} KB';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Row(
        children: [
          Icon(
            Icons.picture_as_pdf_outlined,
            size: 15,
            color: isDuplicate
                ? Colors.amber.shade500
                : cs.onSurfaceVariant.withValues(alpha: 0.55),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: ts.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 11.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (sizeBytes > 0)
                  Text(
                    _sizeLabel,
                    style: ts.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
          if (isDuplicate) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.amber.withValues(alpha: 0.12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
              ),
              child: Text(
                'Ya subido',
                style: ts.bodySmall?.copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.amber.shade500,
                ),
              ),
            ),
          ],
          const SizedBox(width: 2),
          IconButton(
            tooltip: 'Quitar',
            icon: Icon(
              Icons.close,
              size: 14,
              color: cs.onSurfaceVariant.withValues(alpha: 0.55),
            ),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: disabled ? null : onRemove,
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final double width;
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _MetricTile({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: cs.surface.withValues(alpha: 0.32),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ts.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ts.bodySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
