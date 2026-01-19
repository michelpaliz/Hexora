import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';

import '../input_border.dart';

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

    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: buildInputDecoration(
        context,
        label: l.billingDocumentType,
        isFilled: true,
      ),
      items: [
        DropdownMenuItem(value: 'invoice', child: Text(l.documentTypeInvoice)),
        DropdownMenuItem(value: 'receipt', child: Text(l.documentTypeReceipt)),
      ],
      onChanged: (v) => onChanged(v ?? 'invoice'),
    );
  }
}
