import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

import '../../add_client_controller.dart';
import '../input_border.dart';

class BillingContactForm extends StatelessWidget {
  final AddClientController c;
  final bool requireBilling;
  final bool showValidation;
  final VoidCallback onFieldChanged;
  final ValueChanged<String> onFieldBlur;

  const BillingContactForm({
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

    return Row(
      children: [
        Expanded(
          child: Focus(
            onFocusChange: (hasFocus) {
              if (!hasFocus) onFieldBlur('billingEmail');
            },
            child: TextFormField(
              controller: c.billingEmail,
              style: typo.bodySmall.copyWith(fontSize: 13),
              keyboardType: TextInputType.emailAddress,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: buildInputDecoration(
                context,
                label: l.billingEmailLabel,
                prefixIcon: const Icon(Icons.alternate_email_rounded),
                isRequired: c.isBillingRequired('billingEmail'),
                isFilled: c.billingEmail.text.trim().isNotEmpty,
                showCheck: c.isBillingRequired('billingEmail') &&
                    c.billingEmail.text.trim().isNotEmpty,
              ),
              onChanged: (_) => onFieldChanged(),
              validator: (v) {
                if (!c.shouldShowError('billingEmail', showValidation)) {
                  return null;
                }
                if (requireBilling &&
                    c.isBillingRequired('billingEmail') &&
                    (v == null || v.trim().isEmpty)) {
                  return l.fieldIsRequired;
                }
                if (v == null || v.isEmpty) return null;
                final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);
                return ok ? null : l.invalidEmail;
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Focus(
            onFocusChange: (hasFocus) {
              if (!hasFocus) onFieldBlur('billingPhone');
            },
            child: TextFormField(
              controller: c.billingPhone,
              style: typo.bodySmall.copyWith(fontSize: 13),
              keyboardType: TextInputType.phone,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: buildInputDecoration(
                context,
                label: l.billingPhoneLabel,
                prefixIcon: const Icon(Icons.phone_in_talk),
                isRequired: c.isBillingRequired('billingPhone'),
                isFilled: c.billingPhone.text.trim().isNotEmpty,
                showCheck: c.isBillingRequired('billingPhone') &&
                    c.billingPhone.text.trim().isNotEmpty,
              ),
              onChanged: (_) => onFieldChanged(),
              validator: (v) {
                if (!requireBilling ||
                    !c.isBillingRequired('billingPhone')) {
                  return null;
                }
                if (!c.shouldShowError('billingPhone', showValidation)) {
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
    );
  }
}
