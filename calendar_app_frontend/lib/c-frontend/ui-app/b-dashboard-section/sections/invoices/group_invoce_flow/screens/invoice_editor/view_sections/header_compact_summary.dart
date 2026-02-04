part of '../invoice_editor_screen.dart';

class _HeaderCompactSummary extends StatelessWidget {
  final String clientName;
  final String currency;
  final DateTime? invoiceDate;
  final DateTime? dueDate;

  const _HeaderCompactSummary({
    required this.clientName,
    required this.currency,
    required this.invoiceDate,
    required this.dueDate,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final dateFmt = DateFormat.yMMMd();
    final inv = invoiceDate == null ? '-' : dateFmt.format(invoiceDate!);
    final due = dueDate == null ? '-' : dateFmt.format(dueDate!);

    Widget currencyPill() {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          currency.toUpperCase(),
          style: t.bodySmall.copyWith(
            color: cs.onPrimaryContainer,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.6,
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                clientName,
                style: t.bodyMedium.copyWith(fontWeight: FontWeight.w900),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                '${l.invoiceDateLabel}: $inv • ${l.invoiceDueDateLabel}: $due',
                style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        currencyPill(),
      ],
    );
  }
}
