import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

import '../../add_client_controller.dart';
import '../input_border.dart';

class BillingAddressForm extends StatelessWidget {
  final AddClientController c;
  final bool requireBilling;
  final bool showValidation;
  final VoidCallback onFieldChanged;
  final ValueChanged<String> onFieldBlur;

  const BillingAddressForm({
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
            if (!hasFocus) onFieldBlur('billingStreet');
          },
          child: TextFormField(
            controller: c.billingStreet,
            style: typo.bodyMedium,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: buildInputDecoration(
              context,
              label: l.addressStreet,
              prefixIcon: const Icon(Icons.home_outlined),
              isRequired: requireBilling,
              isFilled: c.billingStreet.text.trim().isNotEmpty,
              showCheck:
                  requireBilling && c.billingStreet.text.trim().isNotEmpty,
            ),
            onChanged: (_) => onFieldChanged(),
            validator: (v) {
              if (!requireBilling) return null;
              if (!c.shouldShowError('billingStreet', showValidation)) {
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
            if (!hasFocus) onFieldBlur('billingExtra');
          },
          child: TextFormField(
            controller: c.billingExtra,
            style: typo.bodyMedium,
            decoration: buildInputDecoration(
              context,
              label: l.addressExtra,
              prefixIcon: const Icon(Icons.location_city_outlined),
              isFilled: c.billingExtra.text.trim().isNotEmpty,
            ),
            onChanged: (_) => onFieldChanged(),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Focus(
                onFocusChange: (hasFocus) {
                  if (!hasFocus) onFieldBlur('billingCity');
                },
                child: TextFormField(
                  controller: c.billingCity,
                  style: typo.bodyMedium,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: buildInputDecoration(
                    context,
                    label: l.addressCity,
                    prefixIcon: const Icon(Icons.location_city_rounded),
                    isRequired: c.isBillingRequired('billingCity'),
                    isFilled: c.billingCity.text.trim().isNotEmpty,
                    showCheck: c.isBillingRequired('billingCity') &&
                        c.billingCity.text.trim().isNotEmpty,
                  ),
                  onChanged: (_) => onFieldChanged(),
                  validator: (v) {
                    if (!requireBilling ||
                        !c.isBillingRequired('billingCity')) {
                      return null;
                    }
                    if (!c.shouldShowError('billingCity', showValidation)) {
                      return null;
                    }
                    return (v == null || v.trim().isEmpty)
                        ? l.fieldIsRequired
                        : null;
                  },
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Focus(
                onFocusChange: (hasFocus) {
                  if (!hasFocus) onFieldBlur('billingProvince');
                },
                child: TextFormField(
                  controller: c.billingProvince,
                  style: typo.bodyMedium,
                  decoration: buildInputDecoration(
                    context,
                    label: l.addressProvince,
                    prefixIcon: const Icon(Icons.map_outlined),
                    isFilled: c.billingProvince.text.trim().isNotEmpty,
                  ),
                  onChanged: (_) => onFieldChanged(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Focus(
                onFocusChange: (hasFocus) {
                  if (!hasFocus) onFieldBlur('billingPostal');
                },
                child: TextFormField(
                  controller: c.billingPostal,
                  style: typo.bodyMedium,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: buildInputDecoration(
                    context,
                    label: l.addressPostalCode,
                    prefixIcon: const Icon(Icons.local_post_office_outlined),
                    isRequired: c.isBillingRequired('billingPostal'),
                    isFilled: c.billingPostal.text.trim().isNotEmpty,
                    showCheck: c.isBillingRequired('billingPostal') &&
                        c.billingPostal.text.trim().isNotEmpty,
                  ),
                  onChanged: (_) => onFieldChanged(),
                  validator: (v) {
                    if (!requireBilling ||
                        !c.isBillingRequired('billingPostal')) {
                      return null;
                    }
                    if (!c.shouldShowError('billingPostal', showValidation)) {
                      return null;
                    }
                    return (v == null || v.trim().isEmpty)
                        ? l.fieldIsRequired
                        : null;
                  },
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Focus(
                onFocusChange: (hasFocus) {
                  if (!hasFocus) onFieldBlur('billingCountry');
                },
                child: TextFormField(
                  controller: c.billingCountry,
                  style: typo.bodyMedium,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: buildInputDecoration(
                    context,
                    label: l.addressCountry,
                    prefixIcon: const Icon(Icons.public),
                    isRequired: c.isBillingRequired('billingCountry'),
                    isFilled: c.billingCountry.text.trim().isNotEmpty,
                    showCheck: c.isBillingRequired('billingCountry') &&
                        c.billingCountry.text.trim().isNotEmpty,
                  ),
                  onChanged: (_) => onFieldChanged(),
                  validator: (v) {
                    if (!requireBilling ||
                        !c.isBillingRequired('billingCountry')) {
                      return null;
                    }
                    if (!c.shouldShowError('billingCountry', showValidation)) {
                      return null;
                    }
                    return (v == null || v.trim().isEmpty)
                        ? l.fieldIsRequired
                        : null;
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
