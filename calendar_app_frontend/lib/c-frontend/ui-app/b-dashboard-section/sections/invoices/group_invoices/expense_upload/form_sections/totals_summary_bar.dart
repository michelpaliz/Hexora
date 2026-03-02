import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hexora/b-backend/expenses/expenses_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/widgets/common_views.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ExpenseTotalsSummaryBar extends StatelessWidget {
  final String subtotal;
  final String tax;
  final String total;

  const ExpenseTotalsSummaryBar({
    super.key,
    required this.subtotal,
    required this.tax,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          _SummaryItem(
            label: l.expenseUploadLinesSubtotalLabel,
            value: subtotal,
          ),
          const SizedBox(width: 10),
          _SummaryItem(
            label: l.expenseUploadLinesTaxLabel,
            value: tax,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SummaryItem(
              label: l.expenseUploadLinesTotalLabel,
              value: total,
              highlight: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _SummaryItem({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final style = highlight
        ? t.bodySmall.copyWith(fontWeight: FontWeight.w800, fontSize: 13)
        : t.bodySmall.copyWith(fontWeight: FontWeight.w600);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: t.bodySmall.copyWith(
            color: cs.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
        Text(value, style: style),
      ],
    );
  }
}
