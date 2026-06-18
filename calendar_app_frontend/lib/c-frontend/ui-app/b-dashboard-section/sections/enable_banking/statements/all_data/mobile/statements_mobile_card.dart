import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

import '../../shared/statement_entry_notes_dialog.dart';
import '../../statements_controller.dart';
import '../../statements_formatters.dart';
import '../../statements_shared.dart';

class StatementsMobileCard extends StatelessWidget {
  const StatementsMobileCard({
    super.key,
    required this.entry,
    required this.index,
    required this.controller,
    required this.onTap,
  });

  final Map<String, dynamic> entry;
  final int index;
  final StatementsController controller;
  final VoidCallback onTap;

  String _rawIndex(int idx) {
    final raw = entry['raw'];
    if (raw is List && raw.length > idx) {
      final value = raw[idx];
      if (value != null) return value.toString();
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = AppTypography.of(context);
    final l = AppLocalizations.of(context)!;

    final date = StatementsShared.entryText(entry, ['date']);
    final valueDate = StatementsShared.entryText(entry, ['valueDate']);
    final desc = StatementsShared.entryText(entry, ['description']);
    final entryId = (entry['_id'] ?? entry['id'])?.toString() ?? '';
    final notes = StatementsShared.entryText(entry, ['notes']).trim();
    final hasNotes = notes.isNotEmpty;
    final savingNotes = controller.savingEntryNotes[entryId] == true;

    final rawAmount = _rawIndex(4);
    final amount = rawAmount.isNotEmpty
        ? rawAmount
        : StatementsShared.entryText(entry, ['amount']);
    final amountValue = StatementsFormatters.parseAmount(amount) ?? 0;
    final isNegative = amountValue < 0;
    final amountColor =
        isNegative ? const Color(0xFFC62828) : const Color(0xFF1565C0);

    List<String> toStringList(dynamic raw) {
      if (raw is List) {
        return raw
            .map((e) => e?.toString().trim() ?? '')
            .where((e) => e.isNotEmpty)
            .toList();
      }
      return const [];
    }

    final invoiceNumbers = toStringList(entry['invoiceNumbers']);
    final expenseDocumentNumbers = toStringList(
      entry['expenseDocumentNumbers'] ?? entry['expenseNumbers'],
    );
    final invoiceNumber = (entry['invoiceNumber'] ?? entry['invoice_number'])
            ?.toString()
            .trim() ??
        '';
    final expenseNumber = (entry['expenseNumber'] ?? entry['expense_number'])
            ?.toString()
            .trim() ??
        '';
    final expenseDocumentNumber =
        (entry['expenseDocumentNumber'] ?? entry['expense_document_number'])
                ?.toString()
                .trim() ??
            '';
    final effectiveNumbers = isNegative
        ? (expenseDocumentNumbers.isNotEmpty
            ? expenseDocumentNumbers
            : invoiceNumbers.isNotEmpty
                ? invoiceNumbers
                : expenseDocumentNumber.isNotEmpty
                    ? [expenseDocumentNumber]
                    : const <String>[])
        : (invoiceNumbers.isNotEmpty
            ? invoiceNumbers
            : (invoiceNumber.isNotEmpty ? [invoiceNumber] : const <String>[]));
    final docNumber = effectiveNumbers.isNotEmpty
        ? effectiveNumbers.join(', ')
        : (expenseNumber.isNotEmpty ? expenseNumber : '');
    final hasNoProcede =
        (entry['noProcedeReason']?.toString().trim().isNotEmpty) == true;
    final isUnlinked = entry['clientId'] == null ||
        entry['clientId'].toString().trim().isEmpty;

    final dateDisplay = valueDate.isNotEmpty && valueDate != date
        ? '${StatementsFormatters.formatDate(context, date)} · ${StatementsFormatters.formatDate(context, valueDate)}'
        : (date.isNotEmpty
            ? StatementsFormatters.formatDate(context, date)
            : StatementsFormatters.formatDate(context, valueDate));

    final rowAccent = isNegative ? cs.tertiary : cs.primary;
    final amountBg = isNegative
        ? const Color(0xFFC62828).withValues(alpha: isDark ? 0.18 : 0.08)
        : const Color(0xFF1565C0).withValues(alpha: isDark ? 0.18 : 0.08);
    final amountBorder = isNegative
        ? const Color(0xFFC62828).withValues(alpha: isDark ? 0.22 : 0.14)
        : const Color(0xFF1565C0).withValues(alpha: isDark ? 0.22 : 0.14);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      elevation: 0,
      color: isDark
          ? cs.surface
          : cs.surfaceContainerLowest.withValues(alpha: 0.9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 3,
                height: 46,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: rowAccent.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      desc.isEmpty ? l.statementsNoDescription : desc,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          dateDisplay,
                          style: t.bodySmall.copyWith(
                            color: cs.onSurfaceVariant,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (hasNoProcede)
                          _Badge(
                            label: 'No procede',
                            bg: cs.tertiaryContainer,
                            fg: cs.onTertiaryContainer,
                          )
                        else if (docNumber.isNotEmpty)
                          _Badge(
                            label: docNumber,
                            bg: cs.primaryContainer,
                            fg: cs.onPrimaryContainer,
                          )
                        else if (isUnlinked)
                          _Badge(
                            label: l.statementsUnlinked,
                            bg: cs.surfaceContainerHighest,
                            fg: cs.onSurfaceVariant,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: amountBg,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: amountBorder),
                    ),
                    child: Text(
                      StatementsFormatters.formatCurrency(context, amount),
                      style: t.bodyMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: amountColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Tooltip(
                        message: hasNotes ? 'Editar nota' : 'Añadir nota',
                        child: IconButton(
                          onPressed: entryId.isEmpty || savingNotes
                              ? null
                              : () => StatementEntryNotesDialog.show(
                                    context,
                                    controller,
                                    entry,
                                  ),
                          icon: Icon(
                            savingNotes
                                ? Icons.hourglass_top_rounded
                                : hasNotes
                                    ? Icons.sticky_note_2
                                    : Icons.sticky_note_2_outlined,
                            size: 17,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                          style: IconButton.styleFrom(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            foregroundColor: hasNotes
                                ? cs.primary
                                : cs.onSurfaceVariant.withValues(alpha: 0.65),
                            backgroundColor: hasNotes
                                ? cs.primary.withValues(alpha: 0.10)
                                : Colors.transparent,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.55),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.bg,
    required this.fg,
  });

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: fg.withValues(alpha: 0.08),
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: t.bodySmall.copyWith(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
