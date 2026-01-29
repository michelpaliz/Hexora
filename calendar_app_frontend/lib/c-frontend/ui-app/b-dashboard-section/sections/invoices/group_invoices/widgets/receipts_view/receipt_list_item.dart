import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/receipt/receipt.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class ReceiptListItem extends StatelessWidget {
  final Receipt receipt;
  final GroupClient client;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const ReceiptListItem({
    super.key,
    required this.receipt,
    required this.client,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final l = AppLocalizations.of(context)!;

    final date = receipt.registeredAt ?? receipt.issueDate;
    final dateLabel = date != null
        ? DateFormat.yMMMd(l.localeName).add_Hm().format(date.toLocal())
        : l.receiptDateUnknown;

    final total = receipt.total ??
        receipt.lines.fold<num>(
          0,
          (sum, line) =>
              sum + ((line.total ?? (line.quantity * line.unitPrice))),
        );
    final money = NumberFormat.currency(locale: l.localeName, symbol: '€');
    final totalLabel = money.format(total);

    final number = (receipt.receiptNumber?.trim().isNotEmpty == true)
        ? receipt.receiptNumber!.trim()
        : l.receiptDraftNumberPlaceholder;

    return Card(
      elevation: 1,
      color: cs.surface,
      shadowColor: ThemeColors.cardShadow(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: cs.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: cs.tertiary.withValues(alpha: 0.08),
                child: Icon(
                  Icons.description_outlined,
                  color: cs.onSurfaceVariant,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            client.name,
                            style: t.bodyMedium.copyWith(
                              fontWeight: FontWeight.w900,
                              color: cs.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          totalLabel,
                          style: t.bodyLarge.copyWith(
                            fontWeight: FontWeight.w900,
                            color: cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _StatusPill(status: receipt.status ?? 'draft'),
                    const SizedBox(height: 4),
                    Text(
                      [
                        number,
                        dateLabel,
                        '${l.receiptLinesTitle}: ${receipt.lines.length}',
                      ].join(' · '),
                      style: t.bodySmall.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (onDelete != null)
                    IconButton(
                      tooltip: l.delete,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.delete_outline),
                      color: cs.error.withValues(alpha: 0.8),
                      onPressed: onDelete,
                    )
                  else
                    Icon(
                      Icons.chevron_right,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.6),
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

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final normalized = status.toLowerCase();
    final bool issued = normalized.contains('issue');
    final Color bg = issued
        ? cs.secondaryContainer
        : cs.surface.withValues(alpha: 0.5);
    final Color fg = issued ? cs.onSecondaryContainer : cs.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: issued ? 0.2 : 0.25),
        ),
      ),
      child: Text(
        normalized.isEmpty ? 'draft' : normalized,
        style: t.bodySmall.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
          letterSpacing: .1,
        ),
      ),
    );
  }
}
