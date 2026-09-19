part of '../../expense_upload_screen.dart';

class _BatchLeftControlPanel extends StatefulWidget {
  final int selectedCount;
  final int maxDocuments;
  final int totalBytes;
  final bool submitting;
  final bool hasGroupSelected;
  final bool canImport;
  final bool jobActive;
  final bool jobCompleted;
  final bool jobFailed;
  final String? statusMessage;
  final int warningCount;
  final int importedCount;
  final int skippedCount;
  final VoidCallback onPickDocuments;
  final VoidCallback onImport;
  final VoidCallback? onClearSelection;

  const _BatchLeftControlPanel({
    required this.selectedCount,
    required this.maxDocuments,
    required this.totalBytes,
    required this.submitting,
    required this.hasGroupSelected,
    required this.canImport,
    required this.jobActive,
    required this.jobCompleted,
    required this.jobFailed,
    required this.statusMessage,
    this.warningCount = 0,
    this.importedCount = 0,
    this.skippedCount = 0,
    required this.onPickDocuments,
    required this.onImport,
    this.onClearSelection,
  });

  @override
  State<_BatchLeftControlPanel> createState() => _BatchLeftControlPanelState();
}

class _BatchLeftControlPanelState extends State<_BatchLeftControlPanel> {
  final bool _dragging = false;

