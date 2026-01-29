class InvoiceBlockType {
  static const String item = 'item';
  static const String date = 'date';
  static const String section = 'section';
  static const String subsection = 'subsection';
  static const String divider = 'divider';
  static const String note = 'note';
  static const String checklist = 'checklist';
}

class InvoiceChecklistItem {
  final String text;
  final bool checked;

  const InvoiceChecklistItem({
    required this.text,
    this.checked = false,
  });

  InvoiceChecklistItem copyWith({
    String? text,
    bool? checked,
  }) {
    return InvoiceChecklistItem(
      text: text ?? this.text,
      checked: checked ?? this.checked,
    );
  }

  factory InvoiceChecklistItem.fromJson(Map<String, dynamic> json) {
    return InvoiceChecklistItem(
      text: (json['text'] ?? '').toString(),
      checked: json['checked'] is bool ? json['checked'] as bool : false,
    );
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        if (checked) 'checked': checked,
      };
}

class InvoiceBlock {
  final String type;
  final String? sku;
  final String? description;
  final num? qty;
  final String? unit;
  final num? unitPrice;
  final num? taxRate;
  final int? level;
  final bool? isBillable;
  final String? title;
  final String? value;
  final String? text;
  final List<InvoiceChecklistItem>? items;
  final num? lineSubtotal;
  final num? lineTax;
  final num? lineTotal;
  final Map<String, dynamic>? formatted;

  const InvoiceBlock({
    required this.type,
    this.sku,
    this.description,
    this.qty,
    this.unit,
    this.unitPrice,
    this.taxRate,
    this.level,
    this.isBillable,
    this.title,
    this.value,
    this.text,
    this.items,
    this.lineSubtotal,
    this.lineTax,
    this.lineTotal,
    this.formatted,
  });

  InvoiceBlock copyWith({
    String? type,
    String? sku,
    String? description,
    num? qty,
    String? unit,
    num? unitPrice,
    num? taxRate,
    int? level,
    bool? isBillable,
    String? title,
    String? value,
    String? text,
    List<InvoiceChecklistItem>? items,
    num? lineSubtotal,
    num? lineTax,
    num? lineTotal,
    Map<String, dynamic>? formatted,
  }) {
    return InvoiceBlock(
      type: type ?? this.type,
      sku: sku ?? this.sku,
      description: description ?? this.description,
      qty: qty ?? this.qty,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      taxRate: taxRate ?? this.taxRate,
      level: level ?? this.level,
      isBillable: isBillable ?? this.isBillable,
      title: title ?? this.title,
      value: value ?? this.value,
      text: text ?? this.text,
      items: items ?? this.items,
      lineSubtotal: lineSubtotal ?? this.lineSubtotal,
      lineTax: lineTax ?? this.lineTax,
      lineTotal: lineTotal ?? this.lineTotal,
      formatted: formatted ?? this.formatted,
    );
  }

  factory InvoiceBlock.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'];
    final rawFormatted = json['formatted'];
    return InvoiceBlock(
      type: (json['type'] ?? '').toString(),
      sku: json['sku']?.toString(),
      description: json['description']?.toString(),
      qty: json['qty'] is num ? json['qty'] as num : null,
      unit: json['unit']?.toString(),
      unitPrice: json['unitPrice'] is num ? json['unitPrice'] as num : null,
      taxRate: json['taxRate'] is num ? json['taxRate'] as num : null,
      level: json['level'] is num ? (json['level'] as num).toInt() : null,
      isBillable:
          json['isBillable'] is bool ? json['isBillable'] as bool : null,
      title: json['title']?.toString(),
      value: json['value']?.toString(),
      text: json['text']?.toString(),
      items: itemsJson is List
          ? itemsJson
              .whereType<Map<String, dynamic>>()
              .map(InvoiceChecklistItem.fromJson)
              .toList()
          : null,
      lineSubtotal:
          json['lineSubtotal'] is num ? json['lineSubtotal'] as num : null,
      lineTax: json['lineTax'] is num ? json['lineTax'] as num : null,
      lineTotal: json['lineTotal'] is num ? json['lineTotal'] as num : null,
      formatted:
          rawFormatted is Map ? Map<String, dynamic>.from(rawFormatted) : null,
    );
  }

  Map<String, dynamic> toJson() {
    String? clean(String? v) => v?.trim().isEmpty ?? true ? null : v?.trim();
    return {
      'type': type,
      if (clean(sku) != null) 'sku': clean(sku),
      if (clean(description) != null) 'description': clean(description),
      if (qty != null) 'qty': qty,
      if (clean(unit) != null) 'unit': clean(unit),
      if (unitPrice != null) 'unitPrice': unitPrice,
      if (taxRate != null) 'taxRate': taxRate,
      if (level != null) 'level': level,
      if (isBillable != null) 'isBillable': isBillable,
      if (clean(title) != null) 'title': clean(title),
      if (clean(text) != null) 'text': clean(text),
      if (items != null) 'items': items!.map((item) => item.toJson()).toList(),
      if (lineSubtotal != null) 'lineSubtotal': lineSubtotal,
      if (lineTax != null) 'lineTax': lineTax,
      if (lineTotal != null) 'lineTotal': lineTotal,
      if (formatted != null) 'formatted': formatted,
    };
  }
}
