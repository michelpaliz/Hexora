import 'package:flutter/material.dart';
import 'package:hexora/a-models/invoice/billing_profile.dart';
import 'package:hexora/a-models/invoice/client_billing.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class InvoiceDetailParty extends StatelessWidget {
  final BillingProfile? issuer;
  final ClientBilling? clientBilling;
  const InvoiceDetailParty({
    super.key,
    required this.issuer,
    required this.clientBilling,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 560;
            final sectionBg = cs.surfaceContainerHighest;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.invoiceParties,
                  style: t.bodyMedium.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                if (wide)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _PartySection(
                            title: l.billingProfileTitle,
                            backgroundColor: sectionBg,
                            child: _PartyBlock(
                              profile: issuer,
                              fallback: l.billingProfileEmpty,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _PartySection(
                            title: l.invoiceClientSection,
                            backgroundColor: sectionBg,
                            child: _PartyBlock(
                              profile: clientBilling,
                              fallback: l.billingDetails,
                              isClient: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  _PartySection(
                    title: l.billingProfileTitle,
                    backgroundColor: sectionBg,
                    child: _PartyBlock(
                      profile: issuer,
                      fallback: l.billingProfileEmpty,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _PartySection(
                    title: l.invoiceClientSection,
                    backgroundColor: sectionBg,
                    child: _PartyBlock(
                      profile: clientBilling,
                      fallback: l.billingDetails,
                      isClient: true,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PartySection extends StatelessWidget {
  final String title;
  final Color backgroundColor;
  final Widget child;

  const _PartySection({
    required this.title,
    required this.backgroundColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: t.bodySmall.copyWith(fontWeight: FontWeight.w800),
          ),
          child,
        ],
      ),
    );
  }
}

class _PartyBlock extends StatelessWidget {
  final Object? profile;
  final String fallback;
  final bool isClient;
  const _PartyBlock({
    required this.profile,
    required this.fallback,
    this.isClient = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final lines = <String>[];
    if (profile is BillingProfile) {
      final p = profile as BillingProfile;
      lines.add(p.legalName);
      lines.add(p.taxId);
      if (p.addressStreet != null) lines.add(p.addressStreet!);
      if (p.addressCity != null) lines.add(p.addressCity!);
      if (p.addressCountry != null) lines.add(p.addressCountry!);
      if (p.email != null) lines.add(p.email!);
      if (p.iban != null) lines.add(p.iban!);
    } else if (profile is ClientBilling) {
      final p = profile as ClientBilling;
      if (p.legalName != null) lines.add(p.legalName!);
      if (p.taxId != null) lines.add(p.taxId!);
      if (p.addressStreet != null) lines.add(p.addressStreet!);
      if (p.addressCity != null) lines.add(p.addressCity!);
      if (p.addressCountry != null) lines.add(p.addressCountry!);
      if (p.email != null) lines.add(p.email!);
      if (p.phone != null) lines.add(p.phone!);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        lines.isEmpty ? fallback : lines.join('\n'),
        style: t.bodySmall.copyWith(
          color: cs.onSurfaceVariant,
          fontStyle: lines.isEmpty ? FontStyle.italic : null,
        ),
      ),
    );
  }
}
