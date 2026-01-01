import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/invoice/billing_profile.dart';
import 'package:hexora/a-models/receipt/receipt.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/receipts_view/receipt_detail_card.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/receipts_view/receipt_list_item.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class GroupReceiptsView extends StatelessWidget {
  final List<Receipt> drafts;
  final List<Receipt> receipts;
  final List<GroupClient> clients;
  final BillingProfile? billingProfile;

  final Receipt? selectedReceipt;
  final ValueChanged<Receipt> onSelectReceipt;

  final VoidCallback onCreateReceipt;
  final ValueChanged<Receipt> onEditReceipt;
  final ValueChanged<Receipt> onIssueReceipt;
  final ValueChanged<Receipt> onDeleteReceipt;
  final ValueChanged<Receipt> onPreviewPdf;
  final ValueChanged<Receipt> onDownloadPdf;

  const GroupReceiptsView({
    super.key,
    required this.drafts,
    required this.receipts,
    required this.clients,
    required this.billingProfile,
    required this.selectedReceipt,
    required this.onSelectReceipt,
    required this.onCreateReceipt,
    required this.onEditReceipt,
    required this.onIssueReceipt,
    required this.onDeleteReceipt,
    required this.onPreviewPdf,
    required this.onDownloadPdf,
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
              child: Card(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              l.receiptsTitle,
                              style: t.bodyLarge.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: onCreateReceipt,
                            icon: const Icon(Icons.add),
                            label: Text(l.createReceiptCta),
                            style: FilledButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                      child: TabBar(
                        dividerColor: Colors.transparent,
                        tabs: [
                          Tab(text: l.groupReceiptsTabDrafts(drafts.length)),
                          Tab(text: l.groupReceiptsTabReceipts(receipts.length)),
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
                              final r = drafts[i];
                              final client = clients.firstWhere(
                                (c) => c.id == r.clientId,
                                orElse: () => GroupClient(
                                  id: r.clientId,
                                  name: l.unknownClient,
                                  isActive: true,
                                ),
                              );
                              return ReceiptListItem(
                                receipt: r,
                                client: client,
                                onTap: () => onSelectReceipt(r),
                                onDelete: () => onDeleteReceipt(r),
                              );
                            },
                          ),
                          ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: receipts.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final r = receipts[i];
                              final client = clients.firstWhere(
                                (c) => c.id == r.clientId,
                                orElse: () => GroupClient(
                                  id: r.clientId,
                                  name: l.unknownClient,
                                  isActive: true,
                                ),
                              );
                              return ReceiptListItem(
                                receipt: r,
                                client: client,
                                onTap: () => onSelectReceipt(r),
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
            child: selectedReceipt == null
                ? Card(
                    child: Center(
                      child: Text(
                        l.groupReceiptsSelectReceiptHint,
                        style:
                            t.bodyMedium.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ),
                  )
                : ReceiptDetailCard(
                    key: ValueKey(selectedReceipt!.id),
                    receipt: selectedReceipt!,
                    client: clients.firstWhere(
                      (c) => c.id == selectedReceipt!.clientId,
                      orElse: () => GroupClient(
                        id: selectedReceipt!.clientId,
                        name: l.unknownClient,
                        isActive: true,
                      ),
                    ),
                    billingProfile: billingProfile,
                    onEdit: () => onEditReceipt(selectedReceipt!),
                    onPreviewPdf: () => onPreviewPdf(selectedReceipt!),
                    onDownloadPdf: () => onDownloadPdf(selectedReceipt!),
                    onIssue: () => onIssueReceipt(selectedReceipt!),
                    onDeleteDraft: () => onDeleteReceipt(selectedReceipt!),
                  ),
          ),
        ],
      ),
    );
  }
}

