part of 'presupuesto_invoice_conversion_view.dart';

extension _PresupuestoInvoiceConversionViewHelpers
    on _PresupuestoInvoiceConversionViewState {
  String _presupuestoId(Map<String, dynamic> item) =>
      (item['_id'] ?? item['id'] ?? '').toString();

  String _presupuestoNumber(Map<String, dynamic> item) {
    final number = (item['presupuestoNumber'] ?? item['budgetNumber'] ?? '')
        .toString()
        .trim();
    return number.isEmpty ? '-' : number;
  }

  String _presupuestoStatus(Map<String, dynamic> item) {
    final status = (item['status'] ?? '').toString().trim();
    return status.isEmpty ? 'draft' : status;
  }

  bool _isDraftPresupuesto(Map<String, dynamic> item) =>
      _presupuestoStatus(item).toLowerCase().contains('draft');

  String _presupuestoClientName(Map<String, dynamic> item) {
    final direct = (item['clientName'] ?? '').toString().trim();
    if (direct.isNotEmpty) return direct;
    final nestedClient = item['client'];
    if (nestedClient is Map) {
      final name = (nestedClient['name'] ?? '').toString().trim();
      if (name.isNotEmpty) return name;
    }
    final clientId = (item['clientId'] ?? '').toString().trim();
    if (clientId.isNotEmpty) {
      final client = widget.clients.cast<GroupClient?>().firstWhere(
            (entry) => entry?.id == clientId,
            orElse: () => null,
          );
      if (client != null && client.name.trim().isNotEmpty) {
        return client.name.trim();
      }
    }
    return _isSpanish ? 'Cliente desconocido' : 'Unknown client';
  }

  DateTime? _presupuestoDate(Map<String, dynamic> item) {
    final raw = item['issueDate'] ??
        item['registeredAt'] ??
        item['createdAt'] ??
        item['occurrenceDate'];
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    return DateTime.tryParse(raw.toString());
  }

  List<double> _presupuestoVatRates(Map<String, dynamic> item) {
    final values = <double>{};
    final lineGroups = <dynamic>[item['lines'], item['blocks']];
    for (final group in lineGroups) {
      if (group is! List) continue;
      for (final raw in group.whereType<Map>()) {
        final value =
            _toDouble(raw['taxRate'] ?? raw['tax'] ?? raw['vat'] ?? raw['iva']);
        if (value != null && value >= 0) {
          values.add(double.parse(value.toStringAsFixed(2)));
        }
      }
    }
    final sorted = values.toList()..sort();
    return sorted;
  }

  String _formatVatRateLabel(double value) {
    final roundedInt = value.roundToDouble();
    final number = (value - roundedInt).abs() < 0.0001
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
    return '$number%';
  }

  String _presupuestoVatSummaryLabel(Map<String, dynamic> item) {
    final rates = _presupuestoVatRates(item);
    if (rates.isEmpty) {
      return _isSpanish
          ? 'Calculado automáticamente'
          : 'Calculated automatically';
    }
    if (rates.length == 1) {
      return _formatVatRateLabel(rates.first);
    }
    final joined = rates.map(_formatVatRateLabel).join(', ');
    return _isSpanish ? 'IVA mixto · $joined' : 'Mixed VAT · $joined';
  }

  double? _presupuestoTotal(Map<String, dynamic> item) {
    final candidates = <dynamic>[
      item['total'],
      item['totalAmount'],
      item['grandTotal'],
      item['amount'],
    ];
    for (final value in candidates) {
      final parsed = _toDouble(value);
      if (parsed != null) return parsed;
    }
    return null;
  }

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse((value ?? '').toString().trim().replaceAll(',', '.'));
  }

  double? _parseDouble(String value) => _toDouble(value);

  String _formatStatusLabel(String status) {
    final normalized = status.trim().toLowerCase();
    if (normalized.isEmpty) return _isSpanish ? 'Borrador' : 'Draft';
    if (normalized.contains('issued')) return _isSpanish ? 'Emitido' : 'Issued';
    if (normalized.contains('accept')) {
      return _isSpanish ? 'Aceptado' : 'Accepted';
    }
    if (normalized.contains('approved')) {
      return _isSpanish ? 'Aprobado' : 'Approved';
    }
    if (normalized.contains('draft')) return _isSpanish ? 'Borrador' : 'Draft';
    return status;
  }

  Color _statusColor(ColorScheme cs, String status) {
    final normalized = status.trim().toLowerCase();
    if (normalized.contains('issued') ||
        normalized.contains('accept') ||
        normalized.contains('approved')) {
      return cs.tertiary;
    }
    if (normalized.contains('draft')) return cs.secondary;
    return cs.primary;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return _isSpanish ? 'Sin fecha' : 'No date';
    return DateFormat('d MMM yyyy', _localeTag).format(date.toLocal());
  }
}
