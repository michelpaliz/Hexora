import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/invoice/client_billing.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/l10n/app_localizations.dart';

class ClientListItem extends StatelessWidget {
  final GroupClient client;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  /// Typography (injected)
  final TextStyle nameStyle;
  final TextStyle metaStyle;

  const ClientListItem({
    super.key,
    required this.client,
    this.onTap,
    this.onDelete,
    required this.nameStyle,
    required this.metaStyle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isMobile = MediaQuery.sizeOf(context).width < 700;

    return Card(
      color: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha:0.3), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 14,
                backgroundColor: cs.primary.withValues(alpha:0.10),
                child: Icon(Icons.person_outline, size: 16, color: cs.primary),
              ),
              const SizedBox(width: 8),

              // Name + inline meta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: nameStyle.copyWith(fontSize: 13),
                    ),
                    _MetaRow(
                      phone: client.phone,
                      email: client.email,
                      billing: client.billing,
                      textStyle: metaStyle.copyWith(fontSize: 11),
                      iconColor: cs.onSurfaceVariant.withValues(alpha:0.9),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 6),

              // Chips + actions — hide billing chip on mobile to avoid overflow
              if (!isMobile) ...[
                _BillingChip(billing: client.billing),
                const SizedBox(width: 4),
              ],
              _StatusChip(active: client.isActive),
              if (onDelete != null) ...[
                const SizedBox(width: 2),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.delete_outline, size: 16, color: cs.error),
                    tooltip: AppLocalizations.of(context)!.remove,
                    onPressed: onDelete,
                  ),
                ),
              ],
              const SizedBox(width: 2),
              Icon(Icons.chevron_right, size: 16, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String? phone;
  final String? email;
  final ClientBilling? billing;
  final TextStyle textStyle;
  final Color iconColor;

  const _MetaRow({
    required this.phone,
    required this.email,
    this.billing,
    required this.textStyle,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final parts = <_MetaPart>[];

    if ((email ?? '').isNotEmpty) {
      parts.add(_MetaPart(Icons.alternate_email_rounded, email!));
    }
    if ((phone ?? '').isNotEmpty) {
      parts.add(_MetaPart(Icons.phone_rounded, phone!));
    }
    final legalName = billing?.legalName;
    if (legalName != null && legalName.isNotEmpty) {
      parts.add(_MetaPart(Icons.receipt_long_outlined, legalName));
    }

    if (parts.isEmpty) {
      return Text(
        AppLocalizations.of(context)!.contact,
        style: textStyle.copyWith(fontStyle: FontStyle.italic),
      );
    }

    return Row(
      children: [
        for (int i = 0; i < parts.length; i++) ...[
          if (i > 0) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text('·', style: textStyle.copyWith(color: iconColor)),
            ),
          ],
          Icon(parts[i].icon, size: 12, color: iconColor),
          const SizedBox(width: 3),
          if (i == parts.length - 1)
            Flexible(
              child: Text(
                parts[i].text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textStyle,
              ),
            )
          else
            Text(
              parts[i].text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            ),
        ],
      ],
    );
  }
}

class _MetaPart {
  final IconData icon;
  final String text;
  const _MetaPart(this.icon, this.text);
}

class _BillingChip extends StatelessWidget {
  final ClientBilling? billing;
  const _BillingChip({required this.billing});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    final bool isComplete = billing?.isComplete == true;
    final Color bg = isComplete ? cs.secondaryContainer : cs.surfaceContainerHighest;
    final Color fg = isComplete ? cs.onSecondaryContainer : cs.onSurfaceVariant;
    final doc = billing?.documentType ?? 'invoice';
    final docLabel =
        doc == 'receipt' ? l.documentTypeReceipt : l.documentTypeInvoice;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withValues(alpha:0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined, size: 12, color: fg),
          const SizedBox(width: 3),
          Text(
            isComplete ? l.billingComplete : l.billingMissing,
            style: t.bodySmall.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: fg.withValues(alpha:0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              docLabel,
              style: t.bodySmall.copyWith(
                color: fg,
                fontWeight: FontWeight.w700,
                fontSize: 9,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool active;
  const _StatusChip({required this.active});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    // Theme-driven containers for status
    final Color bg = active ? cs.secondaryContainer : cs.errorContainer;
    final Color fg = active ? cs.onSecondaryContainer : cs.onErrorContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withValues(alpha:0.25)),
      ),
      child: Text(
        active ? l.active : l.inactive,
        style: t.bodySmall.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}
