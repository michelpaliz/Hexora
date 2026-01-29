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
  String type;
  final TextEditingController sku;
  final TextEditingController description;
  final TextEditingController qtyCtrl;
  final TextEditingController unitCtrl;
  final TextEditingController unitPriceCtrl;
  final TextEditingController taxRateCtrl;
  final TextEditingController levelCtrl;
  bool isBillable;
  final TextEditingController title;
  String? dateValue;
  final TextEditingController text;
  final List<InvoiceChecklistItemDraft> checklistItems;

  InvoiceBlockDraft({
    required this.type,
    String? sku,
    String? description,
    String? qty,
    String? unit,
    String? unitPrice,
    String? taxRate,
    String? level,
    this.isBillable = true,
    String? title,
    String? dateValue,
    String? text,
    List<InvoiceChecklistItemDraft>? checklistItems,
  })  : sku = TextEditingController(text: sku ?? ''),
        description = TextEditingController(text: description ?? ''),
        qtyCtrl = TextEditingController(text: qty ?? '1'),
        unitCtrl = TextEditingController(text: unit ?? ''),
        unitPriceCtrl = TextEditingController(text: unitPrice ?? ''),
        taxRateCtrl = TextEditingController(text: taxRate ?? '21'),
        levelCtrl = TextEditingController(text: level ?? ''),
        title = TextEditingController(text: title ?? ''),
        dateValue = dateValue,
        text = TextEditingController(text: text ?? ''),
        checklistItems = checklistItems ?? <InvoiceChecklistItemDraft>[];

  factory InvoiceBlockDraft.item() => InvoiceBlockDraft(
        type: InvoiceBlockType.item,
      );

  factory InvoiceBlockDraft.ofType(String type) {
    final draft = InvoiceBlockDraft(type: type);
    if (type == InvoiceBlockType.checklist && draft.checklistItems.isEmpty) {
      draft.checklistItems.add(InvoiceChecklistItemDraft());
    }
    return draft;
  }

  String _norm(String v) => v.trim().replaceAll(',', '.');

  num? get qty => num.tryParse(_norm(qtyCtrl.text));
  num? get unitPrice => num.tryParse(_norm(unitPriceCtrl.text));
  num? get taxRate => num.tryParse(_norm(taxRateCtrl.text));
  int? get level => int.tryParse(levelCtrl.text.trim());

  bool get isItem => type == InvoiceBlockType.item;
  bool get isBillableItem => isItem && isBillable;

  bool get hasBillableContent {
    if (!isBillableItem) return false;
    return description.text.trim().isNotEmpty &&
        (unitPrice ?? 0) > 0 &&
        (qty ?? 0) >= 0;
  }

  InvoiceBlock toBlock() {
    String? clean(String? v) => v?.trim().isEmpty ?? true ? null : v?.trim();
    final parsedQty = qty;
    final parsedUnitPrice = unitPrice;
    final parsedTaxRate = taxRate;
    final parsedLevel = level;

    return InvoiceBlock(
      type: type,
      sku: clean(sku.text),
      description: clean(description.text),
      qty: parsedQty,
      unit: clean(unitCtrl.text),
      unitPrice: parsedUnitPrice,
      taxRate: parsedTaxRate,
      level: parsedLevel,
      isBillable: isItem ? isBillable : null,
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
    taxRateCtrl.dispose();
    levelCtrl.dispose();
    title.dispose();
    text.dispose();
    for (final item in checklistItems) {
      item.dispose();
    }
  }
}
