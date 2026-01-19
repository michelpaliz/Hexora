import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/invoice/billing_profile.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_details_sheet/invoice_detail_sheet.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_list_item.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class GroupInvoicesInvoicesView extends StatelessWidget {
  final List<Invoice> drafts;
  final List<Invoice> invoices;
  final List<GroupClient> clients;
  final BillingProfile? billingProfile;
  final Invoice? selectedInvoice;
  final ValueChanged<Invoice> onSelectInvoice;
  final ValueChanged<Invoice> onDeleteInvoice;
  final VoidCallback onCreateInvoice;
  final int initialTabIndex;
  final ValueChanged<String>? onOpenRecurringSeries;

  const GroupInvoicesInvoicesView({
    super.key,
    required this.drafts,
    required this.invoices,
    required this.clients,
    required this.billingProfile,
    required this.selectedInvoice,
    required this.onSelectInvoice,
    required this.onDeleteInvoice,
    required this.onCreateInvoice,
    this.initialTabIndex = 0,
    this.onOpenRecurringSeries,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: DefaultTabController(
              length: 2,
              initialIndex: initialTabIndex.clamp(0, 1),
              child: Card(
              child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              l.invoicesListTitle,
                              style:
                                  t.bodyMedium.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: onCreateInvoice,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: Text(l.createInvoiceCta),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                      child: TabBar(
                        dividerColor: Colors.transparent,
                        tabs: [
                          Tab(text: l.groupInvoicesTabDrafts(drafts.length)),
                          Tab(text: l.groupInvoicesTabInvoices(invoices.length)),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: TabBarView(
                        children: [
                          ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: drafts.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final inv = drafts[i];
                              final client = clients.firstWhere(
                                (c) => c.id == inv.clientId,
                                orElse: () => GroupClient(
                                  id: inv.clientId,
                                  name: l.unknownClient,
                                  isActive: true,
                                ),
                              );
                              return InvoiceListItem(
                                invoice: inv,
                                client: client,
                                onTap: () => onSelectInvoice(inv),
                                onDelete: () => onDeleteInvoice(inv),
                              );
                            },
                          ),
                          ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: invoices.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final inv = invoices[i];
                              final client = clients.firstWhere(
                                (c) => c.id == inv.clientId,
                                orElse: () => GroupClient(
                                  id: inv.clientId,
                                  name: l.unknownClient,
                                  isActive: true,
                                ),
                              );
                              return InvoiceListItem(
                                invoice: inv,
                                client: client,
                                onTap: () => onSelectInvoice(inv),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: selectedInvoice == null
                  ? Center(
                      child: Text(
                        l.groupInvoicesSelectInvoiceHint,
                        style: t.bodyMedium.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    )
                  : InvoiceDetailSheet(
                      key: ValueKey(selectedInvoice!.id),
                      invoice: selectedInvoice!,
                      client: clients.firstWhere(
                        (c) => c.id == selectedInvoice!.clientId,
                        orElse: () => GroupClient(
                          id: selectedInvoice!.clientId,
                          name: l.unknownClient,
                          isActive: true,
                        ),
                      ),
                      billingProfile: billingProfile,
                      onOpenRecurringSeries: onOpenRecurringSeries,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
