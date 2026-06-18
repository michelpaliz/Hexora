import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/utils/money_format_utils.dart';

enum ExpenseLineDiscountMode {
  amount,
  percent,
}

class ExpenseDocumentDiscountPreview {
  final double subtotalBeforeDiscount;
  final double discountAmount;
  final double discountPercent;
  final double taxableBase;
  final double tax;
  final double total;

  const ExpenseDocumentDiscountPreview({
    required this.subtotalBeforeDiscount,
    required this.discountAmount,
    required this.discountPercent,
    required this.taxableBase,
    required this.tax,
    required this.total,
  });
}

class ExpenseWithholdingPreview {
  final ExpenseWithholdingType type;
  final double percent;
  final double amount;
  final double taxableBase;
  final double grossTotal;
  final double payableTotal;

  const ExpenseWithholdingPreview({
    required this.type,
    required this.percent,
    required this.amount,
    required this.taxableBase,
    required this.grossTotal,
    required this.payableTotal,
  });

  bool get hasWithholding =>
      type != ExpenseWithholdingType.none && amount > 0.0001;
}

enum ExpenseDocumentType {
  standard,
  advance,
  finalExpense,
}

enum ExpenseWithholdingType {
  none,
  irpf,
  other,
}

extension ExpenseWithholdingTypeX on ExpenseWithholdingType {
  String get apiValue {
    switch (this) {
      case ExpenseWithholdingType.none:
        return '';
      case ExpenseWithholdingType.irpf:
        return 'IRPF';
      case ExpenseWithholdingType.other:
        return 'other';
    }
  }

  String get labelEs {
    switch (this) {
      case ExpenseWithholdingType.none:
        return 'Sin retencion';
      case ExpenseWithholdingType.irpf:
        return 'IRPF';
      case ExpenseWithholdingType.other:
        return 'Otra';
    }
  }

  static ExpenseWithholdingType fromApi(dynamic raw) {
    final text = (raw ?? '').toString().trim().toLowerCase();
    switch (text) {
      case 'irpf':
        return ExpenseWithholdingType.irpf;
      case 'other':
        return ExpenseWithholdingType.other;
      default:
        return ExpenseWithholdingType.none;
    }
  }
}

extension ExpenseDocumentTypeX on ExpenseDocumentType {
  String get apiValue {
    switch (this) {
      case ExpenseDocumentType.standard:
        return 'standard';
      case ExpenseDocumentType.advance:
        return 'advance';
      case ExpenseDocumentType.finalExpense:
        return 'final';
    }
  }

  String get labelEs {
    switch (this) {
      case ExpenseDocumentType.standard:
        return 'Estandar';
      case ExpenseDocumentType.advance:
        return 'Anticipo';
      case ExpenseDocumentType.finalExpense:
        return 'Factura final';
    }
  }

  bool get isAdvance => this == ExpenseDocumentType.advance;
  bool get isFinal => this == ExpenseDocumentType.finalExpense;

  static ExpenseDocumentType fromApi(dynamic raw) {
    final text = (raw ?? '').toString().trim().toLowerCase();
    switch (text) {
      case 'advance':
        return ExpenseDocumentType.advance;
      case 'final':
        return ExpenseDocumentType.finalExpense;
      default:
        return ExpenseDocumentType.standard;
    }
  }
}

class ExpenseAdvanceOption {
  final String id;
  final String invoiceNumber;
  final String vendorName;
  final String providerId;
  final String issueDate;
  final String currency;
  final double total;
  final double tax;
  final double base;

  const ExpenseAdvanceOption({
    required this.id,
    required this.invoiceNumber,
    required this.vendorName,
    required this.providerId,
    required this.issueDate,
    required this.currency,
    required this.total,
    required this.tax,
    required this.base,
  });

