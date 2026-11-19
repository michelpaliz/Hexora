import 'package:flutter/material.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/models/workers/worker.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/l10n/build_context_locale.dart';
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
    this.identityOnly = false,
    this.financialOnly = false,
    this.showAdvance = true,
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
  final bool identityOnly;
  final bool financialOnly;
  final bool showAdvance;

  bool _isEs(BuildContext context) => context.isSpanishLocale;

  String _advanceLabel(BuildContext context) =>
      _isEs(context) ? 'Anticipo' : 'Advance';

  String _toPayLabel(BuildContext context) =>
      _isEs(context) ? 'A pagar' : 'To pay';

  num _toNum(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value;
    return num.tryParse(value.toString()) ?? 0;
  }

  String _formatMoney(BuildContext context, num value, String currency) {
    final locale = Localizations.localeOf(context).toString();
    final symbol = currency.toUpperCase() == 'EUR' ? '\u20AC' : currency;
    return NumberFormat.currency(
      locale: locale,
      symbol: symbol,
      decimalDigits: 2,
    ).format(value);
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
      final identity = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Tooltip(
              message: worker.displayName ?? 'Worker',
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
          ),
          const SizedBox(width: 6),
          _StatusChip(label: statusLabel, inactive: isInactive),
        ],
      );
      final financial = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _FinancialMetric(
            label: _toPayLabel(context),
            value: _formatMoney(context, safeNetPayNum, effectiveCurrency),
            emphasized: true,
          ),
          if (showAdvance) ...[
            const SizedBox(width: 10),
            Container(
              width: 1,
              height: 18,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            const SizedBox(width: 10),
            _FinancialMetric(
              label: _advanceLabel(context),
              value: _formatMoney(context, advanceNum, effectiveCurrency),
              onTap: onOpenAdvanceDialog,
            ),
          ],
        ],
      );
      if (identityOnly) return identity;
      if (financialOnly) return financial;
      return Row(
        children: [
          Flexible(child: identity),
          const SizedBox(width: 8),
          Expanded(child: Center(child: financial)),
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

class _FinancialMetric extends StatelessWidget {
  const _FinancialMetric({
    required this.label,
    required this.value,
    this.emphasized = false,
    this.onTap,
  });

  final String label;
  final String value;
  final bool emphasized;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final typography = AppTypography.of(context);
    final content = Text.rich(
      TextSpan(children: [
        TextSpan(
          text: '$label: ',
          style: typography.caption.copyWith(color: colors.onSurfaceVariant),
        ),
        TextSpan(
          text: value,
          style: typography.bodySmall.copyWith(
            color: emphasized ? colors.primary : colors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ]),
      maxLines: 1,
    );
    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
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
