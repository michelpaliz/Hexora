class ReceiptLine {
  final String description;
  final num quantity;
  final num unitPrice;
  final num? total;

  const ReceiptLine({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    this.total,
  });

  factory ReceiptLine.fromJson(Map<String, dynamic> json) {
    final q = json['quantity'];
    final p = json['unitPrice'];
    return ReceiptLine(
      description: (json['description'] ?? '').toString(),
      quantity: q is num ? q : num.tryParse(q?.toString() ?? '') ?? 1,
      unitPrice: p is num ? p : num.tryParse(p?.toString() ?? '') ?? 0,
      total: json['total'] is num ? json['total'] as num : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'description': description,
        'quantity': quantity,
        'unitPrice': unitPrice,
        if (total != null) 'total': total,
      };
}

