import 'package:flutter/material.dart';
import 'package:hexora/a-models/receipt/receipt_line.dart';

class ReceiptLineDraft {
  final TextEditingController descriptionCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController unitCtrl;

  ReceiptLineDraft._({
    required this.descriptionCtrl,
    required this.qtyCtrl,
    required this.unitCtrl,
  });

  factory ReceiptLineDraft.empty() => ReceiptLineDraft._(
        descriptionCtrl: TextEditingController(),
        qtyCtrl: TextEditingController(text: '1'),
        unitCtrl: TextEditingController(text: '0'),
      );

  factory ReceiptLineDraft.fromLine(ReceiptLine line) => ReceiptLineDraft._(
        descriptionCtrl: TextEditingController(text: line.description),
        qtyCtrl: TextEditingController(text: line.quantity.toString()),
        unitCtrl: TextEditingController(text: line.unitPrice.toString()),
      );

  bool get hasAnyValue =>
      description.trim().isNotEmpty || (quantity != 1) || (unitPrice != 0);

  String get description => descriptionCtrl.text;

  num get quantity => num.tryParse(qtyCtrl.text.replaceAll(',', '.')) ?? 1;

  num get unitPrice => num.tryParse(unitCtrl.text.replaceAll(',', '.')) ?? 0;

  num get total => quantity * unitPrice;

  void dispose() {
    descriptionCtrl.dispose();
    qtyCtrl.dispose();
    unitCtrl.dispose();
  }
}

