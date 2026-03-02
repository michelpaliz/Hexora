import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';

class InvoiceDetailHeader extends StatelessWidget {
  final String clientName;
  final String invoiceNumber;
  final bool hasRecurrence;
  final String recurrenceLabel;
  final String? occurrenceLabel;
  final String recurrenceButtonLabel;
  final ValueChanged<String>? onOpenRecurringSeries;
  final String? recurringSeriesId;
  final String status;

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
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
              Text(
                clientName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.bodyLarge.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                invoiceNumber,
                style: t.bodySmall.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
