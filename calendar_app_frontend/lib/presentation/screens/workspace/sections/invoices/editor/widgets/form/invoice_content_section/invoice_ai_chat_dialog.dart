import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/sections/invoice_editor_controller.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/widgets/invoice_form_sheet/invoice_lines_editor.dart';
import 'package:hexora/presentation/shared/widgets/buttons/hexora_button.dart';
import 'package:hexora/services/invoicing/invoice_lines_ocr_models.dart';
import 'package:hexora/services/invoicing/invoice_lines_ocr_service.dart';
import 'package:intl/intl.dart';

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
  final _conversationScroll = ScrollController();
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
  bool _conversationNearBottom = true;

  bool get _isSpanish => Localizations.localeOf(context).languageCode == 'es';

  @override
  void initState() {
    super.initState();
    _conversationScroll.addListener(_trackConversationPosition);
  }

  @override
  void dispose() {
    _message.dispose();
    _messageFocus.dispose();
    _conversationScroll
      ..removeListener(_trackConversationPosition)
      ..dispose();
    for (final line in _ownedLines) {
      line.dispose();
    }
    super.dispose();
  }

  void _trackConversationPosition() {
    if (!_conversationScroll.hasClients) return;
    _conversationNearBottom = _conversationScroll.position.maxScrollExtent -
            _conversationScroll.position.pixels <
        96;
  }

  void _scrollToLatestIfNeeded(bool wasNearBottom) {
    if (!wasNearBottom) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_conversationScroll.hasClients) return;
      _conversationScroll.animateTo(
        _conversationScroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
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

  List<Map<String, String>> _apiConversationHistory() {
    final recent = _messages.length <= 12
        ? _messages
        : _messages.sublist(_messages.length - 12);
    return [
      for (final message in recent)
        {
          'role': message['role'] ?? 'assistant',
          'text': message['text'] ?? '',
        },
    ];
  }

  Future<void> _send() async {
    final text = _message.text.trim();
    if (_sending || (text.isEmpty && _file == null)) return;
    final followConversation = _conversationNearBottom;
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
          'status': 'warning',
        });
        _message.clear();
        _requiresSingleInvoice = true;
      });
      _scrollToLatestIfNeeded(followConversation);
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    _scrollToLatestIfNeeded(followConversation);
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
        history: _apiConversationHistory(),
        locale: _isSpanish ? 'es' : 'en',
        file: _file,
      );
      if (!mounted) return;
      final concurrentEdits = sentValues.entries.any((entry) =>
              _editableLines.contains(entry.key) &&
              !_sameFields(_fieldValues(entry.key), entry.value)) ||
          _editableLines.any((draft) => !sentValues.containsKey(draft)) ||
          sentDrafts.any((draft) => !_editableLines.contains(draft));
      final reviewCount = response.draftLines.where((line) {
        return line.description.trim().isEmpty ||
            line.quantity <= 0 ||
            line.unitPrice <= 0 ||
            line.taxRate < 0 ||
            line.needsPrice;
      }).length;
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
        _messages.add({
          'role': 'assistant',
          'text': response.reply,
          'status': response.requiresSingleInvoice || reviewCount > 0
              ? 'warning'
              : 'processed',
          if (!response.requiresSingleInvoice)
            'lineCount': response.draftLines.length.toString(),
          if (!response.requiresSingleInvoice)
            'reviewCount': reviewCount.toString(),
          if (concurrentEdits) 'concurrentEdits': 'true',
        });
        _message.clear();
        _file = null;
      });
      _scrollToLatestIfNeeded(followConversation);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error is OcrExtractionException
          ? error.userMessage
          : error.toString().replaceFirst('Exception: ', ''));
      _scrollToLatestIfNeeded(followConversation);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _apply() {
    if (!_showEditor || !_canApply) return;
    widget.controller.applyAiSuggestedLines(_suggestedLines);
    if (!widget.embedded) Navigator.of(context).pop();
  }

  void _focusAiChat(BuildContext actionContext) {
    DefaultTabController.maybeOf(actionContext)?.animateTo(0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _messageFocus.requestFocus();
    });
  }

  Widget _buildInitialChatState(bool isEs) {
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 26, color: colors.primary),
          const SizedBox(height: 10),
          Text(
            isEs
                ? '¿Qué quieres incluir en la factura?'
                : 'What would you like to include in the invoice?',
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            isEs
                ? 'Describe los trabajos o adjunta una imagen o PDF.'
                : 'Describe the work or attach an image or PDF.',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final prompt in prompts)
                ActionChip(
                  visualDensity: VisualDensity.compact,
                  label: Text(prompt),
                  onPressed: _sending
                      ? null
                      : () {
                          _message.text = prompt;
                          _message.selection = TextSelection.collapsed(
                            offset: _message.text.length,
                          );
                          _messageFocus.requestFocus();
                        },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAssistantMessage(Map<String, String> item, bool isEs) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final status = item['status'];
    final lineCount = int.tryParse(item['lineCount'] ?? '');
    final reviewCount = int.tryParse(item['reviewCount'] ?? '') ?? 0;
    final warning = status == 'warning';
    final processed = status == 'processed';
    final statusColor =
        warning ? const Color(0xFFD97706) : const Color(0xFF15803D);
    final statusLabel = warning
        ? (isEs ? 'Requiere revisión' : 'Needs review')
        : (isEs ? 'Procesado' : 'Processed');
    final statusIcon = warning
        ? Icons.warning_amber_rounded
        : Icons.check_circle_outline_rounded;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child:
              Icon(Icons.auto_awesome_rounded, size: 18, color: colors.primary),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (warning || processed)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 13, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              if (lineCount != null) ...[
                const SizedBox(height: 7),
                Text(
                  isEs
                      ? 'Factura procesada · $lineCount conceptos detectados'
                      : 'Invoice processed · $lineCount items detected',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (reviewCount > 0) ...[
                  const SizedBox(height: 3),
                  Text(
                    isEs
                        ? '$reviewCount conceptos necesitan revisión por falta de datos.'
                        : '$reviewCount items need review because data is missing.',
                    style: textTheme.bodySmall?.copyWith(color: statusColor),
                  ),
                ],
                if (lineCount > 0) ...[
                  const SizedBox(height: 3),
                  Text(
                    isEs
                        ? 'Revisa las líneas en el panel derecho o indícame qué deseas corregir.'
                        : 'Review the lines in the right panel or tell me what to correct.',
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
              if (item['concurrentEdits'] == 'true') ...[
                const SizedBox(height: 4),
                Text(
                  isEs
                      ? 'Se conservaron tus cambios mientras respondía.'
                      : 'Your edits were preserved while the AI responded.',
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
              if ((item['text'] ?? '').trim().isNotEmpty) ...[
                SizedBox(height: lineCount == null ? 5 : 3),
                InvoiceAiAssistantDetail(
                  text: item['text']!,
                  isSpanish: isEs,
                  initiallyExpanded: lineCount == null,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProcessingIndicator(bool isEs) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      key: const ValueKey('invoice-ai-processing-indicator'),
      children: [
        SizedBox(
          width: 14,
          height: 14,
          child:
              CircularProgressIndicator(strokeWidth: 2, color: colors.primary),
        ),
        const SizedBox(width: 8),
        Text(
          isEs ? 'Analizando...' : 'Analyzing...',
          style: textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildChatPane(BuildContext context, bool isEs) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: ListView(
                  key: const ValueKey('invoice-ai-conversation'),
                  controller: _conversationScroll,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  children: [
                    if (_messages.isEmpty) _buildInitialChatState(isEs),
                    for (final item in _messages)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: item['role'] == 'user'
                            ? InvoiceAiUserMessageBubble(
                                text: item['text'] ?? '',
                                isSpanish: isEs,
                              )
                            : _buildAssistantMessage(item, isEs),
                      ),
                    if (_sending)
                      Padding(
                        padding: const EdgeInsets.only(top: 2, bottom: 8),
                        child: _buildProcessingIndicator(isEs),
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
                    color: colors.errorContainer.withValues(alpha: .65),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, size: 17, color: colors.error),
                      const SizedBox(width: 7),
                      Text(
                        isEs ? 'Error' : 'Error',
                        style: textTheme.labelMedium?.copyWith(
                          color: colors.error,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          _error!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.onErrorContainer,
                          ),
                        ),
                      ),
                      if (_message.text.trim().isNotEmpty || _file != null)
                        TextButton(
                          onPressed: _sending ? null : _send,
                          child: Text(isEs ? 'Reintentar' : 'Retry'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Container(
                key: const ValueKey('invoice-ai-composer'),
                margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colors.outlineVariant.withValues(alpha: .7),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow.withValues(alpha: .05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        IconButton(
                          tooltip: isEs
                              ? 'Adjuntar imagen o PDF'
                              : 'Attach image or PDF',
                          onPressed: _sending ? null : _pickFile,
                          icon: const Icon(Icons.attach_file_rounded, size: 19),
                          constraints: const BoxConstraints.tightFor(
                            width: 36,
                            height: 36,
                          ),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                        Expanded(
                          child: CallbackShortcuts(
                            bindings: {
                              const SingleActivator(LogicalKeyboardKey.enter):
                                  _send,
                            },
                            child: TextField(
                              controller: _message,
                              focusNode: _messageFocus,
                              minLines: 1,
                              maxLines: 5,
                              keyboardType: TextInputType.multiline,
                              textInputAction: TextInputAction.newline,
                              style: textTheme.bodySmall,
                              decoration: InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                hintText: isEs
                                    ? 'Escribe cómo quieres crear la factura...'
                                    : 'Describe how you want to create the invoice...',
                                contentPadding:
                                    const EdgeInsets.fromLTRB(4, 7, 4, 7),
                              ),
                            ),
                          ),
                        ),
                        if (_suggestedLines.isNotEmpty)
                          Tooltip(
                            message: isEs
                                ? 'Revisa las líneas antes de añadirlas al borrador.'
                                : 'Review the lines before adding them to the draft.',
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Icon(
                                Icons.info_outline_rounded,
                                size: 16,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        const SizedBox(width: 4),
                        IconButton.filled(
                          tooltip: isEs ? 'Enviar' : 'Send',
                          onPressed: _sending ? null : _send,
                          constraints: const BoxConstraints.tightFor(
                            width: 36,
                            height: 36,
                          ),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          icon: _sending
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colors.onPrimary,
                                  ),
                                )
                              : const Icon(Icons.arrow_upward_rounded,
                                  size: 19),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isCompleteLine(OcrExtractedLineDraft line) =>
      line.description.trim().isNotEmpty &&
      line.quantity > 0 &&
      line.unitPrice > 0 &&
      line.taxRate >= 0 &&
      !line.needsPrice;

  String _formatMoney(double amount) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final currency = widget.controller.currency.text.trim().toUpperCase();
    return NumberFormat.simpleCurrency(
      locale: locale,
      name: currency.isEmpty ? 'EUR' : currency,
    ).format(amount);
  }

  String _formatNumber(double value) => NumberFormat(
        '0.##',
        Localizations.localeOf(context).toLanguageTag(),
      ).format(value);

  Widget _buildProposedLine(OcrExtractedLineDraft line, bool isEs) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final complete = _isCompleteLine(line);
    final description = line.description.trim().isEmpty
        ? (isEs ? 'Concepto sin descripción' : 'Description missing')
        : line.description.trim();
    final details = <String>[
      if (line.quantity > 0)
        '${isEs ? 'Cant.' : 'Qty'} ${_formatNumber(line.quantity)}',
      if (line.unitPrice > 0) '× ${_formatMoney(line.unitPrice)}',
      if (line.taxRate == 0)
        isEs ? 'Exento' : 'Exempt'
      else if (line.taxRate > 0)
        '${isEs ? 'IVA' : 'VAT'} ${_formatNumber(line.taxRate)}%',
    ];

    return SizedBox(
      height: 48,
      child: Row(
        children: [
          Expanded(
            child: Tooltip(
              message: description,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: line.description.trim().isEmpty
                          ? colors.tertiary
                          : colors.onSurface,
                    ),
                  ),
                  if (details.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      details.join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          if (complete)
            Text(
              _formatMoney(line.lineTotal),
              textAlign: TextAlign.right,
              style: textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            )
          else
            Tooltip(
              message: isEs
                  ? 'Faltan datos para calcular esta línea'
                  : 'Missing data for this line',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 15, color: colors.tertiary),
                  const SizedBox(width: 4),
                  Text(
                    isEs ? 'Pendiente' : 'Pending',
                    style: textTheme.labelMedium?.copyWith(
                      color: colors.tertiary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _totalRow(String label, double amount, {bool strong = false}) {
    final colors = Theme.of(context).colorScheme;
    final style = (strong
            ? Theme.of(context).textTheme.titleSmall
            : Theme.of(context).textTheme.bodySmall)
        ?.copyWith(
      fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
      color: strong ? colors.onSurface : colors.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(_formatMoney(amount), style: style),
        ],
      ),
    );
  }

  Widget _buildInvoicePreview(BuildContext context, bool isEs) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final completeLines = _suggestedLines.where(_isCompleteLine).toList();
    final hasIncomplete = completeLines.length != _suggestedLines.length;
    final subtotal = completeLines.fold<double>(
      0,
      (sum, line) => sum + line.lineSubtotal,
    );
    final tax =
        completeLines.fold<double>(0, (sum, line) => sum + line.lineTax);
    final total =
        completeLines.fold<double>(0, (sum, line) => sum + line.lineTotal);
    final taxRates = completeLines.map((line) => line.taxRate).toSet().toList()
      ..sort();
    final taxLabel = taxRates.isEmpty
        ? (isEs ? 'IVA' : 'VAT')
        : '${isEs ? 'IVA' : 'VAT'} (${taxRates.map((rate) => '${_formatNumber(rate)}%').join(', ')})';
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final linesMaxHeight = (viewportHeight * .32).clamp(120.0, 320.0);
    final editorMaxHeight = (viewportHeight * .42).clamp(200.0, 420.0);

    final panel = Container(
      key: const ValueKey('invoice-ai-summary-panel'),
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: .75),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 18,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  _showEditor
                      ? (isEs ? 'Editar líneas' : 'Edit invoice lines')
                      : (isEs ? 'Resumen de factura' : 'Invoice summary'),
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                isEs
                    ? '${_suggestedLines.length} líneas'
                    : '${_suggestedLines.length} lines',
                style: textTheme.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          if (_sending) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: colors.primaryContainer.withValues(alpha: .35),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isEs ? 'Analizando conceptos...' : 'Analyzing items...',
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: colors.errorContainer.withValues(alpha: .55),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline, size: 16, color: colors.error),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      _error!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          if (_suggestedLines.isEmpty && !_showEditor)
            SizedBox(
              height: 116,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 340),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.format_list_bulleted_rounded,
                        size: 24,
                        color: colors.onSurfaceVariant.withValues(alpha: .7),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        _requiresSingleInvoice
                            ? (isEs
                                ? 'Envía una sola factura'
                                : 'Send one invoice')
                            : (isEs ? 'Sin líneas todavía' : 'No lines yet'),
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _requiresSingleInvoice
                            ? (isEs
                                ? 'Procesa una factura cada vez para preparar sus líneas.'
                                : 'Process one invoice at a time to prepare its lines.')
                            : (isEs
                                ? 'Describe los trabajos o adjunta un archivo para generar las líneas.'
                                : 'Describe the work or attach a file to generate invoice lines.'),
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (!_showEditor)
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: linesMaxHeight),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _suggestedLines.length,
                itemBuilder: (_, index) =>
                    _buildProposedLine(_suggestedLines[index], isEs),
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: colors.outlineVariant.withValues(alpha: .45),
                ),
              ),
            )
          else ...[
            Text(
              isEs
                  ? 'Revisa y completa las líneas antes de añadirlas al borrador.'
                  : 'Review and complete the lines before adding them to the draft.',
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: editorMaxHeight),
              child: SingleChildScrollView(
                child: InvoiceLinesEditor(
                  key: ObjectKey(_editableLines),
                  lines: _editableLines,
                  onChanged: _syncEditedLines,
                  showDiscount: false,
                ),
              ),
            ),
          ],
          if (_suggestedLines.isNotEmpty) ...[
            const SizedBox(height: 8),
            Divider(
              height: 12,
              color: colors.outlineVariant.withValues(alpha: .55),
            ),
            if (completeLines.isNotEmpty) ...[
              if (hasIncomplete)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    isEs
                        ? 'Importes provisionales · faltan datos en algunas líneas'
                        : 'Provisional amounts · some lines are incomplete',
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.tertiary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              _totalRow(isEs ? 'Base imponible' : 'Subtotal', subtotal),
              _totalRow(taxLabel, tax),
              _totalRow(isEs ? 'Total' : 'Total', total, strong: true),
            ] else
              Text(
                isEs
                    ? 'Completa cantidades y precios para calcular los importes.'
                    : 'Complete quantities and prices to calculate amounts.',
                style: textTheme.bodySmall?.copyWith(
                  color: colors.tertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                Builder(
                  builder: (actionContext) => HexoraButton(
                    key: const ValueKey('invoice-ai-correct-action'),
                    onPressed:
                        _sending ? null : () => _focusAiChat(actionContext),
                    label: isEs ? 'Corregir con IA' : 'Correct with AI',
                    icon: Icons.chat_bubble_outline,
                    variant: HexoraButtonVariant.secondary,
                    size: HexoraButtonSize.compact,
                  ),
                ),
                if (!_showEditor)
                  HexoraButton(
                    key: const ValueKey('invoice-ai-confirm-action'),
                    onPressed: _sending
                        ? null
                        : () => setState(() => _showEditor = true),
                    label: isEs
                        ? 'Confirmar y editar líneas'
                        : 'Confirm and edit lines',
                    icon: Icons.edit_outlined,
                    size: HexoraButtonSize.compact,
                  )
                else
                  HexoraButton(
                    key: const ValueKey('invoice-ai-apply-action'),
                    onPressed: _sending || !_canApply ? null : _apply,
                    label: isEs ? 'Añadir al borrador' : 'Add to draft',
                    icon: Icons.playlist_add_check,
                    loading: _sending,
                    size: HexoraButtonSize.compact,
                  ),
              ],
            ),
          ],
        ],
      ),
    );

    return Align(alignment: Alignment.topCenter, child: panel);
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
          if (!widget.embedded) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _sending ? null : () => Navigator.of(context).pop(),
                child: Text(isEs ? 'Cancelar' : 'Cancel'),
              ),
            ),
          ],
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

class InvoiceAiUserMessageBubble extends StatefulWidget {
  const InvoiceAiUserMessageBubble({
    super.key,
    required this.text,
    required this.isSpanish,
  });

  final String text;
  final bool isSpanish;

  @override
  State<InvoiceAiUserMessageBubble> createState() =>
      _InvoiceAiUserMessageBubbleState();
}

class _InvoiceAiUserMessageBubbleState
    extends State<InvoiceAiUserMessageBubble> {
  bool _expanded = false;

  bool get _isLong =>
      widget.text.length > 300 || '\n'.allMatches(widget.text).length > 7;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final showFull = !_isLong || _expanded;

    return Align(
      alignment: Alignment.centerRight,
      heightFactor: 1,
      child: FractionallySizedBox(
        widthFactor: .82,
        alignment: Alignment.centerRight,
        child: Container(
          key: const ValueKey('invoice-ai-user-message'),
          padding: const EdgeInsets.fromLTRB(11, 8, 9, 7),
          decoration: BoxDecoration(
            color: colors.primaryContainer.withValues(alpha: .32),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 160),
                alignment: Alignment.topCenter,
                child: Text(
                  widget.text,
                  maxLines: showFull ? null : 7,
                  overflow:
                      showFull ? TextOverflow.visible : TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    height: 1.4,
                    color: colors.onSurface,
                  ),
                ),
              ),
              if (_isLong)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    key: const ValueKey('invoice-ai-user-message-toggle'),
                    onPressed: () => setState(() => _expanded = !_expanded),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: const Size(0, 28),
                    ),
                    child: Text(
                      _expanded
                          ? (widget.isSpanish ? 'Ver menos' : 'Show less')
                          : (widget.isSpanish ? 'Ver más' : 'Show more'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class InvoiceAiAssistantDetail extends StatefulWidget {
  const InvoiceAiAssistantDetail({
    super.key,
    required this.text,
    required this.isSpanish,
    required this.initiallyExpanded,
  });

  final String text;
  final bool isSpanish;
  final bool initiallyExpanded;

  @override
  State<InvoiceAiAssistantDetail> createState() =>
      _InvoiceAiAssistantDetailState();
}

class _InvoiceAiAssistantDetailState extends State<InvoiceAiAssistantDetail> {
  late bool _expanded = widget.initiallyExpanded;

  bool get _canToggle => !widget.initiallyExpanded || widget.text.length > 260;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_expanded)
          SelectableText(
            widget.text,
            style: textTheme.bodySmall?.copyWith(
              height: 1.45,
              color: colors.onSurfaceVariant,
            ),
          ),
        if (_canToggle)
          TextButton(
            key: const ValueKey('invoice-ai-assistant-detail-toggle'),
            onPressed: () => setState(() => _expanded = !_expanded),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 28),
            ),
            child: Text(
              _expanded
                  ? (widget.isSpanish ? 'Ocultar detalle' : 'Hide detail')
                  : (widget.isSpanish ? 'Ver detalle' : 'View detail'),
            ),
          ),
      ],
    );
  }
}
