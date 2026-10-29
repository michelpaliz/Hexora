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
    return Column(
      children: [
        BillingLegalAndTax(
          c: c,
          requireBilling: requireBilling,
          showValidation: widget.showValidation,
          onFieldChanged: widget.onFieldChanged,
          onFieldBlur: widget.onFieldBlur,
        ),
        const SizedBox(height: 8),
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