  factory ExpenseAdvanceOption.fromRecentMap(Map<String, String> item) {
    final total = parseFlexibleMoney(item['total']) ?? 0;
    final tax = parseFlexibleMoney(item['tax']) ?? 0;
    return ExpenseAdvanceOption(
      id: (item['id'] ?? '').trim(),
      invoiceNumber: (item['invoice'] ?? '').trim(),
      vendorName: (item['vendor'] ?? item['providerName'] ?? '').trim(),
      providerId: (item['providerId'] ?? '').trim(),
      issueDate: (item['date'] ?? '').trim(),
      currency: ((item['currency'] ?? '').trim().isEmpty
              ? 'EUR'
              : (item['currency'] ?? '').trim())
          .toUpperCase(),
      total: total,
      tax: tax,
      base: (total - tax).clamp(0, double.infinity).toDouble(),
    );
  }

  String get menuLabel {
    final invoiceLabel =
        invoiceNumber.isNotEmpty ? '#$invoiceNumber' : 'Sin numero';
    final vendorLabel = vendorName.isNotEmpty ? vendorName : 'Proveedor';
    return '$invoiceLabel · $vendorLabel';
  }

  String get detailLabel {
    final amount = formatMoneyEu(total, fallback: '-');
    final invoiceLabel =
        invoiceNumber.isNotEmpty ? '#$invoiceNumber' : 'Sin numero';
    final dateLabel = issueDate.trim();
    final vendorLabel = vendorName.isNotEmpty ? vendorName : 'Proveedor';
    final parts = <String>[invoiceLabel, vendorLabel];
    if (dateLabel.isNotEmpty) parts.add(dateLabel);
    parts.add('$amount $currency');
    return parts.join(' · ');
  }
}

class ExpenseSettlementDraft {
  ExpenseDocumentType expenseType;
  final TextEditingController advancePercentController =
      TextEditingController();
  final TextEditingController projectBaseAmountController =
      TextEditingController();
  final TextEditingController advanceTaxRateController =
      TextEditingController();
  String? selectedAdvanceExpenseId;

  ExpenseSettlementDraft({
    this.expenseType = ExpenseDocumentType.standard,
  });

  factory ExpenseSettlementDraft.fromExpenseMap(Map<String, dynamic> map) {
    final draft = ExpenseSettlementDraft();
    draft.loadFromExpenseMap(map);
    return draft;
  }

  static double? _parseNum(dynamic raw) => parseFlexibleMoney(raw);

  String _formatEditableNumber(num value) {
    final fixed = value.toDouble().toStringAsFixed(2);
    if (fixed.endsWith('.00')) return fixed.substring(0, fixed.length - 3);
    if (fixed.endsWith('0')) return fixed.substring(0, fixed.length - 1);
    return fixed;
  }

  bool get isAdvance => expenseType.isAdvance;
  bool get isFinal => expenseType.isFinal;

  double? get advancePercent => _parseNum(advancePercentController.text.trim());
  double? get projectBaseAmount =>
      _parseNum(projectBaseAmountController.text.trim());
  double? get advanceTaxRate =>
      _parseNum(advanceTaxRateController.text.trim());

  void setExpenseType(ExpenseDocumentType nextType) {
    expenseType = nextType;
    if (!isFinal) {
      selectedAdvanceExpenseId = null;
    }
  }

  void loadFromExpenseMap(Map<String, dynamic> map) {
    expenseType = ExpenseDocumentTypeX.fromApi(map['expenseType']);
    final advancePayment = map['advancePayment'] is Map
        ? Map<String, dynamic>.from(map['advancePayment'] as Map)
        : const <String, dynamic>{};
    final finalSettlement = map['finalSettlement'] is Map
        ? Map<String, dynamic>.from(map['finalSettlement'] as Map)
        : const <String, dynamic>{};

    advancePercentController.text = advancePayment['percent'] == null
        ? ''
        : _formatEditableNumber(
            _parseNum(advancePayment['percent']) ?? 0,
          );
    projectBaseAmountController.text =
        advancePayment['projectBaseAmount'] == null
            ? ''
            : _formatEditableNumber(
                _parseNum(advancePayment['projectBaseAmount']) ?? 0,
              );
    advanceTaxRateController.text = advancePayment['taxRate'] == null
        ? ''
        : _formatEditableNumber(
            _parseNum(advancePayment['taxRate']) ?? 0,
          );

    final advanceExpenseId =
        (finalSettlement['advanceExpenseId'] ?? '').toString().trim();
    selectedAdvanceExpenseId =
        advanceExpenseId.isEmpty ? null : advanceExpenseId;
  }

