import 'package:flutter/material.dart';
import 'package:hexora/a-models/invoice/invoice_block.dart';

class InvoiceChecklistItemDraft {
  final TextEditingController text;
  bool checked;

  InvoiceChecklistItemDraft({
    String? initialText,
    this.checked = false,
  }) : text = TextEditingController(text: initialText ?? '');

  InvoiceChecklistItem toItem() => InvoiceChecklistItem(
        text: text.text.trim(),
        checked: checked,
      );

  void dispose() {
    text.dispose();
  }
}

class InvoiceBlockDraft {
  static bool defaultBillableForType(String type) {
    return type == InvoiceBlockType.item;
  }

  String type;
  final TextEditingController sku;
  List<String>? conceptItems;
  String? conceptTitle;
  String? serviceDate;
  bool? isCompositeConcept;
  late final TextEditingController conceptTitleCtrl;
  late final TextEditingController conceptItemsCtrl;
  late final TextEditingController serviceDateCtrl;
  late final TextEditingController description;
  late final TextEditingController qtyCtrl;
  late final TextEditingController unitCtrl;
  late final TextEditingController unitPriceCtrl;
  late final TextEditingController discountRateCtrl;
  late final TextEditingController taxRateCtrl;
  late final TextEditingController levelCtrl;
  bool isBillable;
  late final TextEditingController title;
  String? dateValue;
  late final TextEditingController text;
  late final List<InvoiceChecklistItemDraft> checklistItems;

  InvoiceBlockDraft({
    required this.type,
    String? sku,
    this.conceptItems,
    this.conceptTitle,
    this.serviceDate,
    this.isCompositeConcept,
    String? description,
    String? qty,
    String? unit,
    String? unitPrice,
    String? discountRate,
    String? taxRate,
    String? level,
    this.isBillable = true,
    String? title,
    this.dateValue,
    String? text,
    List<InvoiceChecklistItemDraft>? checklistItems,
  }) : sku = TextEditingController(text: sku ?? '') {
    conceptTitleCtrl = TextEditingController(text: conceptTitle ?? sku ?? '');
    conceptItemsCtrl = TextEditingController(
      text: conceptItems == null || conceptItems!.length <= 1
          ? conceptItems?.join(', ') ?? ''
          : conceptItems!.join('\n'),
    );
    serviceDateCtrl = TextEditingController(text: serviceDate ?? '');
    this.description = TextEditingController(text: description ?? '');
    qtyCtrl = TextEditingController(text: qty ?? '1');
    unitCtrl = TextEditingController(text: unit ?? '');
    unitPriceCtrl = TextEditingController(text: unitPrice ?? '');
    discountRateCtrl = TextEditingController(text: discountRate ?? '0');
    taxRateCtrl = TextEditingController(text: taxRate ?? '21');
    levelCtrl = TextEditingController(text: level ?? '');
    this.title = TextEditingController(text: title ?? '');
    this.text = TextEditingController(text: text ?? '');
    this.checklistItems = checklistItems ?? <InvoiceChecklistItemDraft>[];
  }

  factory InvoiceBlockDraft.item() => InvoiceBlockDraft(
        type: InvoiceBlockType.item,
        isBillable: true,
      );

  factory InvoiceBlockDraft.ofType(String type) {
    final draft = InvoiceBlockDraft(
      type: type,
      isBillable: defaultBillableForType(type),
    );
    if (type == InvoiceBlockType.checklist && draft.checklistItems.isEmpty) {
      draft.checklistItems.add(InvoiceChecklistItemDraft());
    }
    return draft;
  }

  String _norm(String v) => v.trim().replaceAll(',', '.');

  num? get qty => num.tryParse(_norm(qtyCtrl.text));
  num? get unitPrice => num.tryParse(_norm(unitPriceCtrl.text));
  num? get discountRate {
    final parsed = num.tryParse(_norm(discountRateCtrl.text)) ?? 0;
    return parsed.clamp(0, 100);
  }

