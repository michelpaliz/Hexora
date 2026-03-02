part of '../../expense_upload_screen.dart';

mixin ExpenseUploadImportTabsSection on _ExpenseUploadScreenStateBase {
  BuildContext get context;
  String? get batchVerifyMessage;
  bool get jsonSubmitting;
  bool get jsonPromptLoading;
  String? get jsonPromptMessage;
  String? get jsonPromptText;
  String? get jsonFileName;
  String? get jsonInvoiceFileName;
  String? get selectedFileName;
  TextEditingController get jsonPayloadController;
  bool get jsonAdvancedExpanded;
  set jsonAdvancedExpanded(bool value);
  TextEditingController get jsonProviderIdOverrideController;
  TextEditingController get jsonGroupIdOverrideController;
  TextEditingController get jsonStatementEntryController;
  TextEditingController get jsonClientController;
  String? get jsonError;
  bool get batchSubmitting;
  bool get batchGeneratingJson;
  TextEditingController get batchJsonController;
  int get batchDetectedInvoices;
  set batchDetectedInvoices(int value);
  List<Uint8List> get batchDocumentBytes;
  List<String> get batchDocumentNames;
  String? get batchError;
  Future<void> pickJsonPayloadFile();
  Future<void> pickJsonInvoiceFile();
  Future<void> fetchExpenseJsonPrompt();
  Future<void> copyPromptToClipboard();
  Future<void> submitExpenseJsonImport();
  Future<void> pickBatchJsonFile();
  Future<void> pickBatchDocuments();
  Future<void> generateBatchJsonWithAi();
  Future<void> submitBatchImport();
  List<Map<String, dynamic>> extractBatchInvoices(Map<String, dynamic> payload);
  String resolveGroupId();

  @override
  Widget _buildJsonImportTab(AppLocalizations l) {
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Flujo simple: pega JSON + sube la factura.',
            style: ts.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _CompactOutlinedButton(
                onPressed: jsonSubmitting ? null : pickJsonPayloadFile,
                icon: Icons.upload_file_outlined,
                label: 'JSON file',
              ),
              _CompactOutlinedButton(
                onPressed: jsonSubmitting ? null : pickJsonInvoiceFile,
                icon: Icons.picture_as_pdf_outlined,
                label: 'Invoice file',
              ),
              _CompactOutlinedButton(
                onPressed: jsonPromptLoading ? null : fetchExpenseJsonPrompt,
                icon: Icons.content_copy_outlined,
                label: 'Get AI Prompt',
              ),
            ],
          ),
          if ((jsonPromptMessage ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(jsonPromptMessage!, style: ts.bodySmall),
          ],
          if ((jsonPromptText ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              constraints: const BoxConstraints(maxHeight: 140),
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.4),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  jsonPromptText!,
                  style: ts.bodySmall?.copyWith(fontSize: 11),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: _CompactOutlinedButton(
                onPressed: copyPromptToClipboard,
                icon: Icons.copy_outlined,
                label: 'Copy Prompt',
              ),
            ),
          ],
          if (jsonPromptLoading) ...[
            const SizedBox(height: 6),
            const LinearProgressIndicator(minHeight: 2),
          ],
          if ((jsonFileName ?? '').isNotEmpty ||
              (jsonInvoiceFileName ?? '').isNotEmpty ||
              (selectedFileName ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              [
                if ((jsonFileName ?? '').isNotEmpty) 'JSON: $jsonFileName',
                if ((jsonInvoiceFileName ?? '').isNotEmpty)
                  'Invoice: $jsonInvoiceFileName'
                else if ((selectedFileName ?? '').isNotEmpty)
                  'Invoice: $selectedFileName',
              ].join(' · '),
              style: ts.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
          const SizedBox(height: 8),
          TextField(
            controller: jsonPayloadController,
            enabled: !jsonSubmitting,
            minLines: 6,
            maxLines: 10,
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            decoration: const InputDecoration(
              labelText: 'JSON payload',
              hintText: 'Paste JSON payload',
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            ),
          ),
          const SizedBox(height: 6),
          ExpansionTile(
            initiallyExpanded: jsonAdvancedExpanded,
            onExpansionChanged: (v) => setState(() => jsonAdvancedExpanded = v),
            title: Text(
              'Advanced options',
              style: ts.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            dense: true,
            visualDensity: VisualDensity.compact,
            tilePadding: const EdgeInsets.symmetric(horizontal: 4),
            childrenPadding:
                const EdgeInsets.only(bottom: 6, left: 4, right: 4),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _AdvancedField(
                    width: 220,
                    controller: jsonProviderIdOverrideController,
                    enabled: !jsonSubmitting,
                    label: 'providerId override',
                  ),
                  _AdvancedField(
                    width: 190,
                    controller: jsonGroupIdOverrideController,
                    enabled: !jsonSubmitting,
                    label: 'groupId override',
                  ),
                  _AdvancedField(
                    width: 190,
                    controller: jsonStatementEntryController,
                    enabled: !jsonSubmitting,
                    label: 'statementEntryId',
                  ),
                  _AdvancedField(
                    width: 190,
                    controller: jsonClientController,
                    enabled: !jsonSubmitting,
                    label: 'clientId',
                  ),
                ],
              ),
            ],
          ),
          if ((jsonError ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              jsonError!,
              style: TextStyle(color: cs.error, fontSize: 12),
            ),
          ],
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: (jsonSubmitting || resolveGroupId().trim().isEmpty)
                ? null
                : submitExpenseJsonImport,
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              textStyle: const TextStyle(fontSize: 13),
            ),
            icon: jsonSubmitting
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.playlist_add_check_circle_outlined,
                    size: 18),
            label: const Text('Import JSON'),
          ),
          const SizedBox(height: 4),
          Text(
            'Required: JSON and invoice file/photo linked to the expense.',
            style: ts.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget _buildBatchImportTab(AppLocalizations l) {
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
          Text(
            selectedCount == 0
                ? l.expenseUploadBatchLimits
                : l.expenseUploadBatchSelectedCount(selectedCount),
            style: ts.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 6,
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
                        ),
                        _MetricTile(
                          width: tileWidth,
                          icon: Icons.space_dashboard_outlined,
                          label: 'Espacios disponibles',
                          value: '$remainingSlots',
                        ),
                        _MetricTile(
                          width: tileWidth,
                          icon: Icons.data_usage_outlined,
                          label: 'Tamaño total',
                          value: '$totalSizeMb MB',
                        ),
                        _MetricTile(
                          width: tileWidth,
                          icon: Icons.receipt_long_outlined,
                          label: 'Facturas detectadas en JSON',
                          value: '$batchDetectedInvoices',
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          if (batchDocumentNames.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: batchDocumentNames
                  .map(
                    (name) => Chip(
                      label: Text(name, style: const TextStyle(fontSize: 11)),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                  )
                  .toList(),
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
            const SizedBox(height: 4),
            Text(
              batchError!,
              style: TextStyle(color: cs.error, fontSize: 12),
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

// ── Compact helper widgets ──────────────────────────────────────────────

class _CompactOutlinedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;

  const _CompactOutlinedButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        textStyle: const TextStyle(fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      icon: Icon(icon, size: 16),
      label: Text(label),
    );
  }
}

class _AdvancedField extends StatelessWidget {
  final double width;
  final TextEditingController controller;
  final bool enabled;
  final String label;

  const _AdvancedField({
    required this.width,
    required this.controller,
    required this.enabled,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        enabled: enabled,
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final double width;
  final IconData icon;
  final String label;
  final String value;

  const _MetricTile({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: cs.surface.withValues(alpha: 0.32),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ts.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ts.bodySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
