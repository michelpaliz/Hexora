import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class InvoiceDetailHistoryCard extends StatefulWidget {
  final String title;
  final List<dynamic> history;
  final String Function(dynamic) formatWhen;

  const InvoiceDetailHistoryCard({
    super.key,
    required this.title,
    required this.history,
    required this.formatWhen,
  });

  @override
  State<InvoiceDetailHistoryCard> createState() =>
      _InvoiceDetailHistoryCardState();
}

class _InvoiceDetailHistoryCardState extends State<InvoiceDetailHistoryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final hasEntries = widget.history.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: hasEntries ? () => setState(() => _expanded = !_expanded) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.history,
                    size: 16,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.title,
                    style: t.bodySmall.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (hasEntries) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${widget.history.length}',
                        style: t.bodySmall.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (hasEntries)
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 200),
                      turns: _expanded ? 0.5 : 0,
                      child: Icon(
                        Icons.expand_more,
                        size: 16,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                ],
              ),
              if (!hasEntries) ...[
                const SizedBox(height: 4),
                Text(
                  l.invoiceChangeHistoryEmpty,
                  style: t.bodySmall.copyWith(
                    color: cs.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              if (_expanded && hasEntries) ...[
                const SizedBox(height: 6),
                ...widget.history.map((h) {
                  final when = widget.formatWhen(h);
                  final oldVal = (h.oldValue ?? '-').trim();
                  final newVal = (h.newValue ?? '-').trim();
                  final fieldLabel =
                      (h.field ?? '').toString().trim().isEmpty
                          ? l.details
                          : h.field.toString();
                  final reason = (h.reason ?? '').toString().trim();
                  final userId = (h.userId ?? '').toString().trim();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.circle,
                          size: 6,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$fieldLabel: $oldVal → $newVal',
                                style: t.bodySmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                [
                                  when,
                                  if (reason.isNotEmpty)
                                    '${l.reasonLabel}: $reason',
                                  if (userId.isNotEmpty)
                                    '${l.updatedByLabel}: $userId',
                                ].join(' · '),
                                style: t.bodySmall.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