  Map<String, dynamic>? buildAdvancePaymentPayload() {
    final payload = <String, dynamic>{};
    final percent = advancePercent;
    final projectBase = projectBaseAmount;
    final taxRate = advanceTaxRate;

    if (percent != null) payload['percent'] = percent;
    if (projectBase != null) payload['projectBaseAmount'] = projectBase;
    if (taxRate != null) payload['taxRate'] = taxRate;
    return payload.isEmpty ? null : payload;
  }

  Map<String, dynamic>? buildFinalSettlementPayload() {
    final advanceExpenseId = (selectedAdvanceExpenseId ?? '').trim();
    if (advanceExpenseId.isEmpty) return null;
    return <String, dynamic>{
      'advanceExpenseId': advanceExpenseId,
    };
  }

  void applyToExpensePayload(Map<String, dynamic> expense) {
    expense['expenseType'] = expenseType.apiValue;
    expense.remove('advancePayment');
    expense.remove('finalSettlement');
    if (isAdvance) {
      final advancePayment = buildAdvancePaymentPayload();
      if (advancePayment != null) {
        expense['advancePayment'] = advancePayment;
      }
    }
    if (isFinal) {
      final finalSettlement = buildFinalSettlementPayload();
      if (finalSettlement != null) {
        expense['finalSettlement'] = finalSettlement;
      }
    }
  }

  String? validate() {
    if (isFinal && (selectedAdvanceExpenseId ?? '').trim().isEmpty) {
      return 'Selecciona un anticipo relacionado para registrar la factura final.';
    }
    final percent = advancePercent;
    if (percent != null && (percent < 0 || percent > 100)) {
      return 'El porcentaje del anticipo debe estar entre 0 y 100.';
    }
    final projectBase = projectBaseAmount;
    if (projectBase != null && projectBase < 0) {
      return 'La base del proyecto no puede ser negativa.';
    }
    final taxRate = advanceTaxRate;
    if (taxRate != null && taxRate < 0) {
      return 'El IVA del anticipo no puede ser negativo.';
    }
    return null;
  }

  void dispose() {
    advancePercentController.dispose();
    projectBaseAmountController.dispose();
    advanceTaxRateController.dispose();
  }
}

class ExpenseDocumentDiscountDraft {
  final TextEditingController discountAmountController =
      TextEditingController();
  final TextEditingController discountPercentController =
      TextEditingController();

  ExpenseLineDiscountMode _mode = ExpenseLineDiscountMode.amount;
  bool _syncingControllers = false;

  static double? _parseNum(dynamic raw) => parseFlexibleMoney(raw);

  String _formatEditableNumber(num value) {
    final fixed = value.toDouble().toStringAsFixed(2);
    if (fixed.endsWith('.00')) return fixed.substring(0, fixed.length - 3);
    if (fixed.endsWith('0')) return fixed.substring(0, fixed.length - 1);
    return fixed;
  }

  double get rawDiscountAmount => _parseNum(discountAmountController.text) ?? 0;
  double get rawDiscountPercent =>
      _parseNum(discountPercentController.text) ?? 0;

  bool get hasDiscount =>
      rawDiscountAmount > 0.0001 || rawDiscountPercent > 0.0001;

