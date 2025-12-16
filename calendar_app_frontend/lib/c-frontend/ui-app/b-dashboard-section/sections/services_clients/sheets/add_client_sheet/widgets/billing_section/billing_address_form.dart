import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

import '../../add_client_controller.dart';
import '../input_border.dart';

class BillingAddressForm extends StatelessWidget {
  final AddClientController c;

  const BillingAddressForm({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);
    final inputBorder = buildInputBorder(context);

    return Column(
      children: [
        TextFormField(
          controller: c.billingStreet,
          style: typo.bodyMedium,
          decoration: InputDecoration(
            labelText: l.addressStreet,
            prefixIcon: const Icon(Icons.home_outlined),
            enabledBorder: inputBorder,
            focusedBorder: inputBorder.copyWith(
              borderSide: BorderSide(color: cs.primary, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: c.billingExtra,
          style: typo.bodyMedium,
          decoration: InputDecoration(
            labelText: l.addressExtra,
            prefixIcon: const Icon(Icons.location_city_outlined),
            enabledBorder: inputBorder,
            focusedBorder: inputBorder.copyWith(
              borderSide: BorderSide(color: cs.primary, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: c.billingCity,
                style: typo.bodyMedium,
                decoration: InputDecoration(
                  labelText: l.addressCity,
                  prefixIcon: const Icon(Icons.location_city_rounded),
                  enabledBorder: inputBorder,
                  focusedBorder: inputBorder.copyWith(
                    borderSide: BorderSide(color: cs.primary, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: c.billingProvince,
                style: typo.bodyMedium,
                decoration: InputDecoration(
                  labelText: l.addressProvince,
                  prefixIcon: const Icon(Icons.map_outlined),
                  enabledBorder: inputBorder,
                  focusedBorder: inputBorder.copyWith(
                    borderSide: BorderSide(color: cs.primary, width: 1.5),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: c.billingPostal,
                style: typo.bodyMedium,
                decoration: InputDecoration(
                  labelText: l.addressPostalCode,
                  prefixIcon: const Icon(Icons.local_post_office_outlined),
                  enabledBorder: inputBorder,
                  focusedBorder: inputBorder.copyWith(
                    borderSide: BorderSide(color: cs.primary, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: c.billingCountry,
                style: typo.bodyMedium,
                decoration: InputDecoration(
                  labelText: l.addressCountry,
                  prefixIcon: const Icon(Icons.public),
                  enabledBorder: inputBorder,
                  focusedBorder: inputBorder.copyWith(
                    borderSide: BorderSide(color: cs.primary, width: 1.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
