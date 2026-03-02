import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/invoice/billing_profile.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';

class GroupInvoicesCompanyHeader extends StatelessWidget {
  final Group group;
  final BillingProfile? billingProfile;
  final bool busyProfile;
  final VoidCallback onEdit;

  const GroupInvoicesCompanyHeader({
    super.key,
    required this.group,
    required this.billingProfile,
    required this.busyProfile,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final name = billingProfile?.legalName.trim().isNotEmpty == true
        ? billingProfile!.legalName.trim()
        : group.name;
    final logoUrl = billingProfile?.logoUrl?.trim();
    final hasLogo = logoUrl != null && logoUrl.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: cs.surface,
                child: hasLogo
                    ? ClipOval(
                        child: Image.network(
                          logoUrl!,
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(
                        Icons.receipt_long_outlined,
                        color: cs.onSurfaceVariant,
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodyMedium.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