  void loadFromExpenseMap(
    Map<String, dynamic> map, {
    double? subtotalBeforeDiscountHint,
  }) {
    final amount = _parseNum(map['discountAmount'] ?? map['discount_amount']) ?? 0;
    final percent =
        _parseNum(map['discountPercent'] ?? map['discount_percent']) ?? 0;

    if (percent > 0 && amount <= 0) {
      _mode = ExpenseLineDiscountMode.percent;
      discountPercentController.text = _formatEditableNumber(percent);
      if ((subtotalBeforeDiscountHint ?? 0) > 0) {
        final derived = ((subtotalBeforeDiscountHint ?? 0) * percent) / 100;
        discountAmountController.text =
            derived <= 0 ? '' : _formatEditableNumber(derived);
      } else {
        discountAmountController.text = '';
      }
      return;
    }

    _mode = ExpenseLineDiscountMode.amount;
    discountAmountController.text =
        amount <= 0 ? '' : _formatEditableNumber(amount);
    if (percent > 0) {
      discountPercentController.text = _formatEditableNumber(percent);
    } else if ((subtotalBeforeDiscountHint ?? 0) > 0 && amount > 0) {
      final derivedPercent = (amount / (subtotalBeforeDiscountHint ?? 1)) * 100;
      discountPercentController.text = _formatEditableNumber(derivedPercent);
    } else {
      discountPercentController.text = '';
    }
  }

  void onDiscountAmountChanged(double subtotalBeforeDiscount) {
    _mode = ExpenseLineDiscountMode.amount;
    syncDerivedFields(subtotalBeforeDiscount);
  }

  void onDiscountPercentChanged(double subtotalBeforeDiscount) {
    _mode = ExpenseLineDiscountMode.percent;
    syncDerivedFields(subtotalBeforeDiscount);
  }

  void syncDerivedFields(double subtotalBeforeDiscount) {
    if (_syncingControllers) return;
    _syncingControllers = true;
    final base = subtotalBeforeDiscount <= 0 ? 0.0 : subtotalBeforeDiscount;
    if (_mode == ExpenseLineDiscountMode.percent) {
      final normalizedPercent = rawDiscountPercent.clamp(0.0, 100.0);
      final amount = base <= 0 ? 0.0 : (base * normalizedPercent) / 100;
      if (rawDiscountPercent != normalizedPercent) {
        discountPercentController.text = normalizedPercent <= 0
            ? ''
            : _formatEditableNumber(normalizedPercent);
      }
      discountAmountController.text =
          amount <= 0 ? '' : _formatEditableNumber(amount);
    } else {
      final normalizedAmount = rawDiscountAmount.clamp(0.0, base);
      final percent =
          base <= 0 ? 0.0 : ((normalizedAmount / base) * 100).clamp(0.0, 100.0);
      if (rawDiscountAmount != normalizedAmount) {
        discountAmountController.text = normalizedAmount <= 0
            ? ''
            : _formatEditableNumber(normalizedAmount);
      }
      discountPercentController.text =
          percent <= 0 ? '' : _formatEditableNumber(percent);
    }
    _syncingControllers = false;
  }

  ExpenseDocumentDiscountPreview buildPreview({
    required double subtotalBeforeDiscount,
    required double taxBeforeDiscount,
  }) {
    final base = subtotalBeforeDiscount < 0 ? 0.0 : subtotalBeforeDiscount;
    final discountAmount = _mode == ExpenseLineDiscountMode.percent
        ? (base * rawDiscountPercent.clamp(0.0, 100.0)) / 100
        : rawDiscountAmount.clamp(0.0, base);
    final discountPercent = base <= 0
        ? 0.0
        : ((discountAmount / base) * 100).clamp(0.0, 100.0);
    final taxableBase = (base - discountAmount).clamp(0.0, double.infinity);
    final ratio = base <= 0 ? 0.0 : taxableBase / base;
    final tax = taxBeforeDiscount < 0 ? 0.0 : taxBeforeDiscount * ratio;
    final total = taxableBase + tax;
    return ExpenseDocumentDiscountPreview(
      subtotalBeforeDiscount: base,
      discountAmount: discountAmount.toDouble(),
      discountPercent: discountPercent.toDouble(),
      taxableBase: taxableBase.toDouble(),
      tax: tax.toDouble(),
      total: total.toDouble(),
    );
  }

