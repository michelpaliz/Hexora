import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';

import '../../statements_controller.dart';
import 'statements_all_data_table_header.dart';
import 'statements_all_data_table_row.dart';

class StatementsAllDataTable extends StatefulWidget {
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
  });

  final List<Map<String, dynamic>> entries;
  final StatementsController controller;
  final Set<String> selectedIds;
  final ValueChanged<bool> onToggleAll;
  final ValueChanged<String> onToggleRow;
  final ValueChanged<Map<String, dynamic>> onShowDetails;
  final ValueChanged<Map<String, dynamic>> onSuggest;
  final ValueChanged<Map<String, dynamic>> onLink;

  @override
  State<StatementsAllDataTable> createState() => _StatementsAllDataTableState();
}

class _StatementsAllDataTableState extends State<StatementsAllDataTable> {
  bool _isCompact(BuildContext context) =>
      MediaQuery.of(context).size.width < 1100;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isCompact = _isCompact(context);
    final entries = widget.entries;
    final controller = widget.controller;
    final selectedIds = widget.selectedIds;

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
          onToggleAll: widget.onToggleAll,
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = Map<String, dynamic>.from(entries[index]);
            return RepaintBoundary(
              child: StatementsAllDataTableRow(
                entry: entry,
                index: index,
                isCompact: isCompact,
                controller: controller,
                selectedIds: selectedIds,
                hasSelection: selectedIds.isNotEmpty,
                onToggleRow: widget.onToggleRow,
                onShowDetails: widget.onShowDetails,
                onSuggest: widget.onSuggest,
                onLink: widget.onLink,
              ),
            );
          },
        ),
      ],
    );
  }
}
