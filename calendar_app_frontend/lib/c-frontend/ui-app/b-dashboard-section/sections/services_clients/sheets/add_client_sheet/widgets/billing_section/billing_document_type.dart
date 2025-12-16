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
    final cs = Theme.of(context).colorScheme;
    final inputBorder = buildInputBorder(context);

    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: l.billingDocumentType,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
      ),
      items: [
        DropdownMenuItem(value: 'invoice', child: Text(l.documentTypeInvoice)),
        DropdownMenuItem(value: 'receipt', child: Text(l.documentTypeReceipt)),
      ],
      onChanged: (v) => onChanged(v ?? 'invoice'),
    );
  }
}
