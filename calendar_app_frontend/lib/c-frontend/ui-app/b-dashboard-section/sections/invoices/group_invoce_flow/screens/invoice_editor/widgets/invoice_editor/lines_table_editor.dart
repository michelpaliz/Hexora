import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_form_sheet/invoice_lines_editor.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class LinesTableEditor extends StatefulWidget {
  final List<LineDraft> lines;
  final VoidCallback onChanged;

  static const double _gap = 10;
  static const double _qtyWidth = 110;
  static const double _unitWidth = 150;
  static const double _vatWidth = 120;
  static const double _totalWidth = 150;
  static const double _deleteWidth = 40;

  const LinesTableEditor({
    super.key,
    required this.lines,
    required this.onChanged,
  });

  @override
  State<LinesTableEditor> createState() => _LinesTableEditorState();
}

class _LinesTableEditorState extends State<LinesTableEditor> {
  final ScrollController _horizontal = ScrollController();

  @override
  void dispose() {
    _horizontal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    const minTableWidth = 980.0;

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
    );

    InputDecoration fieldDec({
      required String hint,
      String? suffixText,
    }) {
      return InputDecoration(
        hintText: hint,
        suffixText: suffixText,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        isDense: true,
        filled: true,
        fillColor: cs.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      );
    }

    final headerStyle = t.bodySmall.copyWith(
      color: cs.onSurfaceVariant,
      fontWeight: FontWeight.w700,
    );

    Widget buildTable(double availableWidth) {
      final tableWidth =
          availableWidth < minTableWidth ? minTableWidth : availableWidth;

      return SizedBox(
        width: tableWidth,
        child: Column(
          children: [
            _HeaderRow(style: headerStyle),
            const SizedBox(height: 8),
            if (widget.lines.isEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l.invoiceLinesRequired,
                  style: t.bodySmall.copyWith(color: cs.error),
                ),
              )
            else
              ...List.generate(widget.lines.length, (i) {
                final line = widget.lines[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _LineRow(
                    index: i,
                    line: line,
                    fieldDec: fieldDec,
                    onChanged: widget.onChanged,
                    onDelete: () {
                      widget.lines.removeAt(i);
                      for (int p = 0; p < widget.lines.length; p++) {
                        widget.lines[p].position = p + 1;
                      }
                      widget.onChanged();
                    },
                  ),
                );
              }),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final scrollable = constraints.maxWidth < minTableWidth;
        final table = buildTable(constraints.maxWidth);

        if (!scrollable) return table;

        return Scrollbar(
          controller: _horizontal,
          thumbVisibility: true,
          trackVisibility: true,
          notificationPredicate: (n) => n.depth == 0,
          child: SingleChildScrollView(
            controller: _horizontal,
            scrollDirection: Axis.horizontal,
            child: table,
          ),
        );
      },
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final TextStyle style;
  const _HeaderRow({required this.style});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(flex: 3, child: Text(l.lineDescription, style: style)),
        const SizedBox(width: LinesTableEditor._gap),
        SizedBox(
          width: LinesTableEditor._qtyWidth,
          child: Text(l.lineQuantity, style: style, textAlign: TextAlign.center),
        ),
        const SizedBox(width: LinesTableEditor._gap),
        SizedBox(
          width: LinesTableEditor._unitWidth,
          child:
              Text(l.lineUnitPrice, style: style, textAlign: TextAlign.center),
        ),
        const SizedBox(width: LinesTableEditor._gap),
        SizedBox(
          width: LinesTableEditor._vatWidth,
          child: Text('${l.taxRateShort}%',
              style: style, textAlign: TextAlign.center),
        ),
        const SizedBox(width: LinesTableEditor._gap),
        SizedBox(
          width: LinesTableEditor._totalWidth,
          child: Text(l.invoiceTotalLabel, style: style, textAlign: TextAlign.right),
        ),
        const SizedBox(width: 4),
        const SizedBox(width: LinesTableEditor._deleteWidth),
      ],
    );
  }
}

class _LineRow extends StatelessWidget {
  final int index;
  final LineDraft line;
  final InputDecoration Function({required String hint, String? suffixText})
      fieldDec;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  const _LineRow({
    required this.index,
    required this.line,
    required this.fieldDec,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);

    final qty = line.quantity ?? 1;
    final unit = line.unitPrice ?? 0;
    final taxRate = line.taxRate ?? 21;
    final subtotal = qty * unit;
    final tax = subtotal * (taxRate / 100);
    final total = subtotal + tax;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: TextFormField(
            controller: line.description,
            decoration: fieldDec(hint: l.lineDescription),
            onChanged: (_) => onChanged(),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l.fieldIsRequired : null,
          ),
        ),
        const SizedBox(width: LinesTableEditor._gap),
        SizedBox(
          width: LinesTableEditor._qtyWidth,
          child: TextFormField(
            controller: line.quantityCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            decoration: fieldDec(hint: l.lineQuantity),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            onChanged: (_) => onChanged(),
          ),
        ),
        const SizedBox(width: LinesTableEditor._gap),
        SizedBox(
          width: LinesTableEditor._unitWidth,
          child: TextFormField(
            controller: line.unitPriceCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            decoration: fieldDec(hint: l.lineUnitPrice),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            onChanged: (_) => onChanged(),
          ),
        ),
        const SizedBox(width: LinesTableEditor._gap),
        SizedBox(
          width: LinesTableEditor._vatWidth,
          child: TextFormField(
            controller: line.taxRateCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            decoration: fieldDec(hint: '${l.taxRateShort}%', suffixText: '%'),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            onChanged: (_) => onChanged(),
          ),
        ),
        const SizedBox(width: LinesTableEditor._gap),
        SizedBox(
          width: LinesTableEditor._totalWidth,
          child: Container(
            height: 48,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Text(
              NumberFormat.simpleCurrency(name: '').format(total),
              style: t.bodySmall.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: LinesTableEditor._deleteWidth,
          height: 48,
          child: IconButton(
            tooltip: l.remove,
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
            color: cs.error,
          ),
        ),
      ],
    );
  }
}
