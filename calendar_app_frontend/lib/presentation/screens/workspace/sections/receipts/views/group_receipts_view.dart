import 'package:hexora/presentation/shared/widgets/hexora_section_tabs.dart';
import 'package:hexora/presentation/shared/widgets/documents/compact_document_row.dart';
import 'package:hexora/presentation/shared/widgets/documents/document_split_view.dart';
import 'package:hexora/presentation/shared/widgets/financial/hexora_financial_table.dart';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/models/invoice/billing_profile.dart';
import 'package:hexora/models/receipt/receipt.dart';
import 'package:hexora/presentation/screens/workspace/sections/receipts/widgets/receipt_detail_card.dart';
import 'package:hexora/presentation/screens/workspace/sections/receipts/widgets/receipt_list_item.dart';
import 'package:hexora/presentation/screens/workspace/sections/receipts/utils/receipt_delivery_utils.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
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
  Widget build(BuildContext context) =>
      CompactDocumentMonthHeading(label: label);
}

class _GroupedReceiptList extends StatefulWidget {
  final List<Receipt> receipts;
  final List<GroupClient> clients;
  final String unknownClientLabel;
  final EdgeInsetsGeometry padding;
  final Widget Function(
    Receipt,
    GroupClient,
    Set<HexoraFinancialColumn>,
  ) itemBuilder;

  const _GroupedReceiptList({
    required this.receipts,
    required this.clients,
    required this.unknownClientLabel,
    required this.padding,
    required this.itemBuilder,
  });

  @override
  State<_GroupedReceiptList> createState() => _GroupedReceiptListState();
}

class _GroupedReceiptListState extends State<_GroupedReceiptList> {
  static const _available = {
    HexoraFinancialColumn.date,
    HexoraFinancialColumn.taxableBase,
    HexoraFinancialColumn.total,
  };
  Set<HexoraFinancialColumn> _visible = Set.of(_available);

  @override
  void initState() {
    super.initState();
    HexoraColumnVisibilityStore.load('recibos', _available).then((value) {
      if (mounted) setState(() => _visible = value);
    });
  }

  DateTime? _date(Receipt r) => r.issueDate ?? r.registeredAt;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final items = <Object>[];
    String? lastKey;

    for (final r in widget.receipts) {
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
      padding: widget.padding,
      itemCount: items.length + 1,
      itemBuilder: (_, i) {
        if (i == 0) {
          return Column(
            children: [
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: HexoraColumnVisibilityMenu(
                    moduleKey: 'recibos',
                    availableColumns: _available,
                    visibleColumns: _visible,
                    onChanged: (value) => setState(() => _visible = value),
                  ),
                ),
              ),
              CompactDocumentTableHeader(
                identityLabel: 'Recibo',
                visibleFinancialColumns: _visible,
                actionsWidth: 144,
              ),
            ],
          );
        }
        final item = items[i - 1];
        if (item is String) return _MonthDivider(label: item, first: i == 0);
        final r = item as Receipt;
        final client = _receiptClientFor(
          r,
          widget.clients,
          widget.unknownClientLabel,
        );
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.sizeOf(context).width < 650 ? 8 : 0),
          child: widget.itemBuilder(r, client, _visible),
        );
      },
    );
  }
}

class _IssuedReceiptsTab extends StatefulWidget {
  const _IssuedReceiptsTab({
    required this.receipts,
    required this.clients,
    required this.unknownClientLabel,
    required this.selectedId,
    required this.onSelect,
    required this.onPreview,
    required this.onDownload,
    required this.onMarkSent,
    required this.onMarkUnsent,
  });

  final List<Receipt> receipts;
  final List<GroupClient> clients;
  final String unknownClientLabel;
  final String? selectedId;
  final ValueChanged<Receipt> onSelect;
  final Future<void> Function(Receipt) onPreview;
  final ValueChanged<Receipt> onDownload;
  final ValueChanged<Receipt> onMarkSent;
  final ValueChanged<Receipt> onMarkUnsent;

  @override
  State<_IssuedReceiptsTab> createState() => _IssuedReceiptsTabState();
}

