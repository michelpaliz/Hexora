part of '../../expense_upload_screen.dart';

class _BatchOnboardingFlow extends StatefulWidget {
  final ColorScheme cs;
  final TextTheme ts;
  final Future<void> Function(
    List<({String fileName, Uint8List fileBytes})> files, {
    required int selectedCount,
  })? onDropWebDocuments;
  final VoidCallback? onPickDocuments;
  final VoidCallback? onPickZip;

  const _BatchOnboardingFlow({
    required this.cs,
    required this.ts,
    required this.onDropWebDocuments,
    required this.onPickDocuments,
    required this.onPickZip,
  });

  @override
  State<_BatchOnboardingFlow> createState() => _BatchOnboardingFlowState();
}

class _BatchOnboardingFlowState extends State<_BatchOnboardingFlow> {
  bool _dragging = false;
  bool _webDropProcessing = false;
  DropzoneViewController? _webDropController;

  Future<void> _handleWebDropFile(DropzoneFileInterface file) async {
    await _handleWebDropFiles([file]);
  }

  Future<void> _handleWebDropFiles(List<DropzoneFileInterface>? files) async {
    final controller = _webDropController;
    final onDrop = widget.onDropWebDocuments;
    if (controller == null ||
        onDrop == null ||
        files == null ||
        files.isEmpty) {
      if (mounted && _dragging) setState(() => _dragging = false);
      return;
    }
    if (_webDropProcessing) return;
    _webDropProcessing = true;

    final droppedFiles = <({String fileName, Uint8List fileBytes})>[];
    try {
      final names = <String>[];
      for (final file in files) {
        try {
          names.add(await controller.getFilename(file));
        } catch (_) {
          names.add('Archivo no legible');
        }
      }
      final zipIndexes = <int>[
        for (var i = 0; i < names.length; i++)
          if (names[i].toLowerCase().endsWith('.zip')) i,
      ];
      if (zipIndexes.isNotEmpty && files.length != 1) {
        await onDrop(
          [(fileName: names[zipIndexes.first], fileBytes: Uint8List(0))],
          selectedCount: files.length,
        );
        return;
      }
      for (var i = 0;
          i < files.length &&
              i < _ExpenseUploadScreenStateBase._maxBatchDocuments;
          i++) {
        final file = files[i];
        final fileName = names[i];
        try {
          if (fileName.toLowerCase().endsWith('.zip') &&
              await controller.getFileSize(file) >
                  _ExpenseUploadScreenStateBase._maxBatchArchiveSizeBytes) {
            droppedFiles.add((fileName: fileName, fileBytes: Uint8List(0)));
            continue;
          }
          if (!fileName.toLowerCase().endsWith('.zip') &&
              await controller.getFileSize(file) >
                  _ExpenseUploadScreenStateBase._maxBatchFileSizeBytes) {
            droppedFiles.add((fileName: fileName, fileBytes: Uint8List(0)));
            continue;
          }
          final fileBytes = await controller.getFileData(file);
          droppedFiles.add((fileName: fileName, fileBytes: fileBytes));
        } catch (_) {
          droppedFiles.add((fileName: fileName, fileBytes: Uint8List(0)));
        }
      }

      if (mounted && _dragging) setState(() => _dragging = false);
      if (droppedFiles.isEmpty) return;
      await onDrop(droppedFiles, selectedCount: files.length);
    } finally {
      _webDropProcessing = false;
      if (mounted && _dragging) setState(() => _dragging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.cs;
    final ts = widget.ts;
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final steps = [
      (icon: Icons.upload_file_outlined, label: 'Sube tus documentos'),
      (icon: Icons.auto_awesome_outlined, label: 'Hexora analiza con IA'),
      (icon: Icons.checklist_rounded, label: 'Revisa incidencias'),
      (icon: Icons.check_circle_outline_rounded, label: 'Importa al instante'),
    ];
    final webDropEnabled = kIsWeb &&
        widget.onDropWebDocuments != null &&
        FlutterDropzonePlatform.instance.runtimeType.toString() ==
            'FlutterDropzonePlugin';

    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: _dragging
            ? cs.primaryContainer.withValues(alpha: 0.18)
            : cs.surfaceContainerHighest.withValues(alpha: 0.07),
        border: Border.all(
          color: _dragging
              ? cs.primary.withValues(alpha: 0.7)
              : cs.outlineVariant.withValues(alpha: 0.38),
          width: _dragging ? 2 : 1.5,
          strokeAlign: BorderSide.strokeAlignCenter,
        ),
        boxShadow: _dragging
            ? [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.12),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _dragging
                  ? cs.primary.withValues(alpha: 0.22)
                  : cs.primaryContainer.withValues(alpha: 0.38),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: cs.primary.withValues(
                  alpha: _dragging ? 0.45 : 0.18,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(
                    alpha: _dragging ? 0.25 : 0.08,
                  ),
                  blurRadius: 18,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              _dragging
                  ? Icons.file_download_done_outlined
                  : Icons.cloud_upload_outlined,
              size: 32,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            child: Text(
              _dragging
                  ? (isEs
                      ? 'Suelta las facturas o el ZIP para cargarlos'
                      : 'Drop invoices or ZIP to upload')
                  : (webDropEnabled
                      ? (isEs
                          ? 'Arrastra tus facturas o un ZIP aqu\u00ed'
                          : 'Drag invoices or a ZIP here')
                      : (isEs
                          ? 'Selecciona facturas o un ZIP'
                          : 'Choose invoices or a ZIP')),
              key: ValueKey(_dragging),
              style: ts.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isEs
                ? 'PDF, JPG, JPEG, JPE, PNG o WEBP \u2022 o un ZIP de hasta 100 MB y 200 facturas'
                : 'PDF, JPG, JPEG, JPE, PNG or WEBP \u2022 or one ZIP up to 100 MB and 200 invoices',
            style: ts.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontSize: 12.5,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: widget.onPickDocuments,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(220, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                icon: const Icon(Icons.upload_file_outlined, size: 18),
                label: Text(isEs ? 'Seleccionar archivos' : 'Select files'),
              ),
              OutlinedButton.icon(
                onPressed: widget.onPickZip,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(195, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                icon: const Icon(Icons.folder_outlined, size: 18),
                label: Text(isEs ? 'Seleccionar un ZIP' : 'Select a ZIP'),
              ),
            ],
          ),
          const SizedBox(height: 22),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < steps.length; i++) ...[
                  _OnboardingStep(
                    icon: steps[i].icon,
                    label: steps[i].label,
                    index: i + 1,
                    cs: cs,
                    ts: ts,
                  ),
                  if (i < steps.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 13,
                        color: cs.primary.withValues(alpha: 0.35),
                      ),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 24,
              runSpacing: 8,
              children: [
                _BatchLimitItem(
                  icon: Icons.insert_drive_file_outlined,
                  title: isEs ? 'Formatos admitidos' : 'Supported formats',
                  value: 'PDF, JPG, JPEG, PNG, WEBP',
                  cs: cs,
                  ts: ts,
                ),
                _BatchLimitItem(
                  icon: Icons.inventory_2_outlined,
                  title: isEs ? 'Tamano maximo' : 'Maximum size',
                  value: isEs ? '100 MB por ZIP' : '100 MB per ZIP',
                  cs: cs,
                  ts: ts,
                ),
                _BatchLimitItem(
                  icon: Icons.description_outlined,
                  title: isEs ? 'Limite de documentos' : 'Document limit',
                  value: isEs
                      ? 'Hasta 200 facturas por ZIP'
                      : 'Up to 200 invoices per ZIP',
                  cs: cs,
                  ts: ts,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (webDropEnabled) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: DropzoneView(
              operation: DragOperation.copy,
              onCreated: (controller) => _webDropController = controller,
              onHover: () {
                if (!mounted || _dragging) return;
                setState(() => _dragging = true);
              },
              onLeave: () {
                if (!mounted || !_dragging) return;
                setState(() => _dragging = false);
              },
              onDropFile: _handleWebDropFile,
              onDropFiles: _handleWebDropFiles,
            ),
          ),
          IgnorePointer(child: SingleChildScrollView(child: content)),
        ],
      );
    }

    return SingleChildScrollView(child: content);
  }
}

class _BatchLimitItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final ColorScheme cs;
  final TextTheme ts;

  const _BatchLimitItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.cs,
    required this.ts,
  });

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Icon(icon, size: 17, color: cs.primary),
          ),
          const SizedBox(width: 9),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title,
                  style: ts.bodySmall?.copyWith(fontWeight: FontWeight.w800)),
              Text(value,
                  style: ts.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            ],
          ),
        ],
      );
}

class _OnboardingStep extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final ColorScheme cs;
  final TextTheme ts;

  const _OnboardingStep({
    required this.icon,
    required this.label,
    required this.index,
    required this.cs,
    required this.ts,
  });

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: cs.primaryContainer.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: cs.primary.withValues(alpha: 0.18),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 15, color: cs.primary),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: ts.bodySmall?.copyWith(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
                height: 1.25,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
