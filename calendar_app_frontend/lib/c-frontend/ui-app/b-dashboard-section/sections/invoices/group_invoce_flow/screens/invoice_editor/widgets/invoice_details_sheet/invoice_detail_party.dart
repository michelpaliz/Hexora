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
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 1,
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 560;
            final sectionBg = cs.surface;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.invoiceParties,
                  style: t.bodyLarge.copyWith(fontWeight: FontWeight.w900),
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
                            child: _PartyDetails(
                              profile: issuer,
                              emptyLabel: l.billingProfileEmpty,
                              kind: _PartyKind.issuer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _PartySection(
                            title: l.invoiceClientSection,
                            backgroundColor: sectionBg,
                            child: _PartyDetails(
                              profile: clientBilling,
                              emptyLabel: l.billingDetails,
                              kind: _PartyKind.client,
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
                    child: _PartyDetails(
                      profile: issuer,
                      emptyLabel: l.billingProfileEmpty,
                      kind: _PartyKind.issuer,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _PartySection(
                    title: l.invoiceClientSection,
                    backgroundColor: sectionBg,
                    child: _PartyDetails(
                      profile: clientBilling,
                      emptyLabel: l.billingDetails,
                      kind: _PartyKind.client,
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
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: t.bodyMedium.copyWith(
              fontWeight: FontWeight.w900,
              color: cs.onSurface,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

enum _PartyKind { issuer, client }

class _PartyDetails extends StatefulWidget {
  final Object? profile;
  final String emptyLabel;
  final _PartyKind kind;

  const _PartyDetails({
    required this.profile,
    required this.emptyLabel,
    required this.kind,
  });

  @override
  State<_PartyDetails> createState() => _PartyDetailsState();
}

class _PartyDetailsState extends State<_PartyDetails> {
  bool _detailsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
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
      legalName,
      taxId,
      email,
      phone,
      website,
      iban,
      addressStreet,
      addressCity,
      addressCountry,
    ].any(hasAny);

    if (!hasData) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          widget.emptyLabel,
          style: t.bodySmall.copyWith(
            color: cs.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

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

    final emailLabel =
        widget.kind == _PartyKind.issuer ? l.billingEmailLabel : l.emailLabel;
    final phoneLabel =
        widget.kind == _PartyKind.issuer ? l.billingPhoneLabel : l.phoneLabel;

    final emailValue = email?.trim();
    final phoneValue = phone?.trim();
    final websiteValue = website?.trim();

    final hasDetails = hasAny(emailValue) ||
        hasAny(phoneValue) ||
        hasAny(websiteValue) ||
        addressLines.isNotEmpty ||
        (widget.kind == _PartyKind.issuer && hasAny(iban));

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasAny(legalName))
            Text(
              legalName!.trim(),
              style: t.bodyMedium.copyWith(
                fontWeight: FontWeight.w900,
                color: cs.onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          if (hasAny(taxId)) ...[
            const SizedBox(height: 6),
            Text(
              '${l.billingTaxId}: ${taxId!.trim()}',
              style: t.bodySmall.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (!_detailsExpanded && hasAny(emailValue)) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.email_outlined,
                  size: 14,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    emailValue!,
                    style: t.bodySmall.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (hasDetails && !_detailsExpanded) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    [
                      if (!hasAny(emailValue) && addressLines.isNotEmpty)
                        addressLines.first,
                    ].join(' · '),
                    style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: () => setState(() => _detailsExpanded = true),
                  icon: const Icon(Icons.expand_more, size: 18),
                  label: Text(l.details),
                ),
              ],
            ),
          ],
          if (_detailsExpanded) ...[
            const SizedBox(height: 10),
            if (hasAny(taxId)) ...[
              _SectionHeader(label: l.billingTaxId),
              const SizedBox(height: 8),
              _KeyValueRow(
                label: l.billingTaxId,
                value: taxId!.trim(),
                icon: Icons.badge_outlined,
                copyValue: taxId,
              ),
            ],
            if (hasAny(emailValue) ||
                hasAny(phoneValue) ||
                hasAny(websiteValue)) ...[
              if (hasAny(taxId)) const SizedBox(height: 10),
              _SectionHeader(label: l.contact),
              const SizedBox(height: 8),
              if (hasAny(emailValue))
                _KeyValueRow(
                  label: emailLabel,
                  value: emailValue!,
                  icon: Icons.email_outlined,
                  copyValue: emailValue,
                ),
              if (hasAny(phoneValue))
                _KeyValueRow(
                  label: phoneLabel,
                  value: phoneValue!,
                  icon: Icons.phone_outlined,
                  copyValue: phoneValue,
                ),
              if (hasAny(websiteValue))
                _KeyValueRow(
                  label: l.billingWebsite,
                  value: websiteValue!,
                  icon: Icons.language_outlined,
                  copyValue: websiteValue,
                ),
            ],
            if (addressLines.isNotEmpty) ...[
              if (hasAny(emailValue) ||
                  hasAny(phoneValue) ||
                  hasAny(websiteValue))
                const SizedBox(height: 10),
              _SectionHeader(label: l.billingAddress),
              const SizedBox(height: 8),
              SelectableText(
                addressLines.join('\n'),
                style: t.bodySmall.copyWith(color: cs.onSurface),
              ),
            ],
            if (widget.kind == _PartyKind.issuer && hasAny(iban)) ...[
              const SizedBox(height: 10),
              _SectionHeader(label: l.billingIban),
              const SizedBox(height: 8),
              _CopyField(
                label: l.billingIban,
                value: iban!.trim(),
                icon: Icons.account_balance_outlined,
              ),
            ],
            const SizedBox(height: 2),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
                onPressed: () => setState(() => _detailsExpanded = false),
                icon: const Icon(Icons.expand_less, size: 18),
                label: Text(l.details),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Text(
      label,
      style: t.bodySmall.copyWith(
        color: cs.onSurfaceVariant,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final String? copyValue;

  const _KeyValueRow({
    required this.label,
    required this.value,
    required this.icon,
    this.copyValue,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final copyLabel = MaterialLocalizations.of(context).copyButtonLabel;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: t.bodySmall.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: t.bodySmall.copyWith(color: cs.onSurface),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (copyValue != null)
            IconButton(
              tooltip: copyLabel,
              visualDensity: VisualDensity.compact,
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: copyValue!));
                if (!context.mounted) return;
                final l = AppLocalizations.of(context)!;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.copiedToClipboard)),
                );
              },
              icon: Icon(
                Icons.content_copy_outlined,
                size: 18,
                color: cs.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _CopyField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _CopyField({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final copyLabel = MaterialLocalizations.of(context).copyButtonLabel;

    final codeStyle = t.bodySmall.copyWith(
      color: cs.onSurface,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.3,
      fontFamily: 'monospace',
    );

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: t.bodySmall.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(value, style: codeStyle),
              ],
            ),
          ),
          IconButton(
            tooltip: copyLabel,
            visualDensity: VisualDensity.compact,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: value));
              if (!context.mounted) return;
              final l = AppLocalizations.of(context)!;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l.copiedToClipboard)),
              );
            },
            icon: Icon(
              Icons.content_copy_outlined,
              size: 18,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
