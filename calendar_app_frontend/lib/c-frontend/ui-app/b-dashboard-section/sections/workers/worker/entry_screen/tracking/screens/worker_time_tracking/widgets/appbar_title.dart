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
    final toPayText =
        '${_toPayLabel(context)}: ${safeNetPayNum.toStringAsFixed(2)}'
        '${effectiveCurrency.isEmpty ? '' : ' $effectiveCurrency'}';
    final advanceText =
        '${_advanceLabel(context)}: ${advanceNum.toStringAsFixed(2)}'
        '${effectiveCurrency.isEmpty ? '' : ' $effectiveCurrency'}';
    final payableSummary = totals == null
        ? '${group.name} • $monthLabel'
        : '${_toPayLabel(context)}: ${safeNetPayNum.toStringAsFixed(2)}'
            '${effectiveCurrency.isEmpty ? '' : ' $effectiveCurrency'} • $monthLabel';

    if (compact) {
      return Row(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
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
            child: Tooltip(
              message: totals == null
                  ? payableSummary
                  : '$toPayText - $advanceText - $monthLabel',
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _InlineMetric(
                      icon: Icons.account_balance_wallet_outlined,
                      label: totals == null ? payableSummary : toPayText,
                    ),
                    if (onOpenAdvanceDialog != null) ...[
                      const SizedBox(width: 8),
                      _InlineMetric(
                        icon: Icons.request_quote_outlined,
                        label: advanceText,
                        onTap: onOpenAdvanceDialog,
                      ),
                    ],
                  ],
                ),
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
                style: t.titleLarge
                    .copyWith(fontWeight: FontWeight.w700, fontSize: 16),
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
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _InlineMetric extends StatelessWidget {
  const _InlineMetric({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: cs.onSurfaceVariant.withValues(alpha: 0.78),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          maxLines: 1,
          style: t.bodySmall.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );

    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: content,
      ),
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
    final fg =
        inactive ? cs.onSurface.withValues(alpha: 0.7) : Colors.green.shade700;
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
