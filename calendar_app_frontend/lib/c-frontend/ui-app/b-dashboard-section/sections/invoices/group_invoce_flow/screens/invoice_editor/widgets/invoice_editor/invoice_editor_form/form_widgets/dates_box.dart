import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class DatesBox extends StatelessWidget {
  final DateTime? invoiceDate;
  final DateTime? dueDate;
  final VoidCallback onPickInvoiceDate;
  final VoidCallback onPickDueDate;

  const DatesBox({
    super.key,
    required this.invoiceDate,
    required this.dueDate,
    required this.onPickInvoiceDate,
    required this.onPickDueDate,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SizedBox(
        height: 72,
        child: Row(
          children: [
            Expanded(
              child: DateMini(
                label: l.invoiceDateLabel,
                value: invoiceDate,
                onPick: onPickInvoiceDate,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DateMini(
                label: l.invoiceDueDateLabel,
                value: dueDate,
                onPick: onPickDueDate,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DateMini extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onPick;

  const DateMini({
    super.key,
    required this.label,
    required this.value,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onPick,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: t.bodySmall.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    value != null ? DateFormat.yMMMd().format(value!) : '-',
                    style: t.bodySmall.copyWith(fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  l.change,
                  style: t.bodySmall.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
