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
    required this.tableTheme,
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
  final StatementsTableTheme tableTheme;

  bool _isCompact(BuildContext context) =>
      MediaQuery.of(context).size.width < 1100;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isCompact = _isCompact(context);
    final entries = this.entries;
    final controller = this.controller;
    final selectedIds = this.selectedIds;

    final selectableVisible = entries.where((entry) {
      final id = (entry['_id'] ?? entry['id'])?.toString();
      return id != null && id.isNotEmpty;
    }).toList();
    final allVisibleSelected = selectableVisible.isNotEmpty &&
        selectableVisible.every(
            (e) => selectedIds.contains((e['_id'] ?? e['id'])?.toString()));

    return Column(
      children: [
        StatementsAllDataTableHeader(
          label: l,
          isCompact: isCompact,
          allVisibleSelected: allVisibleSelected,
          onToggleAll: onToggleAll,
          tableTheme: tableTheme,
        ),
        const SizedBox(height: 24),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: entries.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final entry = Map<String, dynamic>.from(entries[index]);
            return RepaintBoundary(
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
                tableTheme: tableTheme,
              ),
            );
          },
        ),
      ],
    );
  }
}