  // Derive the active workflow step from job state.
  int get _activeStep {
    if (widget.jobActive) return 1;
    if (widget.jobCompleted || widget.jobFailed) {
      return widget.warningCount > 0 ? 2 : 3;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final step = _activeStep;

    final steps = [
      (
        icon: Icons.cloud_upload_outlined,
        title: isEs ? 'Subir documentos' : 'Upload documents',
        subtitle: isEs
            ? 'Hasta ${widget.maxDocuments} archivos'
            : 'Up to ${widget.maxDocuments} files',
      ),
      (
        icon: Icons.auto_awesome_outlined,
        title: isEs
            ? 'Verificaci\u00f3n autom\u00e1tica'
            : 'Automatic verification',
        subtitle: isEs ? 'OCR e IA' : 'OCR and AI',
      ),
      (
        icon: Icons.warning_amber_rounded,
        title: isEs ? 'Revisar incidencias' : 'Review issues',
        subtitle: widget.warningCount > 0
            ? (isEs
                ? '${widget.warningCount} detectadas'
                : '${widget.warningCount} found')
            : (isEs ? 'Sin incidencias' : 'No issues'),
      ),
      (
        icon: Icons.playlist_add_check_circle_outlined,
        title: isEs ? 'Confirmar importaci\u00f3n' : 'Confirm import',
        subtitle: isEs ? 'Importar gastos' : 'Import expenses',
      ),
    ];

    bool stepCompleted(int i) {
      if (widget.jobFailed) return false;
      return i < step;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: cs.surface.withValues(alpha: 0.18),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.28)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    (constraints.maxHeight - 32).clamp(0, double.infinity),
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ Step navigator ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬
                    for (int i = 0; i < steps.length; i++) ...[
                      if (i > 0)
                        Padding(
                          padding: const EdgeInsets.only(left: 15),
                          child: SizedBox(
                            height: 12,
                            width: 1,
                            child: VerticalDivider(
                              color: i <= step
                                  ? cs.primary.withValues(alpha: 0.35)
                                  : cs.outlineVariant.withValues(alpha: 0.35),
                              thickness: 1,
                              width: 1,
                            ),
                          ),
                        ),
                      _StepRow(
                        index: i,
                        icon: steps[i].icon,
                        title: steps[i].title,
                        subtitle: steps[i].subtitle,
                        isActive: step == i,
                        isCompleted: stepCompleted(i),
                        isReachable: i <= step,
                        onTap: null,
                        cs: cs,
                        ts: ts,
                      ),
                    ],
                    const SizedBox(height: 16),
                    // ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ Step content ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬
                    if (step == 0) ...[
                      // Upload zone
                      Builder(
                        builder: (context) {
                          final uploadZone = AnimatedContainer(
                            duration: const Duration(milliseconds: 140),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _dragging
                                    ? cs.primary.withValues(alpha: 0.8)
                                    : cs.outlineVariant.withValues(alpha: 0.38),
                                width: _dragging ? 1.5 : 1,
                              ),
                              color: _dragging
                                  ? cs.primaryContainer.withValues(alpha: 0.16)
                                  : cs.surface.withValues(alpha: 0.26),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Icon(
                                  _dragging
                                      ? Icons.file_download_done_outlined
                                      : Icons.cloud_upload_outlined,
                                  size: 28,
                                  color: cs.primary,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _dragging
                                      ? l.expenseBatchLeftDropActive
                                      : l.expenseBatchLeftDropHint,
                                  textAlign: TextAlign.center,
                                  style: ts.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: _dragging ? cs.primary : null,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  l.expenseBatchLeftFileTypes,
                                  textAlign: TextAlign.center,
                                  style: ts.bodySmall
                                      ?.copyWith(color: cs.onSurfaceVariant),
                                ),
                                const SizedBox(height: 12),
                                FilledButton.tonalIcon(
                                  onPressed: widget.submitting
                                      ? null
                                      : widget.onPickDocuments,
                                  icon: const Icon(Icons.upload_file_outlined,
                                      size: 17),
                                  label: Text(l.expenseBatchLeftPickCta),
                                ),
                              ],
                            ),
                          );

                          return uploadZone;
                        },
                      ),
                      if (widget.selectedCount > 0) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: cs.primaryContainer.withValues(alpha: 0.12),
                            border: Border.all(
                              color: cs.primary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.insert_drive_file_outlined,
                                  size: 14, color: cs.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isEs
                                      ? '${widget.selectedCount} archivo${widget.selectedCount == 1 ? '' : 's'} seleccionado${widget.selectedCount == 1 ? '' : 's'}'
                                      : '${widget.selectedCount} file${widget.selectedCount == 1 ? '' : 's'} selected',
                                  style: ts.bodySmall?.copyWith(
                                    color: cs.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (widget.onClearSelection != null)
                                InkWell(
                                  onTap: widget.submitting
                                      ? null
                                      : widget.onClearSelection,
                                  borderRadius: BorderRadius.circular(4),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Icon(Icons.close_rounded,
                                        size: 14,
                                        color:
                                            cs.primary.withValues(alpha: 0.7)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ] else if (step == 1) ...[
                      // Processing pipeline visualization
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: cs.primaryContainer.withValues(alpha: 0.08),
                          border: Border.all(
                            color: cs.primary.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: cs.primary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isEs
                                      ? 'Procesando lote...'
                                      : 'Processing batch...',
                                  style: ts.bodySmall?.copyWith(
                                    color: cs.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            if ((widget.statusMessage ?? '')
                                .trim()
                                .isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                widget.statusMessage!.trim(),
                                style: ts.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  height: 1.4,
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            _BatchPipelineStages(isEs: isEs, cs: cs, ts: ts),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Results summary
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: widget.jobFailed
                              ? cs.errorContainer.withValues(alpha: 0.12)
                              : widget.warningCount > 0
                                  ? Colors.amber.withValues(alpha: 0.08)
                                  : Colors.green.withValues(alpha: 0.08),
                          border: Border.all(
                            color: widget.jobFailed
                                ? cs.error.withValues(alpha: 0.28)
                                : widget.warningCount > 0
                                    ? Colors.amber.withValues(alpha: 0.35)
                                    : Colors.green.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  widget.jobFailed
                                      ? Icons.error_outline_rounded
                                      : widget.warningCount > 0
                                          ? Icons.warning_amber_rounded
                                          : Icons.check_circle_outline_rounded,
                                  size: 14,
                                  color: widget.jobFailed
                                      ? cs.error
                                      : widget.warningCount > 0
                                          ? Colors.amber.shade700
                                          : Colors.green.shade600,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  widget.jobFailed
                                      ? (isEs
                                          ? 'Importaci\u00f3n fallida'
                                          : 'Import failed')
                                      : widget.warningCount > 0
                                          ? (isEs
                                              ? 'Revisi\u00f3n necesaria'
                                              : 'Review needed')
                                          : (isEs
                                              ? '${widget.importedCount} gastos listos'
                                              : '${widget.importedCount} expenses ready'),
                                  style: ts.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: widget.jobFailed
                                        ? cs.error
                                        : widget.warningCount > 0
                                            ? Colors.amber.shade700
                                            : Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                            if ((widget.statusMessage ?? '')
                                .trim()
                                .isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                widget.statusMessage!.trim(),
                                style: ts.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant, height: 1.4),
                              ),
                            ],
                            if (!widget.jobFailed) ...[
                              const SizedBox(height: 10),
                              if (widget.importedCount > 0)
                                _ResultRow(
                                  icon: Icons.check_circle_outline_rounded,
                                  label: isEs
                                      ? '${widget.importedCount} listos'
                                      : '${widget.importedCount} ready',
                                  color: Colors.green.shade600,
                                  ts: ts,
                                ),
                              if (widget.warningCount > 0) ...[
                                const SizedBox(height: 4),
                                _ResultRow(
                                  icon: Icons.warning_amber_rounded,
                                  label: isEs
                                      ? '${widget.warningCount} requieren revisi\u00f3n'
                                      : '${widget.warningCount} need review',
                                  color: Colors.amber.shade700,
                                  ts: ts,
                                ),
                              ],
                              if (widget.skippedCount > 0) ...[
                                const SizedBox(height: 4),
                                _ResultRow(
                                  icon: Icons.remove_circle_outline_rounded,
                                  label: isEs
                                      ? '${widget.skippedCount} duplicados omitidos'
                                      : '${widget.skippedCount} duplicates omitted',
                                  color: cs.onSurfaceVariant,
                                  ts: ts,
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ],
                    const Spacer(),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: widget.canImport ? widget.onImport : null,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: widget.submitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              Icons.playlist_add_check_circle_outlined),
                      label: Text(
                        widget.jobCompleted
                            ? l.expenseBatchLeftCompleted
                            : widget.jobActive
                                ? l.expenseBatchLeftProcessing
                                : (isEs
                                    ? 'Analizar documentos'
                                    : 'Analyze documents'),
                      ),
                    ),
                    if (!widget.hasGroupSelected) ...[
                      const SizedBox(height: 8),
                      Text(
                        l.expenseBatchLeftGroupRequired,
                        style: ts.bodySmall?.copyWith(color: cs.error),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BatchPipelineStages extends StatelessWidget {
  final bool isEs;
  final ColorScheme cs;
  final TextTheme ts;

  const _BatchPipelineStages(
      {required this.isEs, required this.cs, required this.ts});

  @override
  Widget build(BuildContext context) {
    final stages = [
      (
        icon: Icons.check_circle_outline_rounded,
        label: isEs ? 'Documentos subidos' : 'Documents uploaded',
        done: true
      ),
      (
        icon: Icons.document_scanner_outlined,
        label: isEs ? 'OCR extrayendo texto' : 'OCR extracting text',
        done: false
      ),
      (
        icon: Icons.auto_awesome_outlined,
        label: isEs ? 'IA analizando datos' : 'AI analysing data',
        done: false
      ),
      (
        icon: Icons.price_check_outlined,
        label: isEs ? 'Validando importes' : 'Validating amounts',
        done: false
      ),
    ];

    return Column(
      children: [
        for (int i = 0; i < stages.length; i++) ...[
          if (i > 0) const SizedBox(height: 6),
          Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: stages[i].done
                    ? Icon(Icons.check_circle_rounded,
                        size: 14, color: Colors.green.shade600)
                    : SizedBox(
                        width: 13,
                        height: 13,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: cs.primary.withValues(alpha: 0.6),
                        ),
                      ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  stages[i].label,
                  style: ts.bodySmall?.copyWith(
                    fontSize: 11,
                    color: stages[i].done
                        ? cs.onSurface
                        : cs.onSurfaceVariant.withValues(alpha: 0.7),
                    fontWeight: stages[i].done ? FontWeight.w600 : null,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
