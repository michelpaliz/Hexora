import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/a-models/invoice/invoice_concept_utils.dart';
import 'package:hexora/a-models/invoice/invoice_line.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class LineDraft {
  int position;
  String? id;
  String? evidenceBlobName;
  String? sku;
  List<String>? conceptItems;
  String? conceptTitle;
  String? serviceDate;
  bool? isCompositeConcept;
  String? parseMethod;
  late final TextEditingController conceptTitleCtrl;
  late final TextEditingController conceptItemsCtrl;
  late final TextEditingController serviceDateCtrl;
  final TextEditingController description = TextEditingController();
  final TextEditingController quantityCtrl = TextEditingController(text: '1');
  final TextEditingController unitPriceCtrl = TextEditingController();
  final TextEditingController discountRateCtrl =
      TextEditingController(text: '0');
  final TextEditingController taxRateCtrl = TextEditingController(text: '21');
  final FocusNode quantityFocus = FocusNode();
  final FocusNode unitPriceFocus = FocusNode();

  LineDraft({
    required this.position,
    this.id,
    this.evidenceBlobName,
    this.sku,
    this.conceptItems,
    this.conceptTitle,
    this.serviceDate,
    this.isCompositeConcept,
    this.parseMethod,
  }) {
    conceptTitleCtrl = TextEditingController(text: conceptTitle ?? sku ?? '');
    conceptItemsCtrl = TextEditingController(
      text: conceptItems == null || conceptItems!.length <= 1
          ? conceptItems?.join(', ') ?? ''
          : conceptItems!.join('\n'),
    );
    serviceDateCtrl = TextEditingController(text: serviceDate ?? '');
  }

  String _norm(String v) => v.trim().replaceAll(',', '.');

  InvoiceLine toLine() {
    final qty = num.tryParse(_norm(quantityCtrl.text)) ?? 1;
    final price = num.tryParse(_norm(unitPriceCtrl.text)) ?? 0;
    final discount =
        (num.tryParse(_norm(discountRateCtrl.text)) ?? 0).clamp(0, 100);
    final tax = num.tryParse(_norm(taxRateCtrl.text)) ?? 21;
    final items = _conceptItemsFromText(conceptItemsCtrl.text);
    final title = conceptTitleCtrl.text.trim();
    final detail = description.text.trim();
    final legacyDescription = detail.isNotEmpty
        ? detail
        : (items?.isNotEmpty ?? false)
            ? items!.first
            : title;
    return InvoiceLine(
      id: '',
      invoiceId: '',
      position: position,
      description: legacyDescription,
      quantity: qty,
      unitPrice: price,
      discountRate: discount,
      taxRate: tax,
      sku: title.isEmpty ? sku : title,
      conceptItems: items,
      conceptTitle: title.isEmpty ? conceptTitle : title,
      serviceDate: serviceDateCtrl.text.trim().isEmpty
          ? serviceDate
          : serviceDateCtrl.text.trim(),
      isCompositeConcept:
          isCompositeConcept ?? ((items?.length ?? 0) > 1 ? true : null),
      parseMethod: parseMethod,
    );
  }

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
    sku = title.isEmpty ? null : title;
    conceptItems = _conceptItemsFromText(conceptItemsCtrl.text);
    final date = serviceDateCtrl.text.trim();
    serviceDate = date.isEmpty ? null : date;
    isCompositeConcept = (conceptItems?.length ?? 0) > 1 ? true : null;
  }

  num? get quantity => num.tryParse(_norm(quantityCtrl.text));
  num? get unitPrice => num.tryParse(_norm(unitPriceCtrl.text));
  num? get discountRate =>
      (num.tryParse(_norm(discountRateCtrl.text)) ?? 0).clamp(0, 100);
  num? get taxRate => num.tryParse(_norm(taxRateCtrl.text));

  void dispose() {
    description.dispose();
    conceptTitleCtrl.dispose();
    conceptItemsCtrl.dispose();
    serviceDateCtrl.dispose();
    quantityCtrl.dispose();
    unitPriceCtrl.dispose();
    discountRateCtrl.dispose();
    taxRateCtrl.dispose();
    quantityFocus.dispose();
    unitPriceFocus.dispose();
  }
}

