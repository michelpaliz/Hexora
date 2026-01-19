import 'package:flutter/material.dart';

class ExpenseLineDraft {
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController quantityController =
      TextEditingController(text: '1');
  final TextEditingController unitPriceController = TextEditingController();
  final TextEditingController taxRateController = TextEditingController();

  double _parseNum(String raw) {
    final value = raw.trim().replaceAll(',', '.');
    return double.tryParse(value) ?? 0;
  }

  double get quantity => _parseNum(quantityController.text);
  double get unitPrice => _parseNum(unitPriceController.text);
  double get taxRate => _parseNum(taxRateController.text);

  double get subtotal => quantity * unitPrice;
  double get taxAmount => subtotal * (taxRate / 100);
  double get total => subtotal + taxAmount;

  Map<String, dynamic> toJson() {
    return {
      'description': descriptionController.text.trim(),
      'quantity': quantity,
      'unitPrice': unitPrice,
      'taxRate': taxRate,
      'lineSubtotal': subtotal,
      'lineTax': taxAmount,
      'lineTotal': total,
    };
  }

  void dispose() {
    descriptionController.dispose();
    quantityController.dispose();
    unitPriceController.dispose();
    taxRateController.dispose();
  }
}
