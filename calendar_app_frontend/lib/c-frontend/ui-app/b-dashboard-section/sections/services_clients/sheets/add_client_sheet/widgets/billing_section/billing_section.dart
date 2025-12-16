import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/sheets/add_client_sheet/widgets/billing_section/billing_address_form.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/sheets/add_client_sheet/widgets/billing_section/billing_contact_form.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/sheets/add_client_sheet/widgets/billing_section/billing_document_type.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/sheets/add_client_sheet/widgets/billing_section/billing_legal_and_tax.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

import '../../add_client_controller.dart';

class BillingSection extends StatefulWidget {
  final AddClientController c;

  const BillingSection({super.key, required this.c});

  @override
  State<BillingSection> createState() => _BillingSectionState();
}

class _BillingSectionState extends State<BillingSection> {
  AddClientController get c => widget.c;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);

    // mirrors: initiallyExpanded: _billingExpanded || _hasBillingData
    final initiallyExpanded = c.billingExpanded || c.hasBillingData;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        onExpansionChanged: (v) => setState(() => c.billingExpanded = v),
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: const Icon(Icons.receipt_long_outlined),
        title: Row(
          children: [
            Expanded(
              child: Text(
                l.billingDetails,
                style: typo.bodyMedium.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            _BillingStatusChip(c: c),
          ],
        ),
        subtitle: Text(
          l.billingDetailsSubtitle,
          style: typo.bodySmall.copyWith(color: cs.onSurfaceVariant),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        children: [
          const SizedBox(height: 8),
          BillingDocumentType(
            value: c.billingDocType,
            onChanged: (v) => setState(() => c.billingDocType = v),
          ),
          const SizedBox(height: 10),
          BillingLegalAndTax(c: c),
          const SizedBox(height: 10),
          BillingAddressForm(c: c),
          const SizedBox(height: 10),
          BillingContactForm(c: c),
        ],
      ),
    );
  }
}

class _BillingStatusChip extends StatelessWidget {
  final AddClientController c;

  const _BillingStatusChip({required this.c});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);

    final complete = c.client?.billing?.isComplete ?? false;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: complete ? cs.secondaryContainer : cs.errorContainer,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
      ),
      child: Text(
        complete ? l.billingComplete : l.billingMissing,
        style: typo.bodySmall.copyWith(
          fontWeight: FontWeight.w700,
          color: complete ? cs.onSecondaryContainer : cs.onErrorContainer,
        ),
      ),
    );
  }
}
