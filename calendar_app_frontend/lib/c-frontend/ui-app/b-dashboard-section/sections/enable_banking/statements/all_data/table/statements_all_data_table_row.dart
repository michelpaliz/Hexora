import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

import '../../statements_controller.dart';
import '../../statements_formatters.dart';
import '../../statements_shared.dart';
import 'statements_all_data_table_client_cell.dart';

class StatementsAllDataTableRow extends StatelessWidget {
  const StatementsAllDataTableRow({
    super.key,
    required this.entry,
    required this.index,
    required this.isCompact,
    required this.controller,
    required this.selectedIds,
    required this.hasSelection,
    required this.onToggleRow,
    required this.onShowDetails,
    required this.onSuggest,
    required this.onLink,
  });

  final Map<String, dynamic> entry;
  final int index;
  final bool isCompact;
  final StatementsController controller;
  final Set<String> selectedIds;
  final bool hasSelection;
  final ValueChanged<String> onToggleRow;
  final ValueChanged<Map<String, dynamic>> onShowDetails;
  final ValueChanged<Map<String, dynamic>> onSuggest;
  final ValueChanged<Map<String, dynamic>> onLink;

  Widget _moneyText(
    BuildContext context,
    String amount, {
    required bool emphasize,
    required Color amountColor,
  }) {
    final typography = AppTypography.of(context);
    final formatted = StatementsFormatters.formatCurrency(context, amount);
    return Text(
      formatted,
      textAlign: TextAlign.right,
      style: (emphasize ? typography.bodyLarge : typography.bodySmall).copyWith(
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
    const descMinWidth = 220.0;
    const descMaxWidth = 260.0;
    final entryId = (entry['_id'] ?? entry['id'])?.toString() ?? '';
    final batchId = entry['_batchId']?.toString() ?? '';
    final date = StatementsShared.entryText(entry, ['date']);
    final valueDate = StatementsShared.entryText(entry, ['valueDate']);
    final desc = StatementsShared.entryText(entry, ['description']);
    final amount = StatementsShared.entryText(entry, ['amount']);
    final balance = StatementsShared.entryText(entry, ['balance']);
    final amountValue = StatementsFormatters.parseAmount(amount);
    final isNegative = (amountValue ?? 0) < 0;
    final linkError = controller.linkClientError[entryId];
    final linking = controller.linkingClient[entryId] == true;
    final suggestLoading = controller.loadingSuggestions[entryId] == true;
    final hasSuggestions =
        (controller.suggestions[entryId]?.isNotEmpty ?? false);
    final isSelected = entryId.isNotEmpty && selectedIds.contains(entryId);
    final isUnlinked = entry['clientId'] == null ||
        entry['clientId'].toString().trim().isEmpty;
    final baseRowColor = cs.surfaceVariant.withOpacity(0.18);
    final zebraRowColor = cs.surfaceVariant.withOpacity(0.08);
    final selectedRowColor = cs.primaryContainer.withOpacity(0.16);
    final rowColor = isSelected
        ? selectedRowColor
        : (index.isEven ? baseRowColor : zebraRowColor);
    final rowAccent = isNegative ? cs.tertiary : cs.primary;

    return Material(
      color: rowColor,
      child: InkWell(
        hoverColor: cs.primary.withOpacity(0.08),
        onTap: () => onShowDetails(entry),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4,
                    height: 52,
                    margin: const EdgeInsets.only(right: 8, top: 2),
                    decoration: BoxDecoration(
                      color: rowAccent.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  SizedBox(
                    width: 36,
                    child: Checkbox(
                      value: isSelected,
                      onChanged:
                          entryId.isEmpty ? null : (_) => onToggleRow(entryId),
                    ),
                  ),
                  if (!isCompact) ...[
                    SizedBox(
                      width: 90,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              batchId.isEmpty ? '-' : batchId,
                              style: typography.bodySmall.copyWith(
                                color: cs.onSurfaceVariant,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (batchId.isNotEmpty)
                            Tooltip(
                              message: l.statementsColumnBatchCopy,
                              child: InkWell(
                                onTap: () {
                                  Clipboard.setData(
                                      ClipboardData(text: batchId));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(l.copiedToClipboard)),
                                  );
                                },
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(Icons.copy, size: 14),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  SizedBox(
                    width: 100,
                    child: Text(
                      valueDate.isNotEmpty && valueDate != date
                          ? '${StatementsFormatters.formatDate(context, date)}\n${StatementsFormatters.formatDate(context, valueDate)}'
                          : (date.isNotEmpty
                              ? StatementsFormatters.formatDate(context, date)
                              : StatementsFormatters.formatDate(
                                  context, valueDate)),
                      style: typography.bodySmall,
                    ),
                  ),
                  const SizedBox(width: 8),
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
                              desc.isEmpty ? l.statementsNoDescription : desc,
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
                        minWidth: descMinWidth,
                        maxWidth: descMaxWidth,
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
                                desc.isEmpty ? l.statementsNoDescription : desc,
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
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 140,
                    child: _moneyText(
                      context,
                      amount,
                      emphasize: true,
                      amountColor: isNegative ? cs.tertiary : cs.primary,
                    ),
                  ),
                  if (!isCompact) ...[
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 150,
                      child: _moneyText(
                        context,
                        balance,
                        emphasize: false,
                        amountColor: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 200,
                    child: StatementsAllDataTableClientCell(
                      label: StatementsShared.clientLabel(l, controller, entry),
                      unlinked: isUnlinked,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: isCompact ? 44 : 112,
                    child: hasSelection
                        ? const SizedBox.shrink()
                        : isCompact
                            ? PopupMenuButton<String>(
                                tooltip: l.statementsHeaderActions,
                                onSelected: (value) {
                                  if (value == 'suggest') {
                                    onSuggest(entry);
                                  } else if (value == 'link') {
                                    onLink(entry);
                                  } else if (value == 'details') {
                                    onShowDetails(entry);
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'suggest',
                                    child: Text(l.statementsActionSuggest),
                                  ),
                                  PopupMenuItem(
                                    value: 'link',
                                    child: Text(l.statementsActionLink),
                                  ),
                                  PopupMenuItem(
                                    value: 'details',
                                    child: Text(l.statementsViewDetails),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Tooltip(
                                    message: l.statementsActionsTooltipSuggest,
                                    child: FilledButton.tonal(
                                      onPressed:
                                          suggestLoading || entryId.isEmpty
                                              ? null
                                              : () => onSuggest(entry),
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                        textStyle:
                                            typography.bodySmall.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      child: suggestLoading
                                          ? const SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2),
                                            )
                                          : Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (hasSuggestions)
                                                  const Icon(Icons.auto_awesome,
                                                      size: 14),
                                                if (hasSuggestions)
                                                  const SizedBox(width: 4),
                                                Text(l.statementsActionSuggest),
                                              ],
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  PopupMenuButton<String>(
                                    tooltip: l.statementsHeaderActions,
                                    icon:
                                        const Icon(Icons.more_horiz, size: 18),
                                    onSelected: (value) {
                                      if (value == 'link') {
                                        onLink(entry);
                                      } else if (value == 'details') {
                                        onShowDetails(entry);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: 'link',
                                        child: Text(l.statementsActionLink),
                                      ),
                                      PopupMenuItem(
                                        value: 'details',
                                        child: Text(l.statementsViewDetails),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                  ),
                ],
              ),
              if (linkError != null)
                Padding(
                  padding: const EdgeInsets.only(left: 44, top: 4),
                  child: Text(linkError, style: TextStyle(color: cs.error)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
