import 'package:hexora/presentation/shared/widgets/sidebar_edge_shell.dart';
import 'package:hexora/presentation/shared/widgets/navigation_group.dart';
import 'package:flutter/material.dart';
import 'package:hexora/theme/themes/navigation_theme.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/models/invoice/billing_profile.dart';
import 'package:hexora/l10n/app_localizations.dart';

import 'side_menu/billing_details_edit.dart';
import 'side_menu/nav_section.dart';
import 'side_menu/sub_menu_item.dart';

bool get _showTaxesInInvoiceSideMenu => false;
bool get _showBillingProfileInInvoiceSideMenu => false;
bool get _showAccountingInInvoiceSideMenu => false;
bool get _showReportsInInvoiceSideMenu => false;
bool get _showLegacyClientsInInvoiceSideMenu => false;

class GroupInvoicesSideMenu extends StatelessWidget {
  static const double expandedWidth = NavigationTokens.sidebarWidth;
  static const double collapsedWidth = NavigationTokens.railWidth;

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
  final bool showOperations;
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
    required this.showOperations,
    required this.onToggleCollapse,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: navigationTheme(Theme.of(context)),
      child: Builder(builder: _buildMenu),
    );
  }

  Widget _buildMenu(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final menuWidth = collapsed ? collapsedWidth : expandedWidth;
    final isEs = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('es');
    final customersLabel = isEs ? 'Clientes' : 'Customers';
    final incomeAnalysisLabel =
        isEs ? 'Análisis de ingresos' : 'Income analysis';
    final recurringLabel = isEs ? 'Recurrentes' : 'Recurring';
    const childIndent = 0.0;

    if (collapsed) {
      final items = <({
        String key,
        IconData icon,
        String label,
        List<CollapsedNavigationDestination> destinations,
      })>[
        (
          key: 'clients',
          icon: Icons.people_outline,
          label: customersLabel,
          destinations: [
            CollapsedNavigationDestination(
              icon: Icons.people_outline,
              label: isEs ? 'Todos' : 'All',
              selected: selectedMenu == 'clients',
              onTap: () => onMenuChanged('clients'),
            ),
            CollapsedNavigationDestination(
              icon: Icons.category_outlined,
              label: l.clientClassificationTitle,
              selected: selectedMenu == 'client_classifications',
              onTap: () => onMenuChanged('client_classifications'),
            ),
            CollapsedNavigationDestination(
              icon: Icons.insights_outlined,
              label: incomeAnalysisLabel,
              selected: selectedMenu == 'client_invoice_stats',
              onTap: () => onMenuChanged('client_invoice_stats'),
            ),
            if (showOperations)
              CollapsedNavigationDestination(
                icon: Icons.design_services_outlined,
                label: isEs
                    ? 'Crear cliente o servicios'
                    : 'Create client or services',
                selected: selectedMenu == 'operations',
                onTap: () => onMenuChanged('operations'),
              ),
          ],
        ),
        (
          key: 'invoices',
          icon: Icons.receipt_long_outlined,
          label: 'Facturación',
          destinations: [
            CollapsedNavigationDestination(
              icon: Icons.add_rounded,
              label: l.createInvoiceCta,
              onTap: onCreateInvoice,
            ),
            CollapsedNavigationDestination(
              icon: Icons.receipt_long_outlined,
              label: 'Facturas emitidas',
              count: issuedCount + draftsCount,
              selected: selectedMenu == 'invoices_issued' ||
                  selectedMenu == 'invoices_drafts',
              onTap: () => onMenuChanged('invoices_issued'),
            ),
            CollapsedNavigationDestination(
              icon: Icons.sync_alt_rounded,
              label: recurringLabel,
              selected: selectedMenu == 'recurring',
              onTap: () => onMenuChanged('recurring'),
            ),
          ],
        ),
        (
          key: 'budgets',
          icon: Icons.request_quote_outlined,
          label: isEs ? 'Presupuestos por partidas' : 'Itemized budgets',
          destinations: [
            CollapsedNavigationDestination(
              icon: Icons.add_rounded,
              label: isEs ? 'Nuevo presupuesto por partidas' : 'New budget',
              onTap: () => onMenuChanged('budgets_new'),
            ),
            CollapsedNavigationDestination(
              icon: Icons.format_list_bulleted_rounded,
              label: isEs ? 'Todos' : 'All',
              selected: selectedMenu == 'budgets_list',
              onTap: () => onMenuChanged('budgets_list'),
            ),
            CollapsedNavigationDestination(
              icon: Icons.account_tree_outlined,
              label: isEs ? 'Convertir presupuesto' : 'Convert budget',
              selected: selectedMenu == 'budgets_convert',
              onTap: () => onMenuChanged('budgets_convert'),
            ),
          ],
        ),
        (
          key: 'receipts',
          icon: Icons.description_outlined,
          label: isEs ? 'Recibos' : 'Receipts',
          destinations: [
            CollapsedNavigationDestination(
              icon: Icons.add_rounded,
              label: l.createReceiptCta,
              onTap: onCreateReceipt,
            ),
            CollapsedNavigationDestination(
              icon: Icons.description_outlined,
              label: isEs ? 'Recibos' : 'Receipts',
              count: receiptsCount,
              selected: selectedMenu == 'receipts',
              onTap: () => onMenuChanged('receipts'),
            ),
            CollapsedNavigationDestination(
              icon: Icons.sync_alt_rounded,
              label: recurringLabel,
              selected: selectedMenu == 'recurring_receipts',
              onTap: () => onMenuChanged('recurring_receipts'),
            ),
          ],
        ),
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
        child: SidebarEdgeShell(
          collapsed: true,
          onToggle: onToggleCollapse,
          child: Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(8, 20, 8, 12),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return CollapsedNavigationGroup(
                      icon: item.icon,
                      title: item.label,
                      selected: item.key == activeKey,
                      destinations: item.destinations,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: menuWidth,
      child: SidebarEdgeShell(
        collapsed: false,
        onToggle: onToggleCollapse,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GroupInvoicesNavSection(
                      title: customersLabel,
                      icon: Icons.people_outline,
                      expanded: clientsExpanded,
                      onToggle: onToggleClientsExpanded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          GroupInvoicesSubMenuItem(
                            icon: Icons.people_outline,
                            label: isEs ? 'Todos' : 'All',
                            selected: selectedMenu == 'clients',
                            indent: childIndent,
                            onPressed: () => onMenuChanged('clients'),
                          ),
                          GroupInvoicesSubMenuItem(
                            icon: Icons.category_outlined,
                            label: l.clientClassificationTitle,
                            selected: selectedMenu == 'client_classifications',
                            indent: childIndent,
                            onPressed: () =>
                                onMenuChanged('client_classifications'),
                          ),
                          GroupInvoicesSubMenuItem(
                            icon: Icons.insights_outlined,
                            label: incomeAnalysisLabel,
                            selected: selectedMenu == 'client_invoice_stats',
                            indent: childIndent,
                            onPressed: () =>
                                onMenuChanged('client_invoice_stats'),
                          ),
                          if (showOperations)
                            GroupInvoicesSubMenuItem(
                              icon: Icons.design_services_outlined,
                              label: isEs
                                  ? 'Crear cliente o servicios'
                                  : 'Create client or services',
                              selected: selectedMenu == 'operations',
                              indent: childIndent,
                              onPressed: () => onMenuChanged('operations'),
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
                    NavigationGroup(
                      title: isEs ? 'Facturas' : 'Invoices',
                      icon: Icons.receipt_long_outlined,
                      initiallyExpanded: facturacionExpanded,
                      storageId: 'billing-tree-invoices',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          GroupInvoicesSubMenuItem(
                            icon: Icons.receipt_long_outlined,
                            label: isEs ? 'Emitidas' : 'Issued',
                            count: issuedCount + draftsCount,
                            selected: selectedMenu == 'invoices_issued' ||
                                selectedMenu == 'invoices_drafts',
                            indent: childIndent,
                            onPressed: () => onMenuChanged('invoices_issued'),
                          ),
                          GroupInvoicesSubMenuItem(
                            icon: Icons.repeat_rounded,
                            label: recurringLabel,
                            selected: selectedMenu == 'recurring',
                            indent: childIndent,
                            onPressed: () => onMenuChanged('recurring'),
                          ),
                          GroupInvoicesSubMenuItem(
                            icon: Icons.add_rounded,
                            label: l.createInvoiceCta,
                            selected: false,
                            primaryAction: true,
                            indent: childIndent,
                            onPressed: onCreateInvoice,
                          ),
                        ],
                      ),
                    ),
                    NavigationGroup(
                      title: isEs
                          ? 'Presupuestos por partidas'
                          : 'Itemized budgets',
                      icon: Icons.request_quote_outlined,
                      initiallyExpanded: facturacionExpanded,
                      storageId: 'billing-tree-budgets',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          GroupInvoicesSubMenuItem(
                            icon: Icons.format_list_bulleted_outlined,
                            label: isEs ? 'Todos' : 'All',
                            selected: selectedMenu == 'budgets_list',
                            indent: childIndent,
                            onPressed: () => onMenuChanged('budgets_list'),
                          ),
                          GroupInvoicesSubMenuItem(
                            icon: Icons.transform_outlined,
                            label: isEs ? 'Convertir' : 'Convert',
                            selected: selectedMenu == 'budgets_convert',
                            indent: childIndent,
                            onPressed: () => onMenuChanged('budgets_convert'),
                          ),
                          GroupInvoicesSubMenuItem(
                            icon: Icons.add_rounded,
                            label: isEs ? 'Nuevo presupuesto' : 'New budget',
                            selected: selectedMenu == 'budgets_new',
                            primaryAction: true,
                            indent: childIndent,
                            onPressed: () => onMenuChanged('budgets_new'),
                          ),
                        ],
                      ),
                    ),
                    NavigationGroup(
                      title: isEs ? 'Recibos' : 'Receipts',
                      icon: Icons.description_outlined,
                      initiallyExpanded: facturacionExpanded,
                      storageId: 'billing-tree-receipts',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          GroupInvoicesSubMenuItem(
                            icon: Icons.description_outlined,
                            label: isEs ? 'Todos' : 'All',
                            count: receiptsCount,
                            selected: selectedMenu == 'receipts',
                            indent: childIndent,
                            onPressed: () => onMenuChanged('receipts'),
                          ),
                          GroupInvoicesSubMenuItem(
                            icon: Icons.repeat_rounded,
                            label: recurringLabel,
                            selected: selectedMenu == 'recurring_receipts',
                            indent: childIndent,
                            onPressed: () =>
                                onMenuChanged('recurring_receipts'),
                          ),
                          GroupInvoicesSubMenuItem(
                            icon: Icons.add_rounded,
                            label: l.createReceiptCta,
                            selected: false,
                            primaryAction: true,
                            indent: childIndent,
                            onPressed: onCreateReceipt,
                          ),
                        ],
                      ),
                    ),
                    if (_showLegacyClientsInInvoiceSideMenu) ...[
                      const SizedBox(height: 8),
                      GroupInvoicesNavSection(
                        title: customersLabel,
                        icon: Icons.people_outline,
                        expanded: clientsExpanded,
                        onToggle: onToggleClientsExpanded,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            GroupInvoicesSubMenuItem(
                              icon: Icons.people_outline,
                              label: isEs ? 'Todos' : 'All',
                              selected: selectedMenu == 'clients',
                              onPressed: () => onMenuChanged('clients'),
                            ),
                            GroupInvoicesSubMenuItem(
                              icon: Icons.insights_outlined,
                              label: incomeAnalysisLabel,
                              selected: selectedMenu == 'client_invoice_stats',
                              onPressed: () =>
                                  onMenuChanged('client_invoice_stats'),
                            ),
                            GroupInvoicesSubMenuItem(
                              icon: Icons.category_outlined,
                              label: l.clientClassificationTitle,
                              selected:
                                  selectedMenu == 'client_classifications',
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
                              icon: Icons.history_rounded,
                              label: 'Historial de lotes',
                              selected:
                                  selectedMenu == 'expenses_import_history',
                              onPressed: () =>
                                  onMenuChanged('expenses_import_history'),
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
                              onPressed: () =>
                                  onMenuChanged('invoices_suspects'),
                            ),
                            GroupInvoicesSubMenuItem(
                              icon: Icons.warning_amber_rounded,
                              label: isEs
                                  ? 'Auditoría IVA gastos'
                                  : 'Expense VAT audit',
                              selected: selectedMenu == 'expenses_suspects',
                              onPressed: () =>
                                  onMenuChanged('expenses_suspects'),
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
      ),
    );
  }
}
