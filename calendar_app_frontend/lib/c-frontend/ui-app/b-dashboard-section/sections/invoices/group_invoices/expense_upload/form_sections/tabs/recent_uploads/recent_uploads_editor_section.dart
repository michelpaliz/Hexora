part of '../recent_uploads_tab.dart';

extension _ExpenseRecentUploadsEditorSection on _ExpenseRecentUploadsTabState {
  Widget _buildEditorOverlay(
    AppLocalizations l,
    AppTypography t,
    ColorScheme cs,
  ) {
    final editing = _latestExpenseSnapshot(_editingExpense!);
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.25),
      child: FolderPanel(
        title: 'Editar gasto',
        onBack: _closeExpenseEditor,
        contentTopPadding: 36,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 1100;
            if (isWide) {
              return Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildEditorFormPanel(editing, l, t, cs),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: _buildEditorPreviewPanel(editing, l, t, cs),
                  ),
                ],
              );
            }

            final formHeight = (constraints.maxHeight * 0.62).clamp(320, 860);
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: formHeight.toDouble(),
                    child: _buildEditorFormPanel(editing, l, t, cs),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: (constraints.maxHeight * 0.38).clamp(260, 640),
                    child: _buildEditorPreviewPanel(editing, l, t, cs),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEditorFormPanel(
    Map<String, String> editing,
    AppLocalizations l,
    AppTypography t,
    ColorScheme cs,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _PanelHeader(icon: Icons.edit_note_outlined, label: 'Formulario'),
          Expanded(
            child: _ExpenseInlineEditor(
              expenseId: (editing['id'] ?? '').trim(),
              groupId: widget.groupId,
              expensesApi: _expensesApi,
              seedItem: editing,
              availableAdvanceExpenses: widget.recentUploads,
              onSaved: _applyEditedExpense,
              onCancel: _closeExpenseEditor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorPreviewPanel(
    Map<String, String> item,
    AppLocalizations l,
    AppTypography t,
    ColorScheme cs,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelHeader(icon: Icons.preview_outlined, label: l.preview),
          Expanded(child: _buildPreviewContent(item, l, t, cs)),
        ],
      ),
    );
  }
}

// ── Shared panel header ───────────────────────────────────────────────────────

