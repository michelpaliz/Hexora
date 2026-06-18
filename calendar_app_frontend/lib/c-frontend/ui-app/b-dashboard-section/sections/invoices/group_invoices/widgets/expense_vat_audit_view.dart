import 'package:flutter/material.dart';
import 'package:hexora/b-backend/expenses/expenses_api.dart';
import 'package:hexora/c-frontend/ui-app/shared/downloads/download_jobs_store.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:url_launcher/url_launcher.dart';

class ExpenseVatAuditView extends StatefulWidget {
  const ExpenseVatAuditView({
    super.key,
    required this.groupId,
    required this.onEditExpense,
  });

  final String groupId;
  final Future<void> Function(String expenseId) onEditExpense;

  @override
  State<ExpenseVatAuditView> createState() => _ExpenseVatAuditViewState();
}

class _ExpenseVatAuditViewState extends State<ExpenseVatAuditView> {
  final ExpensesApi _api = ExpensesApi();
  final TextEditingController _searchCtrl = TextEditingController();
  final Set<String> _busyIds = <String>{};

  Map<String, dynamic>? _response;
  bool _loading = true;
  bool _exporting = false;
  String? _error;
  String? _providerId;
  String? _clientId;
  String _currency = 'EUR';
  DateTime? _from;
  DateTime? _to;
  String _searchText = '';
  Map<String, dynamic>? _selectedRow;
  bool _filtersExpanded = false;

