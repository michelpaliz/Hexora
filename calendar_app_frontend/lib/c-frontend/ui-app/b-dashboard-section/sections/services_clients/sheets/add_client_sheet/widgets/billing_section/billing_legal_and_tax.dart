import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

import '../../add_client_controller.dart';
import '../input_border.dart';

class BillingLegalAndTax extends StatelessWidget {
  final AddClientController c;

  const BillingLegalAndTax({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);
    final inputBorder = buildInputBorder(context);

    return Column(
      children: [
        TextFormField(
          controller: c.billingLegalName,
          style: typo.bodyMedium,
          decoration: InputDecoration(
            labelText: l.billingLegalName,
            prefixIcon: const Icon(Icons.badge_outlined),
            enabledBorder: inputBorder,
            focusedBorder: inputBorder.copyWith(
              borderSide: BorderSide(color: cs.primary, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: c.billingTaxId,
          style: typo.bodyMedium,
          decoration: InputDecoration(
            labelText: l.billingTaxId,
            prefixIcon: const Icon(Icons.numbers),
            enabledBorder: inputBorder,
            focusedBorder: inputBorder.copyWith(
              borderSide: BorderSide(color: cs.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
