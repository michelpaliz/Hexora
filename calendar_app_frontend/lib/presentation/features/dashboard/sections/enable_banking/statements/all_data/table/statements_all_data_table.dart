import 'dart:math' as math;

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
    required this.onDateFilterTap,
    required this.dateFilterActive,
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
  final ValueChanged<bool> onToggleAll;
  final ValueChanged<String> onToggleRow;
  final ValueChanged<Map<String, dynamic>> onShowDetails;
  final ValueChanged<Map<String, dynamic>> onSuggest;
  final ValueChanged<Map<String, dynamic>> onLink;
  final ValueChanged<Map<String, dynamic>> onLinkInvoice;
  final ValueChanged<Map<String, dynamic>> onMarkNoProcede;
  final String? Function(Map<String, dynamic> entry) noProcedeReasonForEntry;
  final StatementsTableTheme tableTheme;
  final VoidCallback onDateFilterTap;
  final bool dateFilterActive;
  final VoidCallback onAmountFilterTap;
  final bool amountFilterActive;
  final VoidCallback onClientProviderFilterTap;
  final bool clientProviderFilterActive;
  final VoidCallback onInvoiceSortTap;
  final int invoiceSortMode;

  bool _isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 800;

  bool _isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= 800 && width < 1500;
  }

  double _preferredHeight(BuildContext context) {
    const headerAndGapHeight = 70.0;
    const rowExtent = 64.0;
    final contentHeight = headerAndGapHeight + (entries.length * rowExtent);
    final viewportHeight = (MediaQuery.sizeOf(context).height * 0.68)
        .clamp(360.0, 720.0)
        .toDouble();
    return math.min(contentHeight, viewportHeight);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isCompact = _isCompact(context);
    final isTablet = _isTablet(context);

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
        final tableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : _preferredHeight(context);

        final list = ListView.builder(
          itemCount: entries.length,
          itemExtent: 64,
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
              padding: index < entries.length - 1
                  ? const EdgeInsets.only(bottom: 5)
                  : EdgeInsets.zero,
              child: StatementsAllDataTableRow(
                entry: entry,
                index: index,
                isCompact: isCompact,
                isTablet: isTablet,
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

        return SizedBox(
          height: tableHeight,
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
                onAmountFilterTap: onAmountFilterTap,
                amountFilterActive: amountFilterActive,
                onClientProviderFilterTap: onClientProviderFilterTap,
                clientProviderFilterActive: clientProviderFilterActive,
                onInvoiceSortTap: onInvoiceSortTap,
                invoiceSortMode: invoiceSortMode,
              ),
              const SizedBox(height: 6),
              Expanded(child: list),
            ],
          ),
        );
      },
    );
  }
}
