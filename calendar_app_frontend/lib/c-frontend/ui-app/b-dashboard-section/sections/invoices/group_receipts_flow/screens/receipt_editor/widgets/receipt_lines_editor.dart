import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_receipts_flow/screens/receipt_editor/widgets/receipt_line_draft.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class ReceiptLinesEditor extends StatefulWidget {
  final List<ReceiptLineDraft> lines;
  final bool canEdit;
  final ValueChanged<int> onRemove;
  final VoidCallback onChanged;
  final VoidCallback? onAddLine;

  static const double _gap = 10;
  static const double _qtyWidth = 90;
  static const double _unitWidth = 130;
  static const double _totalWidth = 130;
  static const double _deleteWidth = 40;

  const ReceiptLinesEditor({
    super.key,
    required this.lines,
    required this.canEdit,
    required this.onRemove,
    required this.onChanged,
    this.onAddLine,
  });

  @override
  State<ReceiptLinesEditor> createState() => _ReceiptLinesEditorState();
}

class _ReceiptLinesEditorState extends State<ReceiptLinesEditor> {
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

    const minWidth = 520.0;

    final inputBorder = UnderlineInputBorder(
      borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
    );
    final focusedBorder = UnderlineInputBorder(
      borderSide: BorderSide(color: cs.primary, width: 1.8),
    );

    InputDecoration fieldDec({required String hint}) {
      return InputDecoration(
        hintText: hint,
        enabledBorder: inputBorder,
        focusedBorder: focusedBorder,
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
          availableWidth < minWidth ? minWidth : availableWidth;

      return SizedBox(
        width: tableWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(l.lineDescription, style: headerStyle),
                ),
                const SizedBox(width: ReceiptLinesEditor._gap),
                SizedBox(
                  width: ReceiptLinesEditor._qtyWidth,
                  child: Text(
                    l.lineQuantity,
                    style: headerStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: ReceiptLinesEditor._gap),
                SizedBox(
                  width: ReceiptLinesEditor._unitWidth,
                  child: Text(
                    l.lineUnitPrice,
                    style: headerStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: ReceiptLinesEditor._gap),
                SizedBox(
                  width: ReceiptLinesEditor._totalWidth,
                  child: Text(
                    l.receiptLineTotalLabel,
                    style: headerStyle,
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 4),
                SizedBox(width: ReceiptLinesEditor._deleteWidth),
              ],
            ),
            const SizedBox(height: 8),

            // ── Lines ──────────────────────────────────────────────────────
            if (widget.lines.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  l.receiptLinesRequired,
                  style: t.bodySmall.copyWith(color: cs.error),
                ),
              )
            else
              ...List.generate(widget.lines.length, (i) {
                final line = widget.lines[i];
                final isLast = i == widget.lines.length - 1;
                final autoFocus =
                    isLast && line.description.trim().isEmpty;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _ReceiptLineRow(
                    key: ObjectKey(line),
                    index: i,
                    line: line,
                    canEdit: widget.canEdit,
                    fieldDec: fieldDec,
                    onChanged: widget.onChanged,
                    onRemove: () => widget.onRemove(i),
                    onAddLine: widget.onAddLine,
                    canDelete: widget.lines.length > 1,
                    autoFocus: autoFocus,
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
        final scrollable = constraints.maxWidth < minWidth;
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

// ─────────────────────────────────────────────────────────────────────────────

class _ReceiptLineRow extends StatefulWidget {
  final int index;
  final ReceiptLineDraft line;
  final bool canEdit;
  final bool canDelete;
  final bool autoFocus;
  final bool isLast;
  final InputDecoration Function({required String hint}) fieldDec;
  final VoidCallback onChanged;
  final VoidCallback onRemove;
  final VoidCallback? onAddLine;

  const _ReceiptLineRow({
    super.key,
    required this.index,
    required this.line,
    required this.canEdit,
    required this.canDelete,
    required this.autoFocus,
    required this.isLast,
    required this.fieldDec,
    required this.onChanged,
    required this.onRemove,
    required this.onAddLine,
  });

  @override
  State<_ReceiptLineRow> createState() => _ReceiptLineRowState();
}

class _ReceiptLineRowState extends State<_ReceiptLineRow> {
  final _descFocus = FocusNode();
  final _qtyFocus = FocusNode();
  final _unitFocus = FocusNode();
  bool _hovered = false;

  @override
  void dispose() {
    _descFocus.dispose();
    _qtyFocus.dispose();
    _unitFocus.dispose();
    super.dispose();
  }

  void _focusNext(FocusNode next) {
    if (!mounted) return;
    FocusScope.of(context).requestFocus(next);
  }

  void _handleUnitSubmit() {
    if (widget.isLast) {
      widget.onAddLine?.call();
    } else {
      Future.microtask(() {
        if (!mounted) return;
        FocusScope.of(context).nextFocus();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);

    final total = widget.line.total;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _hovered
              ? cs.surfaceContainerHighest.withValues(alpha: 0.45)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Description
            Expanded(
              flex: 3,
              child: Focus(
                onKeyEvent: (_, event) {
                  if (event is KeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.backspace &&
                      widget.line.description.trim().isEmpty &&
                      widget.canDelete) {
                    widget.onRemove();
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: TextFormField(
                  controller: widget.line.descriptionCtrl,
                  focusNode: _descFocus,
                  autofocus: widget.autoFocus,
                  enabled: widget.canEdit,
                  textInputAction: TextInputAction.next,
                  style: t.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                  decoration: widget.fieldDec(hint: l.lineDescription),
                  onChanged: (_) => widget.onChanged(),
                  onFieldSubmitted: (_) => _focusNext(_qtyFocus),
                ),
              ),
            ),
            const SizedBox(width: ReceiptLinesEditor._gap),

            // Quantity
            SizedBox(
              width: ReceiptLinesEditor._qtyWidth,
              child: TextFormField(
                controller: widget.line.qtyCtrl,
                focusNode: _qtyFocus,
                enabled: widget.canEdit,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                textInputAction: TextInputAction.next,
                style: t.bodySmall,
                decoration: widget.fieldDec(hint: '1'),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                onChanged: (_) => widget.onChanged(),
                onFieldSubmitted: (_) => _focusNext(_unitFocus),
              ),
            ),
            const SizedBox(width: ReceiptLinesEditor._gap),

            // Unit price
            SizedBox(
              width: ReceiptLinesEditor._unitWidth,
              child: TextFormField(
                controller: widget.line.unitCtrl,
                focusNode: _unitFocus,
                enabled: widget.canEdit,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                textInputAction: TextInputAction.done,
                style: t.bodySmall,
                decoration: widget.fieldDec(hint: '0.00'),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                onChanged: (_) => widget.onChanged(),
                onFieldSubmitted: (_) => _handleUnitSubmit(),
              ),
            ),
            const SizedBox(width: ReceiptLinesEditor._gap),

            // Total (read-only, animated)
            SizedBox(
              width: ReceiptLinesEditor._totalWidth,
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
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),

            // Delete
            SizedBox(
              width: ReceiptLinesEditor._deleteWidth,
              height: 40,
              child: IconButton(
                tooltip: l.remove,
                onPressed:
                    (widget.canEdit && widget.canDelete) ? widget.onRemove : null,
                icon: const Icon(Icons.delete_outline, size: 18),
                color: cs.error,
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints.tightFor(width: 36, height: 36),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
