import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/a-models/invoice/invoice_block.dart';
import 'package:hexora/a-models/invoice/invoice_concept_utils.dart';
import 'package:hexora/b-backend/invoicing/models/manual_editor_capabilities.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_form_sheet/invoice_blocks_editor.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/utils/money_format_utils.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class BlockCard extends StatefulWidget {
  final int index;
  final int total;
  final InvoiceBlockDraft block;
  final bool selected;
  final List<ManualEditorBlockTypeCapability> availableBlockTypes;
  final VoidCallback onSelect;
  final VoidCallback onDelete;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onChanged;
  final VoidCallback onAddChecklistItem;
  final ValueChanged<int> onRemoveChecklistItem;

  const BlockCard({
    super.key,
    required this.index,
    required this.total,
    required this.block,
    required this.selected,
    required this.availableBlockTypes,
    required this.onSelect,
    required this.onDelete,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onChanged,
    required this.onAddChecklistItem,
    required this.onRemoveChecklistItem,
  });

  @override
  State<BlockCard> createState() => BlockCardState();
}

class BlockCardState extends State<BlockCard> {
  bool _hovered = false;
  bool _expanded = false;
  static const _unitOptions = <String>[
    'ud',
    'h',
    'trabj',
    'kg',
    'm',
    'm2',
    'm3',
    'l',
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final block = widget.block;
    final numFmt = NumberFormat('#,##0.##');
    final moneyFmt = NumberFormat.simpleCurrency(name: '');

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
    );

    // Compact label style for all fieldDec decorations.
    const labelStyle = TextStyle(fontSize: 11);

    InputDecoration fieldDec({required String label, String? suffixText}) {
      return InputDecoration(
        labelText: label,
        suffixText: suffixText,
        labelStyle: labelStyle.copyWith(color: cs.onSurfaceVariant),
        floatingLabelStyle: labelStyle.copyWith(
          color: cs.onSurfaceVariant,
          fontSize: 10,
        ),
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      );
    }

    final currentLang = Localizations.localeOf(context).languageCode;

    // Returns a server-localized label if available, otherwise falls back to
    // the local l10n string, then the raw type id.
    String typeLabel(String type) {
      final serverLabel = widget.availableBlockTypes
          .where((t) => t.id == type)
          .map((t) => t.label.resolve(currentLang))
          .firstWhere((s) => s.isNotEmpty, orElse: () => '');
      if (serverLabel.isNotEmpty) return serverLabel;
      switch (type) {
        case InvoiceBlockType.item:
          return l.invoiceBlockTypeItem;
        case InvoiceBlockType.date:
          return l.invoiceBlockTypeDate;
        case InvoiceBlockType.section:
          return l.invoiceBlockTypeSection;
        case InvoiceBlockType.subsection:
          return l.invoiceBlockTypeSubsection;
        case InvoiceBlockType.divider:
          return l.invoiceBlockTypeDivider;
        case InvoiceBlockType.note:
          return l.invoiceBlockTypeNote;
        case InvoiceBlockType.checklist:
          return l.invoiceBlockTypeChecklist;
        case InvoiceBlockType.worker:
          return currentLang.startsWith('es') ? 'Trabajador' : 'Worker';
      }
      return type;
    }

    IconData typeIcon(String type) {
      switch (type) {
        case InvoiceBlockType.item:
          return Icons.receipt_long_outlined;
        case InvoiceBlockType.date:
          return Icons.event_outlined;
        case InvoiceBlockType.section:
          return Icons.segment_outlined;
        case InvoiceBlockType.subsection:
          return Icons.subdirectory_arrow_right_outlined;
        case InvoiceBlockType.divider:
          return Icons.horizontal_rule;
        case InvoiceBlockType.note:
          return Icons.sticky_note_2_outlined;
        case InvoiceBlockType.checklist:
          return Icons.checklist_outlined;
        case InvoiceBlockType.worker:
          return Icons.engineering_outlined;
      }
      return Icons.more_horiz;
    }

