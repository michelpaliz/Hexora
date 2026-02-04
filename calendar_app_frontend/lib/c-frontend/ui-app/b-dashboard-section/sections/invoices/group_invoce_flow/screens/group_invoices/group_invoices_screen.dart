import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/invoice/billing_profile.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/group_invoices/widgets/business_card.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/group_invoices/widgets/clients_flow_view.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/group_invoices/widgets/invoices_flow_view.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/group_invoices/widgets/left_nav_panel.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/group_invoices/widgets/totals_card.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/client_billing_view.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_details_sheet/invoice_detail_sheet.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_list_item.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/widgets/common_views.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

import 'group_invoices_controller.dart';

class GroupInvoicesScreen extends StatefulWidget {
  final Group group;
  const GroupInvoicesScreen({super.key, required this.group});

  @override
  State<GroupInvoicesScreen> createState() => _GroupInvoicesScreenState();
}

class _GroupInvoicesScreenState extends State<GroupInvoicesScreen> {
  late final GroupInvoicesController _c;

  @override
  void initState() {
    super.initState();
    _c = GroupInvoicesController(group: widget.group);
    _c.loadAll();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  GroupClient _clientOrUnknown(
      AppLocalizations l, List<GroupClient> clients, String id) {
    return clients.firstWhere(
      (c) => c.id == id,
      orElse: () => GroupClient(id: id, name: l.unknownClient, isActive: true),
    );
  }

  void _openInvoiceDetailSheet({
    required Invoice invoice,
    required List<GroupClient> clients,
    required BillingProfile? billingProfile,
  }) {
    final l = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => InvoiceDetailSheet(
        invoice: invoice,
        client: _clientOrUnknown(l, clients, invoice.clientId),
        billingProfile: billingProfile,
        group: widget.group,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final s = _c.state;

        Widget body;
        if (s.loading) {
          body = const Center(child: CircularProgressIndicator());
        } else if (s.error != null) {
          body = ErrorView(message: s.error!, onRetry: _c.loadAll);
        } else {
          final visibleInvoices = _c.visibleInvoicesForSelectedClient();
          final draftInvoices = _c.visibleDraftsForSelectedClient();

          body = RefreshIndicator(
            onRefresh: _c.loadAll,
            child: Row(
              children: [
                LeftNavPanel(
                  group: widget.group,
                  typography: t,
                  colorScheme: cs,
                  billingProfile: s.billingProfile,
                  busyProfile: s.busyProfile,
                  businessExpanded: s.businessExpanded,
                  totalsExpanded: s.totalsExpanded,
                  draftsCount: s.drafts.length,
                  invoicesCount: s.invoices.length,
                  onEditBusiness: () => _c.openBillingProfile(context),
                  onToggleBusinessExpanded: _c.toggleBusinessExpanded,
                  onToggleTotalsExpanded: _c.toggleTotalsExpanded,
                  onSelectMenuClients: () => _c.setMenu('clients'),
                  onSelectMenuInvoices: () => _c.setMenu('invoices'),
                  businessCard: BusinessCard(
                    typography: t,
                    colorScheme: cs,
                    billingProfile: s.billingProfile,
                    expanded: s.businessExpanded,
                    onEdit: s.busyProfile
                        ? null
                        : () => _c.openBillingProfile(context),
                    onToggleExpanded: _c.toggleBusinessExpanded,
                    formatBillingAddress: (p) => _c.formatBillingAddress(p),
                  ),
                  totalsCard: TotalsCard(
                    typography: t,
                    colorScheme: cs,
                    expanded: s.totalsExpanded,
                    draftsCount: s.drafts.length,
                    invoicesCount: s.invoices.length,
                    onToggleExpanded: _c.toggleTotalsExpanded,
                  ),
                ),
                Expanded(
                  child: s.selectedMenu == 'clients'
                      ? ClientsFlowView(
                          typography: t,
                          colorScheme: cs,
                          clients: s.clients,
                          selectedClient: s.selectedClient,
                          visibleInvoices: visibleInvoices,
                          draftInvoices: draftInvoices,
                          onSelectClient: _c.selectClient,
                          onEditClient: (c) => _c.openEditClient(context, c),
                          onCreateInvoice: () => _c.openCreateInvoice(context),
                          onOpenInvoiceDetail: (inv) => _openInvoiceDetailSheet(
                            invoice: inv,
                            clients: s.clients,
                            billingProfile: s.billingProfile,
                          ),
                          onDeleteInvoice: (inv) =>
                              _c.deleteInvoice(context, inv),
                          onEditDraft: (inv) =>
                              _c.openEditDraft(context, inv),
                          clientBillingViewBuilder: (client) =>
                              ClientBillingView(
                            client: client,
                            headline: t.bodyMedium
                                .copyWith(fontWeight: FontWeight.w800),
                            onSurface: cs.onSurface,
                          ),
                          invoiceTileBuilder: (
                              {required Invoice invoice,
                              required GroupClient client,
                              VoidCallback? onDelete,
                              VoidCallback? onEdit,
                              required VoidCallback onTap}) {
                            return InvoiceListItem(
                              invoice: invoice,
                              client: client,
                              onTap: onTap,
                              onDelete: onDelete,
                              onEdit: onEdit,
                            );
                          },
                        )
                      : InvoicesView(
                          typography: t,
                          colorScheme: cs,
                          drafts: s.drafts,
                          invoices: s.invoices,
                          clients: s.clients,
                          selectedInvoice: s.selectedInvoice,
                          onSelectInvoice: _c.selectInvoice,
                          onDeleteDraft: (inv) =>
                              _c.deleteInvoice(context, inv),
                          onEditDraft: (inv) =>
                              _c.openEditDraft(context, inv),
                          detailBuilder: (inv) => InvoiceDetailSheet(
                            key: ValueKey(inv.id),
                            invoice: inv,
                            client:
                                _clientOrUnknown(l, s.clients, inv.clientId),
                            billingProfile: s.billingProfile,
                            group: widget.group,
                          ),
                          invoiceItemBuilder: (inv, client,
                              {VoidCallback? onDelete,
                              VoidCallback? onEdit,
                              required VoidCallback onTap}) {
                            return InvoiceListItem(
                              invoice: inv,
                              client: client,
                              onTap: onTap,
                              onDelete: onDelete,
                              onEdit: onEdit,
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              l.invoicesTitle(widget.group.name),
              style: t.titleLarge.copyWith(fontWeight: FontWeight.w800),
            ),
            backgroundColor: cs.surface,
            iconTheme: IconThemeData(color: cs.onSurface),
          ),
          body: body,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _c.openCreateInvoice(context),
            icon: const Icon(Icons.add),
            label: Text(l.createInvoiceCta),
          ),
        );
      },
    );
  }
}
