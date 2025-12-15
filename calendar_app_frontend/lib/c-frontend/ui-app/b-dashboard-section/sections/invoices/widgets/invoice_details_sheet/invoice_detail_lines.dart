import 'package:flutter/material.dart';
import 'package:hexora/a-models/invoice/invoice_line.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/widgets/invoice_lines_preview.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class InvoiceDetailLines extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<InvoiceLine> lines;
  final Future<void> Function() onRefresh;
  final String totalLabel;

  const InvoiceDetailLines({
    super.key,
    required this.loading,
    required this.error,
    required this.lines,
    required this.onRefresh,
    required this.totalLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l.invoiceLinesTitle,
              style: t.bodyMedium.copyWith(fontWeight: FontWeight.w800),
            ),
            IconButton(
              tooltip: l.refreshButton,
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        if (loading) const LinearProgressIndicator(minHeight: 2),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              error!,
              style: t.bodySmall.copyWith(color: cs.error),
            ),
          ),
        if (!loading) ...[
          const SizedBox(height: 6),
          InvoiceLinesPreview(lines: lines),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              totalLabel,
              style: t.bodyMedium.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
