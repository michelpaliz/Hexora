class InvoiceLine {
  final String? id;
  final String invoiceId;
  final int position;
  final String description;
  final num quantity;
  final num unitPrice;
  final num taxRate;
  final num? lineSubtotal;
  final num? lineTax;
  final num? lineTotal;

  const InvoiceLine({
    this.id,
    required this.invoiceId,
    required this.position,
    required this.description,
    this.quantity = 1,
    required this.unitPrice,
    this.taxRate = 21,
    this.lineSubtotal,
    this.lineTax,
    this.lineTotal,
  });

  InvoiceLine copyWith({
    String? id,
    String? invoiceId,
    int? position,
    String? description,
    num? quantity,
    num? unitPrice,
    num? taxRate,
    num? lineSubtotal,
    num? lineTax,
    num? lineTotal,
  }) {
    return InvoiceLine(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      position: position ?? this.position,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      taxRate: taxRate ?? this.taxRate,
      lineSubtotal: lineSubtotal ?? this.lineSubtotal,
      lineTax: lineTax ?? this.lineTax,
      lineTotal: lineTotal ?? this.lineTotal,
    );
  }

  factory InvoiceLine.fromJson(Map<String, dynamic> json) {
    return InvoiceLine(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      invoiceId: (json['invoiceId'] ?? '').toString(),
      position: (json['position'] is num ? json['position'] as num : 0).toInt(),
      description: (json['description'] ?? '').toString(),
      quantity: json['quantity'] is num ? json['quantity'] as num : 1,
      unitPrice: json['unitPrice'] is num ? json['unitPrice'] as num : 0,
      taxRate: json['taxRate'] is num ? json['taxRate'] as num : 21,
      lineSubtotal:
          json['lineSubtotal'] is num ? json['lineSubtotal'] as num : null,
      lineTax: json['lineTax'] is num ? json['lineTax'] as num : null,
      lineTotal: json['lineTotal'] is num ? json['lineTotal'] as num : null,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'invoiceId': invoiceId,
        'position': position,
        'description': description,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'taxRate': taxRate,
        if (lineSubtotal != null) 'lineSubtotal': lineSubtotal,
        if (lineTax != null) 'lineTax': lineTax,
        if (lineTotal != null) 'lineTotal': lineTotal,
      };
}
