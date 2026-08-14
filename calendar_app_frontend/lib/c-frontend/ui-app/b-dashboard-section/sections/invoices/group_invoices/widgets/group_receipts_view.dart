import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/invoice/billing_profile.dart';
import 'package:hexora/a-models/receipt/receipt.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/receipts_view/receipt_detail_card.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/receipts_view/receipt_list_item.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

String _receiptMonthLabel(DateTime dt, String locale) {
  final formatter = DateFormat.yMMMM(locale);
  final raw = formatter.format(dt.toLocal());
  return raw[0].toUpperCase() + raw.substring(1);
}

String _receiptClientDisplayName(Receipt receipt, String fallback) {
  final snapshotName = receipt.clientSnapshot?.legalName?.trim();
  if (snapshotName != null && snapshotName.isNotEmpty) return snapshotName;
  final manualName = receipt.clientName?.trim();
  if (manualName != null && manualName.isNotEmpty) return manualName;
  return fallback;
}

GroupClient _receiptClientFor(
  Receipt receipt,
  List<GroupClient> clients,
  String unknownClientLabel,
) {
  GroupClient? existing;
  for (final client in clients) {
    if (client.id == receipt.clientId) {
      existing = client;
      break;
    }
  }
  final fallback = existing?.name ?? unknownClientLabel;
  final displayName = _receiptClientDisplayName(receipt, fallback);
  return existing == null
      ? GroupClient(
          id: receipt.clientId,
          name: displayName,
          isActive: true,
        )
      : existing.copyWith(name: displayName);
}