class _PanelHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _PanelHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.35)),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: cs.onSurfaceVariant, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: ts.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
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
  final ValueChanged<Map<String, String>> onSaved;
  final VoidCallback onCancel;

  const _ExpenseInlineEditor({
    required this.expenseId,
    required this.groupId,
    required this.expensesApi,
    required this.seedItem,
    required this.availableAdvanceExpenses,
    required this.onSaved,
    required this.onCancel,
  });

  @override
  State<_ExpenseInlineEditor> createState() => _ExpenseInlineEditorState();
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
  String? _error;
  List<Map<String, dynamic>> _providers = const [];
  String? _selectedProviderId;

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
    _taxController =
        TextEditingController(text: widget.seedItem['tax'] ?? '');
    _currencyController =
        TextEditingController(text: widget.seedItem['currency'] ?? 'EUR');
    _notesController = TextEditingController();
    _totalController.addListener(_syncBaseFromTotalTax);
    _taxController.addListener(_syncBaseFromTotalTax);
    _baseController.addListener(_syncTotalFromBaseTax);
    final seedProviderId = (widget.seedItem['providerId'] ?? '').trim();
    _selectedProviderId = seedProviderId.isEmpty ? null : seedProviderId;
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
    final finalTax = double.tryParse(_normalizedDecimalOrNull(_taxController.text) ?? '');
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
    _baseController.text = (preview?.taxableBase ?? _linesSubtotal()).toStringAsFixed(2);
    _taxController.text = (preview?.tax ?? _linesTax()).toStringAsFixed(2);
    _totalController.text = (preview?.total ?? _linesTotal()).toStringAsFixed(2);
    _syncingAmounts = false;
  }

  bool _validateLines() {
    for (final line in _lines) {
      if (line.descriptionController.text.trim().isEmpty) {
        setState(() => _error = 'La descripcion de la linea es obligatoria.');
        return false;
      }
      if (line.quantity <= 0) {
        setState(() => _error = 'La cantidad debe ser mayor que cero.');
        return false;
      }
      if (line.baseUnitPrice < 0) {
        setState(() => _error = 'El precio base no puede ser negativo.');
        return false;
      }
      if (line.discountPercent < 0 || line.discountPercent > 100) {
        setState(() => _error = 'El descuento % debe estar entre 0 y 100.');
        return false;
      }
      if (line.discountAmount < 0 ||
          line.discountAmount > line.grossSubtotal + 0.0001) {
        setState(
          () => _error =
              'El descuento no puede superar el importe bruto de la linea.',
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
    });
    try {
      final data = await widget.expensesApi.fetchExpense(widget.expenseId);
      if (!mounted) return;
      final subtotalNum = ExpenseFormHelpers.parseNum(data['subtotal']);
      final totalNum = ExpenseFormHelpers.parseNum(data['total']) ?? 0;
      final taxNum = ExpenseFormHelpers.parseNum(data['taxTotal']) ?? 0;
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
      if ((providerId ?? '').isNotEmpty) {
        _selectedProviderId = providerId;
      }
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
      ctrl.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_validateLines()) return;
    final settlementError = _settlement.validate();
    if (settlementError != null) {
      setState(() => _error = settlementError);
      return;
    }
    final summaryTotalsError = _summaryTotalsValidationError();
    if (summaryTotalsError != null) {
      setState(() => _error = summaryTotalsError);
      return;
    }
    final discountPreview = _documentDiscountPreview();
    final discountValidationBase =
        discountPreview?.subtotalBeforeDiscount ??
            double.tryParse(_baseAmountDisplay()) ??
            0;
    final discountError = _documentDiscount.validate(discountValidationBase);
    if (discountError != null) {
      setState(() => _error = discountError);
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
      final updatedLinesCount =
          updatedLinesSummary['count'] as int? ?? 0;
      final responseUseSummaryTotals = ExpenseFormHelpers.shouldUseSummaryTotals(
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
            (updated['discountAmount'] ??
                    payload['discountAmount'] ??
                    '')
                .toString(),
        'discountPercent':
            (updated['discountPercent'] ??
                    payload['discountPercent'] ??
                    '')
                .toString(),
        'providerName': (updated['provider']?['name'] ??
                updated['providerName'] ??
                providerName)
            .toString(),
        'expenseType':
            (updated['expenseType'] ?? payload['expenseType'] ?? '').toString(),
        'advancePercent':
            ((updated['advancePayment']?['percent'] ??
                        payload['advancePayment']?['percent']) ??
                    '')
                .toString(),
        'advanceProjectBaseAmount':
            ((updated['advancePayment']?['projectBaseAmount'] ??
                        payload['advancePayment']?['projectBaseAmount']) ??
                    '')
                .toString(),
        'advanceTaxRate':
            ((updated['advancePayment']?['taxRate'] ??
                        payload['advancePayment']?['taxRate']) ??
                    '')
                .toString(),
        'finalAdvanceExpenseId':
            ((updated['finalSettlement']?['advanceExpenseId'] ??
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
        'linesCount':
            updatedLinesCount > 0 ? updatedLinesCount.toString() : '',
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
                          color:
                              cs.onSurfaceVariant.withValues(alpha: 0.55)),
                      const SizedBox(width: 5),
                      Text(
                        text.toUpperCase(),
                        style: ts.bodySmall?.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurfaceVariant
                              .withValues(alpha: 0.55),
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
              onLinesChanged: () {
                setState(() {
                  _lineEditorEnabled = true;
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
            final documentDiscountFields = ExpenseDocumentDiscountFields(
              discount: _documentDiscount,
              enabled: !_saving,
              preview: _documentDiscountPreview(),
              compactSummary: true,
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
              onSummaryModeChanged: (value) => setState(() {
                _useSummaryTotals = value;
                if (!_useSummaryTotals && _hasEditableLines) {
                  _syncControllersFromLines();
                } else if (_useSummaryTotals) {
                  _syncSummaryControllers(_ExpenseEditorDocumentTotalField.total);
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

            return ListView(
              padding: EdgeInsets.zero,
              children: [
                // ── Proveedor ──────────────────────────────────────
                sectionLabel(l.expenseUploadVendorLabel,
                    Icons.business_outlined),
                ExpenseProviderPicker(
                  providers: _providers,
                  selectedProviderId: _selectedProviderId,
                  providersError: null,
                  loading: _loadingProviders,
                  onSelectProvider: (id) {
                    setState(() => _selectedProviderId = id);
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
                ),
                gap,
                row([
                  _field(
                    _vendorController,
                    l.expenseUploadVendorLabel,
                    icon: Icons.storefront_outlined,
                    required: true,
                    cs: cs,
                  ),
                  _field(
                    _currencyController,
                    l.expenseUploadCurrencyLabel,
                    icon: Icons.euro_outlined,
                    cs: cs,
                  ),
                ]),
                sectionGap,

                // ── Factura ────────────────────────────────────────
                sectionLabel(l.expenseUploadInvoiceNumberLabel,
                    Icons.receipt_outlined),
                row([
                  _field(
                    _invoiceController,
                    l.expenseUploadInvoiceNumberLabel,
                    icon: Icons.tag_outlined,
                    cs: cs,
                  ),
                  _dateField(
                    _issueDateController,
                    l.expenseUploadIssueDateLabel,
                    cs: cs,
                  ),
                ]),
                gap,
                _dateField(
                  _dueDateController,
                  l.expenseUploadDueDateLabel,
                  cs: cs,
                ),
                sectionGap,

                // ── Importes ───────────────────────────────────────
                settlementFields,
                const SizedBox(height: 10),
                documentDiscountFields,
                const SizedBox(height: 10),
                ExpenseDocumentWithholdingFields(
                  withholding: _withholding,
                  enabled: !_saving,
                  compactSummary: true,
                  preview: _withholding.buildPreview(
                    taxableBase:
                        double.tryParse(_baseController.text.trim()) ?? 0,
                    grossTotal:
                        double.tryParse(_totalController.text.trim()) ?? 0,
                  ),
                  onChanged: () => setState(() {}),
                ),
                sectionGap,
                totalsFields,
                sectionGap,

                // ── Notas ──────────────────────────────────────────
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

                // ── Líneas ─────────────────────────────────────────
                linesEditor,

                // ── Error ──────────────────────────────────────────
                if ((_error ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: cs.errorContainer.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: cs.error.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            size: 14, color: cs.error),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(color: cs.error, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // ── Actions ────────────────────────────────────────
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: _saving ? null : widget.onCancel,
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        textStyle: const TextStyle(fontSize: 13),
                        side: BorderSide(
                          color: cs.outlineVariant.withValues(alpha: 0.5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(l.cancel),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white),
                              )
                            : const Icon(Icons.save_outlined, size: 16),
                        label: Text(
                          _saving ? 'Guardando...' : 'Guardar Edición',
                        ),
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          textStyle: const TextStyle(fontSize: 13),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Field helpers ─────────────────────────────────────────────────────────────

extension _ExpenseInlineEditorFields on _ExpenseInlineEditorState {
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
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
        ),
        filled: true,
        fillColor: readOnly
            ? cs.surfaceContainerHighest.withValues(alpha: 0.10)
            : cs.surfaceContainerHighest.withValues(alpha: 0.22),
        isDense: true,
        contentPadding: icon != null
            ? const EdgeInsets.symmetric(horizontal: 4, vertical: 10)
            : const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      );

  Widget _field(
    TextEditingController controller,
    String label, {
    IconData? icon,
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
    return TextFormField(
      controller: ctrl,
      readOnly: true,
      style: const TextStyle(fontSize: 13),
      decoration: _decor(
        label,
        cs,
        icon: Icons.event_outlined,
        suffix: IconButton(
          icon: Icon(Icons.edit_calendar_outlined,
              size: 15, color: cs.onSurfaceVariant),
          onPressed: () => _pickDate(ctrl),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ),
      onTap: () => _pickDate(ctrl),
      enableInteractiveSelection: false,
    );
  }
}