  double grossBaseFromFinal(double finalBase) {
    final base = finalBase < 0 ? 0.0 : finalBase;
    if (rawDiscountAmount > 0.0001) {
      return base + rawDiscountAmount;
    }
    final percent = rawDiscountPercent.clamp(0.0, 100.0);
    if (percent > 0 && percent < 100) {
      return base / (1 - (percent / 100));
    }
    return base;
  }

  double grossTaxFromFinal({
    required double finalBase,
    required double finalTax,
  }) {
    final grossBase = grossBaseFromFinal(finalBase);
    if (grossBase <= 0 || finalBase <= 0) return finalTax < 0 ? 0 : finalTax;
    final ratio = finalBase / grossBase;
    if (ratio <= 0) return finalTax < 0 ? 0 : finalTax;
    return (finalTax < 0 ? 0 : finalTax) / ratio;
  }

  void applyToExpensePayload(Map<String, dynamic> expense) {
    expense['discountAmount'] = rawDiscountAmount <= 0
        ? 0
        : double.parse(rawDiscountAmount.toStringAsFixed(2));
    expense['discountPercent'] = rawDiscountPercent <= 0
        ? 0
        : double.parse(rawDiscountPercent.toStringAsFixed(2));
  }

  String? validate(double subtotalBeforeDiscount) {
    if (rawDiscountAmount < 0) {
      return 'El descuento total no puede ser negativo.';
    }
    if (rawDiscountPercent < 0 || rawDiscountPercent > 100) {
      return 'El descuento % debe estar entre 0 y 100.';
    }
    if (subtotalBeforeDiscount > 0 &&
        rawDiscountAmount > subtotalBeforeDiscount + 0.0001) {
      return 'El descuento total no puede superar el subtotal.';
    }
    return null;
  }

  void dispose() {
    discountAmountController.dispose();
    discountPercentController.dispose();
  }

  void clear() {
    discountAmountController.clear();
    discountPercentController.clear();
    _mode = ExpenseLineDiscountMode.amount;
  }
}

class ExpenseWithholdingDraft {
  ExpenseWithholdingType type;
  final TextEditingController amountController = TextEditingController();
  final TextEditingController percentController = TextEditingController();

  ExpenseLineDiscountMode _mode = ExpenseLineDiscountMode.percent;
  bool _syncingControllers = false;

  ExpenseWithholdingDraft({
    this.type = ExpenseWithholdingType.none,
  });

  static double? _parseNum(dynamic raw) => parseFlexibleMoney(raw);

  String _formatEditableNumber(num value) {
    final fixed = value.toDouble().toStringAsFixed(2);
    if (fixed.endsWith('.00')) return fixed.substring(0, fixed.length - 3);
    if (fixed.endsWith('0')) return fixed.substring(0, fixed.length - 1);
    return fixed;
  }

  bool get enabled => type != ExpenseWithholdingType.none;
  double get rawAmount => _parseNum(amountController.text) ?? 0;
  double get rawPercent => _parseNum(percentController.text) ?? 0;

  void setType(ExpenseWithholdingType nextType) {
    type = nextType;
    if (!enabled) {
      amountController.clear();
      percentController.clear();
      _mode = ExpenseLineDiscountMode.percent;
    }
  }

