import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

import '../statements_controller.dart';
import '../statements_formatters.dart';
import '../statements_shared.dart';

class StatementsHistoryEntries extends StatelessWidget {
  const StatementsHistoryEntries({
    super.key,
    required this.controller,
    required this.yearController,
    required this.fromController,
    required this.toController,
    required this.sizeOptions,
    required this.onApplyFilters,
    required this.onClearFilters,
    required this.parseYear,
  });

  final StatementsController controller;
  final TextEditingController yearController;
  final TextEditingController fromController;
  final TextEditingController toController;
  final List<int> sizeOptions;
  final VoidCallback onApplyFilters;
  final VoidCallback onClearFilters;
  final int? Function(String value) parseYear;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);

    if (controller.entriesYear != null &&
        yearController.text != controller.entriesYear.toString()) {
      yearController.text = controller.entriesYear.toString();
    }
    if (controller.entriesDateFrom != null &&
        fromController.text != controller.entriesDateFrom) {
      fromController.text = controller.entriesDateFrom ?? '';
    }
    if (controller.entriesDateTo != null &&
        toController.text != controller.entriesDateTo) {
      toController.text = controller.entriesDateTo ?? '';
    }

    final totalPages = controller.entriesSize == 0
        ? 1
        : (controller.entriesTotal / controller.entriesSize)
            .ceil()
            .clamp(1, 9999);

    final inputPadding = const EdgeInsets.symmetric(horizontal: 8, vertical: 6);
    final inputStyle = t.bodySmall;

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.table_chart_outlined, size: 16, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                l.statementsBatchEntries,
                style: t.bodySmall.copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              if (controller.selectedBatchId != null)
                Text(
                  l.statementsBatchChip(controller.selectedBatchId!),
                  style: t.caption.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 100,
                child: TextField(
                  controller: yearController,
                  style: inputStyle,
                  decoration: InputDecoration(
                    labelText: l.statementsFilterYear,
                    hintText: '2025',
                    isDense: true,
                    border: const OutlineInputBorder(),
                    contentPadding: inputPadding,
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: fromController,
                  style: inputStyle,
                  decoration: InputDecoration(
                    labelText: l.statementsFilterFrom,
                    hintText: 'YYYY-MM-DD',
                    isDense: true,
                    border: const OutlineInputBorder(),
                    contentPadding: inputPadding,
                  ),
                ),
              ),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: toController,
                  style: inputStyle,
                  decoration: InputDecoration(
                    labelText: l.statementsFilterTo,
                    hintText: 'YYYY-MM-DD',
                    isDense: true,
                    border: const OutlineInputBorder(),
                    contentPadding: inputPadding,
                  ),
                ),
              ),
              SizedBox(
                width: 100,
                child: DropdownButtonFormField<int>(
                  initialValue: controller.entriesSize,
                  style: inputStyle,
                  decoration: InputDecoration(
                    labelText: l.statementsPageSize,
                    isDense: true,
                    border: const OutlineInputBorder(),
                    contentPadding: inputPadding,
                  ),
                  items: sizeOptions
                      .map(
                        (v) => DropdownMenuItem(
                          value: v,
                          child: Text(v.toString()),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v == null || controller.selectedBatchId == null) return;
                    controller.fetchBatchEntries(controller.selectedBatchId!, page: 1, size: v);
                  },
                ),
              ),
              SizedBox(
                width: 110,
                child: DropdownButtonFormField<String>(
                  initialValue: controller.entriesOrder,
                  style: inputStyle,
                  decoration: InputDecoration(
                    labelText: 'Orden',
                    isDense: true,
                    border: const OutlineInputBorder(),
                    contentPadding: inputPadding,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'source',
                      child: Text('Origen'),
                    ),
                    DropdownMenuItem(
                      value: 'date',
                      child: Text('Fecha'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v == null || controller.selectedBatchId == null) return;
                    controller.fetchBatchEntries(
                      controller.selectedBatchId!,
                      page: 1,
                      order: v,
                    );
                  },
                ),
              ),
              FilledButton.tonal(
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  textStyle: const TextStyle(fontSize: 11),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: controller.selectedBatchId == null ? null : onApplyFilters,
                child: Text(l.statementsApplyFilters),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  textStyle: const TextStyle(fontSize: 11),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: controller.selectedBatchId == null ? null : onClearFilters,
                child: Text(l.statementsClearFilters),
              ),
            ],
          ),
            const SizedBox(height: 8),
            Card(
              color: cs.surfaceContainerHighest.withOpacity(0.4),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.insights_outlined),
                        const SizedBox(width: 8),
                        Text(l.statementsSummaryTitle, style: t.bodyLarge),
                        const Spacer(),
                        Wrap(
                          spacing: 8,
                          children: [
                            ChoiceChip(
                              label: Text(l.statementsSummaryMonthly),
                              selected: controller.summaryGroup == 'month',
                              onSelected: controller.selectedBatchId == null
                                  ? null
                                  : (_) => controller.fetchSummary(
                                        batchId: controller.selectedBatchId!,
                                        group: 'month',
                                        year: parseYear(yearController.text),
                                        dateFrom: fromController.text.trim().isEmpty
                                            ? null
                                            : fromController.text.trim(),
                                        dateTo: toController.text.trim().isEmpty
                                            ? null
                                            : toController.text.trim(),
                                      ),
                            ),
                            ChoiceChip(
                              label: Text(l.statementsSummaryYearly),
                              selected: controller.summaryGroup == 'year',
                              onSelected: controller.selectedBatchId == null
                                  ? null
                                  : (_) => controller.fetchSummary(
                                        batchId: controller.selectedBatchId!,
                                        group: 'year',
                                        year: parseYear(yearController.text),
                                        dateFrom: fromController.text.trim().isEmpty
                                            ? null
                                            : fromController.text.trim(),
                                        dateTo: toController.text.trim().isEmpty
                                            ? null
                                            : toController.text.trim(),
                                      ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (controller.loadingSummary)
                      const LinearProgressIndicator()
                    else if (controller.summaryError != null)
                      Text(controller.summaryError!, style: t.bodySmall.copyWith(color: cs.error))
                    else if (controller.summary.isEmpty)
                      Text(l.statementsSummaryEmpty, style: t.bodySmall)
                    else
                      Column(
                        children: controller.summary.map((row) {
                          final year = row['year']?.toString() ?? '';
                          final month = row['month']?.toString();
                          final total =
                              StatementsFormatters.formatAmount(context, row['total']);
                          final income =
                              StatementsFormatters.formatAmount(context, row['income']);
                          final expense =
                              StatementsFormatters.formatAmount(context, row['expense']);
                          final count =
                              StatementsFormatters.formatCount(context, row['count']);
                          final label = month == null || month.isEmpty
                              ? year
                              : '${month.padLeft(2, '0')}/$year';
                          return ListTile(
                            dense: true,
                            title: Text(label, style: t.bodyMedium),
                            subtitle: Text(
                              l.statementsSummaryLine(total, count),
                              style: t.bodySmall,
                            ),
                            trailing: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${l.statementsSummaryNet}: $total',
                                    style: t.bodySmall),
                                Text('${l.statementsSummaryIncome}: $income',
                                    style: t.bodySmall),
                                Text('${l.statementsSummaryExpense}: $expense',
                                    style: t.bodySmall),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (controller.loadingEntries)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (controller.entriesError != null)
              Text(controller.entriesError!, style: t.bodySmall.copyWith(color: cs.error))
            else if (controller.entries.isEmpty)
              Text(l.statementsSelectBatch, style: t.bodySmall)
            else
              Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 110,
                          child: Text(
                            l.statementsHeaderDate,
                            style: t.bodySmall.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: Text(
                            l.statementsHeaderDescription,
                            style: t.bodySmall.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: Text(
                            l.statementsHeaderDetails,
                            style: t.bodySmall.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 90,
                          child: Text(
                            l.statementsHeaderAmount,
                            style: t.bodySmall.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 90,
                          child: Text(
                            l.statementsHeaderBalance,
                            style: t.bodySmall.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: Text(
                            l.statementsHeaderClient,
                            style: t.bodySmall.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 180,
                          child: Text(
                            l.statementsHeaderActions,
                            style: t.bodySmall.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...controller.entries.map((entry) {
                    final e = Map<String, dynamic>.from(entry);
                    final entryId = (e['_id'] ?? e['id'])?.toString() ?? '';
                    final date = StatementsShared.entryText(e, ['date']);
                    final valueDate = StatementsShared.entryText(e, ['valueDate']);
                    final desc = StatementsShared.entryText(e, ['description']);
                    final details = StatementsShared.entryText(e, ['details']);
                    final amount = StatementsShared.entryText(e, ['amount']);
                    final balance = StatementsShared.entryText(e, ['balance']);
                    final linkError = controller.linkClientError[entryId];
                    final linking = controller.linkingClient[entryId] == true;
                    final suggestLoading = controller.loadingSuggestions[entryId] == true;

                    return Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 110,
                              child: Text(
                                valueDate.isNotEmpty && valueDate != date
                                    ? '${StatementsFormatters.formatDate(context, date)}\n${StatementsFormatters.formatDate(context, valueDate)}'
                                    : (date.isNotEmpty
                                        ? StatementsFormatters.formatDate(
                                            context,
                                            date,
                                          )
                                        : StatementsFormatters.formatDate(
                                            context,
                                            valueDate,
                                          )),
                                style: t.bodySmall,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 3,
                              child: Text(
                                desc.isEmpty ? l.statementsNoDescription : desc,
                                style: t.bodyMedium,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 3,
                              child: Text(
                                details.isEmpty ? '-' : details,
                                style: t.bodySmall,
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 90,
                              child: Text(
                                StatementsFormatters.formatAmount(context, amount),
                                style: t.bodyMedium,
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 90,
                              child: Text(
                                StatementsFormatters.formatAmount(context, balance),
                                style: t.bodyMedium,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: Text(
                                StatementsShared.clientLabel(l, controller, e),
                                style: t.bodyMedium,
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 180,
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  TextButton(
                                    onPressed: suggestLoading || entryId.isEmpty
                                        ? null
                                        : () => StatementsShared.showSuggestionsDialog(
                                              context,
                                              controller,
                                              e,
                                            ),
                                    child: suggestLoading
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : Text(l.statementsActionSuggest),
                                  ),
                                  TextButton(
                                    onPressed: entryId.isEmpty || linking
                                        ? null
                                        : () => StatementsShared.showClientPickerDialog(
                                              context,
                                              controller,
                                              e,
                                            ),
                                    child: linking
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : Text(l.statementsActionLink),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (linkError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                linkError,
                                style: t.bodySmall.copyWith(color: cs.error),
                              ),
                            ),
                          ),
                        const Divider(),
                      ],
                    );
                  }),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        l.statementsPageInfo(controller.entriesPage, totalPages),
                        style: t.bodySmall,
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: controller.entriesPage > 1 &&
                                controller.selectedBatchId != null
                            ? () => controller.fetchBatchEntries(
                                  controller.selectedBatchId!,
                                  page: controller.entriesPage - 1,
                                )
                            : null,
                        child: Text(l.statementsPrevPage),
                      ),
                      TextButton(
                        onPressed: controller.entriesPage < totalPages &&
                                controller.selectedBatchId != null
                            ? () => controller.fetchBatchEntries(
                                  controller.selectedBatchId!,
                                  page: controller.entriesPage + 1,
                                )
                            : null,
                        child: Text(l.statementsNextPage),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      );
  }
}
