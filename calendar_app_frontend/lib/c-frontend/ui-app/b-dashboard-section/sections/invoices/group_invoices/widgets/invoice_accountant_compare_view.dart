import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/b-backend/invoicing/invoice_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/sections/invoice_editor_pdf.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/pdf_preview/pdf_preview_launcher.dart'
    as pdf_launcher;
import 'package:hexora/f-themes/font_type/typography_extension.dart';

class InvoiceAccountantCompareView extends StatefulWidget {
  const InvoiceAccountantCompareView({
    super.key,
    required this.groupId,
    required this.clients,
    required this.onEditInvoice,
  });

  final String groupId;
  final List<GroupClient> clients;
  final Future<void> Function(String invoiceId) onEditInvoice;

  @override
  State<InvoiceAccountantCompareView> createState() =>
      _InvoiceAccountantCompareViewState();
}

class _InvoiceAccountantCompareViewState
    extends State<InvoiceAccountantCompareView> {
  final InvoicesApi _api = InvoicesApi();
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _toleranceCtrl =
      TextEditingController(text: '0.05');

  PlatformFile? _file;
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _response;
  String _status = 'issued';
  String? _clientId;
  String? _currency;
  DateTime? _from;
  DateTime? _to;
  String _search = '';
  String _tab = 'all';
  bool _filtersExpanded = false;
  Map<String, dynamic>? _selectedRow;

  bool get _isEs =>
      Localizations.localeOf(context).languageCode.toLowerCase().startsWith('es');
  String _tx(String es, String en) => _isEs ? es : en;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      if (mounted) setState(() => _search = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _toleranceCtrl.dispose();
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

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      withData: true,
      allowedExtensions: const ['xlsx', 'xls'],
    );
    if (result == null || result.files.isEmpty || !mounted) return;
    setState(() {
      _file = result.files.single;
      _error = null;
    });
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
    setState(() {
      if (isFrom) {
        _from = picked;
      } else {
        _to = picked;
      }
    });
  }

  Future<void> _compare() async {
    final picked = _file;
    if (picked == null || picked.bytes == null) {
      setState(() =>
          _error = _tx('Debes subir un Excel.', 'You must upload an Excel file.'));
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _api.previewAccountantCompare(
        bytes: picked.bytes!,
        fileName: picked.name,
        groupId: widget.groupId,
        status: _status,
        from: _fmtDate(_from),
        to: _fmtDate(_to),
        clientId: _clientId,
        currency: _currency,
        tolerance: _toleranceCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _response = result;
        _tab = 'all';
        _selectedRow = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                _tx('No se pudo comparar el Excel.', 'Could not compare the Excel.'))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _rows {
    final raw = _response?['rows'];
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  List<Map<String, dynamic>> get _missingInAccountant {
    final raw = _response?['missingInAccountant'];
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  List<Map<String, dynamic>> get _visibleItems {
    final all = <Map<String, dynamic>>[
      ..._rows,
      ..._missingInAccountant
          .map((e) => <String, dynamic>{...e, '_missingInAccountant': true}),
    ];
    return all.where((row) {
      final isMissingInAccountant = row['_missingInAccountant'] == true;
      final status = isMissingInAccountant
          ? 'missing_in_accountant'
          : (row['matchStatus'] ?? '').toString();
      final invoice = (row['invoiceNumber'] ?? '').toString().toLowerCase();
      final accountantClient =
          (row['accountant']?['clientName'] ?? '').toString().toLowerCase();
      final hexoraClient =
          (row['hexora']?['clientName'] ?? '').toString().toLowerCase();
      final searchMatches = _search.isEmpty ||
          invoice.contains(_search) ||
          accountantClient.contains(_search) ||
          hexoraClient.contains(_search);
      if (!searchMatches) return false;
      switch (_tab) {
        case 'match':
          return status == 'match';
        case 'mismatch':
          return status == 'mismatch';
        case 'missing_in_hexora':
          return status == 'missing_in_hexora';
        case 'missing_in_accountant':
          return status == 'missing_in_accountant';
        default:
          return true;
      }
    }).toList(growable: false);
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'match':
        return _tx('Coincide', 'Match');
      case 'mismatch':
        return _tx('Diferencia', 'Mismatch');
      case 'missing_in_hexora':
        return _tx('Sin Hexora', 'No Hexora');
      case 'missing_in_accountant':
        return _tx('Sin asesoría', 'No accountant');
      default:
        return status;
    }
  }

  Color _statusColor(String status, ColorScheme cs) {
    switch (status) {
      case 'match':
        return cs.tertiary;
      case 'mismatch':
        return cs.error;
      case 'missing_in_hexora':
      case 'missing_in_accountant':
        return cs.primary;
      default:
        return cs.onSurfaceVariant;
    }
  }

  Future<void> _openInvoice(Map<String, dynamic> row) async {
    final id = (row['hexora']?['id'] ?? '').toString().trim();
    if (id.isEmpty) return;
    await widget.onEditInvoice(id);
  }

  Future<void> _previewPdf(Map<String, dynamic> row) async {
    final id = (row['hexora']?['id'] ?? '').toString().trim();
    if (id.isEmpty) return;
    try {
      final response = await _api.previewPdf(id);
      final bytes = InvoiceEditorPdf.validatePdf(response);
      await pdf_launcher.launchPdfPreview(
        bytes,
        fileName:
            'invoice-${(row['invoiceNumber'] ?? id).toString().replaceAll('/', '-')}.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final summary = _response?['summary'] is Map
        ? Map<String, dynamic>.from(_response!['summary'])
        : const <String, dynamic>{};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _topBar(cs, t),
        const SizedBox(height: 8),
        _filtersBar(cs, t),
        if (_error != null) ...[
          const SizedBox(height: 8),
          _errorBanner(cs),
        ],
        if (_response != null) ...[
          const SizedBox(height: 8),
          _statsRow(summary, cs),
          const SizedBox(height: 8),
          _tabsRow(summary, cs),
          const SizedBox(height: 8),
          Expanded(child: _resultsPanel(cs, t)),
        ] else
          const Expanded(child: SizedBox()),
      ],
    );
  }

  // ─── Top bar ─────────────────────────────────────────────────────────────────

  Widget _topBar(ColorScheme cs, AppTypography t) {
    final hasFile = _file != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cs.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.compare_arrows_rounded, size: 18, color: cs.secondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _tx('Comparar Excel de asesoría', 'Compare accountant Excel'),
                  style: t.bodyMedium.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  _tx(
                    'Sube el Excel de tu asesoría y detecta diferencias frente a Hexora.',
                    'Upload the accountant Excel and detect differences against Hexora.',
                  ),
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Upload zone chip
          GestureDetector(
            onTap: _loading ? null : _pickFile,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: hasFile
                    ? cs.secondary.withValues(alpha: 0.08)
                    : cs.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: hasFile
                      ? cs.secondary.withValues(alpha: 0.4)
                      : cs.outlineVariant.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    hasFile ? Icons.description_outlined : Icons.upload_file_rounded,
                    size: 14,
                    color: hasFile ? cs.secondary : cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    hasFile
                        ? (_file!.name.length > 28
                            ? '${_file!.name.substring(0, 25)}…'
                            : _file!.name)
                        : _tx('Subir Excel', 'Upload Excel'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: hasFile ? cs.secondary : cs.onSurfaceVariant,
                    ),
                  ),
                  if (hasFile) ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => setState(() => _file = null),
                      child: Icon(Icons.close_rounded,
                          size: 13, color: cs.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: _loading ? null : _compare,
            icon: _loading
                ? SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: cs.onSecondary),
                  )
                : const Icon(Icons.compare_arrows_rounded, size: 15),
            label: Text(
              _loading
                  ? _tx('Comparando…', 'Comparing…')
                  : _tx('Comparar', 'Compare'),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: cs.secondary,
              foregroundColor: cs.onSecondary,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Filters bar ─────────────────────────────────────────────────────────────

  Widget _filtersBar(ColorScheme cs, AppTypography t) {
    final hasFilters = _from != null ||
        _to != null ||
        _clientId != null ||
        _currency != null ||
        _status != 'issued';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () =>
                setState(() => _filtersExpanded = !_filtersExpanded),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(12),
              bottom: _filtersExpanded
                  ? Radius.zero
                  : const Radius.circular(12),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.tune_rounded,
                      size: 14, color: cs.onSurfaceVariant),
                  const SizedBox(width: 7),
                  Text(
                    _tx('Filtros', 'Filters'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  if (hasFilters) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: cs.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    '${_tx('Tolerancia', 'Tolerance')}: ',
                    style:
                        TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                  SizedBox(
                    width: 58,
                    height: 28,
                    child: TextField(
                      controller: _toleranceCtrl,
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(7),
                          borderSide: BorderSide(
                              color: cs.outlineVariant
                                  .withValues(alpha: 0.4)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(7),
                          borderSide: BorderSide(
                              color: cs.outlineVariant
                                  .withValues(alpha: 0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(7),
                          borderSide: BorderSide(
                              color: cs.secondary.withValues(alpha: 0.6)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _filtersExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 16,
                    color: cs.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (_filtersExpanded) ...[
            Divider(
                height: 1,
                color: cs.outlineVariant.withValues(alpha: 0.2)),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  SizedBox(
                    width: 160,
                    child: _compactDropdown<String>(
                      label: _tx('Estado', 'Status'),
                      value: _status,
                      items: [
                        DropdownMenuItem(
                            value: 'issued',
                            child: Text(_tx('Emitidas', 'Issued'))),
                        DropdownMenuItem(
                            value: 'draft',
                            child: Text(_tx('Borrador', 'Draft'))),
                        DropdownMenuItem(
                            value: 'void',
                            child: Text(_tx('Anuladas', 'Void'))),
                      ],
                      onChanged: (v) =>
                          setState(() => _status = v ?? 'issued'),
                      cs: cs,
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: _compactDropdown<String?>(
                      label: _tx('Cliente', 'Client'),
                      value: _clientId,
                      items: [
                        DropdownMenuItem<String?>(
                            value: null,
                            child: Text(_tx('Todos', 'All'))),
                        ...widget.clients.map((c) =>
                            DropdownMenuItem<String?>(
                                value: c.id, child: Text(c.name))),
                      ],
                      onChanged: (v) => setState(() => _clientId = v),
                      cs: cs,
                    ),
                  ),
                  SizedBox(
                    width: 130,
                    child: _compactDropdown<String?>(
                      label: _tx('Moneda', 'Currency'),
                      value: _currency,
                      items: [
                        DropdownMenuItem<String?>(
                            value: null,
                            child: Text(_tx('Todas', 'All'))),
                        const DropdownMenuItem<String?>(
                            value: 'EUR', child: Text('EUR')),
                      ],
                      onChanged: (v) => setState(() => _currency = v),
                      cs: cs,
                    ),
                  ),
                  _dateChip(_tx('Desde', 'From'), _fmtDate(_from),
                      () => _pickDate(true), cs),
                  _dateChip(_tx('Hasta', 'To'), _fmtDate(_to),
                      () => _pickDate(false), cs),
                  if (hasFilters)
                    TextButton.icon(
                      onPressed: () => setState(() {
                        _from = null;
                        _to = null;
                        _clientId = null;
                        _currency = null;
                        _status = 'issued';
                      }),
                      icon:
                          const Icon(Icons.restart_alt_rounded, size: 14),
                      label: Text(_tx('Limpiar', 'Reset'),
                          style: const TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        foregroundColor: cs.error,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 7),
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

  Widget _compactDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required ColorScheme cs,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: cs.secondary.withValues(alpha: 0.6)),
        ),
      ),
      style: const TextStyle(fontSize: 12),
      items: items,
      onChanged: onChanged,
    );
  }

  Widget _dateChip(
      String label, String? value, VoidCallback onTap, ColorScheme cs) {
    final hasValue = value != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasValue
                ? cs.secondary.withValues(alpha: 0.4)
                : cs.outlineVariant.withValues(alpha: 0.3),
          ),
          color: hasValue ? cs.secondary.withValues(alpha: 0.06) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 12,
                color: hasValue ? cs.secondary : cs.onSurfaceVariant),
            const SizedBox(width: 5),
            Text(
              '$label: ${value ?? '—'}',
              style: TextStyle(
                fontSize: 12,
                color: hasValue ? cs.secondary : cs.onSurfaceVariant,
                fontWeight:
                    hasValue ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Error banner ─────────────────────────────────────────────────────────────

  Widget _errorBanner(ColorScheme cs) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.errorContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 16, color: cs.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_error!,
                style: TextStyle(fontSize: 12, color: cs.error)),
          ),
          IconButton(
            onPressed: () => setState(() => _error = null),
            icon: Icon(Icons.close_rounded,
                size: 14, color: cs.error),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // ─── Stats row ────────────────────────────────────────────────────────────────

  Widget _statsRow(Map<String, dynamic> summary, ColorScheme cs) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _statChip(
              Icons.table_rows_rounded,
              _tx('Filas asesoría', 'Excel rows'),
              '${summary['accountantRows'] ?? 0}',
              cs.onSurfaceVariant,
              cs),
          const SizedBox(width: 6),
          _statChip(
              Icons.receipt_long_outlined,
              _tx('Facturas Hexora', 'Hexora invoices'),
              '${summary['hexoraInvoices'] ?? 0}',
              cs.onSurfaceVariant,
              cs),
          const SizedBox(width: 6),
          _statChip(
              Icons.check_circle_outline_rounded,
              _tx('Coinciden', 'Matches'),
              '${summary['matchedCount'] ?? 0}',
              cs.tertiary,
              cs),
          const SizedBox(width: 6),
          _statChip(
              Icons.warning_amber_rounded,
              _tx('Diferencias', 'Mismatches'),
              '${summary['mismatchCount'] ?? 0}',
              cs.error,
              cs),
          const SizedBox(width: 6),
          _statChip(
              Icons.remove_circle_outline_rounded,
              _tx('Sin Hexora', 'No Hexora'),
              '${summary['missingInHexoraCount'] ?? 0}',
              cs.primary,
              cs),
          const SizedBox(width: 6),
          _statChip(
              Icons.find_in_page_outlined,
              _tx('Sin asesoría', 'No accountant'),
              '${summary['missingInAccountantCount'] ?? 0}',
              cs.primary,
              cs),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label, String value,
      Color color, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 9,
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600)),
              Text(value,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: color,
                      height: 1.1)),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Tabs row ─────────────────────────────────────────────────────────────────

  Widget _tabsRow(Map<String, dynamic> summary, ColorScheme cs) {
    final tabs = [
      ('all', _tx('Todas', 'All'), null),
      ('match', _tx('Coinciden', 'Matches'), summary['matchedCount']),
      ('mismatch', _tx('Diferencias', 'Mismatches'),
          summary['mismatchCount']),
      ('missing_in_hexora', _tx('Sin Hexora', 'No Hexora'),
          summary['missingInHexoraCount']),
      ('missing_in_accountant', _tx('Sin asesoría', 'No accountant'),
          summary['missingInAccountantCount']),
    ];
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final tab in tabs)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: _tabChip(tab.$1, tab.$2, tab.$3, cs),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 220,
          height: 34,
          child: TextField(
            controller: _searchCtrl,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: _tx('Buscar factura…', 'Search invoice…'),
              hintStyle: TextStyle(
                  fontSize: 12,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
              prefixIcon: Icon(Icons.search_rounded,
                  size: 15, color: cs.onSurfaceVariant),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 34),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.4)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color: cs.secondary.withValues(alpha: 0.6)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tabChip(
      String id, String label, dynamic count, ColorScheme cs) {
    final selected = _tab == id;
    return GestureDetector(
      onTap: () => setState(() => _tab = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? cs.secondary.withValues(alpha: 0.12)
              : cs.surfaceContainerHighest.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? cs.secondary.withValues(alpha: 0.4)
                : cs.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
                color:
                    selected ? cs.secondary : cs.onSurfaceVariant,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: selected
                      ? cs.secondary.withValues(alpha: 0.2)
                      : cs.outlineVariant.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? cs.secondary
                        : cs.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Results panel (split) ────────────────────────────────────────────────────

  Widget _resultsPanel(ColorScheme cs, AppTypography t) {
    final items = _visibleItems;
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 32,
                color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
            const SizedBox(height: 8),
            Text(
              _tx('No hay resultados para este filtro.',
                  'No results for this filter.'),
              style:
                  TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 780;
        if (!wide) {
          return _listPanel(items, cs, t, singleCol: true);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 340,
                child: _listPanel(items, cs, t, singleCol: false)),
            const SizedBox(width: 10),
            Expanded(
              child: _selectedRow != null
                  ? _detailPanel(_selectedRow!, cs, t)
                  : _emptyDetail(cs),
            ),
          ],
        );
      },
    );
  }

  Widget _emptyDetail(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.touch_app_outlined,
                size: 28,
                color: cs.onSurfaceVariant.withValues(alpha: 0.25)),
            const SizedBox(height: 8),
            Text(
              _tx('Selecciona una fila para ver el detalle',
                  'Select a row to view details'),
              style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── List panel ───────────────────────────────────────────────────────────────

  Widget _listPanel(List<Map<String, dynamic>> items, ColorScheme cs,
      AppTypography t,
      {required bool singleCol}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.2),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                Text(
                  '${items.length} ${_tx('resultados', 'results')}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Divider(
              height: 1,
              color: cs.outlineVariant.withValues(alpha: 0.2)),
          Expanded(
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: cs.outlineVariant.withValues(alpha: 0.12)),
              itemBuilder: (context, index) =>
                  _listRow(items[index], cs, t, singleCol: singleCol),
            ),
          ),
        ],
      ),
    );
  }

  Widget _listRow(Map<String, dynamic> row, ColorScheme cs,
      AppTypography t,
      {required bool singleCol}) {
    final missingInAccountant = row['_missingInAccountant'] == true;
    final status = missingInAccountant
        ? 'missing_in_accountant'
        : (row['matchStatus'] ?? '').toString();
    final color = _statusColor(status, cs);
    final isSelected = !singleCol && identical(_selectedRow, row);
    final hexora = row['hexora'] is Map
        ? Map<String, dynamic>.from(row['hexora'])
        : const <String, dynamic>{};
    final accountant = row['accountant'] is Map
        ? Map<String, dynamic>.from(row['accountant'])
        : const <String, dynamic>{};
    final clientName =
        (accountant['clientName'] ?? hexora['clientName'] ?? '—')
            .toString();
    final total = hexora['total'] ?? accountant['total'];

    return InkWell(
      onTap: () {
        if (singleCol) {
          showDialog(
            context: context,
            builder: (_) => Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: SizedBox(
                width: 560,
                height: 520,
                child: _detailPanel(row, cs, t),
              ),
            ),
          );
        } else {
          setState(() => _selectedRow = row);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        color: isSelected
            ? cs.secondary.withValues(alpha: 0.06)
            : Colors.transparent,
        child: Row(
          children: [
            Container(
                width: 3,
                height: 54,
                color: color.withValues(alpha: 0.7)),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (row['invoiceNumber'] ?? '—').toString(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? cs.secondary : null,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            clientName,
                            style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurfaceVariant),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (total != null)
                          Text(
                            _money(total),
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700),
                          ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _statusLabel(status),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Detail panel ─────────────────────────────────────────────────────────────

  Widget _detailPanel(
      Map<String, dynamic> row, ColorScheme cs, AppTypography t) {
    final missingInAccountant = row['_missingInAccountant'] == true;
    final status = missingInAccountant
        ? 'missing_in_accountant'
        : (row['matchStatus'] ?? '').toString();
    final color = _statusColor(status, cs);
    final hexora = row['hexora'] is Map
        ? Map<String, dynamic>.from(row['hexora'])
        : const <String, dynamic>{};
    final accountant = row['accountant'] is Map
        ? Map<String, dynamic>.from(row['accountant'])
        : const <String, dynamic>{};
    final deltas = row['deltas'] is Map
        ? Map<String, dynamic>.from(row['deltas'])
        : const <String, dynamic>{};
    final reasons = row['reasons'] is List
        ? (row['reasons'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : const <Map<String, dynamic>>[];
    final clientName =
        (accountant['clientName'] ?? hexora['clientName'] ?? '—')
            .toString();
    final invoiceNumber = (row['invoiceNumber'] ?? '—').toString();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.2),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.receipt_long_outlined,
                      size: 15, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(invoiceNumber,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800)),
                      Text(clientName,
                          style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurfaceVariant),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: color.withValues(alpha: 0.2)),
                  ),
                  child: Text(_statusLabel(status),
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color)),
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: () => setState(() => _selectedRow = null),
                  icon: Icon(Icons.close_rounded,
                      size: 16, color: cs.onSurfaceVariant),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 28, minHeight: 28),
                ),
              ],
            ),
          ),
          Divider(
              height: 1,
              color: cs.outlineVariant.withValues(alpha: 0.2)),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Meta chips
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _metaChip(
                          Icons.tag_rounded,
                          '${_tx('Fila Excel', 'Excel row')}: ${row['sourceRowNumber'] ?? '—'}',
                          cs),
                      _metaChip(
                          Icons.calendar_today_outlined,
                          '${_tx('Asesoría', 'Accountant')}: ${_date(accountant['issueDate'])}',
                          cs),
                      _metaChip(
                          Icons.calendar_today_outlined,
                          'Hexora: ${_date(hexora['issueDate'])}',
                          cs),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _comparisonTable(
                      accountant, hexora, deltas, color, cs, t),
                  if (reasons.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                        _tx('Motivos detectados', 'Detected reasons'),
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    ...reasons
                        .map((r) => _reasonRow(r, color, cs, t)),
                  ],
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if ((hexora['id'] ?? '').toString().trim().isNotEmpty)
                        _actionBtn(
                            Icons.edit_outlined,
                            _tx('Abrir factura', 'Open invoice'),
                            () => _openInvoice(row),
                            cs.secondary,
                            cs),
                      if ((hexora['id'] ?? '').toString().trim().isNotEmpty)
                        _actionBtn(
                            Icons.picture_as_pdf_outlined,
                            _tx('Ver PDF', 'View PDF'),
                            () => _previewPdf(row),
                            cs.onSurfaceVariant,
                            cs),
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

  Widget _metaChip(IconData icon, String label, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: cs.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _comparisonTable(
    Map<String, dynamic> accountant,
    Map<String, dynamic> hexora,
    Map<String, dynamic> deltas,
    Color color,
    ColorScheme cs,
    AppTypography t,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.2),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(9)),
            ),
            child: Row(
              children: [
                const Expanded(flex: 2, child: SizedBox()),
                Expanded(
                  flex: 3,
                  child: Text(
                    _tx('Asesoría', 'Accountant'),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurfaceVariant),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Hexora',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurfaceVariant),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Δ',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
          Divider(
              height: 1,
              color: cs.outlineVariant.withValues(alpha: 0.2)),
          _tableRow(_tx('Base', 'Base'), accountant['subtotal'],
              hexora['subtotal'], deltas['subtotal'], false, color, cs),
          Divider(
              height: 1,
              color: cs.outlineVariant.withValues(alpha: 0.1)),
          _tableRow('IVA', accountant['taxTotal'], hexora['taxTotal'],
              deltas['taxTotal'], false, color, cs),
          Divider(
              height: 1,
              color: cs.outlineVariant.withValues(alpha: 0.1)),
          _tableRow(_tx('Total', 'Total'), accountant['total'],
              hexora['total'], deltas['total'], true, color, cs),
        ],
      ),
    );
  }

  Widget _tableRow(
    String label,
    dynamic accountantVal,
    dynamic hexoraVal,
    dynamic deltaVal,
    bool isTotal,
    Color color,
    ColorScheme cs,
  ) {
    final delta = deltaVal is num
        ? deltaVal.toDouble()
        : double.tryParse('$deltaVal');
    final hasDelta = delta != null && delta.abs() > 0.001;

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      color: isTotal && hasDelta ? color.withValues(alpha: 0.05) : null,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    isTotal ? FontWeight.w700 : FontWeight.w500,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              _money(accountantVal),
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      isTotal ? FontWeight.w700 : FontWeight.w400),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              _money(hexoraVal),
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      isTotal ? FontWeight.w700 : FontWeight.w400),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              hasDelta ? _money(deltaVal) : '—',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: hasDelta
                    ? color
                    : cs.onSurfaceVariant.withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reasonRow(Map<String, dynamic> reason, Color color,
      ColorScheme cs, AppTypography t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withValues(alpha: 0.05),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 12, color: color),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  (reason['message'] ?? reason['code'] ?? '')
                      .toString(),
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color),
                ),
              ),
            ],
          ),
          if (reason['accountant'] != null ||
              reason['hexora'] != null) ...[
            const SizedBox(height: 4),
            Text(
              '${_tx('Asesoría', 'Accountant')}: ${_money(reason['accountant'])} · '
              'Hexora: ${_money(reason['hexora'])} · '
              'Δ ${_money(reason['delta'])}',
              style: TextStyle(
                  fontSize: 11, color: cs.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap,
      Color color, ColorScheme cs) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14, color: color),
      label: Text(label,
          style: TextStyle(fontSize: 12, color: color)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        side: BorderSide(color: color.withValues(alpha: 0.3)),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