  void loadFromExpenseMap(
    Map<String, dynamic> map, {
    double? taxableBaseHint,
  }) {
    final withholding = map['withholding'] is Map
        ? Map<String, dynamic>.from(map['withholding'] as Map)
        : const <String, dynamic>{};
    type = ExpenseWithholdingTypeX.fromApi(withholding['type']);
    if (!enabled) {
      amountController.clear();
      percentController.clear();
      return;
    }

    final amount = _parseNum(withholding['amount']) ?? 0;
    final percent = _parseNum(withholding['percent']) ?? 0;

    if (percent > 0 && amount <= 0) {
      _mode = ExpenseLineDiscountMode.percent;
      percentController.text = _formatEditableNumber(percent);
      if ((taxableBaseHint ?? 0) > 0) {
        final derived = ((taxableBaseHint ?? 0) * percent) / 100;
        amountController.text = derived <= 0 ? '' : _formatEditableNumber(derived);
      } else {
        amountController.text = '';
      }
      return;
    }

    _mode = ExpenseLineDiscountMode.amount;
    amountController.text = amount <= 0 ? '' : _formatEditableNumber(amount);
    if (percent > 0) {
      percentController.text = _formatEditableNumber(percent);
    } else if ((taxableBaseHint ?? 0) > 0 && amount > 0) {
      final derivedPercent = (amount / (taxableBaseHint ?? 1)) * 100;
      percentController.text = _formatEditableNumber(derivedPercent);
    } else {
      percentController.text = '';
    }
  }

  void onAmountChanged(double taxableBase) {
    _mode = ExpenseLineDiscountMode.amount;
    syncDerivedFields(taxableBase);
  }

  void onPercentChanged(double taxableBase) {
    _mode = ExpenseLineDiscountMode.percent;
    syncDerivedFields(taxableBase);
  }

  void syncDerivedFields(double taxableBase) {
    if (_syncingControllers || !enabled) return;
    _syncingControllers = true;
    final base = taxableBase <= 0 ? 0.0 : taxableBase;
    if (_mode == ExpenseLineDiscountMode.percent) {
      final normalizedPercent = rawPercent.clamp(0.0, 100.0);
      final amount = base <= 0 ? 0.0 : (base * normalizedPercent) / 100;
      if (rawPercent != normalizedPercent) {
        percentController.text =
            normalizedPercent <= 0 ? '' : _formatEditableNumber(normalizedPercent);
      }
      amountController.text = amount <= 0 ? '' : _formatEditableNumber(amount);
    } else {
      final normalizedAmount = rawAmount.clamp(0.0, base);
      final percent =
          base <= 0 ? 0.0 : ((normalizedAmount / base) * 100).clamp(0.0, 100.0);
      if (rawAmount != normalizedAmount) {
        amountController.text =
            normalizedAmount <= 0 ? '' : _formatEditableNumber(normalizedAmount);
      }
      percentController.text = percent <= 0 ? '' : _formatEditableNumber(percent);
    }
    _syncingControllers = false;
  }

  ExpenseWithholdingPreview buildPreview({
    required double taxableBase,
    required double grossTotal,
  }) {
    final base = taxableBase < 0 ? 0.0 : taxableBase;
    final gross = grossTotal < 0 ? 0.0 : grossTotal;
    if (!enabled) {
      return ExpenseWithholdingPreview(
        type: ExpenseWithholdingType.none,
        percent: 0,
        amount: 0,
        taxableBase: base,
        grossTotal: gross,
        payableTotal: gross,
      );
    }
    final amount = _mode == ExpenseLineDiscountMode.percent
        ? (base * rawPercent.clamp(0.0, 100.0)) / 100
        : rawAmount.clamp(0.0, base);
    final percent = base <= 0
        ? 0.0
        : ((amount / base) * 100).clamp(0.0, 100.0);
    final payableTotal = (gross - amount).clamp(0.0, double.infinity);
    return ExpenseWithholdingPreview(
      type: type,
      percent: percent.toDouble(),
      amount: amount.toDouble(),
      taxableBase: base,
      grossTotal: gross,
      payableTotal: payableTotal.toDouble(),
    );
  }

  void applyToExpensePayload(
    Map<String, dynamic> expense, {
    required double taxableBase,
    required double grossTotal,
  }) {
    expense.remove('withholding');
    if (!enabled) return;
    final preview = buildPreview(
      taxableBase: taxableBase,
      grossTotal: grossTotal,
    );
    expense['withholding'] = <String, dynamic>{
      'type': type.apiValue,
      'percent': double.parse(preview.percent.toStringAsFixed(2)),
      'amount': double.parse(preview.amount.toStringAsFixed(2)),
    };
  }

