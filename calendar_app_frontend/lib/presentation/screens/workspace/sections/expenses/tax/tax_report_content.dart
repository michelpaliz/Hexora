part of 'tax_reporting_view.dart';

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : {};
List<Map<String, dynamic>> _rows(dynamic value) => value is List
    ? value
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList()
    : [];
dynamic _read(Map<String, dynamic> row, List<String> keys) {
  for (final key in keys) {
    if (row[key] != null) return row[key];
  }
  return null;
}

String _text(dynamic value) =>
    value == null || value is Map || value is List ? '—' : value.toString();
String _party(Map<String, dynamic> row, String type) => _text(
    row['${type}Name'] ?? _map(row[type])['name'] ?? row[type] ?? row['name']);
String _date(dynamic value) {
  final date = DateTime.tryParse(value?.toString() ?? '');
  return date == null ? '—' : DateFormat('dd/MM/yyyy').format(date);
}

dynamic _base(Map<String, dynamic> row) =>
    _read(row, ['baseTotal', 'taxBase', 'base', 'subtotal']);
dynamic _vat(Map<String, dynamic> row) =>
    _read(row, ['vatTotal', 'vat', 'tax', 'taxTotal']);
dynamic _total(Map<String, dynamic> row) {
  const keys = [
    'total',
    'grossTotal',
    'totalAmount',
    'grandTotal',
    'amountTotal'
  ];
  return _read(row, keys) ?? _read(_map(row['totals']), keys);
}

List<Map<String, dynamic>> _rateRows(dynamic raw) => raw is Map
    ? raw.entries
        .map((entry) => {..._map(entry.value), 'rate': entry.key})
        .toList()
    : _rows(raw);

dynamic _vatReportTotal(Map<String, dynamic> row) {
  final total = _total(row);
  if (total != null) return total;
  final rates = _rateRows(row['byVatRate']);
  // Some report rows only return totals inside the rate breakdown. Reuse that
  // backend total only when a single rate covers this entire summary row.
  // Never add amounts here (especially for mixed-rate invoices).
  if (rates.length != 1) return null;
  final base = parseFlexibleMoney(_base(row));
  final vat = parseFlexibleMoney(_vat(row));
  final rate = rates.single;
  if (base == null ||
      vat == null ||
      base != parseFlexibleMoney(_base(rate)) ||
      vat != parseFlexibleMoney(_vat(rate))) {
    return null;
  }
  return _total(rate);
}

dynamic _count(Map<String, dynamic> row) {
  final direct = _read(row, [
    'count',
    'documentCount',
    'documentsCount',
    'records',
    'invoiceCount',
    'invoicesCount',
    'totalInvoices',
    'expenseCount',
  ]);
  if (direct != null) return direct;
  for (final key in const ['invoices', 'documents']) {
    final list = row[key];
    if (list is List) return list.length;
  }
  return null;
}

/// Presentation-only icon/color pairing for a summary card, inferred from its
/// label text. Purely cosmetic — does not affect which value is displayed.
class _CardMeta {
  const _CardMeta(this.icon, this.color);
  final IconData icon;
  final Color Function(ColorScheme cs) color;
}

_CardMeta _cardMeta(String label, dynamic value) {
  final lower = label.toLowerCase();
  if (lower.contains('revisión') || lower.contains('revision')) {
    return _CardMeta(
        Icons.warning_amber_rounded, (cs) => const Color(0xFFD97706));
  }
  if (lower.contains('resultado') ||
      lower.contains('pagar') ||
      lower.contains('compensar') ||
      lower.contains('equilibr')) {
    final amount = parseFlexibleMoney(value);
    if (amount == null || amount == 0) {
      return _CardMeta(Icons.balance_rounded, (cs) => cs.onSurfaceVariant);
    }
    return amount > 0
        ? _CardMeta(Icons.arrow_circle_up_rounded, (cs) => cs.error)
        : _CardMeta(Icons.arrow_circle_down_rounded, (cs) => cs.primary);
  }
  if (lower.contains('soportado') ||
      lower.contains('deducible') ||
      lower.contains('compras') ||
      lower.contains('gasto')) {
    return _CardMeta(Icons.shopping_bag_outlined, (cs) => cs.tertiary);
  }
  if (lower.contains('iva') || lower.contains('irpf')) {
    return _CardMeta(Icons.percent_rounded, (cs) => cs.primary);
  }
  if (lower.contains('base') ||
      lower.contains('importe') ||
      lower.contains('bruto') ||
      lower.contains('pagadero') ||
      lower.contains('ventas')) {
    return _CardMeta(Icons.trending_up_rounded, (cs) => cs.primary);
  }
  return _CardMeta(Icons.receipt_long_rounded, (cs) => cs.onSurfaceVariant);
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard(
      {required this.label, required this.value, required this.isMoney});
  final String label;
  final dynamic value;
  final bool isMoney;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final meta = _cardMeta(label, value);
    final color = meta.color(cs);
    final displayValue = isMoney ? formatTaxEur(value) : _text(value);
    // Bare segment — no border/shadow of its own. It's laid out inside the
    // shared composed bar in `_cards`, which owns the single outer frame and
    // the divider between this and its neighboring segments.
    return Container(
      key: ValueKey('tax-summary-card-$label'),
      constraints: const BoxConstraints(minHeight: _summaryBarItemHeight),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(meta.icon, size: 17, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodySmall.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  displayValue,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.titleLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: cs.onSurface,
                    letterSpacing: -0.2,
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

class _ColumnFilterResult {
  const _ColumnFilterResult(this.selectedValues, this.sortAscending);

  final Set<String> selectedValues;
  final bool? sortAscending;
}

/// Positioned in the root overlay so the table's horizontal clip cannot hide it.
class _ColumnFilterPopover extends StatelessWidget {
  const _ColumnFilterPopover({required this.anchor, required this.child});
  final Rect anchor;
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final media = MediaQuery.of(context);
          final available = Rect.fromLTRB(
            media.padding.left + 12,
            media.padding.top + 12,
            constraints.maxWidth - media.padding.right - 12,
            constraints.maxHeight -
                media.viewInsets.bottom -
                media.padding.bottom -
                12,
          );
          final width = available.width.clamp(0.0, 360.0);
          final height = available.height.clamp(0.0, 500.0);
          final left =
              anchor.left.clamp(available.left, available.right - width);
          final preferredTop = anchor.bottom + 6;
          final top = (preferredTop + height <= available.bottom
                  ? preferredTop
                  : anchor.top - height - 6)
              .clamp(available.top, available.bottom - height);
          return Stack(children: [
            Positioned(
              left: left,
              top: top,
              width: width,
              height: height,
              child: Material(
                elevation: 12,
                shadowColor:
                    Theme.of(context).colorScheme.shadow.withValues(alpha: .18),
                color: Theme.of(context).colorScheme.surface,
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant),
                ),
                clipBehavior: Clip.antiAlias,
                // Short viewports and the on-screen keyboard must not hide actions.
                child: SingleChildScrollView(
                  child: SizedBox(
                      height: height < 380 ? 380 : height, child: child),
                ),
              ),
            ),
          ]);
        },
      );
}

