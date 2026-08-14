import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/invoice/billing_profile.dart';
import 'package:hexora/l10n/app_localizations.dart';

import 'side_menu/billing_details_edit.dart';
import 'side_menu/nav_section.dart';
import 'side_menu/section_label.dart';
import 'side_menu/sub_menu_item.dart';

bool get _showTaxesInInvoiceSideMenu => false;
bool get _showBillingProfileInInvoiceSideMenu => false;
bool get _showAccountingInInvoiceSideMenu => false;
bool get _showReportsInInvoiceSideMenu => false;
bool get _showLegacyClientsInInvoiceSideMenu => false;

class GroupInvoicesSideMenu extends StatelessWidget {
  static const double expandedWidth = 224;
  static const double collapsedWidth = 64;

  final Group group;
  final BillingProfile? billingProfile;
  final bool busyProfile;
  final bool businessExpanded;
  final bool facturacionExpanded;
  final bool gastosExpanded;
  final bool impuestosExpanded;
  final bool informesExpanded;
  final bool clientsExpanded;
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
  final VoidCallback onToggleClientsExpanded;
  final String selectedMenu;
  final ValueChanged<String> onMenuChanged;
  final bool collapsed;
  final bool compactMode;
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
    required this.clientsExpanded,
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
    required this.onToggleClientsExpanded,
    required this.selectedMenu,
    required this.onMenuChanged,
    required this.collapsed,
    this.compactMode = false,
    required this.onToggleCollapse,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final menuWidth = collapsed ? collapsedWidth : expandedWidth;
    final cs = Theme.of(context).colorScheme;
    final isEs = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('es');
    const childIndent = 12.0;

