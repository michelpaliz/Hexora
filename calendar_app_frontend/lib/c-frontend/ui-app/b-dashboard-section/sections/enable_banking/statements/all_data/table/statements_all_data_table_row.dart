import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

import '../../statements_controller.dart';
import '../../statements_formatters.dart';
import '../../statements_shared.dart';
import 'statements_all_data_table_client_cell.dart';
import 'statements_all_data_table_layout.dart';
import 'statements_all_data_table_theme.dart';

class StatementsAllDataTableRow extends StatelessWidget {
  const StatementsAllDataTableRow({
    super.key,
    required this.entry,
    required this.index,
    required this.isCompact,
    required this.controller,
    required this.selectedIds,
    required this.onToggleRow,
    required this.onShowDetails,
    required this.onSuggest,
    required this.onLink,
    required this.onLinkInvoice,
    required this.tableTheme,
  });

  final Map<String, dynamic> entry;
  final int index;
  final bool isCompact;
  final StatementsController controller;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggleRow;
  final ValueChanged<Map<String, dynamic>> onShowDetails;
  final ValueChanged<Map<String, dynamic>> onSuggest;
  final ValueChanged<Map<String, dynamic>> onLink;
  final ValueChanged<Map<String, dynamic>> onLinkInvoice;
  final StatementsTableTheme tableTheme;

