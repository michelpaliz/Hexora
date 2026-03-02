import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';

import '../../statements_controller.dart';
import 'statements_all_data_table_header.dart';
import 'statements_all_data_table_row.dart';
import 'statements_all_data_table_theme.dart';

class StatementsAllDataTable extends StatelessWidget {
  const StatementsAllDataTable({
    super.key,
    required this.entries,
    required this.controller,
    required this.selectedIds,
    required this.onToggleAll,
    required this.onToggleRow,
    required this.onShowDetails,
    required this.onSuggest,
    required this.onLink,
    required this.onLinkInvoice,
    required this.onMarkNoProcede,
    required this.noProcedeReasonForEntry,
    required this.tableTheme,
    required this.onAmountFilterTap,
    required this.amountFilterActive,
    required this.onInvoiceSortTap,
    required this.invoiceSortMode,
  });

  final List<Map<String, dynamic>> entries;
  final StatementsController controller;
  final Set<String> selectedIds;
  final ValueChanged<bool> onToggleAll;
  final ValueChanged<String> onToggleRow;
  final ValueChanged<Map<String, dynamic>> onShowDetails;
  final ValueChanged<Map<String, dynamic>> onSuggest;
  final ValueChanged<Map<String, dynamic>> onLink;
  final ValueChanged<Map<String, dynamic>> onLinkInvoice;
  final ValueChanged<Map<String, dynamic>> onMarkNoProcede;
  final String? Function(Map<String, dynamic> entry) noProcedeReasonForEntry;
  final StatementsTableTheme tableTheme;
  final VoidCallback onAmountFilterTap;
  final bool amountFilterActive;
  final VoidCallback onInvoiceSortTap;
  final int invoiceSortMode;

  bool _isCompact(BuildContext context) =>
      MediaQuery.of(context).size.width < 1100;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isCompact = _isCompact(context);

    final selectableVisible = entries.where((entry) {
      final id = (entry['_id'] ?? entry['id'])?.toString();
      return id != null && id.isNotEmpty;
    }).toList(growable: false);
    final allVisibleSelected = selectableVisible.isNotEmpty &&
        selectableVisible.every(
          (e) => selectedIds.contains((e['_id'] ?? e['id'])?.toString()),
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedHeight = constraints.maxHeight.isFinite;

        final list = ListView.builder(
          itemCount: entries.length,
          itemExtent: 80,
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: true,
          cacheExtent: 500,
          shrinkWrap: !hasBoundedHeight,
          physics:
              hasBoundedHeight ? null : const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final entry = entries[index];
            final entryId = (entry['_id'] ?? entry['id'])?.toString() ?? '';
            return Padding(
              key: ValueKey(entryId),
              padding: index < entries.length - 1
                  ? const EdgeInsets.only(bottom: 4)
                  : EdgeInsets.zero,
              child: StatementsAllDataTableRow(
                entry: entry,
                index: index,
                isCompact: isCompact,
                controller: controller,
                selectedIds: selectedIds,
                onToggleRow: onToggleRow,
                onShowDetails: onShowDetails,
                onSuggest: onSuggest,
                onLink: onLink,
                onLinkInvoice: onLinkInvoice,
                onMarkNoProcede: onMarkNoProcede,
                noProcedeReason: noProcedeReasonForEntry(entry),
                tableTheme: tableTheme,
              ),
            );
          },
        );

        return Column(
          children: [
            StatementsAllDataTableHeader(
              label: l,
              isCompact: isCompact,
              allVisibleSelected: allVisibleSelected,
              onToggleAll: onToggleAll,
              tableTheme: tableTheme,
              onAmountFilterTap: onAmountFilterTap,
              amountFilterActive: amountFilterActive,
              onInvoiceSortTap: onInvoiceSortTap,
              invoiceSortMode: invoiceSortMode,
            ),
            const SizedBox(height: 6),
            if (hasBoundedHeight) Expanded(child: list) else list,
          ],
        );
      },
    );
  }
}