class _ColumnFilterDialog extends StatefulWidget {
  const _ColumnFilterDialog({
    required this.column,
    required this.values,
    required this.selectedValues,
    required this.sortAscending,
  });

  final String column;
  final List<String> values;
  final Set<String> selectedValues;
  final bool? sortAscending;

  @override
  State<_ColumnFilterDialog> createState() => _ColumnFilterDialogState();
}

class _ColumnFilterDialogState extends State<_ColumnFilterDialog> {
  late final Set<String> _selectedValues;
  late bool? _sortAscending;
  final _search = TextEditingController();
  final _scroll = ScrollController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selectedValues = {...widget.selectedValues};
    _sortAscending = widget.sortAscending;
  }

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final visibleValues = widget.values
        .where((value) => value.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    final visibleSet = visibleValues.toSet();
    // Applying a search includes only checked matches, never hidden selections.
    final effectiveSelection = _selectedValues.intersection(visibleSet);
    final allVisibleSelected = visibleValues.isNotEmpty &&
        effectiveSelection.length == visibleValues.length;
    final bool? selectAllValue = allVisibleSelected
        ? true
        : effectiveSelection.isEmpty
            ? false
            : null;

    Widget sortButton(bool ascending) {
      final selected = _sortAscending == ascending;
      return Expanded(
        child: TextButton.icon(
          onPressed: () =>
              setState(() => _sortAscending = selected ? null : ascending),
          icon: Icon(
              ascending
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              size: 16),
          label: Text(ascending ? 'Ascendente' : 'Descendente'),
          style: TextButton.styleFrom(
            foregroundColor: selected ? cs.primary : cs.onSurfaceVariant,
            backgroundColor: selected
                ? cs.primary.withValues(alpha: .1)
                : cs.surfaceContainerLow,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle:
                const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 6, 0),
        child: Row(children: [
          Icon(Icons.filter_alt_outlined, size: 18, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(
              child: Text(widget.column,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis)),
          IconButton(
            tooltip: 'Cerrar',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 2, 12, 10),
        child: Row(children: [
          sortButton(true),
          const SizedBox(width: 8),
          sortButton(false)
        ]),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: TextField(
          key: const ValueKey('tax-column-filter-search'),
          controller: _search,
          style: const TextStyle(fontSize: 13),
          onChanged: (value) => setState(() => _query = value.trim()),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: cs.surfaceContainerLow,
            prefixIcon: const Icon(Icons.search_rounded, size: 18),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Borrar búsqueda',
                    icon: const Icon(Icons.close_rounded, size: 16),
                    onPressed: () {
                      _search.clear();
                      setState(() => _query = '');
                    },
                  ),
            hintText: 'Buscar y filtrar valores',
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
          ),
        ),
      ),
      CheckboxListTile(
        key: const ValueKey('tax-filter-select-all'),
        dense: true,
        tristate: true,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        value: selectAllValue,
        title: Text(
            _query.isEmpty ? 'Todos los valores' : 'Todos los resultados',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        secondary: Text('${visibleValues.length}',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        onChanged: visibleValues.isEmpty
            ? null
            : (_) => setState(() {
                  if (allVisibleSelected) {
                    _selectedValues.removeAll(visibleSet);
                  } else {
                    _selectedValues.addAll(visibleSet);
                  }
                }),
      ),
      Divider(height: 1, color: cs.outlineVariant),
      Expanded(
        child: visibleValues.isEmpty
            ? Center(
                child: Text('No hay valores coincidentes.',
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)))
            : Scrollbar(
                controller: _scroll,
                thumbVisibility: true,
                child: ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: visibleValues.length,
                  itemBuilder: (context, index) {
                    final value = visibleValues[index];
                    return CheckboxListTile(
                      key: ValueKey('tax-filter-value-$value'),
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      value: _selectedValues.contains(value),
                      title: Text(value, style: const TextStyle(fontSize: 13)),
                      onChanged: (selected) => setState(() {
                        if (selected == true) {
                          _selectedValues.add(value);
                        } else {
                          _selectedValues.remove(value);
                        }
                      }),
                    );
                  },
                ),
              ),
      ),
      Divider(height: 1, color: cs.outlineVariant),
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Row(children: [
          Expanded(
              child: TextButton(
            onPressed: () => Navigator.pop(context,
                _ColumnFilterResult(widget.values.toSet(), _sortAscending)),
            child: const Text('Limpiar filtro', style: TextStyle(fontSize: 12)),
          )),
          const SizedBox(width: 8),
          Expanded(
              child: FilledButton(
            key: const ValueKey('tax-apply-column-filter'),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              textStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            onPressed: () => Navigator.pop(
                context,
                _ColumnFilterResult(
                    _selectedValues.intersection(visibleSet), _sortAscending)),
            child: Text('Aplicar (${effectiveSelection.length})'),
          )),
        ]),
      ),
    ]);
  }
}

