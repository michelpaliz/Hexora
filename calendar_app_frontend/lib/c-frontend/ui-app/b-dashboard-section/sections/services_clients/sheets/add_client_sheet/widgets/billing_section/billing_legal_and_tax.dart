import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

import '../../add_client_controller.dart';
import '../input_border.dart';

class BillingLegalAndTax extends StatelessWidget {
  final AddClientController c;
  final bool requireBilling;
  final bool showValidation;
  final VoidCallback onFieldChanged;
  final ValueChanged<String> onFieldBlur;

  const BillingLegalAndTax({
    super.key,
    required this.c,
    required this.requireBilling,
    required this.showValidation,
    required this.onFieldChanged,
    required this.onFieldBlur,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final typo = AppTypography.of(context);

    return Column(
      children: [
        Focus(
          onFocusChange: (hasFocus) {
            if (!hasFocus) onFieldBlur('billingLegalName');
          },
          child: TextFormField(
            controller: c.billingLegalName,
            style: typo.bodyMedium,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: buildInputDecoration(
              context,
              label: l.billingLegalName,
              prefixIcon: const Icon(Icons.badge_outlined),
              isRequired: c.isBillingRequired('billingLegalName'),
              isFilled: c.billingLegalName.text.trim().isNotEmpty,
              showCheck: c.isBillingRequired('billingLegalName') &&
                  c.billingLegalName.text.trim().isNotEmpty,
            ),
            onChanged: (_) => onFieldChanged(),
            validator: (v) {
              if (!requireBilling ||
                  !c.isBillingRequired('billingLegalName')) {
                return null;
              }
              if (!c.shouldShowError('billingLegalName', showValidation)) {
                return null;
              }
              return (v == null || v.trim().isEmpty)
                  ? l.fieldIsRequired
                  : null;
            },
          ),
        ),
        const SizedBox(height: 10),
        Focus(
          onFocusChange: (hasFocus) {
            if (!hasFocus) onFieldBlur('billingTaxId');
          },
          child: TextFormField(
            controller: c.billingTaxId,
            style: typo.bodyMedium,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: buildInputDecoration(
              context,
              label: l.billingTaxId,
              prefixIcon: const Icon(Icons.numbers),
              isRequired: c.isBillingRequired('billingTaxId'),
              isFilled: c.billingTaxId.text.trim().isNotEmpty,
              showCheck: c.isBillingRequired('billingTaxId') &&
                  c.billingTaxId.text.trim().isNotEmpty,
            ),
            onChanged: (_) => onFieldChanged(),
            validator: (v) {
              if (!requireBilling ||
                  !c.isBillingRequired('billingTaxId')) {
                return null;
              }
              if (!c.shouldShowError('billingTaxId', showValidation)) {
                return null;
              }
              return (v == null || v.trim().isEmpty)
                  ? l.fieldIsRequired
                  : null;
            },
          ),
        ),
      ],
    );
  }
}
