// Preserved from the original import-tabs part; workflow logic is unchanged.
// ignore_for_file: dead_code

part of '../../expense_upload_screen.dart';

extension _ExpenseBatchImportTab on _ExpenseUploadImportTabsSection {
  Widget _buildBatchImportTab(AppLocalizations l,
      {bool showInlineControls = true}) {
    {
      final cs = Theme.of(context).colorScheme;
      final hasGroup = resolveGroupId().trim().isNotEmpty;
      final selectedCount = batchDocumentNames.length;
      const maxBatchDocs = _ExpenseUploadScreenStateBase._maxBatchDocuments;
      final jobStatusName = _expenseBatchJobStatusFromPayload(_batchJobStatus);
      final hasTrackedJob = (_batchJobId ?? '').trim().isNotEmpty;
      final jobActive =
          hasTrackedJob && !_isExpenseBatchJobTerminal(jobStatusName);
      final jobCompleted = jobStatusName == 'completed';
      final jobFailed = jobStatusName == 'failed';
      final jobTotalFiles = _batchJobInt(_batchJobStatus?['totalFiles']);
      final jobProcessedFiles =
          _batchJobInt(_batchJobStatus?['processedFiles']);
      final jobImportedCount = _batchJobInt(_batchJobStatus?['readyCount']);
      final jobSkippedCount = _batchJobInt(_batchJobStatus?['warningCount']) +
          _batchJobInt(_batchJobStatus?['duplicateCount']) +
          _batchJobInt(_batchJobStatus?['failedCount']);
      final hasPreviewItems = _batchPreviewItems.isNotEmpty;
      final selectedPreviewCount =
          _batchPreviewItems.where((item) => item.selected).length;
      final useCompletedPreviewFocus = jobCompleted && hasPreviewItems;
      final hasIncidentExport = hasTrackedJob &&
          _hasIncidentItems(
            _batchPreviewItems,
            skippedCount: jobSkippedCount,
            duplicateCount: _batchJobInt(_batchJobStatus?['duplicateCount']) +
                _batchJobInt(_batchConfirmResult?['duplicateCount']),
            failedCount: _batchJobInt(_batchJobStatus?['failedCount']),
            warningCount: _batchJobInt(_batchJobStatus?['warningCount']) +
                _batchJobInt(_batchConfirmResult?['skippedCount']),
          );
      final headerLoadedCount =
          hasTrackedJob && jobTotalFiles > 0 ? jobTotalFiles : selectedCount;
      final remainingSlots =
          (maxBatchDocs - headerLoadedCount).clamp(0, maxBatchDocs);
      final totalBytes = batchDocumentBytes.fold<int>(
        0,
        (sum, bytes) => sum + bytes.length,
      );
      final backendProgress = _batchJobDouble(_batchJobStatus?['progress']);
      final uploadRatio = hasTrackedJob
          ? (backendProgress > 0
              ? backendProgress.clamp(0.0, 1.0).toDouble()
              : (jobTotalFiles > 0
                  ? (jobProcessedFiles / jobTotalFiles)
                      .clamp(0.0, 1.0)
                      .toDouble()
                  : 0.0))
          : (maxBatchDocs == 0
              ? 0.0
              : (selectedCount / maxBatchDocs).clamp(0.0, 1.0).toDouble());
      final verifyText = hasTrackedJob
          ? _expenseBatchJobUiMessage(_batchJobStatus)
          : batchVerifyMessage ?? l.expenseUploadBatchWaiting;
      final verifyLower = verifyText.toLowerCase();
      final verifyLooksOk = jobCompleted ||
          (verifyLower.contains('verific') && verifyLower.contains('ok'));
      final verifyHasIssue = jobFailed ||
          verifyLower.contains('no ') ||
          verifyLower.contains('error') ||
          verifyLower.contains('invalid');

      final uploadedFileNames = recentUploads
          .map((e) => (e['file'] ?? '').toLowerCase().trim())
          .where((n) => n.isNotEmpty)
          .toSet();
      final selectionNameCounts = <String, int>{};
      for (final raw in batchDocumentNames) {
        final key = raw.toLowerCase().trim();
        if (key.isEmpty) continue;
        selectionNameCounts[key] = (selectionNameCounts[key] ?? 0) + 1;
      }
      final warningKeys = <String>{
        ...selectionNameCounts.entries
            .where((entry) => entry.value > 1)
            .map((entry) => entry.key),
        ...uploadedFileNames.where(selectionNameCounts.containsKey),
      };
      final resultIssueMap = <String, String>{
        ..._expenseBatchFileIssueMapFromPayload(_batchJobStatus),
        ..._expenseBatchFileIssueMapFromPayload(_batchJobResult),
      };

      final files = <_BatchExecutionFile>[
        for (var index = 0; index < batchDocumentNames.length; index++)
          _BatchExecutionFile(
            originalIndex: index,
            name: batchDocumentNames[index],
            sizeBytes: index < batchDocumentBytes.length
                ? batchDocumentBytes[index].length
                : 0,
            status: (() {
              final key = batchDocumentNames[index].toLowerCase().trim();
              if (resultIssueMap.containsKey(key)) {
                return _BatchExecutionFileStatus.error;
              }
              if (warningKeys.contains(key)) {
                return _BatchExecutionFileStatus.warning;
              }
              return _BatchExecutionFileStatus.success;
            })(),
            detail: (() {
              final key = batchDocumentNames[index].toLowerCase().trim();
              final jobIssue = resultIssueMap[key];
              if (jobIssue != null && jobIssue.isNotEmpty) {
                return jobIssue;
              }
              if (uploadedFileNames.contains(key)) {
                return 'Ya existe en gastos recientes';
              }
              if ((selectionNameCounts[key] ?? 0) > 1) {
                return 'Nombre duplicado en la seleccion';
              }
              if (jobCompleted) {
                return 'Procesado correctamente';
              }
              if (jobActive) {
                return 'En cola para importar';
              }
              if (jobFailed) {
                return 'Listo para reintentar';
              }
              return 'Listo para importar';
            })(),
          ),
      ];
      final warningIndexes = files
          .where((file) => file.status == _BatchExecutionFileStatus.warning)
          .map((file) => file.originalIndex)
          .toSet();
      final filteredFiles = files.where((file) {
        switch (_batchFileFilterIndex) {
          case 1:
            return file.status == _BatchExecutionFileStatus.success;
          case 2:
            return file.status != _BatchExecutionFileStatus.success;
          default:
            return true;
        }
      }).toList(growable: false);

      final copyIssuesText = [
        'Archivos con incidencia',
        if ((batchError ?? '').trim().isNotEmpty)
          'Error: ${batchError!.trim()}',
        '',
        ...batchSkippedDetails.map((detail) => '- $detail'),
      ].join('\n');

      Widget executionPanel = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BatchCollapsibleSummary(
            collapsed: _batchSummaryCollapsed,
            onToggle: () => _updateImportState(() {
              _batchSummaryCollapsed = !_batchSummaryCollapsed;
            }),
            loadedCount: headerLoadedCount,
            maxCount: maxBatchDocs,
            totalBytes: totalBytes,
            remainingSlots: remainingSlots,
            uploadRatio: uploadRatio,
            status: jobStatusName,
            hasTrackedJob: hasTrackedJob,
            totalFiles: jobTotalFiles > 0 ? jobTotalFiles : headerLoadedCount,
            processedFiles: jobProcessedFiles,
            importedCount: jobImportedCount,
            skippedCount: jobSkippedCount,
            reviewCount: _batchJobInt(_batchJobStatus?['warningCount']) +
                _batchJobInt(_batchJobStatus?['failedCount']),
            duplicateCount: _batchJobInt(_batchJobStatus?['duplicateCount']),
            currentStep: _batchJobText(_batchJobStatus?['currentStep']),
            message: _batchJobText(_batchJobStatus?['message']),
            loadingResult: _batchResultLoading,
            warningDetails: batchSkippedDetails,
            warningsExpanded: _batchErrorsExpanded,
            onToggleWarnings: () => _updateImportState(() {
              _batchErrorsExpanded = !_batchErrorsExpanded;
            }),
            onCopyWarnings: batchSkippedDetails.isEmpty
                ? null
                : () => copyTextWithManualFallbackDialog(
                      context,
                      text: copyIssuesText,
                      successMessage: 'Lista copiada',
                      dialogTitle: 'Copiar incidencias manualmente',
                      dialogMessage:
                          'Tu navegador bloqueo la copia automatica. Selecciona la lista y copiala manualmente.',
                    ),
          ),
          if ((batchError ?? '').trim().isNotEmpty &&
              batchSkippedDetails.isEmpty) ...[
            const SizedBox(height: 6),
            _BatchStateBanner(
              icon: Icons.info_outline,
              message: batchError!.trim(),
              color: cs.error,
              backgroundColor: cs.errorContainer.withValues(alpha: 0.22),
              borderColor: cs.error.withValues(alpha: 0.32),
              textColor: cs.onErrorContainer,
            ),
          ],
          const SizedBox(height: 6),
          Expanded(
            child: useCompletedPreviewFocus
                ? _BatchExpensePreviewReviewPanel(
                    items: _batchPreviewItems,
                    selectedCount: selectedPreviewCount,
                    confirming: batchSubmitting,
                    confirmResult: _batchConfirmResult,
                    canExportIncidents: hasIncidentExport,
                    exportingIncidents: _batchExportingIncidents,
                    onExportIncidents: exportBatchIncidentExcel,
                    onToggle: (item, selected) => _updateImportState(() {
                      if (!item.canSelect) return;
                      item.selected = selected;
                    }),
                    onEdit: (item) => _showBatchPreviewEditDialog(item),
                    onConfirm: confirmBatchPreviewImport,
                  )
                : hasPreviewItems
                    ? DefaultTabController(
                        length: 3,
                        initialIndex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _BatchReviewTabHeader(
                              fileCount: files.length,
                              selectedCount: selectedPreviewCount,
                              hasIssue: verifyHasIssue,
                              looksOk: verifyLooksOk,
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: TabBarView(
                                children: [
                                  _buildBatchFileListView(
                                    filteredFiles: filteredFiles,
                                    totalCount: files.length,
                                    warningCount: warningIndexes.length,
                                    warningIndexes: warningIndexes,
                                    selectedCount: selectedCount,
                                    hasTrackedJob: hasTrackedJob,
                                    jobActive: jobActive,
                                  ),
                                  _BatchExpensePreviewReviewPanel(
                                    items: _batchPreviewItems,
                                    selectedCount: selectedPreviewCount,
                                    confirming: batchSubmitting,
                                    confirmResult: _batchConfirmResult,
                                    canExportIncidents: hasIncidentExport,
                                    exportingIncidents:
                                        _batchExportingIncidents,
                                    onExportIncidents: exportBatchIncidentExcel,
                                    onToggle: (item, selected) =>
                                        _updateImportState(() {
                                      if (!item.canSelect) return;
                                      item.selected = selected;
                                    }),
                                    onEdit: (item) =>
                                        _showBatchPreviewEditDialog(item),
                                    onConfirm: confirmBatchPreviewImport,
                                  ),
                                  _BatchVerificationTabPanel(
                                    title:
                                        l.expenseUploadBatchVerificationTitle,
                                    message: verifyText,
                                    hasIssue: verifyHasIssue,
                                    looksOk: verifyLooksOk,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : _buildBatchFileListView(
                        filteredFiles: filteredFiles,
                        totalCount: files.length,
                        warningCount: warningIndexes.length,
                        warningIndexes: warningIndexes,
                        selectedCount: selectedCount,
                        hasTrackedJob: hasTrackedJob,
                        jobActive: jobActive,
                      ),
          ),
          if (!hasGroup) ...[
            const SizedBox(height: 10),
            Text(
              l.expenseUploadBatchGroupRequired,
              style: TextStyle(color: cs.error, fontSize: 12),
            ),
          ],
        ],
      );

      if (!showInlineControls) {
        return executionPanel;
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BatchLeftControlPanel(
            selectedCount: headerLoadedCount,
            maxDocuments: maxBatchDocs,
            totalBytes: totalBytes,
            submitting: batchSubmitting ||
                batchGeneratingJson ||
                jobActive ||
                _batchStartingJob,
            hasGroupSelected: hasGroup,
            canImport: !jobActive &&
                !batchSubmitting &&
                !batchGeneratingJson &&
                !jobCompleted &&
                !hasPreviewItems &&
                hasGroup &&
                batchDocumentNames.isNotEmpty,
            jobActive: jobActive,
            jobCompleted: jobCompleted,
            jobFailed: jobFailed,
            statusMessage: hasTrackedJob ? verifyText : null,
            warningCount: warningIndexes.length,
            importedCount: jobImportedCount,
            skippedCount: jobSkippedCount,
            onPickDocuments: pickBatchDocuments,
            onImport: submitBatchImport,
            onClearSelection: batchDocumentNames.isEmpty
                ? null
                : () => _updateImportState(() {
                      _resetBatchJobTracking(
                        clearResult: true,
                        clearCache: true,
                      );
                      batchDocumentBytes.clear();
                      batchDocumentNames.clear();
                      _batchSkippedDetails.clear();
                      _batchVerifyMessage = null;
                      _batchError = null;
                      _batchDetectedInvoices = 0;
                      _batchFileFilterIndex = 0;
                    }),
          ),
          const SizedBox(height: 16),
          Expanded(child: executionPanel),
        ],
      );
    }
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;
    final hasGroup = resolveGroupId().trim().isNotEmpty;
    final selectedCount = batchDocumentNames.length;
    const maxBatchDocs = _ExpenseUploadScreenStateBase._maxBatchDocuments;
    final remainingSlots =
        (maxBatchDocs - selectedCount).clamp(0, maxBatchDocs);
    final totalBytes = batchDocumentBytes.fold<int>(
      0,
      (sum, bytes) => sum + bytes.length,
    );
    final totalSizeMb = (totalBytes / (1024 * 1024)).toStringAsFixed(2);
    final uploadRatio = maxBatchDocs == 0 ? 0.0 : selectedCount / maxBatchDocs;
    final verifyText = batchVerifyMessage ?? l.expenseUploadBatchWaiting;
    final verifyLower = verifyText.toLowerCase();
    final verifyLooksOk =
        verifyLower.contains('verific') && verifyLower.contains('ok');
    final verifyHasIssue = verifyLower.contains('no ') ||
        verifyLower.contains('error') ||
        verifyLower.contains('invalid');
    final showInlineUploader = MediaQuery.of(context).size.width < 920;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.layers_outlined, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                'Batch import',
                style: ts.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l.expenseUploadBatchFlow,
            style: ts.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          if (showInlineUploader) ...[
            _CompactOutlinedButton(
              onPressed: (batchSubmitting || batchGeneratingJson)
                  ? null
                  : pickBatchDocuments,
              icon: Icons.picture_as_pdf_outlined,
              label: l.expenseUploadBatchUploadDocsCta,
            ),
            const SizedBox(height: 6),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  selectedCount == 0
                      ? l.expenseUploadBatchLimits
                      : l.expenseUploadBatchSelectedCount(selectedCount),
                  style: ts.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
              if (selectedCount > 0)
                Text(
                  '${(uploadRatio * 100).toStringAsFixed(0)}%',
                  style: ts.bodySmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: uploadRatio.clamp(0, 1),
              backgroundColor: cs.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resumen de carga',
                  style: ts.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final tileWidth = constraints.maxWidth >= 660
                        ? (constraints.maxWidth - 8) / 2
                        : constraints.maxWidth;
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MetricTile(
                          width: tileWidth,
                          icon: Icons.insert_drive_file_outlined,
                          label: 'Archivos cargados',
                          value: '$selectedCount / $maxBatchDocs',
                          valueColor: selectedCount > 0 ? cs.primary : null,
                        ),
                        _MetricTile(
                          width: tileWidth,
                          icon: Icons.space_dashboard_outlined,
                          label: 'Espacios disponibles',
                          value: '$remainingSlots',
                          valueColor: remainingSlots == 0
                              ? cs.error
                              : remainingSlots < 20
                                  ? Colors.amber.shade700
                                  : null,
                        ),
                        _MetricTile(
                          width: tileWidth,
                          icon: Icons.data_usage_outlined,
                          label: 'TamaÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â±o total',
                          value: '$totalSizeMb MB',
                        ),
                        _MetricTile(
                          width: tileWidth,
                          icon: Icons.receipt_long_outlined,
                          label: 'Facturas detectadas en JSON',
                          value: batchDetectedInvoices > 0
                              ? '$batchDetectedInvoices'
                              : 'ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â',
                          valueColor:
                              batchDetectedInvoices > 0 ? cs.primary : null,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          if (batchDocumentNames.isNotEmpty) ...[
            const SizedBox(height: 8),
            _BatchDocumentList(
              names: batchDocumentNames,
              bytes: batchDocumentBytes,
              uploadedFileNames: recentUploads
                  .map((e) => (e['file'] ?? '').toLowerCase().trim())
                  .where((n) => n.isNotEmpty)
                  .toSet(),
              disabled: batchSubmitting || batchGeneratingJson,
              onRemoveAt: (i) => _updateImportState(() {
                batchDocumentBytes.removeAt(i);
                batchDocumentNames.removeAt(i);
              }),
              onClearAll: () => _updateImportState(() {
                batchDocumentBytes.clear();
                batchDocumentNames.clear();
              }),
            ),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: verifyHasIssue
                    ? cs.error.withValues(alpha: 0.5)
                    : cs.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  verifyHasIssue
                      ? Icons.error_outline
                      : (verifyLooksOk
                          ? Icons.check_circle_outline
                          : Icons.hourglass_bottom),
                  size: 16,
                  color: verifyHasIssue
                      ? cs.error
                      : (verifyLooksOk ? cs.primary : cs.onSurfaceVariant),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.expenseUploadBatchVerificationTitle,
                        style:
                            ts.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        verifyText,
                        style:
                            ts.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l.expenseUploadBatchImportTitle,
            style: ts.bodySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          if (!hasGroup)
            Text(
              l.expenseUploadBatchGroupRequired,
              style: TextStyle(color: cs.error, fontSize: 12),
            ),
          if ((batchError ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: cs.errorContainer.withValues(alpha: 0.25),
                border: Border.all(
                  color: cs.error.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      size: 14, color: cs.error.withValues(alpha: 0.8)),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      batchError!,
                      style: ts.bodySmall?.copyWith(
                        color: cs.onErrorContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (batchSkippedDetails.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.amber.withValues(alpha: 0.06),
                border: Border.all(
                  color: Colors.amber.withValues(alpha: 0.38),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ Header ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            size: 14, color: Colors.amber.shade600),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${batchSkippedDetails.length} archivos con incidencia',
                            style: ts.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.amber.shade200,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Copiar lista',
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints:
                              const BoxConstraints(minWidth: 28, minHeight: 28),
                          icon: Icon(Icons.copy_all_outlined,
                              size: 15,
                              color:
                                  cs.onSurfaceVariant.withValues(alpha: 0.7)),
                          onPressed: () => copyTextWithManualFallbackDialog(
                            context,
                            text: [
                              'Archivos con incidencia',
                              if ((batchError ?? '').trim().isNotEmpty)
                                'Error: ${batchError!.trim()}',
                              '',
                              ...batchSkippedDetails.map(
                                  (d) => 'ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¢ $d'),
                            ].join('\n'),
                            successMessage: 'Lista copiada',
                            dialogTitle: 'Copiar incidencias manualmente',
                            dialogMessage:
                                'Tu navegador bloqueÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â³ la copia automÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¡tica. Selecciona la lista y cÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â³piala manualmente.',
                          ),
                        ),
                        if (batchSkippedDetails.length > 6)
                          IconButton(
                            tooltip:
                                'Ver todos (${batchSkippedDetails.length})',
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 28, minHeight: 28),
                            icon: Icon(Icons.open_in_new,
                                size: 15,
                                color:
                                    cs.onSurfaceVariant.withValues(alpha: 0.7)),
                            onPressed: () => showSafeDialogOnActiveView<void>(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded,
                                        size: 18, color: Colors.amber.shade600),
                                    const SizedBox(width: 8),
                                    Text(
                                        '${batchSkippedDetails.length} archivos con incidencia'),
                                  ],
                                ),
                                content: SizedBox(
                                  width: 720,
                                  child: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxHeight: 420),
                                    child: Scrollbar(
                                      thumbVisibility: true,
                                      child: ListView.separated(
                                        shrinkWrap: true,
                                        itemCount: batchSkippedDetails.length,
                                        separatorBuilder: (_, __) => Divider(
                                          height: 1,
                                          color: cs.outlineVariant
                                              .withValues(alpha: 0.25),
                                        ),
                                        itemBuilder: (context, index) =>
                                            _SkippedFileRow(
                                          detail: batchSkippedDetails[index],
                                          cs: cs,
                                          ts: ts,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(dialogContext).pop(),
                                    child: const Text('Cerrar'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: Colors.amber.withValues(alpha: 0.25),
                  ),
                  // ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ Scrollable list ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 210),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ...batchSkippedDetails.take(6).map(
                                (detail) => _SkippedFileRow(
                                  detail: detail,
                                  cs: cs,
                                  ts: ts,
                                ),
                              ),
                          if (batchSkippedDetails.length > 6)
                            TextButton.icon(
                              onPressed: () => showSafeDialogOnActiveView<void>(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: Row(
                                    children: [
                                      Icon(Icons.warning_amber_rounded,
                                          size: 18,
                                          color: Colors.amber.shade600),
                                      const SizedBox(width: 8),
                                      Text(
                                          '${batchSkippedDetails.length} archivos con incidencia'),
                                    ],
                                  ),
                                  content: SizedBox(
                                    width: 720,
                                    child: ConstrainedBox(
                                      constraints:
                                          const BoxConstraints(maxHeight: 420),
                                      child: Scrollbar(
                                        thumbVisibility: true,
                                        child: ListView.separated(
                                          shrinkWrap: true,
                                          itemCount: batchSkippedDetails.length,
                                          separatorBuilder: (_, __) => Divider(
                                            height: 1,
                                            color: cs.outlineVariant
                                                .withValues(alpha: 0.25),
                                          ),
                                          itemBuilder: (context, index) =>
                                              _SkippedFileRow(
                                            detail: batchSkippedDetails[index],
                                            cs: cs,
                                            ts: ts,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(dialogContext).pop(),
                                      child: const Text('Cerrar'),
                                    ),
                                  ],
                                ),
                              ),
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                foregroundColor: cs.onSurfaceVariant,
                                textStyle: const TextStyle(fontSize: 11),
                              ),
                              icon: const Icon(Icons.visibility_outlined,
                                  size: 13),
                              label: Text(
                                'Ver ${batchSkippedDetails.length - 6} mÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¡s',
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: (batchSubmitting || batchGeneratingJson || !hasGroup)
                ? null
                : submitBatchImport,
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              textStyle: const TextStyle(fontSize: 13),
            ),
            icon: batchSubmitting
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.playlist_add_check_circle_outlined,
                    size: 18),
            label: Text(l.expenseUploadBatchImportCta),
          ),
        ],
      ),
    );
  }
}
