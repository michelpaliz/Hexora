class ReceiptLine {
  final String description;
  final num quantity;
  final String unit;
  final String? unitLabel;
  final num unitPrice;
  final num? total;

  const ReceiptLine({
    required this.description,
    required this.quantity,
    this.unit = 'unit',
    this.unitLabel,
    required this.unitPrice,
    this.total,
  });

  factory ReceiptLine.fromJson(Map<String, dynamic> json) {
    final q = json['quantity'];
    final p = json['unitPrice'];
    return ReceiptLine(
      description: (json['description'] ?? '').toString(),
      quantity: q is num ? q : num.tryParse(q?.toString() ?? '') ?? 1,
      unit: _normalizeUnit(json['unit']),
      unitLabel: json['unitLabel']?.toString(),
      unitPrice: p is num ? p : num.tryParse(p?.toString() ?? '') ?? 0,
      total: json['lineTotal'] is num
          ? json['lineTotal'] as num
          : (json['total'] is num ? json['total'] as num : null),
    );
  }

  Map<String, dynamic> toJson() => {
        'description': description,
        'quantity': quantity,
        'unit': unit,
        if (unitLabel != null && unitLabel!.trim().isNotEmpty)
          'unitLabel': unitLabel!.trim(),
        'unitPrice': unitPrice,
        'lineTotal': total ?? (quantity * unitPrice),
        if (total != null) 'total': total,
      };

  String quantityWithUnit() {
    final quantityText = _formatQuantity(quantity);
    final label = _displayUnitLabel();
    return '$quantityText $label'.trim();
  }

  String _displayUnitLabel() {
    final custom = unitLabel?.trim();
    if (unit == 'other' && custom != null && custom.isNotEmpty) {
      return custom;
    }
    switch (unit) {
      case 'hour':
        return quantity == 1 ? 'hora' : 'horas';
      case 'day':
        return quantity == 1 ? 'día' : 'días';
      case 'service':
        return quantity == 1 ? 'servicio' : 'servicios';
      case 'item':
        return quantity == 1 ? 'artículo' : 'artículos';
      case 'unit':
      default:
        return 'uds.';
    }
  }

  static String _formatQuantity(num value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }

  static String _normalizeUnit(dynamic value) {
    final raw = (value ?? '').toString().trim().toLowerCase();
    const allowed = {'unit', 'hour', 'day', 'service', 'item', 'other'};
    return allowed.contains(raw) ? raw : 'unit';
  }
}
