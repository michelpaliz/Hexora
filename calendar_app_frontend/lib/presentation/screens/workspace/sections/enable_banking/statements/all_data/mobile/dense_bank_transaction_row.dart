import 'package:flutter/material.dart';

import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

import '../../statements_controller.dart';
import '../../statements_formatters.dart';
import '../../statements_shared.dart';

/// Dense, borderless banking transaction row for the mobile movements list.
///
/// Two text lines only — description + amount on the first, date + linked
/// status on the second — targeting a ~44–48px visual height while keeping a
/// 44px touch target. The whole row is tappable and opens the transaction
/// detail sheet, where notes, linking and editing live; there is no per-row
/// card, badge, accent bar or action row. The row expands (never clips) when
/// the viewer scales up text.
class DenseBankTransactionRow extends StatelessWidget {
  const DenseBankTransactionRow({
    super.key,
    required this.entry,
    required this.controller,
    required this.onTap,
  });

  final Map<String, dynamic> entry;
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

  List<String> _toStringList(dynamic raw) {
    if (raw is List) {
      return raw
          .map((e) => e?.toString().trim() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
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

    final rawAmount = _rawIndex(4);
    final amount = rawAmount.isNotEmpty
        ? rawAmount
        : StatementsShared.entryText(entry, ['amount']);
    final amountValue = StatementsFormatters.parseAmount(amount) ?? 0;
    final isNegative = amountValue < 0;
    final positiveColor =
        isDark ? const Color(0xFF66BB6A) : const Color(0xFF2E7D32);
    final negativeColor =
        isDark ? const Color(0xFFEF5350) : const Color(0xFFC62828);
    final amountColor = isNegative ? negativeColor : positiveColor;

    // Linked reference / "no procede" / unlinked state.
    final invoiceNumbers = _toStringList(entry['invoiceNumbers']);
    final expenseDocumentNumbers = _toStringList(
      entry['expenseDocumentNumbers'] ?? entry['expenseNumbers'],
    );
    final invoiceNumber =
        (entry['invoiceNumber'] ?? entry['invoice_number'])?.toString().trim() ??
            '';
    final expenseNumber =
        (entry['expenseNumber'] ?? entry['expense_number'])?.toString().trim() ??
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

    final dateDisplay = date.isNotEmpty
        ? StatementsFormatters.formatDate(context, date)
        : StatementsFormatters.formatDate(context, valueDate);

    String? statusLabel;
    Color statusColor = cs.onSurfaceVariant;
    if (hasNoProcede) {
      statusLabel = 'No procede';
      statusColor = cs.tertiary;
    } else if (docNumber.isNotEmpty) {
      statusLabel = docNumber;
      statusColor = cs.primary;
    } else if (isUnlinked) {
      statusLabel = l.statementsUnlinked;
      statusColor = cs.onSurfaceVariant;
    }

    final descStyle = t.bodyMedium.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: cs.onSurface,
    );
    final amountStyle = t.bodyMedium.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: amountColor,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final metaStyle = t.bodySmall.copyWith(
      fontSize: 11,
      color: cs.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            desc.isEmpty ? l.statementsNoDescription : desc,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: descStyle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          flex: 2,
                          child: Text(
                            StatementsFormatters.formatCurrency(context, amount),
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: amountStyle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            dateDisplay,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: metaStyle,
                          ),
                        ),
                        if (statusLabel != null) ...[
                          Text(' · ', style: metaStyle),
                          Flexible(
                            child: Text(
                              statusLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: metaStyle.copyWith(color: statusColor),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                size: 14,
                color: cs.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
