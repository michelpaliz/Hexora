import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/sheets/add_client_sheet/widgets/billing_section/billing_address_form.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/sheets/add_client_sheet/widgets/billing_section/billing_contact_form.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/sheets/add_client_sheet/widgets/billing_section/billing_legal_and_tax.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

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
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);

    // mirrors: initiallyExpanded: _billingExpanded || _hasBillingData
    final initiallyExpanded = c.billingExpanded || c.hasBillingData;
    final requireBilling =
        c.hasBillingData || c.billingExpanded || widget.showValidation;
    final completed = c.billingCompletedCount;
    final total = c.billingRequiredTotal;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.light
            ? Colors.white
            : null,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: Theme.of(context).brightness == Brightness.light
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        onExpansionChanged: (v) => setState(() => c.billingExpanded = v),
        tilePadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        leading: const Icon(Icons.receipt_long_outlined, size: 20),
        title: Row(
          children: [
            Expanded(
              child: Text(
                l.billingDetails,
                style: typo.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            _BillingStatusChip(
              completed: completed,
              total: total,
            ),
          ],
        ),
        subtitle: Text(
          l.billingDetailsSubtitle,
          style: typo.bodySmall.copyWith(
            color: cs.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        children: [
          const SizedBox(height: 6),
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
      ),
    );
  }
}

class _BillingStatusChip extends StatelessWidget {
  final int completed;
  final int total;

  const _BillingStatusChip({
    required this.completed,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);

    final complete = completed >= total && total > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: complete ? cs.secondaryContainer : cs.errorContainer,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Text(
        l.billingProgressLabel(completed, total),
        style: typo.bodySmall.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 10,
          color: complete ? cs.onSecondaryContainer : cs.onErrorContainer,
        ),
      ),
    );
  }
}
