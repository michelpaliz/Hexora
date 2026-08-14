import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/private_document/private_document.dart';
import 'package:hexora/b-backend/documents/private_documents_api.dart';
import 'package:intl/intl.dart';

class PrivateDocumentUploadDialog {
  static Future<PrivateDocument?> show(
    BuildContext context, {
    required PrivateDocumentsApi api,
    required String groupId,
  }) {
    return showDialog<PrivateDocument?>(
      context: context,
      builder: (_) => _PrivateDocumentUploadDialogBody(api: api, groupId: groupId),
    );
  }
}

class _PrivateDocumentUploadDialogBody extends StatefulWidget {
  const _PrivateDocumentUploadDialogBody({
    required this.api,
    required this.groupId,
  });

  final PrivateDocumentsApi api;
  final String groupId;

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
  String? _error;

  bool get _isEs => Localizations.localeOf(context)
      .languageCode
      .toLowerCase()
      .startsWith('es');

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
    final result =
        await FilePicker.platform.pickFiles(allowMultiple: false, withData: true);
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
      setState(() => _error = _isEs ? 'Selecciona un archivo' : 'Select a file');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final expiryText = _expiryController.text.trim();
      final expiryDate = expiryText.isEmpty ? null : DateTime.tryParse(expiryText);
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
    final isEs = _isEs;
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(isEs ? 'Subir documento' : 'Upload document'),
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
                      _fileName ??
                          (isEs
                              ? 'Ningún archivo seleccionado'
                              : 'No file selected'),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _submitting ? null : _pickFile,
                    icon: const Icon(Icons.attach_file_rounded, size: 16),
                    label: Text(isEs ? 'Elegir archivo' : 'Choose file'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: isEs ? 'Título (opcional)' : 'Title (optional)',
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
                onChanged: _submitting
                    ? null
                    : (v) => setState(() => _category = v ?? _category),
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
                onChanged: _submitting
                    ? null
                    : (v) => setState(() => _status = v ?? _status),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _expiryController,
                      decoration: InputDecoration(
                        labelText: isEs
                            ? 'Fecha de caducidad (opcional)'
                            : 'Expiry date (optional)',
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _submitting ? null : _pickExpiryDate,
                    child: Text(isEs ? 'Fecha' : 'Date'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _tagsController,
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
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: Text(isEs ? 'Cancelar' : 'Cancel'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEs ? 'Subir' : 'Upload'),
        ),
      ],
    );
  }
}
