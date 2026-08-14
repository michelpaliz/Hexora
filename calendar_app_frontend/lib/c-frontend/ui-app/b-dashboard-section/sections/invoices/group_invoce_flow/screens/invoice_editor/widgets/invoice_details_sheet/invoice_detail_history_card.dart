import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
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
  bool _expanded = false;

  bool get _isEs => widget.localeName.toLowerCase().startsWith('es');

  DateTime? _date(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is Map && value[r'$date'] != null) {
      return _date(value[r'$date']);
    }
    return null;
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
    final from = item['fromVersion'];
    final to = item['toVersion'];
    if (from == null && to == null) return null;
    return '${from ?? '?'} → ${to ?? '?'}';
  }

  String _fieldLabel(String field) {
    const es = {
      'issueDate': 'Fecha de emision',
      'discountAmount': 'Descuento fijo',
      'discountPercent': 'Descuento porcentual',
      'currency': 'Moneda',
      'notes': 'Notas',
      'clientId': 'Cliente',
      'blocks': 'Conceptos',
      'lines': 'Lineas',
      'totals': 'Totales',
      'clientSnapshot': 'Datos fiscales del cliente',
      'issuerSnapshot': 'Datos del emisor',
    };
    const en = {
      'issueDate': 'Issue date',
      'discountAmount': 'Fixed discount',
      'discountPercent': 'Discount percentage',
      'currency': 'Currency',
      'notes': 'Notes',
      'clientId': 'Client',
      'blocks': 'Concepts',
      'lines': 'Lines',
      'totals': 'Totals',
      'clientSnapshot': 'Client billing details',
      'issuerSnapshot': 'Issuer details',
    };
    final root = field.split('.').first;
    return (_isEs ? es : en)[root] ?? field;
  }

  String _empty(dynamic value) {
    if (value == null) return _isEs ? 'No establecido' : 'Not set';
    final text = value.toString().trim();
    return text.isEmpty ? (_isEs ? 'No establecido' : 'Not set') : text;
  }

  String _money(dynamic value) {
    final number = value is num
        ? value
        : num.tryParse(value?.toString().replaceAll(',', '.') ?? '');
    if (number == null) return _empty(value);
    return NumberFormat.currency(
      locale: widget.localeName,
      name: widget.currency,
      symbol: widget.currency,
    ).format(number);
  }

  int _conceptCount(dynamic value) {
    if (value is List) return value.length;
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) return decoded.length;
      } catch (_) {}
    }
    return 0;
  }

  String _value(String field, dynamic value) {
    final root = field.split('.').first;
    if (root == 'issueDate') {
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
    }.contains(root)) {
      return _money(value);
    }
    if (root == 'blocks' || root == 'lines') {
      final count = _conceptCount(value);
      return _isEs ? '$count conceptos' : '$count concepts';
    }
    if (root == 'totals' && value is Map) {
      final values = Map<String, dynamic>.from(value);
      return [
        '${_isEs ? 'Subtotal' : 'Subtotal'}: ${_money(values['subtotal'])}',
        '${_isEs ? 'IVA' : 'VAT'}: ${_money(values['taxTotal'] ?? values['vat'])}',
        'Total: ${_money(values['total'])}',
      ].join(' · ');
    }
    if (value is Map || value is List) return _empty(value);
    return _empty(value);
  }

  List<Map<String, dynamic>> _changes(Map<String, dynamic> item) {
    final raw = item['changes'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((change) => Map<String, dynamic>.from(change))
          .toList();
    }
    if (item['field'] != null) return [item];
    return const [];
  }

  List<String> _changeLines(Map<String, dynamic> change) {
    final field = (change['field'] ?? change['path'] ?? '').toString();
    final root = field.split('.').first;
    final oldValue = change['oldValue'];
    final newValue = change['newValue'];
    if ((root == 'blocks' || root == 'lines')) {
      int count(dynamic value) => value is List
          ? value.length
          : value is num
              ? value.toInt()
              : 0;
      final added = count(change['added']);
      final removed = count(change['removed']);
      final modified = count(change['modified']);
      final parts = <String>[
        if (added > 0) '${_isEs ? 'anadidos' : 'added'}: $added',
        if (removed > 0) '${_isEs ? 'eliminados' : 'removed'}: $removed',
        if (modified > 0) '${_isEs ? 'modificados' : 'modified'}: $modified',
      ];
      if (parts.isEmpty) {
        final oldCount = _conceptCount(oldValue);
        final newCount = _conceptCount(newValue);
        final delta = newCount - oldCount;
        if (delta > 0) parts.add('${_isEs ? 'anadidos' : 'added'}: $delta');
        if (delta < 0) {
          parts.add('${_isEs ? 'eliminados' : 'removed'}: ${-delta}');
        }
        if (delta == 0) {
          parts.add(_isEs ? 'conceptos modificados' : 'concepts modified');
        }
      }
      return ['${_fieldLabel(field)}: ${parts.join(', ')}'];
    }
    if ((root == 'clientSnapshot' || root == 'issuerSnapshot') &&
        oldValue is Map &&
        newValue is Map) {
      final oldMap = Map<String, dynamic>.from(oldValue);
      final newMap = Map<String, dynamic>.from(newValue);
      final keys = {...oldMap.keys, ...newMap.keys}.where(
        (key) => oldMap[key]?.toString() != newMap[key]?.toString(),
      );
      return keys
          .map((key) =>
              '${_fieldLabel('$root.$key')} ($key): ${_empty(oldMap[key])} → ${_empty(newMap[key])}')
          .toList();
    }
    return [
      '${_fieldLabel(field)}: ${_value(field, oldValue)} → ${_value(field, newValue)}',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final hasEntries = widget.history.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: hasEntries
                  ? () => setState(() => _expanded = !_expanded)
                  : null,
              child: Row(
                children: [
                  Icon(Icons.history_rounded,
                      size: 16, color: cs.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(widget.title,
                      style: t.bodySmall.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(width: 6),
                  if (widget.loading)
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (hasEntries)
                    Text('${widget.history.length}', style: t.bodySmall),
                  const Spacer(),
                  if (hasEntries)
                    Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                        size: 18),
                ],
              ),
            ),
            if ((widget.error ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
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
                  TextButton(
                      onPressed: widget.onRetry, child: Text(l.tryAgain)),
                ],
              ),
            ] else if (!widget.loading && !hasEntries) ...[
              const SizedBox(height: 6),
              Text(l.invoiceChangeHistoryEmpty,
                  style: t.bodySmall.copyWith(color: cs.onSurfaceVariant)),
            ],
            if (_expanded && hasEntries) ...[
              const SizedBox(height: 12),
              for (var index = 0; index < widget.history.length; index++)
                _timelineEntry(
                  context,
                  widget.history[index],
                  isLast: index == widget.history.length - 1,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _timelineEntry(
    BuildContext context,
    Map<String, dynamic> item, {
    required bool isLast,
  }) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final reason = _empty(item['reason']);
    final version = _version(item);
    final source = item['source']?.toString().trim();
    final changes = _changes(item);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 18,
            child: Column(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                      child: Container(width: 1, color: cs.outlineVariant)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(_user(item),
                            style: t.bodySmall
                                .copyWith(fontWeight: FontWeight.w800)),
                      ),
                      Text(_when(item),
                          style: t.bodySmall.copyWith(
                              color: cs.onSurfaceVariant, fontSize: 11)),
                    ],
                  ),
                  Text(reason,
                      style: t.bodySmall.copyWith(color: cs.onSurfaceVariant)),
                  if (version != null || source == 'legacy') ...[
                    const SizedBox(height: 3),
                    Text(
                      [
                        if (version != null) version,
                        if (source == 'legacy') 'Legacy',
                      ].join(' · '),
                      style: t.bodySmall.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                  if (changes.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    for (final change in changes)
                      for (final line in _changeLines(change))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text(
                            line,
                            style: t.bodySmall.copyWith(fontSize: 11.5),
                          ),
                        ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