  num? get taxRate => num.tryParse(_norm(taxRateCtrl.text));
  int? get level => int.tryParse(levelCtrl.text.trim());

  List<String>? _conceptItemsFromText(String value) {
    final items = value
        .split(RegExp(r'[,;\n]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    return items.isEmpty ? null : items;
  }

  void syncConceptMetadata() {
    final title = conceptTitleCtrl.text.trim();
    conceptTitle = title.isEmpty ? null : title;
    sku.text = title;
    conceptItems = _conceptItemsFromText(conceptItemsCtrl.text);
    final date = serviceDateCtrl.text.trim();
    serviceDate = date.isEmpty ? null : date;
    isCompositeConcept = (conceptItems?.length ?? 0) > 1 ? true : null;
  }

  bool get isItem => type == InvoiceBlockType.item;
  bool get isSection => type == InvoiceBlockType.section;
  bool get isChecklist => type == InvoiceBlockType.checklist;
  bool get isBillableItem => isItem && isBillable;
  bool get isBillableSection => isSection && isBillable;
  bool get isBillableChecklist => isChecklist && isBillable;
  bool get isBillableLine => (isItem || isSection || isChecklist) && isBillable;

  bool get hasBillableContent {
    if (isBillableItem) {
      final hasConcept = description.text.trim().isNotEmpty ||
          conceptTitleCtrl.text.trim().isNotEmpty ||
          conceptItemsCtrl.text.trim().isNotEmpty;
      return hasConcept && (unitPrice ?? 0) > 0 && (qty ?? 0) >= 0;
    }
    if (isBillableSection) {
      return title.text.trim().isNotEmpty &&
          (unitPrice ?? 0) > 0 &&
          (qty ?? 0) >= 0;
    }
    if (isBillableChecklist) {
      final titleText = title.text.trim();
      final firstItem = checklistItems.isNotEmpty
          ? checklistItems.first.text.text.trim()
          : '';
      return (titleText.isNotEmpty || firstItem.isNotEmpty) &&
          (unitPrice ?? 0) > 0 &&
          (qty ?? 0) >= 0;
    }
    return false;
  }

  InvoiceBlock toBlock() {
    String? clean(String? v) => v?.trim().isEmpty ?? true ? null : v?.trim();
    final parsedQty = qty;
    final parsedUnitPrice = unitPrice;
    final parsedDiscountRate = discountRate ?? 0;
    final parsedTaxRate = taxRate;
    final parsedLevel = level;

    return InvoiceBlock(
      type: type,
      sku: clean(sku.text),
      conceptItems: _conceptItemsFromText(conceptItemsCtrl.text),
      conceptTitle: clean(conceptTitleCtrl.text) ?? conceptTitle,
      serviceDate: clean(serviceDateCtrl.text) ?? serviceDate,
      isCompositeConcept: isCompositeConcept ??
          ((_conceptItemsFromText(conceptItemsCtrl.text)?.length ?? 0) > 1
              ? true
              : null),
      description: clean(description.text),
      qty: parsedQty,
      unit: clean(unitCtrl.text),
      unitPrice: parsedUnitPrice,
      discountRate: isBillableLine ? parsedDiscountRate : null,
      taxRate: parsedTaxRate,
      level: parsedLevel,
      isBillable: isBillableLine ? isBillable : null,
      title: clean(title.text),
      text: clean(text.text),
      items: checklistItems.isEmpty
          ? null
          : checklistItems.map((item) => item.toItem()).toList(),
    );
  }

  void dispose() {
    sku.dispose();
    description.dispose();
    qtyCtrl.dispose();
    unitCtrl.dispose();
    unitPriceCtrl.dispose();
    discountRateCtrl.dispose();
    taxRateCtrl.dispose();
    levelCtrl.dispose();
    title.dispose();
    text.dispose();
    for (final item in checklistItems) {
      item.dispose();
    }
  }
}
