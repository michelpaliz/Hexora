import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/sections/invoice_editor_controller.dart';
import 'package:hexora/services/invoicing/invoice_lines_ocr_models.dart';
import 'package:hexora/services/invoicing/invoice_lines_ocr_service.dart';

class InvoiceAiChatDialog extends StatefulWidget {
  const InvoiceAiChatDialog({super.key, required this.controller});

  final InvoiceEditorController controller;

  @override
  State<InvoiceAiChatDialog> createState() => _InvoiceAiChatDialogState();
}

class _InvoiceAiChatDialogState extends State<InvoiceAiChatDialog> {
  final _service = InvoiceLinesOcrService();
  final _message = TextEditingController();
  final _messages = <Map<String, String>>[];
  List<OcrExtractedLineDraft> _suggestedLines = [];
  OcrImageFile? _file;
  String? _draftId;
  String? _error;
  bool _sending = false;

  bool get _isSpanish => Localizations.localeOf(context).languageCode == 'es';

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp', 'pdf'],
      withData: true,
    );
    if (!mounted || picked == null || picked.files.isEmpty) return;
    final file = picked.files.first;
    if (file.bytes == null ||
        file.bytes!.isEmpty ||
        file.bytes!.length > 10 * 1024 * 1024) {
      setState(() => _error = _isSpanish
          ? 'El archivo debe tener menos de 10 MB.'
          : 'The file must be under 10 MB.');
      return;
    }
    setState(() {
      _file = OcrImageFile(bytes: file.bytes!, fileName: file.name);
      _error = null;
    });
  }

  Future<void> _send() async {
    final text = _message.text.trim();
    if (_sending || (text.isEmpty && _file == null)) return;
    if (text.length > 2000) {
      setState(() => _error = _isSpanish
          ? 'El mensaje no puede superar 2000 caracteres.'
          : 'The message cannot exceed 2000 characters.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final draftId =
          _draftId ?? await widget.controller.ensureDraftIdForAiChat(context);
      if (!mounted) return;
      if (draftId == null || draftId.isEmpty) {
        throw Exception(_isSpanish
            ? 'Selecciona un cliente y guarda el borrador.'
            : 'Select a client and save the draft.');
      }
      final response = await _service.chatAboutInvoice(
        invoiceId: draftId,
        message: text,
        draftLines: _suggestedLines,
        history: _messages.length <= 12
            ? _messages
            : _messages.sublist(_messages.length - 12),
        file: _file,
      );
      if (!mounted) return;
      setState(() {
        _draftId = draftId;
        _messages.add({
          'role': 'user',
          'text': text.isNotEmpty
              ? text
              : (_isSpanish ? 'Documento adjunto' : 'Attached document')
        });
        _messages.add({'role': 'assistant', 'text': response.reply});
        _suggestedLines = response.draftLines;
        _message.clear();
        _file = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error is OcrExtractionException
          ? error.userMessage
          : error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _apply() {
    if (_suggestedLines.isEmpty) return;
    widget.controller.applyAiSuggestedLines(_suggestedLines);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEs = _isSpanish;
    final width = MediaQuery.sizeOf(context).width;
    return AlertDialog(
      title: Text(isEs ? 'Crear factura con IA' : 'Create invoice with AI'),
      content: SizedBox(
        width: width < 720 ? width - 80 : 640,
        height: MediaQuery.sizeOf(context).height * 0.65,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(isEs
                ? 'Adjunta una imagen o PDF y explica qué necesitas. Revisa las líneas antes de añadirlas al borrador.'
                : 'Attach an image or PDF and describe what you need. Review the lines before adding them to the draft.'),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  for (final item in _messages)
                    Align(
                      alignment: item['role'] == 'user'
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(item['text'] ?? ''),
                        ),
                      ),
                    ),
                  if (_suggestedLines.isNotEmpty) ...[
                    const Divider(),
                    Text(isEs ? 'Líneas propuestas' : 'Proposed lines',
                        style: Theme.of(context).textTheme.titleSmall),
                    for (final line in _suggestedLines)
                      ListTile(
                        dense: true,
                        title: Text(line.description),
                        subtitle: Text(
                            '${line.quantity} × ${line.unitPrice.toStringAsFixed(2)} € · IVA ${line.taxRate}%'),
                        trailing:
                            Text('${line.lineTotal.toStringAsFixed(2)} €'),
                      ),
                  ],
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            if (_file != null) ...[
              const SizedBox(height: 8),
              Row(children: [
                if (!_file!.fileName.toLowerCase().endsWith('.pdf'))
                  Image.memory(Uint8List.fromList(_file!.bytes),
                      width: 42,
                      height: 42,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.image_not_supported_outlined)),
                const SizedBox(width: 8),
                Expanded(
                    child:
                        Text(_file!.fileName, overflow: TextOverflow.ellipsis)),
                IconButton(
                    onPressed:
                        _sending ? null : () => setState(() => _file = null),
                    icon: const Icon(Icons.close)),
              ]),
            ],
            const SizedBox(height: 8),
            TextField(
              controller: _message,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: isEs
                    ? 'Ej.: Usa esta foto y cambia el precio a 120 €'
                    : 'E.g. Use this photo and change the price to €120',
              ),
              onSubmitted: (_) => _send(),
            ),
            const SizedBox(height: 8),
            Row(children: [
              OutlinedButton.icon(
                onPressed: _sending ? null : _pickFile,
                icon: const Icon(Icons.attach_file),
                label: Text(isEs ? 'Imagen o PDF' : 'Image or PDF'),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _sending ? null : _send,
                icon: _sending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send),
                label: Text(isEs ? 'Enviar' : 'Send'),
              ),
            ]),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: _sending ? null : () => Navigator.of(context).pop(),
            child: Text(isEs ? 'Cancelar' : 'Cancel')),
        FilledButton(
          onPressed: _sending || _suggestedLines.isEmpty ? null : _apply,
          child: Text(isEs ? 'Añadir al borrador' : 'Add to draft'),
        ),
      ],
    );
  }
}