  Widget _moneyText(
    BuildContext context,
    String amount, {
    required bool emphasize,
    required Color amountColor,
    TextStyle? textStyle,
  }) {
    final typography = AppTypography.of(context);
    final formatted = StatementsFormatters.formatCurrency(context, amount);
    return Text(
      formatted,
      textAlign: TextAlign.right,
      style: (textStyle ??
              (emphasize ? typography.bodyLarge : typography.bodySmall))
          .copyWith(
        fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
        color: amountColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final typography = AppTypography.of(context);
    final isWide = MediaQuery.of(context).size.width > 1400;
    final balanceMaxWidth =
        isWide ? 200.0 : StatementsAllDataTableLayout.balanceMaxWidth;
    final balanceClientGap =
        isWide ? 40.0 : StatementsAllDataTableLayout.balanceClientGap;
    final entryId = (entry['_id'] ?? entry['id'])?.toString() ?? '';
    final batchId = entry['_batchId']?.toString() ?? '';
    final date = StatementsShared.entryText(entry, ['date']);
    final valueDate = StatementsShared.entryText(entry, ['valueDate']);
    final desc = StatementsShared.entryText(entry, ['description']);
    String _rawIndex(Map<String, dynamic> entry, int index) {
      final raw = entry['raw'];
      if (raw is List && raw.length > index) {
        final value = raw[index];
        if (value != null) return value.toString();
      }
      return '';
    }

    final rawAmount = _rawIndex(entry, 4);
    final rawBalance = _rawIndex(entry, 5);
    final amount = rawAmount.isNotEmpty
        ? rawAmount
        : StatementsShared.entryText(entry, ['amount']);
    final balance = rawBalance.isNotEmpty
        ? rawBalance
        : StatementsShared.entryText(entry, ['balance']);
    final amountValue = StatementsFormatters.parseAmount(amount);
    final isNegative = (amountValue ?? 0) < 0;
    final invoiceId =
        (entry['invoiceId'] ?? entry['invoice_id'] ?? entry['invoice'])
            ?.toString();
    final hasInvoice = invoiceId != null && invoiceId.trim().isNotEmpty;
    final expenseDocId = (entry['expenseDocumentId'] ??
            entry['expense_document_id'] ??
            entry['expenseDocument'])
        ?.toString();
    final hasExpenseDoc =
        expenseDocId != null && expenseDocId.trim().isNotEmpty;
    final linkError = controller.linkClientError[entryId];
    final linking = controller.linkingClient[entryId] == true;
    final suggestLoading = controller.loadingSuggestions[entryId] == true;
    final isSelected = entryId.isNotEmpty && selectedIds.contains(entryId);
    final isUnlinked = entry['clientId'] == null ||
        entry['clientId'].toString().trim().isEmpty;
    final rowColor = isSelected
        ? tableTheme.rowSelected
        : (index.isEven ? tableTheme.rowBg : tableTheme.rowBgAlt);
    final rowAccent = isNegative ? cs.tertiary : cs.primary;
    final amountAbs = (amountValue ?? 0).abs();
    final canLinkInvoice = isNegative && amountAbs > 1;
    final canSuggest = (amountValue ?? 0) > 0;

    Future<void> showRowMenu(Offset position) async {
      final overlay =
          Overlay.of(context).context.findRenderObject() as RenderBox;
      final result = await showMenu<String>(
        context: context,
        position: RelativeRect.fromRect(
          Rect.fromLTWH(position.dx, position.dy, 0, 0),
          Offset.zero & overlay.size,
        ),
        items: [
          PopupMenuItem(
            value: 'suggest',
            enabled: entryId.isNotEmpty && !suggestLoading,
            child: Text(l.statementsActionSuggest),
          ),
          PopupMenuItem(
            value: 'link',
            enabled: entryId.isNotEmpty && !linking,
            child: Text(l.statementsActionLink),
          ),
          PopupMenuItem(
            value: 'details',
            child: Text(l.statementsViewDetails),
          ),
        ],
      );
      if (result == 'suggest') {
        if (entryId.isNotEmpty && !suggestLoading) {
          onSuggest(entry);
        }
      } else if (result == 'link') {
        if (entryId.isNotEmpty && !linking) {
          onLink(entry);
        }
      } else if (result == 'details') {
        onShowDetails(entry);
      }
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tableTheme.border),
      ),
      child: Material(
        color: rowColor,
        borderRadius: BorderRadius.circular(12),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onSecondaryTapDown: (details) => showRowMenu(details.globalPosition),
          onLongPressStart: (details) => showRowMenu(details.globalPosition),
          child: InkWell(
            hoverColor: tableTheme.rowHover,
            borderRadius: BorderRadius.circular(12),
            onTap: () => onShowDetails(entry),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 18,
                horizontal: StatementsAllDataTableLayout.horizontalPadding,
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: -8,
                    top: 14,
                    bottom: 14,
                    child: Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: rowAccent.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(
                              width:
                                  StatementsAllDataTableLayout.leadingSpacer),
                          SizedBox(
                            width: StatementsAllDataTableLayout.checkWidth,
                            child: Checkbox(
                              value: isSelected,
                              onChanged: entryId.isEmpty
                                  ? null
                                  : (_) => onToggleRow(entryId),
                            ),
                          ),
                          if (!isCompact) ...[
                            SizedBox(
                              width: StatementsAllDataTableLayout.batchWidth,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      batchId.isEmpty ? '-' : batchId,
                                      style: typography.bodySmall.copyWith(
                                        color: tableTheme.textSecondary,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures()
                                        ],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  // Copy action removed per request.
                                ],
                              ),
                            ),
                            const SizedBox(
                                width: StatementsAllDataTableLayout.columnGap),
                          ],
                          SizedBox(
                            width: StatementsAllDataTableLayout.dateWidth,
                            child: Text(
                              valueDate.isNotEmpty && valueDate != date
                                  ? '${StatementsFormatters.formatDate(context, date)}\n${StatementsFormatters.formatDate(context, valueDate)}'
                                  : (date.isNotEmpty
                                      ? StatementsFormatters.formatDate(
                                          context, date)
                                      : StatementsFormatters.formatDate(
                                          context, valueDate)),
                              style: typography.bodyLarge.copyWith(
                                color: tableTheme.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(
                              width: StatementsAllDataTableLayout.columnGap),
                          if (isCompact)
                            Expanded(
                              flex: 4,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (isUnlinked)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Icon(
                                        Icons.link_off_outlined,
                                        size: 16,
                                        color: cs.tertiary,
                                      ),
                                    ),
                                  if (isUnlinked) const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      desc.isEmpty
                                          ? l.statementsNoDescription
                                          : desc,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: typography.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            ConstrainedBox(
                              constraints: const BoxConstraints(
                                minWidth:
                                    StatementsAllDataTableLayout.descMinWidth,
                                maxWidth:
                                    StatementsAllDataTableLayout.descMaxWidth,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (isUnlinked)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Icon(
                                        Icons.link_off_outlined,
                                        size: 16,
                                        color: cs.tertiary,
                                      ),
                                    ),
                                  if (isUnlinked) const SizedBox(width: 6),
                                  Expanded(
                                    child: Tooltip(
                                      message: desc.isEmpty
                                          ? l.statementsNoDescription
                                          : desc,
                                      child: Text(
                                        desc.isEmpty
                                            ? l.statementsNoDescription
                                            : desc,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: typography.bodyMedium.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          // Details column hidden for now.
                          const SizedBox(
                              width: StatementsAllDataTableLayout.columnGap),
                          SizedBox(
                            width: StatementsAllDataTableLayout.amountWidth,
                            child: _moneyText(
                              context,
                              amount,
                              emphasize: true,
                              amountColor: isNegative
                                  ? tableTheme.amountNegative
                                  : tableTheme.amountPositive,
                            ),
                          ),
                          if (!isCompact) ...[
                            const SizedBox(
                                width: StatementsAllDataTableLayout.columnGap),
                            SizedBox(
                              width: balanceMaxWidth,
                              child: Align(
                                alignment: Alignment.centerRight,
                                  child: _moneyText(
                                    context,
                                    balance,
                                    emphasize: false,
                                    amountColor: tableTheme.textSecondary,
                                    textStyle: typography.bodyMedium,
                                  ),
                              ),
                            ),
                          ],
                          SizedBox(width: balanceClientGap),
                          Expanded(
                            flex: 3,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                minWidth:
                                    StatementsAllDataTableLayout.clientMinWidth,
                              ),
                              child: DefaultTextStyle.merge(
                                style: TextStyle(color: tableTheme.textPrimary),
                                child: StatementsAllDataTableClientCell(
                                  label: StatementsShared.clientLabel(
                                      l, controller, entry),
                                  unlinked: isUnlinked,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                              width:
                                  StatementsAllDataTableLayout.columnGapWide),
                          SizedBox(
                            width: StatementsAllDataTableLayout.invoiceWidth,
                            child: Align(
                              alignment: Alignment.center,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 120,
                                ),
                                child: Text(
                                  hasInvoice
                                      ? 'Factura vinculada'
                                      : hasExpenseDoc
                                          ? 'Gasto vinculado'
                                          : 'Sin factura',
                                  overflow: TextOverflow.ellipsis,
                                  style: typography.bodySmall.copyWith(
                                    color: (hasInvoice || hasExpenseDoc)
                                        ? tableTheme.textPrimary
                                        : tableTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                              width:
                                  StatementsAllDataTableLayout.columnGapWide),
                          SizedBox(
                            width: StatementsAllDataTableLayout.actionsWidth,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: IconTheme(
                                data:
                                    IconThemeData(color: tableTheme.textPrimary),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      tooltip: 'Sugerir factura',
                                      onPressed: (!canSuggest ||
                                              suggestLoading ||
                                              entryId.isEmpty)
                                          ? null
                                          : () => onSuggest(entry),
                                      icon: const Icon(Icons.auto_awesome,
                                          size: 18),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 28,
                                        minHeight: 28,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Vincular factura',
                                      onPressed: (!canLinkInvoice ||
                                              entryId.isEmpty)
                                          ? null
                                          : () => onLinkInvoice(entry),
                                      icon: const Icon(Icons.receipt_long,
                                          size: 18),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 28,
                                        minHeight: 28,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: l.statementsViewDetails,
                                      onPressed: () => onShowDetails(entry),
                                      icon: const Icon(Icons.info_outline,
                                          size: 18),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 28,
                                        minHeight: 28,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (linkError != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 44, top: 4),
                          child: Text(linkError,
                              style: TextStyle(color: cs.error)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
