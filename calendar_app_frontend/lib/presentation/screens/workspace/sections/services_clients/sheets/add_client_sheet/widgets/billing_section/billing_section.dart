import 'package:flutter/material.dart';
import 'package:hexora/presentation/screens/workspace/sections/services_clients/sheets/add_client_sheet/widgets/billing_section/billing_address_form.dart';
import 'package:hexora/presentation/screens/workspace/sections/services_clients/sheets/add_client_sheet/widgets/billing_section/billing_contact_form.dart';
import 'package:hexora/presentation/screens/workspace/sections/services_clients/sheets/add_client_sheet/widgets/billing_section/billing_legal_and_tax.dart';
import '../../add_client_controller.dart';

class BillingSection extends StatefulWidget {
  final AddClientController c;
  final bool showValidation;
  final VoidCallback onFieldChanged;
  final ValueChanged<String> onFieldBlur;

  const BillingSection({
    super.key,
    required this.c,
    required this.showValidation,
    required this.onFieldChanged,
    required this.onFieldBlur,
  });

  @override
  State<BillingSection> createState() => _BillingSectionState();
}

class _BillingSectionState extends State<BillingSection> {
  AddClientController get c => widget.c;

  @override
  Widget build(BuildContext context) {
    final requireBilling =
        c.hasBillingData || c.billingExpanded || widget.showValidation;
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BillingGroupLabel(
          text: isSpanish ? 'Identidad fiscal' : 'Legal identity',
          icon: Icons.badge_outlined,
          topGap: 0,
        ),
        BillingLegalAndTax(
          c: c,
          requireBilling: requireBilling,
          showValidation: widget.showValidation,
          onFieldChanged: widget.onFieldChanged,
          onFieldBlur: widget.onFieldBlur,
        ),
        _BillingGroupLabel(
          text: isSpanish ? 'Dirección y contacto' : 'Address and contact',
          icon: Icons.location_on_outlined,
        ),
        BillingAddressForm(
          c: c,
          requireBilling: requireBilling,
          showValidation: widget.showValidation,
          onFieldChanged: widget.onFieldChanged,
          onFieldBlur: widget.onFieldBlur,
        ),
        const SizedBox(height: 8),
        BillingContactForm(
          c: c,
          requireBilling: requireBilling,
          showValidation: widget.showValidation,
          onFieldChanged: widget.onFieldChanged,
          onFieldBlur: widget.onFieldBlur,
        ),
      ],
    );
  }
}

/// A subtle, type-only section label; no card, border, or background colour.
class _BillingGroupLabel extends StatelessWidget {
  const _BillingGroupLabel({
    required this.text,
    required this.icon,
    this.topGap = 14,
  });

  final String text;
  final IconData icon;
  final double topGap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(2, topGap, 2, 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            text.toUpperCase(),
            style: t.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
