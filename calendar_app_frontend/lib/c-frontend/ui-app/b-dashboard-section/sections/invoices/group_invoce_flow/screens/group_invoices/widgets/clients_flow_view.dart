import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/widgets/common_views.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

typedef InvoiceTileBuilder = Widget Function({
  required Invoice invoice,
  required GroupClient client,
  VoidCallback? onDelete,
  required VoidCallback onTap,
});

typedef ClientBillingViewBuilder = Widget Function(GroupClient client);

class ClientsFlowView extends StatelessWidget {
  final AppTypography typography;
  final ColorScheme colorScheme;

  final List<GroupClient> clients;
  final GroupClient? selectedClient;

  final List<Invoice> visibleInvoices;
  final List<Invoice> draftInvoices;

  final ValueChanged<GroupClient> onSelectClient;
  final ValueChanged<GroupClient> onEditClient;
  final VoidCallback onCreateInvoice;

  final ValueChanged<Invoice> onOpenInvoiceDetail;
  final ValueChanged<Invoice> onDeleteInvoice;

  final ClientBillingViewBuilder clientBillingViewBuilder;
  final InvoiceTileBuilder invoiceTileBuilder;

  const ClientsFlowView({
    super.key,
    required this.typography,
    required this.colorScheme,
    required this.clients,
    required this.selectedClient,
    required this.visibleInvoices,
    required this.draftInvoices,
    required this.onSelectClient,
    required this.onEditClient,
    required this.onCreateInvoice,
    required this.onOpenInvoiceDetail,
    required this.onDeleteInvoice,
    required this.clientBillingViewBuilder,
    required this.invoiceTileBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = typography;
    final cs = colorScheme;

    return Column(
      children: [
        const SizedBox(height: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            l.clientsTitle,
                            style: t.bodyMedium
                                .copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: clients.isEmpty
                              ? EmptyView(
                                  icon: Icons.person_outline,
                                  title: l.noClientsYet,
                                  subtitle: l.noClientsYet,
                                )
                              : ListView.separated(
                                  itemCount: clients.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 1),
                                  itemBuilder: (_, i) {
                                    final c = clients[i];
                                    final selected = selectedClient?.id == c.id;
                                    return ListTile(
                                      selected: selected,
                                      title: Text(c.name),
                                      subtitle: Text(c.billing?.legalName ??
                                          (c.email ?? '')),
                                      onTap: () => onSelectClient(c),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: selectedClient == null
                          ? Center(
                              child: Text(
                                l.selectClientFirst,
                                style: t.bodyMedium
                                    .copyWith(color: cs.onSurfaceVariant),
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      selectedClient!.name,
                                      style: t.titleLarge.copyWith(
                                          fontWeight: FontWeight.w800),
                                    ),
                                    Wrap(
                                      spacing: 8,
                                      children: [
                                        OutlinedButton.icon(
                                          icon: const Icon(Icons.edit_outlined),
                                          label: Text(l.edit),
                                          onPressed: () =>
                                              onEditClient(selectedClient!),
                                        ),
                                        FilledButton.icon(
                                          icon: const Icon(Icons.add),
                                          label: Text(l.createInvoiceCta),
                                          onPressed: onCreateInvoice,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                clientBillingViewBuilder(selectedClient!),
                                const SizedBox(height: 12),
                                Text(
                                  l.invoicesListTitle,
                                  style: t.bodyMedium
                                      .copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 6),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: visibleInvoices.isEmpty
                                            ? EmptyView(
                                                icon:
                                                    Icons.receipt_long_outlined,
                                                title: l.noInvoicesYet,
                                                subtitle:
                                                    l.noInvoicesYetSubtitle,
                                              )
                                            : ListView.builder(
                                                itemCount:
                                                    visibleInvoices.length,
                                                itemBuilder: (_, i) {
                                                  final inv =
                                                      visibleInvoices[i];
                                                  final client =
                                                      selectedClient!;
                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            bottom: 8),
                                                    child: invoiceTileBuilder(
                                                      invoice: inv,
                                                      client: client,
                                                      onTap: () =>
                                                          onOpenInvoiceDetail(
                                                              inv),
                                                    ),
                                                  );
                                                },
                                              ),
                                      ),
                                      if (draftInvoices.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Row(
                                            children: [
                                              Text(
                                                'Draft invoices',
                                                style: t.bodyMedium.copyWith(
                                                    fontWeight:
                                                        FontWeight.w800),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '${draftInvoices.length}',
                                                style: t.bodySmall.copyWith(
                                                    color: cs.onSurfaceVariant),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        SizedBox(
                                          height: 160,
                                          child: ListView.builder(
                                            itemCount: draftInvoices.length,
                                            itemBuilder: (_, i) {
                                              final inv = draftInvoices[i];
                                              return ListTile(
                                                leading: const Icon(
                                                    Icons.drafts_outlined),
                                                title: Text(
                                                    inv.invoiceNumber.isNotEmpty
                                                        ? inv.invoiceNumber
                                                        : l.invoicesListTitle),
                                                subtitle: Text(
                                                    '${selectedClient!.name} • ${inv.status ?? 'draft'}'),
                                                trailing: IconButton(
                                                  icon: const Icon(
                                                      Icons.delete_outline),
                                                  onPressed: () =>
                                                      onDeleteInvoice(inv),
                                                ),
                                                onTap: () =>
                                                    onOpenInvoiceDetail(inv),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
