part of '../recent_uploads_tab.dart';

extension _ExpenseRecentUploadsEditorSection on _ExpenseRecentUploadsTabState {
  Widget _buildEditorOverlay(
    AppLocalizations l,
    AppTypography t,
    ColorScheme cs,
  ) {
    final editing = _editingExpense!;
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.25),
      child: FolderPanel(
        title: 'Editar gasto',
        onBack: () => setState(() => _editingExpense = null),
        contentTopPadding: 36,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 1100;
            if (isWide) {
              return Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildEditorFormPanel(
                      editing,
                      l,
                      t,
                      cs,
                    ),
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
                    child: _buildEditorFormPanel(
                      editing,
                      l,
                      t,
                      cs,
                    ),
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
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10)),
              border: Border(
                bottom: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.edit_note_outlined, color: cs.onSurface, size: 15),
                const SizedBox(width: 6),
                Text(
                  'Formulario',
                  style: t.bodySmall.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          Expanded(
            child: _ExpenseInlineEditor(
              expenseId: (editing['id'] ?? '').trim(),
              groupId: widget.groupId,
              expensesApi: _expensesApi,
              seedItem: editing,
              onSaved: _applyEditedExpense,
              onCancel: () => setState(() => _editingExpense = null),
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
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10)),
              border: Border(
                bottom: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.preview_outlined, color: cs.onSurface, size: 15),
                const SizedBox(width: 6),
                Text(
                  l.preview,
                  style: t.bodySmall.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          Expanded(child: _buildPreviewContent(item, l, t, cs)),
        ],
      ),
    );
  }
}

class _ExpenseInlineEditor extends StatefulWidget {
  final String expenseId;
  final String groupId;
  final ExpensesApi expensesApi;
  final Map<String, String> seedItem;
  final ValueChanged<Map<String, String>> onSaved;
  final VoidCallback onCancel;

  const _ExpenseInlineEditor({
    required this.expenseId,
    required this.groupId,
    required this.expensesApi,
    required this.seedItem,
    required this.onSaved,
    required this.onCancel,
  });

  @override
  State<_ExpenseInlineEditor> createState() => _ExpenseInlineEditorState();
}

class _ExpenseInlineEditorState extends State<_ExpenseInlineEditor> {
  final _formKey = GlobalKey<FormState>();
  final _providersApi = ProvidersApi();
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
  String? _error;
  List<Map<String, dynamic>> _providers = const [];
  String? _selectedProviderId;

  @override
  void initState() {
    super.initState();
    _vendorController = TextEditingController(
      text: widget.seedItem['vendor'] ?? '',
    );
    _invoiceController = TextEditingController(
      text: widget.seedItem['invoice'] ?? '',
    );
    _issueDateController = TextEditingController(
      text: widget.seedItem['date'] ?? '',
    );
    _dueDateController = TextEditingController(
      text: widget.seedItem['due'] ?? '',
    );
    _baseController = TextEditingController();
    _totalController = TextEditingController(
      text: widget.seedItem['total'] ?? '',
    );
    _taxController = TextEditingController(
      text: widget.seedItem['tax'] ?? '',
    );
    _currencyController = TextEditingController(
      text: widget.seedItem['currency'] ?? 'EUR',
    );
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
    _vendorController.dispose();
    _invoiceController.dispose();
    _issueDateController.dispose();
    _dueDateController.dispose();
    _baseController.dispose();
    _totalController.dispose();
    _taxController.dispose();
    _currencyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadExpense() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await widget.expensesApi.fetchExpense(widget.expenseId);
      if (!mounted) return;
      _vendorController.text =
          (data['vendorName'] ?? data['vendor'] ?? '').toString();
      _invoiceController.text = (data['invoiceNumber'] ?? '').toString();
      _issueDateController.text = (data['issueDate'] ?? '').toString();
      _dueDateController.text = (data['dueDate'] ?? '').toString();
      _totalController.text = (data['total'] ?? '').toString();
      _taxController.text = (data['taxTotal'] ?? '').toString();
      _currencyController.text = (data['currency'] ?? 'EUR').toString();
      _notesController.text = (data['notes'] ?? '').toString();
      _syncBaseFromTotalTax();
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
      if (mounted) {
        setState(() => _loading = false);
      }
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
    if (_syncingAmounts) return;
    _syncingAmounts = true;
    final base = _baseAmountDisplay();
    _baseController.text = base;
    _syncingAmounts = false;
  }

