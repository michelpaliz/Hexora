import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class ClientBillingView extends StatelessWidget {
  final GroupClient client;
  final TextStyle headline;
  final Color onSurface;
  const ClientBillingView({
    super.key,
    required this.client,
    required this.headline,
    required this.onSurface,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final b = client.billing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.billingDetails, style: headline),
        const SizedBox(height: 6),
        _row(l.billingLegalName, b?.legalName ?? client.name, t, onSurface),
        _row(l.billingTaxId, b?.taxId ?? '-', t, onSurface),
        _row(
            l.billingEmailLabel, b?.email ?? client.email ?? '-', t, onSurface),
        _row(
            l.billingPhoneLabel, b?.phone ?? client.phone ?? '-', t, onSurface),
        _row(l.billingAddress, _address(b), t, onSurface),
      ],
    );
  }

  String _address(dynamic b) {
    if (b == null) return '-';
    final parts = [
      b.addressStreet,
      b.addressCity,
      b.addressProvince,
      b.addressPostalCode,
      b.addressCountry,
    ].whereType<String>().where((s) => s.trim().isNotEmpty).toList();
    return parts.isEmpty ? '-' : parts.join(', ');
  }

  Widget _row(
    String label,
    String value,
    AppTypography t,
    Color onSurface,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: t.bodySmall.copyWith(
                color: onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: t.bodySmall.copyWith(color: onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
