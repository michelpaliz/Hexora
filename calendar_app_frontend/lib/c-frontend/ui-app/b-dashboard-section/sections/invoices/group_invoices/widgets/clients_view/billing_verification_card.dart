import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class BillingVerificationCard extends StatelessWidget {
  final GroupClient client;
  final VoidCallback onEdit;

  const BillingVerificationCard({
    super.key,
    required this.client,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    final b = client.billing;

    bool missing(String? v) => v == null || v.trim().isEmpty;

    final requiredMissing = <String>[
      if (missing(b?.legalName) && client.name.trim().isEmpty)
        l.billingLegalName,
      if (missing(b?.taxId)) l.billingTaxId,
      if (missing(b?.addressStreet)) l.addressStreet,
      if (missing(b?.addressCity)) l.addressCity,
      if (missing(b?.addressCountry)) l.addressCountry,
    ];

    final ready = requiredMissing.isEmpty;
    final statusBg = ready ? cs.tertiaryContainer : cs.errorContainer;
    final statusFg = ready ? cs.onTertiaryContainer : cs.onErrorContainer;
    final statusLabel = ready ? l.billingComplete : l.billingMissing;

    final address = [
      b?.addressStreet,
      b?.addressExtra,
      b?.addressCity,
      b?.addressProvince,
      b?.addressPostalCode,
      b?.addressCountry,
    ].whereType<String>().map((e) => e.trim()).where((e) => e.isNotEmpty).join(
          ', ',
        );

    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.billingDetails,
                    style: t.bodyMedium.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                _StatusPill(
                  label: statusLabel,
                  background: statusBg,
                  foreground: statusFg,
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: l.edit,
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (!ready)
              _MissingBanner(
                title: l.clientBillingMissingTitle,
                message: l.clientBillingMissingMessage(requiredMissing.join(', ')),
              ),
            if (!ready) const SizedBox(height: 10),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(top: 8),
              iconColor: cs.onSurfaceVariant,
              collapsedIconColor: cs.onSurfaceVariant,
              title: Text(
                l.details,
                style: t.bodySmall.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 720;
                    if (!wide) {
                      return _FieldsColumn(
                        client: client,
                        address: address,
                        onEdit: onEdit,
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _FieldsColumn(
                            client: client,
                            address: address,
                            onEdit: onEdit,
                            leftOnly: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _FieldsColumn(
                            client: client,
                            address: address,
                            onEdit: onEdit,
                            rightOnly: true,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldsColumn extends StatelessWidget {
  final GroupClient client;
  final String address;
  final VoidCallback onEdit;
  final bool leftOnly;
  final bool rightOnly;

  const _FieldsColumn({
    required this.client,
    required this.address,
    required this.onEdit,
    this.leftOnly = false,
    this.rightOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final b = client.billing;

    String v(String? s) => (s ?? '').trim();

    final legalName = v(b?.legalName).isNotEmpty ? v(b?.legalName) : client.name;
    final taxId = v(b?.taxId);
    final email = v(b?.email).isNotEmpty ? v(b?.email) : v(client.email);
    final phone = v(b?.phone).isNotEmpty ? v(b?.phone) : v(client.phone);

    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Field(
          label: l.billingLegalName,
          value: legalName,
          required: true,
          copyValue: legalName,
        ),
        _Field(
          label: l.billingTaxId,
          value: taxId,
          required: true,
          copyValue: taxId,
        ),
        _Field(
          label: l.billingAddress,
          value: address,
          required: true,
          copyValue: address,
        ),
      ],
    );

    final right = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Field(
          label: l.billingEmailLabel,
          value: email,
          required: false,
          copyValue: email,
          link: email.contains('@') ? Uri.parse('mailto:$email') : null,
        ),
        _Field(
          label: l.billingPhoneLabel,
          value: phone,
          required: false,
          copyValue: phone,
        ),
      ],
    );

    if (leftOnly) return left;
    if (rightOnly) return right;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        left,
        const SizedBox(height: 12),
        right,
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String value;
  final bool required;
  final String? copyValue;
  final Uri? link;

  const _Field({
    required this.label,
    required this.value,
    required this.required,
    this.copyValue,
    this.link,
  });

  bool get _missing => value.trim().isEmpty;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    final labelStyle = t.bodySmall.copyWith(
      color: cs.onSurfaceVariant,
      fontWeight: FontWeight.w800,
    );

    final valueStyle = t.bodyMedium.copyWith(
      color: _missing
          ? (required ? cs.error : cs.onSurfaceVariant)
          : cs.onSurface,
      fontWeight: _missing ? FontWeight.w700 : FontWeight.w800,
      fontStyle: _missing ? FontStyle.italic : null,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: labelStyle),
                const SizedBox(height: 4),
                SelectableText(
                  _missing ? '-' : value,
                  style: valueStyle,
                  maxLines: 2,
                ),
              ],
            ),
          ),
          if (!_missing && (copyValue?.trim().isNotEmpty ?? false)) ...[
            const SizedBox(width: 6),
            IconButton(
              tooltip: MaterialLocalizations.of(context).copyButtonLabel,
              icon: const Icon(Icons.content_copy_outlined),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: copyValue!.trim()));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.copiedToClipboard)),
                );
              },
            ),
          ],
          if (!_missing && link != null) ...[
            const SizedBox(width: 2),
            IconButton(
              tooltip: l.emailLabel,
              icon: const Icon(Icons.email_outlined),
              onPressed: () async {
                final ok = await canLaunchUrl(link!);
                if (!ok) return;
                await launchUrl(link!);
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _MissingBanner extends StatelessWidget {
  final String title;
  final String message;
  const _MissingBanner({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: cs.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: t.bodySmall.copyWith(
                    color: cs.onErrorContainer,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: t.bodySmall.copyWith(color: cs.onErrorContainer),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _StatusPill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: t.bodySmall.copyWith(
          color: foreground,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
