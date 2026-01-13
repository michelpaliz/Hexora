import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

import '../statements_controller.dart';
import '../statements_formatters.dart';
import 'statements_history_widgets.dart';

class StatementsHistoryList extends StatelessWidget {
  const StatementsHistoryList({
    super.key,
    required this.controller,
    required this.expandedTech,
    required this.onToggleTech,
    required this.onCopy,
    required this.showHeader,
  });

  final StatementsController controller;
  final Set<String> expandedTech;
  final ValueChanged<String> onToggleTech;
  final ValueChanged<String> onCopy;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final thresholdOptions = const [3, 5, 7];
    String labelFrom(String template) {
      final cleaned = template.replaceAll(':', '').trim();
      return cleaned.isEmpty ? template : cleaned;
    }

    final uploadedLabel = labelFrom(l.statementsUploadedAt(''));
    final entriesLabel = labelFrom(l.statementsEntryCount(''));
    final skippedLabelText = labelFrom(l.statementsSkippedLabel(''));
    final sheetLabelText = labelFrom(l.statementsSheetLabel(''));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showHeader)
              Row(
                children: [
                  const Icon(Icons.history),
                  const SizedBox(width: 8),
                  Text(l.statementsHistoryTabTitle, style: t.titleLarge),
                  const Spacer(),
                  SizedBox(
                    width: 120,
                    child: DropdownButtonFormField<int>(
                      initialValue: controller.statusThreshold,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: l.statementsFreshnessThreshold,
                        isDense: true,
                        border: const OutlineInputBorder(),
                      ),
                      items: thresholdOptions
                          .map(
                            (v) => DropdownMenuItem(
                              value: v,
                              child: Text(v.toString()),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        controller.setStatusThreshold(v);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: l.refreshAction,
                    onPressed: controller.loadingImports
                        ? null
                        : controller.listImports,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            if (controller.loadingImports)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (controller.importsError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  controller.importsError!,
                  style: t.bodySmall.copyWith(color: cs.error),
                ),
              )
            else if (controller.imports.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(l.statementsNoImports, style: t.bodySmall),
              )
            else
              Column(
                children: controller.imports.map((b) {
                  final id =
                      (b['batchId'] ?? b['_id'] ?? b['id'])?.toString() ?? '';
                  final filename =
                      (b['originalName'] ?? b['filename'])?.toString();
                  final uploadedAt =
                      b['uploadedAt'] ?? b['createdAt'] ?? b['date'];
                  final count = b['entryCount'] ?? b['entries'] ?? b['count'];
                  final skipped = b['skippedDuplicates'] ?? b['skipped'];
                  final checksum = b['checksum']?.toString();
                  final sheet = b['sheet']?.toString();
                  final uploader = b['userId']?.toString();
                  final deleting = controller.deletingBatch[id] == true;
                  final reprocessing = controller.reprocessingBatch[id] == true;
                  final deleteErr = controller.deleteBatchError[id];
                  final reprocessErr = controller.reprocessBatchError[id];
                  final fileLabel = filename?.isNotEmpty == true
                      ? filename!
                      : l.statementsBatchFallback;
                  final dateLabel = uploadedAt == null
                      ? '-'
                      : StatementsFormatters.formatDate(context, uploadedAt);
                  final countLabel = count == null
                      ? '-'
                      : StatementsFormatters.formatCount(context, count);
                  final skippedLabel = skipped == null
                      ? '-'
                      : StatementsFormatters.formatCount(context, skipped);
                  final batchStatusLabel = (skipped is num && skipped > 0)
                      ? l.statementsStatusWarning
                      : l.statementsStatusSuccess;
                  final batchStatusColor = (skipped is num && skipped > 0)
                      ? cs.tertiary
                      : cs.primary;
                  final showTech = expandedTech.contains(id);
                  final freshnessStatus = controller.batchStatus[id];
                  final statusLoading = controller.loadingStatus[id] == true;
                  final statusErr = controller.statusError[id];
                  final isStale = freshnessStatus?['stale'] == true;
                  final isAdmin = freshnessStatus?['isAdmin'] == true;
                  final lastDate = freshnessStatus?['lastDate'];
                  final daysSince = freshnessStatus?['daysSince'];
                  final hasLastDate =
                      lastDate != null && lastDate.toString().isNotEmpty;
                  final lastDateLabel = hasLastDate
                      ? StatementsFormatters.formatDate(context, lastDate)
                      : '';
                  final daysLabel = daysSince == null
                      ? ''
                      : StatementsFormatters.formatCount(context, daysSince);
                  final freshnessLabel = !hasLastDate
                      ? l.statementsFreshnessNoData
                      : isStale
                          ? l.statementsFreshnessStale(lastDateLabel, daysLabel)
                          : l.statementsFreshnessUpToDate(lastDateLabel);
                  final freshnessColor = isStale ? cs.error : cs.primary;

                  return Card(
                    color: controller.selectedBatchId == id
                        ? cs.primaryContainer.withOpacity(0.35)
                        : null,
                    elevation: 1,
                    shadowColor: cs.shadow.withOpacity(0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: cs.outlineVariant.withOpacity(0.35),
                      ),
                    ),
                    child: InkWell(
                      onTap: id.isEmpty
                          ? null
                          : () async {
                              await controller.fetchBatchEntries(id, page: 1);
                              await controller.fetchSummary(batchId: id);
                              await controller.fetchBatchStatus(id);
                            },
                      borderRadius: BorderRadius.circular(14),
                      hoverColor: cs.primary.withOpacity(0.06),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: Tooltip(
                                          message: fileLabel,
                                          child: Text(
                                            fileLabel,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: t.bodyLarge.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      StatusBadge(
                                        label: batchStatusLabel,
                                        color: batchStatusColor,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final columns =
                                    constraints.maxWidth < 420 ? 1 : 2;
                                final items = <Widget>[
                                  MetaItem(
                                    label: uploadedLabel,
                                    value: dateLabel,
                                    icon: Icons.calendar_today_outlined,
                                  ),
                                  MetaItem(
                                    label: entriesLabel,
                                    value: countLabel,
                                    icon: Icons.table_rows_outlined,
                                  ),
                                  MetaItem(
                                    label: skippedLabelText,
                                    value: skippedLabel,
                                    icon: Icons.copy_all_outlined,
                                  ),
                                  if (sheet != null && sheet.isNotEmpty)
                                    MetaItem(
                                      label: sheetLabelText,
                                      value: sheet,
                                      valueTooltip: sheet,
                                      icon: Icons.grid_view_outlined,
                                    ),
                                ];
                                return GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: items.length,
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columns,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 8,
                                    mainAxisExtent: 44,
                                  ),
                                  itemBuilder: (context, index) => items[index],
                                );
                              },
                            ),
                            if (skipped is num && skipped > 0) ...[
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: cs.tertiaryContainer.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: cs.tertiary.withOpacity(0.2),
                                  ),
                                ),
                                child: Text(
                                  l.statementsSkippedLabel(skippedLabel),
                                  style: t.bodySmall.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              alignment: WrapAlignment.start,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                FilledButton(
                                  onPressed: id.isEmpty ||
                                          deleting ||
                                          reprocessing
                                      ? null
                                      : () async {
                                          await controller.fetchBatchEntries(id,
                                              page: 1);
                                          await controller.fetchSummary(
                                              batchId: id);
                                          await controller.fetchBatchStatus(id);
                                        },
                                  child: Text(l.statementsActionViewEntries),
                                ),
                                OutlinedButton(
                                  onPressed: id.isEmpty ||
                                          deleting ||
                                          reprocessing
                                      ? null
                                      : () async {
                                          final ok = await showDialog<bool>(
                                            context: context,
                                            builder: (dialogContext) {
                                              return AlertDialog(
                                                title: Text(
                                                    l.statementsReprocessTitle),
                                                content: Text(l
                                                    .statementsReprocessMessage),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(
                                                                dialogContext)
                                                            .pop(false),
                                                    child: Text(
                                                        l.statementsCancel),
                                                  ),
                                                  FilledButton(
                                                    onPressed: () =>
                                                        Navigator.of(
                                                                dialogContext)
                                                            .pop(true),
                                                    child: Text(l
                                                        .statementsReprocessAction),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                          if (ok == true) {
                                            await controller.reprocessBatch(id);
                                          }
                                        },
                                  child: reprocessing
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        )
                                      : Text(l.statementsReprocessAction),
                                ),
                                PopupMenuButton<String>(
                                  tooltip: l.moreActions,
                                  onSelected: (value) async {
                                    if (value == 'delete') {
                                      final ok = await showDialog<bool>(
                                        context: context,
                                        builder: (dialogContext) {
                                          return AlertDialog(
                                            title:
                                                Text(l.statementsDeleteTitle),
                                            content:
                                                Text(l.statementsDeleteMessage),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(dialogContext)
                                                        .pop(false),
                                                child: Text(l.statementsCancel),
                                              ),
                                              FilledButton(
                                                onPressed: () =>
                                                    Navigator.of(dialogContext)
                                                        .pop(true),
                                                child: Text(
                                                    l.statementsDeleteAction),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                      if (ok == true) {
                                        await controller.deleteBatch(id);
                                      }
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline,
                                              color: cs.error),
                                          const SizedBox(width: 8),
                                          Text(
                                            l.statementsDeleteAction,
                                            style: TextStyle(color: cs.error),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (deleteErr != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  deleteErr,
                                  style: t.bodySmall.copyWith(color: cs.error),
                                ),
                              ),
                            if (reprocessErr != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  reprocessErr,
                                  style: t.bodySmall.copyWith(color: cs.error),
                                ),
                              ),
                            const SizedBox(height: 6),
                            TextButton.icon(
                              onPressed: () => onToggleTech(id),
                              icon: Icon(showTech
                                  ? Icons.expand_less
                                  : Icons.expand_more),
                              label: Text(
                                showTech
                                    ? l.statementsHideTechDetails
                                    : l.statementsShowTechDetails,
                              ),
                            ),
                            if (showTech)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerHighest
                                      .withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TechLine(
                                      label: l.statementsTechBatchId,
                                      value: id,
                                      onCopy:
                                          id.isEmpty ? null : () => onCopy(id),
                                    ),
                                    if (checksum != null && checksum.isNotEmpty)
                                      TechLine(
                                        label: l.statementsTechChecksum,
                                        value: checksum,
                                        onCopy: () => onCopy(checksum),
                                      ),
                                    if (uploader != null && uploader.isNotEmpty)
                                      TechLine(
                                        label: l.statementsTechUploader,
                                        value: uploader,
                                        onCopy: () => onCopy(uploader),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
