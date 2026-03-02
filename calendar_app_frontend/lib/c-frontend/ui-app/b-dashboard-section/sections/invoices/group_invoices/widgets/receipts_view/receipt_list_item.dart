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
  final VoidCallback? onIssue;
  final VoidCallback? onDelete;
  final VoidCallback? onDownload;

  const ReceiptListItem({
    super.key,
    required this.receipt,
    required this.client,
    this.onTap,
    this.onIssue,
    this.onDelete,
    this.onDownload,
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
    final money = NumberFormat.currency(locale: l.localeName, symbol: 'EUR');
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
            crossAxisAlignment: CrossAxisAlignment.center,
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
                        const SizedBox(width: 8),
                        _StatusPill(status: receipt.status ?? 'draft'),
                        const SizedBox(width: 10),
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
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (onDownload != null)
                    _ActionIconButton(
                      icon: Icons.download_outlined,
                      tooltip: l.download,
                      color: cs.onSurfaceVariant,
                      onPressed: onDownload!,
                    ),
                  if (onIssue != null)
                    _ActionIconButton(
                      icon: Icons.publish_outlined,
                      tooltip: l.receiptIssueCta,
                      color: cs.tertiary,
                      onPressed: onIssue!,
                    ),
                  if ((onIssue != null || onDownload != null) &&
                      onDelete != null)
                    Container(
                      width: 1,
                      height: 20,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      color: cs.outlineVariant.withValues(alpha: 0.3),
                    ),
                  if (onDelete != null)
                    _ActionIconButton(
                      icon: Icons.delete_outline,
                      tooltip: l.delete,
                      color: cs.error,
                      onPressed: onDelete!,
                    ),
                  if (onIssue == null && onDelete == null && onDownload == null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
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
    final l = AppLocalizations.of(context)!;
    final normalized = status.toLowerCase();
    final bool issued = normalized.contains('issue');
    final bool draft = normalized.contains('draft') || normalized.isEmpty;
    final Color bg =
        issued ? cs.secondaryContainer : cs.surface.withValues(alpha: 0.5);
    final Color fg = issued ? cs.onSecondaryContainer : cs.onSurfaceVariant;
    final label =
        issued ? l.statusIssued : (draft ? l.statusDraft : normalized);
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
        label,
        style: t.bodySmall.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
          letterSpacing: .1,
        ),
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onPressed;

  const _ActionIconButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      padding: const EdgeInsets.all(4),
      splashRadius: 18,
      icon: Icon(icon, size: 20),
      color: color.withValues(alpha: 0.8),
      onPressed: onPressed,
    );
  }
}