  void _syncTotalFromBaseTax() {
    if (_syncingAmounts) return;
    final base = _normalizedDecimalOrNull(_baseController.text);
    final tax = _normalizedDecimalOrNull(_taxController.text);
    final baseNum = base == null ? null : double.tryParse(base);
    final taxNum = tax == null ? 0.0 : double.tryParse(tax);
    if (baseNum == null) return;
    _syncingAmounts = true;
    _totalController.text = (baseNum + (taxNum ?? 0.0)).toStringAsFixed(2);
    _syncingAmounts = false;
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final totalValue = _normalizedDecimalOrNull(_totalController.text);
    final taxTotalValue = _normalizedDecimalOrNull(_taxController.text);
    final issueDate = _normalizedDateOrNull(_issueDateController.text);
    final dueDate = _normalizedDateOrNull(_dueDateController.text);
    final payload = <String, dynamic>{
      'vendorName': _vendorController.text.trim(),
      'invoiceNumber': _invoiceController.text.trim(),
      if (issueDate != null) 'issueDate': issueDate,
      if (dueDate != null) 'dueDate': dueDate,
      if (totalValue != null) 'total': totalValue,
      if (taxTotalValue != null) 'taxTotal': taxTotalValue,
      'currency': _currencyController.text.trim().toUpperCase(),
      'notes': _notesController.text.trim(),
      if ((_selectedProviderId ?? '').trim().isNotEmpty)
        'providerId': _selectedProviderId!.trim(),
    };
    try {
      final updated = await widget.expensesApi
          .updateExpense(id: widget.expenseId, payload: payload);
      final providerName = _selectedProviderName();
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
        'total': (updated['total'] ?? _totalController.text).toString(),
        'tax': (updated['taxTotal'] ?? _taxController.text).toString(),
        'currency':
            (updated['currency'] ?? _currencyController.text).toString(),
        'notes': (updated['notes'] ?? _notesController.text).toString(),
        'providerId':
            (updated['providerId'] ?? _selectedProviderId ?? '').toString(),
        'providerName': (updated['provider']?['name'] ??
                updated['providerName'] ??
                providerName)
            .toString(),
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
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Form(
        key: _formKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 400;

            Widget row(List<Widget> children) {
              if (!wide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < children.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(child: children[i]),
                  ],
                ],
              );
            }

            return ListView(
              children: [
                DropdownButtonFormField<String>(
                  value: _providers.any(
                    (p) => _providerId(p) == (_selectedProviderId ?? ''),
                  )
                      ? _selectedProviderId
                      : null,
                  items: _providers
                      .where((p) => _providerId(p).trim().isNotEmpty)
                      .map(
                        (p) => DropdownMenuItem<String>(
                          value: _providerId(p),
                          child: Text(
                            _providerName(p),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: _loadingProviders
                      ? null
                      : (v) {
                          setState(() => _selectedProviderId = v);
                          if (v == null) return;
                          final provider = _providers.firstWhere(
                            (p) => _providerId(p) == v,
                            orElse: () => const <String, dynamic>{},
                          );
                          final name = _providerName(provider);
                          if (name.isNotEmpty && name != '-') {
                            _vendorController.text = name;
                          }
                        },
                  decoration: InputDecoration(
                    labelText: _loadingProviders
                        ? '${l.expenseUploadVendorLabel}...'
                        : 'Proveedor existente',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                // Proveedor (full width, required)
                _field(_vendorController, l.expenseUploadVendorLabel,
                    required: true),
                // Invoice # + Currency
                row([
                  _field(_invoiceController, l.expenseUploadInvoiceNumberLabel),
                  _field(_currencyController, l.expenseUploadCurrencyLabel),
                ]),
                // Issue date + Due date
                row([
                  _field(_issueDateController, l.expenseUploadIssueDateLabel),
                  _field(_dueDateController, l.expenseUploadDueDateLabel),
                ]),
                // Base (editable) first
                _field(_baseController, l.expenseUploadLinesSubtotalLabel),
                // Total + Tax
                row([
                  _field(_totalController, l.expenseUploadTotalLabel,
                      required: true),
                  _field(_taxController, l.expenseUploadTaxTotalLabel),
                ]),
                // Notes (compact)
                _field(_notesController, l.expenseUploadNotesLabel,
                    maxLines: 2),
                if ((_error ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _error!,
                    style: TextStyle(color: cs.error, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: _saving ? null : widget.onCancel,
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        textStyle: const TextStyle(fontSize: 13),
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
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_outlined, size: 18),
                        label: Text(_saving ? 'Guardando...' : l.save),
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          textStyle: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant _ExpenseInlineEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expenseId != widget.expenseId) {
      _loadExpense();
    }
  }
}

extension _ExpenseInlineEditorFields on _ExpenseInlineEditorState {
  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 12),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null
            : null,
      ),
    );
  }
}
