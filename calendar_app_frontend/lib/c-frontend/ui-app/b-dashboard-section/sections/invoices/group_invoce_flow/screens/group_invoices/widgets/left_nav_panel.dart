import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/invoice/billing_profile.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class LeftNavPanel extends StatelessWidget {
  final Group group;
  final AppTypography typography;
  final ColorScheme colorScheme;

  final BillingProfile? billingProfile;
  final bool busyProfile;
  final bool businessExpanded;
  final bool totalsExpanded;
  final int draftsCount;
  final int invoicesCount;

  final VoidCallback onEditBusiness;
  final VoidCallback onToggleBusinessExpanded;
  final VoidCallback onToggleTotalsExpanded;
  final VoidCallback onSelectMenuClients;
  final VoidCallback onSelectMenuInvoices;

  final Widget businessCard;
  final Widget totalsCard;

  const LeftNavPanel({
    super.key,
    required this.group,
    required this.typography,
    required this.colorScheme,
    required this.billingProfile,
    required this.busyProfile,
    required this.businessExpanded,
    required this.totalsExpanded,
    required this.draftsCount,
    required this.invoicesCount,
    required this.onEditBusiness,
    required this.onToggleBusinessExpanded,
    required this.onToggleTotalsExpanded,
    required this.onSelectMenuClients,
    required this.onSelectMenuInvoices,
    required this.businessCard,
    required this.totalsCard,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = typography;
    final cs = colorScheme;

    return SizedBox(
      width: 280,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundImage: NetworkImage(group.photoUrl ?? ''),
                    child:
                        group.photoUrl == null ? const Icon(Icons.group) : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      group.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodyMedium.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              businessCard,
              const SizedBox(height: 12),
              totalsCard,
              const SizedBox(height: 12),
              FilledButton.icon(
                icon: const Icon(Icons.people_outline),
                label: const Text('Clients invoice flow'),
                onPressed: onSelectMenuClients,
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.receipt_long_outlined),
                label: Text(l.invoicesListTitle),
                onPressed: onSelectMenuInvoices,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
