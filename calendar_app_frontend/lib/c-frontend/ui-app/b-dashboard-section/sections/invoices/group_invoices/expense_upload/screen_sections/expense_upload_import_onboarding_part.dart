part of '../../expense_upload_screen.dart';

class _BatchOnboardingFlow extends StatefulWidget {
  final ColorScheme cs;
  final TextTheme ts;
  final Future<void> Function(
    List<({String fileName, Uint8List fileBytes})> files, {
    required int selectedCount,
  })? onDropWebDocuments;

  const _BatchOnboardingFlow({
    required this.cs,
    required this.ts,
    required this.onDropWebDocuments,
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
      for (final file in files) {
        try {
          final fileName = await controller.getFilename(file);
          final fileBytes = await controller.getFileData(file);
          if (fileName.trim().isEmpty || fileBytes.isEmpty) continue;
          droppedFiles.add((fileName: fileName, fileBytes: fileBytes));
        } catch (_) {
          // The shared batch validation handles readable supported files;
          // unreadable browser drops are skipped here.
        }
      }

      if (mounted && _dragging) setState(() => _dragging = false);
      if (droppedFiles.isEmpty) return;
      await onDrop(droppedFiles, selectedCount: files.length);
    } finally {
      _webDropProcessing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.cs;
    final ts = widget.ts;
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
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
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
                  ? 'Suelta los documentos para cargarlos'
                  : 'Arrastra tus facturas aqu\u00ed',
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
            'PDF, JPG, PNG o WEBP \u2022 hasta 200 documentos por lote',
            style: ts.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontSize: 12.5,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
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
          IgnorePointer(child: content),
        ],
      );
    }

    return content;
  }
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
