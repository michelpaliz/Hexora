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
    this.onOpenEntries,
  });

  final StatementsController controller;
  final Set<String> expandedTech;
  final ValueChanged<String> onToggleTech;
  final ValueChanged<String> onCopy;
  final bool showHeader;
  final VoidCallback? onOpenEntries;

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

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showHeader)
            Row(
              children: [
                Icon(Icons.history, size: 16, color: cs.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  l.statementsHistoryTabTitle,
                  style: t.bodySmall.copyWith(fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                SizedBox(
                  width: 100,
                  child: DropdownButtonFormField<int>(
                    initialValue: controller.statusThreshold,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l.statementsFreshnessThreshold,
                      isDense: true,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                    ),
                    style: t.bodySmall,
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
                const SizedBox(width: 6),
                IconButton(
                  tooltip: l.refreshAction,
                  onPressed:
                      controller.loadingImports ? null : controller.listImports,
                  icon: const Icon(Icons.refresh, size: 18),
                  constraints:
                      const BoxConstraints(minWidth: 28, minHeight: 28),
                  padding: EdgeInsets.zero,
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
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.imports.length,
              itemBuilder: (context, index) {
                final b = controller.imports[index];
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
                final batchStatusColor =
                    (skipped is num && skipped > 0) ? cs.tertiary : cs.primary;
                final showTech = expandedTech.contains(id);
                final isSelected = controller.selectedBatchId == id;
                final borderColor = isSelected
                    ? cs.primary.withValues(alpha: 0.5)
                    : cs.outlineVariant.withValues(alpha: 0.25);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Material(
                    color: isSelected
                        ? cs.primaryContainer.withValues(alpha: 0.25)
                        : Theme.of(context).canvasColor,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: id.isEmpty
                          ? null
                          : () async {
                              await controller.fetchBatchEntries(id, page: 1);
                              await controller.fetchSummary(batchId: id);
                              await controller.fetchBatchStatus(id);
                              onOpenEntries?.call();
                            },
                      borderRadius: BorderRadius.circular(8),
                      hoverColor: cs.primary.withValues(alpha: 0.05),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
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
                                            style: t.bodySmall.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      StatusBadge(
                                        label: batchStatusLabel,
                                        color: batchStatusColor,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$uploadedLabel $dateLabel · '
                                  '$entriesLabel $countLabel · '
                                  '$skippedLabelText $skippedLabel'
                                  '${(sheet != null && sheet.isNotEmpty) ? ' · $sheetLabelText $sheet' : ''}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: t.caption.copyWith(
                                    color: cs.onSurfaceVariant,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    textStyle: const TextStyle(fontSize: 11),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: id.isEmpty ||
                                          deleting ||
                                          reprocessing
                                      ? null
                                      : () async {
                                          await controller.fetchBatchEntries(
                                            id,
                                            page: 1,
                                          );
                                          await controller.fetchSummary(
                                            batchId: id,
                                          );
                                          await controller.fetchBatchStatus(id);
                                          onOpenEntries?.call();
                                        },
                                  child: Text(l.statementsActionViewEntries),
                                ),
                                const SizedBox(width: 4),
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    textStyle: const TextStyle(fontSize: 11),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
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
                                                  l.statementsReprocessTitle,
                                                ),
                                                content: Text(
                                                  l.statementsReprocessMessage,
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(
                                                                dialogContext)
                                                            .pop(false),
                                                    child: Text(
                                                      l.statementsCancel,
                                                    ),
                                                  ),
                                                  FilledButton(
                                                    onPressed: () =>
                                                        Navigator.of(
                                                                dialogContext)
                                                            .pop(true),
                                                    child: Text(
                                                      l.statementsReprocessAction,
                                                    ),
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
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(l.statementsReprocessAction),
                                ),
                                const SizedBox(width: 2),
                                PopupMenuButton<String>(
                                  tooltip: l.moreActions,
                                  icon: const Icon(Icons.more_vert, size: 16),
                                  constraints: const BoxConstraints(
                                    minWidth: 24,
                                    minHeight: 24,
                                  ),
                                  padding: EdgeInsets.zero,
                                  onSelected: (value) async {
                                    if (value == 'toggleTech') {
                                      onToggleTech(id);
                                      return;
                                    }
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
                                                  l.statementsDeleteAction,
                                                ),
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
                                      value: 'toggleTech',
                                      child: Text(
                                        showTech
                                            ? l.statementsHideTechDetails
                                            : l.statementsShowTechDetails,
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete_outline,
                                            color: cs.error,
                                          ),
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
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  deleteErr,
                                  style: t.bodySmall.copyWith(color: cs.error),
                                ),
                              ),
                            if (reprocessErr != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  reprocessErr,
                                  style: t.bodySmall.copyWith(color: cs.error),
                                ),
                              ),
                            if (showTech)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: cs.surfaceContainerHighest
                                        .withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      TechLine(
                                        label: l.statementsTechBatchId,
                                        value: id,
                                        onCopy: id.isEmpty
                                            ? null
                                            : () => onCopy(id),
                                      ),
                                      if (checksum != null &&
                                          checksum.isNotEmpty)
                                        TechLine(
                                          label: l.statementsTechChecksum,
                                          value: checksum,
                                          onCopy: () => onCopy(checksum),
                                        ),
                                      if (uploader != null &&
                                          uploader.isNotEmpty)
                                        TechLine(
                                          label: l.statementsTechUploader,
                                          value: uploader,
                                          onCopy: () => onCopy(uploader),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
