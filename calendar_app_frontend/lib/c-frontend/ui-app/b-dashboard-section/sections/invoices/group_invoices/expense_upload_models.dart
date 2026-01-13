import 'package:flutter/material.dart';

class ExpenseLineDraft {
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController quantityController =
      TextEditingController(text: '1');
  final TextEditingController unitPriceController = TextEditingController();
  final TextEditingController taxRateController = TextEditingController();

  double get quantity => double.tryParse(quantityController.text) ?? 0;
  double get unitPrice => double.tryParse(unitPriceController.text) ?? 0;
  double get taxRate => double.tryParse(taxRateController.text) ?? 0;

  double get subtotal => quantity * unitPrice;
  double get taxAmount => subtotal * (taxRate / 100);
  double get total => subtotal + taxAmount;

  Map<String, dynamic> toJson() {
    return {
      'description': descriptionController.text.trim(),
      'quantity': quantity,
      'unitPrice': unitPrice,
      'taxRate': taxRate,
    };
  }

  void dispose() {
    descriptionController.dispose();
    quantityController.dispose();
    unitPriceController.dispose();
    taxRateController.dispose();
  }
}
