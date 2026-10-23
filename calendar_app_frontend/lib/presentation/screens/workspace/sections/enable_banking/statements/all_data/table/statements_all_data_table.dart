import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hexora/theme/typography/hexora_design_tokens.dart';
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
    this.activeEntryId,
    required this.onToggleAll,
    required this.onToggleRow,
    required this.onShowDetails,
    required this.onSuggest,
    required this.onLinkInvoice,
    required this.onMarkNoProcede,
    required this.noProcedeReasonForEntry,
    required this.tableTheme,
    required this.onDateFilterTap,
    required this.dateFilterActive,
    required this.onDescriptionFilterTap,
    required this.descriptionFilterActive,
    required this.onNotesFilterTap,
    required this.notesFilterActive,
    required this.onAmountFilterTap,
    required this.amountFilterActive,
    required this.onClientProviderFilterTap,
    required this.clientProviderFilterActive,
    required this.onInvoiceSortTap,
    required this.invoiceSortMode,
  });

  final List<Map<String, dynamic>> entries;
  final StatementsController controller;
  final Set<String> selectedIds;

  /// Entry currently shown in the side panel; its row is highlighted.
  final String? activeEntryId;
  final ValueChanged<bool> onToggleAll;
  final ValueChanged<String> onToggleRow;
  final ValueChanged<Map<String, dynamic>> onShowDetails;
  final ValueChanged<Map<String, dynamic>> onSuggest;
  final ValueChanged<Map<String, dynamic>> onLinkInvoice;
  final ValueChanged<Map<String, dynamic>> onMarkNoProcede;
  final String? Function(Map<String, dynamic> entry) noProcedeReasonForEntry;
  final StatementsTableTheme tableTheme;
  final VoidCallback onDateFilterTap;
  final bool dateFilterActive;
  final VoidCallback onDescriptionFilterTap;
  final bool descriptionFilterActive;
  final VoidCallback onNotesFilterTap;
  final bool notesFilterActive;
  final VoidCallback onAmountFilterTap;
  final bool amountFilterActive;
  final VoidCallback onClientProviderFilterTap;
  final bool clientProviderFilterActive;
  final VoidCallback onInvoiceSortTap;
  final int invoiceSortMode;

  double _rowExtent(BuildContext context) =>
      HexoraTableTokens.rowMinHeight +
      HexoraTableTokens.gap +
      math.max(0, MediaQuery.textScalerOf(context).scale(13) - 13) * 3;

  double _preferredHeight(BuildContext context) {
    const headerAndGapHeight = 52.0;
    final rowExtent = _rowExtent(context);
    final contentHeight = headerAndGapHeight + (entries.length * rowExtent);
    final viewportHeight = (MediaQuery.sizeOf(context).height * 0.68)
        .clamp(360.0, 720.0)
        .toDouble();
    return math.min(contentHeight, viewportHeight);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

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
        // Use the space left after sidebars, not the full window width.
        // Keep enough room for the compact fixed columns and description.
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final tableWidth = math.max(800.0, availableWidth);
        final isCompact = tableWidth < 1100;
        final isTablet = tableWidth >= 1100 && tableWidth < 1500;
        final tableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : _preferredHeight(context);

        final list = ListView.builder(
          itemCount: entries.length,
          itemExtent: _rowExtent(context),
          primary: false,
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: true,
          cacheExtent: 192,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          itemBuilder: (context, index) {
            final entry = entries[index];
            final entryId = (entry['_id'] ?? entry['id'])?.toString() ?? '';
            return Padding(
              key: ValueKey(entryId),
              padding: EdgeInsets.zero,
              child: StatementsAllDataTableRow(
                entry: entry,
                index: index,
                isCompact: isCompact,
                isTablet: isTablet,
                controller: controller,
                selectedIds: selectedIds,
                activeEntryId: activeEntryId,
                onToggleRow: onToggleRow,
                onShowDetails: onShowDetails,
                onSuggest: onSuggest,
                onLinkInvoice: onLinkInvoice,
                onMarkNoProcede: onMarkNoProcede,
                noProcedeReason: noProcedeReasonForEntry(entry),
                tableTheme: tableTheme,
              ),
            );
          },
        );

        final table = Container(
          height: tableHeight,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tableTheme.border),
          ),
          child: Column(
            children: [
              StatementsAllDataTableHeader(
                label: l,
                isCompact: isCompact,
                isTablet: isTablet,
                allVisibleSelected: allVisibleSelected,
                onToggleAll: onToggleAll,
                tableTheme: tableTheme,
                onDateFilterTap: onDateFilterTap,
                dateFilterActive: dateFilterActive,
                onDescriptionFilterTap: onDescriptionFilterTap,
                descriptionFilterActive: descriptionFilterActive,
                onNotesFilterTap: onNotesFilterTap,
                notesFilterActive: notesFilterActive,
                onAmountFilterTap: onAmountFilterTap,
                amountFilterActive: amountFilterActive,
                onClientProviderFilterTap: onClientProviderFilterTap,
                clientProviderFilterActive: clientProviderFilterActive,
                onInvoiceSortTap: onInvoiceSortTap,
                invoiceSortMode: invoiceSortMode,
              ),
              Expanded(child: list),
            ],
          ),
        );
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: tableWidth, child: table),
        );
      },
    );
  }
}
