import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/group_model/worker/worker.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class WorkerAppBarTitle extends StatelessWidget {
  const WorkerAppBarTitle({
    super.key,
    required this.group,
    required this.worker,
    required this.year,
    required this.month,
    this.totals,
    this.compact = false,
    this.advanceAmount,
    this.currency,
    this.onOpenAdvanceDialog,
  });

  final Group group;
  final Worker worker;
  final int year;
  final int month;
  final Map<String, dynamic>? totals;
  final bool compact;
  final double? advanceAmount;
  final String? currency;
  final VoidCallback? onOpenAdvanceDialog;

  bool _isEs(BuildContext context) =>
      Localizations.localeOf(context).languageCode.toLowerCase() == 'es';

  String _advanceLabel(BuildContext context) =>
      _isEs(context) ? 'Anticipo' : 'Advance';

  String _toPayLabel(BuildContext context) =>
      _isEs(context) ? 'A pagar' : 'To pay';

  num _toNum(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value;
    return num.tryParse(value.toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final locale = Localizations.localeOf(context).toString();
    final monthLabel = DateFormat.yMMMM(locale).format(DateTime(year, month));
    final l = AppLocalizations.of(context)!;
    final isInactive = worker.status == WorkerStatus.archived;
    final statusLabel = isInactive ? l.statusInactive : l.statusActive;
    final effectiveCurrency =
        ((currency ?? totals?['currency'] ?? worker.currency) ?? '')
            .toString()
            .trim();
    final grossPayNum = _toNum(totals?['grossPay'] ?? totals?['totalPay']);
    final advanceNum = _toNum(totals?['advanceAmount'] ?? advanceAmount);
    final netPayNum = _toNum(totals?['netPay'] ?? (grossPayNum - advanceNum));
    final safeNetPayNum = netPayNum < 0 ? 0 : netPayNum;
    final payableSummary = totals == null
        ? '${group.name} • $monthLabel'
        : '${_toPayLabel(context)}: ${safeNetPayNum.toStringAsFixed(2)}'
            '${effectiveCurrency.isEmpty ? '' : ' $effectiveCurrency'} • $monthLabel';

    if (compact) {
      return Row(
        children: [
          Flexible(
            fit: FlexFit.loose,
            child: Text(
              worker.displayName ?? 'Worker',
              style: t.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          _StatusChip(label: statusLabel, inactive: isInactive),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              payableSummary,
              style: t.bodySmall.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onOpenAdvanceDialog != null && advanceAmount != null)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: TextButton.icon(
                onPressed: onOpenAdvanceDialog,
                icon: const Icon(Icons.request_quote_outlined, size: 14),
                label: Text(
                  '${_advanceLabel(context)}: ${advanceAmount!.toStringAsFixed(2)}'
                  '${(currency ?? '').trim().isEmpty ? '' : ' ${currency!.trim()}'}',
                  style: t.caption.copyWith(fontWeight: FontWeight.w700),
                ),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                ),
              ),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                worker.displayName ?? 'Worker',
                style: t.titleLarge.copyWith(fontWeight: FontWeight.w700, fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            _StatusChip(label: statusLabel, inactive: isInactive),
          ],
        ),
        Text(
          payableSummary,
          style: t.bodySmall.copyWith(
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.6),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool inactive;

  const _StatusChip({
    required this.label,
    required this.inactive,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final bg = inactive
        ? cs.surfaceContainerHighest
        : Colors.green.withValues(alpha: 0.12);
    final fg = inactive
        ? cs.onSurface.withValues(alpha: 0.7)
        : Colors.green.shade700;
    final border =
        inactive ? cs.outlineVariant : Colors.green.withValues(alpha: 0.3);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: t.caption.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
