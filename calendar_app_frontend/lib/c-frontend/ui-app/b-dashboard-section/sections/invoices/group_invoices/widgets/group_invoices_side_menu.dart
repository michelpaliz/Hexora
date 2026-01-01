import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/invoice/billing_profile.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/billing_profile_summary_card.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class GroupInvoicesSideMenu extends StatelessWidget {
  static const double expandedWidth = 280;
  static const double collapsedWidth = 86;

  final Group group;
  final BillingProfile? billingProfile;
  final bool busyProfile;
  final bool businessExpanded;
  final bool totalsExpanded;
  final int issuedCount;
  final int draftsCount;
  final VoidCallback onEditBillingProfile;
  final VoidCallback onToggleBusinessExpanded;
  final VoidCallback onToggleTotalsExpanded;
  final String selectedMenu;
  final ValueChanged<String> onMenuChanged;
  final bool collapsed;
  final VoidCallback onToggleCollapse;

  const GroupInvoicesSideMenu({
    super.key,
    required this.group,
    required this.billingProfile,
    required this.busyProfile,
    required this.businessExpanded,
    required this.totalsExpanded,
    required this.issuedCount,
    required this.draftsCount,
    required this.onEditBillingProfile,
    required this.onToggleBusinessExpanded,
    required this.onToggleTotalsExpanded,
    required this.selectedMenu,
    required this.onMenuChanged,
    required this.collapsed,
    required this.onToggleCollapse,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    final menuWidth = collapsed ? collapsedWidth : expandedWidth;

    return SizedBox(
      width: menuWidth,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: collapsed
                        ? l.groupInvoicesNavExpand
                        : l.groupInvoicesNavCollapse,
                    onPressed: onToggleCollapse,
                    icon: Icon(
                      collapsed ? Icons.chevron_right : Icons.chevron_left,
                    ),
                  ),
                  if (!collapsed) ...[
                    CircleAvatar(
                      radius: 22,
                      backgroundImage: NetworkImage(group.photoUrl ?? ''),
                      child: group.photoUrl == null
                          ? const Icon(Icons.group)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        group.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodyMedium.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (!collapsed) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: onToggleBusinessExpanded,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Text(
                                  l.groupInvoicesBusinessTitle,
                                  style: t.bodySmall.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: l.edit,
                            onPressed: busyProfile ? null : onEditBillingProfile,
                            icon: busyProfile
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: businessExpanded
                                ? l.groupInvoicesCollapseTooltip
                                : l.groupInvoicesExpandTooltip,
                            onPressed: onToggleBusinessExpanded,
                            icon: Icon(
                              businessExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                            ),
                          ),
                        ],
                      ),
                      BillingProfileSummaryCard(
                        profile: billingProfile,
                        expanded: businessExpanded,
                        onToggleExpanded: onToggleBusinessExpanded,
                      ),
                      const SizedBox(height: 10),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: busyProfile ? null : onEditBillingProfile,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: cs.outlineVariant.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: SizedBox(
                                  width: 34,
                                  height: 34,
                                  child: (billingProfile?.logoUrl
                                              ?.trim()
                                              .isNotEmpty ==
                                          true)
                                      ? Image.network(
                                          billingProfile!.logoUrl!.trim(),
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Container(
                                            color: cs.surfaceContainerHighest,
                                            child: Icon(
                                              Icons.image_not_supported_outlined,
                                              color: cs.onSurfaceVariant,
                                            ),
                                          ),
                                        )
                                      : Container(
                                          color: cs.surfaceContainerHighest,
                                          child: Icon(
                                            Icons.image_outlined,
                                            color: cs.onSurfaceVariant,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l.invoiceLogoTitle,
                                      style: t.bodySmall.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      billingProfile?.logoUrl
                                                  ?.trim()
                                                  .isNotEmpty ==
                                              true
                                          ? billingProfile!.logoUrl!.trim()
                                          : l.invoiceLogoUploadCta,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: t.bodySmall.copyWith(
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Icon(
                                Icons.chevron_right,
                                color: cs.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: onToggleTotalsExpanded,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Text(
                                  l.groupInvoicesTotalsTitle,
                                  style: t.bodySmall.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: totalsExpanded
                                ? l.groupInvoicesCollapseTooltip
                                : l.groupInvoicesExpandTooltip,
                            onPressed: onToggleTotalsExpanded,
                            icon: Icon(
                              totalsExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                            ),
                          ),
                        ],
                      ),
                      if (!totalsExpanded)
                        Text(
                          l.groupInvoicesTotalsInline(issuedCount, draftsCount),
                          style: t.bodySmall.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      else ...[
                        const SizedBox(height: 10),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 160),
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    icon: const Icon(
                                      Icons.check_circle_outline,
                                    ),
                                    label: Text(
                                      l.groupInvoicesTotalsIssuedButton(
                                        issuedCount,
                                      ),
                                    ),
                                    onPressed: () {},
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.tonalIcon(
                                    icon: const Icon(
                                      Icons.drafts_outlined,
                                    ),
                                    label: Text(
                                      l.groupInvoicesTotalsDraftsButton(
                                        draftsCount,
                                      ),
                                    ),
                                    onPressed: () {},
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  icon: const Icon(Icons.people_outline),
                  label: Text(l.groupInvoicesClientsFlowCta),
                  onPressed: () => onMenuChanged('clients'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: Text(l.invoicesListTitle),
                  onPressed: () => onMenuChanged('invoices'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.description_outlined),
                  label: Text(l.receiptsTitle),
                  onPressed: () => onMenuChanged('receipts'),
                ),
              ] else ...[
                const SizedBox(height: 16),
                _MenuIconButton(
                  icon: Icons.people_outline,
                  label: l.groupInvoicesClientsFlowCta,
                  selected: selectedMenu == 'clients',
                  onPressed: () => onMenuChanged('clients'),
                ),
                const SizedBox(height: 8),
                _MenuIconButton(
                  icon: Icons.receipt_long_outlined,
                  label: l.invoicesListTitle,
                  selected: selectedMenu == 'invoices',
                  onPressed: () => onMenuChanged('invoices'),
                ),
                const SizedBox(height: 8),
                _MenuIconButton(
                  icon: Icons.description_outlined,
                  label: l.receiptsTitle,
                  selected: selectedMenu == 'receipts',
                  onPressed: () => onMenuChanged('receipts'),
                ),
              ],
              if (selectedMenu.isNotEmpty) const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuIconButton extends StatelessWidget {
  const _MenuIconButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = selected ? cs.primaryContainer : cs.surface;
    final fg = selected ? cs.onPrimaryContainer : cs.onSurface;
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Icon(icon, color: fg),
        ),
      ),
    );
  }
}
