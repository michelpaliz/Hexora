part of '../invoice_email_widgets.dart';

class SendInvoiceSheet extends StatefulWidget {
  final Invoice invoice;
  final GroupClient client;
  final EmailApi emailApi;
  final String pdfLink;
  final Future<void> Function() onSent;

  const SendInvoiceSheet({
    super.key,
    required this.invoice,
    required this.client,
    required this.emailApi,
    required this.pdfLink,
    required this.onSent,
  });

  @override
  State<SendInvoiceSheet> createState() => _SendInvoiceSheetState();
}

class _SendInvoiceSheetState extends State<SendInvoiceSheet>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _toController;
  late final TextEditingController _ccController;
  late final TextEditingController _subjectController;
  late final quill.QuillController _quillController;
  final FocusNode _bodyFocus = FocusNode();
  final ScrollController _bodyScroll = ScrollController();
  late final TabController _tabs;
  bool _templatesSeeded = false;

  bool _attachPdf = true;
  bool _previewLoading = false;
  String? _previewError;
  Map<String, dynamic>? _previewPayload;
  bool _sending = false;
  bool _isReadyToSend = false;
  String? _sendMessage;
  String? _sendError;

  @override
  void initState() {
    super.initState();
    debugPrint('[SendInvoiceSheet] opened for invoice=${widget.invoice.id}');
    final fallbackEmail = widget.client.billing?.email ?? widget.client.email;
    _toController = TextEditingController(text: fallbackEmail ?? '');
    _ccController = TextEditingController();
    _subjectController = TextEditingController();
    _quillController = quill.QuillController.basic();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() {
      if (_tabs.index == 1 && !_tabs.indexIsChanging) {
        _loadPreview();
      }
    });
    _toController.addListener(_onComposeChanged);
    _ccController.addListener(_clearPreview);
    _subjectController.addListener(_onComposeChanged);
    _quillController.addListener(_clearPreview);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_templatesSeeded) return;
    final l = AppLocalizations.of(context)!;
    _subjectController.text =
        l.invoiceEmailSubjectTemplate(widget.invoice.invoiceNumber);
    final seed = l.invoiceEmailMessageTemplate(
      widget.client.name,
      widget.invoice.invoiceNumber,
    );
    _quillController.document
      ..delete(0, _quillController.document.length)
      ..insert(0, seed);
    _refreshReadyToSend();
    _templatesSeeded = true;
  }

  void _onComposeChanged() {
    _clearPreview();
    _refreshReadyToSend();
  }

  bool _hasAtLeastOneRecipient(String raw) {
    return raw
        .split(RegExp(r'[,;\s]+'))
        .map((value) => value.trim())
        .any((value) => value.isNotEmpty);
  }

  void _refreshReadyToSend() {
    final nextValue = _hasAtLeastOneRecipient(_toController.text) &&
        _subjectController.text.trim().isNotEmpty;
    if (nextValue == _isReadyToSend) return;
    setState(() => _isReadyToSend = nextValue);
  }

  void _clearPreview() {
    if (_previewPayload == null && _previewError == null) return;
    setState(() {
      _previewPayload = null;
      _previewError = null;
    });
  }

  String _cssHex(Color color) {
    final r = color.r.round().toRadixString(16).padLeft(2, '0');
    final g = color.g.round().toRadixString(16).padLeft(2, '0');
    final b = color.b.round().toRadixString(16).padLeft(2, '0');
    return '#$r$g$b';
  }

  String _themeAwarePreviewHtml({
    required String html,
    required Color textColor,
    required Color linkColor,
  }) {
    final textHex = _cssHex(textColor);
    final linkHex = _cssHex(linkColor);
    return '''
<style>
  body, p, div, span, li, td, th, blockquote, h1, h2, h3, h4, h5, h6 {
    color: $textHex !important;
  }
  a { color: $linkHex !important; }
</style>
$html
''';
  }

  @override
  void dispose() {
    _tabs.dispose();
    _toController.dispose();
    _ccController.dispose();
    _subjectController.dispose();
    _quillController.dispose();
    _bodyFocus.dispose();
    _bodyScroll.dispose();
    super.dispose();
  }

  Map<String, dynamic> _payload() {
    final text = _quillController.document.toPlainText().trim();
    final html = _quillToHtml(_quillController.document);
    return {
      'invoiceId': widget.invoice.id,
      'groupId': widget.invoice.groupId,
      'to': _toController.text.trim(),
      'cc':
          _ccController.text.trim().isEmpty ? null : _ccController.text.trim(),
      'subject': _subjectController.text.trim(),
      'text': text,
      'html': html,
      'attachInvoicePdf': true,
      'attachPdf': _attachPdf,
      'pdfLink': _attachPdf ? '' : widget.pdfLink,
      'applyDefaultFooter': true,
    };
  }

  Future<void> _loadPreview() async {
    if (_previewLoading) return;
    setState(() {
      _previewLoading = true;
      _previewError = null;
      _previewPayload = null;
    });
    try {
      final data = await widget.emailApi.previewTemplate(_payload());
      if (!mounted) return;
      setState(() => _previewPayload = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _previewError = e.toString());
    } finally {
      if (mounted) setState(() => _previewLoading = false);
    }
  }

  Future<void> _send() async {
    if (_sending) return;
    setState(() {
      _sending = true;
      _sendError = null;
      _sendMessage = null;
    });
    try {
      await widget.emailApi.sendInvoice(_payload());
      final now = DateTime.now();
      if (!mounted) return;
      setState(() {
        _sendMessage = AppLocalizations.of(context)!.invoiceEmailSentAtLabel(
          DateFormat.yMMMd().add_Hm().format(now.toLocal()),
        );
      });
      await widget.onSent();
    } catch (e) {
      if (!mounted) return;
      setState(() => _sendError = e.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Map<String, dynamic>? _previewAttachment() {
    final payload = _previewPayload ?? {};
    final attachment = payload['attachment'];
    if (attachment is Map<String, dynamic>) return attachment;
    final attachments = payload['attachments'];
    if (attachments is List && attachments.isNotEmpty) {
      final first = attachments.first;
      if (first is Map<String, dynamic>) return first;
    }
    return null;
  }

  Future<void> _promptLink() async {
    final l = AppLocalizations.of(context)!;
    final urlCtrl = TextEditingController();
    final selection = _quillController.selection;
    final selectionText = selection.isValid && selection.start < selection.end
        ? _quillController.document
            .getPlainText(selection.start, selection.end - selection.start)
            .trim()
        : '';
    final labelCtrl = TextEditingController(text: selectionText);

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.mailComposeFormat),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelCtrl,
              decoration: InputDecoration(labelText: l.mailComposeSubjectLabel),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(labelText: 'URL'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.mailComposeCancel),
          ),
          FilledButton(
            onPressed: () {
              final url = urlCtrl.text.trim();
              if (url.isEmpty) return;
              Navigator.of(context).pop({
                'url': url,
                'label': labelCtrl.text.trim(),
              });
            },
            child: Text(l.mailComposeAddAttachment),
          ),
        ],
      ),
    );

    if (result == null || result['url'] == null) return;
    final label = (result['label'] ?? '').trim();
    final url = result['url']!.trim();
    if (selection.isValid && selection.start != selection.end) {
      _quillController.formatSelection(quill.LinkAttribute(url));
      return;
    }
    final insertText = label.isEmpty ? url : label;
    final index = selection.start < 0 ? 0 : selection.start;
    _quillController.document.insert(index, insertText);
    _quillController.updateSelection(
      TextSelection.collapsed(offset: index + insertText.length),
      quill.ChangeSource.local,
    );
    _quillController.formatSelection(quill.LinkAttribute(url));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final previewHtml = _previewPayload?['html']?.toString() ?? '';
    final attachment = _previewAttachment();
    final attachmentName = (attachment?['name'] ??
            attachment?['fileName'] ??
            attachment?['filename'])
        ?.toString();
    final attachmentSize = attachment?['size'] ?? attachment?['bytes'];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.invoiceEmailSheetTitle,
            style: t.titleLarge.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            l.invoiceEmailSheetSubtitle,
            style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          ToggleButtons(
            isSelected: [_attachPdf, !_attachPdf],
            onPressed: (index) => setState(() => _attachPdf = index == 0),
            constraints: const BoxConstraints(minHeight: 36, minWidth: 120),
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(l.invoiceEmailAttachPdfLabel),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(l.invoiceEmailSendLinkLabel),
              ),
            ],
          ),
          if (!_attachPdf)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                widget.pdfLink,
                style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabs,
            tabs: [
              Tab(text: l.invoiceEmailTabEdit),
              Tab(text: l.invoiceEmailTabPreview),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 360,
            child: TabBarView(
              controller: _tabs,
              children: [
                SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: _toController,
                        decoration: InputDecoration(
                          labelText: l.invoiceEmailToLabel,
                          hintText: l.e_gEmail,
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _ccController,
                        decoration: InputDecoration(
                          labelText: l.invoiceEmailCcLabel,
                          hintText: l.e_gEmail,
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _subjectController,
                        decoration: InputDecoration(
                          labelText: l.invoiceEmailSubjectLabel,
                        ),
                      ),
                      const SizedBox(height: 10),
                      AnimatedBuilder(
                        animation: _quillController,
                        builder: (context, _) {
                          final canUndo = _quillController.hasUndo;
                          final canRedo = _quillController.hasRedo;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      l.invoiceEmailMessageLabel,
                                      style: t.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: canUndo
                                        ? () => _quillController.undo()
                                        : null,
                                    icon: const Icon(Icons.undo_rounded),
                                    color: cs.onSurface,
                                    tooltip: 'Undo',
                                  ),
                                  IconButton(
                                    onPressed: canRedo
                                        ? () => _quillController.redo()
                                        : null,
                                    icon: const Icon(Icons.redo_rounded),
                                    color: cs.onSurface,
                                    tooltip: 'Redo',
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      final isBold = _quillController
                                          .getSelectionStyle()
                                          .attributes
                                          .containsKey(
                                              quill.Attribute.bold.key);
                                      _quillController.formatSelection(
                                        isBold
                                            ? quill.Attribute.clone(
                                                quill.Attribute.bold,
                                                null,
                                              )
                                            : quill.Attribute.bold,
                                      );
                                    },
                                    icon: const Icon(Icons.format_bold_rounded),
                                    color: cs.onSurface,
                                    tooltip: 'Bold',
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      final isItalic = _quillController
                                          .getSelectionStyle()
                                          .attributes
                                          .containsKey(
                                              quill.Attribute.italic.key);
                                      _quillController.formatSelection(
                                        isItalic
                                            ? quill.Attribute.clone(
                                                quill.Attribute.italic,
                                                null,
                                              )
                                            : quill.Attribute.italic,
                                      );
                                    },
                                    icon:
                                        const Icon(Icons.format_italic_rounded),
                                    color: cs.onSurface,
                                    tooltip: 'Italic',
                                  ),
                                  IconButton(
                                    onPressed: _promptLink,
                                    icon: const Icon(Icons.link_rounded),
                                    color: cs.onSurface,
                                    tooltip: 'Link',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: cs.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: cs.outlineVariant),
                                ),
                                constraints:
                                    const BoxConstraints(minHeight: 160),
                                child: DefaultTextStyle(
                                  style: t.bodySmall.copyWith(
                                    color: cs.onSurface,
                                    height: 1.55,
                                  ),
                                  child: Builder(
                                    builder: (context) {
                                      _quillController.readOnly = _sending;
                                      return quill.QuillEditor(
                                        controller: _quillController,
                                        scrollController: _bodyScroll,
                                        focusNode: _bodyFocus,
                                        config: quill.QuillEditorConfig(
                                          padding: EdgeInsets.zero,
                                          autoFocus: false,
                                          expands: false,
                                          customStyles: quill.DefaultStyles(
                                            placeHolder:
                                                quill.DefaultTextBlockStyle(
                                              t.bodySmall.copyWith(
                                                color: cs.onSurfaceVariant,
                                              ),
                                              const quill.HorizontalSpacing(
                                                0,
                                                0,
                                              ),
                                              quill.VerticalSpacing.zero,
                                              quill.VerticalSpacing.zero,
                                              null,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                _previewLoading
                    ? Center(
                        child: CircularProgressIndicator(color: cs.primary),
                      )
                    : _previewError != null
                        ? Center(
                            child: Text(
                              _previewError!,
                              style: t.bodySmall.copyWith(color: cs.error),
                            ),
                          )
                        : previewHtml.isEmpty
                            ? Center(
                                child: Text(
                                  l.invoiceEmailNoPreview,
                                  style: t.bodySmall.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              )
                            : SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    HtmlWidget(
                                      _themeAwarePreviewHtml(
                                        html: previewHtml,
                                        textColor: cs.onSurface,
                                        linkColor: cs.primary,
                                      ),
                                    ),
                                    if (attachmentName != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 12),
                                        child: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: cs.surfaceContainerHighest,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.attach_file,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  attachmentName,
                                                  style: t.bodySmall.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                              if (attachmentSize is int)
                                                Text(
                                                  formatBytes(attachmentSize),
                                                  style: t.bodySmall.copyWith(
                                                    color: cs.onSurfaceVariant,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (_sendMessage != null)
            Text(
              _sendMessage!,
              style: t.bodySmall.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          if (_sendError != null)
            Text(
              _sendError!,
              style: t.bodySmall.copyWith(color: cs.error),
            ),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l.cancel),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _previewLoading ? null : _loadPreview,
                icon: const Icon(Icons.refresh),
                label: Text(l.invoiceEmailPreviewRefreshCta),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: (!_sending && _isReadyToSend) ? _send : null,
                icon: _sending
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.onPrimary,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  _sending ? l.invoiceEmailSendingLabel : l.invoiceEmailSendCta,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
