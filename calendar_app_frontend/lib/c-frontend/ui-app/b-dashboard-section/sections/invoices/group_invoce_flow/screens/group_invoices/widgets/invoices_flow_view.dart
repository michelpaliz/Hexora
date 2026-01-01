import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

typedef InvoiceItemBuilder = Widget Function(
  Invoice inv,
  GroupClient client, {
  VoidCallback? onDelete,
  required VoidCallback onTap,
});

class InvoicesView extends StatelessWidget {
  final AppTypography typography;
  final ColorScheme colorScheme;

  final List<Invoice> drafts;
  final List<Invoice> invoices;
  final List<GroupClient> clients;

  final Invoice? selectedInvoice;

  final ValueChanged<Invoice> onSelectInvoice;
  final ValueChanged<Invoice> onDeleteDraft;

  final Widget Function(Invoice inv) detailBuilder;
  final InvoiceItemBuilder invoiceItemBuilder;

  const InvoicesView({
    super.key,
    required this.typography,
    required this.colorScheme,
    required this.drafts,
    required this.invoices,
    required this.clients,
    required this.selectedInvoice,
    required this.onSelectInvoice,
    required this.onDeleteDraft,
    required this.detailBuilder,
    required this.invoiceItemBuilder,
  });

  GroupClient _clientOrUnknown(AppLocalizations l, String id) {
    return clients.firstWhere(
      (c) => c.id == id,
      orElse: () => GroupClient(id: id, name: l.unknownClient, isActive: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = typography;
    final cs = colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: DefaultTabController(
              length: 2,
              child: Card(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                      child: TabBar(
                        dividerColor: Colors.transparent,
                        tabs: [
                          Tab(text: 'Drafts (${drafts.length})'),
                          Tab(text: 'Invoices (${invoices.length})'),
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
                              final client = _clientOrUnknown(l, inv.clientId);
                              return invoiceItemBuilder(
                                inv,
                                client,
                                onTap: () => onSelectInvoice(inv),
                                onDelete: () => onDeleteDraft(inv),
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
                              final client = _clientOrUnknown(l, inv.clientId);
                              return invoiceItemBuilder(
                                inv,
                                client,
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
                        'Select an invoice to see details',
                        style:
                            t.bodyMedium.copyWith(color: cs.onSurfaceVariant),
                      ),
                    )
                  : detailBuilder(selectedInvoice!),
            ),
          ),
        ],
      ),
    );
  }
}
