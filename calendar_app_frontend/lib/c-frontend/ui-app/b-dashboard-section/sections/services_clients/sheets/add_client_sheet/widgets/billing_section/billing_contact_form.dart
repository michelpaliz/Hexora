import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

import '../../add_client_controller.dart';
import '../input_border.dart';

class BillingContactForm extends StatelessWidget {
  final AddClientController c;

  const BillingContactForm({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);
    final inputBorder = buildInputBorder(context);

    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: c.billingEmail,
            style: typo.bodyMedium,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: l.billingEmailLabel,
              prefixIcon: const Icon(Icons.alternate_email_rounded),
              enabledBorder: inputBorder,
              focusedBorder: inputBorder.copyWith(
                borderSide: BorderSide(color: cs.primary, width: 1.5),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return null;
              final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);
              return ok ? null : l.invalidEmail;
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextFormField(
            controller: c.billingPhone,
            style: typo.bodyMedium,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: l.billingPhoneLabel,
              prefixIcon: const Icon(Icons.phone_in_talk),
              enabledBorder: inputBorder,
              focusedBorder: inputBorder.copyWith(
                borderSide: BorderSide(color: cs.primary, width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