class _ClientInvoiceNumbers extends StatelessWidget {
  const _ClientInvoiceNumbers({
    required this.clientName,
    required this.numbers,
    required this.expectedCount,
  });
  final String clientName;
  final List<String> numbers;
  final double? expectedCount;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final incomplete = expectedCount != null && numbers.length < expectedCount!;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 6, 0),
        child: Row(children: [
          Icon(Icons.receipt_long_outlined, size: 18, color: cs.primary),
          const SizedBox(width: 8),
          const Expanded(
              child: Text('Facturas del cliente',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
          IconButton(
              tooltip: 'Cerrar',
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded, size: 18)),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Text(clientName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
      ),
      Divider(height: 1, color: cs.outlineVariant),
      if (incomplete && numbers.isNotEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Text(
              '${numbers.length} de ${expectedCount!.toInt()} números disponibles.',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        ),
      Expanded(
        child: numbers.isEmpty
            ? Center(
                child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                    expectedCount == 0
                        ? 'No hay facturas para este cliente en el período.'
                        : 'El informe incluye el recuento, pero no los números de factura de este cliente.',
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                    textAlign: TextAlign.center),
              ))
            : ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: numbers.length,
                separatorBuilder: (_, __) => Divider(
                    height: 1, color: cs.outlineVariant.withValues(alpha: .5)),
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: SelectableText(numbers[i],
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: cs.primary)),
                ),
              ),
      ),
    ]);
  }
}

/// Client-grouped breakdown for the sales report, with its own independent
/// filter/sort state (kept separate from the invoice table's, since both can
/// be reached from the same section via tabs).
class _ClientGroupTable extends StatefulWidget {
  const _ClientGroupTable({required this.rows, required this.invoices});
  final List<Map<String, dynamic>> rows;
  final List<Map<String, dynamic>> invoices;

  @override
  State<_ClientGroupTable> createState() => _ClientGroupTableState();
}

class _ClientGroupTableState extends State<_ClientGroupTable> {
  static const _columns = [
    'Cliente',
    'Facturas',
    'Base imponible',
    'IVA',
    'Total'
  ];
  static const _rightAlignFrom = 2;

  final _selectedValues = <int, Set<String>>{};
  int? _sortColumn;
  bool _sortAscending = true;

  List<String> _invoiceNumbers(Map<String, dynamic> client) {
    String? id(dynamic value) =>
        value is String && value.trim().isNotEmpty ? value.trim() : null;
    String? clientId(Map<String, dynamic> row) =>
        id(row['clientId']) ??
        id(_map(row['client'])['_id']) ??
        id(_map(row['client'])['id']);
    final groupId = clientId(client) ?? id(client['_id']);
    final numbers = <String>{};
    void addNumber(dynamic value) {
      if (value is String && value.trim().isNotEmpty) numbers.add(value.trim());
      if (value is num) numbers.add(value.toString());
    }

    for (final value in client['invoiceNumbers'] is List
        ? client['invoiceNumbers'] as List
        : const []) {
      addNumber(value);
    }
    for (final invoice in _rows(client['invoices'])) {
      addNumber(_read(invoice, ['invoiceNumber', 'number']));
    }
    if (groupId != null) {
      for (final invoice in widget.invoices) {
        if (clientId(invoice) == groupId) {
          addNumber(_read(invoice, ['invoiceNumber', 'number']));
        }
      }
    }
    return numbers.toList();
  }

  Future<void> _showInvoices(
      Map<String, dynamic> client, BuildContext cellContext) async {
    final cell = cellContext.findRenderObject()! as RenderBox;
    final overlay = Navigator.of(context, rootNavigator: true)
        .overlay!
        .context
        .findRenderObject()! as RenderBox;
    final anchor =
        cell.localToGlobal(Offset.zero, ancestor: overlay) & cell.size;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 140),
      pageBuilder: (context, animation, secondaryAnimation) =>
          _ColumnFilterPopover(
        anchor: anchor,
        child: _ClientInvoiceNumbers(
          clientName: _party(client, 'client'),
          numbers: _invoiceNumbers(client),
          expectedCount: parseFlexibleMoney(_count(client)),
        ),
      ),
      transitionBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(opacity: animation, child: child),
    );
  }

  String _columnText(Map<String, dynamic> row, int column) => switch (column) {
        0 => _party(row, 'client'),
        1 => _text(_count(row)),
        2 => formatTaxEur(_base(row)),
        3 => formatTaxEur(_vat(row)),
        _ => formatTaxEur(_total(row)),
      };

  dynamic _sortValue(Map<String, dynamic> row, int column) {
    if (column >= _rightAlignFrom) {
      return parseFlexibleMoney(switch (column - _rightAlignFrom) {
        0 => _base(row),
        1 => _vat(row),
        _ => _total(row),
      });
    }
    if (column == 1) return parseFlexibleMoney(_count(row));
    return _columnText(row, column).toLowerCase();
  }

  int _compare(dynamic left, dynamic right) {
    if (left == null && right == null) return 0;
    if (left == null) return 1;
    if (right == null) return -1;
    if (left is num && right is num) return left.compareTo(right);
    return left.toString().compareTo(right.toString());
  }

  Future<void> _openColumnFilter(int column, BuildContext headerContext) async {
    final availableRows = widget.rows
        .where((row) => _selectedValues.entries
            .where((filter) => filter.key != column)
            .every((filter) =>
                filter.value.contains(_columnText(row, filter.key))))
        .toList()
      ..sort((a, b) => _compare(_sortValue(a, column), _sortValue(b, column)));
    final values =
        availableRows.map((row) => _columnText(row, column)).toSet().toList();
    final header = headerContext.findRenderObject()! as RenderBox;
    final overlay = Navigator.of(context, rootNavigator: true)
        .overlay!
        .context
        .findRenderObject()! as RenderBox;
    final anchor =
        header.localToGlobal(Offset.zero, ancestor: overlay) & header.size;
    final result = await showGeneralDialog<_ColumnFilterResult>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 140),
      pageBuilder: (context, animation, secondaryAnimation) =>
          _ColumnFilterPopover(
        anchor: anchor,
        child: _ColumnFilterDialog(
          column: _columns[column],
          values: values,
          selectedValues: _selectedValues[column] ?? values.toSet(),
          sortAscending: _sortColumn == column ? _sortAscending : null,
        ),
      ),
      transitionBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(opacity: animation, child: child),
    );
    if (result == null || !context.mounted) return;
    setState(() {
      if (result.selectedValues.length == values.length) {
        _selectedValues.remove(column);
      } else {
        _selectedValues[column] = result.selectedValues;
      }
      if (result.sortAscending != null) {
        _sortColumn = column;
        _sortAscending = result.sortAscending!;
      } else if (_sortColumn == column) {
        _sortColumn = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final visibleRows = [
      for (var i = 0; i < widget.rows.length; i++)
        (index: i, row: widget.rows[i])
    ]
        .where((entry) => _selectedValues.entries.every((filter) =>
            filter.value.contains(_columnText(entry.row, filter.key))))
        .toList()
      ..sort((left, right) {
        if (_sortColumn == null) return left.index.compareTo(right.index);
        final result = _compare(_sortValue(left.row, _sortColumn!),
            _sortValue(right.row, _sortColumn!));
        if (result == 0) return left.index.compareTo(right.index);
        return _sortAscending ? result : -result;
      });

    Widget headerLabel(int i) => Builder(
          builder: (headerContext) => Tooltip(
            message: 'Filtrar por ${_columns[i]}',
            child: InkWell(
              key: ValueKey('tax-client-column-filter-${_columns[i]}'),
              onTap: () => _openColumnFilter(i, headerContext),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(_columns[i]),
                const SizedBox(width: 6),
                Icon(
                  _selectedValues.containsKey(i)
                      ? Icons.filter_alt_rounded
                      : Icons.filter_alt_outlined,
                  size: 15,
                  color: _selectedValues.containsKey(i)
                      ? cs.primary
                      : cs.onSurfaceVariant.withValues(alpha: .62),
                ),
                if (_sortColumn == i) ...[
                  const SizedBox(width: 2),
                  Icon(
                    _sortAscending
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 14,
                    color: cs.primary,
                  ),
                ],
              ]),
            ),
          ),
        );

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (_selectedValues.isNotEmpty || _sortColumn != null)
          Container(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
            child: Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: 'Restablecer tabla',
                icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                onPressed: () => setState(() {
                  _selectedValues.clear();
                  _sortColumn = null;
                }),
              ),
            ),
          ),
        SingleChildScrollView(
          key: const PageStorageKey('tax-client-group-table'),
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStatePropertyAll(
                cs.surfaceContainerHighest.withValues(alpha: 0.4)),
            headingTextStyle: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
              color: cs.onSurfaceVariant,
              letterSpacing: 0.1,
            ),
            dataRowMinHeight: 46,
            dataRowMaxHeight: 56,
            columns: [
              for (var i = 0; i < _columns.length; i++)
                DataColumn(label: headerLabel(i), numeric: i >= _rightAlignFrom)
            ],
            rows: [
              for (var i = 0; i < visibleRows.length; i++)
                DataRow(
                  color: WidgetStatePropertyAll(i.isEven
                      ? Colors.transparent
                      : cs.surfaceContainerHighest.withValues(alpha: 0.18)),
                  cells: [
                    DataCell(Text(_party(visibleRows[i].row, 'client'))),
                    DataCell(Builder(
                        builder: (cellContext) => TextButton.icon(
                              onPressed: () => _showInvoices(
                                  visibleRows[i].row, cellContext),
                              icon: const Icon(Icons.receipt_long_outlined,
                                  size: 16),
                              label: Text(_text(_count(visibleRows[i].row))),
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                            ))),
                    DataCell(Text(formatTaxEur(_base(visibleRows[i].row)))),
                    DataCell(Text(formatTaxEur(_vat(visibleRows[i].row)))),
                    DataCell(Text(formatTaxEur(_total(visibleRows[i].row)),
                        style: const TextStyle(fontWeight: FontWeight.w700))),
                  ],
                )
            ],
          ),
        ),
        if (visibleRows.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('No hay resultados para estos filtros.',
                style: TextStyle(color: cs.onSurfaceVariant)),
          ),
      ]),
    );
  }
}

