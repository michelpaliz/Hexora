import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/sheets/add_client_sheet/widgets/input_border.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

import '../add_client_controller.dart';

class ClientContactForm extends StatelessWidget {
  final AddClientController c;

  const ClientContactForm({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);
    final inputBorder = buildInputBorder(context);

    return Column(
      children: [
        TextFormField(
          controller: c.name,
          style: typo.bodyMedium,
          decoration: InputDecoration(
            labelText: '${l.nameLabel} *',
            labelStyle: typo.bodySmall.copyWith(color: cs.onSurfaceVariant),
            hintText: l.e_gJohnDoe,
            hintStyle: typo.bodySmall.copyWith(
              color: cs.onSurfaceVariant.withOpacity(0.7),
            ),
            prefixIcon: const Icon(Icons.person_outline),
            enabledBorder: inputBorder,
            focusedBorder: inputBorder.copyWith(
              borderSide: BorderSide(color: cs.primary, width: 1.5),
            ),
            errorBorder: inputBorder.copyWith(
              borderSide: BorderSide(color: cs.error),
            ),
            focusedErrorBorder: inputBorder.copyWith(
              borderSide: BorderSide(color: cs.error, width: 1.5),
            ),
          ),
          textInputAction: TextInputAction.next,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? l.nameIsRequired : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: c.phone,
          style: typo.bodyMedium,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: l.phoneLabel,
            labelStyle: typo.bodySmall.copyWith(color: cs.onSurfaceVariant),
            hintText: l.e_gPhone,
            hintStyle: typo.bodySmall.copyWith(
              color: cs.onSurfaceVariant.withOpacity(0.7),
            ),
            prefixIcon: const Icon(Icons.phone_outlined),
            enabledBorder: inputBorder,
            focusedBorder: inputBorder.copyWith(
              borderSide: BorderSide(color: cs.primary, width: 1.5),
            ),
          ),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: c.email,
          style: typo.bodyMedium,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: l.emailLabel,
            labelStyle: typo.bodySmall.copyWith(color: cs.onSurfaceVariant),
            hintText: l.e_gEmail,
            hintStyle: typo.bodySmall.copyWith(
              color: cs.onSurfaceVariant.withOpacity(0.7),
            ),
            prefixIcon: const Icon(Icons.alternate_email),
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
      ],
    );
  }
}