  String? validate({
    required double taxableBase,
    required double grossTotal,
  }) {
    if (!enabled) return null;
    if (rawAmount < 0) {
      return 'La retencion no puede ser negativa.';
    }
    if (rawPercent < 0 || rawPercent > 100) {
      return 'La retencion % debe estar entre 0 y 100.';
    }
    if (taxableBase > 0 && rawAmount > taxableBase + 0.0001) {
      return 'La retencion no puede superar la base imponible.';
    }
    final preview = buildPreview(
      taxableBase: taxableBase,
      grossTotal: grossTotal,
    );
    if (preview.amount > grossTotal + 0.0001) {
      return 'La retencion no puede superar el total bruto.';
    }
    return null;
  }

  void clear() {
    type = ExpenseWithholdingType.none;
    amountController.clear();
    percentController.clear();
    _mode = ExpenseLineDiscountMode.percent;
  }

  void dispose() {
    amountController.dispose();
    percentController.dispose();
  }
}

class ExpenseLineDraft {
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController quantityController =
      TextEditingController(text: '1');
  final TextEditingController baseUnitPriceController = TextEditingController();
  final TextEditingController discountAmountController =
      TextEditingController();
  final TextEditingController discountPercentController =
      TextEditingController();
  final TextEditingController taxRateController =
      TextEditingController(text: '21');

  ExpenseLineDiscountMode _discountMode = ExpenseLineDiscountMode.percent;
  bool _syncingDiscountControllers = false;

  ExpenseLineDraft();

  factory ExpenseLineDraft.fromMap(Map<String, dynamic> map) {
    final draft = ExpenseLineDraft();
    draft.descriptionController.text =
        (map['description'] ?? map['conceptTitle'] ?? map['title'] ?? '')
            .toString()
            .trim();
    final quantity =
        parseFlexibleMoney(map['quantity'] ?? map['qty'] ?? 1) ?? 1;
    final baseUnitPrice = parseFlexibleMoney(
          map['baseUnitPrice'] ?? map['unitPrice'] ?? map['price'] ?? 0,
        ) ??
        0;
    final discountAmount =
        parseFlexibleMoney(map['discountAmount'] ?? map['discount_amount']) ??
            0;
    final discountPercent =
        parseFlexibleMoney(map['discountPercent'] ?? map['discount_percent']) ??
            0;
    final explicitTaxRate = parseFlexibleMoney(
      map['taxRate'] ?? map['vatRate'] ?? map['tax_rate'],
    );
    final storedLineSubtotal = parseFlexibleMoney(map['lineSubtotal']);
    final storedLineTax = parseFlexibleMoney(map['lineTax']);
    final derivedTaxRate = (storedLineSubtotal != null &&
            storedLineTax != null &&
            storedLineSubtotal.abs() > 0.0001)
        ? (storedLineTax / storedLineSubtotal) * 100
        : null;
    final taxRate = explicitTaxRate ?? derivedTaxRate ?? 21;

    draft.quantityController.text = draft._formatEditableNumber(quantity);
    draft.baseUnitPriceController.text =
        draft._formatEditableNumber(baseUnitPrice);
    draft.taxRateController.text = draft._formatEditableNumber(taxRate);

    if (discountPercent > 0 && discountAmount <= 0) {
      draft._discountMode = ExpenseLineDiscountMode.percent;
      draft.discountPercentController.text =
          draft._formatEditableNumber(discountPercent);
    } else if (discountAmount > 0) {
      draft._discountMode = ExpenseLineDiscountMode.amount;
      draft.discountAmountController.text =
          draft._formatEditableNumber(discountAmount);
    }

    draft.syncDerivedDiscountFields();
    return draft;
  }

  double _parseNum(String raw) {
    return parseFlexibleMoney(raw) ?? 0;
  }

