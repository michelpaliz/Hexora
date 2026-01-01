import 'package:flutter/material.dart';
import 'package:hexora/a-models/invoice/billing_profile.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/group_invoices/widgets/mini_info_row.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class BusinessCard extends StatelessWidget {
  final AppTypography typography;
  final ColorScheme colorScheme;

  final BillingProfile? billingProfile;
  final bool expanded;

  final VoidCallback? onEdit;
  final VoidCallback onToggleExpanded;

  final String Function(BillingProfile p) formatBillingAddress;

  const BusinessCard({
    super.key,
    required this.typography,
    required this.colorScheme,
    required this.billingProfile,
    required this.expanded,
    required this.onEdit,
    required this.onToggleExpanded,
    required this.formatBillingAddress,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = typography;
    final cs = colorScheme;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: onToggleExpanded,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      'Business',
                      style: t.bodySmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: l.edit,
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: expanded ? 'Collapse' : 'Expand',
                onPressed: onToggleExpanded,
                icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
              ),
            ],
          ),
          Text(
            billingProfile?.legalName.isNotEmpty == true
                ? billingProfile!.legalName
                : l.billingProfileEmpty,
            maxLines: expanded ? 3 : 2,
            overflow: TextOverflow.ellipsis,
            style: t.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            billingProfile?.email?.isNotEmpty == true
                ? billingProfile!.email!
                : '-',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
          ),
          if (expanded) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    MiniInfoRow(
                        label: l.billingTaxId,
                        value: billingProfile?.taxId ?? '-'),
                    MiniInfoRow(
                      label: l.billingWebsite,
                      value: (billingProfile?.website?.isNotEmpty == true)
                          ? billingProfile!.website!
                          : '-',
                    ),
                    MiniInfoRow(
                      label: l.billingIban,
                      value: (billingProfile?.iban?.isNotEmpty == true)
                          ? billingProfile!.iban!
                          : '-',
                    ),
                    MiniInfoRow(
                      label: l.billingAddress,
                      value: billingProfile == null
                          ? '-'
                          : formatBillingAddress(billingProfile!),
                    ),
                    MiniInfoRow(
                      label: l.billingTaxRate,
                      value: billingProfile == null
                          ? '-'
                          : '${billingProfile!.vatRate}%',
                    ),
                    MiniInfoRow(
                        label: l.billingCurrency,
                        value: billingProfile?.currency ?? '-'),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