/// Report-specific composition of existing cards, tables and empty states.
/// Report metrics are displayed as returned. The invoice footer sums the
/// displayed rows independently of the full-period report metrics.
class _TaxReportContent extends StatefulWidget {
  const _TaxReportContent(
      {super.key,
      required this.section,
      required this.data,
      required this.filters,
      required this.onRefresh});
  final TaxReportSection section;
  final Map<String, dynamic> data;
  final Widget filters;
  final VoidCallback onRefresh;

  @override
  State<_TaxReportContent> createState() => _TaxReportContentState();
}

class _TaxReportContentState extends State<_TaxReportContent> {
  TaxReportSection get section => widget.section;
  Map<String, dynamic> get data => widget.data;
  Widget get filters => widget.filters;
  final selectedValues = <int, Set<String>>{};
  int? sortColumn;
  bool sortAscending = false;

  int? get _defaultSortColumn => section == TaxReportSection.charged ? 0 : null;

  @override
  void initState() {
    super.initState();
    sortColumn = _defaultSortColumn;
  }

  Widget _empty(
          [String message =
              'No hay registros para el período seleccionado.']) =>
      EmptyHint(
          title: 'Sin datos',
          message: message,
          tip: 'Selecciona otro período para consultar sus registros.',
          icon: Icons.receipt_long_outlined);

