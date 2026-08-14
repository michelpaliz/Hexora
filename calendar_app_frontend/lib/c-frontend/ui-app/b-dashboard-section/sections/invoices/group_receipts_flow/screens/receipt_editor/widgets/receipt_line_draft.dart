import 'package:flutter/material.dart';
import 'package:hexora/a-models/receipt/receipt_line.dart';

class ReceiptLineDraft {
  final TextEditingController descriptionCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController unitCtrl;
  final TextEditingController unitLabelCtrl;
  String selectedUnit;

  ReceiptLineDraft._({
    required this.descriptionCtrl,
    required this.qtyCtrl,
    required this.unitCtrl,
    required this.unitLabelCtrl,
    required this.selectedUnit,
  });

  factory ReceiptLineDraft.empty() => ReceiptLineDraft._(
        descriptionCtrl: TextEditingController(),
        qtyCtrl: TextEditingController(text: '1'),
        unitCtrl: TextEditingController(text: '0'),
        unitLabelCtrl: TextEditingController(),
        selectedUnit: 'unit',
      );

  factory ReceiptLineDraft.fromLine(ReceiptLine line) => ReceiptLineDraft._(
        descriptionCtrl: TextEditingController(text: line.description),
        qtyCtrl: TextEditingController(text: line.quantity.toString()),
        unitCtrl: TextEditingController(text: line.unitPrice.toString()),
        unitLabelCtrl: TextEditingController(text: line.unitLabel ?? ''),
        selectedUnit: _normalizeUnit(line.unit),
      );

  bool get hasAnyValue =>
      description.trim().isNotEmpty || (quantity != 1) || (unitPrice != 0);

  String get description => descriptionCtrl.text;

  num get quantity => num.tryParse(qtyCtrl.text.replaceAll(',', '.')) ?? 1;

  String get unit => _normalizeUnit(selectedUnit);

  String? get unitLabel {
    final custom = unitLabelCtrl.text.trim();
    if (unit == 'other') return custom.isEmpty ? 'Otro' : custom;
    return receiptUnitLabel(unit);
  }

  num get unitPrice => num.tryParse(unitCtrl.text.replaceAll(',', '.')) ?? 0;

  num get total => quantity * unitPrice;

  void dispose() {
    descriptionCtrl.dispose();
    qtyCtrl.dispose();
    unitCtrl.dispose();
    unitLabelCtrl.dispose();
  }

  static String _normalizeUnit(String value) {
    const allowed = {'unit', 'hour', 'day', 'service', 'item', 'other'};
    return allowed.contains(value) ? value : 'unit';
  }
}

String receiptUnitLabel(String unit) {
  switch (unit) {
    case 'hour':
      return 'Hora';
    case 'day':
      return 'Día';
    case 'service':
      return 'Servicio';
    case 'item':
      return 'Artículo';
    case 'other':
      return 'Otro';
    case 'unit':
    default:
      return 'Ud.';
  }
}
