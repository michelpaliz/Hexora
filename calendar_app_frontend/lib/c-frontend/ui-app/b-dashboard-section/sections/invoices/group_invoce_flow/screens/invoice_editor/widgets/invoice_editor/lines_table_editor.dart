import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_form_sheet/invoice_lines_editor.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class LinesTableEditor extends StatefulWidget {
  final List<LineDraft> lines;
  final VoidCallback onChanged;
  final bool Function(LineDraft line)? canAttachEvidence;
  final String? Function(LineDraft line)? evidenceBlobNameOf;
  final Future<void> Function(LineDraft line)? onAttachEvidence;
  final Future<void> Function(LineDraft line)? onOpenEvidence;
  final Future<void> Function(LineDraft line)? onDeleteEvidence;

  static const double _gap = 10;
  static const double _qtyWidth = 110;
  static const double _unitWidth = 150;
  static const double _vatWidth = 120;
  static const double _totalWidth = 150;
  static const double _evidenceActionsWidth = 132;
  static const double _deleteWidth = 40;

  const LinesTableEditor({
    super.key,
    required this.lines,
    required this.onChanged,
    this.canAttachEvidence,
    this.evidenceBlobNameOf,
    this.onAttachEvidence,
    this.onOpenEvidence,
    this.onDeleteEvidence,
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

    final inputBorder = UnderlineInputBorder(
      borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
    );
    final focusedBorder = UnderlineInputBorder(
      borderSide: BorderSide(color: cs.primary, width: 1.8),
    );
    final errorBorder = UnderlineInputBorder(
      borderSide: BorderSide(color: cs.error, width: 1.4),
    );

    InputDecoration fieldDec({
      required String hint,
      String? suffixText,
    }) {
      return InputDecoration(
        hintText: hint,
        suffixText: suffixText,
        enabledBorder: inputBorder,
        focusedBorder: focusedBorder,
        errorBorder: errorBorder,
        focusedErrorBorder: errorBorder,
        isDense: true,
        filled: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
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
                final isLast = i == widget.lines.length - 1;
                final shouldAutofocus =
                    isLast && line.description.text.trim().isEmpty;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _LineRow(
                    key: ObjectKey(line),
                    index: i,
                    line: line,
                    fieldDec: fieldDec,
                    onChanged: widget.onChanged,
                    onDelete: () {
                      final removed = widget.lines.remove(line);
                      if (!removed) return;
                      for (int p = 0; p < widget.lines.length; p++) {
                        widget.lines[p].position = p + 1;
                      }
                      widget.onChanged();
                      if (mounted) setState(() {});
                    },
                    onAddLine: () {
                      final nextPos = widget.lines.length + 1;
                      widget.lines.add(LineDraft(position: nextPos));
                      widget.onChanged();
                      if (mounted) setState(() {});
                    },
                    canAttachEvidence: widget.canAttachEvidence?.call(line) ??
                        false,
                    hasEvidence:
                        (widget.evidenceBlobNameOf?.call(line)?.trim() ?? '')
                            .isNotEmpty,
                    onAttachEvidence: widget.onAttachEvidence == null
                        ? null
                        : () => widget.onAttachEvidence!(line),
                    onOpenEvidence: widget.onOpenEvidence == null
                        ? null
                        : () => widget.onOpenEvidence!(line),
                    onDeleteEvidence: widget.onDeleteEvidence == null
                        ? null
                        : () => widget.onDeleteEvidence!(line),
                    autoFocus: shouldAutofocus,
                    isLast: isLast,
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
        const SizedBox(width: 8),
        const SizedBox(width: LinesTableEditor._evidenceActionsWidth),
        const SizedBox(width: 4),
        const SizedBox(width: LinesTableEditor._deleteWidth),
      ],
    );
  }
}

class _LineRow extends StatefulWidget {
  final int index;
  final LineDraft line;
  final InputDecoration Function({required String hint, String? suffixText})
      fieldDec;
  final VoidCallback onChanged;
  final VoidCallback onDelete;
  final VoidCallback onAddLine;
  final bool canAttachEvidence;
  final bool hasEvidence;
  final Future<void> Function()? onAttachEvidence;
  final Future<void> Function()? onOpenEvidence;
  final Future<void> Function()? onDeleteEvidence;
  final bool autoFocus;
  final bool isLast;

  const _LineRow({
    super.key,
    required this.index,
    required this.line,
    required this.fieldDec,
    required this.onChanged,
    required this.onDelete,
    required this.onAddLine,
    required this.canAttachEvidence,
    required this.hasEvidence,
    required this.onAttachEvidence,
    required this.onOpenEvidence,
    required this.onDeleteEvidence,
    required this.autoFocus,
    required this.isLast,
  });

  @override
  State<_LineRow> createState() => _LineRowState();
}

class _LineRowState extends State<_LineRow> {
  final _descFocus = FocusNode();
  final _qtyFocus = FocusNode();
  final _unitFocus = FocusNode();
  final _vatFocus = FocusNode();

  @override
  void dispose() {
    _descFocus.dispose();
    _qtyFocus.dispose();
    _unitFocus.dispose();
    _vatFocus.dispose();
    super.dispose();
  }

  void _focusNext(FocusNode next) {
    if (!mounted) return;
    FocusScope.of(context).requestFocus(next);
  }

  void _handleVatSubmit() {
    if (widget.isLast) {
      widget.onAddLine();
    }
    Future.microtask(() {
      if (!mounted) return;
      FocusScope.of(context).nextFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);

    final qty = widget.line.quantity ?? 1;
    final unit = widget.line.unitPrice ?? 0;
    final taxRate = widget.line.taxRate ?? 21;
    final subtotal = qty * unit;
    final tax = subtotal * (taxRate / 100);
    final total = subtotal + tax;

    String? priceValidator(String? v) {
      final parsed = num.tryParse((v ?? '').trim()) ?? 0;
      if (parsed <= 0) return l.invoicePreviewNeedsLines;
      return null;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Expanded(
              flex: 3,
              child: Focus(
                onKeyEvent: (_, event) {
                  if (event is KeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.backspace &&
                      widget.line.description.text.trim().isEmpty) {
                    widget.onDelete();
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: TextFormField(
                  controller: widget.line.description,
                  focusNode: _descFocus,
                  autofocus: widget.autoFocus,
                  textInputAction: TextInputAction.next,
                  style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                  decoration: widget.fieldDec(hint: l.lineDescription),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  onChanged: (_) => widget.onChanged(),
                  onFieldSubmitted: (_) => _focusNext(_qtyFocus),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? l.fieldIsRequired : null,
                ),
              ),
            ),
            const SizedBox(width: LinesTableEditor._gap),
            SizedBox(
              width: LinesTableEditor._qtyWidth,
              child: TextFormField(
                controller: widget.line.quantityCtrl,
                focusNode: _qtyFocus,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                textInputAction: TextInputAction.next,
                style: t.bodySmall,
                decoration: widget.fieldDec(hint: l.lineQuantity),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                onChanged: (_) => widget.onChanged(),
                onFieldSubmitted: (_) => _focusNext(_unitFocus),
              ),
            ),
            const SizedBox(width: LinesTableEditor._gap),
            SizedBox(
              width: LinesTableEditor._unitWidth,
              child: TextFormField(
                controller: widget.line.unitPriceCtrl,
                focusNode: _unitFocus,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                textInputAction: TextInputAction.next,
                style: t.bodySmall,
                decoration: widget.fieldDec(hint: l.lineUnitPrice),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                onChanged: (_) => widget.onChanged(),
                onFieldSubmitted: (_) => _focusNext(_vatFocus),
                validator: priceValidator,
              ),
            ),
            const SizedBox(width: LinesTableEditor._gap),
            SizedBox(
              width: LinesTableEditor._vatWidth,
              child: TextFormField(
                controller: widget.line.taxRateCtrl,
                focusNode: _vatFocus,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                textInputAction: TextInputAction.done,
                style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                decoration:
                    widget.fieldDec(hint: '${l.taxRateShort}%', suffixText: '%'),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                onChanged: (_) => widget.onChanged(),
                onFieldSubmitted: (_) => _handleVatSubmit(),
              ),
            ),
            const SizedBox(width: LinesTableEditor._gap),
            SizedBox(
              width: LinesTableEditor._totalWidth,
              child: Align(
                alignment: Alignment.centerRight,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, anim) =>
                      FadeTransition(opacity: anim, child: child),
                  child: Text(
                    NumberFormat.simpleCurrency(name: '').format(total),
                    key: ValueKey<double>(total.toDouble()),
                    style: t.bodyMedium.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            SizedBox(
              width: LinesTableEditor._evidenceActionsWidth,
              height: 48,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: l.invoiceLineEvidenceAttach,
                    onPressed: widget.onAttachEvidence == null
                        ? null
                        : () => widget.onAttachEvidence!.call(),
                    icon: const Icon(Icons.attach_file_rounded, size: 18),
                    color: widget.canAttachEvidence
                        ? null
                        : cs.onSurfaceVariant.withValues(alpha: 0.65),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints.tightFor(width: 36, height: 36),
                    splashRadius: 18,
                  ),
                  IconButton(
                    tooltip: l.invoiceLineEvidenceOpen,
                    onPressed: widget.hasEvidence && widget.onOpenEvidence != null
                        ? () => widget.onOpenEvidence!.call()
                        : null,
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints.tightFor(width: 36, height: 36),
                    splashRadius: 18,
                  ),
                  IconButton(
                    tooltip: l.invoiceLineEvidenceDelete,
                    onPressed:
                        widget.hasEvidence && widget.onDeleteEvidence != null
                            ? () => widget.onDeleteEvidence!.call()
                            : null,
                    icon: const Icon(Icons.link_off_outlined, size: 18),
                    color: cs.tertiary,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints.tightFor(width: 36, height: 36),
                    splashRadius: 18,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            SizedBox(
              width: LinesTableEditor._deleteWidth,
              height: 48,
              child: IconButton(
                tooltip: l.remove,
                onPressed: widget.onDelete,
                icon: const Icon(Icons.delete_outline),
                color: cs.error,
              ),
            ),
          ],
        ),
    );
  }
}
