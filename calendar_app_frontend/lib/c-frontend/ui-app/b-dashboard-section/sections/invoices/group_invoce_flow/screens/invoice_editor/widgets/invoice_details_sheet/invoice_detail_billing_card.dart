import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class InvoiceDetailBillingCard extends StatelessWidget {
  final String title;
  final bool canEdit;
  final bool saving;
  final VoidCallback onEdit;
  final String billingName;
  final String billingEntity;
  final String billingStreet;
  final String billingCity;
  final String billingPostal;
  final String billingProvince;
  final String billingCountry;

  const InvoiceDetailBillingCard({
    super.key,
    required this.title,
    required this.canEdit,
    required this.saving,
    required this.onEdit,
    required this.billingName,
    required this.billingEntity,
    required this.billingStreet,
    required this.billingCity,
    required this.billingPostal,
    required this.billingProvince,
    required this.billingCountry,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    final addressLine = [
      if (billingStreet.isNotEmpty) billingStreet,
      if (billingPostal.isNotEmpty || billingCity.isNotEmpty)
        [
          if (billingPostal.isNotEmpty) billingPostal,
          if (billingCity.isNotEmpty) billingCity,
        ].join(' '),
      if (billingProvince.isNotEmpty || billingCountry.isNotEmpty)
        [
          if (billingProvince.isNotEmpty) billingProvince,
          if (billingCountry.isNotEmpty) billingCountry,
        ].join(' · '),
    ].where((e) => e.trim().isNotEmpty).join(', ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.badge_outlined, size: 16, color: cs.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                title,
                style: t.bodySmall.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (canEdit)
                SizedBox(
                  width: 28,
                  height: 28,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    tooltip: l.invoiceBillingNameEditCta,
                    onPressed: saving ? null : onEdit,
                    icon: saving
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            Icons.edit_outlined,
                            size: 14,
                            color: cs.onSurfaceVariant,
                          ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            billingName,
            style: t.bodyMedium.copyWith(fontWeight: FontWeight.w800),
          ),
          if (billingEntity.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              billingEntity,
              style: t.bodySmall.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (addressLine.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    addressLine,
                    style: t.bodySmall.copyWith(color: cs.onSurface),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
