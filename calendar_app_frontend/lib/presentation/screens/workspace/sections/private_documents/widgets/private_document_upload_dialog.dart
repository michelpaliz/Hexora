import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hexora/presentation/shared/widgets/buttons/hexora_button.dart';
import 'package:hexora/presentation/shared/widgets/dialogs/hexora_dialog_route.dart';
import 'package:hexora/models/documents/private_document.dart';
import 'package:hexora/services/documents/private_documents_api.dart';
import 'package:intl/intl.dart';

class PrivateDocumentUploadDialog {
  static Future<PrivateDocument?> show(
    BuildContext context, {
    required PrivateDocumentsApi api,
    required String groupId,
    bool fullScreen = false,
  }) {
    return showHexoraDialog<PrivateDocument?>(
      context: context,
      builder: (_) => _PrivateDocumentUploadDialogBody(
        api: api,
        groupId: groupId,
        fullScreen: fullScreen,
      ),
    );
  }
}

class _PrivateDocumentUploadDialogBody extends StatefulWidget {
  const _PrivateDocumentUploadDialogBody({
    required this.api,
    required this.groupId,
    required this.fullScreen,
  });

  final PrivateDocumentsApi api;
  final String groupId;
  final bool fullScreen;

  @override
  State<_PrivateDocumentUploadDialogBody> createState() =>
      _PrivateDocumentUploadDialogBodyState();
}

