import 'package:flutter/material.dart';
import 'package:hexora/a-models/invoice/billing_profile.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class BillingProfileCard extends StatelessWidget {
  final BillingProfile? profile;
  final VoidCallback onEdit;
  final bool busy;

  const BillingProfileCard({
    super.key,
    required this.profile,
    required this.onEdit,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final isComplete = profile?.isComplete == true;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.apartment_rounded, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l.billingProfileTitle,
                    style: t.bodyMedium.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                _StatusChip(
                  label: isComplete ? l.billingComplete : l.billingMissing,
                  color: isComplete ? cs.secondaryContainer : cs.surfaceVariant,
                  textColor: isComplete
                      ? cs.onSecondaryContainer
                      : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: busy ? null : onEdit,
                  icon: busy
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.edit_outlined),
                  label: Text(l.edit),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (profile == null)
              Text(
                l.billingProfileEmpty,
                style: t.bodyMedium.copyWith(color: cs.onSurfaceVariant),
              )
            else ...[
              _InfoRow(label: l.billingLegalName, value: profile!.legalName),
              _InfoRow(label: l.billingTaxId, value: profile!.taxId),
              _InfoRow(
                label: l.billingEmailLabel,
                value: profile!.email ?? '-',
              ),
              _InfoRow(
                label: l.billingWebsite,
                value: profile!.website?.isNotEmpty == true
                    ? profile!.website!
                    : '-',
              ),
              _InfoRow(
                label: l.billingIban,
                value: profile!.iban?.isNotEmpty == true ? profile!.iban! : '-',
              ),
              _InfoRow(
                label: l.billingAddress,
                value: _formatAddress(profile!),
              ),
              _InfoRow(
                label: l.billingTaxRate,
                value: '${profile!.vatRate}%',
              ),
              _InfoRow(
                label: l.billingCurrency,
                value: profile!.currency,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatAddress(BillingProfile p) {
    final parts = [
      p.addressStreet,
      p.addressExtra,
      p.addressCity,
      p.addressProvince,
      p.addressPostalCode,
      p.addressCountry,
    ].whereType<String>().where((e) => e.trim().isNotEmpty).toList();
    return parts.isEmpty ? '-' : parts.join(', ');
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return  Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: t.bodySmall.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: t.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  const _StatusChip(
      {required this.label, required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTypography.of(context).bodySmall.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