  String _formatEditableNumber(num value) {
    final fixed = value.toDouble().toStringAsFixed(2);
    if (fixed.endsWith('.00')) return fixed.substring(0, fixed.length - 3);
    if (fixed.endsWith('0')) return fixed.substring(0, fixed.length - 1);
    return fixed;
  }

  double get quantity => _parseNum(quantityController.text);
  double get baseUnitPrice => _parseNum(baseUnitPriceController.text);
  double get taxRate => _parseNum(taxRateController.text);
  double get rawDiscountAmount => _parseNum(discountAmountController.text);
  double get rawDiscountPercent => _parseNum(discountPercentController.text);

  double get grossSubtotal => quantity * baseUnitPrice;

  double get discountAmount {
    final gross = grossSubtotal;
    if (gross <= 0) return 0;
    if (_discountMode == ExpenseLineDiscountMode.percent) {
      return (gross * rawDiscountPercent.clamp(0, 100)) / 100;
    }
    return rawDiscountAmount.clamp(0, gross);
  }

  double get discountPercent {
    final gross = grossSubtotal;
    if (gross <= 0) return 0;
    if (_discountMode == ExpenseLineDiscountMode.percent) {
      return rawDiscountPercent.clamp(0, 100);
    }
    return ((discountAmount / gross) * 100).clamp(0, 100);
  }

  double get subtotal {
    final value = grossSubtotal - discountAmount;
    return value < 0 ? 0 : value;
  }

  double get unitPrice => quantity <= 0 ? 0 : subtotal / quantity;
  double get taxAmount => subtotal * (taxRate / 100);
  double get total => subtotal + taxAmount;

  bool get hasDiscount => discountAmount > 0.0001 || discountPercent > 0.0001;

  void onDiscountAmountChanged() {
    _discountMode = ExpenseLineDiscountMode.amount;
    syncDerivedDiscountFields();
  }

  void onDiscountPercentChanged() {
    _discountMode = ExpenseLineDiscountMode.percent;
    syncDerivedDiscountFields();
  }

  void onPricingChanged() {
    syncDerivedDiscountFields();
  }

  void syncDerivedDiscountFields() {
    if (_syncingDiscountControllers) return;
    _syncingDiscountControllers = true;
    final gross = grossSubtotal;
    if (_discountMode == ExpenseLineDiscountMode.percent) {
      final normalizedPercent = rawDiscountPercent.clamp(0.0, 100.0);
      final amount = gross <= 0 ? 0.0 : (gross * normalizedPercent) / 100;
      if (rawDiscountPercent != normalizedPercent) {
        discountPercentController.text =
            _formatEditableNumber(normalizedPercent);
      }
      discountAmountController.text =
          amount <= 0 ? '' : _formatEditableNumber(amount);
    } else {
      final normalizedAmount = rawDiscountAmount.clamp(0.0, gross);
      final percent =
          gross <= 0 ? 0.0 : ((normalizedAmount / gross) * 100).clamp(0.0, 100.0);
      if (rawDiscountAmount != normalizedAmount) {
        discountAmountController.text =
            normalizedAmount <= 0 ? '' : _formatEditableNumber(normalizedAmount);
      }
      discountPercentController.text =
          percent <= 0 ? '' : _formatEditableNumber(percent);
    }
    _syncingDiscountControllers = false;
  }

  Map<String, dynamic> toJson() {
    return {
      'description': descriptionController.text.trim(),
      'quantity': quantity,
      'baseUnitPrice': baseUnitPrice,
      'discountAmount': discountAmount,
      'discountPercent': discountPercent,
      'taxRate': taxRate,
      'lineSubtotal': subtotal,
      'lineTax': taxAmount,
      'lineTotal': total,
    };
  }

  void dispose() {
    descriptionController.dispose();
    quantityController.dispose();
    baseUnitPriceController.dispose();
    discountAmountController.dispose();
    discountPercentController.dispose();
    taxRateController.dispose();
  }
}
