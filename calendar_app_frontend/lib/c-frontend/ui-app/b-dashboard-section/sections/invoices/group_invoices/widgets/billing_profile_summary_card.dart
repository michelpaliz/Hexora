import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/a-models/invoice/billing_profile.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class BillingProfileSummaryCard extends StatelessWidget {
  final BillingProfile? profile;
  final bool expanded;
  final VoidCallback onToggleExpanded;

  const BillingProfileSummaryCard({
    super.key,
    required this.profile,
    required this.expanded,
    required this.onToggleExpanded,
  });

  bool _has(String? v) => (v ?? '').trim().isNotEmpty;

  List<String> _missingFieldLabels(AppLocalizations l, BillingProfile? p) {
    if (p == null) return [l.billingLegalName, l.billingTaxId];
    final missing = <String>[];
    if (!_has(p.legalName)) missing.add(l.billingLegalName);
    if (!_has(p.taxId)) missing.add(l.billingTaxId);
    if (!_has(p.email)) missing.add(l.billingEmailLabel);
    if (!_has(p.iban)) missing.add(l.billingIban);
    if (!_has(p.addressStreet) ||
        !_has(p.addressCity) ||
        !_has(p.addressCountry)) {
      missing.add(l.billingAddress);
    }
    return missing;
  }

  String _addressInline(BillingProfile p) {
    final parts = <String>[
      if (_has(p.addressStreet)) p.addressStreet!.trim(),
      if (_has(p.addressExtra)) p.addressExtra!.trim(),
      [
        if (_has(p.addressPostalCode)) p.addressPostalCode!.trim(),
        if (_has(p.addressCity)) p.addressCity!.trim(),
      ].join(' ').trim(),
      if (_has(p.addressProvince)) p.addressProvince!.trim(),
      if (_has(p.addressCountry)) p.addressCountry!.trim(),
    ].where((e) => e.trim().isNotEmpty).toList();
    return parts.isEmpty ? '-' : parts.join(', ');
  }

  Future<void> _copy(BuildContext context, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    final l = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.copiedToClipboard)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    final missing = _missingFieldLabels(l, profile);
    final ready = missing.isEmpty;

    final statusBg = ready ? cs.secondaryContainer : cs.surfaceContainerHighest;
    final statusFg = ready ? cs.onSecondaryContainer : cs.onSurfaceVariant;

    final taxId =
        (profile != null && _has(profile!.taxId)) ? profile!.taxId.trim() : '-';
    final iban =
        (profile != null && _has(profile!.iban)) ? profile!.iban!.trim() : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              ready ? Icons.verified_outlined : Icons.report_gmailerrorred,
              size: 16,
              color: cs.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                ready ? l.billingComplete : l.billingMissing,
                style: t.bodySmall.copyWith(
                  color: statusFg,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        _InfoRow(
          label: l.billingTaxId,
          value: taxId,
          icon: Icons.badge_outlined,
          monospace: true,
          inline: true,
          onCopy: taxId == '-' ? null : () => _copy(context, taxId),
        ),
        if (!expanded && !ready) ...[
          const SizedBox(height: 6),
          Text(
            '${l.details}: ${missing.take(2).join(', ')}${missing.length > 2 ? '…' : ''}',
            style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (expanded) ...[
          const SizedBox(height: 8),
          if (iban != null)
            _InfoRow(
              label: l.billingIban,
              value: iban,
              icon: Icons.account_balance_outlined,
              monospace: true,
              onCopy: () => _copy(context, iban),
            ),
          _InfoRow(
            label: l.billingAddress,
            value: profile == null ? '-' : _addressInline(profile!),
            icon: Icons.place_outlined,
          ),
        ],
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            ),
            onPressed: onToggleExpanded,
            icon: Icon(
              expanded ? Icons.expand_less : Icons.expand_more,
              size: 18,
            ),
            label: Text(l.details),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool monospace;
  final bool inline;
  final VoidCallback? onTap;
  final VoidCallback? onCopy;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    this.monospace = false,
    this.inline = false,
    this.onTap,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final copyLabel = MaterialLocalizations.of(context).copyButtonLabel;

    final valueStyle = t.bodySmall.copyWith(
      color: cs.onSurfaceVariant,
      fontWeight: FontWeight.w700,
      fontFamily: monospace ? 'monospace' : null,
      letterSpacing: monospace ? 0.2 : null,
    );

    final row = Row(
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
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: valueStyle,
                maxLines: inline ? 1 : 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (onCopy != null)
          IconButton(
            tooltip: copyLabel,
            visualDensity: VisualDensity.compact,
            onPressed: onCopy,
            icon: Icon(
              Icons.content_copy_outlined,
              size: 18,
              color: cs.onSurfaceVariant,
            ),
          )
        else if (onTap != null)
          IconButton(
            tooltip: label,
            visualDensity: VisualDensity.compact,
            onPressed: onTap,
            icon: Icon(
              Icons.open_in_new,
              size: 18,
              color: cs.onSurfaceVariant,
            ),
          ),
      ],
    );

    if (onTap == null)
      return Padding(padding: const EdgeInsets.only(bottom: 8), child: row);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: row,
      ),
    );
  }
}
