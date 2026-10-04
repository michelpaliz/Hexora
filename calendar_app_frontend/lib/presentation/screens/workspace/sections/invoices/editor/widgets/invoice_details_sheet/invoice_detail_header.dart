import 'package:flutter/material.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
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
  final String currency;
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
    this.currency = 'EUR',
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
    final totalFormatted = NumberFormat.simpleCurrency(
      locale: Localizations.localeOf(context).toString(),
      name: currency,
    ).format(total);
    final normalizedType = (invoiceType ?? '').trim().toLowerCase();
    final showTypeBadge =
        normalizedType == 'advance' || normalizedType == 'final';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
            builder: (context, constraints) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Tooltip(
                        message: clientName,
                        child: Text(
                          clientName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.bodyMedium.copyWith(
                              fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints:
                          BoxConstraints(maxWidth: constraints.maxWidth * 0.4),
                      child: Text(
                        totalFormatted,
                        textAlign: TextAlign.end,
                        style: t.bodyMedium.copyWith(
                          fontSize: 14,
                          color: cs.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                )),
        const SizedBox(height: 3),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '${isEs ? 'Factura' : 'Invoice'} $invoiceNumber',
              style: t.bodySmall.copyWith(
                fontSize: 11,
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 12, color: statusColor),
                  const SizedBox(width: 4),
                  Text(
                    statusLabel,
                    style: t.bodySmall.copyWith(
                      fontSize: 11,
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (showTypeBadge)
              Text(
                normalizedType == 'advance'
                    ? (isEs ? 'ANTICIPO' : 'ADVANCE')
                    : 'FINAL',
                style: t.bodySmall.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