class _IssuedReceiptsTabState extends State<_IssuedReceiptsTab> {
  ReceiptDeliveryFilter _filter = ReceiptDeliveryFilter.all;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final filtered = filterReceiptsByDelivery(widget.receipts, _filter);
    return Column(
      children: [
        // Content-sized chips instead of a full-width dropdown, so the
        // filter doesn't take space away from the list.
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 2),
          child: SingleChildScrollView(
            key: const ValueKey('receipt-delivery-filter'),
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final (value, label) in const [
                  (ReceiptDeliveryFilter.all, 'Todos'),
                  (ReceiptDeliveryFilter.notSent, 'No enviados'),
                  (ReceiptDeliveryFilter.sent, 'Enviados'),
                  (ReceiptDeliveryFilter.failed, 'Error de envío'),
                ])
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 6),
                    child: ChoiceChip(
                      label: Text(_filter == value
                          ? '$label · ${filtered.length}'
                          : label),
                      selected: _filter == value,
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onSelected: (_) => setState(() => _filter = value),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    'No hay recibos con este estado de envío.',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                )
              : _GroupedReceiptList(
                  receipts: filtered,
                  clients: widget.clients,
                  unknownClientLabel: widget.unknownClientLabel,
                  padding: const EdgeInsets.all(10),
                  itemBuilder: (receipt, client, visibleColumns) =>
                      ReceiptListItem(
                    receipt: receipt,
                    client: client,
                    selected: receipt.id == widget.selectedId,
                    visibleFinancialColumns: visibleColumns,
                    onTap: () => widget.onSelect(receipt),
                    onPreview: () => widget.onPreview(receipt),
                    onDownload: () => widget.onDownload(receipt),
                    onMarkSent: () => widget.onMarkSent(receipt),
                    onMarkUnsent: () => widget.onMarkUnsent(receipt),
                  ),
                ),
        ),
      ],
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
  final ValueChanged<Receipt> onMarkReceiptSent;
  final ValueChanged<Receipt> onMarkReceiptUnsent;
  final ValueChanged<Receipt> onDeleteReceipt;
  final Future<void> Function(Receipt) onPreviewPdf;
  final ValueChanged<Receipt> onDownloadPdf;
  final ValueChanged<Receipt> onImportJson;
  final Future<Uint8List?> Function(Receipt) onLoadInlinePdf;
  final bool disableDetailPreviewInteraction;
  final int initialTabIndex;
  final bool showHeaderTabs;
  final ValueChanged<int>? onTabChanged;
  final VoidCallback? onClearSelection;
  final ValueNotifier<DocumentViewMode?> modeNotifier;

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
    required this.onMarkReceiptSent,
    required this.onMarkReceiptUnsent,
    required this.onDeleteReceipt,
    required this.onPreviewPdf,
    required this.onDownloadPdf,
    required this.onImportJson,
    required this.onLoadInlinePdf,
    this.disableDetailPreviewInteraction = false,
    this.initialTabIndex = 0,
    this.showHeaderTabs = true,
    this.onTabChanged,
    this.onClearSelection,
    required this.modeNotifier,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEs = l.localeName.toLowerCase().startsWith('es');
    final totalCount = drafts.length + receipts.length;
    final activeReceipts = initialTabIndex == 0 ? drafts : receipts;
    final selectedIndex = selectedReceipt == null
        ? -1
        : activeReceipts.indexWhere((item) => item.id == selectedReceipt!.id);

    return Padding(
      padding: const EdgeInsets.all(5),
      child: DocumentSplitView(
        storageKey: 'receipts',
        modeNotifier: modeNotifier,
        selectionKey: selectedReceipt?.id,
        list: DefaultTabController(
          key: ValueKey('receipt-tabs-$initialTabIndex-$showHeaderTabs'),
          length: 2,
          initialIndex: initialTabIndex.clamp(0, 1),
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
                if (showHeaderTabs) ...[
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
                    child: HexoraSectionTabs(
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
                              Text(l.groupReceiptsTabReceipts(receipts.length)),
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
                ],
                Expanded(
                  child: TabBarView(
                    children: [
                      _GroupedReceiptList(
                        receipts: drafts,
                        clients: clients,
                        unknownClientLabel: l.unknownClient,
                        padding: const EdgeInsets.all(10),
                        itemBuilder: (r, client, visibleColumns) =>
                            ReceiptListItem(
                          receipt: r,
                          client: client,
                          selected: r.id == selectedReceipt?.id,
                          visibleFinancialColumns: visibleColumns,
                          onTap: () => onSelectReceipt(r),
                          onPreview: () => onPreviewPdf(r),
                          onEdit: () => onEditReceipt(r),
                          onDownload: () => onDownloadPdf(r),
                          onIssue: () => onIssueReceipt(r),
                          onDelete: () => onDeleteReceipt(r),
                        ),
                      ),
                      _IssuedReceiptsTab(
                        receipts: receipts,
                        clients: clients,
                        unknownClientLabel: l.unknownClient,
                        selectedId: selectedReceipt?.id,
                        onSelect: onSelectReceipt,
                        onPreview: onPreviewPdf,
                        onDownload: onDownloadPdf,
                        onMarkSent: onMarkReceiptSent,
                        onMarkUnsent: onMarkReceiptUnsent,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        preview: Container(
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
              : ValueListenableBuilder<DocumentViewMode?>(
                  valueListenable: modeNotifier,
                  builder: (context, mode, _) => ReceiptDetailCard(
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
                    onMarkSent: () => onMarkReceiptSent(selectedReceipt!),
                    onMarkUnsent: () => onMarkReceiptUnsent(selectedReceipt!),
                    onDeleteDraft: () => onDeleteReceipt(selectedReceipt!),
                    onImportJson: () => onImportJson(selectedReceipt!),
                    onLoadInlinePdf: () => onLoadInlinePdf(selectedReceipt!),
                    previewInteractive: !disableDetailPreviewInteraction,
                    onPrevious: selectedIndex > 0
                        ? () =>
                            onSelectReceipt(activeReceipts[selectedIndex - 1])
                        : null,
                    onNext: selectedIndex >= 0 &&
                            selectedIndex + 1 < activeReceipts.length
                        ? () =>
                            onSelectReceipt(activeReceipts[selectedIndex + 1])
                        : null,
                    onClose: onClearSelection,
                    onExpand: null,
                    isExpanded: false,
                  ),
                ),
        ),
      ),
    );
  }
}