    String? nonNegativeValidator(String? v) {
      final parsed = parseFlexibleMoney(v);
      if (parsed == null) return l.fieldIsRequired;
      if (parsed < 0) return l.invoiceValidationNonNegative;
      return null;
    }

    String? taxValidator(String? v) {
      final parsed = parseFlexibleMoney(v);
      if (parsed == null) return l.fieldIsRequired;
      if (parsed < 0 || parsed > 100) return l.invoiceValidationTaxRate;
      return null;
    }

    String? discountValidator(String? v) {
      final parsed = parseFlexibleMoney(v);
      if (parsed == null) return l.fieldIsRequired;
      if (parsed < 0 || parsed > 100) return l.invoiceValidationTaxRate;
      return null;
    }

    Widget typePicker() {
      // Use whatever the server returned — no hardcoded list.
      final types = widget.availableBlockTypes.isNotEmpty
          ? widget.availableBlockTypes
          : const <ManualEditorBlockTypeCapability>[];

      return Tooltip(
        message: typeLabel(block.type),
        child: PopupMenuButton<String>(
          tooltip: '',
          onSelected: (value) {
            setState(() {
              block.type = value;
              _expanded = true;
            });
            widget.onSelect();
            widget.onChanged();
          },
          itemBuilder: (_) => types
              .map((t) => PopupMenuItem<String>(
                    value: t.id,
                    child: Row(
                      children: [
                        Icon(typeIcon(t.id),
                            size: 16,
                            color: t.id == block.type
                                ? cs.primary
                                : cs.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Text(typeLabel(t.id)),
                      ],
                    ),
                  ))
              .toList(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(typeIcon(block.type), size: 16, color: cs.primary),
                const SizedBox(width: 3),
                Icon(Icons.expand_more, size: 14, color: cs.onSurfaceVariant),
              ],
            ),
          ),
        ),
      );
    }

    String summaryText() {
      switch (block.type) {
        case InvoiceBlockType.item:
          final rawSku = block.conceptTitleCtrl.text.trim();
          final sku = isInvoiceUnitCode(rawSku) ? '' : rawSku;
          final concept = block.conceptItemsCtrl.text
              .split(RegExp(r'[,;\n]'))
              .map((item) => item.trim())
              .firstWhere((item) => item.isNotEmpty, orElse: () => '');
          final desc = block.description.text.trim();
          final label = concept.isNotEmpty
              ? concept
              : desc.isEmpty
                  ? l.lineDescription
                  : desc;
          return sku.isEmpty ? label : '$sku · $label';
        case InvoiceBlockType.date:
        case InvoiceBlockType.section:
        case InvoiceBlockType.subsection:
          return block.title.text.trim().isEmpty
              ? typeLabel(block.type)
              : block.title.text.trim();
        case InvoiceBlockType.note:
          return block.text.text.trim().isEmpty
              ? typeLabel(block.type)
              : block.text.text.trim();
        case InvoiceBlockType.checklist:
          final title = block.title.text.trim();
          if (title.isNotEmpty) return title;
          if (block.checklistItems.isEmpty) return typeLabel(block.type);
          final first = block.checklistItems.first.text.text.trim();
          return first.isEmpty ? typeLabel(block.type) : first;
        case InvoiceBlockType.divider:
          return typeLabel(block.type);
      }
      return typeLabel(block.type);
    }

    String? itemMeta() {
      if (!block.isBillableLine) return null;
      final qty = block.qty ?? 1;
      final price = block.unitPrice ?? 0;
      final discountRate = block.discountRate ?? 0;
      final unit = block.unitCtrl.text.trim();
      final qtyText =
          unit.isEmpty ? numFmt.format(qty) : '${numFmt.format(qty)} $unit';
      final discountText =
          discountRate > 0 ? ' · Dto. ${numFmt.format(discountRate)}%' : '';
      return '$qtyText × ${moneyFmt.format(price)}$discountText';
    }

    String? itemTotalText() {
      if (!block.isBillableLine) return null;
      final qty = block.qty ?? 1;
      final price = block.unitPrice ?? 0;
      final discountRate = block.discountRate ?? 0;
      final taxRate = block.taxRate ?? 21;
      final grossBase = qty * price;
      final base = grossBase - (grossBase * discountRate / 100);
      final tax = base * (taxRate / 100);
      final total = base + tax;
      return moneyFmt.format(total);
    }

    bool shouldShowLevel() {
      return block.levelCtrl.text.trim().isNotEmpty;
    }

    Widget itemFields({String? descriptionLabel}) {
      // ── Compact unit-dropdown suffix ──────────────────────────────────────
      Widget unitField() => TextFormField(
            controller: block.unitCtrl,
            decoration: fieldDec(label: l.invoiceBlockUnitLabel).copyWith(
              suffixIcon: PopupMenuButton<String>(
                tooltip: l.invoiceBlockUnitLabel,
                icon: const Icon(Icons.arrow_drop_down, size: 18),
                onSelected: (value) {
                  block.unitCtrl.text = value;
                  block.unitCtrl.selection =
                      TextSelection.collapsed(offset: value.length);
                  widget.onChanged();
                },
                itemBuilder: (_) => [
                  for (final unit in _unitOptions)
                    PopupMenuItem<String>(
                      value: unit,
                      child: Text(unit),
                    ),
                ],
              ),
            ),
            onChanged: (_) => widget.onChanged(),
          );

      final isEs = currentLang.startsWith('es');

      Widget conceptMetadataFields() => LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 760;
              final titleText = block.conceptTitleCtrl.text.trim();
              final titleLooksLikeUnit =
                  titleText.isEmpty || isInvoiceUnitCode(titleText);
              final conceptItemCount = block.conceptItemsCtrl.text
                  .split(RegExp(r'[,;\n]'))
                  .map((item) => item.trim())
                  .where((item) => item.isNotEmpty)
                  .length;
              final isComposite = conceptItemCount > 1 ||
                  block.conceptItemsCtrl.text.contains('\n');
              final unitCodeField = TextFormField(
                controller: block.conceptTitleCtrl,
                decoration: fieldDec(
                  label: titleLooksLikeUnit
                      ? (isEs ? 'Vivienda / unidad' : 'Unit code')
                      : (isEs ? 'Título' : 'Title'),
                ).copyWith(hintText: titleLooksLikeUnit ? 'B30' : 'Materiales'),
                textCapitalization: TextCapitalization.characters,
                onChanged: (_) {
                  block.syncConceptMetadata();
                  widget.onChanged();
                },
              );
              final conceptField = TextFormField(
                controller: block.conceptItemsCtrl,
                decoration: fieldDec(
                  label: isComposite
                      ? (isEs
                          ? 'Conceptos, uno por línea'
                          : 'Concepts, one per line')
                      : (isEs ? 'Concepto de trabajo' : 'Work concept'),
                ).copyWith(
                  hintText: isEs
                      ? 'Sustitución de ruedas de mampara'
                      : 'Shower screen wheel replacement',
                ),
                minLines: isComposite ? 3 : 1,
                maxLines: isComposite ? 5 : 1,
                onChanged: (_) {
                  block.syncConceptMetadata();
                  widget.onChanged();
                },
              );

              Future<void> pickServiceDate() async {
                final now = DateTime.now();
                final current = cleanInvoiceServiceDate(
                  block.serviceDateCtrl.text,
                );
                final selected = await showDatePicker(
                  context: context,
                  initialDate: DateTime.tryParse(current ?? '') ?? now,
                  firstDate: DateTime(now.year - 10),
                  lastDate: DateTime(now.year + 5),
                );
                if (selected == null) return;

                block.serviceDateCtrl.text =
                    DateFormat('yyyy-MM-dd').format(selected);
                block.syncConceptMetadata();
                widget.onChanged();
                if (mounted) setState(() {});
              }

              final serviceDateField = TextFormField(
                controller: block.serviceDateCtrl,
                decoration: fieldDec(
                  label: isEs ? 'Fecha servicio' : 'Service date',
                ).copyWith(
                  hintText: 'YYYY-MM-DD',
                  prefixIcon: IconButton(
                    tooltip: isEs ? 'Seleccionar fecha' : 'Select date',
                    onPressed: pickServiceDate,
                    icon: const Icon(
                      Icons.calendar_today_outlined,
                      size: 15,
                    ),
                  ),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9/-]')),
                  LengthLimitingTextInputFormatter(10),
                ],
                onChanged: (_) {
                  block.syncConceptMetadata();
                  widget.onChanged();
                },
              );
              if (!wide) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: unitCodeField),
                        const SizedBox(width: 8),
                        Expanded(child: serviceDateField),
                      ],
                    ),
                    const SizedBox(height: 8),
                    conceptField,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 130, child: unitCodeField),
                  const SizedBox(width: 8),
                  Expanded(child: conceptField),
                  const SizedBox(width: 8),
                  SizedBox(width: 160, child: serviceDateField),
                ],
              );
            },
          );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          conceptMetadataFields(),
          const SizedBox(height: 8),
          // ── Row 1: Description — clean, full-width ────────────────────────

          // ── Row 2: Qty · Unit · Price · Tax% — balanced widths ───────────
          // flex 1:2:3:1 → Qty≈14% | Unit≈29% | Price≈43% | Tax≈14%
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: TextFormField(
                  controller: block.description,
                  decoration: fieldDec(
                    label: descriptionLabel ?? (isEs ? 'Detalle' : 'Detail'),
                  ).copyWith(
                    hintText: isEs
                        ? 'Corrección de deslizamiento y ajuste.'
                        : 'Alignment correction and adjustment.',
                  ),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (v) {
                    final hasDetail = v?.trim().isNotEmpty == true;
                    final hasConcept =
                        block.conceptTitleCtrl.text.trim().isNotEmpty ||
                            block.conceptItemsCtrl.text.trim().isNotEmpty;
                    return hasDetail || hasConcept ? null : l.fieldIsRequired;
                  },
                  onChanged: (_) => widget.onChanged(),
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 74,
                child: TextFormField(
                  controller: block.qtyCtrl,
                  decoration: fieldDec(label: l.lineQuantity),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: nonNegativeValidator,
                  onChanged: (_) => widget.onChanged(),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(width: 72, child: unitField()),
              const SizedBox(width: 6),
              SizedBox(
                width: 118,
                child: TextFormField(
                  controller: block.unitPriceCtrl,
                  decoration: fieldDec(label: l.lineUnitPrice),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: nonNegativeValidator,
                  onChanged: (_) => widget.onChanged(),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 70,
                child: TextFormField(
                  controller: block.discountRateCtrl,
                  decoration: fieldDec(label: 'Dto. %'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: discountValidator,
                  onChanged: (_) => widget.onChanged(),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 64,
                child: TextFormField(
                  controller: block.taxRateCtrl,
                  decoration: fieldDec(label: '${l.taxRateShort}%'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: taxValidator,
                  onChanged: (_) => widget.onChanged(),
                ),
              ),
            ],
          ),
        ],
      );
    }

    Widget workerFields() {
      return itemFields(
        descriptionLabel: currentLang.startsWith('es')
            ? 'Nombre / descripción del trabajador'
            : 'Worker name / description',
      );
    }

    Widget titleField({required String label}) {
      return TextFormField(
        controller: block.title,
        decoration: fieldDec(label: label),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? l.fieldIsRequired : null,
        onChanged: (_) => widget.onChanged(),
      );
    }

    Widget sectionFields() {
      block.qtyCtrl.text = '1';
      block.unitCtrl.text = '';
      block.taxRateCtrl.text = '0';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleField(label: l.invoiceBlockTitleLabelSection),
          const SizedBox(height: 12),
          Row(
            children: [
              Switch(
                value: block.isBillable,
                onChanged: (v) {
                  setState(() => block.isBillable = v);
                  widget.onChanged();
                },
              ),
              Text(
                l.invoiceBlockBillableLabel,
                style: t.bodySmall.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          if (block.isBillable) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 200,
                  child: TextFormField(
                    controller: block.unitPriceCtrl,
                    decoration: fieldDec(
                      label: currentLang.startsWith('es')
                          ? 'Precio del paquete'
                          : 'Package price',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: nonNegativeValidator,
                    onChanged: (_) => widget.onChanged(),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 90,
                  child: TextFormField(
                    controller: block.discountRateCtrl,
                    decoration: fieldDec(label: 'Dto. %'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: discountValidator,
                    onChanged: (_) => widget.onChanged(),
                  ),
                ),
              ],
            ),
          ],
        ],
      );
    }

    Widget dateField() {
      final locale = Localizations.localeOf(context);
      final isEnUs = locale.languageCode == 'en' && locale.countryCode == 'US';
      final pattern = isEnUs ? 'MM/dd/yyyy' : 'dd/MM/yyyy';
      final placeholder = pattern.toLowerCase();
      final formatter = DateFormat(pattern, locale.toString());

      Future<void> pickDate() async {
        final initial = block.dateValue == null
            ? DateTime.now()
            : DateTime.tryParse(block.dateValue!);
        final now = DateTime.now();
        final selected = await showDatePicker(
          context: context,
          initialDate: initial ?? now,
          firstDate: DateTime(now.year - 1),
          lastDate: DateTime(now.year + 5),
        );
        if (selected == null) return;
        final iso = DateFormat('yyyy-MM-dd').format(selected);
        block.dateValue = iso;
        if (block.title.text.trim().isEmpty) {
          block.title.text = formatter.format(selected);
        }
        widget.onChanged();
        setState(() {});
      }

      void applyAutoFormat() {
        if (block.dateValue == null || block.dateValue!.trim().isEmpty) {
          pickDate();
          return;
        }
        final parsed = DateTime.tryParse(block.dateValue!);
        if (parsed == null) return;
        block.title.text = formatter.format(parsed);
        widget.onChanged();
        setState(() {});
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: block.title,
            decoration: fieldDec(label: l.invoiceBlockTitleLabelDate)
                .copyWith(hintText: placeholder),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l.fieldIsRequired : null,
            onChanged: (_) => widget.onChanged(),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: pickDate,
                icon: const Icon(Icons.event_outlined),
                label: Text(l.invoiceBlocksQuickDate),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: applyAutoFormat,
                child: Text(l.invoiceBlockDateAutoFormatCta),
              ),
            ],
          ),
        ],
      );
    }

    Widget textField({required String label}) {
      return TextFormField(
        controller: block.text,
        decoration: fieldDec(label: label),
        maxLines: 3,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? l.fieldIsRequired : null,
        onChanged: (_) => widget.onChanged(),
      );
    }

    Widget levelField() {
      return SizedBox(
        width: 120,
        child: TextFormField(
          controller: block.levelCtrl,
          decoration: fieldDec(label: l.invoiceBlockLevelLabel),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
          ],
          onChanged: (_) => widget.onChanged(),
        ),
      );
    }

    Widget checklistFields() {
      if (block.qtyCtrl.text.trim().isEmpty) block.qtyCtrl.text = '1';
      if (block.unitCtrl.text.trim().isEmpty) block.unitCtrl.text = 'ud';
      if (block.taxRateCtrl.text.trim().isEmpty) block.taxRateCtrl.text = '21';

      Widget checklistUnitField() => TextFormField(
            controller: block.unitCtrl,
            decoration: fieldDec(label: l.invoiceBlockUnitLabel).copyWith(
              suffixIcon: PopupMenuButton<String>(
                tooltip: l.invoiceBlockUnitLabel,
                icon: const Icon(Icons.arrow_drop_down, size: 18),
                onSelected: (value) {
                  block.unitCtrl.text = value;
                  block.unitCtrl.selection =
                      TextSelection.collapsed(offset: value.length);
                  widget.onChanged();
                },
                itemBuilder: (_) => [
                  for (final unit in _unitOptions)
                    PopupMenuItem<String>(
                      value: unit,
                      child: Text(unit),
                    ),
                ],
              ),
            ),
            onChanged: (_) => widget.onChanged(),
          );

      Widget compactChecklistFields() {
        // Small inline + button that sits before the title field.
        Widget addBtn() => Tooltip(
              message: l.invoiceBlockAddChecklistItem,
              waitDuration: const Duration(milliseconds: 400),
              child: InkWell(
                onTap: widget.onAddChecklistItem,
                borderRadius: BorderRadius.circular(7),
                child: Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7),
                    color: cs.primaryContainer.withValues(alpha: 0.35),
                    border: Border.all(
                      color: cs.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Icon(Icons.add, size: 15, color: cs.primary),
                ),
              ),
            );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row: [+] [Título de lista] + billing fields if billable
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                addBtn(),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: titleField(
                    label: currentLang.startsWith('es')
                        ? 'Título de lista'
                        : 'List title',
                  ),
                ),
                if (block.isBillable) ...[
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 74,
                    child: TextFormField(
                      controller: block.qtyCtrl,
                      decoration: fieldDec(label: l.lineQuantity),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: nonNegativeValidator,
                      onChanged: (_) => widget.onChanged(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(width: 72, child: checklistUnitField()),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 118,
                    child: TextFormField(
                      controller: block.unitPriceCtrl,
                      decoration: fieldDec(label: l.lineUnitPrice),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: nonNegativeValidator,
                      onChanged: (_) => widget.onChanged(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 70,
                    child: TextFormField(
                      controller: block.discountRateCtrl,
                      decoration: fieldDec(label: 'Dto. %'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: discountValidator,
                      onChanged: (_) => widget.onChanged(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 64,
                    child: TextFormField(
                      controller: block.taxRateCtrl,
                      decoration: fieldDec(label: '${l.taxRateShort}%'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: taxValidator,
                      onChanged: (_) => widget.onChanged(),
                    ),
                  ),
                ],
              ],
            ),
            if (shouldShowLevel()) ...[
              const SizedBox(height: 6),
              SizedBox(width: 80, child: levelField()),
            ],
            if (block.checklistItems.isNotEmpty) const SizedBox(height: 8),
            for (int i = 0; i < block.checklistItems.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: block.checklistItems[i].text,
                        decoration:
                            fieldDec(label: l.invoiceBlockChecklistItemLabel),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? l.fieldIsRequired
                            : null,
                        onChanged: (_) => widget.onChanged(),
                      ),
                    ),
                    IconButton(
                      tooltip: l.remove,
                      onPressed: () => widget.onRemoveChecklistItem(i),
                      icon: Icon(Icons.delete_outline,
                          size: 16, color: cs.error.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
          ],
        );
      }

      bool useCompactChecklistLayout() => true;
      if (useCompactChecklistLayout()) return compactChecklistFields();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Billable toggle at the top — determines whether billing fields show
          Row(
            children: [
              Switch(
                value: block.isBillable,
                onChanged: (v) {
                  setState(() => block.isBillable = v);
                  widget.onChanged();
                },
              ),
              Text(
                l.invoiceBlockBillableLabel,
                style: t.bodySmall.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          titleField(
            label:
                currentLang.startsWith('es') ? 'Título de lista' : 'List title',
          ),
          if (block.isBillable) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 140,
                  child: TextFormField(
                    controller: block.qtyCtrl,
                    decoration: fieldDec(label: l.lineQuantity),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: nonNegativeValidator,
                    onChanged: (_) => widget.onChanged(),
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: TextFormField(
                    controller: block.unitCtrl,
                    decoration:
                        fieldDec(label: l.invoiceBlockUnitLabel).copyWith(
                      suffixIcon: PopupMenuButton<String>(
                        tooltip: l.invoiceBlockUnitLabel,
                        icon: const Icon(Icons.arrow_drop_down),
                        onSelected: (value) {
                          block.unitCtrl.text = value;
                          block.unitCtrl.selection =
                              TextSelection.collapsed(offset: value.length);
                          widget.onChanged();
                        },
                        itemBuilder: (_) => [
                          for (final unit in _unitOptions)
                            PopupMenuItem<String>(
                              value: unit,
                              child: Text(unit),
                            ),
                        ],
                      ),
                    ),
                    onChanged: (_) => widget.onChanged(),
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: TextFormField(
                    controller: block.unitPriceCtrl,
                    decoration: fieldDec(label: l.lineUnitPrice),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: nonNegativeValidator,
                    onChanged: (_) => widget.onChanged(),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    controller: block.discountRateCtrl,
                    decoration: fieldDec(label: 'Dto. %'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: discountValidator,
                    onChanged: (_) => widget.onChanged(),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: TextFormField(
                    controller: block.taxRateCtrl,
                    decoration: fieldDec(label: '${l.taxRateShort}%'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: taxValidator,
                    onChanged: (_) => widget.onChanged(),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          for (int i = 0; i < block.checklistItems.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: block.checklistItems[i].text,
                      decoration:
                          fieldDec(label: l.invoiceBlockChecklistItemLabel),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? l.fieldIsRequired
                          : null,
                      onChanged: (_) => widget.onChanged(),
                    ),
                  ),
                  IconButton(
                    tooltip: l.remove,
                    onPressed: () => widget.onRemoveChecklistItem(i),
                    icon: Icon(Icons.delete_outline, color: cs.error),
                  ),
                ],
              ),
            ),
          TextButton.icon(
            onPressed: widget.onAddChecklistItem,
            icon: const Icon(Icons.add),
            label: Text(l.invoiceBlockAddChecklistItem),
          ),
        ],
      );
    }

    Widget body() {
      switch (block.type) {
        case InvoiceBlockType.item:
          return itemFields();
        case InvoiceBlockType.worker:
          return workerFields();
        case InvoiceBlockType.date:
          return dateField();
        case InvoiceBlockType.section:
          return sectionFields();
        case InvoiceBlockType.subsection:
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleField(label: l.invoiceBlockTitleLabelSubsection),
              const SizedBox(height: 12),
              if (shouldShowLevel()) levelField(),
            ],
          );
        case InvoiceBlockType.divider:
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Divider(thickness: 1.5, color: cs.outlineVariant),
              const SizedBox(height: 4),
              Text(
                currentLang.startsWith('es')
                    ? 'Línea separadora visual (no aparece en el PDF como texto)'
                    : 'Visual separator line (not printed as text in PDF)',
                style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          );
        case InvoiceBlockType.note:
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              textField(label: l.invoiceBlockNoteLabel),
              const SizedBox(height: 12),
              if (shouldShowLevel()) levelField(),
            ],
          );
        case InvoiceBlockType.checklist:
          return checklistFields();
      }
      return const SizedBox.shrink();
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: widget.selected
              ? cs.primaryContainer.withValues(alpha: 0.25)
              : _hovered
                  ? cs.primary.withValues(alpha: 0.04)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.selected
                ? cs.primary.withValues(alpha: 0.6)
                : cs.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: action strip on the left (outside InkWell so touch
            // events always fire), then the tappable expand/collapse area.
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Action buttons: ↑ ↓ | 🗑 ────────────────────────────────
                _ActionStrip(
                  index: widget.index,
                  total: widget.total,
                  onMoveUp: widget.onMoveUp,
                  onMoveDown: widget.onMoveDown,
                  onDelete: widget.onDelete,
                  l: l,
                  cs: cs,
                ),
                const SizedBox(width: 4),
                // ── Tappable expand area ─────────────────────────────────────
                Expanded(
                  child: InkWell(
                    onTap: () {
                      widget.onSelect();
                      setState(() => _expanded = !_expanded);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 5),
                      child: Row(
                        children: [
                          typePicker(),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              summaryText(),
                              style: t.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface,
                              ),
                              maxLines: _expanded ? 2 : 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (itemMeta() != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              itemMeta()!,
                              style: t.bodySmall.copyWith(
                                fontSize: 11,
                                color: cs.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          if (itemTotalText() != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    cs.primaryContainer.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                itemTotalText()!,
                                style: t.bodySmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: cs.onPrimaryContainer,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(width: 4),
                          AnimatedRotation(
                            turns: _expanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 150),
                            child: Icon(
                              Icons.keyboard_arrow_down,
                              size: 16,
                              color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ), // Expanded (InkWell)
                // ── Billable toggle icon ─────────────────────────────────────
                if (block.type == InvoiceBlockType.item ||
                    block.type == InvoiceBlockType.worker ||
                    block.type == InvoiceBlockType.section ||
                    block.type == InvoiceBlockType.checklist) ...[
                  const SizedBox(width: 4),
                  Tooltip(
                    message: l.invoiceBlockBillableLabel,
                    waitDuration: const Duration(milliseconds: 400),
                    child: InkWell(
                      onTap: () {
                        setState(() => block.isBillable = !block.isBillable);
                        widget.onChanged();
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 5),
                        decoration: BoxDecoration(
                          color: block.isBillable
                              ? cs.primaryContainer.withValues(alpha: 0.55)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: block.isBillable
                                ? cs.primary.withValues(alpha: 0.4)
                                : cs.outlineVariant.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Icon(
                          block.isBillable
                              ? Icons.euro_rounded
                              : Icons.euro_outlined,
                          size: 13,
                          color: block.isBillable
                              ? cs.primary
                              : cs.onSurfaceVariant.withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                  ),
                ],
              ], // Row children
            ), // Row
            if (_expanded) ...[
              const SizedBox(height: 10),
              // Scale down all TextFormField input text uniformly.
              Theme(
                data: Theme.of(context).copyWith(
                  textTheme: Theme.of(context).textTheme.copyWith(
                        bodyLarge: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(fontSize: 12),
                      ),
                ),
                child: body(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact ↑ ↓ | 🗑 strip rendered inside the card header row.
/// Lives outside any InkWell so touch events are never intercepted.
class _ActionStrip extends StatelessWidget {
  final int index;
  final int total;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onDelete;
  final AppLocalizations l;
  final ColorScheme cs;

  const _ActionStrip({
    required this.index,
    required this.total,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onDelete,
    required this.l,
    required this.cs,
  });

  Widget _btn({
    required IconData icon,
    required String tooltip,
    VoidCallback? onTap,
    Color? color,
  }) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 600),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
          child: Icon(
            icon,
            size: 13,
            color: onTap == null
                ? cs.onSurface.withValues(alpha: 0.18)
                : (color ?? cs.onSurfaceVariant.withValues(alpha: 0.6)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn(
            icon: Icons.keyboard_arrow_up,
            tooltip: l.invoiceBlockMoveUp,
            onTap: index == 0 ? null : onMoveUp,
          ),
          _btn(
            icon: Icons.keyboard_arrow_down,
            tooltip: l.invoiceBlockMoveDown,
            onTap: index == total - 1 ? null : onMoveDown,
          ),
          SizedBox(
            height: 12,
            child: VerticalDivider(
              width: 6,
              thickness: 0.5,
              color: cs.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          _btn(
            icon: Icons.delete_outline,
            tooltip: l.remove,
            onTap: onDelete,
            color: cs.error.withValues(alpha: 0.65),
          ),
        ],
      ),
    );
  }
}
