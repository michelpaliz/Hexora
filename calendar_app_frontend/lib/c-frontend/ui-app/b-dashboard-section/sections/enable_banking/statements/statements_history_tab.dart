import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'history/statements_history_entries.dart';
import 'history/statements_history_list.dart';
import 'statements_controller.dart';

class StatementsHistoryTab extends StatefulWidget {
  const StatementsHistoryTab({super.key});

  @override
  State<StatementsHistoryTab> createState() => _StatementsHistoryTabState();
}

class _StatementsHistoryTabState extends State<StatementsHistoryTab>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final List<int> _sizeOptions = const [50, 100, 200];
  final Set<String> _expandedTech = <String>{};

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _yearController.dispose();
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  int? _parseYear(String value) {
    final v = value.trim();
    if (v.isEmpty) return null;
    return int.tryParse(v);
  }

  Future<void> _applyFilters(StatementsController s) async {
    if (s.selectedBatchId == null) return;
    final year = _parseYear(_yearController.text);
    final dateFrom = _fromController.text.trim().isEmpty
        ? null
        : _fromController.text.trim();
    final dateTo =
        _toController.text.trim().isEmpty ? null : _toController.text.trim();
    await s.fetchBatchEntries(
      s.selectedBatchId!,
      page: 1,
      year: year,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
    await s.fetchSummary(
      batchId: s.selectedBatchId!,
      year: year,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
  }

  Future<void> _clearFilters(StatementsController s) async {
    _yearController.clear();
    _fromController.clear();
    _toController.clear();
    if (s.selectedBatchId == null) return;
    await s.fetchBatchEntries(
      s.selectedBatchId!,
      page: 1,
      year: null,
      dateFrom: null,
      dateTo: null,
    );
    await s.fetchSummary(
      batchId: s.selectedBatchId!,
      year: null,
      dateFrom: null,
      dateTo: null,
    );
  }

  Future<void> _copy(BuildContext context, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.copiedToClipboard)),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final s = context.watch<StatementsController>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1200;
        if (!wide) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              StatementsHistoryList(
                controller: s,
                expandedTech: _expandedTech,
                onToggleTech: (id) {
                  setState(() {
                    if (_expandedTech.contains(id)) {
                      _expandedTech.remove(id);
                    } else {
                      _expandedTech.add(id);
                    }
                  });
                },
                onCopy: (value) => _copy(context, value),
                showHeader: true,
              ),
              const SizedBox(height: 16),
              StatementsHistoryEntries(
                controller: s,
                yearController: _yearController,
                fromController: _fromController,
                toController: _toController,
                sizeOptions: _sizeOptions,
                onApplyFilters: () => _applyFilters(s),
                onClearFilters: () => _clearFilters(s),
                parseYear: _parseYear,
              ),
              const SizedBox(height: 80),
            ],
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 360,
                  child: StatementsHistoryList(
                    controller: s,
                    expandedTech: _expandedTech,
                    onToggleTech: (id) {
                      setState(() {
                        if (_expandedTech.contains(id)) {
                          _expandedTech.remove(id);
                        } else {
                          _expandedTech.add(id);
                        }
                      });
                    },
                    onCopy: (value) => _copy(context, value),
                    showHeader: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatementsHistoryEntries(
                    controller: s,
                    yearController: _yearController,
                    fromController: _fromController,
                    toController: _toController,
                    sizeOptions: _sizeOptions,
                    onApplyFilters: () => _applyFilters(s),
                    onClearFilters: () => _clearFilters(s),
                    parseYear: _parseYear,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 80),
          ],
        );
      },
    );
  }
}
