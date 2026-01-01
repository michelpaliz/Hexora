import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'statements/statements_controller.dart';
import 'statements/statements_formatters.dart';
import 'statements/statements_freshness_banner.dart';
import 'statements/statements_shared.dart';

enum _StepStatus { disabled, active, completed }

class StatementsTab extends StatefulWidget {
  const StatementsTab({super.key});

  @override
  State<StatementsTab> createState() => _StatementsTabState();
}

class _StatementsTabState extends State<StatementsTab>
    with AutomaticKeepAliveClientMixin {
  String? _statementFileName;
  List<int>? _statementFileBytes;
  String _statementsTabHint = '';
  String? _fileError;
  bool _confirmed = false;
  int _activeStep = 1;
  bool _collapseLeftPanel = false;

  @override
  bool get wantKeepAlive => true;

  Future<void> _pickStatementFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['xls', 'xlsx'],
    );
    final file = result?.files.single;
    if (!mounted) return;
    if (file == null) return;
    if (file.bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.statementsFileReadError),
        ),
      );
      return;
    }
    final maxBytes = 10 * 1024 * 1024;
    final tooLarge = file.bytes!.length > maxBytes;
    setState(() {
      _statementFileName = file.name;
      _statementFileBytes = file.bytes!;
      _fileError = tooLarge
          ? AppLocalizations.of(context)!.statementsFileTooLarge
          : null;
      _confirmed = false;
      _activeStep = 1;
    });
  }

  void _clearSelectedFile() {
    setState(() {
      _statementFileName = null;
      _statementFileBytes = null;
      _fileError = null;
      _confirmed = false;
      _activeStep = 1;
    });
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes} B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final s = context.watch<StatementsController>();
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final result = s.lastImportResult ?? const <String, dynamic>{};
    final batchId =
        (result['batchId'] ?? result['_id'] ?? result['id'])?.toString();
    final inserted = result['inserted'];
    final skipped = result['skippedDuplicates'];
    final sheet = result['sheet'];
    final checksum = result['checksum'];
    final preview = (result['entries'] is List)
        ? (result['entries'] as List).whereType<Map>().take(5).toList()
        : const <Map>[];
    final hasFile = _statementFileBytes != null;
    final hasResult = result.isNotEmpty;
    final canUpload = hasFile && _fileError == null && !s.uploading;
    final freshnessBatchId = (s.selectedBatchId?.isNotEmpty == true)
        ? s.selectedBatchId
        : (batchId?.isNotEmpty == true
            ? batchId
            : (s.imports.isNotEmpty
                ? (s.imports.first['batchId'] ??
                        s.imports.first['_id'] ??
                        s.imports.first['id'])
                    ?.toString()
                : null));

    if (!hasResult && _activeStep != 1) {
      _activeStep = 1;
    }

    final step1Status = hasResult ? _StepStatus.completed : _StepStatus.active;
    final step2Status = hasResult
        ? (_confirmed ? _StepStatus.completed : _StepStatus.active)
        : _StepStatus.disabled;
    final step3Status = hasResult
        ? (_confirmed ? _StepStatus.completed : _StepStatus.active)
        : _StepStatus.disabled;

    Widget buildUploadWorkspace() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _pickStatementFile,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cs.surfaceVariant.withOpacity(0.35),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _fileError != null ? cs.error : cs.outlineVariant,
                  width: 1.4,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.cloud_upload_outlined, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        l.statementsDragDropTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l.statementsDragDropHint,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l.statementsFormatsHint,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.attach_file),
                      onPressed: _pickStatementFile,
                      label: Text(l.statementsChooseFile),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_statementFileName != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  _fileError == null ? Icons.check_circle : Icons.error_outline,
                  color: _fileError == null ? cs.primary : cs.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l.statementsSelectedFile(_statementFileName!),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_statementFileBytes != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    _formatBytes(_statementFileBytes!.length),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _clearSelectedFile,
                  child: Text(l.statementsRemoveFile),
                ),
              ],
            ),
            if (_fileError != null) ...[
              const SizedBox(height: 6),
              Text(_fileError!, style: TextStyle(color: cs.error)),
            ],
          ],
          const SizedBox(height: 16),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: canUpload ? 1 : 0.6,
            child: FilledButton(
              onPressed: !canUpload
                  ? null
                  : () async {
                      final res = await s.importStatement(
                        bytes: _statementFileBytes!,
                        filename: _statementFileName ?? 'statement.xlsx',
                      );
                      if (res != null) {
                        await s.listImports();
                      }
                      if (!mounted) return;
                      setState(() {
                        _confirmed = false;
                        _activeStep = res == null ? 1 : 2;
                        _statementsTabHint = res == null
                            ? l.statementsUploadFailed
                            : l.statementsUploadComplete;
                      });
                    },
              child: s.uploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l.statementsUploadParse),
            ),
          ),
          if (s.uploading) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(),
          ],
          if (s.uploadError != null) ...[
            const SizedBox(height: 8),
            Text(
              s.uploadError == 'duplicate_file'
                  ? l.statementsDuplicateFileError
                  : s.uploadError!,
              style: TextStyle(color: cs.error),
            ),
          ],
          if (_statementsTabHint.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _statementsTabHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      );
    }

    Widget buildReviewWorkspace() {
      if (!hasResult) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.statementsReviewDisabled,
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: cs.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(child: Icon(Icons.table_chart_outlined)),
            ),
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.statementsResultsHelp,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              if (batchId != null && batchId.isNotEmpty)
                Chip(label: Text(l.statementsBatchLabel(batchId))),
              if (sheet != null)
                Chip(label: Text(l.statementsSheetLabel(sheet.toString()))),
              if (checksum != null)
                Chip(
                    label:
                        Text(l.statementsChecksumLabel(checksum.toString()))),
              if (inserted != null)
                Chip(
                    label:
                        Text(l.statementsInsertedLabel(inserted.toString()))),
              if (skipped != null)
                Chip(label: Text(l.statementsSkippedLabel(skipped.toString()))),
            ],
          ),
          if (skipped != null) ...[
            const SizedBox(height: 8),
            Text(
              l.statementsDuplicateSummary(skipped.toString()),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (preview.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              l.statementsPreviewTitle(preview.length),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ...preview.map((entry) {
              final e = Map<String, dynamic>.from(entry);
              final date = StatementsShared.entryText(e, ['date', 'valueDate']);
              final desc =
                  StatementsShared.entryText(e, ['description', 'details']);
              final amount = StatementsShared.entryText(e, ['amount']);
              return ListTile(
                dense: true,
                title: Text(desc.isEmpty ? l.statementsNoDescription : desc),
                subtitle: Text(
                  [
                    if (date.isNotEmpty)
                      StatementsFormatters.formatDate(context, date),
                    if (amount.isNotEmpty)
                      l.statementsAmountLabel(
                        StatementsFormatters.formatAmount(context, amount),
                      ),
                  ].where((v) => v.isNotEmpty).join(' • '),
                ),
              );
            }),
          ],
        ],
      );
    }

    Widget buildConfirmWorkspace() {
      final canConfirm = hasResult && !_confirmed;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasResult ? l.statementsConfirmHelp : l.statementsConfirmDisabled,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          if (hasResult) ...[
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (batchId != null && batchId.isNotEmpty)
                  Chip(label: Text(l.statementsBatchLabel(batchId))),
                if (checksum != null)
                  Chip(
                      label:
                          Text(l.statementsChecksumLabel(checksum.toString()))),
                if (inserted != null)
                  Chip(
                      label:
                          Text(l.statementsInsertedLabel(inserted.toString()))),
                if (skipped != null)
                  Chip(
                      label:
                          Text(l.statementsSkippedLabel(skipped.toString()))),
              ],
            ),
            const SizedBox(height: 12),
          ],
          FilledButton(
            onPressed: canConfirm
                ? () {
                    setState(() {
                      _confirmed = true;
                      _activeStep = 3;
                    });
                  }
                : null,
            child: Text(l.statementsConfirmAction),
          ),
          if (_confirmed) ...[
            const SizedBox(height: 8),
            Text(
              l.statementsConfirmSuccess,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      );
    }

    Widget buildLeftPanel(int step) {
      final title = step == 1
          ? l.statementsStepContextUploadTitle
          : (step == 2
              ? l.statementsStepContextReviewTitle
              : l.statementsStepContextConfirmTitle);

      final summaryRows = <Widget>[];
      if (step == 2 && hasResult) {
        summaryRows.addAll([
          _SummaryLine(
            label: l.statementsInsertedLabel(''),
            value: inserted?.toString() ?? '-',
          ),
          _SummaryLine(
            label: l.statementsSkippedLabel(''),
            value: skipped?.toString() ?? '-',
          ),
        ]);
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (step == 1) ...[
            Text(l.statementsUploadDescription,
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Text(l.statementsFormatsHint,
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Text(l.statementsSecurityNote,
                style: Theme.of(context).textTheme.bodySmall),
          ] else if (step == 2) ...[
            Text(l.statementsResultsHelp,
                style: Theme.of(context).textTheme.bodySmall),
            if (summaryRows.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(l.statementsImportSummaryTitle,
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              ...summaryRows,
            ],
          ] else ...[
            Text(l.statementsConfirmHelp,
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            Text(l.statementsConfirmChecklistTitle,
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            _ChecklistItem(text: l.statementsConfirmChecklistItem1),
            _ChecklistItem(text: l.statementsConfirmChecklistItem2),
            const SizedBox(height: 8),
            Text(l.statementsSecurityNote,
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      );
    }

    Widget buildRightPanel(int step) {
      final child = step == 1
          ? buildUploadWorkspace()
          : (step == 2 ? buildReviewWorkspace() : buildConfirmWorkspace());
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, animation) {
          final offset = Tween<Offset>(
            begin: const Offset(0.08, 0),
            end: Offset.zero,
          ).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: offset, child: child),
          );
        },
        child: KeyedSubtree(key: ValueKey(step), child: child),
      );
    }

    Widget buildStepRail() {
      return Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _StepRailItem(
                  index: 1,
                  label: l.statementsStepUpload,
                  status: step1Status,
                  active: _activeStep == 1,
                  onTap: step1Status == _StepStatus.disabled
                      ? null
                      : () => setState(() => _activeStep = 1),
                ),
                _StepRailItem(
                  index: 2,
                  label: l.statementsStepReview,
                  status: step2Status,
                  active: _activeStep == 2,
                  onTap: step2Status == _StepStatus.disabled
                      ? null
                      : () => setState(() => _activeStep = 2),
                ),
                _StepRailItem(
                  index: 3,
                  label: l.statementsStepConfirm,
                  status: step3Status,
                  active: _activeStep == 3,
                  onTap: step3Status == _StepStatus.disabled
                      ? null
                      : () => setState(() => _activeStep = 3),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: _collapseLeftPanel
                ? l.statementsPanelExpand
                : l.statementsPanelCollapse,
            onPressed: () => setState(() => _collapseLeftPanel = !_collapseLeftPanel),
            icon: Icon(_collapseLeftPanel
                ? Icons.chevron_right
                : Icons.chevron_left),
          ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 720;
        final isTablet = !isMobile && constraints.maxWidth < 1024;
        final leftCollapsed = isMobile ? false : (isTablet ? _collapseLeftPanel : false);

        if (isMobile) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (freshnessBatchId != null) ...[
                StatementsFreshnessBanner(
                  controller: s,
                  batchId: freshnessBatchId,
                ),
                const SizedBox(height: 12),
              ],
              buildStepRail(),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.surfaceVariant.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: buildLeftPanel(_activeStep),
              ),
              const SizedBox(height: 16),
              buildRightPanel(_activeStep),
            ],
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (freshnessBatchId != null) ...[
              StatementsFreshnessBanner(
                controller: s,
                batchId: freshnessBatchId,
              ),
              const SizedBox(height: 12),
            ],
            buildStepRail(),
            const SizedBox(height: 16),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!leftCollapsed)
                    SizedBox(
                      width: constraints.maxWidth * (isTablet ? 0.3 : 0.28),
                      child: Card(
                        color: cs.surfaceVariant.withOpacity(0.18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: KeyedSubtree(
                              key: ValueKey(_activeStep),
                              child: buildLeftPanel(_activeStep),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (!leftCollapsed) const SizedBox(width: 16),
                  Expanded(
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            buildRightPanel(_activeStep),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StepRailItem extends StatelessWidget {
  const _StepRailItem({
    required this.index,
    required this.label,
    required this.status,
    required this.active,
    required this.onTap,
  });

  final int index;
  final String label;
  final _StepStatus status;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isCompleted = status == _StepStatus.completed;
    final isDisabled = status == _StepStatus.disabled;
    final bg = active ? cs.primaryContainer : cs.surface;
    final border = active ? cs.primary : cs.outlineVariant;
    final fg = isDisabled ? cs.onSurfaceVariant : cs.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StepBadge(index: index, status: status),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: fg, fontWeight: FontWeight.w700),
            ),
            if (isCompleted) ...[
              const SizedBox(width: 6),
              Icon(Icons.check_circle, size: 16, color: cs.primary),
            ],
          ],
        ),
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge({required this.index, required this.status});

  final int index;
  final _StepStatus status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isActive = status == _StepStatus.active;
    final isCompleted = status == _StepStatus.completed;
    final bg = isCompleted
        ? cs.primary
        : (isActive ? cs.primaryContainer : cs.surfaceVariant);
    final fg = isCompleted
        ? cs.onPrimary
        : (isActive ? cs.onPrimaryContainer : cs.onSurfaceVariant);

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: cs.outlineVariant),
      ),
      alignment: Alignment.center,
      child: isCompleted
          ? Icon(Icons.check, size: 16, color: fg)
          : Text(
              index.toString(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
                  ),
            ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.replaceAll(':', ''),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  const _ChecklistItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
