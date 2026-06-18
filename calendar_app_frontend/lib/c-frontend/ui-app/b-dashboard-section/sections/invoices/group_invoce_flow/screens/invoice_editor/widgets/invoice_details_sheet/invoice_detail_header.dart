import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:intl/intl.dart';

class InvoiceDetailHeader extends StatelessWidget {
  final String clientName;
  final String invoiceNumber;
  final bool hasRecurrence;
  final String recurrenceLabel;
  final String? occurrenceLabel;
  final String recurrenceButtonLabel;
  final ValueChanged<String>? onOpenRecurringSeries;
  final String? recurringSeriesId;
  final String statusLabel;
  final Color statusColor;
  final IconData statusIcon;
  final double total;
  final String? invoiceType;
  final String? issuedByLabel;
  final String? issuedAtLabel;

  const InvoiceDetailHeader({
    super.key,
    required this.clientName,
    required this.invoiceNumber,
    required this.hasRecurrence,
    required this.recurrenceLabel,
    required this.occurrenceLabel,
    required this.recurrenceButtonLabel,
    required this.onOpenRecurringSeries,
    required this.recurringSeriesId,
    required this.statusLabel,
    required this.statusColor,
    required this.statusIcon,
    required this.total,
    this.invoiceType,
    this.issuedByLabel,
    this.issuedAtLabel,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final isEs =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'es';
    final totalFormatted = NumberFormat.simpleCurrency(name: '').format(total);
    final normalizedType = (invoiceType ?? '').trim().toLowerCase();
    final showTypeBadge =
        normalizedType == 'advance' || normalizedType == 'final';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Icon(
            Icons.receipt_long_outlined,
            color: cs.onSurfaceVariant,
            size: 16,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: client name + status badges + total
              Row(
                children: [
                  Expanded(
                    child: Text(
                      clientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodyLarge.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, size: 11, color: statusColor),
                              const SizedBox(width: 4),
                              Text(
                                statusLabel,
                                style: t.bodySmall.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (showTypeBadge) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              normalizedType == 'advance'
                                  ? (isEs ? 'ANTICIPO' : 'ADVANCE')
                                  : (isEs ? 'FINAL' : 'FINAL'),
                              style: t.bodySmall.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                        if (total > 0) ...[
                          const SizedBox(width: 10),
                          Text(
                            totalFormatted,
                            style: t.bodyMedium.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              // Row 2: invoice number + issuer metadata
              Row(
                children: [
                  Expanded(
                    child: Text(
                      [
                        invoiceNumber,
                        if ((issuedByLabel ?? '').trim().isNotEmpty)
                          issuedByLabel!.trim(),
                        if ((issuedAtLabel ?? '').trim().isNotEmpty)
                          issuedAtLabel!.trim(),
                      ].join('  ·  '),
                      style: t.bodySmall.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
