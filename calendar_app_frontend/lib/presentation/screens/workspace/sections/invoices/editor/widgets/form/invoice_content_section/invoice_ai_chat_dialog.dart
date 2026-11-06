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

  Widget _buildChatPane(BuildContext context, bool isEs) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(isEs ? 'Chat' : 'Chat',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceContainerLowest,
              border: Border.all(color: colors.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView(
              padding: const EdgeInsets.all(10),
              children: [
                if (_messages.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(isEs
                        ? 'Adjunta una imagen o PDF y describe las líneas que necesitas. Puedes pedir correcciones después.'
                        : 'Attach an image or PDF and describe the invoice lines you need. You can ask for changes afterward.'),
                  ),
                for (final item in _messages)
                  Align(
                    alignment: item['role'] == 'user'
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Card(
                        color: item['role'] == 'user'
                            ? colors.primaryContainer
                            : colors.surfaceContainerHigh,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(item['text'] ?? ''),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: TextStyle(color: colors.error)),
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
                child: Text(_file!.fileName, overflow: TextOverflow.ellipsis)),
            IconButton(
              onPressed: _sending ? null : () => setState(() => _file = null),
              icon: const Icon(Icons.close),
            ),
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
    );
  }

  Widget _buildInvoicePreview(BuildContext context, bool isEs) {
    final colors = Theme.of(context).colorScheme;
    final subtotal =
        _suggestedLines.fold<double>(0, (sum, line) => sum + line.lineSubtotal);
    final tax =
        _suggestedLines.fold<double>(0, (sum, line) => sum + line.lineTax);
    final total =
        _suggestedLines.fold<double>(0, (sum, line) => sum + line.lineTotal);
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            const Icon(Icons.receipt_long_outlined),
            const SizedBox(width: 8),
            Expanded(
              child: Text(isEs ? 'Vista previa de factura' : 'Invoice preview',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            Text('${_suggestedLines.length}',
                style: Theme.of(context).textTheme.labelLarge),
          ]),
          const Divider(height: 24),
          if (_suggestedLines.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  isEs
                      ? 'Las líneas que proponga la IA aparecerán aquí.'
                      : 'AI proposed invoice lines will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ),
            )
          else ...[
            Expanded(
              child: ListView.separated(
                itemCount: _suggestedLines.length,
                separatorBuilder: (_, __) => const Divider(height: 20),
                itemBuilder: (context, index) {
                  final line = _suggestedLines[index];
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(line.description,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(
                              '${line.quantity} × ${line.unitPrice.toStringAsFixed(2)} € · ${isEs ? 'IVA' : 'VAT'} ${line.taxRate}%',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${line.lineTotal.toStringAsFixed(2)} €'),
                      IconButton(
                        tooltip: isEs ? 'Eliminar línea' : 'Remove line',
                        visualDensity: VisualDensity.compact,
                        onPressed: () =>
                            setState(() => _suggestedLines.removeAt(index)),
                        icon: const Icon(Icons.close, size: 18),
                      ),
                    ],
                  );
                },
              ),
            ),
            const Divider(height: 20),
            _totalRow(isEs ? 'Base imponible' : 'Subtotal', subtotal),
            const SizedBox(height: 6),
            _totalRow(isEs ? 'Impuestos' : 'Tax', tax),
            const SizedBox(height: 10),
            _totalRow(isEs ? 'Total' : 'Total', total, strong: true),
          ],
        ],
      ),
    );
  }

  Widget _totalRow(String label, double amount, {bool strong = false}) {
    final style = strong
        ? Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w800)
        : Theme.of(context).textTheme.bodyMedium;
    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text('${amount.toStringAsFixed(2)} €', style: style)
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEs = _isSpanish;
    final screen = MediaQuery.sizeOf(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(12),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: screen.width < 820 ? screen.width - 24 : 1100,
          maxHeight: screen.height * 0.9,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                const Icon(Icons.auto_awesome_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                      isEs ? 'Crear factura con IA' : 'Create invoice with AI',
                      style: Theme.of(context).textTheme.titleLarge),
                ),
                IconButton(
                  tooltip: isEs ? 'Cerrar' : 'Close',
                  onPressed:
                      _sending ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ]),
              const SizedBox(height: 4),
              Text(isEs
                  ? 'Conversa a la izquierda y revisa las líneas y los importes a la derecha.'
                  : 'Chat on the left and review invoice lines and totals on the right.'),
              const SizedBox(height: 16),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth >= 700) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                              flex: 6, child: _buildChatPane(context, isEs)),
                          const SizedBox(width: 16),
                          Expanded(
                              flex: 5,
                              child: _buildInvoicePreview(context, isEs)),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        Expanded(flex: 5, child: _buildChatPane(context, isEs)),
                        const SizedBox(height: 12),
                        Expanded(
                            flex: 4,
                            child: _buildInvoicePreview(context, isEs)),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(children: [
                TextButton(
                  onPressed:
                      _sending ? null : () => Navigator.of(context).pop(),
                  child: Text(isEs ? 'Cancelar' : 'Cancel'),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed:
                      _sending || _suggestedLines.isEmpty ? null : _apply,
                  icon: const Icon(Icons.playlist_add_check),
                  label: Text(isEs ? 'Añadir al borrador' : 'Add to draft'),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
