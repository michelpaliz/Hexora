import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/private_document/private_document.dart';
import 'package:hexora/b-backend/documents/private_documents_api.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/snack_helper.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

enum PrivateDocumentDetailResult { changed, unchanged }

class PrivateDocumentDetailDialog {
  static Future<PrivateDocumentDetailResult> show(
    BuildContext context, {
    required PrivateDocumentsApi api,
    required String groupId,
    required PrivateDocument document,
  }) async {
    final result = await showDialog<PrivateDocumentDetailResult>(
      context: context,
      builder: (_) => _PrivateDocumentDetailDialogBody(
        api: api,
        groupId: groupId,
        document: document,
      ),
    );
    return result ?? PrivateDocumentDetailResult.unchanged;
  }
}

class _PrivateDocumentDetailDialogBody extends StatefulWidget {
  const _PrivateDocumentDetailDialogBody({
    required this.api,
    required this.groupId,
    required this.document,
  });

  final PrivateDocumentsApi api;
  final String groupId;
  final PrivateDocument document;

  @override
  State<_PrivateDocumentDetailDialogBody> createState() =>
      _PrivateDocumentDetailDialogBodyState();
}

class _PrivateDocumentDetailDialogBodyState
    extends State<_PrivateDocumentDetailDialogBody> {
  late final TextEditingController _titleController;
  late final TextEditingController _expiryController;
  late final TextEditingController _notesController;
  late final TextEditingController _tagsController;
  late final TextEditingController _counterpartiesController;
  late String _category;
  late String _status;

  bool _dirty = false;
  bool _saving = false;
  bool _deleting = false;
  bool _openingFile = false;
  String? _error;

  bool get _isEs => Localizations.localeOf(context)
      .languageCode
      .toLowerCase()
      .startsWith('es');

  @override
  void initState() {
    super.initState();
    final d = widget.document;
    _titleController = TextEditingController(text: d.title ?? '');
    _expiryController = TextEditingController(
      text: d.expiryDate == null
          ? ''
          : DateFormat('yyyy-MM-dd').format(d.expiryDate!),
    );
    _notesController = TextEditingController(text: d.notes ?? '');
    _tagsController = TextEditingController(text: d.tags.join(', '));
    _counterpartiesController =
        TextEditingController(text: d.counterparties.join(', '));
    _category = d.category;
    _status = d.status;
    for (final c in [
      _titleController,
      _expiryController,
      _notesController,
      _tagsController,
      _counterpartiesController,
    ]) {
      c.addListener(() {
        if (!_dirty) setState(() => _dirty = true);
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _expiryController.dispose();
    _notesController.dispose();
    _tagsController.dispose();
    _counterpartiesController.dispose();
    super.dispose();
  }

  List<String> _splitList(String raw) => raw
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList(growable: false);

  Future<void> _pickExpiryDate() async {
    final initial =
        DateTime.tryParse(_expiryController.text.trim()) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 30),
    );
    if (picked == null) return;
    setState(() {
      _expiryController.text = DateFormat('yyyy-MM-dd').format(picked);
      _dirty = true;
    });
  }

  Future<void> _openFile() async {
    setState(() {
      _openingFile = true;
      _error = null;
    });
    try {
      final url = await widget.api.getFileDownloadUrl(
        groupId: widget.groupId,
        documentId: widget.document.id,
      );
      final launched =
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        setState(() {
          _error =
              _isEs ? 'No se pudo abrir el archivo' : 'Could not open the file';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _openingFile = false);
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final expiryText = _expiryController.text.trim();
      await widget.api.update(
        groupId: widget.groupId,
        documentId: widget.document.id,
        title: _titleController.text.trim(),
        category: _category,
        status: _status,
        expiryDate: expiryText.isEmpty ? null : DateTime.tryParse(expiryText),
        clearExpiryDate: expiryText.isEmpty,
        notes: _notesController.text.trim(),
        tags: _splitList(_tagsController.text),
        counterparties: _splitList(_counterpartiesController.text),
      );
      if (!mounted) return;
      showSuccessSnack(context, _isEs ? 'Documento actualizado' : 'Document updated');
      Navigator.of(context).pop(PrivateDocumentDetailResult.changed);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final isEs = _isEs;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isEs ? 'Eliminar documento' : 'Delete document'),
        content: Text(
          isEs
              ? '¿Seguro que quieres eliminar "${widget.document.displayTitle}"? Esta acción no se puede deshacer.'
              : 'Are you sure you want to delete "${widget.document.displayTitle}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(isEs ? 'Cancelar' : 'Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(isEs ? 'Eliminar' : 'Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() {
      _deleting = true;
      _error = null;
    });
    try {
      await widget.api
          .remove(groupId: widget.groupId, documentId: widget.document.id);
      if (!mounted) return;
      showSuccessSnack(context, _isEs ? 'Documento eliminado' : 'Document deleted');
      Navigator.of(context).pop(PrivateDocumentDetailResult.changed);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEs = _isEs;
    final cs = Theme.of(context).colorScheme;
    final busy = _saving || _deleting || _openingFile;

    return AlertDialog(
      title: Text(
        widget.document.displayTitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.document.fileName,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: busy ? null : _openFile,
                    icon: _openingFile
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.open_in_new_rounded, size: 16),
                    label: Text(isEs ? 'Abrir' : 'Open'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleController,
                enabled: !busy,
                decoration: InputDecoration(
                  labelText: isEs ? 'Título' : 'Title',
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: InputDecoration(
                  labelText: isEs ? 'Categoría' : 'Category',
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  for (final c in PrivateDocumentCategory.values)
                    DropdownMenuItem(
                      value: c,
                      child: Text(
                        isEs
                            ? PrivateDocumentCategory.labelEs(c)
                            : PrivateDocumentCategory.labelEn(c),
                      ),
                    ),
                ],
                onChanged: busy
                    ? null
                    : (v) => setState(() {
                          _category = v ?? _category;
                          _dirty = true;
                        }),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: InputDecoration(
                  labelText: isEs ? 'Estado de revisión' : 'Review status',
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  for (final s in PrivateDocumentReviewStatus.values)
                    DropdownMenuItem(
                      value: s,
                      child: Text(
                        isEs
                            ? PrivateDocumentReviewStatus.labelEs(s)
                            : PrivateDocumentReviewStatus.labelEn(s),
                      ),
                    ),
                ],
                onChanged: busy
                    ? null
                    : (v) => setState(() {
                          _status = v ?? _status;
                          _dirty = true;
                        }),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _expiryController,
                      enabled: !busy,
                      decoration: InputDecoration(
                        labelText: isEs ? 'Fecha de caducidad' : 'Expiry date',
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: busy ? null : _pickExpiryDate,
                    child: Text(isEs ? 'Fecha' : 'Date'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _tagsController,
                enabled: !busy,
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
                enabled: !busy,
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
                enabled: !busy,
                decoration: InputDecoration(
                  labelText: isEs ? 'Notas' : 'Notes',
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                maxLines: 3,
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(_error!, style: TextStyle(color: cs.error)),
                ),
              ],
            ],
          ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton.icon(
          onPressed: busy ? null : _confirmDelete,
          icon: _deleting
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(Icons.delete_outline_rounded, color: cs.error),
          label: Text(isEs ? 'Eliminar' : 'Delete', style: TextStyle(color: cs.error)),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: busy
                  ? null
                  : () => Navigator.of(context)
                      .pop(PrivateDocumentDetailResult.unchanged),
              child: Text(isEs ? 'Cerrar' : 'Close'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: busy || !_dirty ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEs ? 'Guardar' : 'Save'),
            ),
          ],
        ),
      ],
    );
  }
}
