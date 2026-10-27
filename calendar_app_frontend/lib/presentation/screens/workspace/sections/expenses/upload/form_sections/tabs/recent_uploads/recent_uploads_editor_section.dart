part of '../recent_uploads_tab.dart';

extension _ExpenseRecentUploadsEditorSection on _ExpenseRecentUploadsTabState {
  Widget _buildEditorOverlay(
    AppLocalizations l,
    AppTypography t,
    ColorScheme cs, {
    bool showHeaderTab = true,
  }) {
    final editing = _latestExpenseSnapshot(_editingExpense!);
    final border = cs.outlineVariant.withValues(alpha: 0.35);
    final panel = Material(
      color: cs.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showHeaderTab)
            SizedBox(
              height: 44,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: border)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Volver',
                        onPressed: _closeExpenseEditor,
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        color: cs.onSurfaceVariant,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints.tightFor(
                            width: 28, height: 28),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Editar gasto',
                        style:
                            t.bodySmall.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final useSplitView = constraints.maxWidth >= 860;
                  if (useSplitView) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 9,
                          child: _buildEditorFormPanel(editing, l, t, cs),
                        ),
                        Container(width: 1, color: border),
                        Expanded(
                          flex: 11,
                          child: _buildEditorPreviewPanel(editing, l, t, cs),
                        ),
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildEditorPanelSwitcher(cs),
                      const SizedBox(height: 8),
                      Expanded(
                        child: IndexedStack(
                          index: _editorPanelIndex,
                          children: [
                            _buildEditorFormPanel(editing, l, t, cs),
                            _buildEditorPreviewPanel(editing, l, t, cs),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
    return panel;
  }

  Widget _buildEditorFormPanel(
    Map<String, String> editing,
    AppLocalizations l,
    AppTypography t,
    ColorScheme cs,
  ) {
    return KeyedSubtree(
      key: const ValueKey('expense-editor-form-panel'),
      child: _ExpenseInlineEditor(
        expenseId: (editing['id'] ?? '').trim(),
        groupId: widget.groupId,
        expensesApi: _expensesApi,
        seedItem: editing,
        availableAdvanceExpenses: widget.recentUploads,
        onPreviewTotalsChanged: (totals) => _editorPreviewTotals.value = totals,
        onSaved: _applyEditedExpense,
        onCancel: _closeExpenseEditor,
      ),
    );
  }

  Widget _buildEditorPreviewPanel(
    Map<String, String> item,
    AppLocalizations l,
    AppTypography t,
    ColorScheme cs,
  ) {
    return ValueListenableBuilder<_ExpensePreviewTotals?>(
      valueListenable: _editorPreviewTotals,
      builder: (context, previewTotals, _) => KeyedSubtree(
        key: const ValueKey('expense-editor-preview-panel'),
        child: _buildPreviewContent(
          item,
          l,
          t,
          cs,
          previewTotals: previewTotals,
        ),
      ),
    );
  }

  Widget _buildEditorPanelSwitcher(ColorScheme cs) {
    Widget option({
      required int index,
      required IconData icon,
      required String label,
    }) {
      final selected = _editorPanelIndex == index;
      return Expanded(
        child: InkWell(
          onTap: () => _setEditorPanelIndex(index),
          borderRadius: BorderRadius.circular(7),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: selected
                  ? cs.primary.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: selected ? cs.primary : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: selected ? cs.primary : cs.onSurfaceVariant,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          option(
            index: 0,
            icon: Icons.edit_note_outlined,
            label: 'Formulario',
          ),
          option(
            index: 1,
            icon: Icons.picture_as_pdf_outlined,
            label: 'Documento',
          ),
        ],
      ),
    );
  }
}

// ── Editor widget ─────────────────────────────────────────────────────────────

class _ExpenseInlineEditor extends StatefulWidget {
  final String expenseId;
  final String groupId;
  final ExpensesApi expensesApi;
  final Map<String, String> seedItem;
  final List<Map<String, String>> availableAdvanceExpenses;
  final ValueChanged<_ExpensePreviewTotals> onPreviewTotalsChanged;
  final ValueChanged<Map<String, String>> onSaved;
  final VoidCallback onCancel;

  const _ExpenseInlineEditor({
    required this.expenseId,
    required this.groupId,
    required this.expensesApi,
    required this.seedItem,
    required this.availableAdvanceExpenses,
    required this.onPreviewTotalsChanged,
    required this.onSaved,
    required this.onCancel,
  });

  @override
  State<_ExpenseInlineEditor> createState() => _ExpenseInlineEditorState();
}

enum _ExpenseEditorTab { general, amounts, lines }

/// A total together with its source.  The editor intentionally keeps these
/// snapshots separate: a stored expense total is not necessarily an OCR total,
/// and neither is necessarily the sum of the editable lines.
class _ExpenseTotalsSnapshot {
  final double? subtotal;
  final double? tax;
  final double? total;

  const _ExpenseTotalsSnapshot({this.subtotal, this.tax, this.total});

  bool get hasValues => subtotal != null || tax != null || total != null;
}

class _ExpensePreviewTotals {
  const _ExpensePreviewTotals({
    required this.storedTotal,
    required this.currentTotal,
    required this.extractedTotal,
    required this.currency,
  });

  final double? storedTotal;
  final double? currentTotal;
  final double? extractedTotal;
  final String currency;
}

class _ExpenseTotalsDifference {
  final String label;
  final double amount;
  final _ExpenseEditorTab targetTab;

  const _ExpenseTotalsDifference({
    required this.label,
    required this.amount,
    required this.targetTab,
  });
}

class _ExpenseInlineEditorState extends State<_ExpenseInlineEditor> {
  final _formKey = GlobalKey<FormState>();
  final _providersApi = ProvidersApi();
  final List<ExpenseLineDraft> _lines = [];
  final _settlement = ExpenseSettlementDraft();
  final _documentDiscount = ExpenseDocumentDiscountDraft();
  final _withholding = ExpenseWithholdingDraft();
  late final TextEditingController _vendorController;
  late final TextEditingController _invoiceController;
  late final TextEditingController _issueDateController;
  late final TextEditingController _dueDateController;
  late final TextEditingController _baseController;
  late final TextEditingController _totalController;
  late final TextEditingController _taxController;
  late final TextEditingController _currencyController;
  late final TextEditingController _notesController;

  bool _loading = true;
  bool _saving = false;
  bool _loadingProviders = false;
  bool _syncingAmounts = false;
  bool _lineEditorEnabled = false;
  bool _useSummaryTotals = false;
  ({String base, String tax, String total})? _summaryTotalsDraft;
  _ExpenseTotalsSnapshot? _storedTotals;
  _ExpenseTotalsSnapshot? _extractedDocumentTotals;
  String? _error;
  _ExpenseEditorTab _activeTab = _ExpenseEditorTab.general;
  final Set<_ExpenseEditorTab> _tabsWithErrors = {};
  List<Map<String, dynamic>> _providers = const [];
  String? _selectedProviderId;
  bool _manualProviderMode = false;

  @override
  void initState() {
    super.initState();
    _vendorController =
        TextEditingController(text: widget.seedItem['vendor'] ?? '');
    _invoiceController =
        TextEditingController(text: widget.seedItem['invoice'] ?? '');
    _issueDateController =
        TextEditingController(text: widget.seedItem['date'] ?? '');
    _dueDateController =
        TextEditingController(text: widget.seedItem['due'] ?? '');
    _baseController = TextEditingController();
    _totalController =
        TextEditingController(text: widget.seedItem['total'] ?? '');
    _taxController = TextEditingController(text: widget.seedItem['tax'] ?? '');
    _currencyController =
        TextEditingController(text: widget.seedItem['currency'] ?? 'EUR');
    _notesController = TextEditingController();
    _totalController.addListener(_syncBaseFromTotalTax);
    _totalController.addListener(_publishPreviewTotals);
    _taxController.addListener(_syncBaseFromTotalTax);
    _baseController.addListener(_syncTotalFromBaseTax);
    _currencyController.addListener(_publishPreviewTotals);
    final seedProviderId = (widget.seedItem['providerId'] ?? '').trim();
    _selectedProviderId = seedProviderId.isEmpty ? null : seedProviderId;
    _manualProviderMode =
        seedProviderId.isEmpty && _vendorController.text.trim().isNotEmpty;
    _syncBaseFromTotalTax();
    _loadProviders();
    _loadExpense();
  }

  @override
  void dispose() {
    _disposeLines();
    _vendorController.dispose();
    _invoiceController.dispose();
    _issueDateController.dispose();
    _dueDateController.dispose();
    _baseController.dispose();
    _totalController.dispose();
    _taxController.dispose();
    _currencyController.dispose();
    _notesController.dispose();
    _settlement.dispose();
    _documentDiscount.dispose();
    _withholding.dispose();
    super.dispose();
  }

  void _disposeLines() {
    for (final line in _lines) {
      line.dispose();
    }
    _lines.clear();
  }

  bool get _hasEditableLines => _lineEditorEnabled && _lines.isNotEmpty;

  void _addLine() {
    setState(() {
      _lineEditorEnabled = true;
      _lines.add(ExpenseLineDraft());
      _syncControllersFromLines();
    });
  }

  void _removeLine(int index) {
    final line = _lines.removeAt(index);
    line.dispose();
    setState(() {
      _lineEditorEnabled = true;
      _syncControllersFromLines();
    });
  }

  double _linesSubtotal() =>
      _lines.fold<double>(0, (sum, line) => sum + line.subtotal);
  double _linesTax() =>
      _lines.fold<double>(0, (sum, line) => sum + line.taxAmount);
  double _linesTotal() => _linesSubtotal() + _linesTax();

  double? _parseAmount(TextEditingController controller) {
    return ExpenseFormHelpers.parseAmount(controller.text);
  }

  void _setFormattedAmount(TextEditingController controller, double value) {
    final formatted = value.toStringAsFixed(2);
    if (controller.text != formatted) {
      controller.text = formatted;
    }
  }

  void _syncSummaryControllers(_ExpenseEditorDocumentTotalField changedField) {
    if (_syncingAmounts) return;
    final base = _parseAmount(_baseController);
    final tax = _parseAmount(_taxController) ?? 0;
    final total = _parseAmount(_totalController);

    _syncingAmounts = true;
    if (changedField == _ExpenseEditorDocumentTotalField.total ||
        (changedField == _ExpenseEditorDocumentTotalField.tax &&
            (base == null || base < 0) &&
            total != null)) {
      if (total != null) {
        _setFormattedAmount(
          _baseController,
          (total - tax).clamp(0, double.infinity).toDouble(),
        );
      }
    } else if (base != null) {
      _setFormattedAmount(
        _totalController,
        (base + tax).clamp(0, double.infinity).toDouble(),
      );
    }
    _syncingAmounts = false;
  }

  String? _summaryTotalsValidationError() {
    if (!_useSummaryTotals) return null;
    return ExpenseFormHelpers.validateSummaryTotals(
      base: _parseAmount(_baseController),
      tax: _parseAmount(_taxController),
      total: _parseAmount(_totalController),
    );
  }

  ExpenseDocumentDiscountPreview? _documentDiscountPreview() {
    if (_useSummaryTotals) {
      final finalBase = _parseAmount(_baseController);
      final finalTax = _parseAmount(_taxController) ?? 0;
      if (finalBase == null) return null;
      final grossBase = _documentDiscount.grossBaseFromFinal(finalBase);
      final grossTax = _documentDiscount.grossTaxFromFinal(
        finalBase: finalBase,
        finalTax: finalTax,
      );
      _documentDiscount.syncDerivedFields(grossBase);
      return _documentDiscount.buildPreview(
        subtotalBeforeDiscount: grossBase,
        taxBeforeDiscount: grossTax,
      );
    }
    if (_hasEditableLines) {
      final subtotal = _linesSubtotal();
      final tax = _linesTax();
      _documentDiscount.syncDerivedFields(subtotal);
      return _documentDiscount.buildPreview(
        subtotalBeforeDiscount: subtotal,
        taxBeforeDiscount: tax,
      );
    }
    final finalBase = double.tryParse(_baseAmountDisplay());
    final finalTax =
        double.tryParse(_normalizedDecimalOrNull(_taxController.text) ?? '');
    if (finalBase == null) return null;
    final grossBase = _documentDiscount.grossBaseFromFinal(finalBase);
    final grossTax = _documentDiscount.grossTaxFromFinal(
      finalBase: finalBase,
      finalTax: finalTax ?? 0,
    );
    _documentDiscount.syncDerivedFields(grossBase);
    return _documentDiscount.buildPreview(
      subtotalBeforeDiscount: grossBase,
      taxBeforeDiscount: grossTax,
    );
  }

  void _syncControllersFromLines() {
    if (!_hasEditableLines || _useSummaryTotals) return;
    final preview = _documentDiscountPreview();
    _syncingAmounts = true;
    _baseController.text =
        (preview?.taxableBase ?? _linesSubtotal()).toStringAsFixed(2);
    _taxController.text = (preview?.tax ?? _linesTax()).toStringAsFixed(2);
    _totalController.text =
        (preview?.total ?? _linesTotal()).toStringAsFixed(2);
    _syncingAmounts = false;
  }

  bool _validateLines() {
    for (final line in _lines) {
      if (line.descriptionController.text.trim().isEmpty) {
        _showTabError(
          _ExpenseEditorTab.lines,
          'La descripción de la línea es obligatoria.',
        );
        return false;
      }
      if (line.quantity <= 0) {
        _showTabError(
          _ExpenseEditorTab.lines,
          'La cantidad debe ser mayor que cero.',
        );
        return false;
      }
      if (line.baseUnitPrice < 0) {
        _showTabError(
          _ExpenseEditorTab.lines,
          'El precio base no puede ser negativo.',
        );
        return false;
      }
      if (line.discountPercent < 0 || line.discountPercent > 100) {
        _showTabError(
          _ExpenseEditorTab.lines,
          'El descuento % debe estar entre 0 y 100.',
        );
        return false;
      }
      if (line.discountAmount < 0 ||
          line.discountAmount > line.grossSubtotal + 0.0001) {
        _showTabError(
          _ExpenseEditorTab.lines,
          'El descuento no puede superar el importe bruto de la línea.',
        );
        return false;
      }
    }
    return true;
  }

  List<ExpenseAdvanceOption> _advanceOptions() {
    final currentExpenseId = widget.expenseId.trim();
    final selectedProvider = (_selectedProviderId ?? '').trim().toLowerCase();
    final selectedVendor = _vendorController.text.trim().toLowerCase();
    final options = <ExpenseAdvanceOption>[];

    for (final item in widget.availableAdvanceExpenses) {
      final type = ExpenseDocumentTypeX.fromApi(item['expenseType']);
      if (!type.isAdvance) continue;
      final itemId = (item['id'] ?? '').trim();
      if (itemId.isEmpty || itemId == currentExpenseId) continue;

      final itemProvider = (item['providerId'] ?? '').trim().toLowerCase();
      final itemVendor =
          ((item['vendor'] ?? item['providerName'] ?? '')).trim().toLowerCase();
      final matchesProvider =
          selectedProvider.isNotEmpty && itemProvider == selectedProvider;
      final matchesVendor = selectedProvider.isEmpty &&
          selectedVendor.isNotEmpty &&
          itemVendor == selectedVendor;
      final canUse = selectedProvider.isEmpty && selectedVendor.isEmpty
          ? true
          : (matchesProvider || matchesVendor);
      if (!canUse) continue;

      options.add(ExpenseAdvanceOption.fromRecentMap(item));
    }

    options.sort((a, b) {
      final aDate = DateTime.tryParse(a.issueDate);
      final bDate = DateTime.tryParse(b.issueDate);
      if (aDate != null && bDate != null) {
        return bDate.compareTo(aDate);
      }
      return b.issueDate.compareTo(a.issueDate);
    });
    return options;
  }

  Future<void> _loadExpense() async {
    setState(() {
      _loading = true;
      _error = null;
      _activeTab = _ExpenseEditorTab.general;
      _tabsWithErrors.clear();
      _summaryTotalsDraft = null;
    });
    try {
      final data = await widget.expensesApi.fetchExpense(widget.expenseId);
      if (!mounted) return;
      final subtotalNum = ExpenseFormHelpers.parseNum(data['subtotal']);
      final totalNum = ExpenseFormHelpers.parseNum(data['total']) ?? 0;
      final taxNum = ExpenseFormHelpers.parseNum(data['taxTotal']) ?? 0;
      _storedTotals = _ExpenseTotalsSnapshot(
        subtotal: subtotalNum,
        tax: ExpenseFormHelpers.parseNum(data['taxTotal']),
        total: ExpenseFormHelpers.parseNum(data['total']),
      );
      _extractedDocumentTotals = _readExplicitExtractedTotals(data);
      _vendorController.text =
          (data['vendorName'] ?? data['vendor'] ?? '').toString();
      _invoiceController.text = (data['invoiceNumber'] ?? '').toString();
      _issueDateController.text = (data['issueDate'] ?? '').toString();
      _dueDateController.text = (data['dueDate'] ?? '').toString();
      _totalController.text = (data['total'] ?? '').toString();
      _taxController.text = (data['taxTotal'] ?? '').toString();
      _baseController.text = subtotalNum?.toStringAsFixed(2) ??
          (totalNum - taxNum).clamp(0, double.infinity).toStringAsFixed(2);
      _currencyController.text = (data['currency'] ?? 'EUR').toString();
      _notesController.text = (data['notes'] ?? '').toString();
      _settlement.loadFromExpenseMap(data);
      final rawLines = data['lines'] is List
          ? data['lines']
          : data['items'] is List
              ? data['items']
              : null;
      _disposeLines();
      _lineEditorEnabled = rawLines is List;
      if (rawLines is List) {
        for (final entry in rawLines) {
          if (entry is Map) {
            _lines.add(
                ExpenseLineDraft.fromMap(Map<String, dynamic>.from(entry)));
          }
        }
      }
      final loadedLines = rawLines is List
          ? rawLines
              .whereType<Map>()
              .map((entry) => Map<String, dynamic>.from(entry))
              .toList(growable: false)
          : const <Map<String, dynamic>>[];
      _useSummaryTotals = ExpenseFormHelpers.shouldUseSummaryTotals(
        expense: data,
        storedTotal: totalNum.toDouble(),
        storedTax: taxNum.toDouble(),
        lines: loadedLines,
      );
      final baseHint = subtotalNum?.toDouble() ??
          (_lineEditorEnabled && !_useSummaryTotals
              ? _linesSubtotal()
              : (totalNum - taxNum).clamp(0, double.infinity).toDouble());
      _documentDiscount.loadFromExpenseMap(
        data,
        subtotalBeforeDiscountHint: baseHint,
      );
      _withholding.loadFromExpenseMap(data, taxableBaseHint: baseHint);
      if (_hasEditableLines && !_useSummaryTotals) {
        _syncControllersFromLines();
      } else if (_baseController.text.trim().isEmpty) {
        _syncSummaryControllers(_ExpenseEditorDocumentTotalField.total);
      }
      final providerId = (data['providerId'] ??
              data['provider']?['id'] ??
              data['provider']?['_id'] ??
              data['provider']?['providerId'])
          ?.toString()
          .trim();
      _selectedProviderId = (providerId ?? '').isEmpty ? null : providerId;
      _manualProviderMode = _selectedProviderId == null &&
          _vendorController.text.trim().isNotEmpty;
      _publishPreviewTotals();
    } on ExpensesApiException catch (e) {
      if (!mounted) return;
      _error = e.message;
    } catch (e) {
      if (!mounted) return;
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  _ExpenseTotalsSnapshot? _readExplicitExtractedTotals(
    Map<String, dynamic> expense,
  ) {
    // Only use an explicitly separated extraction payload.  A stored total can
    // originate from OCR, a later manual correction, or an import; treating it
    // as an OCR value here would make reconciliation misleading.
    Map? source;
    for (final key in const [
      'extractedTotals',
      'ocrTotals',
      'documentTotals',
      'extractionTotals',
    ]) {
      final value = expense[key];
      if (value is Map) {
        source = value;
        break;
      }
    }
    if (source == null) return null;
    final snapshot = _ExpenseTotalsSnapshot(
      subtotal: ExpenseFormHelpers.parseNum(
        source['subtotal'] ?? source['base'] ?? source['baseImponible'],
      ),
      tax: ExpenseFormHelpers.parseNum(
        source['taxTotal'] ??
            source['vatTotal'] ??
            source['tax'] ??
            source['iva'],
      ),
      total: ExpenseFormHelpers.parseNum(
        source['total'] ?? source['documentTotal'] ?? source['amount'],
      ),
    );
    return snapshot.hasValues ? snapshot : null;
  }

  Future<void> _loadProviders() async {
    setState(() => _loadingProviders = true);
    try {
      final items = await _providersApi.list(
        groupId: widget.groupId.trim().isEmpty ? null : widget.groupId.trim(),
      );
      if (!mounted) return;
      setState(() => _providers = items);
    } catch (_) {
      if (!mounted) return;
      setState(() => _providers = const []);
    } finally {
      if (mounted) setState(() => _loadingProviders = false);
    }
  }

  String _providerId(Map<String, dynamic> p) =>
      (p['id'] ?? p['_id'] ?? p['providerId'] ?? '').toString();

  String _providerName(Map<String, dynamic> p) =>
      (p['name'] ?? p['providerName'] ?? p['vendorName'] ?? '-').toString();

  String _selectedProviderName() {
    final id = (_selectedProviderId ?? '').trim();
    if (id.isEmpty) return '';
    final provider = _providers.cast<Map<String, dynamic>?>().firstWhere(
          (p) => (p == null ? '' : _providerId(p)) == id,
          orElse: () => null,
        );
    if (provider == null) return '';
    return _providerName(provider);
  }

  String? _normalizedDateOrNull(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    final iso = DateTime.tryParse(value);
    if (iso != null) {
      final y = iso.year.toString().padLeft(4, '0');
      final m = iso.month.toString().padLeft(2, '0');
      final d = iso.day.toString().padLeft(2, '0');
      return '$y-$m-$d';
    }
    return value;
  }

  String? _normalizedDecimalOrNull(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    final normalized = normalizeMoneyInput(value);
    final parsed = double.tryParse(normalized);
    if (parsed == null) return normalized;
    return parsed.toString();
  }

  String _baseAmountDisplay() {
    final total = _normalizedDecimalOrNull(_totalController.text);
    final tax = _normalizedDecimalOrNull(_taxController.text);
    if (total == null || tax == null) return '';
    final totalNum = double.tryParse(total);
    final taxNum = double.tryParse(tax);
    if (totalNum == null || taxNum == null) return '';
    return (totalNum - taxNum).toStringAsFixed(2);
  }

  void _syncBaseFromTotalTax() {
    if (_syncingAmounts || _hasEditableLines) return;
    _syncingAmounts = true;
    _baseController.text = _baseAmountDisplay();
    _syncingAmounts = false;
  }

  void _syncTotalFromBaseTax() {
    if (_syncingAmounts || _hasEditableLines) return;
    final base = _normalizedDecimalOrNull(_baseController.text);
    final tax = _normalizedDecimalOrNull(_taxController.text);
    final baseNum = base == null ? null : double.tryParse(base);
    final taxNum = tax == null ? 0.0 : double.tryParse(tax);
    if (baseNum == null) return;
    _syncingAmounts = true;
    _totalController.text = (baseNum + (taxNum ?? 0.0)).toStringAsFixed(2);
    _syncingAmounts = false;
  }

  Future<void> _pickDate(TextEditingController ctrl) async {
    DateTime initial = DateTime.now();
    final existing = DateTime.tryParse(ctrl.text.trim());
    if (existing != null) initial = existing;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() {
        ctrl.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _tabsWithErrors.clear();
      _error = null;
    });
    if (_vendorController.text.trim().isEmpty) {
      _showTabError(
        _ExpenseEditorTab.general,
        'Selecciona o introduce un proveedor.',
      );
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) {
      _showTabError(
        _ExpenseEditorTab.general,
        'Revisa los campos obligatorios.',
      );
      return;
    }
    if (!_validateLines()) return;
    final settlementError = _settlement.validate();
    if (settlementError != null) {
      _showTabError(_ExpenseEditorTab.general, settlementError);
      return;
    }
    final summaryTotalsError = _summaryTotalsValidationError();
    if (summaryTotalsError != null) {
      _showTabError(_ExpenseEditorTab.amounts, summaryTotalsError);
      return;
    }
    final discountPreview = _documentDiscountPreview();
    final discountValidationBase = discountPreview?.subtotalBeforeDiscount ??
        double.tryParse(_baseAmountDisplay()) ??
        0;
    final discountError = _documentDiscount.validate(discountValidationBase);
    if (discountError != null) {
      _showTabError(_ExpenseEditorTab.amounts, discountError);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    if (_hasEditableLines && !_useSummaryTotals) _syncControllersFromLines();
    final totalNumber = ExpenseFormHelpers.parseAmount(_totalController.text);
    final taxTotalNumber = ExpenseFormHelpers.parseAmount(_taxController.text);
    final subtotalNumber = ExpenseFormHelpers.parseAmount(_baseController.text);
    final issueDate = _normalizedDateOrNull(_issueDateController.text);
    final dueDate = _normalizedDateOrNull(_dueDateController.text);
    final linesPayload = (_lineEditorEnabled && !_useSummaryTotals)
        ? (ExpenseFormHelpers.buildLinesPayload(_lines) ??
            <Map<String, dynamic>>[])
        : null;
    final localLinesSummary = _lines.isNotEmpty
        ? ExpenseFormHelpers.summarizeLines(
            ExpenseFormHelpers.buildLinesPayload(_lines) ??
                const <Map<String, dynamic>>[],
          )
        : const <String, dynamic>{};
    final payload = <String, dynamic>{
      'vendorName': _vendorController.text.trim(),
      'invoiceNumber': _invoiceController.text.trim(),
      if (issueDate != null) 'issueDate': issueDate,
      if (dueDate != null) 'dueDate': dueDate,
      if (subtotalNumber != null) 'subtotal': subtotalNumber,
      if (totalNumber != null) 'total': totalNumber,
      if (taxTotalNumber != null) 'taxTotal': taxTotalNumber,
      'currency': _currencyController.text.trim().toUpperCase(),
      'notes': _notesController.text.trim(),
      if ((_selectedProviderId ?? '').trim().isNotEmpty)
        'providerId': _selectedProviderId!.trim(),
      if (linesPayload != null) 'lines': linesPayload,
    };
    if (_useSummaryTotals) {
      final summaryVatBreakdown = ExpenseFormHelpers.buildSummaryVatBreakdown(
        base: subtotalNumber,
        tax: taxTotalNumber,
      );
      if (summaryVatBreakdown != null) {
        payload['vatBreakdown'] = summaryVatBreakdown;
      }
      payload['useSummaryTotals'] = true;
      payload['taxSource'] = 'summary';
    }
    _settlement.applyToExpensePayload(payload);
    _documentDiscount.applyToExpensePayload(payload);
    final grossTotal = double.tryParse(_totalController.text.trim()) ?? 0;
    final taxableBase = double.tryParse(_baseController.text.trim()) ?? 0;
    _withholding.applyToExpensePayload(
      payload,
      taxableBase: taxableBase,
      grossTotal: grossTotal,
    );
    try {
      final updated = await widget.expensesApi
          .updateExpense(id: widget.expenseId, payload: payload);
      final providerName = _selectedProviderName();
      final updatedLinesRaw = updated['lines'] is List
          ? updated['lines']
          : updated['items'] is List
              ? updated['items']
              : linesPayload;
      final updatedLines = updatedLinesRaw is List
          ? updatedLinesRaw
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList(growable: false)
          : const <Map<String, dynamic>>[];
      final updatedLinesSummary = updatedLines.isNotEmpty
          ? ExpenseFormHelpers.summarizeLines(updatedLines)
          : localLinesSummary;
      final updatedLinesCount = updatedLinesSummary['count'] as int? ?? 0;
      final responseUseSummaryTotals =
          ExpenseFormHelpers.shouldUseSummaryTotals(
        expense: updated,
        storedTotal: ExpenseFormHelpers.parseNum(updated['total'])?.toDouble(),
        storedTax: ExpenseFormHelpers.parseNum(
          updated['taxTotal'] ?? updated['vatTotal'] ?? updated['tax'],
        )?.toDouble(),
        lines: updated['lines'] is List
            ? (updated['lines'] as List)
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList(growable: false)
            : updated['items'] is List
                ? (updated['items'] as List)
                    .whereType<Map>()
                    .map((e) => Map<String, dynamic>.from(e))
                    .toList(growable: false)
                : null,
      );
      if (!mounted) return;
      widget.onSaved(<String, String>{
        ...widget.seedItem,
        'id': widget.expenseId,
        'vendor': (updated['vendorName'] ??
                updated['vendor'] ??
                _vendorController.text)
            .toString(),
        'invoice':
            (updated['invoiceNumber'] ?? _invoiceController.text).toString(),
        'date': (updated['issueDate'] ?? _issueDateController.text).toString(),
        'due': (updated['dueDate'] ?? _dueDateController.text).toString(),
        'subtotal': (updated['subtotal'] ?? _baseController.text).toString(),
        'total': (updated['total'] ?? _totalController.text).toString(),
        'tax': (updated['taxTotal'] ?? _taxController.text).toString(),
        'taxSource':
            (updated['taxSource'] ?? updated['totalsSource'] ?? '').toString(),
        'currency':
            (updated['currency'] ?? _currencyController.text).toString(),
        'notes': (updated['notes'] ?? _notesController.text).toString(),
        'providerId':
            (updated['providerId'] ?? _selectedProviderId ?? '').toString(),
        'discountAmount':
            (updated['discountAmount'] ?? payload['discountAmount'] ?? '')
                .toString(),
        'discountPercent':
            (updated['discountPercent'] ?? payload['discountPercent'] ?? '')
                .toString(),
        'providerName': (updated['provider']?['name'] ??
                updated['providerName'] ??
                providerName)
            .toString(),
        'expenseType':
            (updated['expenseType'] ?? payload['expenseType'] ?? '').toString(),
        'advancePercent': ((updated['advancePayment']?['percent'] ??
                    payload['advancePayment']?['percent']) ??
                '')
            .toString(),
        'advanceProjectBaseAmount': ((updated['advancePayment']
                        ?['projectBaseAmount'] ??
                    payload['advancePayment']?['projectBaseAmount']) ??
                '')
            .toString(),
        'advanceTaxRate': ((updated['advancePayment']?['taxRate'] ??
                    payload['advancePayment']?['taxRate']) ??
                '')
            .toString(),
        'finalAdvanceExpenseId': ((updated['finalSettlement']
                        ?['advanceExpenseId'] ??
                    payload['finalSettlement']?['advanceExpenseId']) ??
                '')
            .toString(),
        'finalAdvanceInvoiceNumber':
            (updated['finalSettlement']?['advanceInvoiceNumber'] ?? '')
                .toString(),
        'settlementDeductedBase':
            (updated['finalSettlement']?['deductedBase'] ?? '').toString(),
        'settlementDeductedTax':
            (updated['finalSettlement']?['deductedTax'] ?? '').toString(),
        'settlementDeductedTotal':
            (updated['finalSettlement']?['deductedTotal'] ?? '').toString(),
        'settlementGrossBase':
            (updated['finalSettlement']?['grossBase'] ?? '').toString(),
        'settlementGrossTax':
            (updated['finalSettlement']?['grossTax'] ?? '').toString(),
        'settlementGrossTotal':
            (updated['finalSettlement']?['grossTotal'] ?? '').toString(),
        'settlementRemainingBase':
            (updated['finalSettlement']?['remainingBase'] ?? '').toString(),
        'settlementRemainingTax':
            (updated['finalSettlement']?['remainingTax'] ?? '').toString(),
        'settlementRemainingTotal':
            (updated['finalSettlement']?['remainingTotal'] ?? '').toString(),
        'linesCount': updatedLinesCount > 0 ? updatedLinesCount.toString() : '',
        'linesSummary': (updatedLinesSummary['summary'] ?? '').toString(),
        'linesSubtotal': responseUseSummaryTotals
            ? (updated['subtotal'] ?? _baseController.text.trim()).toString()
            : updatedLinesCount > 0
                ? ((updatedLinesSummary['subtotal'] as num?) ?? 0)
                    .toDouble()
                    .toStringAsFixed(2)
                : '',
        'linesTotal': responseUseSummaryTotals
            ? (updated['total'] ?? _totalController.text.trim()).toString()
            : updatedLinesCount > 0
                ? ((updatedLinesSummary['total'] as num?) ?? 0)
                    .toDouble()
                    .toStringAsFixed(2)
                : '',
        'useSummaryTotals': responseUseSummaryTotals ? 'true' : 'false',
      });
    } on ExpensesApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void didUpdateWidget(covariant _ExpenseInlineEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expenseId != widget.expenseId) _loadExpense();
  }

  void _showTabError(_ExpenseEditorTab tab, String message) {
    setState(() {
      _activeTab = tab;
      _tabsWithErrors.add(tab);
      _error = message;
    });
  }

  double _currentTotal() {
    return ExpenseFormHelpers.parseAmount(_totalController.text) ??
        (_hasEditableLines ? _linesTotal() : 0);
  }

  void _publishPreviewTotals() {
    widget.onPreviewTotalsChanged(
      _ExpensePreviewTotals(
        storedTotal: _storedTotals?.total,
        currentTotal: _currentTotal(),
        extractedTotal: _extractedDocumentTotals?.total,
        currency: _currencyLabel(),
      ),
    );
  }

  ExpenseDocumentDiscountPreview? _lineFinancialPreview() {
    if (!_hasEditableLines) return null;
    return _documentDiscount.buildPreview(
      subtotalBeforeDiscount: _linesSubtotal(),
      taxBeforeDiscount: _linesTax(),
    );
  }

  ExpenseWithholdingPreview _withholdingPreview(
    ExpenseDocumentDiscountPreview? financialPreview,
  ) {
    return _withholding.buildPreview(
      taxableBase:
          financialPreview?.taxableBase ?? _parseAmount(_baseController) ?? 0,
      grossTotal:
          financialPreview?.total ?? _parseAmount(_totalController) ?? 0,
    );
  }

  _ExpenseTotalsSnapshot _activeTotals(
    ExpenseDocumentDiscountPreview preview,
  ) =>
      _ExpenseTotalsSnapshot(
        subtotal: preview.subtotalBeforeDiscount,
        tax: preview.tax,
        total: preview.total,
      );

  List<_ExpenseTotalsDifference> _reconciliationDifferences(
    _ExpenseTotalsSnapshot active,
    _ExpenseTotalsSnapshot? lineTotals,
  ) {
    final differences = <_ExpenseTotalsDifference>[];
    void compare({
      required String label,
      required _ExpenseTotalsSnapshot? other,
      required _ExpenseEditorTab targetTab,
    }) {
      final activeTotal = active.total;
      final otherTotal = other?.total;
      if (activeTotal == null || otherTotal == null) return;
      final difference = activeTotal - otherTotal;
      if (difference.abs() <= ExpenseFormHelpers.summaryTotalsTolerance) {
        return;
      }
      differences.add(_ExpenseTotalsDifference(
        label: label,
        amount: difference,
        targetTab: targetTab,
      ));
    }

    compare(
      label: 'Total actual frente a líneas',
      other: lineTotals,
      targetTab: _ExpenseEditorTab.lines,
    );
    compare(
      label: 'Total actual frente a OCR',
      other: _extractedDocumentTotals,
      targetTab: _ExpenseEditorTab.amounts,
    );
    return differences;
  }

  String _currencyLabel() {
    final currency = _currencyController.text.trim().toUpperCase();
    return currency.isEmpty ? 'EUR' : currency;
  }

  Widget _buildTabBar(ColorScheme cs, TextTheme ts) {
    Widget tab({
      required _ExpenseEditorTab value,
      required IconData icon,
      required String label,
    }) {
      final selected = _activeTab == value;
      final hasError = _tabsWithErrors.contains(value);
      return Expanded(
        child: Semantics(
          button: true,
          selected: selected,
          child: InkWell(
            key: ValueKey('expense-editor-tab-${value.name}'),
            onTap: () => setState(() => _activeTab = value),
            borderRadius: BorderRadius.circular(7),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: selected
                    ? cs.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                border: selected
                    ? Border.all(color: cs.primary.withValues(alpha: 0.55))
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    hasError ? Icons.error_outline_rounded : icon,
                    size: 15,
                    color: hasError
                        ? cs.error
                        : selected
                            ? cs.primary
                            : cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ts.labelMedium?.copyWith(
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w600,
                        color: hasError
                            ? cs.error
                            : selected
                                ? cs.primary
                                : cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          tab(
            value: _ExpenseEditorTab.general,
            icon: Icons.receipt_long_outlined,
            label: 'General',
          ),
          tab(
            value: _ExpenseEditorTab.amounts,
            icon: Icons.calculate_outlined,
            label: 'Importes',
          ),
          tab(
            value: _ExpenseEditorTab.lines,
            icon: Icons.list_alt_outlined,
            label: 'Líneas (${_lines.length})',
          ),
        ],
      ),
    );
  }

  Widget _buildErrorStrip(ColorScheme cs) {
    if ((_error ?? '').isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 6, 0, 0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: cs.errorContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 14, color: cs.error),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _error!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: cs.error, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyFooter(AppLocalizations l, ColorScheme cs) {
    return Container(
      key: const ValueKey('expense-editor-sticky-footer'),
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.fromLTRB(16, 7, 16, 7),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.45)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Text(
                  'Total',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '${ExpenseFormHelpers.formatAmount(_currentTotal())} ${_currencyController.text.trim().toUpperCase() == 'EUR' || _currencyController.text.trim().isEmpty ? '€' : _currencyController.text.trim().toUpperCase()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: _saving ? null : widget.onCancel,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 36),
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(l.cancel),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 36),
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: _saving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined, size: 16),
            label: Text(_saving ? 'Guardando…' : 'Guardar cambios'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Form(
        key: _formKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 400;
            const gap = SizedBox(height: 8);
            const hGap = SizedBox(width: 8);
            const sectionGap = SizedBox(height: 14);

            Widget row(List<Widget> children) {
              if (!wide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < children.length; i++) ...[
                      if (i > 0) gap,
                      children[i],
                    ],
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < children.length; i++) ...[
                    if (i > 0) hGap,
                    Expanded(child: children[i]),
                  ],
                ],
              );
            }

            Widget sectionLabel(String text, IconData icon) => Padding(
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
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.55),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                );

            final linesEditor = ExpenseLinesEditor(
              lines: _lines,
              onAddLine: _addLine,
              onRemoveLine: _removeLine,
              compactWorkspace: true,
              onLinesChanged: () {
                setState(() {
                  _lineEditorEnabled = true;
                  _tabsWithErrors.remove(_ExpenseEditorTab.lines);
                  _syncControllersFromLines();
                });
              },
            );
            final settlementFields = ExpenseSettlementFields(
              settlement: _settlement,
              advanceOptions: _advanceOptions(),
              enabled: !_saving,
              onTypeChanged: (type) => setState(() {
                _settlement.setExpenseType(type);
              }),
              onAdvanceExpenseChanged: (id) => setState(() {
                _settlement.selectedAdvanceExpenseId = id;
              }),
              onChanged: () => setState(() {}),
            );
            final financialPreview = _documentDiscountPreview();
            final displayedFinancialPreview = financialPreview ??
                const ExpenseDocumentDiscountPreview(
                  subtotalBeforeDiscount: 0,
                  discountAmount: 0,
                  discountPercent: 0,
                  taxableBase: 0,
                  tax: 0,
                  total: 0,
                );
            final withholdingPreview = _withholdingPreview(financialPreview);
            final lineFinancialPreview = _lineFinancialPreview();
            final lineTotals = lineFinancialPreview == null
                ? null
                : _ExpenseTotalsSnapshot(
                    subtotal: lineFinancialPreview.subtotalBeforeDiscount,
                    tax: lineFinancialPreview.tax,
                    total: lineFinancialPreview.total,
                  );
            final reconciliationDifferences = _reconciliationDifferences(
              _activeTotals(displayedFinancialPreview),
              lineTotals,
            );
            final documentDiscountFields = ExpenseDocumentDiscountFields(
              discount: _documentDiscount,
              enabled: !_saving,
              preview: financialPreview,
              compactSummary: true,
              showPreview: false,
              onChanged: () => setState(() {
                if (_hasEditableLines && !_useSummaryTotals) {
                  _syncControllersFromLines();
                }
              }),
            );
            final totalsFields = ExpenseDocumentTotalsFields(
              baseController: _baseController,
              taxController: _taxController,
              totalController: _totalController,
              enabled: !_saving,
              useSummaryTotals: _useSummaryTotals,
              lockToLines: _hasEditableLines,
              validationError: _summaryTotalsValidationError(),
              financialSummary: _ExpenseFinancialSummary(
                preview: displayedFinancialPreview,
                withholding: withholdingPreview,
                currency: _currencyLabel(),
                storedTotals: _storedTotals,
                extractedDocumentTotals: _extractedDocumentTotals,
                lineTotals: lineTotals,
                differences: reconciliationDifferences,
                onReviewDifference: (difference) => setState(
                  () => _activeTab = difference.targetTab,
                ),
              ),
              onSummaryModeChanged: (value) => setState(() {
                if (!value) {
                  _summaryTotalsDraft = (
                    base: _baseController.text,
                    tax: _taxController.text,
                    total: _totalController.text,
                  );
                }
                _useSummaryTotals = value;
                if (!_useSummaryTotals && _hasEditableLines) {
                  _syncControllersFromLines();
                } else if (_useSummaryTotals) {
                  final saved = _summaryTotalsDraft;
                  if (saved != null) {
                    _syncingAmounts = true;
                    _baseController.text = saved.base;
                    _taxController.text = saved.tax;
                    _totalController.text = saved.total;
                    _syncingAmounts = false;
                  } else {
                    _syncSummaryControllers(
                        _ExpenseEditorDocumentTotalField.total);
                  }
                }
              }),
              onBaseChanged: (_) {
                _syncSummaryControllers(_ExpenseEditorDocumentTotalField.base);
                setState(() {});
              },
              onTaxChanged: (_) {
                _syncSummaryControllers(_ExpenseEditorDocumentTotalField.tax);
                setState(() {});
              },
              onTotalChanged: (_) {
                _syncSummaryControllers(_ExpenseEditorDocumentTotalField.total);
                setState(() {});
              },
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTabBar(cs, ts),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    key: ValueKey('expense-editor-${_activeTab.name}-content'),
                    padding: const EdgeInsets.only(bottom: 76),
                    children: [
                      // ── Proveedor ──────────────────────────────────────
                      if (_activeTab == _ExpenseEditorTab.general) ...[
                        sectionLabel(l.expenseUploadVendorLabel,
                            Icons.business_outlined),
                        ExpenseProviderPicker(
                          providers: _providers,
                          selectedProviderId: _selectedProviderId,
                          providersError: null,
                          loading: _loadingProviders,
                          manualMode: _manualProviderMode,
                          onSelectProvider: (id) {
                            setState(() {
                              _selectedProviderId = id;
                              _manualProviderMode = false;
                              _tabsWithErrors.remove(_ExpenseEditorTab.general);
                            });
                            if (id == null) return;
                            final provider = _providers.firstWhere(
                              (p) => _providerId(p) == id,
                              orElse: () => const <String, dynamic>{},
                            );
                            final name = _providerName(provider);
                            if (name.isNotEmpty && name != '-') {
                              _vendorController.text = name;
                            }
                          },
                          onManualMode: () => setState(() {
                            _selectedProviderId = null;
                            _manualProviderMode = true;
                            _tabsWithErrors.remove(_ExpenseEditorTab.general);
                          }),
                        ),
                        if (_manualProviderMode) ...[
                          gap,
                          _field(
                            _vendorController,
                            l.expenseUploadVendorLabel,
                            icon: Icons.storefront_outlined,
                            required: true,
                            cs: cs,
                          ),
                        ],
                        sectionGap,

                        // ── Factura ────────────────────────────────────────
                        sectionLabel('Datos del gasto', Icons.receipt_outlined),
                        row([
                          _field(
                            _invoiceController,
                            l.expenseUploadInvoiceNumberLabel,
                            icon: Icons.tag_outlined,
                            cs: cs,
                          ),
                          _field(
                            _currencyController,
                            l.expenseUploadCurrencyLabel,
                            icon: Icons.euro_outlined,
                            onChanged: (_) => setState(() {}),
                            cs: cs,
                          ),
                        ]),
                        gap,
                        row([
                          _dateField(
                            _issueDateController,
                            l.expenseUploadIssueDateLabel,
                            cs: cs,
                          ),
                          _dateField(
                            _dueDateController,
                            l.expenseUploadDueDateLabel,
                            cs: cs,
                          ),
                        ]),
                        sectionGap,

                        // ── Importes ───────────────────────────────────────
                        sectionLabel('Tipo de gasto', Icons.tune_outlined),
                        settlementFields,
                        sectionGap,
                      ],

                      if (_activeTab == _ExpenseEditorTab.amounts) ...[
                        documentDiscountFields,
                        const SizedBox(height: 6),
                        ExpenseDocumentWithholdingFields(
                          withholding: _withholding,
                          enabled: !_saving,
                          compactSummary: true,
                          showPreview: false,
                          dense: true,
                          preview: withholdingPreview,
                          onChanged: () => setState(() {}),
                        ),
                        const SizedBox(height: 10),
                        totalsFields,
                        const SizedBox(height: 8),
                      ],

                      // ── Notas ──────────────────────────────────────────
                      if (_activeTab == _ExpenseEditorTab.general) ...[
                        sectionLabel(
                            l.expenseUploadNotesLabel, Icons.notes_outlined),
                        _field(
                          _notesController,
                          l.expenseUploadNotesLabel,
                          icon: Icons.notes_outlined,
                          maxLines: 2,
                          cs: cs,
                        ),
                        sectionGap,
                      ],

                      // ── Líneas ─────────────────────────────────────────
                      if (_activeTab == _ExpenseEditorTab.lines) linesEditor,

                      // ── Error ──────────────────────────────────────────
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                _buildErrorStrip(cs),
                _buildStickyFooter(l, cs),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Field helpers ─────────────────────────────────────────────────────────────

class _ExpenseFinancialSummary extends StatelessWidget {
  final ExpenseDocumentDiscountPreview preview;
  final ExpenseWithholdingPreview withholding;
  final String currency;
  final _ExpenseTotalsSnapshot? storedTotals;
  final _ExpenseTotalsSnapshot? extractedDocumentTotals;
  final _ExpenseTotalsSnapshot? lineTotals;
  final List<_ExpenseTotalsDifference> differences;
  final ValueChanged<_ExpenseTotalsDifference> onReviewDifference;

  const _ExpenseFinancialSummary({
    required this.preview,
    required this.withholding,
    required this.currency,
    required this.storedTotals,
    required this.extractedDocumentTotals,
    required this.lineTotals,
    required this.differences,
    required this.onReviewDifference,
  });

  String _format(double value) {
    final suffix = currency == 'EUR' ? '€' : currency;
    return '${ExpenseFormHelpers.formatAmount(value)} $suffix';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;
    final entries = <({String label, double value, bool accent})>[
      (label: 'Subtotal', value: preview.subtotalBeforeDiscount, accent: false),
      (label: 'Descuento', value: preview.discountAmount, accent: false),
      (label: 'Base imponible', value: preview.taxableBase, accent: false),
      (label: 'IVA', value: preview.tax, accent: false),
      if (withholding.hasWithholding)
        (label: 'Retención', value: withholding.amount, accent: false),
      (
        label: 'Total del gasto',
        value: preview.total,
        accent: true,
      ),
    ];

    return Container(
      key: const ValueKey('expense-editor-financial-summary'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Desglose de importes',
            style: ts.labelMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 7),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 520 ? 3 : 2;
              final width =
                  (constraints.maxWidth - ((columns - 1) * 8)) / columns;
              return Wrap(
                spacing: 8,
                runSpacing: 7,
                children: [
                  for (final entry in entries)
                    SizedBox(
                      width: width,
                      child: _ExpenseFinancialSummaryItem(
                        label: entry.label,
                        value: _format(entry.value),
                        accent: entry.accent,
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          _ExpenseTotalsSources(
            format: _format,
            currentTotal: preview.total,
            storedTotals: storedTotals,
            extractedDocumentTotals: extractedDocumentTotals,
            lineTotals: lineTotals,
          ),
          if (differences.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: cs.errorContainer.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 15, color: cs.error),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Desajuste: ${differences.first.label} (${_format(differences.first.amount.abs())}).',
                      style: ts.bodySmall?.copyWith(
                        fontSize: 11,
                        color: cs.onErrorContainer,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => onReviewDifference(differences.first),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 28),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Ver diferencia'),
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

class _ExpenseTotalsSources extends StatelessWidget {
  final String Function(double) format;
  final double currentTotal;
  final _ExpenseTotalsSnapshot? storedTotals;
  final _ExpenseTotalsSnapshot? extractedDocumentTotals;
  final _ExpenseTotalsSnapshot? lineTotals;

  const _ExpenseTotalsSources({
    required this.format,
    required this.currentTotal,
    required this.storedTotals,
    required this.extractedDocumentTotals,
    required this.lineTotals,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;
    String valueOf(_ExpenseTotalsSnapshot? value,
            {String empty = 'Sin datos de OCR'}) =>
        value?.total == null ? empty : format(value!.total!);

    Widget source(String label, String value) => Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: ts.bodySmall?.copyWith(
                  fontSize: 10,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
            Text(
              value,
              style: ts.bodySmall?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        );

    return Column(
      children: [
        source('Total guardado', valueOf(storedTotals, empty: 'Sin datos')),
        const SizedBox(height: 3),
        source('Total actual del formulario', format(currentTotal)),
        const SizedBox(height: 3),
        source('Total calculado por líneas',
            valueOf(lineTotals, empty: 'Sin datos')),
        const SizedBox(height: 3),
        source('Total detectado por OCR', valueOf(extractedDocumentTotals)),
      ],
    );
  }
}

class _ExpenseFinancialSummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final bool accent;

  const _ExpenseFinancialSummaryItem({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;
    final color = accent ? cs.primary : cs.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ts.bodySmall?.copyWith(
            fontSize: 10,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ts.bodySmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

extension _ExpenseInlineEditorFields on _ExpenseInlineEditorState {
  String _localizedDate(BuildContext context, DateTime date) {
    if (Localizations.localeOf(context).languageCode == 'es') {
      const months = <String>[
        'ene',
        'feb',
        'mar',
        'abr',
        'may',
        'jun',
        'jul',
        'ago',
        'sept',
        'oct',
        'nov',
        'dic',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    }
    return MaterialLocalizations.of(context).formatMediumDate(date);
  }

  static InputDecoration _decor(
    String label,
    ColorScheme cs, {
    IconData? icon,
    Widget? suffix,
    bool readOnly = false,
  }) =>
      InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        prefixIcon: icon != null ? Icon(icon, size: 15) : null,
        prefixIconConstraints:
            const BoxConstraints(minWidth: 36, minHeight: 36),
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
        ),
        filled: true,
        fillColor: readOnly
            ? cs.surfaceContainerHighest.withValues(alpha: 0.10)
            : cs.surfaceContainerHighest.withValues(alpha: 0.22),
        isDense: true,
        constraints: const BoxConstraints(minHeight: 40),
        contentPadding: icon != null
            ? const EdgeInsets.symmetric(horizontal: 4, vertical: 10)
            : const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      );

  Widget _field(
    TextEditingController controller,
    String label, {
    IconData? icon,
    ValueChanged<String>? onChanged,
    bool required = false,
    int maxLines = 1,
    bool readOnly = false,
    required ColorScheme cs,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        readOnly: readOnly,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 13),
        decoration: _decor(label, cs, icon: icon, readOnly: readOnly),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null
            : null,
      ),
    );
  }

  Widget _dateField(
    TextEditingController ctrl,
    String label, {
    required ColorScheme cs,
  }) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: ctrl,
      builder: (context, value, _) {
        final parsed = DateTime.tryParse(value.text.trim());
        final display = parsed == null
            ? ''
            : _localizedDate(
                context,
                DateTime(parsed.year, parsed.month, parsed.day),
              );
        return InkWell(
          onTap: () => _pickDate(ctrl),
          borderRadius: BorderRadius.circular(8),
          child: InputDecorator(
            isEmpty: display.isEmpty,
            decoration: _decor(
              label,
              cs,
              icon: Icons.event_outlined,
              suffix: Icon(
                Icons.edit_calendar_outlined,
                size: 15,
                color: cs.onSurfaceVariant,
              ),
            ),
            child: Text(
              display,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        );
      },
    );
  }
}