class InvoiceLinesEditor extends StatefulWidget {
  final List<LineDraft> lines;
  final VoidCallback onChanged;
  final bool compactable;
  final bool initiallyCollapsed;
  final bool showTax;

  const InvoiceLinesEditor({
    super.key,
    required this.lines,
    required this.onChanged,
    this.compactable = false,
    this.initiallyCollapsed = false,
    this.showTax = true,
  });

  @override
  State<InvoiceLinesEditor> createState() => _InvoiceLinesEditorState();
}

class _InvoiceLinesEditorState extends State<InvoiceLinesEditor> {
  final Map<int, bool> _collapsedLines = {};
  final Set<LineDraft> _configuredLines = {};

  void _formatController(TextEditingController ctrl, {int decimals = 2}) {
    final raw = ctrl.text.trim();
    if (raw.isEmpty) return;
    final parsed = double.tryParse(raw.replaceAll(',', '.'));
    if (parsed == null) return;
    final formatted = parsed.toStringAsFixed(decimals);
    if (formatted == ctrl.text) return;
    ctrl.text = formatted;
    ctrl.selection = TextSelection.collapsed(offset: formatted.length);
    widget.onChanged();
  }

  void _ensureLineHandlers(LineDraft line) {
    if (_configuredLines.contains(line)) return;
    _configuredLines.add(line);
    line.quantityFocus.addListener(() {
      if (!line.quantityFocus.hasFocus) {
        _formatController(line.quantityCtrl);
      }
    });
    line.unitPriceFocus.addListener(() {
      if (!line.unitPriceFocus.hasFocus) {
        _formatController(line.unitPriceCtrl);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.initiallyCollapsed) {
      for (final line in widget.lines) {
        _collapsedLines[line.position] = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
    );
    final labelStyle = t.bodyMedium.copyWith(fontWeight: FontWeight.w700);
    final priceLabelStyle =
        labelStyle.copyWith(color: cs.primary, fontWeight: FontWeight.w800);
    final priceFill = cs.primaryContainer.withValues(alpha: 0.18);
    final currencySymbol = NumberFormat.simpleCurrency().currencySymbol;
    final currencyFormatter = NumberFormat.simpleCurrency(name: '');
    final isEs = l.localeName.toLowerCase().startsWith('es');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l.invoiceLinesTitle,
              style: t.bodyLarge.copyWith(fontWeight: FontWeight.w800),
            ),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    final nextPos = widget.lines.length + 1;
                    widget.lines.add(LineDraft(position: nextPos));
                    if (widget.initiallyCollapsed) {
                      _collapsedLines[nextPos] = true;
                    }
                    widget.onChanged();
                    setState(() {});
                  },
                  icon: const Icon(Icons.add),
                  label: Text(l.invoiceAddLine, style: t.bodyMedium),
                ),
              ],
            ),
          ],
        ),
        if (widget.lines.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              l.invoiceLinesRequired,
              style: t.bodyMedium.copyWith(color: cs.error),
            ),
          ),
        ...widget.lines.map((line) {
          _ensureLineHandlers(line);
          final idx = widget.lines.indexOf(line);
          final isCollapsed =
              widget.compactable && (_collapsedLines[line.position] ?? false);
          final qty = line.quantity ?? 1;
          final unit = line.unitPrice ?? 0;
          final discountRate = line.discountRate ?? 0;
          final vat = line.taxRate ?? 21;
          final grossBase = qty * unit;
          final subtotal = grossBase - (grossBase * discountRate / 100);
          final total =
              widget.showTax ? subtotal + (subtotal * (vat / 100)) : subtotal;
          return Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '#${line.position}',
                      style: t.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.primary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        currencyFormatter.format(total),
                        style: t.bodySmall.copyWith(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (widget.compactable)
                      IconButton(
                        tooltip: isCollapsed
                            ? MaterialLocalizations.of(context)
                                .collapsedIconTapHint
                            : MaterialLocalizations.of(context)
                                .expandedIconTapHint,
                        onPressed: () {
                          setState(() {
                            _collapsedLines[line.position] = !isCollapsed;
                          });
                        },
                        icon: Icon(
                          isCollapsed
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_up,
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: cs.error,
                      tooltip: l.remove,
                      onPressed: () {
                        widget.lines.removeAt(idx);
                        _collapsedLines.remove(line.position);
                        for (int i = 0; i < widget.lines.length; i++) {
                          widget.lines[i].position = i + 1;
                        }
                        widget.onChanged();
                        setState(() {});
                      },
                    ),
                  ],
                ),
                if (!isCollapsed) ...[
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 760;
                      final compactWidth = wide ? 130.0 : double.infinity;
                      final titleText = line.conceptTitleCtrl.text.trim();
                      final titleLooksLikeUnit =
                          titleText.isEmpty || isInvoiceUnitCode(titleText);
                      final conceptItemCount = line.conceptItemsCtrl.text
                          .split(RegExp(r'[,;\n]'))
                          .map((item) => item.trim())
                          .where((item) => item.isNotEmpty)
                          .length;
                      final isComposite = conceptItemCount > 1 ||
                          line.conceptItemsCtrl.text.contains('\n');

                      final descriptionField = TextFormField(
                        controller: line.description,
                        style: t.bodyMedium,
                        decoration: InputDecoration(
                          labelText: isEs ? 'Detalle' : 'Detail',
                          labelStyle: labelStyle,
                          enabledBorder: inputBorder,
                          focusedBorder: inputBorder.copyWith(
                            borderSide:
                                BorderSide(color: cs.primary, width: 1.5),
                          ),
                        ),
                        onChanged: (_) => widget.onChanged(),
                        validator: (v) {
                          final hasDetail = v?.trim().isNotEmpty == true;
                          final hasConcept =
                              line.conceptTitleCtrl.text.trim().isNotEmpty ||
                                  line.conceptItemsCtrl.text.trim().isNotEmpty;
                          return hasDetail || hasConcept
                              ? null
                              : l.fieldIsRequired;
                        },
                      );

                      final unitCodeField = TextFormField(
                        controller: line.conceptTitleCtrl,
                        style: t.bodyMedium,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: titleLooksLikeUnit
                              ? (isEs ? 'Vivienda / unidad' : 'Unit code')
                              : (isEs ? 'Título' : 'Title'),
                          hintText: titleLooksLikeUnit ? 'B30' : 'Materiales',
                          labelStyle: labelStyle,
                          enabledBorder: inputBorder,
                          focusedBorder: inputBorder.copyWith(
                            borderSide:
                                BorderSide(color: cs.primary, width: 1.5),
                          ),
                        ),
                        onChanged: (_) {
                          line.syncConceptMetadata();
                          widget.onChanged();
                        },
                      );

                      final conceptItemsField = TextFormField(
                        controller: line.conceptItemsCtrl,
                        style: t.bodyMedium,
                        decoration: InputDecoration(
                          labelText: isComposite
                              ? (isEs
                                  ? 'Conceptos, uno por línea'
                                  : 'Concepts, one per line')
                              : (isEs ? 'Concepto de trabajo' : 'Work concept'),
                          hintText: isEs
                              ? 'Sustitución de ruedas de mampara'
                              : 'Shower screen wheel replacement',
                          labelStyle: labelStyle,
                          enabledBorder: inputBorder,
                          focusedBorder: inputBorder.copyWith(
                            borderSide:
                                BorderSide(color: cs.primary, width: 1.5),
                          ),
                        ),
                        minLines: isComposite ? 3 : 1,
                        maxLines: isComposite ? 5 : 1,
                        onChanged: (_) {
                          line.syncConceptMetadata();
                          widget.onChanged();
                        },
                      );

                      final serviceDateField = TextFormField(
                        controller: line.serviceDateCtrl,
                        style: t.bodyMedium,
                        decoration: InputDecoration(
                          labelText: isEs ? 'Fecha servicio' : 'Service date',
                          hintText: 'YYYY-MM-DD',
                          labelStyle: labelStyle,
                          prefixIcon: const Icon(Icons.calendar_today_outlined,
                              size: 16),
                          enabledBorder: inputBorder,
                          focusedBorder: inputBorder.copyWith(
                            borderSide:
                                BorderSide(color: cs.primary, width: 1.5),
                          ),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9-]'),
                          ),
                          LengthLimitingTextInputFormatter(10),
                        ],
                        onChanged: (_) {
                          line.syncConceptMetadata();
                          widget.onChanged();
                        },
                      );

                      final quantityField = TextFormField(
                        controller: line.quantityCtrl,
                        focusNode: line.quantityFocus,
                        style: t.bodyMedium,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          labelText: l.lineQuantity,
                          labelStyle: labelStyle,
                          enabledBorder: inputBorder,
                          focusedBorder: inputBorder.copyWith(
                            borderSide:
                                BorderSide(color: cs.primary, width: 1.5),
                          ),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                        ],
                        onChanged: (_) => widget.onChanged(),
                      );

                      final unitPriceField = TextFormField(
                        controller: line.unitPriceCtrl,
                        focusNode: line.unitPriceFocus,
                        style: t.bodyMedium,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          labelText: l.lineUnitPrice,
                          labelStyle: priceLabelStyle,
                          filled: true,
                          fillColor: priceFill,
                          suffixText: currencySymbol,
                          enabledBorder: inputBorder,
                          focusedBorder: inputBorder.copyWith(
                            borderSide:
                                BorderSide(color: cs.primary, width: 1.5),
                          ),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                        ],
                        onChanged: (_) => widget.onChanged(),
                      );

                      final taxField = TextFormField(
                        controller: line.taxRateCtrl,
                        style: t.bodyMedium,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          labelText: l.lineTaxRate,
                          labelStyle: labelStyle,
                          suffixText: '%',
                          enabledBorder: inputBorder,
                          focusedBorder: inputBorder.copyWith(
                            borderSide:
                                BorderSide(color: cs.primary, width: 1.5),
                          ),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                        ],
                        onChanged: (_) => widget.onChanged(),
                      );
                      final discountField = TextFormField(
                        controller: line.discountRateCtrl,
                        style: t.bodyMedium,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Dto. %',
                          labelStyle: labelStyle,
                          suffixText: '%',
                          enabledBorder: inputBorder,
                          focusedBorder: inputBorder.copyWith(
                            borderSide:
                                BorderSide(color: cs.primary, width: 1.5),
                          ),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                        ],
                        onChanged: (_) => widget.onChanged(),
                      );

                      if (!wide) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(child: unitCodeField),
                                const SizedBox(width: 10),
                                Expanded(child: serviceDateField),
                              ],
                            ),
                            const SizedBox(height: 10),
                            conceptItemsField,
                            const SizedBox(height: 10),
                            descriptionField,
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(child: quantityField),
                                const SizedBox(width: 10),
                                Expanded(child: unitPriceField),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(child: discountField),
                                if (widget.showTax) ...[
                                  const SizedBox(width: 10),
                                  Expanded(child: taxField),
                                ],
                              ],
                            ),
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 120, child: unitCodeField),
                          const SizedBox(width: 12),
                          Expanded(flex: 2, child: conceptItemsField),
                          const SizedBox(width: 12),
                          SizedBox(width: 150, child: serviceDateField),
                          const SizedBox(width: 12),
                          Expanded(flex: 2, child: descriptionField),
                          const SizedBox(width: 12),
                          SizedBox(width: compactWidth, child: quantityField),
                          const SizedBox(width: 12),
                          SizedBox(width: compactWidth, child: unitPriceField),
                          const SizedBox(width: 12),
                          SizedBox(width: compactWidth, child: discountField),
                          if (widget.showTax) ...[
                            const SizedBox(width: 12),
                            SizedBox(width: compactWidth, child: taxField),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }
}
