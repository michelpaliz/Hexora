import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:intl/intl.dart';

class InvoiceDetailHistoryCard extends StatefulWidget {
  const InvoiceDetailHistoryCard({
    super.key,
    required this.title,
    required this.history,
    required this.localeName,
    required this.currency,
    this.loading = false,
    this.error,
    this.onRetry,
  });

  final String title;
  final List<Map<String, dynamic>> history;
  final String localeName;
  final String currency;
  final bool loading;
  final String? error;
  final VoidCallback? onRetry;

  @override
  State<InvoiceDetailHistoryCard> createState() =>
      _InvoiceDetailHistoryCardState();
}

class _InvoiceDetailHistoryCardState extends State<InvoiceDetailHistoryCard> {
  final Set<String> _expandedEvents = <String>{};

  bool get _isEs => widget.localeName.toLowerCase().startsWith('es');

  DateTime? _date(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is Map && value[r'$date'] != null) return _date(value[r'$date']);
    return null;
  }

  DateTime _sortDate(Map<String, dynamic> item) =>
      _date(item['changedAt'] ?? item['createdAt']) ??
      DateTime.fromMillisecondsSinceEpoch(0);

  List<Map<String, dynamic>> get _orderedHistory {
    final entries = widget.history
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
    return entries..sort((a, b) => _sortDate(b).compareTo(_sortDate(a)));
  }

  String _when(Map<String, dynamic> item) {
    final value = _date(item['changedAt'] ?? item['createdAt']);
    return value == null
        ? (_isEs ? 'Fecha no disponible' : 'Date unavailable')
        : DateFormat.yMMMd(widget.localeName).add_Hm().format(value.toLocal());
  }

  String _user(Map<String, dynamic> item) {
    final raw = item['user'];
    final user = raw is Map ? raw : const <String, dynamic>{};
    for (final value in [
      user['name'],
      user['userName'],
      item['userName'],
      item['changedByName'],
    ]) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return _isEs ? 'Usuario desconocido' : 'Unknown user';
  }

  String? _version(Map<String, dynamic> item) {
    final from = item['fromVersion'] ?? item['previousVersion'];
    final to = item['toVersion'] ?? item['version'];
    if (from == null && to == null) return null;
    return '${from ?? '?'} → ${to ?? '?'}';
  }

  String _eventKey(Map<String, dynamic> item, int index) {
    final id = item['_id'] ?? item['id'];
    if (id != null && id.toString().trim().isNotEmpty) return id.toString();
    return '${item['changedAt'] ?? item['createdAt'] ?? 'unknown'}-$index';
  }

  String _fieldLabel(String field) {
    const es = {
      'issueDate': 'Fecha de emisión',
      'dueDate': 'Fecha de vencimiento',
      'discountAmount': 'Descuento fijo',
      'discountPercent': 'Descuento porcentual',
      'currency': 'Moneda',
      'notes': 'Notas',
      'clientId': 'Cliente',
      'blocks': 'Conceptos',
      'lines': 'Líneas',
      'totals': 'Totales',
      'subtotal': 'Base imponible',
      'taxTotal': 'IVA',
      'total': 'Total',
      'quantity': 'Cantidad',
      'qty': 'Cantidad',
      'unitPrice': 'Precio unitario',
      'price': 'Precio unitario',
      'taxRate': 'IVA',
      'tax': 'IVA',
      'iva': 'IVA',
      'description': 'Descripción',
      'status': 'Estado',
      'paymentStatus': 'Estado de pago',
      'deliveryStatus': 'Estado de envío',
      'clientSnapshot': 'Datos fiscales del cliente',
      'issuerSnapshot': 'Datos del emisor',
    };
    const en = {
      'issueDate': 'Issue date',
      'dueDate': 'Due date',
      'discountAmount': 'Fixed discount',
      'discountPercent': 'Discount percentage',
      'currency': 'Currency',
      'notes': 'Notes',
      'clientId': 'Client',
      'blocks': 'Concepts',
      'lines': 'Lines',
      'totals': 'Totals',
      'subtotal': 'Taxable base',
      'taxTotal': 'VAT',
      'total': 'Total',
      'quantity': 'Quantity',
      'qty': 'Quantity',
      'unitPrice': 'Unit price',
      'price': 'Unit price',
      'taxRate': 'VAT',
      'tax': 'VAT',
      'iva': 'VAT',
      'description': 'Description',
      'status': 'Status',
      'paymentStatus': 'Payment status',
      'deliveryStatus': 'Delivery status',
      'clientSnapshot': 'Client billing details',
      'issuerSnapshot': 'Issuer details',
    };
    final parts = field.replaceAll(RegExp(r'\[\d+\]'), '').split('.');
    final key = parts.lastWhere((part) => part.isNotEmpty, orElse: () => field);
    return (_isEs ? es : en)[key] ?? (_isEs ? es : en)[parts.first] ?? key;
  }

  String _empty(dynamic value) {
    if (value == null) return _isEs ? 'No establecido' : 'Not set';
    final text = value.toString().trim();
    return text.isEmpty ? (_isEs ? 'No establecido' : 'Not set') : text;
  }

  num? _number(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString().replaceAll(',', '.') ?? '');
  }

  String _money(dynamic value) {
    final number = _number(value);
    if (number == null) return _empty(value);
    return NumberFormat.currency(
      locale: widget.localeName,
      name: widget.currency,
      symbol: widget.currency,
    ).format(number);
  }

  String _differenceMoney(num value) {
    final formatted = _money(value.abs());
    if (value > 0) return '+$formatted';
    if (value < 0) return '−$formatted';
    return formatted;
  }

  dynamic _decoded(dynamic value) {
    if (value is! String) return value;
    final text = value.trim();
    if (!(text.startsWith('{') || text.startsWith('['))) return value;
    try {
      return jsonDecode(text);
    } catch (_) {
      return value;
    }
  }

  bool _valuesEqual(dynamic left, dynamic right) {
    left = _decoded(left);
    right = _decoded(right);
    if (left is num && right is num) return left == right;
    if (left is Map && right is Map) {
      if (left.length != right.length) return false;
      return left.keys.every(
        (key) => right.containsKey(key) && _valuesEqual(left[key], right[key]),
      );
    }
    if (left is List && right is List) {
      if (left.length != right.length) return false;
      for (var index = 0; index < left.length; index++) {
        if (!_valuesEqual(left[index], right[index])) return false;
      }
      return true;
    }
    return left?.toString().trim() == right?.toString().trim();
  }

  bool _hasStructuralChange(Map<String, dynamic> change) {
    for (final key in ['added', 'removed', 'modified']) {
      final value = change[key];
      if (value is List && value.isNotEmpty) return true;
      if (value is num && value > 0) return true;
    }
    return false;
  }

  List<Map<String, dynamic>> _changes(Map<String, dynamic> item) {
    final raw = item['changes'];
    final changes = raw is List
        ? raw
            .whereType<Map>()
            .map((change) => Map<String, dynamic>.from(change))
            .toList()
        : item['field'] != null
            ? <Map<String, dynamic>>[item]
            : <Map<String, dynamic>>[];
    return changes
        .where((change) =>
            _hasStructuralChange(change) ||
            !_valuesEqual(change['oldValue'], change['newValue']))
        .toList(growable: false);
  }

  String _value(String field, dynamic rawValue) {
    final value = _decoded(rawValue);
    final root = field.split('.').first;
    final leaf = field.split('.').last;
    if (root == 'issueDate' || root == 'dueDate') {
      final date = _date(value);
      return date == null
          ? _empty(value)
          : DateFormat.yMMMd(widget.localeName).format(date.toLocal());
    }
    if ({
          'discountAmount',
          'subtotal',
          'taxTotal',
          'total',
          'paidAmount',
          'unitPrice',
          'price',
        }.contains(root) ||
        {'unitPrice', 'price'}.contains(leaf)) {
      return _money(value);
    }
    if ({'taxRate', 'tax', 'iva', 'discountPercent', 'discountRate'}
        .contains(leaf)) {
      final number = _number(value);
      return number == null ? _empty(value) : '${number.toString()}%';
    }
    if (value is Map || value is List) {
      try {
        return jsonEncode(value);
      } catch (_) {
        return value.toString();
      }
    }
    return _empty(value);
  }

  int _structuralCount(dynamic value) {
    if (value is List) return value.length;
    if (value is num) return value.toInt();
    return 0;
  }

  String _lineName(Map<String, dynamic> row, int index) {
    for (final key in ['description', 'title', 'text', 'concept']) {
      final text = row[key]?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return '${_isEs ? 'Línea' : 'Line'} ${index + 1}';
  }

  List<String> _lineValueChanges(dynamic oldRaw, dynamic newRaw) {
    final oldValue = _decoded(oldRaw);
    final newValue = _decoded(newRaw);
    if (oldValue is! List || newValue is! List) return const [];
    final result = <String>[];
    final length =
        oldValue.length > newValue.length ? oldValue.length : newValue.length;
    const meaningfulFields = [
      'description',
      'title',
      'text',
      'quantity',
      'qty',
      'unitPrice',
      'price',
      'taxRate',
      'tax',
      'iva',
      'discountRate',
      'discountPercent',
    ];
    for (var index = 0; index < length; index++) {
      if (index >= oldValue.length && newValue[index] is Map) {
        final row = Map<String, dynamic>.from(newValue[index] as Map);
        result.add('${_isEs ? 'Añadida' : 'Added'}: ${_lineName(row, index)}');
        continue;
      }
      if (index >= newValue.length && oldValue[index] is Map) {
        final row = Map<String, dynamic>.from(oldValue[index] as Map);
        result.add(
            '${_isEs ? 'Eliminada' : 'Removed'}: ${_lineName(row, index)}');
        continue;
      }
      if (oldValue[index] is! Map || newValue[index] is! Map) continue;
      final oldRow = Map<String, dynamic>.from(oldValue[index] as Map);
      final newRow = Map<String, dynamic>.from(newValue[index] as Map);
      final line = _lineName(newRow, index);
      for (final field in meaningfulFields) {
        if (!oldRow.containsKey(field) && !newRow.containsKey(field)) continue;
        if (_valuesEqual(oldRow[field], newRow[field])) continue;
        result.add(
          '$line · ${_fieldLabel(field)}: '
          '${_value(field, oldRow[field])} → ${_value(field, newRow[field])}',
        );
      }
    }
    return result;
  }

  List<String> _changeLines(Map<String, dynamic> change) {
    final field = (change['field'] ?? change['path'] ?? '').toString();
    final root = field.split('.').first;
    final oldValue = change['oldValue'];
    final newValue = change['newValue'];
    if (root == 'blocks' || root == 'lines') {
      final added = _structuralCount(change['added']);
      final removed = _structuralCount(change['removed']);
      final modified = _structuralCount(change['modified']);
      final parts = <String>[
        if (added > 0) '${_isEs ? 'añadidas' : 'added'}: $added',
        if (removed > 0) '${_isEs ? 'eliminadas' : 'removed'}: $removed',
        if (modified > 0) '${_isEs ? 'modificadas' : 'modified'}: $modified',
      ];
      final lineChanges = _lineValueChanges(oldValue, newValue);
      if (parts.isEmpty && lineChanges.isEmpty) {
        parts.add(_isEs ? 'contenido modificado' : 'content modified');
      }
      return [
        if (parts.isNotEmpty) '${_fieldLabel(field)}: ${parts.join(', ')}',
        ...lineChanges,
      ];
    }
    if (oldValue is Map && newValue is Map) {
      final oldMap = Map<String, dynamic>.from(oldValue);
      final newMap = Map<String, dynamic>.from(newValue);
      final keys = {...oldMap.keys, ...newMap.keys}
          .where((key) => !_valuesEqual(oldMap[key], newMap[key]));
      return keys
          .map((key) =>
              '${_fieldLabel(key.toString())}: ${_value(key.toString(), oldMap[key])} → ${_value(key.toString(), newMap[key])}')
          .toList(growable: false);
    }
    return [
      '${_fieldLabel(field)}: ${_value(field, oldValue)} → ${_value(field, newValue)}',
    ];
  }

  _FinancialChange? _financialChange(List<Map<String, dynamic>> changes) {
    for (final change in changes) {
      final field = (change['field'] ?? change['path'] ?? '').toString();
      final root = field.split('.').first;
      dynamic oldValue = change['oldValue'];
      dynamic newValue = change['newValue'];
      if (root == 'totals') {
        oldValue = _decoded(oldValue);
        newValue = _decoded(newValue);
        if (oldValue is Map && newValue is Map) {
          oldValue = oldValue['total'];
          newValue = newValue['total'];
        }
      } else if (root != 'total') {
        continue;
      }
      final oldNumber = _number(oldValue);
      final newNumber = _number(newValue);
      if (oldNumber != null && newNumber != null && oldNumber != newNumber) {
        return _FinancialChange(oldNumber, newNumber);
      }
    }
    return null;
  }

  String _eventType(Map<String, dynamic> item) {
    for (final key in ['eventType', 'action', 'type']) {
      final value = item[key]?.toString().trim().toLowerCase() ?? '';
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  String _eventTitle(
    Map<String, dynamic> item,
    List<Map<String, dynamic>> changes,
  ) {
    final type = _eventType(item);
    if (type.contains('creat')) {
      return _isEs ? 'Factura creada' : 'Invoice created';
    }
    if (type.contains('issu')) {
      return _isEs ? 'Factura emitida' : 'Invoice issued';
    }
    if (type.contains('send') || type.contains('sent')) {
      return _isEs ? 'Factura enviada' : 'Invoice sent';
    }
    if (type.contains('pay')) {
      return _isEs ? 'Pago registrado' : 'Payment recorded';
    }
    final roots = changes
        .map((change) => (change['field'] ?? change['path'] ?? '')
            .toString()
            .split('.')
            .first)
        .where((root) => root.isNotEmpty)
        .toSet();
    if (roots.isNotEmpty &&
        roots.every((root) =>
            {'status', 'paymentStatus', 'deliveryStatus'}.contains(root))) {
      return _isEs ? 'Estado actualizado' : 'Status updated';
    }
    if (roots.isNotEmpty &&
        roots.every((root) => {'blocks', 'lines'}.contains(root))) {
      return _isEs ? 'Líneas modificadas' : 'Lines changed';
    }
    if (roots.isNotEmpty &&
        roots.every((root) => {
              'totals',
              'subtotal',
              'taxTotal',
              'total',
              'discountAmount',
              'discountPercent',
            }.contains(root))) {
      return _isEs ? 'Importe corregido' : 'Amount corrected';
    }
    return _isEs ? 'Factura modificada' : 'Invoice changed';
  }

  IconData _eventIcon(String title) {
    final normalized = title.toLowerCase();
    if (normalized.contains('pago') || normalized.contains('payment')) {
      return Icons.payments_outlined;
    }
    if (normalized.contains('enviad') || normalized.contains('sent')) {
      return Icons.send_outlined;
    }
    if (normalized.contains('línea') || normalized.contains('line')) {
      return Icons.format_list_bulleted_rounded;
    }
    if (normalized.contains('importe') || normalized.contains('amount')) {
      return Icons.euro_rounded;
    }
    if (normalized.contains('estado') || normalized.contains('status')) {
      return Icons.sync_alt_rounded;
    }
    if (normalized.contains('creada') || normalized.contains('created')) {
      return Icons.add_rounded;
    }
    return Icons.edit_outlined;
  }

  String _changeSummary(List<Map<String, dynamic>> changes) {
    final labels = <String>[];
    for (final change in changes) {
      final field = (change['field'] ?? change['path'] ?? '').toString();
      if (field.isEmpty) continue;
      final label = _fieldLabel(field);
      if (!labels.contains(label)) labels.add(label);
    }
    if (labels.length <= 3) return labels.join(' · ');
    final remaining = labels.length - 3;
    return '${labels.take(3).join(' · ')} · +$remaining';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final history = _orderedHistory;
    final hasEntries = history.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 0, 2, 8),
          child: Row(
            children: [
              Icon(Icons.history_rounded, size: 17, color: cs.onSurfaceVariant),
              const SizedBox(width: 7),
              Text(
                widget.title,
                style: t.bodySmall.copyWith(fontWeight: FontWeight.w800),
              ),
              if (widget.loading) ...[
                const SizedBox(width: 8),
                const SizedBox(
                  width: 13,
                  height: 13,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ] else if (hasEntries) ...[
                const SizedBox(width: 6),
                Text(
                  '${history.length}',
                  style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ],
          ),
        ),
        if ((widget.error ?? '').isNotEmpty)
          Row(
            children: [
              Expanded(
                child: Text(
                  _isEs
                      ? 'No se pudo cargar el historial.'
                      : 'Could not load change history.',
                  style: t.bodySmall.copyWith(color: cs.error),
                ),
              ),
              TextButton(onPressed: widget.onRetry, child: Text(l.tryAgain)),
            ],
          )
        else if (!widget.loading && !hasEntries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              l.invoiceChangeHistoryEmpty,
              style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
            ),
          )
        else
          for (var index = 0; index < history.length; index++)
            _timelineEntry(
              context,
              history[index],
              index: index,
              isLast: index == history.length - 1,
            ),
      ],
    );
  }

  Widget _timelineEntry(
    BuildContext context,
    Map<String, dynamic> item, {
    required int index,
    required bool isLast,
  }) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final changes = _changes(item);
    final title = _eventTitle(item, changes);
    final reason = item['reason']?.toString().trim() ?? '';
    final version = _version(item);
    final source = item['source']?.toString().trim();
    final financial = _financialChange(changes);
    final key = _eventKey(item, index);
    final expanded = _expandedEvents.contains(key);
    final detailLines = changes.expand(_changeLines).toList(growable: false);
    final changeSummary = _changeSummary(changes);

    return IntrinsicHeight(
      key: ValueKey('invoice-history-event-$key'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 26,
            child: Column(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.72),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _eventIcon(title),
                    size: 13,
                    color: cs.onPrimaryContainer,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1,
                      color: cs.outlineVariant.withValues(alpha: 0.65),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 2 : 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: t.bodySmall.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _when(item),
                        style: t.bodySmall.copyWith(
                          color: cs.onSurfaceVariant,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    _user(item),
                    style: t.bodySmall.copyWith(
                      color: cs.onSurfaceVariant,
                      fontSize: 11.5,
                    ),
                  ),
                  if (changeSummary.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      changeSummary,
                      style: t.bodySmall.copyWith(
                        color: cs.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                  if (reason.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      reason,
                      style: t.bodySmall.copyWith(fontSize: 12),
                    ),
                  ],
                  if (financial != null) ...[
                    const SizedBox(height: 6),
                    _financialSummary(context, financial),
                  ],
                  if (version != null || source == 'legacy') ...[
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (version != null)
                          '${_isEs ? 'Versión' : 'Version'} $version',
                        if (source == 'legacy') 'Legacy',
                      ].join(' · '),
                      style: t.bodySmall.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                  if (detailLines.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    TextButton(
                      key: ValueKey('invoice-history-toggle-$key'),
                      onPressed: () => setState(() {
                        if (expanded) {
                          _expandedEvents.remove(key);
                        } else {
                          _expandedEvents.add(key);
                        }
                      }),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 30),
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            expanded
                                ? (_isEs ? 'Ocultar cambios' : 'Hide changes')
                                : (_isEs ? 'Ver cambios' : 'View changes'),
                          ),
                          const SizedBox(width: 3),
                          Icon(
                            expanded ? Icons.expand_less : Icons.expand_more,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (expanded) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(8, 6, 8, 3),
                      decoration: BoxDecoration(
                        color:
                            cs.surfaceContainerHighest.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final line in detailLines)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                line,
                                style: t.bodySmall.copyWith(fontSize: 11.5),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),
                  ],
                  if (!isLast)
                    Divider(
                      height: 8,
                      color: cs.outlineVariant.withValues(alpha: 0.35),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _financialSummary(
    BuildContext context,
    _FinancialChange change,
  ) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    TextStyle style({bool emphasized = false}) => t.bodySmall.copyWith(
          fontSize: 11.5,
          fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
        );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_isEs ? 'Total anterior' : 'Previous total'}: ${_money(change.oldValue)}',
                  style: style(),
                ),
              ),
              Icon(Icons.arrow_forward_rounded,
                  size: 14, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${_isEs ? 'Total nuevo' : 'New total'}: ${_money(change.newValue)}',
                  textAlign: TextAlign.end,
                  style: style(emphasized: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${_isEs ? 'Diferencia' : 'Difference'}: '
              '${_differenceMoney(change.newValue - change.oldValue)}',
              style: style(emphasized: true).copyWith(color: cs.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinancialChange {
  const _FinancialChange(this.oldValue, this.newValue);

  final num oldValue;
  final num newValue;
}
