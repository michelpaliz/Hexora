import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class InvoiceListItem extends StatelessWidget {
  final Invoice invoice;
  final GroupClient client;
  final VoidCallback? onTap;

  const InvoiceListItem({
    super.key,
    required this.invoice,
    required this.client,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final l = AppLocalizations.of(context)!;
    final dateLabel = invoice.registeredAt != null
        ? DateFormat.yMMMd(l.localeName)
            .add_Hm()
            .format(invoice.registeredAt!.toLocal())
        : l.invoiceRegisteredUnknown;
    final total = invoice.total ??
        invoice.lines.fold<num>(0, (sum, line) => sum + (line.lineTotal ?? 0));
    final totalLabel =
        total > 0 ? NumberFormat.simpleCurrency(name: '').format(total) : null;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: cs.primary.withOpacity(0.12),
                child: Icon(Icons.receipt_long_outlined, color: cs.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invoice.invoiceNumber,
                      style: t.bodyMedium.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      client.name,
                      style: t.bodySmall.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateLabel,
                      style: t.bodySmall.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    if (totalLabel != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${l.invoiceTotalLabel}: $totalLabel',
                        style: t.bodySmall.copyWith(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatusPill(status: invoice.status ?? 'draft'),
                  const SizedBox(height: 8),
                  Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final normalized = status.toLowerCase();
    final bool issued = normalized.contains('issue');
    final Color bg = issued ? cs.secondaryContainer : cs.surfaceVariant;
    final Color fg = issued ? cs.onSecondaryContainer : cs.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
      ),
      child: Text(
        normalized.isEmpty ? 'draft' : normalized,
        style: t.bodySmall.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
          letterSpacing: .2,
        ),
      ),
    );
  }
}
