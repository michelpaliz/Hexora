import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PartyRow(
          icon: Icons.business_outlined,
          title: l.billingProfileTitle,
          profile: issuer,
          emptyLabel: l.billingProfileEmpty,
          kind: _PartyKind.issuer,
        ),
        Divider(
          height: 1,
          color: cs.outlineVariant.withValues(alpha: 0.3),
        ),
        _PartyRow(
          icon: Icons.person_outline,
          title: l.invoiceClientSection,
          profile: clientBilling,
          emptyLabel: l.billingDetails,
          kind: _PartyKind.client,
        ),
      ],
    );
  }
}

enum _PartyKind { issuer, client }

class _PartyRow extends StatefulWidget {
  final IconData icon;
  final String title;
  final Object? profile;
  final String emptyLabel;
  final _PartyKind kind;

  const _PartyRow({
    required this.icon,
    required this.title,
    required this.profile,
    required this.emptyLabel,
    required this.kind,
  });

  @override
  State<_PartyRow> createState() => _PartyRowState();
}

class _PartyRowState extends State<_PartyRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    String? legalName;
    String? taxId;
    String? email;
    String? phone;
    String? website;
    String? iban;
    String? addressStreet;
    String? addressExtra;
    String? addressCity;
    String? addressProvince;
    String? addressPostalCode;
    String? addressCountry;

    if (widget.profile is BillingProfile) {
      final p = widget.profile as BillingProfile;
      legalName = p.legalName;
      taxId = p.taxId;
      email = p.email;
      website = p.website;
      iban = p.iban;
      addressStreet = p.addressStreet;
      addressExtra = p.addressExtra;
      addressCity = p.addressCity;
      addressProvince = p.addressProvince;
      addressPostalCode = p.addressPostalCode;
      addressCountry = p.addressCountry;
    } else if (widget.profile is ClientBilling) {
      final p = widget.profile as ClientBilling;
      legalName = p.legalName;
      taxId = p.taxId;
      email = p.email;
      phone = p.phone;
      addressStreet = p.addressStreet;
      addressExtra = p.addressExtra;
      addressCity = p.addressCity;
      addressProvince = p.addressProvince;
      addressPostalCode = p.addressPostalCode;
      addressCountry = p.addressCountry;
    }

    bool hasAny(String? v) => (v ?? '').trim().isNotEmpty;
    final hasData = [
      legalName, taxId, email, phone, website, iban,
      addressStreet, addressCity, addressCountry,
    ].any(hasAny);

    // Summary line for collapsed state
    final summaryParts = <String>[
      if (hasAny(legalName)) legalName!.trim(),
      if (hasAny(taxId)) taxId!.trim(),
    ];
    final summary = summaryParts.isNotEmpty
        ? summaryParts.join(' · ')
        : widget.emptyLabel;

    final addressLines = <String>[
      for (final v in [addressStreet, addressExtra])
        if (hasAny(v)) v!.trim(),
      [
        if (hasAny(addressPostalCode)) addressPostalCode!.trim(),
        if (hasAny(addressCity)) addressCity!.trim(),
        if (hasAny(addressProvince)) addressProvince!.trim(),
      ].join(' ').trim(),
      if (hasAny(addressCountry)) addressCountry!.trim(),
    ].where((e) => e.trim().isNotEmpty).toList();

    final hasDetails = hasAny(email) ||
        hasAny(phone) ||
        hasAny(website) ||
        addressLines.isNotEmpty ||
        (widget.kind == _PartyKind.issuer && hasAny(iban));

    return InkWell(
      onTap: hasDetails ? () => setState(() => _expanded = !_expanded) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: icon + title + summary + chevron
            Row(
              children: [
                Icon(widget.icon, size: 16, color: cs.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  widget.title,
                  style: t.bodySmall.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (hasDetails)
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: _expanded ? 0.5 : 0,
                    child: Icon(
                      Icons.expand_more,
                      size: 16,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            // Always show summary
            Text(
              summary,
              style: t.bodyMedium.copyWith(
                fontWeight: hasData ? FontWeight.w800 : FontWeight.w600,
                color: hasData ? cs.onSurface : cs.onSurfaceVariant,
                fontStyle: hasData ? null : FontStyle.italic,
              ),
              maxLines: _expanded ? 3 : 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (hasAny(email) && !_expanded) ...[
              const SizedBox(height: 2),
              Text(
                email!.trim(),
                style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            // Expanded details
            if (_expanded && hasDetails) ...[
              const SizedBox(height: 6),
              if (hasAny(email))
                _DetailRow(
                  icon: Icons.email_outlined,
                  value: email!.trim(),
                  copyValue: email,
                ),
              if (hasAny(phone))
                _DetailRow(
                  icon: Icons.phone_outlined,
                  value: phone!.trim(),
                  copyValue: phone,
                ),
              if (hasAny(website))
                _DetailRow(
                  icon: Icons.language_outlined,
                  value: website!.trim(),
                  copyValue: website,
                ),
              if (addressLines.isNotEmpty)
                _DetailRow(
                  icon: Icons.location_on_outlined,
                  value: addressLines.join(', '),
                ),
              if (widget.kind == _PartyKind.issuer && hasAny(iban))
                _DetailRow(
                  icon: Icons.account_balance_outlined,
                  value: iban!.trim(),
                  copyValue: iban,
                  mono: true,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String value;
  final String? copyValue;
  final bool mono;

  const _DetailRow({
    required this.icon,
    required this.value,
    this.copyValue,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: t.bodySmall.copyWith(
                color: cs.onSurface,
                fontFamily: mono ? 'monospace' : null,
                fontWeight: mono ? FontWeight.w700 : null,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (copyValue != null)
            GestureDetector(
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: copyValue!));
                if (!context.mounted) return;
                final l = AppLocalizations.of(context)!;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.copiedToClipboard)),
                );
              },
              child: Icon(
                Icons.content_copy_outlined,
                size: 14,
                color: cs.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
        ],
      ),
    );
  }
}
