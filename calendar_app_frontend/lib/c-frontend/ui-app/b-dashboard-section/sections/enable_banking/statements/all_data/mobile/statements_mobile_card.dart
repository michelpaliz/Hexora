import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

import '../../statements_formatters.dart';
import '../../statements_shared.dart';

class StatementsMobileCard extends StatelessWidget {
  const StatementsMobileCard({
    super.key,
    required this.entry,
    required this.index,
    required this.onTap,
  });

  final Map<String, dynamic> entry;
  final int index;
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
    final t = AppTypography.of(context);
    final l = AppLocalizations.of(context)!;

    final date = StatementsShared.entryText(entry, ['date']);
    final valueDate = StatementsShared.entryText(entry, ['valueDate']);
    final desc = StatementsShared.entryText(entry, ['description']);

    final rawAmount = _rawIndex(4);
    final amount = rawAmount.isNotEmpty
        ? rawAmount
        : StatementsShared.entryText(entry, ['amount']);
    final amountValue = StatementsFormatters.parseAmount(amount) ?? 0;
    final isNegative = amountValue < 0;
    final amountColor = isNegative
        ? const Color(0xFFC62828)
        : const Color(0xFF1565C0);

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
    final invoiceNumber =
        (entry['invoiceNumber'] ?? entry['invoice_number'])?.toString().trim() ??
            '';
    final expenseNumber =
        (entry['expenseNumber'] ?? entry['expense_number'])?.toString().trim() ??
            '';
    final effectiveNumbers = invoiceNumbers.isNotEmpty
        ? invoiceNumbers
        : (invoiceNumber.isNotEmpty ? [invoiceNumber] : const <String>[]);
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 3,
                height: 40,
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
                      style:
                          t.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          dateDisplay,
                          style: t.bodySmall.copyWith(
                            color: cs.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 8),
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
              Text(
                StatementsFormatters.formatCurrency(context, amount),
                style: t.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: amountColor,
                  fontSize: 14,
                ),
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
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
