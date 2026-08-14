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
  static const double _unitSelectWidth = 150;
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

    const minWidth = 690.0;

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.36)),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: cs.primary, width: 1.4),
    );

    InputDecoration fieldDec({required String hint}) {
      return InputDecoration(
        hintText: hint,
        enabledBorder: inputBorder,
        focusedBorder: focusedBorder,
        isDense: true,
        filled: true,
        fillColor: cs.surface.withValues(alpha: 0.82),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      );
    }

    final headerStyle = t.bodySmall.copyWith(
      color: cs.onSurfaceVariant,
      fontSize: 11,
      letterSpacing: 0.25,
      fontWeight: FontWeight.w800,
    );

    Widget buildTable(double availableWidth) {
      final tableWidth = availableWidth < minWidth ? minWidth : availableWidth;
      final editorTotal =
          widget.lines.fold<num>(0, (sum, line) => sum + line.total);

      return SizedBox(
        width: tableWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.36),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.24),
                ),
              ),
              child: Row(
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
                    width: ReceiptLinesEditor._unitSelectWidth,
                    child: Text(
                      'Unidad',
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
                  const SizedBox(width: ReceiptLinesEditor._deleteWidth),
                ],
              ),
            ),
            const SizedBox(height: 10),

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
                final autoFocus = isLast && line.description.trim().isEmpty;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
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
            if (widget.lines.isNotEmpty) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.34),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.24),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total líneas',
                        style: t.bodySmall.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        NumberFormat.simpleCurrency(name: '')
                            .format(editorTotal),
                        style: t.bodyMedium.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
  final _customUnitFocus = FocusNode();
  bool _hovered = false;

  @override
  void dispose() {
    _descFocus.dispose();
    _qtyFocus.dispose();
    _unitFocus.dispose();
    _customUnitFocus.dispose();
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: _hovered
              ? cs.primaryContainer.withValues(alpha: 0.12)
              : cs.surface.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered
                ? cs.primary.withValues(alpha: 0.22)
                : cs.outlineVariant.withValues(alpha: 0.22),
          ),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: _hovered ? 0.08 : 0.035),
              blurRadius: _hovered ? 16 : 10,
              offset: const Offset(0, 5),
            ),
          ],
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
                  style: t.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
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
                style: t.bodySmall.copyWith(fontWeight: FontWeight.w700),
                decoration: widget.fieldDec(hint: '1'),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                onChanged: (_) => widget.onChanged(),
                onFieldSubmitted: (_) => _focusNext(_unitFocus),
              ),
            ),
            const SizedBox(width: ReceiptLinesEditor._gap),

            // Unit
            SizedBox(
              width: ReceiptLinesEditor._unitSelectWidth,
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: widget.line.unit,
                      isDense: true,
                      borderRadius: BorderRadius.circular(14),
                      style: t.bodySmall.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                      dropdownColor: cs.surface,
                      decoration: widget.fieldDec(hint: 'Ud.'),
                      items: const [
                        DropdownMenuItem(value: 'unit', child: Text('Ud.')),
                        DropdownMenuItem(value: 'hour', child: Text('Hora')),
                        DropdownMenuItem(value: 'day', child: Text('Día')),
                        DropdownMenuItem(
                            value: 'service', child: Text('Servicio')),
                        DropdownMenuItem(
                            value: 'item', child: Text('Artículo')),
                        DropdownMenuItem(value: 'other', child: Text('Otro')),
                      ],
                      onChanged: widget.canEdit
                          ? (value) {
                              setState(() {
                                widget.line.selectedUnit = value ?? 'unit';
                              });
                              widget.onChanged();
                            }
                          : null,
                    ),
                  ),
                  if (widget.line.unit == 'other') ...[
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 64,
                      child: TextFormField(
                        controller: widget.line.unitLabelCtrl,
                        focusNode: _customUnitFocus,
                        enabled: widget.canEdit,
                        maxLength: 20,
                        decoration: widget.fieldDec(hint: 'Unidad').copyWith(
                              counterText: '',
                            ),
                        style:
                            t.bodySmall.copyWith(fontWeight: FontWeight.w700),
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(20),
                        ],
                        onChanged: (_) => widget.onChanged(),
                        onFieldSubmitted: (_) => _focusNext(_unitFocus),
                      ),
                    ),
                  ],
                ],
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
                style: t.bodySmall.copyWith(fontWeight: FontWeight.w700),
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
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.42),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: cs.primary.withValues(alpha: 0.16),
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    transitionBuilder: (child, anim) =>
                        FadeTransition(opacity: anim, child: child),
                    child: Text(
                      NumberFormat.simpleCurrency(name: '').format(total),
                      key: ValueKey<double>(total.toDouble()),
                      style: t.bodyMedium.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w900,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),

            // Delete
            SizedBox(
              width: ReceiptLinesEditor._deleteWidth,
              height: 40,
              child: Tooltip(
                message: l.remove,
                child: Material(
                  color: cs.errorContainer.withValues(alpha: 0.52),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: (widget.canEdit && widget.canDelete)
                        ? widget.onRemove
                        : null,
                    borderRadius: BorderRadius.circular(12),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: (widget.canEdit && widget.canDelete)
                          ? cs.error
                          : cs.onSurfaceVariant.withValues(alpha: 0.45),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
