import 'package:hexora/a-models/invoice/invoice_concept_utils.dart';

class InvoiceBlockType {
  static const String item = 'item';
  static const String date = 'date';
  static const String section = 'section';
  static const String subsection = 'subsection';
  static const String divider = 'divider';
  static const String note = 'note';
  static const String checklist = 'checklist';
  static const String worker = 'worker';
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
  final List<String>? conceptItems;
  final String? conceptTitle;
  final String? serviceDate;
  final bool? isCompositeConcept;
  final String? description;
  final num? qty;
  final String? unit;
  final num? unitPrice;
  final num? discountRate;
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
    this.conceptItems,
    this.conceptTitle,
    this.serviceDate,
    this.isCompositeConcept,
    this.description,
    this.qty,
    this.unit,
    this.unitPrice,
    this.discountRate,
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
    List<String>? conceptItems,
    String? conceptTitle,
    String? serviceDate,
    bool? isCompositeConcept,
    String? description,
    num? qty,
    String? unit,
    num? unitPrice,
    num? discountRate,
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
      conceptItems: conceptItems ?? this.conceptItems,
      conceptTitle: conceptTitle ?? this.conceptTitle,
      serviceDate: serviceDate ?? this.serviceDate,
      isCompositeConcept: isCompositeConcept ?? this.isCompositeConcept,
      description: description ?? this.description,
      qty: qty ?? this.qty,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      discountRate: discountRate ?? this.discountRate,
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
    final rawConceptItems = json['conceptItems'];
    final rawFormatted = json['formatted'];
    return InvoiceBlock(
      type: (json['type'] ?? '').toString(),
      sku: json['sku']?.toString(),
      conceptItems: rawConceptItems is List
          ? rawConceptItems.map((item) => item.toString()).toList()
          : null,
      conceptTitle: json['conceptTitle']?.toString(),
      serviceDate: cleanInvoiceServiceDate(json['serviceDate']),
      isCompositeConcept: json['isCompositeConcept'] is bool
          ? json['isCompositeConcept'] as bool
          : null,
      description: json['description']?.toString(),
      qty: json['qty'] is num ? json['qty'] as num : null,
      unit: json['unit']?.toString(),
      unitPrice: json['unitPrice'] is num ? json['unitPrice'] as num : null,
      discountRate: json['discountRate'] is num
          ? json['discountRate'] as num
          : json['discountPercent'] is num
              ? json['discountPercent'] as num
              : null,
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
    final cleanSku = cleanInvoiceText(sku);
    final title = invoiceConceptTitleFrom(
      conceptTitle: conceptTitle,
      sku: cleanSku,
    );
    final conceptItemsPayload =
        cleanInvoiceConceptItems(conceptItems, staleSku: cleanSku);
    final date = cleanInvoiceServiceDate(serviceDate);
    return {
      'type': type,
      if (cleanSku != null && isInvoiceUnitCode(cleanSku)) 'sku': cleanSku,
      if (conceptItemsPayload != null) 'conceptItems': conceptItemsPayload,
      if (title != null) 'conceptTitle': title,
      if (date != null) 'serviceDate': date,
      if (isCompositeConcept != null)
        'isCompositeConcept': isCompositeConcept
      else if (conceptItemsPayload != null && conceptItemsPayload.length > 1)
        'isCompositeConcept': true,
      if (cleanInvoiceText(description) != null)
        'description': cleanInvoiceDescription(description!, date),
      if (qty != null) 'qty': qty,
      if (cleanInvoiceText(unit) != null) 'unit': cleanInvoiceText(unit),
      if (unitPrice != null) 'unitPrice': unitPrice,
      if (discountRate != null) 'discountRate': discountRate,
      if (taxRate != null) 'taxRate': taxRate,
      if (level != null) 'level': level,
      if (isBillable != null) 'isBillable': isBillable,
      if (cleanInvoiceText(this.title) != null)
        'title': cleanInvoiceText(this.title),
      if (cleanInvoiceText(text) != null) 'text': cleanInvoiceText(text),
      if (items != null) 'items': items!.map((item) => item.toJson()).toList(),
      if (lineSubtotal != null) 'lineSubtotal': lineSubtotal,
      if (lineTax != null) 'lineTax': lineTax,
      if (lineTotal != null) 'lineTotal': lineTotal,
      if (formatted != null) 'formatted': formatted,
    };
  }
}