  // The period filter and the metric chips are rendered as segments of one
  // composed bar (single border/shadow, thin dividers between segments)
  // rather than as separate floating cards.
  Widget _cards(List<(String, dynamic, bool)> values) =>
      LayoutBuilder(builder: (context, constraints) {
        final cs = Theme.of(context).colorScheme;
        final width = constraints.maxWidth;
        final phone = width < 600;
        final oneColumn = width < 480;
        final filterWidth = phone ? width : (width < 980 ? 320.0 : 390.0);
        final cardWidth = oneColumn
            ? width
            : phone
                ? (width - 10) / 2
                : 220.0;
        final dividerColor = cs.outlineVariant.withValues(alpha: 0.5);
        final segments = <Widget>[
          SizedBox(width: filterWidth, child: filters),
          for (final value in values)
            SizedBox(
              width: cardWidth,
              child: _SummaryCard(
                label: value.$1,
                value: value.$2,
                isMoney: value.$3,
              ),
            ),
        ];
        return Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 0,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  children: [
                    for (var i = 0; i < segments.length; i++)
                      i == 0
                          ? segments[i]
                          : Container(
                              decoration: BoxDecoration(
                                border: Border(
                                    left: BorderSide(color: dividerColor)),
                              ),
                              child: segments[i],
                            ),
                  ],
                ),
              ),
              // Pinned to the bar's trailing edge so it stays put regardless
              // of how the metric chips wrap on narrower widths.
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: dividerColor)),
                ),
                child: IconButton(
                  tooltip: 'Actualizar',
                  onPressed: widget.onRefresh,
                  icon: const Icon(Icons.refresh),
                ),
              ),
            ],
          ),
        );
      });

  static const _numericTableHeaders = {
    'Base imponible',
    'IVA',
    'Total',
    'Documentos',
    'Registros',
    'Importe bruto',
    'IRPF retenido',
    'Importe pagadero',
    'Facturas',
    'Porcentaje',
  };

  Widget _table(List<String> columns, List<List<Widget>> rows) =>
      Builder(builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            key: PageStorageKey('tax-table-${columns.join('|')}'),
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStatePropertyAll(
                  cs.surfaceContainerHighest.withValues(alpha: 0.4)),
              headingTextStyle: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
                color: cs.onSurfaceVariant,
                letterSpacing: 0.1,
              ),
              dataRowMinHeight: 46,
              dataRowMaxHeight: 56,
              columns: [
                for (final column in columns)
                  DataColumn(
                    label: Text(column),
                    numeric: _numericTableHeaders.contains(column),
                  )
              ],
              rows: [
                for (var i = 0; i < rows.length; i++)
                  DataRow(
                    color: WidgetStatePropertyAll(i.isEven
                        ? Colors.transparent
                        : cs.surfaceContainerHighest.withValues(alpha: 0.18)),
                    cells: [for (final cell in rows[i]) DataCell(cell)],
                  )
              ],
            ),
          ),
        );
      });

  List<Widget> _amounts(Map<String, dynamic> row) => [
        Text(formatTaxEur(_base(row))),
        Text(formatTaxEur(_vat(row))),
        Text(formatTaxEur(_total(row)),
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ];

  Widget _vatRates(dynamic raw) {
    final rates = _rateRows(raw);
    if (rates.isEmpty) {
      return Builder(
          builder: (context) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Sin desglose de tipos de IVA disponible.',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant))));
    }
    return _table([
      'Tipo IVA',
      'Base imponible',
      'IVA',
      'Total'
    ], [
      for (final rate in rates)
        [
          Text('${_text(_read(rate, ['rate', 'vatRate', 'taxRate']))} %'),
          ..._amounts(rate),
        ],
    ]);
  }

  Widget _vatEntries(List<Map<String, dynamic>> entries, bool supported) {
    final columns = supported
        ? ['Proveedor', 'Documentos', 'Base imponible', 'IVA', 'Total']
        : [
            'Factura',
            'Fecha de emisión',
            'Cliente',
            'Base imponible',
            'IVA',
            'Total'
          ];
    final widths =
        supported ? [280, 120, 160, 140, 150] : [132, 160, 260, 160, 140, 150];
    // The last three columns (base/IVA/total) are always the money columns.
    final rightAlignFrom = columns.length - 3;

    String columnText(Map<String, dynamic> row, int column) {
      if (supported) {
        return switch (column) {
          0 => _party(row, 'provider'),
          1 => _text(_count(row)),
          2 => formatTaxEur(_base(row)),
          3 => formatTaxEur(_vat(row)),
          _ => formatTaxEur(_vatReportTotal(row)),
        };
      }
      return switch (column) {
        0 => _text(_read(row, ['invoiceNumber', 'number'])),
        1 => _date(_read(row, ['issueDate', 'issuedAt', 'date'])),
        2 => _party(row, 'client'),
        3 => formatTaxEur(_base(row)),
        4 => formatTaxEur(_vat(row)),
        _ => formatTaxEur(_vatReportTotal(row)),
      };
    }

    dynamic sortValue(Map<String, dynamic> row, int column) {
      if (column >= rightAlignFrom) {
        return parseFlexibleMoney(switch (column - rightAlignFrom) {
          0 => _base(row),
          1 => _vat(row),
          _ => _vatReportTotal(row),
        });
      }
      if (supported && column == 1) return parseFlexibleMoney(_count(row));
      if (!supported && column == 1) {
        return DateTime.tryParse(
            _read(row, ['issueDate', 'issuedAt', 'date'])?.toString() ?? '');
      }
      return columnText(row, column).toLowerCase();
    }

    int compare(dynamic left, dynamic right) {
      if (left == null && right == null) return 0;
      if (left == null) return 1;
      if (right == null) return -1;
      if (left is num && right is num) return left.compareTo(right);
      if (left is DateTime && right is DateTime) return left.compareTo(right);
      // Compare digit runs numerically so INV-2 sorts before INV-10.
      final parts = RegExp(r'\d+|\D+');
      final a = parts.allMatches(left.toString()).map((m) => m[0]!).toList();
      final b = parts.allMatches(right.toString()).map((m) => m[0]!).toList();
      for (var i = 0; i < a.length && i < b.length; i++) {
        final an = int.tryParse(a[i]);
        final bn = int.tryParse(b[i]);
        final result =
            an != null && bn != null ? an.compareTo(bn) : a[i].compareTo(b[i]);
        if (result != 0) return result;
      }
      return a.length.compareTo(b.length);
    }

    Widget cells(List<Widget> values, {TextStyle? style}) => Row(children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              flex: widths[i],
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                child: Align(
                  alignment: i >= rightAlignFrom
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: DefaultTextStyle.merge(style: style, child: values[i]),
                ),
              ),
            ),
        ]);
    return Builder(builder: (context) {
      final visibleEntries = [
        for (var i = 0; i < entries.length; i++) (index: i, row: entries[i])
      ]
          .where((entry) => selectedValues.entries.every((filter) =>
              filter.value.contains(columnText(entry.row, filter.key))))
          .toList()
        ..sort((left, right) {
          if (sortColumn == null) return left.index.compareTo(right.index);
          final result = compare(sortValue(left.row, sortColumn!),
              sortValue(right.row, sortColumn!));
          if (result == 0) return left.index.compareTo(right.index);
          return sortAscending ? result : -result;
        });

      double? visibleTotal(dynamic Function(Map<String, dynamic>) value) {
        var cents = 0;
        for (final entry in visibleEntries) {
          final amount = parseFlexibleMoney(value(entry.row));
          // Do not present a partial sum as a complete total when a row is
          // missing an amount. Sum rounded cents to match displayed EUR values.
          if (amount == null || !amount.isFinite) return null;
          cents += (amount * 100).round();
        }
        return cents / 100;
      }

      Widget totalCell(String column, double? total) => Tooltip(
            message: total == null
                ? 'Total no disponible: faltan importes en las facturas visibles.'
                : 'Suma de las facturas visibles',
            child:
                Text(formatTaxEur(total), key: ValueKey('tax-footer-$column')),
          );

      Future<void> openColumnFilter(
          int column, BuildContext headerContext) async {
        final availableRows = entries
            .where((row) => selectedValues.entries
                .where((filter) => filter.key != column)
                .every((filter) =>
                    filter.value.contains(columnText(row, filter.key))))
            .toList()
          ..sort((a, b) => compare(sortValue(a, column), sortValue(b, column)));
        final values = availableRows
            .map((row) => columnText(row, column))
            .toSet()
            .toList();
        final header = headerContext.findRenderObject()! as RenderBox;
        final overlay = Navigator.of(context, rootNavigator: true)
            .overlay!
            .context
            .findRenderObject()! as RenderBox;
        final anchor =
            header.localToGlobal(Offset.zero, ancestor: overlay) & header.size;
        final result = await showGeneralDialog<_ColumnFilterResult>(
          context: context,
          barrierDismissible: true,
          barrierLabel:
              MaterialLocalizations.of(context).modalBarrierDismissLabel,
          barrierColor: Colors.transparent,
          transitionDuration: const Duration(milliseconds: 140),
          pageBuilder: (context, animation, secondaryAnimation) =>
              _ColumnFilterPopover(
            anchor: anchor,
            child: _ColumnFilterDialog(
              column: columns[column],
              values: values,
              selectedValues: selectedValues[column] ?? values.toSet(),
              sortAscending: sortColumn == column ? sortAscending : null,
            ),
          ),
          transitionBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
        );
        if (result == null || !context.mounted) return;
        setState(() {
          if (result.selectedValues.length == values.length) {
            selectedValues.remove(column);
          } else {
            selectedValues[column] = result.selectedValues;
          }
          if (result.sortAscending != null) {
            sortColumn = column;
            sortAscending = result.sortAscending!;
          } else if (sortColumn == column) {
            sortColumn = null;
          }
        });
      }

      Widget headerCells(ColorScheme cs) => Row(children: [
            for (var i = 0; i < columns.length; i++)
              Expanded(
                flex: widths[i],
                child: Builder(
                    builder: (headerContext) => Tooltip(
                          message: 'Filtrar por ${columns[i]}',
                          child: InkWell(
                            key: ValueKey('tax-column-filter-${columns[i]}'),
                            onTap: () => openColumnFilter(i, headerContext),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 16),
                              child: Row(
                                mainAxisAlignment: i >= rightAlignFrom
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start,
                                children: [
                                  Flexible(child: Text(columns[i])),
                                  const SizedBox(width: 6),
                                  Icon(
                                    selectedValues.containsKey(i)
                                        ? Icons.filter_alt_rounded
                                        : Icons.filter_alt_outlined,
                                    size: 15,
                                    color: selectedValues.containsKey(i)
                                        ? cs.primary
                                        : cs.onSurfaceVariant
                                            .withValues(alpha: .62),
                                  ),
                                  if (sortColumn == i) ...[
                                    const SizedBox(width: 2),
                                    Icon(
                                      sortAscending
                                          ? Icons.arrow_upward_rounded
                                          : Icons.arrow_downward_rounded,
                                      size: 14,
                                      color: cs.primary,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        )),
              ),
          ]);

      final cs = Theme.of(context).colorScheme;
      final stripe = cs.surfaceContainerHighest.withValues(alpha: 0.18);
      final expandedTint = cs.primary.withValues(alpha: 0.05);
      return LayoutBuilder(builder: (context, constraints) {
        final minWidth =
            widths.fold<int>(52, (sum, width) => sum + width).toDouble();
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(14),
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            key: PageStorageKey('vat-entries-${section.name}'),
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: constraints.maxWidth < minWidth
                  ? minWidth
                  : constraints.maxWidth,
              child: Column(children: [
                DefaultTextStyle.merge(
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    color: cs.onSurfaceVariant,
                    letterSpacing: 0.1,
                  ),
                  child: Container(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                    child: Row(children: [
                      Expanded(child: headerCells(cs)),
                      SizedBox(
                        width: 52,
                        child: selectedValues.isEmpty &&
                                sortColumn == _defaultSortColumn &&
                                (sortColumn == null || !sortAscending)
                            ? null
                            : IconButton(
                                tooltip: 'Restablecer tabla',
                                icon: const Icon(Icons.filter_alt_off_outlined,
                                    size: 18),
                                onPressed: () => setState(() {
                                  selectedValues.clear();
                                  sortColumn = _defaultSortColumn;
                                  sortAscending = false;
                                }),
                              ),
                      ),
                    ]),
                  ),
                ),
                if (visibleEntries.isEmpty)
                  SizedBox(
                    height: 96,
                    child: Center(
                      child: Text('No hay resultados para estos filtros.',
                          style: TextStyle(color: cs.onSurfaceVariant)),
                    ),
                  )
                else
                  for (var i = 0; i < visibleEntries.length; i++)
                    ExpansionTile(
                      key: PageStorageKey(
                          'vat-entry-${section.name}-${visibleEntries[i].index}'),
                      tilePadding: const EdgeInsets.only(right: 12),
                      childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      backgroundColor: expandedTint,
                      collapsedBackgroundColor:
                          i.isEven ? Colors.transparent : stripe,
                      title: cells([
                        if (supported) ...[
                          Text(_party(visibleEntries[i].row, 'provider')),
                          Text(_text(_count(visibleEntries[i].row))),
                        ] else ...[
                          Text(_text(_read(visibleEntries[i].row,
                              ['invoiceNumber', 'number']))),
                          Text(_date(_read(visibleEntries[i].row,
                              ['issueDate', 'issuedAt', 'date']))),
                          Text(_party(visibleEntries[i].row, 'client')),
                        ],
                        Text(formatTaxEur(_base(visibleEntries[i].row))),
                        Text(formatTaxEur(_vat(visibleEntries[i].row))),
                        Tooltip(
                          message: _vatReportTotal(visibleEntries[i].row) ==
                                  null
                              ? 'El servidor no ha proporcionado el total agregado.'
                              : 'Total con IVA',
                          child: Text(
                              formatTaxEur(
                                  _vatReportTotal(visibleEntries[i].row)),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ]),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  'Desglose IVA · ${supported ? _party(visibleEntries[i].row, 'provider') : _text(_read(visibleEntries[i].row, [
                                          'invoiceNumber',
                                          'number'
                                        ]))}',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: cs.onSurfaceVariant,
                                      fontSize: 12.5),
                                ),
                              ),
                              _vatRates(visibleEntries[i].row['byVatRate']),
                            ],
                          ),
                        ),
                      ],
                    ),
                if (!supported)
                  Container(
                    key: const ValueKey('tax-invoice-totals'),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: .4),
                      border: Border(top: BorderSide(color: cs.outlineVariant)),
                    ),
                    child: Row(children: [
                      Expanded(
                          child: cells([
                        Text(selectedValues.isEmpty
                            ? 'Total'
                            : 'Total filtrado'),
                        Text('${visibleEntries.length} facturas'),
                        const SizedBox.shrink(),
                        totalCell('base', visibleTotal(_base)),
                        totalCell('vat', visibleTotal(_vat)),
                        totalCell('total', visibleTotal(_vatReportTotal)),
                      ],
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                              ))),
                      const SizedBox(width: 52),
                    ]),
                  ),
              ]),
            ),
          ),
        );
      });
    });
  }

  Widget _vatReport() {
    final supported = section == TaxReportSection.supported;
    final totals = _map(data['totals']);
    final branch = _map(data[supported ? 'purchases' : 'sales']);
    final entries = _rows(supported
        ? branch['byProvider'] ?? data['gastos_by_provider']
        : branch['byInvoice'] ?? data['ingresos_by_invoice']);
    final metadata = _map(data['metadata']);
    final count = supported
        ? _read(totals, ['totalExpenses', 'gastosCount', 'expenseCount']) ??
            _read(branch, [
              'totalExpenses',
              'documentCount',
              'documentsCount',
              'expenseCount',
              'count'
            ]) ??
            data['totalExpenses'] ??
            metadata['totalExpenses']
        : _read(totals, ['totalInvoices', 'ingresosCount', 'invoiceCount']) ??
            _read(branch,
                ['totalInvoices', 'invoiceCount', 'documentsCount', 'count']) ??
            data['totalInvoices'] ??
            metadata['totalInvoices'] ??
            entries.length;
    if (entries.isEmpty && (parseFlexibleMoney(count) ?? 0) == 0) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _cards(const []),
        const SizedBox(height: 10),
        _empty(),
      ]);
    }
    final byClient = _rows(branch['byClient'] ?? data['ingresos_by_client']);
    final showClientTab = !supported && byClient.isNotEmpty;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _cards([
        (
          supported ? 'Base deducible' : 'Base de ventas',
          totals[supported ? 'gastosBase' : 'ingresosBase'],
          true
        ),
        (section.label, totals[supported ? 'gastosVat' : 'ingresosVat'], true),
        (supported ? 'Documentos de gasto' : 'Facturas emitidas', count, false),
      ]),
      const SizedBox(height: 16),
      if (showClientTab)
        DefaultTabController(
          length: 2,
          child: Builder(builder: (context) {
            final tabs = DefaultTabController.of(context);
            return ListenableBuilder(
              listenable: tabs,
              builder: (context, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const TabBar(tabs: [
                      Tab(text: 'Facturas'),
                      Tab(text: 'Agrupado por cliente'),
                    ]),
                    const SizedBox(height: 12),
                    if (tabs.index == 0)
                      _vatEntries(entries, supported)
                    else
                      _ClientGroupTable(rows: byClient, invoices: entries),
                  ]),
            );
          }),
        )
      else
        _vatEntries(entries, supported),
    ]);
  }

  Widget _irpf() {
    final totals = _map(data['totals']);
    final providers = _rows(data['byProvider']);
    final records = _rows(data['records']);
    if (providers.isEmpty &&
        records.isEmpty &&
        (parseFlexibleMoney(totals['records']) ?? 0) == 0) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _cards(const []),
        const SizedBox(height: 10),
        _empty(),
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _cards([
        ('Registros con IRPF', totals['records'], false),
        ('Importe bruto', totals['grossTotal'], true),
        ('IRPF retenido', totals['withheldTotal'], true),
        ('Importe pagadero', totals['payableTotal'], true),
      ]),
      const SizedBox(height: 16),
      _table([
        'Proveedor',
        'NIF/CIF',
        'Registros',
        'Importe bruto',
        'IRPF retenido',
        'Importe pagadero'
      ], [
        for (final provider in providers)
          [
            Text(_party(provider, 'provider')),
            Text(_text(_read(provider, ['taxId', 'nif', 'vatId']) ??
                _map(provider['provider'])['taxId'])),
            Text(_text(_read(provider, ['recordCount', 'count', 'records']))),
            Text(formatTaxEur(provider['grossTotal'])),
            Text(formatTaxEur(provider['withheldTotal'])),
            Text(formatTaxEur(provider['payableTotal'])),
          ],
      ]),
      for (var i = 0; i < providers.length; i++)
        ExpansionTile(
          key: PageStorageKey('irpf-provider-$i'),
          title: Text('Registros · ${_party(providers[i], 'provider')}'),
          children: [_irpfRecords(_providerRecords(providers[i], records))],
        ),
      // Keep records accessible even when a response has no provider grouping.
      if (providers.isEmpty) _irpfRecords(records),
    ]);
  }

  List<Map<String, dynamic>> _providerRecords(
      Map<String, dynamic> provider, List<Map<String, dynamic>> records) {
    if (provider['records'] is List) return _rows(provider['records']);
    final id = provider['providerId'] ??
        _map(provider['provider'])['_id'] ??
        provider['_id'];
    if (id == null) return [];
    return records
        .where((record) =>
            (record['providerId'] ?? _map(record['provider'])['_id']) == id)
        .toList();
  }

  Widget _irpfRecords(List<Map<String, dynamic>> records) => records.isEmpty
      ? const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Sin detalle de registros disponible.'))
      : _table([
          'Factura',
          'Fecha de emisión',
          'Porcentaje',
          'IRPF retenido',
          'Importe bruto',
          'Importe pagadero'
        ], [
          for (final record in records)
            [
              Text(_text(_read(
                  record, ['invoiceNumber', 'documentNumber', 'number']))),
              Text(_date(_read(record, ['issueDate', 'date']))),
              Text('${_text(_read(record, [
                    'percentage',
                    'irpfRate',
                    'withholdingRate',
                    'rate'
                  ]))} %'),
              Text(formatTaxEur(
                  _read(record, ['withheldAmount', 'withheldTotal']))),
              Text(formatTaxEur(record['grossTotal'])),
              Text(formatTaxEur(record['payableTotal'])),
            ],
        ]);

  Widget _intracommunity(BuildContext context) {
    final totals = _map(data['totals']);
    final sales = _rows(data['sales']);
    final purchases = _rows(data['purchases']);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _cards([
        ('Ventas intracomunitarias', totals['salesCount'], false),
        ('Compras intracomunitarias', totals['purchaseCount'], false),
        ('Base de ventas', totals['salesBase'], true),
        ('Base de compras', totals['purchaseBase'], true),
        ('Requieren revisión', totals['reviewRequired'], false),
      ]),
      const Align(
          alignment: Alignment.centerLeft,
          child: Tooltip(
            message:
                'Las operaciones se identifican mediante el país fiscal del cliente o proveedor. Los registros cuyo VAT ID no coincide con el país requieren revisión.',
            child: Padding(
                padding: EdgeInsets.all(12), child: Icon(Icons.info_outline)),
          )),
      DefaultTabController(
          length: 2,
          child: Builder(builder: (context) {
            final tabs = DefaultTabController.of(context);
            return ListenableBuilder(
                listenable: tabs,
                builder: (context, _) {
                  final records = tabs.index == 0 ? sales : purchases;
                  return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const TabBar(tabs: [
                          Tab(text: 'Ventas UE'),
                          Tab(text: 'Compras UE')
                        ]),
                        if (records.isEmpty)
                          _empty()
                        else
                          _table([
                            'Fecha',
                            'Documento',
                            'Contraparte',
                            'VAT ID',
                            'País',
                            'Base imponible',
                            'IVA',
                            'Total',
                            'Estado'
                          ], [
                            for (final record in records)
                              [
                                Text(_date(
                                    _read(record, ['issueDate', 'date']))),
                                Text(_text(_read(record, [
                                  'documentNumber',
                                  'invoiceNumber',
                                  'number'
                                ]))),
                                Text(_text(record['counterpartyName'] ??
                                    _map(record['counterparty'])['name'] ??
                                    record['counterparty'] ??
                                    _party(
                                        record,
                                        tabs.index == 0
                                            ? 'client'
                                            : 'provider'))),
                                Text(_text(record['vatId'] ??
                                    _map(record['counterparty'])['vatId'])),
                                Text(_text(record['country'] ??
                                    _map(record['counterparty'])['country'])),
                                ..._amounts(record),
                                if (record['reviewRequired'] == true)
                                  const Chip(
                                      label: Text('Revisar VAT ID',
                                          style:
                                              TextStyle(color: Colors.black87)),
                                      backgroundColor: Color(0xFFFFE0B2),
                                      avatar: Icon(Icons.warning_amber_rounded,
                                          color: Colors.black87))
                                else
                                  const Text('Sin alerta de país/VAT ID'),
                              ],
                          ]),
                      ]);
                });
          })),
    ]);
  }

  Widget _quarterly() {
    final totals = {..._map(data['totals']), ...data};
    final net = parseFlexibleMoney(totals['netVat']);
    final result = net == null
        ? 'Resultado no disponible'
        : net > 0
            ? 'IVA estimado a pagar'
            : net < 0
                ? 'IVA estimado a compensar'
                : 'Resultado equilibrado';
    final comparison = _map(data['comparison']);
    final previous = comparison['previousQuarter'];
    final previousMap = _map(previous);
    final previousLabel = previous is Map
        ? '${_text(previousMap['year'])} · ${_text(previousMap['quarter'])}'
        : _text(previous);
    final variations = {
      for (final key in const [
        'salesVat',
        'purchaseVat',
        'netVat',
        'salesBase',
        'purchaseBase',
        'totalInvoices',
        'totalExpenses'
      ])
        if (comparison['${key}ChangePercent'] != null)
          key: comparison['${key}ChangePercent'],
      ..._map(comparison['variations'] ?? comparison['percentageChanges']),
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _cards([
        ('IVA repercutido', totals['salesVat'], true),
        ('IVA soportado', totals['purchaseVat'], true),
        (result, totals['netVat'], true),
        ('Base de ventas', totals['salesBase'], true),
        ('Base de compras', totals['purchaseBase'], true),
        ('Facturas emitidas', totals['totalInvoices'], false),
        ('Gastos', totals['totalExpenses'], false),
      ]),
      if (totals['totalInvoices'] == 0 && totals['totalExpenses'] == 0)
        _empty(),
      const SizedBox(height: 16),
      RoundedSectionCard(
        margin: EdgeInsets.zero,
        title: 'Comparación trimestral',
        child: data['comparisonAvailable'] != true
            ? const Text('No hay datos comparables del trimestre anterior.')
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Trimestre anterior: $previousLabel'),
                for (final metric in const {
                  'salesVat': 'IVA repercutido',
                  'purchaseVat': 'IVA soportado',
                  'netVat': 'Resultado',
                  'salesBase': 'Base de ventas',
                  'purchaseBase': 'Base de compras',
                  'totalInvoices': 'Facturas emitidas',
                  'totalExpenses': 'Gastos',
                }.entries) ...[
                  if (previousMap[metric.key] != null)
                    Text(
                        '${metric.value}: ${metric.key.startsWith('total') ? _text(previousMap[metric.key]) : formatTaxEur(previousMap[metric.key])}'),
                  if (variations[metric.key] != null)
                    Text('${metric.value}: ${_text(variations[metric.key])} %'),
                ],
              ]),
      ),
      if (data['insights'] is List)
        for (final insight in data['insights'])
          ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(insight is Map
                  ? _text(
                      insight['message'] ?? insight['text'] ?? insight['title'])
                  : _text(insight))),
    ]);
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: switch (section) {
          TaxReportSection.supported ||
          TaxReportSection.charged =>
            _vatReport(),
          TaxReportSection.irpf => _irpf(),
          TaxReportSection.intracommunity => _intracommunity(context),
          TaxReportSection.quarterly => _quarterly(),
        },
      );
}
