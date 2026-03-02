import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/a-models/invoice/invoice_block.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_form_sheet/invoice_blocks_editor.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class BlockCard extends StatefulWidget {
  final int index;
  final int total;
  final InvoiceBlockDraft block;
  final bool selected;
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
  bool _showAdvanced = false;
  static const _unitOptions = <String>['ud', 'h', 'kg', 'm', 'm2', 'm3', 'l'];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final block = widget.block;
    final numFmt = NumberFormat('#,##0.##');
    final moneyFmt = NumberFormat.simpleCurrency(name: '');

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
    );

    InputDecoration fieldDec({required String label, String? suffixText}) {
      return InputDecoration(
        labelText: label,
        suffixText: suffixText,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        isDense: true,
      );
    }

    String typeLabel(String type) {
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
      }
      return Icons.more_horiz;
    }

    String? nonNegativeValidator(String? v) {
      final parsed = num.tryParse((v ?? '').trim());
      if (parsed == null) return l.fieldIsRequired;
      if (parsed < 0) return l.invoiceValidationNonNegative;
      return null;
    }

    String? taxValidator(String? v) {
      final parsed = num.tryParse((v ?? '').trim());
      if (parsed == null) return l.fieldIsRequired;
      if (parsed < 0 || parsed > 100) return l.invoiceValidationTaxRate;
      return null;
    }

    Widget headerActions() {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: l.invoiceBlockMoveUp,
            onPressed: widget.index == 0 ? null : widget.onMoveUp,
            icon: const Icon(Icons.keyboard_arrow_up),
          ),
          IconButton(
            tooltip: l.invoiceBlockMoveDown,
            onPressed:
                widget.index == widget.total - 1 ? null : widget.onMoveDown,
            icon: const Icon(Icons.keyboard_arrow_down),
          ),
          IconButton(
            tooltip: l.remove,
            onPressed: widget.onDelete,
            icon: Icon(Icons.delete_outline, color: cs.error),
          ),
        ],
      );
    }

    Widget typePicker() {
      final items = [
        InvoiceBlockType.item,
        InvoiceBlockType.date,
        InvoiceBlockType.section,
        InvoiceBlockType.subsection,
        InvoiceBlockType.divider,
        InvoiceBlockType.note,
        InvoiceBlockType.checklist,
      ];

      return PopupMenuButton<String>(
        tooltip: l.invoiceBlockTypeLabel,
        onSelected: (value) {
          setState(() {
            block.type = value;
            _expanded = true;
          });
          widget.onSelect();
          widget.onChanged();
        },
        itemBuilder: (_) => items
            .map((type) => PopupMenuItem<String>(
                  value: type,
                  child: Text(typeLabel(type)),
                ))
            .toList(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(typeIcon(block.type), size: 18, color: cs.primary),
            const SizedBox(width: 6),
            Text(
              typeLabel(block.type),
              style: t.bodySmall.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 2),
            Icon(Icons.expand_more, size: 18, color: cs.onSurfaceVariant),
          ],
        ),
      );
    }

    String summaryText() {
      switch (block.type) {
        case InvoiceBlockType.item:
          final sku = block.sku.text.trim();
          final desc = block.description.text.trim();
          final label = desc.isEmpty ? l.lineDescription : desc;
          return sku.isEmpty ? label : '$sku $label';
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
      final unit = block.unitCtrl.text.trim();
      final qtyText =
          unit.isEmpty ? numFmt.format(qty) : '${numFmt.format(qty)} $unit';
      return '$qtyText × ${moneyFmt.format(price)}';
    }

    String? itemTotalText() {
      if (!block.isBillableLine) return null;
      final qty = block.qty ?? 1;
      final price = block.unitPrice ?? 0;
      final taxRate = block.taxRate ?? 21;
      final subtotal = qty * price;
      final tax = subtotal * (taxRate / 100);
      final total = subtotal + tax;
      return moneyFmt.format(total);
    }

    bool shouldShowLevel() {
      return _showAdvanced || block.levelCtrl.text.trim().isNotEmpty;
    }

    Widget advancedToggle() {
      return TextButton.icon(
        onPressed: () => setState(() => _showAdvanced = !_showAdvanced),
        icon: Icon(_showAdvanced ? Icons.expand_less : Icons.more_horiz),
        label: Text(
          _showAdvanced
              ? l.invoiceBlockAdvancedHideCta
              : l.invoiceBlockAdvancedShowCta,
        ),
      );
    }

    Widget itemFields() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: block.description,
            decoration: fieldDec(label: l.lineDescription),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l.fieldIsRequired : null,
            onChanged: (_) => widget.onChanged(),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 160,
                child: TextFormField(
                  controller: block.sku,
                  decoration: fieldDec(label: l.invoiceBlockSkuLabel),
                  onChanged: (_) => widget.onChanged(),
                ),
              ),
              SizedBox(
                width: 220,
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: block.qtyCtrl,
                        decoration: fieldDec(label: l.lineQuantity),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                        ],
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: nonNegativeValidator,
                        onChanged: (_) => widget.onChanged(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
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
                                  TextSelection.collapsed(
                                offset: value.length,
                              );
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
                  ],
                ),
              ),
              SizedBox(
                width: 140,
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
              if (shouldShowLevel())
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    controller: block.levelCtrl,
                    decoration: fieldDec(label: l.invoiceBlockLevelLabel),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                    ],
                    onChanged: (_) => widget.onChanged(),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          advancedToggle(),
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
        ],
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
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 160,
                child: TextFormField(
                  controller: block.unitPriceCtrl,
                  decoration: fieldDec(label: 'Precio del paquete'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: nonNegativeValidator,
                  enabled: block.isBillable,
                  onChanged: (_) => widget.onChanged(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
      if (block.qtyCtrl.text.trim().isEmpty) {
        block.qtyCtrl.text = '1';
      }
      if (block.unitCtrl.text.trim().isEmpty) {
        block.unitCtrl.text = 'ud';
      }
      if (block.taxRateCtrl.text.trim().isEmpty) {
        block.taxRateCtrl.text = '21';
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleField(label: 'Título de lista'),
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
                  enabled: block.isBillable,
                  onChanged: (_) => widget.onChanged(),
                ),
              ),
              SizedBox(
                width: 140,
                child: TextFormField(
                  controller: block.unitCtrl,
                  decoration: fieldDec(label: l.invoiceBlockUnitLabel).copyWith(
                    suffixIcon: PopupMenuButton<String>(
                      tooltip: l.invoiceBlockUnitLabel,
                      icon: const Icon(Icons.arrow_drop_down),
                      onSelected: (value) {
                        block.unitCtrl.text = value;
                        block.unitCtrl.selection = TextSelection.collapsed(
                          offset: value.length,
                        );
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
                  enabled: block.isBillable,
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
                  enabled: block.isBillable,
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
                  enabled: block.isBillable,
                  onChanged: (_) => widget.onChanged(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < block.checklistItems.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Checkbox(
                    value: block.checklistItems[i].checked,
                    onChanged: (v) {
                      setState(
                          () => block.checklistItems[i].checked = v ?? false);
                      widget.onChanged();
                    },
                  ),
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
              advancedToggle(),
            ],
          );
        case InvoiceBlockType.divider:
          return Text(
            l.invoiceBlockTypeDivider,
            style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
          );
        case InvoiceBlockType.note:
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              textField(label: l.invoiceBlockNoteLabel),
              const SizedBox(height: 12),
              if (shouldShowLevel()) levelField(),
              advancedToggle(),
            ],
          );
        case InvoiceBlockType.checklist:
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              checklistFields(),
              const SizedBox(height: 12),
              if (shouldShowLevel()) levelField(),
              advancedToggle(),
            ],
          );
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
                  ? cs.surfaceContainerHighest.withValues(alpha: 0.35)
                  : cs.surfaceContainerLowest,
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      widget.onSelect();
                      setState(() => _expanded = !_expanded);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 6),
                      child: Row(
                        children: [
                          typePicker(),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              summaryText(),
                              style: t.bodyMedium
                                  .copyWith(fontWeight: FontWeight.w700),
                              maxLines: _expanded ? 2 : 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (itemMeta() != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              itemMeta()!,
                              style: t.bodySmall.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                if (itemTotalText() != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    itemTotalText()!,
                    style: t.bodyMedium.copyWith(
                      fontWeight: FontWeight.w900,
                      color: cs.onSurface,
                    ),
                  ),
                ],
                const SizedBox(width: 6),
                headerActions(),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 12),
              body(),
            ],
          ],
        ),
      ),
    );
  }
}