    if (collapsed) {
      final items = <({String key, IconData icon, String label})>[
        (key: 'clients', icon: Icons.people_outline, label: 'Clientes'),
        (
          key: 'invoices',
          icon: Icons.receipt_long_outlined,
          label: 'Facturacion'
        ),
        (
          key: 'budgets',
          icon: Icons.request_quote_outlined,
          label: 'Presupuestos'
        ),
        (key: 'receipts', icon: Icons.description_outlined, label: 'Recibos'),
      ];
      final activeKey =
          selectedMenu.startsWith('invoice') || selectedMenu == 'recurring'
              ? 'invoices'
              : selectedMenu.startsWith('budget')
                  ? 'budgets'
                  : selectedMenu.startsWith('receipt') ||
                          selectedMenu == 'recurring_receipts'
                      ? 'receipts'
                      : 'clients';
      return AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: menuWidth,
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.42)),
          ),
        ),
        child: Column(
          children: [
            Align(
              alignment: Alignment.center,
              child: IconButton.filledTonal(
                tooltip: isEs ? 'Expandir menú' : 'Expand menu',
                onPressed: onToggleCollapse,
                icon: const Icon(Icons.keyboard_double_arrow_right_rounded),
                style: IconButton.styleFrom(
                  minimumSize: const Size(42, 42),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final selected = item.key == activeKey;
                  return Tooltip(
                    message: item.label,
                    waitDuration: const Duration(milliseconds: 350),
                    child: Center(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          switch (item.key) {
                            case 'invoices':
                              onMenuChanged('invoices_issued');
                              break;
                            case 'budgets':
                              onMenuChanged('budgets_list');
                              break;
                            case 'receipts':
                              onMenuChanged('receipts');
                              break;
                            case 'clients':
                              onMenuChanged('clients');
                              break;
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          curve: Curves.easeOutCubic,
                          width: 48,
                          height: 44,
                          decoration: BoxDecoration(
                            color: selected
                                ? cs.primary.withValues(alpha: 0.13)
                                : cs.surfaceContainerHighest
                                    .withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                              color: selected
                                  ? cs.primary.withValues(alpha: 0.25)
                                  : cs.outlineVariant.withValues(alpha: 0.18),
                            ),
                          ),
                          child: Icon(
                            item.icon,
                            size: 19,
                            color: selected ? cs.primary : cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: menuWidth,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.36)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 6, 8, 8),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.34),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.38),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.receipt_long_outlined,
                      size: 18,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ingresos',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: cs.onSurface,
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                        Text(
                          'Menu de datos',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Tooltip(
                    message: isEs ? 'Compactar menú' : 'Collapse menu',
                    child: IconButton.filledTonal(
                      onPressed: onToggleCollapse,
                      icon:
                          const Icon(Icons.keyboard_double_arrow_left_rounded),
                      iconSize: 18,
                      style: IconButton.styleFrom(
                        minimumSize: const Size(40, 34),
                        fixedSize: const Size(40, 34),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GroupInvoicesNavSection(
                    title: 'Clientes',
                    icon: Icons.people_outline,
                    expanded: clientsExpanded,
                    onToggle: onToggleClientsExpanded,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GroupInvoicesSubMenuItem(
                          icon: Icons.people_outline,
                          label: 'Clientes',
                          selected: selectedMenu == 'clients',
                          onPressed: () => onMenuChanged('clients'),
                        ),
                        GroupInvoicesSubMenuItem(
                          icon: Icons.category_outlined,
                          label: l.clientClassificationTitle,
                          selected: selectedMenu == 'client_classifications',
                          onPressed: () =>
                              onMenuChanged('client_classifications'),
                        ),
                        GroupInvoicesSubMenuItem(
                          icon: Icons.insights_outlined,
                          label: 'Análisis de ingresos',
                          selected: selectedMenu == 'client_invoice_stats',
                          onPressed: () =>
                              onMenuChanged('client_invoice_stats'),
                        ),
                      ],
                    ),
                  ),
                  if (_showBillingProfileInInvoiceSideMenu) ...[
                    const SizedBox(height: 8),
                    GroupInvoicesNavSection(
                      title: l.billingDetails,
                      icon: Icons.receipt_long_outlined,
                      expanded: businessExpanded,
                      onToggle: onToggleBusinessExpanded,
                      child: GroupInvoicesBillingDetailsEdit(
                        busy: busyProfile,
                        onEdit: onEditBillingProfile,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  GroupInvoicesNavSection(
                    title: 'Facturación',
                    icon: Icons.receipt_long_outlined,
                    expanded: facturacionExpanded,
                    onToggle: onToggleFacturacionExpanded,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const GroupInvoicesSectionLabel('Facturas'),
                        GroupInvoicesSubMenuItem(
                          icon: Icons.add_rounded,
                          label: l.createInvoiceCta,
                          selected: false,
                          primaryAction: true,
                          indent: childIndent,
                          onPressed: onCreateInvoice,
                        ),
                        GroupInvoicesSubMenuItem(
                          icon: Icons.receipt_long_outlined,
                          label: 'Facturas emitidas',
                          count: issuedCount + draftsCount,
                          selected: selectedMenu == 'invoices_issued' ||
                              selectedMenu == 'invoices_drafts',
                          indent: childIndent,
                          onPressed: () => onMenuChanged('invoices_issued'),
                        ),
                        GroupInvoicesSubMenuItem(
                          icon: Icons.repeat_rounded,
                          label: 'Recurrentes',
                          selected: selectedMenu == 'recurring',
                          indent: childIndent,
                          onPressed: () => onMenuChanged('recurring'),
                        ),
                        const SizedBox(height: 4),
                        GroupInvoicesSectionLabel(l.budgetsMenuSection),
                        GroupInvoicesSubMenuItem(
                          icon: Icons.add_rounded,
                          label: l.budgetsMenuNew,
                          selected: selectedMenu == 'budgets_new',
                          primaryAction: true,
                          indent: childIndent,
                          onPressed: () => onMenuChanged('budgets_new'),
                        ),
                        GroupInvoicesSubMenuItem(
                          icon: Icons.format_list_bulleted_outlined,
                          label: l.budgetsMenuList,
                          selected: selectedMenu == 'budgets_list',
                          indent: childIndent,
                          onPressed: () => onMenuChanged('budgets_list'),
                        ),
                        GroupInvoicesSubMenuItem(
                          icon: Icons.transform_outlined,
                          label: 'Convertir presupuesto',
                          selected: selectedMenu == 'budgets_convert',
                          indent: childIndent,
                          onPressed: () => onMenuChanged('budgets_convert'),
                        ),
                        const SizedBox(height: 4),
                        const GroupInvoicesSectionLabel('Recibos'),
                        GroupInvoicesSubMenuItem(
                          icon: Icons.add_rounded,
                          label: l.createReceiptCta,
                          selected: false,
                          primaryAction: true,
                          indent: childIndent,
                          onPressed: onCreateReceipt,
                        ),
                        GroupInvoicesSubMenuItem(
                          icon: Icons.description_outlined,
                          label: 'Recibos',
                          count: receiptsCount,
                          selected: selectedMenu == 'receipts',
                          indent: childIndent,
                          onPressed: () => onMenuChanged('receipts'),
                        ),
                        GroupInvoicesSubMenuItem(
                          icon: Icons.repeat_rounded,
                          label: 'Recurrentes',
                          selected: selectedMenu == 'recurring_receipts',
                          indent: childIndent,
                          onPressed: () => onMenuChanged('recurring_receipts'),
                        ),
                      ],
                    ),
                  ),
                  if (_showLegacyClientsInInvoiceSideMenu) ...[
                    const SizedBox(height: 8),
                    GroupInvoicesNavSection(
                      title: 'Clientes',
                      icon: Icons.people_outline,
                      expanded: clientsExpanded,
                      onToggle: onToggleClientsExpanded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          GroupInvoicesSubMenuItem(
                            icon: Icons.people_outline,
                            label: 'Clientes',
                            selected: selectedMenu == 'clients',
                            onPressed: () => onMenuChanged('clients'),
                          ),
                          GroupInvoicesSubMenuItem(
                            icon: Icons.insights_outlined,
                            label: 'Análisis de ingresos',
                            selected: selectedMenu == 'client_invoice_stats',
                            onPressed: () =>
                                onMenuChanged('client_invoice_stats'),
                          ),
                          GroupInvoicesSubMenuItem(
                            icon: Icons.category_outlined,
                            label: l.clientClassificationTitle,
                            selected: selectedMenu == 'client_classifications',
                            onPressed: () =>
                                onMenuChanged('client_classifications'),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_showAccountingInInvoiceSideMenu) ...[
                    const SizedBox(height: 8),
                    GroupInvoicesNavSection(
                      title: 'Gastos',
                      icon: Icons.trending_down_outlined,
                      expanded: gastosExpanded,
                      onToggle: onToggleGastosExpanded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          GroupInvoicesSubMenuItem(
                            icon: Icons.receipt_outlined,
                            label: 'Listar gastos',
                            selected: selectedMenu == 'expenses_list',
                            onPressed: () => onMenuChanged('expenses_list'),
                          ),
                          GroupInvoicesSubMenuItem(
                            icon: Icons.upload_file_outlined,
                            label: 'Subir gasto',
                            selected: selectedMenu == 'expenses_upload',
                            onPressed: () => onMenuChanged('expenses_upload'),
                          ),
                          GroupInvoicesSubMenuItem(
                            icon: Icons.store_mall_directory_outlined,
                            label: 'Proveedores',
                            selected: selectedMenu == 'providers',
                            onPressed: () => onMenuChanged('providers'),
                          ),
                          GroupInvoicesSubMenuItem(
                            icon: Icons.person_add_outlined,
                            label: 'Nuevo proveedor',
                            selected: selectedMenu == 'provider_new',
                            onPressed: () => onMenuChanged('provider_new'),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_showTaxesInInvoiceSideMenu) ...[
                    const SizedBox(height: 8),
                    GroupInvoicesNavSection(
                      title: 'Impuestos',
                      icon: Icons.percent,
                      expanded: impuestosExpanded,
                      onToggle: onToggleImpuestosExpanded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          GroupInvoicesSubMenuItem(
                            icon: Icons.calendar_month_outlined,
                            label: 'IVA por trimestre',
                            selected: selectedMenu == 'vat',
                            onPressed: () => onMenuChanged('vat'),
                          ),
                          GroupInvoicesSubMenuItem(
                            icon: Icons.warning_amber_rounded,
                            label: isEs
                                ? 'Auditoría IVA ingresos'
                                : 'Income VAT audit',
                            selected: selectedMenu == 'invoices_suspects',
                            onPressed: () => onMenuChanged('invoices_suspects'),
                          ),
                          GroupInvoicesSubMenuItem(
                            icon: Icons.warning_amber_rounded,
                            label: isEs
                                ? 'Auditoría IVA gastos'
                                : 'Expense VAT audit',
                            selected: selectedMenu == 'expenses_suspects',
                            onPressed: () => onMenuChanged('expenses_suspects'),
                          ),
                          GroupInvoicesSubMenuItem(
                            icon: Icons.compare_arrows_rounded,
                            label: isEs
                                ? 'Comparar Excel de asesoría'
                                : 'Compare accountant Excel',
                            selected:
                                selectedMenu == 'invoices_accountant_compare',
                            onPressed: () =>
                                onMenuChanged('invoices_accountant_compare'),
                          ),
                          const GroupInvoicesSubMenuItem(
                            icon: Icons.history_toggle_off,
                            label: 'Historico impuestos',
                            selected: false,
                            onPressed: null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (_showReportsInInvoiceSideMenu)
                    GroupInvoicesNavSection(
                      title: 'Informes',
                      icon: Icons.insights_outlined,
                      expanded: informesExpanded,
                      onToggle: onToggleInformesExpanded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          GroupInvoicesSubMenuItem(
                            icon: Icons.account_tree_outlined,
                            label: l.groupInvoicesClientsFlowCta,
                            selected: selectedMenu == 'clients_flow',
                            onPressed: () => onMenuChanged('clients_flow'),
                          ),
                          const GroupInvoicesSubMenuItem(
                            icon: Icons.stacked_line_chart_outlined,
                            label: 'Ingresos vs Gastos',
                            selected: false,
                            onPressed: null,
                          ),
                          const GroupInvoicesSubMenuItem(
                            icon: Icons.show_chart_outlined,
                            label: 'Beneficio neto',
                            selected: false,
                            onPressed: null,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
