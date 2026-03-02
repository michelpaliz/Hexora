import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/invoice/billing_profile.dart';
import 'package:hexora/l10n/app_localizations.dart';

import 'side_menu/billing_details_edit.dart';
import 'side_menu/nav_section.dart';
import 'side_menu/section_label.dart';
import 'side_menu/sub_menu_item.dart';

class GroupInvoicesSideMenu extends StatelessWidget {
  static const double expandedWidth = 214;

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
    this.compactMode = false,
    required this.onToggleCollapse,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final menuWidth = expandedWidth;

    return SizedBox(
      width: menuWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                  const SizedBox(height: 12),
                  GroupInvoicesNavSection(
                    title: 'Ingresos',
                    icon: Icons.description_outlined,
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
                          onPressed: onCreateInvoice,
                        ),
                        const SizedBox(height: 6),
                        GroupInvoicesSubMenuItem(
                          icon: Icons.receipt_long_outlined,
                          label: 'Emitidas/Borrador',
                          count: issuedCount + draftsCount,
                          selected: selectedMenu == 'invoices_issued' ||
                              selectedMenu == 'invoices_drafts',
                          onPressed: () => onMenuChanged('invoices_issued'),
                        ),
                        const SizedBox(height: 6),
                        GroupInvoicesSubMenuItem(
                          icon: Icons.repeat_rounded,
                          label: 'Recurrentes',
                          selected: selectedMenu == 'recurring',
                          onPressed: () => onMenuChanged('recurring'),
                        ),
                        const SizedBox(height: 10),
                        GroupInvoicesSubMenuItem(
                          icon: Icons.people_outline,
                          label: 'Clientes',
                          selected: selectedMenu == 'clients',
                          onPressed: () => onMenuChanged('clients'),
                        ),
                        const SizedBox(height: 6),
                        GroupInvoicesSubMenuItem(
                          icon: Icons.category_outlined,
                          label: l.clientClassificationTitle,
                          selected: selectedMenu == 'client_classifications',
                          onPressed: () =>
                              onMenuChanged('client_classifications'),
                        ),
                        const SizedBox(height: 10),
                        GroupInvoicesSectionLabel(l.budgetsMenuSection),
                        GroupInvoicesSubMenuItem(
                          icon: Icons.request_quote_outlined,
                          label: l.budgetsMenuNew,
                          selected: selectedMenu == 'budgets_new',
                          onPressed: () => onMenuChanged('budgets_new'),
                        ),
                        const SizedBox(height: 6),
                        GroupInvoicesSubMenuItem(
                          icon: Icons.format_list_bulleted_outlined,
                          label: l.budgetsMenuList,
                          selected: selectedMenu == 'budgets_list',
                          onPressed: () => onMenuChanged('budgets_list'),
                        ),
                        const SizedBox(height: 6),
                        const GroupInvoicesSectionLabel('Recibos'),
                        GroupInvoicesSubMenuItem(
                          icon: Icons.add_rounded,
                          label: l.createReceiptCta,
                          selected: false,
                          onPressed: onCreateReceipt,
                        ),
                        const SizedBox(height: 6),
                        GroupInvoicesSubMenuItem(
                          icon: Icons.description_outlined,
                          label: 'Recibos',
                          count: receiptsCount,
                          selected: selectedMenu == 'receipts',
                          onPressed: () => onMenuChanged('receipts'),
                        ),
                        const SizedBox(height: 6),
                        GroupInvoicesSubMenuItem(
                          icon: Icons.repeat_rounded,
                          label: 'Recurrentes',
                          selected: selectedMenu == 'recurring_receipts',
                          onPressed: () => onMenuChanged('recurring_receipts'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
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
                        const SizedBox(height: 6),
                        GroupInvoicesSubMenuItem(
                          icon: Icons.upload_file_outlined,
                          label: 'Subir gasto',
                          selected: selectedMenu == 'expenses_upload',
                          onPressed: () => onMenuChanged('expenses_upload'),
                        ),
                        const SizedBox(height: 6),
                        GroupInvoicesSubMenuItem(
                          icon: Icons.store_mall_directory_outlined,
                          label: 'Proveedores',
                          selected: selectedMenu == 'providers',
                          onPressed: () => onMenuChanged('providers'),
                        ),
                        const SizedBox(height: 6),
                        GroupInvoicesSubMenuItem(
                          icon: Icons.person_add_outlined,
                          label: 'Nuevo proveedor',
                          selected: selectedMenu == 'provider_new',
                          onPressed: () => onMenuChanged('provider_new'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  GroupInvoicesNavSection(
                    title: 'Impuestos',
                    icon: Icons.percent,
                    expanded: impuestosExpanded,
                    onToggle: onToggleImpuestosExpanded,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GroupInvoicesSubMenuItem(
                          icon: Icons.calculate_outlined,
                          label: 'Resumen IVA',
                          selected: selectedMenu == 'vat',
                          onPressed: () => onMenuChanged('vat'),
                        ),
                        const SizedBox(height: 6),
                        GroupInvoicesSubMenuItem(
                          icon: Icons.calendar_month_outlined,
                          label: 'IVA por trimestre',
                          selected: selectedMenu == 'vat',
                          onPressed: () => onMenuChanged('vat'),
                        ),
                        const SizedBox(height: 6),
                        GroupInvoicesSubMenuItem(
                          icon: Icons.history_toggle_off,
                          label: 'Historico impuestos',
                          selected: false,
                          onPressed: null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
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
                        const SizedBox(height: 6),
                        GroupInvoicesSubMenuItem(
                          icon: Icons.stacked_line_chart_outlined,
                          label: 'Ingresos vs Gastos',
                          selected: false,
                          onPressed: null,
                        ),
                        const SizedBox(height: 6),
                        GroupInvoicesSubMenuItem(
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
