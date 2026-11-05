import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';

class BillingDocumentType extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const BillingDocumentType({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.billingDocumentType),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'invoice', label: Text(l.documentTypeInvoice)),
            ButtonSegment(value: 'receipt', label: Text(l.documentTypeReceipt)),
          ],
          selected: {value},
          onSelectionChanged: (selection) => onChanged(selection.first),
        ),
      ],
    );
  }
}