class _MonthDivider extends StatelessWidget {
  const _MonthDivider({required this.label, this.first = false});
  final String label;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    return Padding(
      padding: EdgeInsets.only(top: first ? 0 : 14, bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: cs.outlineVariant.withValues(alpha: 0.35),
              height: 1,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              label,
              style: t.bodySmall.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Divider(
              color: cs.outlineVariant.withValues(alpha: 0.35),
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupedReceiptList extends StatelessWidget {
  final List<Receipt> receipts;
  final List<GroupClient> clients;
  final String unknownClientLabel;
  final EdgeInsetsGeometry padding;
  final Widget Function(Receipt, GroupClient) itemBuilder;

  const _GroupedReceiptList({
    required this.receipts,
    required this.clients,
    required this.unknownClientLabel,
    required this.padding,
    required this.itemBuilder,
  });

  DateTime? _date(Receipt r) => r.issueDate ?? r.registeredAt;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final items = <Object>[];
    String? lastKey;

    for (final r in receipts) {
      final date = _date(r);
      final key = date == null
          ? '__none__'
          : '${date.year}-${date.month.toString().padLeft(2, '0')}';
      if (key != lastKey) {
        items.add(date == null ? '—' : _receiptMonthLabel(date, locale));
        lastKey = key;
      }
      items.add(r);
    }

    return ListView.builder(
      padding: padding,
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        if (item is String) return _MonthDivider(label: item, first: i == 0);
        final r = item as Receipt;
        final client = _receiptClientFor(r, clients, unknownClientLabel);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: itemBuilder(r, client),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

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
  final Future<void> Function(Receipt) onPreviewPdf;
  final ValueChanged<Receipt> onDownloadPdf;
  final ValueChanged<Receipt> onImportJson;
  final Future<Uint8List?> Function(Receipt) onLoadInlinePdf;
  final bool disableDetailPreviewInteraction;

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
    required this.onImportJson,
    required this.onLoadInlinePdf,
    this.disableDetailPreviewInteraction = false,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEs = l.localeName.toLowerCase().startsWith('es');
    final totalCount = drafts.length + receipts.length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // ── Left panel: list ──────────────────────────────────────────────
          Expanded(
            flex: 3,
            child: DefaultTabController(
              length: 2,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? cs.surface.withValues(alpha: 0.20)
                      : cs.surface.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(
                      alpha: isDark ? 0.20 : 0.25,
                    ),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    // Header row
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? cs.surfaceContainerHighest.withValues(alpha: 0.30)
                            : cs.surfaceContainerLow.withValues(alpha: 0.60),
                        border: Border(
                          bottom: BorderSide(
                            color: cs.outlineVariant.withValues(
                              alpha: isDark ? 0.20 : 0.25,
                            ),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  cs.primary.withValues(alpha: 0.22),
                                  cs.primary.withValues(alpha: 0.08),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.receipt_long_rounded,
                              size: 15,
                              color: cs.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isEs ? 'Documentos' : 'Documents',
                              style: t.bodySmall.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                                color: cs.onSurface,
                              ),
                            ),
                          ),
                          if (totalCount > 0)
                            Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: cs.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '$totalCount',
                                style: t.bodySmall.copyWith(
                                  color: cs.primary,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          Tooltip(
                            message: isEs ? 'Nuevo documento' : 'New document',
                            child: IconButton(
                              onPressed: onCreateReceipt,
                              icon: const Icon(Icons.add_rounded, size: 18),
                              style: IconButton.styleFrom(
                                foregroundColor: cs.primary,
                                backgroundColor:
                                    cs.primary.withValues(alpha: 0.10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                padding: const EdgeInsets.all(6),
                                minimumSize: const Size(32, 32),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Tab bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                      child: TabBar(
                        dividerColor: Colors.transparent,
                        splashFactory: NoSplash.splashFactory,
                        overlayColor: WidgetStatePropertyAll(
                          cs.primary.withValues(alpha: 0.08),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicator: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        indicatorPadding:
                            const EdgeInsets.symmetric(vertical: 4),
                        labelColor: cs.onPrimaryContainer,
                        unselectedLabelColor: cs.onSurfaceVariant,
                        labelStyle: t.bodySmall.copyWith(
                            fontWeight: FontWeight.w800, fontSize: 12),
                        unselectedLabelStyle: t.bodySmall.copyWith(
                            fontWeight: FontWeight.w600, fontSize: 12),
                        tabs: [
                          Tab(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.edit_note_rounded, size: 14),
                                const SizedBox(width: 5),
                                Text(l.groupReceiptsTabDrafts(drafts.length)),
                              ],
                            ),
                          ),
                          Tab(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.task_alt_rounded, size: 14),
                                const SizedBox(width: 5),
                                Text(l
                                    .groupReceiptsTabReceipts(receipts.length)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: cs.outlineVariant.withValues(
                        alpha: isDark ? 0.20 : 0.25,
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _GroupedReceiptList(
                            receipts: drafts,
                            clients: clients,
                            unknownClientLabel: l.unknownClient,
                            padding: const EdgeInsets.all(10),
                            itemBuilder: (r, client) => ReceiptListItem(
                              receipt: r,
                              client: client,
                              onTap: () => onSelectReceipt(r),
                              onPreview: () => onPreviewPdf(r),
                              onEdit: () => onEditReceipt(r),
                              onDownload: () => onDownloadPdf(r),
                              onIssue: () => onIssueReceipt(r),
                              onDelete: () => onDeleteReceipt(r),
                            ),
                          ),
                          _GroupedReceiptList(
                            receipts: receipts,
                            clients: clients,
                            unknownClientLabel: l.unknownClient,
                            padding: const EdgeInsets.all(10),
                            itemBuilder: (r, client) => ReceiptListItem(
                              receipt: r,
                              client: client,
                              onTap: () => onSelectReceipt(r),
                              onPreview: () => onPreviewPdf(r),
                              onDownload: () => onDownloadPdf(r),
                            ),
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
          // ── Right panel: detail ───────────────────────────────────────────
          Expanded(
            flex: 4,
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? cs.surface.withValues(alpha: 0.20)
                    : cs.surface.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: cs.outlineVariant.withValues(
                    alpha: isDark ? 0.20 : 0.25,
                  ),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: selectedReceipt == null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    cs.primary.withValues(alpha: 0.16),
                                    cs.primary.withValues(alpha: 0.06),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.receipt_long_rounded,
                                size: 26,
                                color: cs.primary.withValues(alpha: 0.75),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              isEs
                                  ? 'Sin documento seleccionado'
                                  : 'No document selected',
                              style: t.bodyLarge.copyWith(
                                fontWeight: FontWeight.w800,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l.groupReceiptsSelectReceiptHint,
                              textAlign: TextAlign.center,
                              style: t.bodySmall.copyWith(
                                color: cs.onSurfaceVariant,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 20),
                            FilledButton.tonalIcon(
                              onPressed: onCreateReceipt,
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: Text(
                                isEs ? 'Nuevo documento' : 'New document',
                              ),
                              style: FilledButton.styleFrom(
                                visualDensity: VisualDensity.comfortable,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ReceiptDetailCard(
                      key: ValueKey(selectedReceipt!.id),
                      receipt: selectedReceipt!,
                      client: _receiptClientFor(
                        selectedReceipt!,
                        clients,
                        l.unknownClient,
                      ),
                      billingProfile: billingProfile,
                      onEdit: () => onEditReceipt(selectedReceipt!),
                      onPreviewPdf: () => onPreviewPdf(selectedReceipt!),
                      onDownloadPdf: () => onDownloadPdf(selectedReceipt!),
                      onIssue: () => onIssueReceipt(selectedReceipt!),
                      onDeleteDraft: () => onDeleteReceipt(selectedReceipt!),
                      onImportJson: () => onImportJson(selectedReceipt!),
                      onLoadInlinePdf: () => onLoadInlinePdf(selectedReceipt!),
                      previewInteractive: !disableDetailPreviewInteraction,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
