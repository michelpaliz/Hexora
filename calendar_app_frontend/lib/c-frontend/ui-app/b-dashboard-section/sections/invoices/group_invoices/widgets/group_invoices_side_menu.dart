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
  final bool facturacionExpanded;
  final bool gastosExpanded;
  final bool impuestosExpanded;
  final bool informesExpanded;
  final int issuedCount;
  final int draftsCount;
  final int receiptsCount;
  final VoidCallback onCreateInvoice;
  final VoidCallback onCreateReceipt;
  final VoidCallback onEditBillingProfile;
  final VoidCallback onToggleBusinessExpanded;
  final VoidCallback onToggleFacturacionExpanded;
  final VoidCallback onToggleGastosExpanded;
  final VoidCallback onToggleImpuestosExpanded;
  final VoidCallback onToggleInformesExpanded;
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
    required this.facturacionExpanded,
    required this.gastosExpanded,
    required this.impuestosExpanded,
    required this.informesExpanded,
    required this.issuedCount,
    required this.draftsCount,
    required this.receiptsCount,
    required this.onCreateInvoice,
    required this.onCreateReceipt,
    required this.onEditBillingProfile,
    required this.onToggleBusinessExpanded,
    required this.onToggleFacturacionExpanded,
    required this.onToggleGastosExpanded,
    required this.onToggleImpuestosExpanded,
    required this.onToggleInformesExpanded,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
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
                  if (!collapsed) const Spacer(),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!collapsed) ...[
                      _CompanyHeader(
                        group: group,
                        billingProfile: billingProfile,
                        busyProfile: busyProfile,
                        expanded: businessExpanded,
                        onToggleExpanded: onToggleBusinessExpanded,
                        onEdit: onEditBillingProfile,
                      ),
                      const SizedBox(height: 12),
                      _NavSection(
                        title: 'Ingresos',
                        icon: Icons.description_outlined,
                        expanded: facturacionExpanded,
                        onToggle: onToggleFacturacionExpanded,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _SectionLabel('Facturas'),
                            _SubMenuItem(
                              icon: Icons.add_rounded,
                              label: l.createInvoiceCta,
                              selected: false,
                              onPressed: onCreateInvoice,
                            ),
                            const SizedBox(height: 6),
                            _SubMenuItem(
                              icon: Icons.receipt_long_outlined,
                              label: 'Emitidas/Borrador',
                              count: issuedCount + draftsCount,
                              selected: selectedMenu == 'invoices_issued' ||
                                  selectedMenu == 'invoices_drafts',
                              onPressed: () => onMenuChanged('invoices_issued'),
                            ),
                            const SizedBox(height: 6),
                            _SubMenuItem(
                              icon: Icons.repeat_rounded,
                              label: 'Recurrentes',
                              selected: selectedMenu == 'recurring',
                              onPressed: () => onMenuChanged('recurring'),
                            ),
                            const SizedBox(height: 10),
                            _SubMenuItem(
                              icon: Icons.people_outline,
                              label: 'Clientes',
                              selected: selectedMenu == 'clients',
                              onPressed: () => onMenuChanged('clients'),
                            ),
                            const SizedBox(height: 6),
                            _SubMenuItem(
                              icon: Icons.category_outlined,
                              label: l.clientClassificationTitle,
                              selected:
                                  selectedMenu == 'client_classifications',
                              onPressed: () =>
                                  onMenuChanged('client_classifications'),
                            ),
                            const SizedBox(height: 6),
                            const _SectionLabel('Recibos'),
                            _SubMenuItem(
                              icon: Icons.add_rounded,
                              label: l.createReceiptCta,
                              selected: false,
                              onPressed: onCreateReceipt,
                            ),
                            const SizedBox(height: 6),
                            _SubMenuItem(
                              icon: Icons.description_outlined,
                              label: 'Recibos',
                              count: receiptsCount,
                              selected: selectedMenu == 'receipts',
                              onPressed: () => onMenuChanged('receipts'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      _NavSection(
                        title: 'Gastos',
                        icon: Icons.trending_down_outlined,
                        expanded: gastosExpanded,
                        onToggle: onToggleGastosExpanded,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _PrimaryMenuItem(
                              icon: Icons.upload_file_outlined,
                              label: 'Subir gasto',
                              selected: selectedMenu == 'expenses_upload',
                              onPressed: () => onMenuChanged('expenses_upload'),
                            ),
                            const SizedBox(height: 6),
                            _SubMenuItem(
                              icon: Icons.store_mall_directory_outlined,
                              label: 'Proveedores',
                              selected: selectedMenu == 'providers',
                              onPressed: () => onMenuChanged('providers'),
                            ),
                            const SizedBox(height: 6),
                            _SubMenuItem(
                              icon: Icons.receipt_outlined,
                              label: 'Gastos registrados',
                              selected: selectedMenu == 'expenses_list',
                              onPressed: () => onMenuChanged('expenses_list'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      _NavSection(
                        title: 'Impuestos',
                        icon: Icons.percent,
                        expanded: impuestosExpanded,
                        onToggle: onToggleImpuestosExpanded,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _SubMenuItem(
                              icon: Icons.calculate_outlined,
                              label: 'Resumen IVA',
                              selected: selectedMenu == 'vat',
                              onPressed: () => onMenuChanged('vat'),
                            ),
                            const SizedBox(height: 6),
                            _SubMenuItem(
                              icon: Icons.calendar_month_outlined,
                              label: 'IVA por trimestre',
                              selected: selectedMenu == 'vat',
                              onPressed: () => onMenuChanged('vat'),
                            ),
                            const SizedBox(height: 6),
                            _SubMenuItem(
                              icon: Icons.history_toggle_off,
                              label: 'Histórico impuestos',
                              selected: false,
                              onPressed: null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      _NavSection(
                        title: 'Informes',
                        icon: Icons.insights_outlined,
                        expanded: informesExpanded,
                        onToggle: onToggleInformesExpanded,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _SubMenuItem(
                              icon: Icons.account_tree_outlined,
                              label: l.groupInvoicesClientsFlowCta,
                              selected: selectedMenu == 'clients_flow',
                              onPressed: () => onMenuChanged('clients_flow'),
                            ),
                            const SizedBox(height: 6),
                            _SubMenuItem(
                              icon: Icons.stacked_line_chart_outlined,
                              label: 'Ingresos vs Gastos',
                              selected: false,
                              onPressed: null,
                            ),
                            const SizedBox(height: 6),
                            _SubMenuItem(
                              icon: Icons.show_chart_outlined,
                              label: 'Beneficio neto',
                              selected: false,
                              onPressed: null,
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 16),
                      _MenuIconButton(
                        icon: Icons.add_rounded,
                        label: l.createInvoiceCta,
                        selected: false,
                        onPressed: onCreateInvoice,
                      ),
                      const SizedBox(height: 8),
                      _MenuIconButton(
                        icon: Icons.receipt_long_outlined,
                        label: 'Emitidas/Borrador',
                        selected: selectedMenu == 'invoices_issued' ||
                            selectedMenu == 'invoices_drafts',
                        onPressed: () => onMenuChanged('invoices_issued'),
                      ),
                      const SizedBox(height: 8),
                      _MenuIconButton(
                        icon: Icons.repeat_rounded,
                        label: 'Recurrentes',
                        selected: selectedMenu == 'recurring',
                        onPressed: () => onMenuChanged('recurring'),
                      ),
                      const SizedBox(height: 8),
                      _MenuIconButton(
                        icon: Icons.people_outline,
                        label: 'Clientes',
                        selected: selectedMenu == 'clients',
                        onPressed: () => onMenuChanged('clients'),
                      ),
                      const SizedBox(height: 8),
                      _MenuIconButton(
                        icon: Icons.category_outlined,
                        label: l.clientClassificationTitle,
                        selected: selectedMenu == 'client_classifications',
                        onPressed: () =>
                            onMenuChanged('client_classifications'),
                      ),
                      _MenuIconButton(
                        icon: Icons.description_outlined,
                        label: 'Recibos',
                        selected: selectedMenu == 'receipts',
                        onPressed: () => onMenuChanged('receipts'),
                      ),
                      const SizedBox(height: 8),
                      _MenuIconButton(
                        icon: Icons.add_rounded,
                        label: l.createReceiptCta,
                        selected: false,
                        onPressed: onCreateReceipt,
                      ),
                      const SizedBox(height: 8),
                      _MenuIconButton(
                        icon: Icons.upload_file_outlined,
                        label: 'Subir gasto',
                        selected: selectedMenu == 'expenses_upload',
                        onPressed: () => onMenuChanged('expenses_upload'),
                      ),
                      const SizedBox(height: 8),
                      _MenuIconButton(
                        icon: Icons.store_mall_directory_outlined,
                        label: 'Proveedores',
                        selected: selectedMenu == 'providers',
                        onPressed: () => onMenuChanged('providers'),
                      ),
                      const SizedBox(height: 8),
                      _MenuIconButton(
                        icon: Icons.percent,
                        label: 'Resumen IVA',
                        selected: selectedMenu == 'vat',
                        onPressed: () => onMenuChanged('vat'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompanyHeader extends StatelessWidget {
  final Group group;
  final BillingProfile? billingProfile;
  final bool busyProfile;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final VoidCallback onEdit;

  const _CompanyHeader({
    required this.group,
    required this.billingProfile,
    required this.busyProfile,
    required this.expanded,
    required this.onToggleExpanded,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
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
        color: cs.surfaceContainerHighest,
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
              TextButton(
                onPressed: busyProfile ? null : onEdit,
                child: busyProfile
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'Editar',
                        style:
                            t.bodySmall.copyWith(fontWeight: FontWeight.w800),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onToggleExpanded,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Text(
                    l.billingDetails,
                    style: t.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    color: cs.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            BillingProfileSummaryCard(
              profile: billingProfile,
              expanded: expanded,
              onToggleExpanded: onToggleExpanded,
            ),
        ],
      ),
    );
  }
}

class _NavSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  const _NavSection({
    required this.title,
    required this.icon,
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: cs.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: t.bodySmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    color: cs.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const SizedBox(height: 6),
            child,
          ],
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Text(
        label.toUpperCase(),
        style: t.bodySmall.copyWith(
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _PrimaryMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  const _PrimaryMenuItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final bg = selected ? cs.primary : cs.primaryContainer;
    final fg = selected ? cs.onPrimary : cs.onPrimaryContainer;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: t.bodySmall.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
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

class _SubMenuItem extends StatelessWidget {
  const _SubMenuItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onPressed,
    this.count,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onPressed;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final enabled = onPressed != null;
    final bg = selected ? cs.primaryContainer : cs.surface;
    final fg = selected
        ? cs.onPrimaryContainer
        : (enabled ? cs.onSurfaceVariant : cs.outline);
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: enabled ? bg : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled
                ? cs.outlineVariant.withOpacity(0.5)
                : cs.outlineVariant.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: t.bodySmall.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (count != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: t.bodySmall.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            if (!enabled)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text(
                  'Pronto',
                  style: t.bodySmall.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