class _PrivateDocumentUploadDialogBodyState
    extends State<_PrivateDocumentUploadDialogBody> {
  final _titleController = TextEditingController();
  final _expiryController = TextEditingController();
  final _notesController = TextEditingController();
  final _tagsController = TextEditingController();
  final _counterpartiesController = TextEditingController();

  String? _fileName;
  List<int>? _fileBytes;
  String _category = PrivateDocumentCategory.contract;
  String _status = PrivateDocumentReviewStatus.pendingReview;
  bool _submitting = false;
  bool _showExtras = false;
  String? _error;

  bool get _isEs => Localizations.localeOf(context)
      .languageCode
      .toLowerCase()
      .startsWith('es');

  bool get _canSubmit => _fileBytes != null && !_submitting;

  @override
  void dispose() {
    _titleController.dispose();
    _expiryController.dispose();
    _notesController.dispose();
    _tagsController.dispose();
    _counterpartiesController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'jpe', 'png', 'webp'],
      allowMultiple: false,
      withData: true,
    );
    if (!mounted) return;
    final file = result?.files.single;
    if (file == null || file.bytes == null) return;
    if (file.bytes!.length > PrivateDocumentsApi.maxUploadBytes) {
      setState(() {
        _error = _isEs
            ? 'El archivo supera el límite de 20 MB'
            : 'File exceeds the 20MB limit';
      });
      return;
    }
    setState(() {
      _fileName = file.name;
      _fileBytes = file.bytes;
      if (_titleController.text.trim().isEmpty) {
        _titleController.text = file.name.replaceFirst(RegExp(r'\.[^.]+$'), '');
      }
      _error = null;
    });
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 30),
    );
    if (!mounted) return;
    if (picked == null) return;
    setState(() {
      _expiryController.text = DateFormat('yyyy-MM-dd').format(picked);
    });
  }

  List<String> _splitList(String raw) => raw
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList(growable: false);

  Future<void> _submit() async {
    if (_fileBytes == null || _fileName == null) {
      setState(
          () => _error = _isEs ? 'Selecciona un archivo' : 'Select a file');
      return;
    }
    final expiryText = _expiryController.text.trim();
    final expiryDate =
        expiryText.isEmpty ? null : DateTime.tryParse(expiryText);
    if (expiryText.isNotEmpty && expiryDate == null) {
      setState(() => _error = _isEs
          ? 'Introduce una fecha de caducidad válida'
          : 'Enter a valid expiry date');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final created = await widget.api.upload(
        groupId: widget.groupId,
        bytes: _fileBytes!,
        fileName: _fileName!,
        category: _category,
        status: _status,
        title: _titleController.text.trim().isEmpty
            ? null
            : _titleController.text.trim(),
        expiryDate: expiryDate,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        tags: _splitList(_tagsController.text),
        counterparties: _splitList(_counterpartiesController.text),
      );
      if (!mounted) return;
      Navigator.of(context).pop(created);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.fullScreen) return _buildFullScreen(context);
    return _buildDialog(context);
  }

  // ── desktop dialog ──────────────────────────────────────────────────────

  Widget _buildDialog(BuildContext context) {
    final isEs = _isEs;
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: cs.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(context),
            if (_submitting) const LinearProgressIndicator(minHeight: 2),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: _formBody(isEs, cs),
              ),
            ),
            _footer(context),
          ],
        ),
      ),
    );
  }

  // ── mobile full-screen sheet ────────────────────────────────────────────

  Widget _buildFullScreen(BuildContext context) {
    final isEs = _isEs;
    final cs = Theme.of(context).colorScheme;

    return Dialog.fullscreen(
      backgroundColor: cs.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(context),
          if (_submitting) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: _formBody(isEs, cs),
            ),
          ),
          _footer(context),
        ],
      ),
    );
  }

  // ── shared pieces ───────────────────────────────────────────────────────

  Widget _header(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEs = _isEs;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 10, 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              isEs ? 'Subir documento' : 'Upload document',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
            ),
          ),
          IconButton(
            tooltip: isEs ? 'Cerrar' : 'Close',
            onPressed:
                _submitting ? null : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, size: 20),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _footer(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEs = _isEs;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          HexoraButton(
            label: isEs ? 'Cancelar' : 'Cancel',
            variant: HexoraButtonVariant.secondary,
            size: HexoraButtonSize.standard,
            onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
          HexoraButton(
            label: isEs ? 'Subir' : 'Upload',
            size: HexoraButtonSize.standard,
            loading: _submitting,
            onPressed: _canSubmit ? _submit : null,
          ),
        ],
      ),
    );
  }

  Widget _formBody(bool isEs, ColorScheme cs) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FileDropZone(
          fileName: _fileName,
          fileSizeBytes: _fileBytes?.length,
          isEs: isEs,
          enabled: !_submitting,
          onPick: _pickFile,
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _titleController,
          enabled: !_submitting,
          decoration: InputDecoration(
            labelText: isEs ? 'Título' : 'Title',
            hintText: isEs
                ? 'Se propone desde el archivo'
                : 'Suggested from file name',
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        _CategoryStatusFields(
          category: _category,
          status: _status,
          enabled: !_submitting,
          isEs: isEs,
          onCategoryChanged: (v) => setState(() => _category = v),
          onStatusChanged: (v) => setState(() => _status = v),
        ),
        const SizedBox(height: 6),
        // Collapsible optional fields — no vertical gap when closed.
        InkWell(
          onTap: () => setState(() => _showExtras = !_showExtras),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
            child: Row(
              children: [
                Icon(
                  _showExtras
                      ? Icons.keyboard_arrow_down_rounded
                      : Icons.keyboard_arrow_right_rounded,
                  size: 20,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  isEs ? 'Información adicional' : 'Additional information',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ),
        if (_showExtras) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _expiryController,
                  readOnly: true,
                  enabled: !_submitting,
                  decoration: InputDecoration(
                    labelText: isEs ? 'Fecha de caducidad' : 'Expiry date',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: isEs ? 'Elegir fecha' : 'Choose date',
                onPressed: _submitting ? null : _pickExpiryDate,
                icon: const Icon(Icons.calendar_today_outlined, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _tagsController,
            enabled: !_submitting,
            decoration: InputDecoration(
              labelText: isEs
                  ? 'Etiquetas (separadas por comas)'
                  : 'Tags (comma separated)',
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _counterpartiesController,
            enabled: !_submitting,
            decoration: InputDecoration(
              labelText: isEs
                  ? 'Contrapartes (separadas por comas)'
                  : 'Counterparties (comma separated)',
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _notesController,
            enabled: !_submitting,
            decoration: InputDecoration(
              labelText: isEs ? 'Notas' : 'Notes',
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            maxLines: 3,
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.error_outline_rounded, size: 16, color: cs.error),
              const SizedBox(width: 6),
              Expanded(
                child: Text(_error!, style: TextStyle(color: cs.error)),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _CategoryStatusFields extends StatelessWidget {
  const _CategoryStatusFields({
    required this.category,
    required this.status,
    required this.enabled,
    required this.isEs,
    required this.onCategoryChanged,
    required this.onStatusChanged,
  });

  final String category;
  final String status;
  final bool enabled;
  final bool isEs;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final categoryField = DropdownButtonFormField<String>(
      initialValue: category,
      decoration: InputDecoration(
        labelText: isEs ? 'Categoría' : 'Category',
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      items: [
        for (final c in PrivateDocumentCategory.values)
          DropdownMenuItem(
            value: c,
            child: Text(isEs
                ? PrivateDocumentCategory.labelEs(c)
                : PrivateDocumentCategory.labelEn(c)),
          ),
      ],
      onChanged: enabled ? (v) => onCategoryChanged(v ?? category) : null,
    );

    final statusField = DropdownButtonFormField<String>(
      initialValue: status,
      decoration: InputDecoration(
        labelText: isEs ? 'Estado de revisión' : 'Review status',
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      items: [
        for (final s in PrivateDocumentReviewStatus.values)
          DropdownMenuItem(
            value: s,
            child: Text(isEs
                ? PrivateDocumentReviewStatus.labelEs(s)
                : PrivateDocumentReviewStatus.labelEn(s)),
          ),
      ],
      onChanged: enabled ? (v) => onStatusChanged(v ?? status) : null,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Side by side on wider surfaces, stacked on narrow phones.
        if (constraints.maxWidth < 420) {
          return Column(
            children: [
              categoryField,
              const SizedBox(height: 12),
              statusField,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: categoryField),
            const SizedBox(width: 10),
            Expanded(child: statusField),
          ],
        );
      },
    );
  }
}

class _FileDropZone extends StatelessWidget {
  const _FileDropZone({
    required this.fileName,
    required this.fileSizeBytes,
    required this.isEs,
    required this.enabled,
    required this.onPick,
  });

  final String? fileName;
  final int? fileSizeBytes;
  final bool isEs;
  final bool enabled;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasFile = fileName != null;
    final sizeLabel = fileSizeBytes == null
        ? null
        : '${(fileSizeBytes! / (1024 * 1024)).toStringAsFixed(fileSizeBytes! < 1024 * 1024 ? 1 : 0)} MB';
    return Material(
      color: hasFile
          ? cs.primary.withValues(alpha: 0.06)
          : cs.surfaceContainerHighest.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: enabled ? onPick : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          constraints: const BoxConstraints(minHeight: 68),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: hasFile
                  ? cs.primary.withValues(alpha: 0.35)
                  : cs.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Icon(
                hasFile ? Icons.description_outlined : Icons.upload_file_rounded,
                color: cs.primary,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName ??
                          (isEs ? 'Selecciona un archivo' : 'Select a file'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sizeLabel ??
                          (isEs
                              ? 'PDF o imagen, hasta 20 MB'
                              : 'PDF or image, up to 20 MB'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              HexoraButton(
                label: hasFile
                    ? (isEs ? 'Cambiar' : 'Change')
                    : (isEs ? 'Elegir' : 'Choose'),
                variant: HexoraButtonVariant.secondary,
                size: HexoraButtonSize.compact,
                onPressed: enabled ? onPick : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
