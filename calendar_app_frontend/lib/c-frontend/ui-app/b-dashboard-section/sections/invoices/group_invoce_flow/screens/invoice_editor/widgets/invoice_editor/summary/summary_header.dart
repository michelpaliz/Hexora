import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';

import 'summary_chips.dart';

class InvoiceSummaryHeader extends StatelessWidget {
  final String invoiceNumber;
  final String status;

  const InvoiceSummaryHeader({
    super.key,
    required this.invoiceNumber,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            invoiceNumber,
            style: t.titleLarge.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        InvoiceSummaryStatusChip(status: status),
      ],
    );
  }
}

