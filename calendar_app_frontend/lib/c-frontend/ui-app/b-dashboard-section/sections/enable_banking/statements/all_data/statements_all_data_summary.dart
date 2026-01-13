import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class StatementsAllDataSummary extends StatelessWidget {
  const StatementsAllDataSummary({
    super.key,
    required this.totalAmount,
    required this.lastBalance,
    required this.lastBalanceDate,
    required this.totalCount,
  });

  final String totalAmount;
  final String lastBalance;
  final String lastBalanceDate;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final typography = AppTypography.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.statementsAllDataSummaryTitle,
            style: typography.bodySmall.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _SummaryBlock(
                title: l.statementsTotalAmount,
                value: totalAmount,
                valueStyle:
                    typography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
              _SummaryBlock(
                title: l.statementsTotalCount,
                value: totalCount.toString(),
                valueStyle:
                    typography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
              _SummaryBlock(
                title: l.statementsLastBalance,
                value: lastBalance,
                subtitle: lastBalanceDate.isEmpty
                    ? ''
                    : l.statementsLastBalanceDate(lastBalanceDate),
                valueStyle: typography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryBlock extends StatelessWidget {
  const _SummaryBlock({
    required this.title,
    required this.value,
    required this.valueStyle,
    this.subtitle = '',
  });

  final String title;
  final String value;
  final TextStyle valueStyle;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final typography = AppTypography.of(context);
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: typography.bodySmall),
          const SizedBox(height: 6),
          Text(value, style: valueStyle),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: typography.bodySmall),
          ],
        ],
      ),
    );
  }
}
