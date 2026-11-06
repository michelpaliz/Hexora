import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/sections/invoice_editor_controller.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/widgets/invoice_form_sheet/invoice_lines_editor.dart';
import 'package:hexora/services/invoicing/invoice_lines_ocr_models.dart';
import 'package:hexora/services/invoicing/invoice_lines_ocr_service.dart';

class InvoiceAiChatDialog extends StatefulWidget {
  const InvoiceAiChatDialog({
    super.key,
    required this.controller,
    this.embedded = false,
  });

  final InvoiceEditorController controller;
  final bool embedded;

  @override
  State<InvoiceAiChatDialog> createState() => _InvoiceAiChatDialogState();
}

class _InvoiceAiChatDialogState extends State<InvoiceAiChatDialog> {
  final _service = InvoiceLinesOcrService();
  final _message = TextEditingController();
  final _messageFocus = FocusNode();
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
  bool _requiresSingleInvoice = false;
  bool _showEditor = false;

  bool get _isSpanish => Localizations.localeOf(context).languageCode == 'es';

  @override
  void dispose() {
    _message.dispose();
    _messageFocus.dispose();
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

  void _mergeField(
      TextEditingController controller, String? before, String incoming) {
    if (controller.text == before && controller.text != incoming) {
      controller.text = incoming;
    }
  }

  void _mergeLine(LineDraft draft, OcrExtractedLineDraft incoming,
      Map<String, String> before) {
    _mergeField(draft.description, before['description'], incoming.description);
    _mergeField(
        draft.quantityCtrl, before['quantity'], incoming.quantity.toString());
    _mergeField(draft.unitPriceCtrl, before['unitPrice'],
        incoming.needsPrice ? '' : incoming.unitPrice.toStringAsFixed(2));
    _mergeField(
        draft.taxRateCtrl, before['taxRate'], incoming.taxRate.toString());
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
          if (!current.contains(candidate) || used.contains(candidate)) {
            continue;
          }
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
        if (draft == null &&
            incoming.length == sentByIndex.length &&
            index < sentByIndex.length &&
            current.contains(sentByIndex[index]) &&
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
      _lineSources[draft] = line;
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
    _suggestedLines = [
      for (final draft in _editableLines) _modelFromEditableDraft(draft)
    ];
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
    draft.unitPriceCtrl.text =
        line.needsPrice ? '' : line.unitPrice.toStringAsFixed(2);
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
        for (final draft in _editableLines) _modelFromEditableDraft(draft),
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
    );
  }

  bool get _canApply =>
      _editableLines.isNotEmpty &&
      _editableLines.every((line) =>
          line.toLine().description.trim().isNotEmpty &&
          (line.quantity ?? 0) > 0 &&
          (line.unitPrice ?? 0) > 0 &&
          (line.taxRate ?? -1) >= 0);

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
        if (response.draftLines.isNotEmpty &&
            !_showEditor &&
            !response.requiresSingleInvoice) {
          _messages.add({
            'role': 'assistant',
            'text':
                '${response.reply}\n\n${_isSpanish ? 'He preparado un resumen a la derecha. Confírmalo para abrir y editar las líneas, o dime aquí qué debo corregir.' : 'I’ve prepared a summary on the right. Confirm it to open and edit the lines, or tell me here what to correct.'}${concurrentEdits ? (_isSpanish ? '\n\nConservé los cambios que hiciste mientras respondía.' : '\n\nI kept the changes you made while I was responding.') : ''}',
          });
        } else {
          _messages.add({
            'role': 'assistant',
            'text':
                '${response.reply}${concurrentEdits ? (_isSpanish ? '\n\nConservé los cambios que hiciste mientras respondía.' : '\n\nI kept the changes you made while I was responding.') : ''}',
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

  void _apply() {
    if (!_showEditor || !_canApply) return;
    widget.controller.applyAiSuggestedLines(_suggestedLines);
    if (!widget.embedded) Navigator.of(context).pop();
  }

  Widget _buildChatPane(BuildContext context, bool isEs) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final prompts = isEs
        ? const [
            'Añade estos trabajos y precios',
            'Organiza las líneas por fecha',
            'Revisa y corrige mi borrador',
          ]
        : const [
            'Add these jobs and prices',
            'Organize the lines by date',
            'Review and correct my draft',
          ];

    return LayoutBuilder(
      builder: (context, constraints) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: ListView(
                  key: const ValueKey('invoice-ai-conversation'),
                  padding: const EdgeInsets.fromLTRB(12, 20, 12, 24),
                  children: [
                    if (_messages.isEmpty) ...[
                      SizedBox(
                          height: (constraints.maxHeight * .13).clamp(8, 72)),
                      Center(
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            color: colors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isEs
                            ? '¿Qué quieres incluir en la factura?'
                            : 'What would you like to include in the invoice?',
                        textAlign: TextAlign.center,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isEs
                            ? 'Describe el trabajo o adjunta una imagen o PDF. Podrás revisar cada línea antes de añadirla.'
                            : 'Describe the work or attach an image or PDF. You can review every line before adding it.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final prompt in prompts)
                            ActionChip(
                              label: Text(prompt),
                              onPressed: _sending
                                  ? null
                                  : () {
                                      _message.text = prompt;
                                      _message.selection =
                                          TextSelection.collapsed(
                                        offset: _message.text.length,
                                      );
                                      _messageFocus.requestFocus();
                                    },
                            ),
                        ],
                      ),
                    ] else
                      for (final item in _messages)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: item['role'] == 'user'
                              ? Align(
                                  alignment: Alignment.centerRight,
                                  child: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 560),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 11,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colors.surfaceContainerHigh,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(item['text'] ?? ''),
                                    ),
                                  ),
                                )
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: colors.primaryContainer,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.auto_awesome_rounded,
                                        size: 16,
                                        color: colors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: SelectableText(
                                          item['text'] ?? '',
                                          style: textTheme.bodyMedium?.copyWith(
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                  ],
                ),
              ),
            ),
          ),
          if (_error != null)
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colors.errorContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(color: colors.onErrorContainer),
                  ),
                ),
              ),
            ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Container(
                key: const ValueKey('invoice-ai-composer'),
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: colors.outlineVariant.withValues(alpha: .7),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow.withValues(alpha: .08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    if (_file != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(children: [
                          if (!_file!.fileName.toLowerCase().endsWith('.pdf'))
                            ClipRRect(
                              borderRadius: BorderRadius.circular(7),
                              child: Image.memory(
                                Uint8List.fromList(_file!.bytes),
                                width: 34,
                                height: 34,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.image_not_supported_outlined,
                                ),
                              ),
                            )
                          else
                            const Icon(Icons.picture_as_pdf_outlined),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _file!.fileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            tooltip: isEs ? 'Quitar archivo' : 'Remove file',
                            onPressed: _sending
                                ? null
                                : () => setState(() => _file = null),
                            icon: const Icon(Icons.close, size: 18),
                          ),
                        ]),
                      ),
                    TextField(
                      controller: _message,
                      focusNode: _messageFocus,
                      minLines: 1,
                      maxLines: 5,
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        hintText: isEs
                            ? 'Escribe cómo quieres crear la factura...'
                            : 'Describe how you want to create the invoice...',
                        contentPadding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                    Row(children: [
                      IconButton(
                        tooltip: isEs
                            ? 'Adjuntar imagen o PDF'
                            : 'Attach image or PDF',
                        onPressed: _sending ? null : _pickFile,
                        icon: const Icon(Icons.add_rounded),
                      ),
                      if (_file == null)
                        Text(
                          isEs ? 'Imagen o PDF' : 'Image or PDF',
                          style: textTheme.labelMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      const Spacer(),
                      IconButton.filled(
                        tooltip: isEs ? 'Enviar' : 'Send',
                        onPressed: _sending ? null : _send,
                        icon: _sending
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colors.onPrimary,
                                ),
                              )
                            : const Icon(Icons.arrow_upward_rounded),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isEs
                ? 'Revisa siempre las líneas antes de añadirlas al borrador.'
                : 'Always review the lines before adding them to the draft.',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
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
                    for (final line in _suggestedLines.take(3))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          '• ${line.description}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    if (_suggestedLines.length > 3)
                      Text(
                        isEs
                            ? 'Y ${_suggestedLines.length - 3} líneas más'
                            : 'And ${_suggestedLines.length - 3} more lines',
                        style: Theme.of(context).textTheme.bodySmall,
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
              label: Text(isEs
                  ? 'Confirmar y editar líneas'
                  : 'Confirm and edit lines'),
            ),
            TextButton.icon(
              onPressed: () =>
                  FocusScope.of(context).requestFocus(_messageFocus),
              icon: const Icon(Icons.chat_bubble_outline),
              label: Text(isEs ? 'Corregir con el chat' : 'Correct with chat'),
            ),
          ] else ...[
            Expanded(
              child: SingleChildScrollView(
                child: InvoiceLinesEditor(
                  key: ObjectKey(_editableLines),
                  lines: _editableLines,
                  onChanged: _syncEditedLines,
                  showDiscount: false,
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
    final content = Padding(
      padding: EdgeInsets.all(widget.embedded ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!widget.embedded) ...[
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
                onPressed: _sending ? null : () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ]),
            const SizedBox(height: 4),
            Text(isEs
                ? 'Escribe o adjunta un archivo a la izquierda y edita las líneas de la factura a la derecha.'
                : 'Write or attach a file on the left and edit the invoice lines on the right.'),
            const SizedBox(height: 16),
          ],
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 980) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 6, child: _buildChatPane(context, isEs)),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 5,
                        child: _buildInvoicePreview(context, isEs),
                      ),
                    ],
                  );
                }
                return DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      TabBar(
                        dividerColor: Colors.transparent,
                        tabs: [
                          Tab(text: isEs ? 'Conversación' : 'Conversation'),
                          Tab(text: isEs ? 'Borrador' : 'Draft'),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildChatPane(context, isEs),
                            _buildInvoicePreview(context, isEs),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            if (!widget.embedded)
              TextButton(
                onPressed: _sending ? null : () => Navigator.of(context).pop(),
                child: Text(isEs ? 'Cancelar' : 'Cancel'),
              ),
            const Spacer(),
            FilledButton.icon(
              onPressed: _sending || !_showEditor || !_canApply ? null : _apply,
              icon: const Icon(Icons.playlist_add_check),
              label: Text(isEs ? 'Añadir al borrador' : 'Add to draft'),
            ),
          ]),
        ],
      ),
    );

    if (widget.embedded) {
      return KeyedSubtree(
        key: const ValueKey('invoice-ai-inline-editor'),
        child: content,
      );
    }

    return Dialog(
      insetPadding: const EdgeInsets.all(12),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: screen.width < 820 ? screen.width - 24 : 1100,
          maxHeight: screen.height * 0.9,
        ),
        child: content,
      ),
    );
  }
}