  bool get _isEs =>
      Localizations.localeOf(context).languageCode.toLowerCase().startsWith('es');
  String _tx(String es, String en) => _isEs ? es : en;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      if (mounted) setState(() => _searchText = _searchCtrl.text.trim().toLowerCase());
    });
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String? _fmtDate(DateTime? value) {
    if (value == null) return null;
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }

  String _date(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return '—';
    return text.length >= 10 ? text.substring(0, 10) : text;
  }

  String _money(dynamic value) {
    final number = value is num ? value.toDouble() : double.tryParse('$value');
    if (number == null) return '—';
    final fixed = number.toStringAsFixed(2).split('.');
    final whole = fixed.first.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[1]}.',
    );
    return '$whole,${fixed.last}';
  }

  List<Map<String, dynamic>> get _rows {
    final raw = _response?['rows'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where((row) {
      if (_searchText.isEmpty) return true;
      return (row['invoiceNumber'] ?? '').toString().toLowerCase().contains(_searchText) ||
          (row['vendorName'] ?? '').toString().toLowerCase().contains(_searchText) ||
          (row['fileName'] ?? '').toString().toLowerCase().contains(_searchText);
    }).toList(growable: false);
  }

  Future<void> _load({bool showSpinner = true}) async {
    if (!mounted) return;
    setState(() {
      if (showSpinner) _loading = true;
      _error = null;
    });
    try {
      final result = await _api.getVatAudit(
        groupId: widget.groupId,
        providerId: _providerId,
        clientId: _clientId,
        from: _fmtDate(_from),
        to: _fmtDate(_to),
        currency: _currency,
      );
      if (mounted) setState(() => _response = result);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted && showSpinner) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom
          ? (_from ?? DateTime(DateTime.now().year, 1, 1))
          : (_to ?? DateTime.now()),
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() => isFrom ? _from = picked : _to = picked);
    await _load();
  }

  Future<void> _exportAudit() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      await DownloadJobsStore.instance.createJob(
        groupId: widget.groupId,
        jobType: 'expense_vat_audit_excel',
        title: 'Auditoría IVA gastos',
        description:
            'Periodo ${_fmtDate(_from) ?? 'inicio'} a ${_fmtDate(_to) ?? 'hoy'}',
        params: <String, dynamic>{
          if (_fmtDate(_from) != null) 'from': _fmtDate(_from),
          if (_fmtDate(_to) != null) 'to': _fmtDate(_to),
          if ((_providerId ?? '').trim().isNotEmpty) 'providerId': _providerId,
          if ((_clientId ?? '').trim().isNotEmpty) 'clientId': _clientId,
          if (_currency.trim().isNotEmpty) 'currency': _currency,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_tx(
            'Estamos preparando tu archivo.',
            'We are preparing your file.',
          )),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_tx(
          'No se pudo generar la auditoría IVA gastos.',
          'Could not generate the expense VAT audit.',
        )),
      ));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _updateReview(Map<String, dynamic> row, String status, {String? notes}) async {
    final id = (row['id'] ?? '').toString().trim();
    if (id.isEmpty || _busyIds.contains(id)) return;
    setState(() => _busyIds.add(id));
    try {
      await _api.patchSuspicionReview(id, status: status, notes: notes);
      await _load(showSpinner: false);
      // Refresh selected row
      if (_selectedRow?['id']?.toString() == id) {
        final updated = _rows.firstWhere(
          (r) => r['id']?.toString() == id,
          orElse: () => _selectedRow!,
        );
        setState(() => _selectedRow = updated);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _busyIds.remove(id));
    }
  }

  Future<void> _needsFix(Map<String, dynamic> row) async {
    final ctrl = TextEditingController(text: (row['reviewNotes'] ?? '').toString());
    final submitted = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_tx('Marcar para corregir', 'Mark for correction')),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: _tx('Añade una nota de revisión...', 'Add a review note...'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            child: Text(_tx('Guardar', 'Save')),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (submitted != null) await _updateReview(row, 'needs_fix', notes: submitted);
  }

  Future<void> _openFile(Map<String, dynamic> row) async {
    final id = (row['id'] ?? '').toString().trim();
    if (id.isEmpty) return;
    try {
      final result = await _api.fetchExpenseFile(id);
      final url = (result['url'] ?? '').toString().trim();
      final uri = Uri.tryParse(url);
      if (uri == null) throw Exception(_tx('No se encontró el archivo.', 'File not found.'));
      await launchUrl(uri, webOnlyWindowName: '_blank');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  String _reviewLabel(String status) {
    switch (status) {
      case 'confirmed_ok': return _tx('Confirmado', 'Confirmed');
      case 'needs_fix': return _tx('A corregir', 'Needs fix');
      default: return _tx('Sin revisar', 'Unreviewed');
    }
  }

  String _reasonLabel(String code) {
    switch (code.toUpperCase()) {
      case 'SUBTOTAL_MISMATCH': return _tx('Discrepancia en base', 'Base mismatch');
      case 'TAX_TOTAL_MISMATCH': return _tx('Discrepancia en IVA', 'VAT mismatch');
      case 'TOTAL_MISMATCH': return _tx('Discrepancia en total', 'Total mismatch');
      case 'IMPOSSIBLE_ZERO_TOTAL': return _tx('Total imposible (0)', 'Impossible zero total');
      default: return code;
    }
  }

  Color _statusColor(bool isSuspect, String review, ColorScheme cs) {
    if (isSuspect) return cs.error;
    if (review == 'confirmed_ok') return cs.tertiary;
    return cs.onSurfaceVariant;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final response = _response ?? const <String, dynamic>{};
    final totals = response['derivedTotals'] is Map
        ? Map<String, dynamic>.from(response['derivedTotals'])
        : const <String, dynamic>{};
    final rows = _rows;

    if (_loading && _response == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _response == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 32, color: cs.error),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center, style: t.bodySmall),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: Text(_tx('Intentar de nuevo', 'Try again')),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Top bar ────────────────────────────────────────────────────────
        _topBar(cs, t, response, totals),
        const SizedBox(height: 10),
        // ── Filters (collapsible) ──────────────────────────────────────────
        _filtersBar(cs, t),
        const SizedBox(height: 10),
        // ── Error banner ───────────────────────────────────────────────────
        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: cs.errorContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 16, color: cs.error),
                const SizedBox(width: 8),
                Expanded(child: Text(_error!, style: t.bodySmall.copyWith(color: cs.error))),
                TextButton(
                  onPressed: _load,
                  child: Text(_tx('Reintentar', 'Retry')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        // ── Main content: list + detail ────────────────────────────────────
        Expanded(
          child: _loading && _response != null
              ? const Center(child: CircularProgressIndicator())
              : rows.isEmpty
                  ? _emptyState(cs, t)
                  : LayoutBuilder(builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 760;
                      if (!wide) {
                        return _selectedRow != null
                            ? _detailPanel(_selectedRow!, cs, t)
                            : _listPanel(rows, cs, t);
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: 340,
                            child: _listPanel(rows, cs, t),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _selectedRow == null
                                ? _detailPlaceholder(cs, t)
                                : _detailPanel(_selectedRow!, cs, t),
                          ),
                        ],
                      );
                    }),
        ),
      ],
    );
  }

  // ── Top bar ──────────────────────────────────────────────────────────────

  Widget _topBar(
    ColorScheme cs,
    AppTypography t,
    Map<String, dynamic> response,
    Map<String, dynamic> totals,
  ) {
    final mismatch = (response['mismatchCount'] ?? 0) as num;
    final hasMismatch = mismatch > 0;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final expensesChipColor = isLight ? const Color(0xFF305E9A) : cs.primary;
    final baseChipColor = isLight ? const Color(0xFF1D4ED8) : cs.secondary;
    final vatChipColor = isLight ? const Color(0xFF475569) : cs.secondary;
    final totalChipColor = isLight ? const Color(0xFFB45309) : cs.primary;
    final issuesChipColor =
        hasMismatch ? (isLight ? const Color(0xFFC2410C) : cs.error) : cs.tertiary;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.fact_check_outlined, size: 16, color: cs.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _tx('Auditoria IVA gastos', 'Expense VAT audit'),
                        style: t.bodyMedium.copyWith(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        _tx(
                          'Compara importes guardados y derivados gasto por gasto.',
                          'Compare stored and derived amounts expense by expense.',
                        ),
                        style: t.bodySmall.copyWith(
                          color: cs.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 4,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _statChip(
                        Icons.receipt_long_outlined,
                        _tx('Gastos', 'Expenses'),
                        '${response['count'] ?? 0}',
                        expensesChipColor,
                        cs,
                        t,
                      ),
                      _statChip(
                        Icons.account_balance_wallet_outlined,
                        'Base',
                        '${_money(totals['subtotal'])} EUR',
                        baseChipColor,
                        cs,
                        t,
                      ),
                      _statChip(
                        Icons.percent_rounded,
                        'IVA',
                        '${_money(totals['taxTotal'])} EUR',
                        vatChipColor,
                        cs,
                        t,
                      ),
                      _statChip(
                        Icons.euro_rounded,
                        _tx('Total', 'Total'),
                        '${_money(totals['total'])} EUR',
                        totalChipColor,
                        cs,
                        t,
                      ),
                      _statChip(
                        hasMismatch
                            ? Icons.warning_amber_rounded
                            : Icons.verified_outlined,
                        _tx('Incidencias', 'Issues'),
                        '$mismatch',
                        issuesChipColor,
                        cs,
                        t,
                        highlight: hasMismatch,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _buildExportButton(cs),
        ],
      ),
    );
  }
  Widget _buildExportButton(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.primary.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: FilledButton.tonalIcon(
        onPressed: _exporting ? null : _exportAudit,
        icon: _exporting
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: cs.primary,
                ),
              )
            : const Icon(Icons.download_rounded, size: 16),
        label: Text(
          _exporting
              ? _tx('Generando...', 'Generating...')
              : _tx('Exportar', 'Export'),
        ),
        style: FilledButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
      ),
    );
  }
  Widget _statChip(
    IconData icon,
    String label,
    String value,
    Color color,
    ColorScheme cs,
    AppTypography t, {
    bool highlight = false,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final backgroundAlpha = highlight
        ? (isLight ? 0.10 : 0.12)
        : (isLight ? 0.055 : 0.07);
    final borderAlpha = highlight
        ? (isLight ? 0.28 : 0.35)
        : (isLight ? 0.16 : 0.2);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: backgroundAlpha),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: borderAlpha)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: color.withValues(alpha: 0.8),
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Filters bar ───────────────────────────────────────────────────────────

  Widget _filtersBar(ColorScheme cs, AppTypography t) {
    final activeFilters = [_from, _to, _providerId, _clientId]
        .where((f) => f != null)
        .length +
        (_searchText.isNotEmpty ? 1 : 0);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          // Toggle row
          InkWell(
            onTap: () => setState(() => _filtersExpanded = !_filtersExpanded),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Row(
                children: [
                  Icon(Icons.tune_rounded,
                      size: 15, color: cs.onSurfaceVariant),
                  const SizedBox(width: 7),
                  Text(
                    _tx('Filtros', 'Filters'),
                    style: t.bodySmall.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (activeFilters > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$activeFilters',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: cs.primary,
                        ),
                      ),
                    ),
                  ],
                  // Search always visible
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 30,
                      child: TextField(
                        controller: _searchCtrl,
                        style: const TextStyle(fontSize: 12),
                        decoration: InputDecoration(
                          hintText: _tx(
                            'Buscar factura, proveedor o archivo...',
                            'Search invoice, vendor or file...',
                          ),
                          hintStyle: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                          prefixIcon: Icon(Icons.search_rounded,
                              size: 14, color: cs.onSurfaceVariant),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7),
                            borderSide: BorderSide(
                                color:
                                    cs.outlineVariant.withValues(alpha: 0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7),
                            borderSide: BorderSide(
                                color:
                                    cs.outlineVariant.withValues(alpha: 0.25)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _filtersExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          // Expandable filters
          if (_filtersExpanded) ...[
            Divider(
                height: 1,
                color: cs.outlineVariant.withValues(alpha: 0.25)),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  _dateField(_tx('Desde', 'From'), _fmtDate(_from),
                      () => _pickDate(true)),
                  _dateField(_tx('Hasta', 'To'), _fmtDate(_to),
                      () => _pickDate(false)),
                  SizedBox(
                    width: 120,
                    child: DropdownButtonFormField<String>(
                      initialValue: _currency,
                      decoration: InputDecoration(
                        labelText: _tx('Moneda', 'Currency'),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 9),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'EUR', child: Text('EUR'))
                      ],
                      onChanged: (value) async {
                        if (value == null) return;
                        setState(() => _currency = value);
                        await _load();
                      },
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: TextFormField(
                      initialValue: _providerId,
                      decoration: InputDecoration(
                        labelText: _tx('Proveedor ID', 'Provider ID'),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 9),
                      ),
                      onFieldSubmitted: (value) async {
                        setState(() => _providerId =
                            value.trim().isEmpty ? null : value.trim());
                        await _load();
                      },
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: TextFormField(
                      initialValue: _clientId,
                      decoration: InputDecoration(
                        labelText: _tx('Cliente ID', 'Client ID'),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 9),
                      ),
                      onFieldSubmitted: (value) async {
                        setState(() => _clientId =
                            value.trim().isEmpty ? null : value.trim());
                        await _load();
                      },
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      setState(() {
                        _from = null;
                        _to = null;
                        _currency = 'EUR';
                        _providerId = null;
                        _clientId = null;
                        _searchCtrl.clear();
                      });
                      await _load();
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 14),
                    label: Text(_tx('Restablecer', 'Reset'),
                        style: const TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── List panel ────────────────────────────────────────────────────────────

  Widget _listPanel(
      List<Map<String, dynamic>> rows, ColorScheme cs, AppTypography t) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Panel header
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                Text(
                  '${rows.length} ${_tx('gastos', 'expenses')}',
                  style: t.bodySmall.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                if (_loading)
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 1.5, color: cs.primary),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.25)),
          Expanded(
            child: ListView.separated(
              itemCount: rows.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.15)),
              itemBuilder: (_, i) => _listRow(rows[i], cs, t),
            ),
          ),
        ],
      ),
    );
  }

  Widget _listRow(
      Map<String, dynamic> row, ColorScheme cs, AppTypography t) {
    final id = (row['id'] ?? '').toString();
    final isSuspect = row['isSuspect'] == true;
    final review = (row['reviewStatus'] ?? 'unreviewed').toString();
    final isSelected = _selectedRow?['id']?.toString() == id;
    final accentColor = _statusColor(isSuspect, review, cs);
    final delta = row['deltaTotal'];
    final hasDelta = delta is num && delta.abs() > 0.009;

    return InkWell(
      onTap: () => setState(() {
        _selectedRow = isSelected ? null : Map<String, dynamic>.from(row);
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        color: isSelected
            ? cs.primary.withValues(alpha: 0.07)
            : Colors.transparent,
        child: Row(
          children: [
            // Colored left stripe
            Container(
              width: 3,
              height: 56,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: isSelected ? 1.0 : 0.5),
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(12)),
              ),
            ),
            const SizedBox(width: 10),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            (row['invoiceNumber'] ?? '—').toString(),
                            style: t.bodySmall.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasDelta)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: cs.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                  color: cs.error.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              'Δ ${_money(delta)} €',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: cs.error,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      (row['vendorName'] ?? '—').toString(),
                      style: t.bodySmall.copyWith(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          _date(row['issueDate']),
                          style: TextStyle(
                            fontSize: 10,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _miniStatusBadge(isSuspect, review, cs),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _miniStatusBadge(bool isSuspect, String review, ColorScheme cs) {
    final color = _statusColor(isSuspect, review, cs);
    final label = isSuspect
        ? 'Issue'
        : review == 'confirmed_ok'
            ? '✓'
            : '–';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  // ── Detail placeholder ────────────────────────────────────────────────────

  Widget _detailPlaceholder(ColorScheme cs, AppTypography t) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fact_check_outlined,
                size: 32,
                color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
            const SizedBox(height: 8),
            Text(
              _tx('Selecciona un gasto para ver el detalle.',
                  'Select an expense to view details.'),
              style:
                  t.bodySmall.copyWith(color: cs.onSurfaceVariant, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  // ── Detail panel ──────────────────────────────────────────────────────────

  Widget _detailPanel(
      Map<String, dynamic> row, ColorScheme cs, AppTypography t) {
    final id = (row['id'] ?? '').toString().trim();
    final isSuspect = row['isSuspect'] == true;
    final review = (row['reviewStatus'] ?? 'unreviewed').toString();
    final busy = _busyIds.contains(id);
    final reasons = row['suspicion']?['reasons'] is List
        ? (row['suspicion']['reasons'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList(growable: false)
        : const <Map<String, dynamic>>[];

    final delta = row['deltaTotal'];
    final hasDelta = delta is num && delta.abs() > 0.009;
    final accentColor = _statusColor(isSuspect, review, cs);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isSuspect
              ? cs.error.withValues(alpha: 0.3)
              : cs.outlineVariant.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Detail header ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.05),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(
                bottom: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.2)),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (row['invoiceNumber'] ?? '—').toString(),
                        style: t.bodyMedium.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        (row['vendorName'] ?? '—').toString(),
                        style: t.bodySmall.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _badge(
                            isSuspect ? _tx('Incidencia', 'Issue') : _tx('Correcto', 'Correct'),
                            isSuspect ? cs.error : cs.tertiary,
                            t,
                          ),
                          _badge(
                            _reviewLabel(review),
                            review == 'confirmed_ok'
                                ? cs.tertiary
                                : review == 'needs_fix'
                                    ? cs.error
                                    : cs.onSurfaceVariant,
                            t,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Close / back button (narrow layout)
                LayoutBuilder(builder: (context, _) {
                  return IconButton(
                    icon: const Icon(Icons.close_rounded, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => setState(() => _selectedRow = null),
                    color: cs.onSurfaceVariant,
                  );
                }),
              ],
            ),
          ),
          // ── Scrollable body ────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Meta info row
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _infoChip(Icons.calendar_today_outlined,
                          _date(row['issueDate']), cs),
                      _infoChip(Icons.category_outlined,
                          (row['expenseTypeLabel'] ?? row['expenseType'] ?? '—').toString(),
                          cs),
                      _infoChip(Icons.percent_rounded,
                          (row['vatTypes'] ?? '—').toString(), cs),
                      _infoChip(Icons.attach_file_rounded,
                          (row['fileName'] ?? '—').toString(), cs),
                      _infoChip(Icons.upload_outlined,
                          '${_tx('Subido', 'Uploaded')}: ${_date(row['uploadedAt'])}',
                          cs),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // ── Amounts comparison table ─────────────────────────
                  _sectionLabel(_tx('Comparativa de importes', 'Amount comparison'), cs, t),
                  const SizedBox(height: 8),
                  _amountTable(row, hasDelta, cs, t),
                  // ── Reasons ──────────────────────────────────────────
                  if (reasons.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _sectionLabel(_tx('Motivos detectados', 'Detected reasons'), cs, t),
                    const SizedBox(height: 8),
                    ...reasons.map((reason) => _reasonChip(reason, cs, t)),
                  ],
                  // ── Review notes ──────────────────────────────────────
                  if ((row['reviewNotes'] ?? '').toString().trim().isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _sectionLabel(_tx('Notas de revisión', 'Review notes'), cs, t),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        (row['reviewNotes'] ?? '').toString(),
                        style: t.bodySmall.copyWith(
                          fontStyle: FontStyle.italic,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                  // ── Actions ───────────────────────────────────────────
                  const SizedBox(height: 16),
                  _sectionLabel(_tx('Acciones', 'Actions'), cs, t),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (review != 'confirmed_ok')
                        _actionBtn(
                          _tx('Marcar correcto', 'Mark correct'),
                          Icons.check_rounded,
                          cs.tertiary,
                          busy,
                          () => _updateReview(row, 'confirmed_ok'),
                          t,
                          cs,
                        ),
                      if (review != 'needs_fix')
                        _actionBtn(
                          _tx('Marcar a corregir', 'Mark for fix'),
                          Icons.build_outlined,
                          cs.error,
                          busy,
                          () => _needsFix(row),
                          t,
                          cs,
                        ),
                      if (review != 'unreviewed')
                        _actionBtn(
                          _tx('Restablecer', 'Reset'),
                          Icons.undo_rounded,
                          cs.onSurfaceVariant,
                          busy,
                          () => _updateReview(row, 'unreviewed'),
                          t,
                          cs,
                        ),
                      _actionBtn(
                        _tx('Ver archivo', 'View file'),
                        Icons.open_in_new_rounded,
                        cs.primary,
                        false,
                        () => _openFile(row),
                        t,
                        cs,
                      ),
                      _actionBtn(
                        _tx('Editar', 'Edit'),
                        Icons.edit_outlined,
                        cs.primary,
                        false,
                        () => widget.onEditExpense(id),
                        t,
                        cs,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountTable(
    Map<String, dynamic> row,
    bool hasDelta,
    ColorScheme cs,
    AppTypography t,
  ) {
    final rows = [
      [
        _tx('Base', 'Base'),
        _money(row['storedSubtotal']),
        _money(row['derivedSubtotal']),
      ],
      [
        'IVA',
        _money(row['storedTaxTotal']),
        _money(row['derivedTaxTotal']),
      ],
      [
        _tx('Total', 'Total'),
        _money(row['storedTotal']),
        _money(row['derivedTotal']),
      ],
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.2),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text('',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurfaceVariant)),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    _tx('Guardado', 'Stored'),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    _tx('Derivado', 'Derived'),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                      color: cs.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Table rows
          ...rows.asMap().entries.map((entry) {
            final i = entry.key;
            final r = entry.value;
            final isLast = i == rows.length - 1;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: !isLast
                    ? Border(
                        bottom: BorderSide(
                          color: cs.outlineVariant.withValues(alpha: 0.15),
                        ),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      r[0],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isLast ? FontWeight.w800 : FontWeight.w600,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      '${r[1]} €',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isLast ? FontWeight.w800 : FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      '${r[2]} €',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isLast ? FontWeight.w800 : FontWeight.w600,
                        color: cs.primary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          // Delta row
          if (hasDelta) ...[
            Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.2)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: cs.error.withValues(alpha: 0.06),
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(10)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            size: 12, color: cs.error),
                        const SizedBox(width: 4),
                        Text(
                          'Δ',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: cs.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 6,
                    child: Text(
                      '${_money(row['deltaTotal'])} €',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: cs.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _reasonChip(
      Map<String, dynamic> reason, ColorScheme cs, AppTypography t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(
          color: cs.errorContainer.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cs.error.withValues(alpha: 0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 13, color: cs.error),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _reasonLabel((reason['code'] ?? '').toString()),
                    style: t.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.error,
                      fontSize: 11,
                    ),
                  ),
                  if ((reason['message'] ?? '').toString().trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      (reason['message'] ?? '').toString(),
                      style: t.bodySmall.copyWith(
                          fontSize: 11, color: cs.onSurface),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String value, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
          const SizedBox(width: 5),
          Text(
            value,
            style: TextStyle(fontSize: 11, color: cs.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label, ColorScheme cs, AppTypography t) {
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: cs.onSurfaceVariant,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1,
            color: cs.outlineVariant.withValues(alpha: 0.25),
          ),
        ),
      ],
    );
  }

  Widget _emptyState(ColorScheme cs, AppTypography t) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_rounded,
              size: 32, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
          const SizedBox(height: 8),
          Text(
            _tx('No hay gastos para este filtro.', 'No expenses found for this filter.'),
            style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  // ── Shared widgets ────────────────────────────────────────────────────────

  Widget _badge(String label, Color color, AppTypography t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          color: color.withValues(alpha: 0.1),
        ),
        child: Text(
          label,
          style: t.bodySmall.copyWith(
              color: color, fontWeight: FontWeight.w700, fontSize: 11),
        ),
      );

  Widget _actionBtn(
    String label,
    IconData icon,
    Color color,
    bool busy,
    VoidCallback onTap,
    AppTypography t,
    ColorScheme cs,
  ) =>
      GestureDetector(
        onTap: busy ? null : onTap,
        child: AnimatedOpacity(
          opacity: busy ? 0.5 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                busy
                    ? SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                            strokeWidth: 1.5, color: color),
                      )
                    : Icon(icon, size: 13, color: color),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: t.bodySmall.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _dateField(String label, String? value, VoidCallback onTap) =>
      SizedBox(
        width: 150,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            ),
            child: Text(value ?? '—', style: const TextStyle(fontSize: 13)),
          ),
        ),
      );
}

