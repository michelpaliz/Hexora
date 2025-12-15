import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/invoice/client_billing.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/l10n/app_localizations.dart';

class ClientListItem extends StatelessWidget {
  final GroupClient client;
  final VoidCallback? onTap;

  /// Typography (injected)
  final TextStyle nameStyle;
  final TextStyle metaStyle;

  const ClientListItem({
    super.key,
    required this.client,
    this.onTap,
    required this.nameStyle,
    required this.metaStyle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      color: cs.surface,
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outlineVariant.withOpacity(0.35), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar / Icon
              CircleAvatar(
                radius: 20,
                backgroundColor: cs.primary.withOpacity(0.10),
                child: Icon(Icons.person_outline, color: cs.primary),
              ),
              const SizedBox(width: 12),

              // Title + details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      client.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: nameStyle,
                    ),
                    const SizedBox(height: 4),

                    // Meta (phone/email)
                    _MetaRow(
                      phone: client.phone,
                      email: client.email,
                      textStyle: metaStyle,
                      iconColor: cs.onSurfaceVariant.withOpacity(0.9),
                    ),
                    if (client.billing != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(Icons.receipt_long_outlined,
                                size: 16, color: cs.onSurfaceVariant),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                client.billing!.legalName?.isNotEmpty == true
                                    ? client.billing!.legalName!
                                    : AppLocalizations.of(context)!
                                        .billingDetails,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: metaStyle.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontStyle:
                                      client.billing!.legalName?.isNotEmpty ==
                                              true
                                          ? null
                                          : FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Status + chevron
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _BillingChip(billing: client.billing),
                  const SizedBox(width: 6),
                  _StatusChip(active: client.isActive),
                  const SizedBox(width: 6),
                  Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                ],
              ),
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
  final TextStyle textStyle;
  final Color iconColor;

  const _MetaRow({
    required this.phone,
    required this.email,
    required this.textStyle,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];

    if ((phone ?? '').isNotEmpty) {
      rows.add(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.phone_rounded, size: 16, color: iconColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              phone!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            ),
          ),
        ],
      ));
    }

    if ((email ?? '').isNotEmpty) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 2));
      rows.add(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.alternate_email_rounded, size: 16, color: iconColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              email!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            ),
          ),
        ],
      ));
    }

    if (rows.isEmpty) {
      rows.add(Text(
        AppLocalizations.of(context)!.contact,
        style: textStyle.copyWith(fontStyle: FontStyle.italic),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows,
    );
  }
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
    final Color bg = isComplete ? cs.secondaryContainer : cs.surfaceVariant;
    final Color fg = isComplete ? cs.onSecondaryContainer : cs.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined, size: 16, color: fg),
          const SizedBox(width: 4),
          Text(
            isComplete ? l.billingComplete : l.billingMissing,
            style: t.bodySmall.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
              letterSpacing: .2,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border:
            Border.all(color: cs.outlineVariant.withOpacity(0.25), width: 1),
        boxShadow: [
          BoxShadow(
            color: ThemeColors.chipGlow(context, bg),
            blurRadius: active ? 8 : 4,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        active ? l.active : l.inactive,
        style: t.bodySmall.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
          letterSpacing: .2,
        ),
      ),
    );
  }
}
