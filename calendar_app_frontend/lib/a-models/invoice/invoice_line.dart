import 'package:hexora/a-models/invoice/invoice_concept_utils.dart';

class InvoiceLine {
  final String? id;
  final String invoiceId;
  final int position;
  final String description;
  final num quantity;
  final num unitPrice;
  final num discountRate;
  final num taxRate;
  final num? lineSubtotal;
  final num? lineTax;
  final num? lineTotal;
  final String? evidenceBlobName;
  final String? sku;
  final List<String>? conceptItems;
  final String? conceptTitle;
  final String? serviceDate;
  final bool? isCompositeConcept;
  final String? parseMethod;

  const InvoiceLine({
    this.id,
    required this.invoiceId,
    required this.position,
    required this.description,
    this.quantity = 1,
    required this.unitPrice,
    this.discountRate = 0,
    this.taxRate = 21,
    this.lineSubtotal,
    this.lineTax,
    this.lineTotal,
    this.evidenceBlobName,
    this.sku,
    this.conceptItems,
    this.conceptTitle,
    this.serviceDate,
    this.isCompositeConcept,
    this.parseMethod,
  });

  InvoiceLine copyWith({
    String? id,
    String? invoiceId,
    int? position,
    String? description,
    num? quantity,
    num? unitPrice,
    num? discountRate,
    num? taxRate,
    num? lineSubtotal,
    num? lineTax,
    num? lineTotal,
    String? evidenceBlobName,
    String? sku,
    List<String>? conceptItems,
    String? conceptTitle,
    String? serviceDate,
    bool? isCompositeConcept,
    String? parseMethod,
  }) {
    return InvoiceLine(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      position: position ?? this.position,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      discountRate: discountRate ?? this.discountRate,
      taxRate: taxRate ?? this.taxRate,
      lineSubtotal: lineSubtotal ?? this.lineSubtotal,
      lineTax: lineTax ?? this.lineTax,
      lineTotal: lineTotal ?? this.lineTotal,
      evidenceBlobName: evidenceBlobName ?? this.evidenceBlobName,
      sku: sku ?? this.sku,
      conceptItems: conceptItems ?? this.conceptItems,
      conceptTitle: conceptTitle ?? this.conceptTitle,
      serviceDate: serviceDate ?? this.serviceDate,
      isCompositeConcept: isCompositeConcept ?? this.isCompositeConcept,
      parseMethod: parseMethod ?? this.parseMethod,
    );
  }

  factory InvoiceLine.fromJson(Map<String, dynamic> json) {
    final rawConceptItems = json['conceptItems'];
    return InvoiceLine(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      invoiceId: (json['invoiceId'] ?? '').toString(),
      position: (json['position'] is num ? json['position'] as num : 0).toInt(),
      description: (json['description'] ?? '').toString(),
      quantity: json['quantity'] is num ? json['quantity'] as num : 1,
      unitPrice: json['unitPrice'] is num ? json['unitPrice'] as num : 0,
      discountRate: json['discountRate'] is num
          ? json['discountRate'] as num
          : json['discountPercent'] is num
              ? json['discountPercent'] as num
              : 0,
      taxRate: json['taxRate'] is num ? json['taxRate'] as num : 21,
      lineSubtotal:
          json['lineSubtotal'] is num ? json['lineSubtotal'] as num : null,
      lineTax: json['lineTax'] is num ? json['lineTax'] as num : null,
      lineTotal: json['lineTotal'] is num ? json['lineTotal'] as num : null,
      evidenceBlobName:
          (json['evidenceBlobName'] ?? json['evidence_blob_name'])?.toString(),
      sku: json['sku']?.toString(),
      conceptItems: rawConceptItems is List
          ? rawConceptItems.map((item) => item.toString()).toList()
          : null,
      conceptTitle: json['conceptTitle']?.toString(),
      serviceDate: cleanInvoiceServiceDate(json['serviceDate']),
      isCompositeConcept: json['isCompositeConcept'] is bool
          ? json['isCompositeConcept'] as bool
          : null,
      parseMethod: json['parseMethod']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final cleanSku = cleanInvoiceText(sku);
    final title = invoiceConceptTitleFrom(
      conceptTitle: conceptTitle,
      sku: cleanSku,
    );
    final items = cleanInvoiceConceptItems(conceptItems, staleSku: cleanSku);
    final date = cleanInvoiceServiceDate(serviceDate);
    final cleanDescription = cleanInvoiceDescription(description, date);
    final descriptionPayload = cleanDescription.isNotEmpty
        ? cleanDescription
        : (items?.isNotEmpty ?? false)
            ? items!.first
            : title ?? '';

    return {
      if (id != null) 'id': id,
      'invoiceId': invoiceId,
      'position': position,
      'description': descriptionPayload,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'discountRate': discountRate,
      'taxRate': taxRate,
      if (lineSubtotal != null) 'lineSubtotal': lineSubtotal,
      if (lineTax != null) 'lineTax': lineTax,
      if (lineTotal != null) 'lineTotal': lineTotal,
      if (evidenceBlobName != null) 'evidenceBlobName': evidenceBlobName,
      if (cleanSku != null && isInvoiceUnitCode(cleanSku)) 'sku': cleanSku,
      if (items != null) 'conceptItems': items,
      if (title != null) 'conceptTitle': title,
      if (date != null) 'serviceDate': date,
      if (isCompositeConcept != null)
        'isCompositeConcept': isCompositeConcept
      else if (items != null && items.length > 1)
        'isCompositeConcept': true,
      if (cleanInvoiceText(parseMethod) != null)
        'parseMethod': cleanInvoiceText(parseMethod),
    };
  }
}
