import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/sections/invoice_editor_controller.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/sections/invoice_editor_pdf.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/widgets/invoice_form_sheet/invoice_lines_editor.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/widgets/pdf_preview/pdf_preview_launcher.dart'
    as pdf_launcher;
import 'package:hexora/presentation/shared/widgets/buttons/hexora_button.dart';
import 'package:hexora/services/invoicing/invoice_api.dart';
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

class _InvoiceAiChatDialogState extends State<InvoiceAiChatDialog>
    with SingleTickerProviderStateMixin {
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
  bool _savingDraft = false;
  bool _draftSaved = false;
  bool _appliedToEditor = false;
  bool _draftCollapsed = false;
  bool _draftHasUnseenUpdate = false;
  bool _wideWorkspace = false;
  String? _previewingInvoiceId;
  late final TabController _compactTabs;

  bool get _isSpanish => Localizations.localeOf(context).languageCode == 'es';
  bool get _chatLocked => _sending || _savingDraft || _appliedToEditor;

  @override
  void initState() {
    super.initState();
    _compactTabs = TabController(length: 2, vsync: this)
      ..addListener(_handleCompactTabChanged);
    _conversationScroll.addListener(_trackConversationPosition);
  }

  void _handleCompactTabChanged() {
    if (_compactTabs.index != 1 || _compactTabs.indexIsChanging) return;
    if (_draftHasUnseenUpdate && mounted) {
      setState(() => _draftHasUnseenUpdate = false);
    }
  }

  @override
  void dispose() {
    _message.dispose();
    _messageFocus.dispose();
    _compactTabs
      ..removeListener(_handleCompactTabChanged)
      ..dispose();
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
      priceReference: source?.description == edited.description &&
              source?.unitPrice == unitPrice
          ? source?.priceReference
          : null,
    );
  }

  bool get _canApply =>
      _editableLines.isNotEmpty &&
      _editableLines.every((line) =>
          line.toLine().description.trim().isNotEmpty &&
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
    if (_chatLocked || (text.isEmpty && _file == null)) return;
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
          _draftSaved = false;
          _appliedToEditor = false;
          _draftCollapsed = false;
          _draftHasUnseenUpdate = !_wideWorkspace;
        }
        final visibleDraftLines = response.requiresSingleInvoice
            ? const <OcrExtractedLineDraft>[]
            : _suggestedLines;
        final responseTotal = visibleDraftLines
            .where(_isCompleteLine)
            .fold<double>(0, (sum, line) => sum + line.lineTotal);
        _messages.add({
          'role': 'assistant',
          'text': response.reply,
          'status': response.requiresSingleInvoice || reviewCount > 0
              ? 'warning'
              : 'processed',
          if (!response.requiresSingleInvoice)
            'lineCount': visibleDraftLines.length.toString(),
          if (!response.requiresSingleInvoice)
            'total': responseTotal.toString(),
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

  void _revealDraft() {
    if (_wideWorkspace) {
      setState(() {
        _draftCollapsed = false;
        _draftHasUnseenUpdate = false;
      });
      return;
    }
    setState(() => _draftHasUnseenUpdate = false);
    _compactTabs.animateTo(1);
  }

  void _requestChanges() {
    if (!_wideWorkspace) _compactTabs.animateTo(0);
    _messageFocus.requestFocus();
  }

  Future<void> _apply() async {
    if (!_showEditor || !_canApply || _savingDraft || _draftSaved) return;
    final isEs = _isSpanish;
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _savingDraft = true;
      _error = null;
    });
    try {
      if (!_appliedToEditor) {
        widget.controller.applyAiSuggestedLines(_suggestedLines);
        _appliedToEditor = true;
      }
      await widget.controller.saveAiDraft(context);
      if (!mounted) return;
      setState(() => _draftSaved = true);
      if (!widget.embedded) Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(
        content: Text(isEs ? 'Borrador guardado.' : 'Draft saved.'),
      ));
    } catch (error) {
      if (!mounted) return;
      final message = _appliedToEditor
          ? (isEs
              ? 'Las líneas están en el editor, pero no se guardó el borrador. Corrige los datos y vuelve a guardar: $error'
              : 'The lines are in the editor, but the draft was not saved. Correct the details and save again: $error')
          : error.toString();
      setState(() => _error = message);
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _savingDraft = false);
    }
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
                  onPressed: _chatLocked
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
    final total = double.tryParse(item['total'] ?? '');
    final reviewCount = int.tryParse(item['reviewCount'] ?? '') ?? 0;
    final warning = status == 'warning';
    const statusColor = Color(0xFFD97706);

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
              if (warning && lineCount == null)
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
                      const Icon(Icons.warning_amber_rounded,
                          size: 13, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        isEs ? 'Requiere revisión' : 'Needs review',
                        style: textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              if (lineCount != null) ...[
                InkWell(
                  key: const ValueKey('invoice-ai-conversation-preview'),
                  onTap: lineCount > 0 ? _revealDraft : null,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(10, 9, 8, 9),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer.withValues(alpha: .28),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: colors.primary.withValues(alpha: .2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.receipt_long_outlined,
                              size: 18, color: colors.primary),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEs ? 'Borrador de factura' : 'Invoice draft',
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                isEs
                                    ? '$lineCount líneas detectadas'
                                    : '$lineCount lines detected',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (total != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              _formatMoney(total),
                              style: textTheme.bodyMedium?.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.w800,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(left: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isEs ? 'Revisar' : 'Review',
                                style: textTheme.labelMedium?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded,
                                  size: 18, color: colors.primary),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (reviewCount > 0) ...[
                  const SizedBox(height: 5),
                  Text(
                    isEs
                        ? '$reviewCount conceptos necesitan revisión por falta de datos.'
                        : '$reviewCount items need review because data is missing.',
                    style: textTheme.bodySmall?.copyWith(color: statusColor),
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
              if (lineCount == null &&
                  (item['text'] ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 5),
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

  String _composerHint(bool isEs) {
    if (_file != null) {
      return isEs
          ? 'Describe qué quieres extraer de este documento...'
          : 'Describe what to extract from this document...';
    }
    if (_suggestedLines.isNotEmpty) {
      return isEs
          ? 'Pide a la IA que modifique tu factura...'
          : 'Ask AI to modify your invoice...';
    }
    return isEs
        ? 'Describe la factura que quieres crear...'
        : 'Describe the invoice you want to create...';
  }

  String _attachmentTypeLabel(String fileName, bool isEs) {
    final dot = fileName.lastIndexOf('.');
    final extension = dot < 0 ? '' : fileName.substring(dot + 1).toUpperCase();
    if (extension == 'PDF') {
      return isEs ? 'Documento PDF' : 'PDF document';
    }
    if (extension.isEmpty) return isEs ? 'Archivo adjunto' : 'Attached file';
    return isEs ? 'Imagen $extension' : '$extension image';
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
                      Icon(Icons.error_outline, size: 18, color: colors.error),
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
                          onPressed: _chatLocked ? null : _send,
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
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.white
                      : colors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: colors.outlineVariant.withValues(alpha: .65),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow.withValues(alpha: .035),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_file != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
                        decoration: BoxDecoration(
                          color: colors.primaryContainer.withValues(alpha: .22),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Row(children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Icon(
                              _file!.fileName.toLowerCase().endsWith('.pdf')
                                  ? Icons.picture_as_pdf_outlined
                                  : Icons.image_outlined,
                              size: 18,
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _file!.fileName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  _attachmentTypeLabel(_file!.fileName, isEs),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: isEs ? 'Quitar archivo' : 'Remove file',
                            onPressed: _chatLocked
                                ? null
                                : () => setState(() => _file = null),
                            constraints: const BoxConstraints.tightFor(
                              width: 30,
                              height: 30,
                            ),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.close_rounded, size: 17),
                          ),
                        ]),
                      ),
                    CallbackShortcuts(
                      bindings: {
                        const SingleActivator(LogicalKeyboardKey.enter): _send,
                      },
                      child: TextField(
                        controller: _message,
                        focusNode: _messageFocus,
                        enabled: !_chatLocked,
                        minLines: 1,
                        maxLines: 6,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        style: textTheme.bodySmall?.copyWith(height: 1.35),
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          filled: false,
                          hintText: _composerHint(isEs),
                          hintStyle: textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                          contentPadding: const EdgeInsets.fromLTRB(3, 4, 3, 7),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          tooltip: isEs
                              ? 'Adjuntar imagen o PDF'
                              : 'Attach image or PDF',
                          onPressed: _chatLocked ? null : _pickFile,
                          icon: const Icon(Icons.attach_file_rounded, size: 18),
                          constraints: const BoxConstraints.tightFor(
                            width: 32,
                            height: 32,
                          ),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                        Tooltip(
                          message: _suggestedLines.isEmpty
                              ? (isEs
                                  ? 'Puedes describir trabajos o adjuntar una imagen o PDF.'
                                  : 'Describe work or attach an image or PDF.')
                              : (isEs
                                  ? 'Pide cambios antes de guardar el borrador.'
                                  : 'Request changes before saving the draft.'),
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: Icon(
                              Icons.info_outline_rounded,
                              size: 17,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 4),
                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _message,
                          builder: (context, value, _) {
                            final canSend = !_chatLocked &&
                                (value.text.trim().isNotEmpty || _file != null);
                            return IconButton.filled(
                              tooltip: isEs ? 'Enviar' : 'Send',
                              onPressed: canSend ? _send : null,
                              constraints: const BoxConstraints.tightFor(
                                width: 34,
                                height: 34,
                              ),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              style: IconButton.styleFrom(
                                backgroundColor: canSend
                                    ? colors.primary
                                    : colors.onSurface.withValues(alpha: .08),
                                foregroundColor: canSend
                                    ? colors.onPrimary
                                    : colors.onSurfaceVariant
                                        .withValues(alpha: .55),
                                disabledBackgroundColor: _sending
                                    ? colors.primary.withValues(alpha: .72)
                                    : colors.onSurface.withValues(alpha: .08),
                                disabledForegroundColor: _sending
                                    ? colors.onPrimary
                                    : colors.onSurfaceVariant
                                        .withValues(alpha: .55),
                              ),
                              icon: _sending
                                  ? SizedBox(
                                      width: 15,
                                      height: 15,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: colors.onPrimary,
                                      ),
                                    )
                                  : const Icon(Icons.arrow_upward_rounded,
                                      size: 18),
                            );
                          },
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

  Future<void> _previewReference(InvoicePriceReference reference) async {
    setState(() => _previewingInvoiceId = reference.invoiceId);
    try {
      final response = await InvoicesApi().previewPdf(reference.invoiceId);
      final bytes = InvoiceEditorPdf.validatePdf(response);
      await pdf_launcher.launchPdfPreview(
        bytes,
        fileName:
            'invoice-${reference.invoiceNumber ?? reference.invoiceId}.pdf',
      );
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
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final date = reference.issueDate;
    final dateLabel = date == null
        ? ''
        : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    final number = reference.invoiceNumber;
    final invoiceLabel = number == null || number.isEmpty
        ? (isEs ? 'Factura anterior' : 'Earlier invoice')
        : '${isEs ? 'Factura' : 'Invoice'} $number';
    final source = <String>[
      invoiceLabel,
      if (dateLabel.isNotEmpty) dateLabel,
      if (reference.invoiceConcept.trim().isNotEmpty)
        reference.invoiceConcept.trim(),
      _formatMoney(reference.unitPrice),
    ].join(' · ');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 5, bottom: 3),
      padding: const EdgeInsets.fromLTRB(9, 7, 5, 5),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: .65),
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEs
                ? 'Precio sugerido por coincidencia con «${reference.matchedConcept}» en una factura emitida del mismo cliente.'
                : 'Price suggested because “${reference.matchedConcept}” matches an issued invoice for this client.',
            style: textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            source,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelSmall?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextButton.icon(
            onPressed: _previewingInvoiceId == null
                ? () => _previewReference(reference)
                : null,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              minimumSize: const Size(0, 28),
            ),
            icon: _previewingInvoiceId == reference.invoiceId
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf_outlined, size: 16),
            label: Text(
                isEs ? 'Ver factura de referencia' : 'Preview source invoice'),
          ),
        ],
      ),
    );
  }

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

    final lineSummary = SizedBox(
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        lineSummary,
        if (line.priceReference != null)
          _referenceDetails(line.priceReference!, isEs),
      ],
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

  Widget _buildInvoicePreview(
    BuildContext context,
    bool isEs, {
    bool canCollapse = false,
  }) {
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
              if (canCollapse) ...[
                const SizedBox(width: 4),
                IconButton(
                  key: const ValueKey('invoice-ai-collapse-draft'),
                  tooltip: isEs ? 'Ocultar borrador' : 'Hide draft',
                  onPressed: () => setState(() => _draftCollapsed = true),
                  visualDensity: VisualDensity.compact,
                  constraints:
                      const BoxConstraints.tightFor(width: 30, height: 30),
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.chevron_right_rounded, size: 18),
                ),
              ],
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InvoiceLinesEditor(
                      key: ObjectKey(_editableLines),
                      lines: _editableLines,
                      onChanged: _syncEditedLines,
                      showDiscount: false,
                    ),
                    for (final line in _suggestedLines)
                      if (line.priceReference != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          '${isEs ? 'Línea' : 'Line'} ${line.position}: ${line.description}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        _referenceDetails(line.priceReference!, isEs),
                      ],
                  ],
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
                TextButton.icon(
                  key: const ValueKey('invoice-ai-request-changes'),
                  onPressed: _sending || _savingDraft ? null : _requestChanges,
                  icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                  label: Text(isEs
                      ? 'Pedir cambios a la IA'
                      : 'Request changes with AI'),
                ),
                if (!_showEditor)
                  HexoraButton(
                    key: const ValueKey('invoice-ai-confirm-action'),
                    onPressed: _sending || _savingDraft
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
                    onPressed:
                        _sending || _savingDraft || _draftSaved || !_canApply
                            ? null
                            : _apply,
                    label: _draftSaved
                        ? (isEs ? 'Borrador guardado' : 'Draft saved')
                        : (isEs ? 'Guardar como borrador' : 'Save as draft'),
                    icon:
                        _draftSaved ? Icons.check_rounded : Icons.save_outlined,
                    loading: _savingDraft,
                    size: HexoraButtonSize.compact,
                  ),
              ],
            ),
          ],
        ],
      ),
    );

    // The editor can contain several extracted lines. Keep its actions inside
    // the available right-hand workspace instead of overflowing beneath the
    // invoice flow footer.
    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 12),
        child: Align(alignment: Alignment.topCenter, child: panel),
      ),
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
          ],
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 980;
                _wideWorkspace = wide;
                final hasDraft = _suggestedLines.isNotEmpty;
                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: hasDraft && !_draftCollapsed ? 2 : 1,
                        child: _buildChatPane(context, isEs),
                      ),
                      if (hasDraft) ...[
                        VerticalDivider(
                          width: 13,
                          thickness: 1,
                          color: Theme.of(context)
                              .colorScheme
                              .outlineVariant
                              .withValues(alpha: .55),
                        ),
                        if (_draftCollapsed)
                          SizedBox(
                            width: 42,
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: IconButton.filledTonal(
                                key: const ValueKey('invoice-ai-expand-draft'),
                                tooltip:
                                    isEs ? 'Mostrar borrador' : 'Show draft',
                                onPressed: _revealDraft,
                                icon: const Icon(Icons.chevron_left_rounded,
                                    size: 19),
                              ),
                            ),
                          )
                        else
                          Expanded(
                            flex: 3,
                            child: _buildInvoicePreview(
                              context,
                              isEs,
                              canCollapse: true,
                            ),
                          ),
                      ],
                    ],
                  );
                }
                return Column(
                  children: [
                    SizedBox(
                      height: 38,
                      child: TabBar(
                        controller: _compactTabs,
                        dividerColor: Colors.transparent,
                        tabAlignment: TabAlignment.center,
                        isScrollable: true,
                        labelPadding:
                            const EdgeInsets.symmetric(horizontal: 14),
                        tabs: [
                          Tab(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.chat_bubble_outline_rounded,
                                    size: 17),
                                const SizedBox(width: 6),
                                Text(isEs ? 'Conversación' : 'Conversation'),
                              ],
                            ),
                          ),
                          Tab(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.receipt_long_outlined,
                                    size: 17),
                                const SizedBox(width: 6),
                                Text(isEs ? 'Borrador' : 'Draft'),
                                if (hasDraft) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: _draftHasUnseenUpdate
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Theme.of(context)
                                              .colorScheme
                                              .surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      '${_suggestedLines.length}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: _draftHasUnseenUpdate
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .onPrimary
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: TabBarView(
                        controller: _compactTabs,
                        children: [
                          _buildChatPane(context, isEs),
                          _buildInvoicePreview(context, isEs),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          if (!widget.embedded) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _sending || _savingDraft
                    ? null
                    : () => Navigator.of(context).pop(),
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
