String? cleanInvoiceText(String? value) {
  final text = value?.trim();
  return text == null || text.isEmpty ? null : text;
}

bool isInvoiceUnitCode(String? value) {
  final text = cleanInvoiceText(value);
  if (text == null) return false;
  return RegExp(r'^[A-Za-z]{1,4}[-\s]?\d{1,4}[A-Za-z]?$').hasMatch(text);
}

String? invoiceConceptTitleFrom({
  String? conceptTitle,
  String? sku,
}) {
  final title = cleanInvoiceText(conceptTitle);
  if (title != null) return title;
  final cleanSku = cleanInvoiceText(sku);
  return isInvoiceUnitCode(cleanSku) ? cleanSku : null;
}

List<String>? cleanInvoiceConceptItems(
  List<String>? conceptItems, {
  String? staleSku,
}) {
  final items = <String>[
    if (conceptItems != null)
      ...conceptItems
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty),
  ];
  final sku = cleanInvoiceText(staleSku);
  if (items.isEmpty && sku != null && !isInvoiceUnitCode(sku)) {
    items.add(sku);
  }
  return items.isEmpty ? null : items;
}

String? cleanInvoiceServiceDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) {
    return value.toIso8601String().split('T').first;
  }
  final text = value.toString().trim();
  if (text.isEmpty) return null;
  final isoDate = RegExp(r'^\d{4}-\d{2}-\d{2}').firstMatch(text);
  if (isoDate != null) return isoDate.group(0);
  final parsed = DateTime.tryParse(text);
  if (parsed != null) return parsed.toIso8601String().split('T').first;
  return text;
}

String cleanInvoiceDescription(String description, String? serviceDate) {
  var text = description.trim();
  final date = cleanInvoiceServiceDate(serviceDate);
  if (date != null && text.startsWith(date)) {
    text = text.substring(date.length).trimLeft();
  }
  text = text.replaceFirst(RegExp(r'^[-–—:|]\s*'), '');
  return text.trim();
}
