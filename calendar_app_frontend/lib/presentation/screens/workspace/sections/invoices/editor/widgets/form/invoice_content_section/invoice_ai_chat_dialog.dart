import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/sections/invoice_editor_controller.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/sections/invoice_editor_pdf.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/widgets/invoice_form_sheet/invoice_lines_editor.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/widgets/pdf_preview/pdf_preview_launcher.dart' as pdf_launcher;
import 'package:hexora/services/invoicing/invoice_api.dart';
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
  final List<LineDraft> _editableLines = [];
  Set<LineDraft> _ownedLines = {};
  final Map<LineDraft, OcrExtractedLineDraft> _lineSources = {};
  final Map<LineDraft, String> _draftIds = {};
  int _nextDraftId = 0;
  OcrImageFile? _file;
  String? _draftId;
  String? _error;
  bool _sending = false;
  bool _savingDraft = false;
  bool _requiresSingleInvoice = false;
  bool _showEditor = false;
  String? _previewingInvoiceId;

  bool get _isSpanish => Localizations.localeOf(context).languageCode == 'es';

  @override
  void dispose() {
    _message.dispose();
    for (final line in _ownedLines) {
      line.dispose();
    }
    super.dispose();
  }

  String _newDraftId() =>
      'ai-${DateTime.now().microsecondsSinceEpoch}-${_nextDraftId++}';

  Map<String, String> _fieldValues(LineDraft line) => {
        'description': line.description.text,
        'quantity': line.quantityCtrl.text,
        'unitPrice': line.unitPriceCtrl.text,
        'taxRate': line.taxRateCtrl.text,
        'conceptTitle': line.conceptTitleCtrl.text,
        'conceptItems': line.conceptItemsCtrl.text,
        'serviceDate': line.serviceDateCtrl.text,
      };

  void _mergeField(TextEditingController controller, String? before,
      String incoming) {
    if (controller.text == before && controller.text != incoming) {
      controller.text = incoming;
    }
  }

  void _mergeLine(LineDraft draft, OcrExtractedLineDraft incoming,
      Map<String, String> before) {
    _mergeField(draft.description, before['description'], incoming.description);
    _mergeField(draft.quantityCtrl, before['quantity'], incoming.quantity.toString());
    _mergeField(draft.unitPriceCtrl, before['unitPrice'],
        incoming.needsPrice ? '' : incoming.unitPrice.toStringAsFixed(2));
    _mergeField(draft.taxRateCtrl, before['taxRate'], incoming.taxRate.toString());
    _mergeField(draft.conceptTitleCtrl, before['conceptTitle'],
        incoming.conceptTitle ?? '');
    _mergeField(draft.conceptItemsCtrl, before['conceptItems'],
        (incoming.conceptItems ?? []).join('\n'));
    _mergeField(draft.serviceDateCtrl, before['serviceDate'],
        incoming.serviceDate ?? '');
    draft.syncConceptMetadata();
  }

  void _reconcileSuggestedLines(
    List<OcrExtractedLineDraft> incoming,
    List<LineDraft> sentDrafts,
    Map<LineDraft, Map<String, String>> sentValues,
    Map<LineDraft, String> sentIds,
    List<OcrExtractedLineDraft> sentLines,
  ) {
    final current = _editableLines.toSet();
    final sentById = {
      for (final draft in sentDrafts)
        if (sentIds[draft] != null) sentIds[draft]!: draft,
    };
    final sentByIndex = sentDrafts.toList();
    final sentByDraft = {
      for (var i = 0; i < sentDrafts.length && i < sentLines.length; i++)
        sentDrafts[i]: sentLines[i],
    };
    final next = <LineDraft>[];
    final used = <LineDraft>{};

    for (var index = 0; index < incoming.length; index++) {
      final line = incoming[index];
      LineDraft? draft;
      if (line.draftId != null && sentById.containsKey(line.draftId)) {
        draft = sentById[line.draftId];
        if (!current.contains(draft)) continue;
      } else {
        for (final candidate in sentDrafts) {
          if (!current.contains(candidate) || used.contains(candidate)) continue;
          final source = sentByDraft[candidate];
          if (source?.description == line.description &&
              source?.serviceDate == line.serviceDate &&
              source?.conceptTitle == line.conceptTitle) {
            draft = candidate;
            break;
          }
        }
        if (draft == null) {
          final deletedMatch = sentLines.indexWhere((sent) =>
              sent.description == line.description &&
              sent.serviceDate == line.serviceDate &&
              sent.conceptTitle == line.conceptTitle &&
              sent.draftId != null &&
              sentById.containsKey(sent.draftId) &&
              !current.contains(sentById[sent.draftId]));
          if (deletedMatch >= 0) continue;
        }
        if (draft == null && incoming.length == sentByIndex.length &&
            index < sentByIndex.length && current.contains(sentByIndex[index]) &&
            !used.contains(sentByIndex[index])) {
          draft = sentByIndex[index];
        }
      }
      if (draft != null && used.contains(draft)) draft = null;
      if (draft == null) {
        draft = _editableDraftFromLine(line, index + 1);
        _draftIds[draft] = line.draftId ?? _newDraftId();
      } else {
        _mergeLine(draft, line, sentValues[draft] ?? _fieldValues(draft));
      }
      final prior = _lineSources[draft];
      _lineSources[draft] = line.priceReference == null &&
              prior?.priceReference != null &&
              prior?.description == line.description &&
              prior?.unitPrice == line.unitPrice
          ? line.copyWith(priceReference: prior!.priceReference)
          : line;
      next.add(draft);
      used.add(draft);
    }

    for (final draft in _editableLines) {
      if (used.contains(draft)) continue;
      final before = sentValues[draft];
      if (before == null || !_sameFields(_fieldValues(draft), before)) {
        next.add(draft);
      }
    }
    final removed = _ownedLines.difference(next.toSet());
    for (final draft in removed) {
      _lineSources.remove(draft);
      _draftIds.remove(draft);
    }
    _editableLines
      ..clear()
      ..addAll(next);
    for (var i = 0; i < _editableLines.length; i++) {
      _editableLines[i].position = i + 1;
    }
    _ownedLines = next.toSet();
    _suggestedLines = [for (final draft in _editableLines) _modelFromEditableDraft(draft)];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final draft in removed) {
        draft.dispose();
      }
    });
  }

  bool _sameFields(Map<String, String> a, Map<String, String> b) =>
      a.length == b.length &&
      a.entries.every((entry) => b[entry.key] == entry.value);

  LineDraft _editableDraftFromLine(OcrExtractedLineDraft line, int position) {
    final draft = LineDraft(
      position: position,
      conceptTitle: line.conceptTitle,
      conceptItems: line.conceptItems,
      serviceDate: line.serviceDate,
      isCompositeConcept: line.isCompositeConcept,
      parseMethod: line.parseMethod,
    );
    draft.description.text = line.description;
    draft.quantityCtrl.text = line.quantity.toString();
    draft.unitPriceCtrl.text = line.needsPrice
        ? ''
        : line.unitPrice.toStringAsFixed(2);
    draft.taxRateCtrl.text = line.taxRate.toString();
    return draft;
  }

  void _syncEditedLines() {
    final present = _editableLines.toSet();
    final removed = _ownedLines.difference(present).toList();
    for (final line in removed) {
      _lineSources.remove(line);
      _draftIds.remove(line);
    }
    _ownedLines = present;
    for (final line in present) {
      _draftIds.putIfAbsent(line, _newDraftId);
    }
    if (removed.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final line in removed) {
          line.dispose();
        }
      });
    }
    setState(() {
      _suggestedLines = [
        for (final draft in _editableLines)
          _modelFromEditableDraft(draft),
      ];
    });
  }

  OcrExtractedLineDraft _modelFromEditableDraft(LineDraft draft) {
    draft.syncConceptMetadata();
    final edited = draft.toLine();
    final source = _lineSources[draft];
    final quantity = (draft.quantity ?? 0).toDouble();
    final unitPrice = (draft.unitPrice ?? 0).toDouble();
    final taxRate = (draft.taxRate ?? 0).toDouble();
    final subtotal = quantity * unitPrice;
    final tax = subtotal * taxRate / 100;
    return OcrExtractedLineDraft(
      position: draft.position,
      description: edited.description,
      quantity: quantity,
      unitPrice: unitPrice,
      taxRate: taxRate,
      lineSubtotal: subtotal,
      lineTax: tax,
      lineTotal: subtotal + tax,
      sourceText: source?.sourceText ?? '',
      conceptTitle: draft.conceptTitle,
      conceptItems: draft.conceptItems,
      serviceDate: draft.serviceDate,
      isCompositeConcept: draft.isCompositeConcept,
      parseMethod: draft.parseMethod,
      needsPrice: unitPrice <= 0,
      draftId: _draftIds.putIfAbsent(draft, _newDraftId),
      priceReference: source?.description == edited.description &&
              source?.unitPrice == unitPrice
          ? source?.priceReference
          : null,
    );
  }

  bool get _canApply => _editableLines.isNotEmpty && _editableLines.every(
      (line) => line.toLine().description.trim().isNotEmpty &&
          (line.quantity ?? 0) > 0 &&
          (widget.controller.useBlocks
              ? (line.unitPrice ?? 0) >= 0
              : (line.unitPrice ?? 0) > 0) &&
          (line.taxRate ?? -1) >= 0 &&
          (line.taxRate ?? 101) <= 100);

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
    if (_sending || _savingDraft || (text.isEmpty && _file == null)) return;
    if (text.length > 2000) {
      setState(() => _error = _isSpanish
          ? 'El mensaje no puede superar 2000 caracteres.'
          : 'The message cannot exceed 2000 characters.');
      return;
    }
    final normalizedText = text.replaceAll(
      RegExp(r'&#x20;|&#32;|&nbsp;', caseSensitive: false),
      ' ',
    );
    final invoiceHeadingCount = RegExp(
      r'(?:^|\n)\s*(?:factura|invoice)\s*:',
      caseSensitive: false,
    ).allMatches(normalizedText).length;
    if (_file == null && invoiceHeadingCount > 1) {
      setState(() {
        _messages.add({'role': 'user', 'text': text});
        _messages.add({
          'role': 'assistant',
          'text': _isSpanish
              ? 'Veo más de una factura en el texto. Envíame una factura por vez y prepararé sus líneas.'
              : 'I found more than one invoice in the text. Please send one invoice at a time and I’ll prepare its lines.',
        });
        _message.clear();
        _requiresSingleInvoice = true;
      });
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
      final sentDrafts = List<LineDraft>.of(_editableLines);
      final sentValues = {
        for (final draft in sentDrafts) draft: _fieldValues(draft),
      };
      final sentIds = {
        for (final draft in sentDrafts) draft: _draftIds[draft]!,
      };
      final sentLines = List<OcrExtractedLineDraft>.of(_suggestedLines);
      final response = await _service.chatAboutInvoice(
        invoiceId: draftId,
        message: text,
        draftLines: sentLines,
        history: _messages.length <= 12
            ? _messages
            : _messages.sublist(_messages.length - 12),
        locale: _isSpanish ? 'es' : 'en',
        file: _file,
      );
      if (!mounted) return;
      final concurrentEdits = sentValues.entries.any((entry) =>
              _editableLines.contains(entry.key) &&
              !_sameFields(_fieldValues(entry.key), entry.value)) ||
          _editableLines.any((draft) => !sentValues.containsKey(draft)) ||
          sentDrafts.any((draft) => !_editableLines.contains(draft));
      setState(() {
        _draftId = draftId;
        _messages.add({
          'role': 'user',
          'text': text.isNotEmpty
              ? text
              : (_isSpanish ? 'Documento adjunto' : 'Attached document')
        });
        _requiresSingleInvoice = response.requiresSingleInvoice;
        if (!response.requiresSingleInvoice) {
          _reconcileSuggestedLines(
              response.draftLines, sentDrafts, sentValues, sentIds, sentLines);
        }
        if (response.draftLines.isNotEmpty && !_showEditor &&
            !response.requiresSingleInvoice) {
          _messages.add({
            'role': 'assistant',
            'text': '${response.reply}\n\n${_isSpanish ? 'He preparado un resumen a la derecha. Confírmalo para abrir y editar las líneas, o dime aquí qué debo corregir.' : 'I’ve prepared a summary on the right. Confirm it to open and edit the lines, or tell me here what to correct.'}${concurrentEdits ? (_isSpanish ? '\n\nConservé los cambios que hiciste mientras respondía.' : '\n\nI kept the changes you made while I was responding.') : ''}',
          });
        } else {
          _messages.add({
            'role': 'assistant',
            'text': '${response.reply}${concurrentEdits ? (_isSpanish ? '\n\nConservé los cambios que hiciste mientras respondía.' : '\n\nI kept the changes you made while I was responding.') : ''}',
          });
        }
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

  Future<void> _apply() async {
    if (!_showEditor || !_canApply || _savingDraft) return;
    final isEs = _isSpanish;
    setState(() => _savingDraft = true);
    final messenger = ScaffoldMessenger.of(context);
    var applied = false;
    try {
      widget.controller.applyAiSuggestedLines(_suggestedLines);
      applied = true;
      await widget.controller.saveAiDraft(context);
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(
        content: Text(isEs ? 'Borrador guardado.' : 'Draft saved.'),
      ));
    } catch (error) {
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(
        content: Text(applied
            ? (isEs
                ? 'Las líneas están en el editor, pero no se guardó el borrador. Corrige los datos y vuelve a guardar: $error'
                : 'The lines are in the editor, but the draft was not saved. Correct the details and save again: $error')
            : error.toString()),
      ));
    }
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
                        ? 'Pega tus notas o adjunta una imagen o PDF. Revisa las líneas propuestas y pide correcciones aquí.'
                        : 'Paste your notes or attach an image or PDF. Review the proposed lines and ask for changes here.'),
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
                ? 'Pega notas con fechas, trabajos y precios o describe el archivo...'
                : 'Paste notes with dates, work, and prices or describe the file...',
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
            onPressed: _sending || _savingDraft ? null : _send,
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

  Future<void> _previewReference(InvoicePriceReference reference) async {
    setState(() => _previewingInvoiceId = reference.invoiceId);
    try {
      final response = await InvoicesApi().previewPdf(reference.invoiceId);
      final bytes = InvoiceEditorPdf.validatePdf(response);
      await pdf_launcher.launchPdfPreview(bytes,
          fileName: 'invoice-${reference.invoiceNumber ?? reference.invoiceId}.pdf');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isSpanish
              ? 'No se pudo abrir la factura de referencia.'
              : 'Could not open the reference invoice.'),
        ));
      }
    } finally {
      if (mounted) setState(() => _previewingInvoiceId = null);
    }
  }

  Widget _referenceDetails(InvoicePriceReference reference, bool isEs) {
    final date = reference.issueDate;
    final dateLabel = date == null
        ? ''
        : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    final number = reference.invoiceNumber;
    final invoiceLabel = number == null || number.isEmpty
        ? (isEs ? 'Factura anterior' : 'Earlier invoice')
        : '${isEs ? 'Factura' : 'Invoice'} $number';
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEs
                ? 'Precio sugerido porque coincide con «${reference.matchedConcept}» en una factura emitida del mismo cliente.'
                : 'Price suggested because “${reference.matchedConcept}” matches an issued invoice for this client.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            '$invoiceLabel${dateLabel.isEmpty ? '' : ' · $dateLabel'} · ${reference.invoiceConcept} · ${reference.unitPrice.toStringAsFixed(2)} €',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          TextButton.icon(
            onPressed: _previewingInvoiceId == null
                ? () => _previewReference(reference)
                : null,
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
            label: Text(isEs ? 'Ver factura de referencia' : 'Preview source invoice'),
          ),
        ],
      ),
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
              child: Text(
                  _showEditor
                      ? (isEs ? 'Editar líneas' : 'Edit invoice lines')
                      : (isEs ? 'Resumen de factura' : 'Invoice summary'),
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            Text('${_suggestedLines.length}',
                style: Theme.of(context).textTheme.labelLarge),
          ]),
          if (_showEditor)
            Text(
              _sending
                  ? (isEs
                      ? 'La IA está respondiendo. Puedes seguir editando; conservaré tus cambios.'
                      : 'AI is responding. You can keep editing; your changes will be preserved.')
                  : (isEs
                      ? 'Los cambios de estas líneas se incluyen en tu próximo mensaje al chat.'
                      : 'Changes to these lines are included in your next chat message.'),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
          const Divider(height: 24),
          if (_suggestedLines.isEmpty && !_showEditor)
            Expanded(
              child: Center(
                child: Text(
                  _requiresSingleInvoice
                      ? (isEs
                          ? 'Envía una sola factura para preparar la vista previa.'
                          : 'Send one invoice at a time to prepare the preview.')
                      : (isEs
                          ? 'Las líneas que proponga la IA aparecerán aquí.'
                          : 'AI proposed invoice lines will appear here.'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ),
            )
          else if (!_showEditor) ...[
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      isEs
                          ? 'He preparado ${_suggestedLines.length} líneas. Revisa el resumen antes de abrir el editor.'
                          : 'I prepared ${_suggestedLines.length} lines. Review the summary before opening the editor.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 14),
                    for (final line in _suggestedLines)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${line.serviceDate == null ? '' : '${line.serviceDate} · '}${line.conceptTitle == null ? '' : '${line.conceptTitle}: '}${line.description}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              '${isEs ? 'Cant.' : 'Qty'} ${line.quantity} · ${line.needsPrice ? (isEs ? 'Precio pendiente' : 'Price needed') : '${line.unitPrice.toStringAsFixed(2)} €/${isEs ? 'ud.' : 'unit'}'}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: line.needsPrice
                                      ? colors.tertiary
                                      : colors.onSurfaceVariant),
                            ),
                            if (line.priceReference != null)
                              _referenceDetails(line.priceReference!, isEs),
                          ],
                        ),
                      ),
                    const Divider(height: 24),
                    _totalRow(isEs ? 'Base imponible' : 'Subtotal', subtotal),
                    const SizedBox(height: 6),
                    _totalRow(isEs ? 'Impuestos' : 'Tax', tax),
                    const SizedBox(height: 8),
                    _totalRow(isEs ? 'Total' : 'Total', total, strong: true),
                    if (_suggestedLines.any((line) => line.needsPrice)) ...[
                      const SizedBox(height: 12),
                      Text(
                        isEs
                            ? 'Hay líneas sin precio; el total es parcial.'
                            : 'Some lines have no price; the total is partial.',
                        style: TextStyle(color: colors.tertiary),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => setState(() => _showEditor = true),
              icon: const Icon(Icons.edit_outlined),
              label: Text(isEs ? 'Confirmar y editar líneas' : 'Confirm and edit lines'),
            ),
          ] else ...[
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InvoiceLinesEditor(
                      key: ObjectKey(_editableLines),
                      lines: _editableLines,
                      onChanged: _syncEditedLines,
                      showDiscount: false,
                    ),
                    for (final line in _suggestedLines)
                      if (line.priceReference != null) ...[
                        Text('${isEs ? 'Línea' : 'Line'} ${line.position}: ${line.description}'),
                        _referenceDetails(line.priceReference!, isEs),
                      ],
                  ],
                ),
              ),
            ),
            const Divider(height: 20),
            if (_suggestedLines.any((line) => line.needsPrice)) ...[
              Text(
                isEs
                    ? 'Faltan precios; el total es parcial. Complétalos aquí antes de añadir las líneas.'
                    : 'Some prices are missing; this total is partial. Fill them in here before adding the lines.',
                style: TextStyle(
                    color: colors.tertiary, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
            ],
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
                  onPressed: _sending || _savingDraft
                      ? null
                      : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ]),
              const SizedBox(height: 4),
              Text(isEs
                  ? 'Escribe o adjunta un archivo a la izquierda y edita las líneas de la factura a la derecha.'
                  : 'Write or attach a file on the left and edit the invoice lines on the right.'),
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
                  onPressed: _sending || _savingDraft
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: Text(isEs ? 'Cancelar' : 'Cancel'),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed:
                      _sending || _savingDraft || !_showEditor || !_canApply
                          ? null
                          : _apply,
                  icon: _savingDraft
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.save_outlined),
                  label: Text(_savingDraft
                      ? (isEs ? 'Guardando...' : 'Saving...')
                      : (isEs ? 'Guardar como borrador' : 'Save as draft')),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
