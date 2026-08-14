import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/a-models/receipt/receipt.dart';
import 'package:hexora/b-backend/auth_user/auth/token/service/authenticated_http_client.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:hexora/b-backend/blobUploader/blobServer.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/client/client_api.dart';
import 'package:hexora/b-backend/invoicing/invoice_api.dart';
import 'package:hexora/b-backend/invoicing/presupuestos_api.dart';
import 'package:hexora/b-backend/receipts/receipts_api.dart';
import 'package:hexora/b-backend/mail/domain/mail_domain.dart';
import 'package:hexora/b-backend/mail/models/mail_requests.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/dashboard/controller/group_dashboard_state.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/enable_banking/widgets/folder_section_card.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/sections/invoice_editor_pdf.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/pdf_preview/pdf_preview_launcher.dart'
    as pdf_launcher;
import 'package:hexora/c-frontend/ui-app/shared/widgets/client_search_select.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/snack_helper.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

part 'compose/mail_compose_utils.dart';
part 'compose/mail_compose_view.dart';

// Widget components (split from mail_compose_widgets.dart for better maintainability)
part 'compose/widgets/email_chips_input.dart';
part 'compose/widgets/collapsed_panel.dart';
part 'compose/widgets/compose_bottom_bar.dart';
part 'compose/widgets/invoice_picker_sheet.dart';
part 'compose/widgets/inline_invoice_wizard.dart';
part 'compose/widgets/invoice_selection_preview.dart';

class MailComposeScreen extends StatefulWidget {
  const MailComposeScreen({
    super.key,
    this.embedded = false,
    this.onSent,
    this.onClose,
  });

  final bool embedded;
  final VoidCallback? onSent;
  final VoidCallback? onClose;

  @override
  State<MailComposeScreen> createState() => _MailComposeScreenState();
}

class _MailComposeScreenState extends State<MailComposeScreen> {
  final _clientsApi = ClientsApi();
  final _invoicesApi = InvoicesApi();
  final _receiptsApi = ReceiptsApi();
  final _presupuestosApi = PresupuestosApi();

  final _toCtrl = TextEditingController();
  final _ccCtrl = TextEditingController();
  final _bccCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _invoiceIdsCtrl = TextEditingController();
  final _bodyFocus = FocusNode();
  final _bodyScroll = ScrollController();
  late final quill.QuillController _quillController =
      quill.QuillController.basic();

  final List<String> _toList = [];
  final List<String> _ccList = [];
  final List<String> _bccList = [];

  // ── Template picker state ──────────────────────────────────────────────────
  List<Map<String, dynamic>> _composeTemplates = const [];
  bool _composeTemplatesLoading = false;
  String? _selectedComposeTemplateId;
  String? _selectedComposeTemplateName;

  bool _attachInvoicePdf = false;
  bool _includeInvoiceLinks = false;
  bool _applyDefaultFooter = true;
  bool _sending = false;
  bool _uploadingAttachment = false;
  bool _showCc = false;
  bool _showBcc = false;
  bool _attachmentsExpanded = false;
  bool _invoiceExpanded = false;
  bool _openingInvoicePicker = false;
  bool _loadingRecipientClients = false;
  bool _useClientMode =
      false; // true = pick from client list, false = type email directly
  bool _loadingRecentInvoices = false;
  bool _inlineInvoiceLoading = false;
  String? _inlineInvoiceError;
  String? _inlineClientId;
  String? _recipientClientId;
  String? _recipientClientError;

  final List<MailOutgoingAttachment> _attachments = [];
  List<GroupClient> _pickerClients = const [];
  final Map<String, List<Invoice>> _pickerInvoicesByClient = {};
  final Map<String, List<Receipt>> _pickerReceiptsByClient = {};
  final Map<String, List<Map<String, dynamic>>> _pickerPresupuestosByClient =
      {};
  final Set<String> _selectedPresupuestoIds = <String>{};
  final Set<String> _selectedReceiptIds = <String>{};

  void update(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  void _refreshCanSendState() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _toCtrl.addListener(_refreshCanSendState);
    _subjectCtrl.addListener(_refreshCanSendState);
    _quillController.addListener(_refreshCanSendState);
    debugPrint('[MailCompose] opened (embedded=${widget.embedded})');
    if (widget.embedded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _prepareInlineInvoiceFlow();
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadRecipientClientsIfNeeded();
    });
  }

  @override
  void dispose() {
    _toCtrl.removeListener(_refreshCanSendState);
    _subjectCtrl.removeListener(_refreshCanSendState);
    _quillController.removeListener(_refreshCanSendState);
    _toCtrl.dispose();
    _ccCtrl.dispose();
    _bccCtrl.dispose();
    _subjectCtrl.dispose();
    _invoiceIdsCtrl.dispose();
    _bodyFocus.dispose();
    _bodyScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _MailComposeView(state: this);
  }

  Future<void> _addAttachment() async {
    final l = AppLocalizations.of(context)!;
    final storageKeyCtrl = TextEditingController();
    final filenameCtrl = TextEditingController();
    final contentTypeCtrl = TextEditingController();
    final sizeCtrl = TextEditingController();

    final result = await showDialog<MailOutgoingAttachment>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l.mailComposeAddAttachment),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: storageKeyCtrl,
                  decoration: InputDecoration(
                    labelText: l.mailComposeStorageKeyLabel,
                    hintText: l.mailComposeStorageKeyHint,
                  ),
                ),
                TextField(
                  controller: filenameCtrl,
                  decoration: InputDecoration(
                    labelText: l.mailComposeFilenameLabel,
                    hintText: l.mailComposeFilenameHint,
                  ),
                ),
                TextField(
                  controller: contentTypeCtrl,
                  decoration: InputDecoration(
                    labelText: l.mailComposeContentTypeLabel,
                    hintText: l.mailComposeContentTypeHint,
                  ),
                ),
                TextField(
                  controller: sizeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l.mailComposeSizeLabel,
                    hintText: l.mailComposeSizeHint,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l.mailComposeCancel),
            ),
            FilledButton(
              onPressed: () {
                final key = storageKeyCtrl.text.trim();
                if (key.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.mailComposeStorageKeyRequired)),
                  );
                  return;
                }
                final size = int.tryParse(sizeCtrl.text.trim());
                Navigator.of(context).pop(
                  MailOutgoingAttachment(
                    storageKey: key,
                    filename: filenameCtrl.text.trim().isEmpty
                        ? null
                        : filenameCtrl.text.trim(),
                    contentType: contentTypeCtrl.text.trim().isEmpty
                        ? null
                        : contentTypeCtrl.text.trim(),
                    size: size,
                  ),
                );
              },
              child: Text(l.mailComposeAddAttachment),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() {
        _attachments.add(result);
        _attachmentsExpanded = true;
      });
    }
  }

  Future<void> _pickAndUploadAttachment() async {
    final l = AppLocalizations.of(context)!;
    final authHeaders = await AuthenticatedHttpClient.authorizedHeaders(
      includeJsonContentType: false,
    );
    final auth = authHeaders['Authorization'] ?? '';
    final token = auth.startsWith('Bearer ')
        ? auth.substring('Bearer '.length).trim()
        : '';
    if (!mounted) return;
    if (token.isEmpty) {
      _showError(l.notAuthenticatedOrUserMissing);
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: kIsWeb,
    );
    if (!mounted) return;
    final file = result?.files.single;
    if (file == null) return;

    if (!kIsWeb && (file.path == null || file.path!.isEmpty)) {
      _showError(l.mailComposeFileReadError);
      return;
    }
    if (kIsWeb && file.bytes == null) {
      _showError(l.mailComposeFileReadError);
      return;
    }

    setState(() => _uploadingAttachment = true);
    try {
      final mimeType = _inferMimeType(file);
      final uploadResult = await uploadImageToAzure(
        scope: 'users',
        accessToken: token,
        file: kIsWeb ? null : File(file.path!),
        bytes: kIsWeb ? file.bytes : null,
        mimeType: mimeType,
      );

      setState(() {
        _attachments.add(
          MailOutgoingAttachment(
            storageKey: uploadResult.blobName,
            filename: file.name,
            contentType: mimeType,
            size: file.size,
          ),
        );
        _attachmentsExpanded = true;
      });
    } catch (e) {
      _showError(l.mailComposeUploadFailed(e.toString()));
    } finally {
      if (mounted) setState(() => _uploadingAttachment = false);
    }
  }

  Future<void> _send() async {
    final l = AppLocalizations.of(context)!;
    _flushRecipientInputs();
    _applySelectedClientEmailIfNeeded();
    final to = _toList;
    if (to.isEmpty) {
      _showError(l.mailComposeToRequired);
      return;
    }

    final cc = _ccList;
    final bcc = _bccList;
    final subject = _subjectCtrl.text.trim();
    final body = _quillController.document.toPlainText().trim();
    if (subject.isEmpty) {
      _showError(l.mailComposeSubjectRequired);
      return;
    }
    if (body.isEmpty) {
      _showError(l.mailComposeBodyRequired);
      return;
    }

    final invoiceIds = _splitValues(_normalizeInvoiceIds(_invoiceIdsCtrl.text))
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final presupuestoIds = _selectedPresupuestoIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final receiptIds = _selectedReceiptIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final hasDocumentIds = invoiceIds.isNotEmpty ||
        presupuestoIds.isNotEmpty ||
        receiptIds.isNotEmpty;
    final hasManualPdfAttachment = _manualPdfAttachmentCount > 0;
    if (_useClientMode && !hasDocumentIds && !hasManualPdfAttachment) {
      final msg = l.localeName.toLowerCase().startsWith('es')
          ? 'Adjunta al menos un PDF (factura, presupuesto, recibo o archivo) para enviar desde cliente.'
          : 'Attach at least one PDF (invoice, budget, receipt, or file) before sending from client mode.';
      _showError(msg);
      return;
    }
    final groupId = _currentGroupId();
    if (groupId == null || groupId.isEmpty) {
      _showError(l.notAuthenticatedOrUserMissing);
      return;
    }

    final mailDomain = context.read<MailDomain>();
    setState(() => _sending = true);
    try {
      debugPrint('[MailCompose] send requested '
          'to=${to.join(',')} '
          'cc=${_ccList.join(',')} '
          'bcc=${_bccList.join(',')} '
          'invoiceIds=${invoiceIds.join(',')} '
          'presupuestoIds=${presupuestoIds.join(',')} '
          'receiptIds=${receiptIds.join(',')} '
          'receiptPdfAttachments=0 (frontend fallback disabled) '
          'attachInvoicePdf=$_attachInvoicePdf '
          'attachPresupuestoPdf=${presupuestoIds.isNotEmpty ? true : null} '
          'attachReceiptPdf=${receiptIds.isNotEmpty ? true : null} '
          'includeLinks=$_includeInvoiceLinks '
          'applyDefaultFooter=$_applyDefaultFooter');
      final request = MailSendRequest(
        groupId: groupId,
        to: to,
        cc: cc,
        bcc: bcc,
        subject: subject,
        textBody: body,
        htmlBody: _quillToHtml(_quillController.document),
        attachments: _attachments,
        invoiceIds: invoiceIds,
        presupuestoIds: presupuestoIds,
        receiptIds: receiptIds,
        // Always attach PDFs when document IDs are present via the inline wizard.
        attachInvoicePdf: hasDocumentIds ? true : null,
        attachPresupuestoPdf: presupuestoIds.isNotEmpty ? true : null,
        attachReceiptPdf: receiptIds.isNotEmpty ? true : null,
        includeInvoiceLinks: hasDocumentIds ? _includeInvoiceLinks : null,
        applyDefaultFooter: true,
        templateId: _selectedComposeTemplateId,
      );
      await mailDomain.sendMessage(request);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.mailComposeSentToast)),
      );
      _resetForm();
      if (widget.embedded) {
        widget.onSent?.call();
      } else {
        Navigator.of(context).maybePop();
      }
    } catch (e) {
      _showError(l.mailComposeSendFailed(e.toString()));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String? _currentGroupId() {
    try {
      return context.read<GroupDashboardState>().group.id;
    } catch (_) {
      return null;
    }
  }

  http.Client? _mailHttpClient() {
    try {
      return context.read<http.Client>();
    } catch (_) {
      return null;
    }
  }

  void _resetForm() {
    _toCtrl.clear();
    _ccCtrl.clear();
    _bccCtrl.clear();
    _subjectCtrl.clear();
    _quillController.replaceText(
      0,
      _quillController.document.length,
      '',
      const TextSelection.collapsed(offset: 0),
    );
    _invoiceIdsCtrl.clear();
    setState(() {
      _attachInvoicePdf = false;
      _includeInvoiceLinks = false;
      _applyDefaultFooter = true;
      _sending = false;
      _showCc = false;
      _showBcc = false;
      _attachmentsExpanded = false;
      _invoiceExpanded = false;
      _useClientMode = false;
      _toList.clear();
      _ccList.clear();
      _bccList.clear();
      _attachments.clear();
      _selectedPresupuestoIds.clear();
      _selectedReceiptIds.clear();
      _selectedComposeTemplateId = null;
      _selectedComposeTemplateName = null;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  bool _isManualPdfAttachment(MailOutgoingAttachment attachment) {
    final contentType = (attachment.contentType ?? '').toLowerCase().trim();
    if (contentType.contains('pdf')) return true;
    final filename = (attachment.filename ?? '').toLowerCase().trim();
    return filename.endsWith('.pdf');
  }

  List<MailOutgoingAttachment> get _manualPdfAttachments =>
      _attachments.where(_isManualPdfAttachment).toList(growable: false);

  int get _manualPdfAttachmentCount => _manualPdfAttachments.length;

  String _manualPdfAttachmentName(MailOutgoingAttachment attachment) {
    final filename = (attachment.filename ?? '').trim();
    if (filename.isNotEmpty) return filename;
    final storageKey = (attachment.storageKey ?? '').trim();
    return storageKey.isNotEmpty ? storageKey : 'PDF';
  }

  String _manualPdfAttachmentNamesSummary({int maxNames = 2}) {
    final names = _manualPdfAttachments
        .map(_manualPdfAttachmentName)
        .where((name) => name.trim().isNotEmpty)
        .toList(growable: false);
    if (names.isEmpty) return '';
    final visible = names.take(maxNames).join(', ');
    final hidden = names.length - maxNames;
    return hidden > 0 ? '$visible +$hidden' : visible;
  }

  bool get _isSpanishLocale => Localizations.localeOf(context)
      .languageCode
      .toLowerCase()
      .startsWith('es');

  // ── Template loading & application ────────────────────────────────────────

  Future<bool> _loadComposeTemplates() async {
    final l = AppLocalizations.of(context)!;
    final groupId = _currentGroupId();
    if (groupId == null || groupId.isEmpty) {
      _showError(l.notAuthenticatedOrUserMissing);
      return false;
    }
    setState(() {
      _composeTemplatesLoading = true;
    });
    try {
      final base = ApiConstants.baseUrl.endsWith('/api')
          ? ApiConstants.baseUrl
          : '${ApiConstants.baseUrl}/api';
      final uri = Uri.parse('$base/mail/templates')
          .replace(queryParameters: {'groupId': groupId});
      final r = await AuthenticatedHttpClient.get(
        uri,
        client: _mailHttpClient(),
      );
      if (!mounted) return false;
      if (r.statusCode < 200 || r.statusCode >= 300) {
        throw Exception(
          r.body.trim().isNotEmpty ? r.body.trim() : r.reasonPhrase,
        );
      }

      final decoded = jsonDecode(r.body);
      final dynamic raw = decoded is List
          ? decoded
          : decoded is Map
              ? decoded['items'] ??
                  decoded['data'] ??
                  decoded['templates'] ??
                  const <dynamic>[]
              : null;
      if (raw is! List) {
        throw const FormatException('Unexpected templates response');
      }

      final templates = raw
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList(growable: false);
      setState(() {
        _composeTemplates = templates;
      });
      return true;
    } catch (e) {
      if (!mounted) return false;
      final detail = e.toString().replaceFirst('Exception: ', '').trim();
      final message = _isSpanishLocale
          ? 'No se pudieron cargar las plantillas${detail.isEmpty ? '.' : ': $detail'}'
          : 'Could not load templates${detail.isEmpty ? '.' : ': $detail'}';
      setState(() {
        _composeTemplates = const [];
      });
      _showError(message);
      return false;
    } finally {
      if (mounted) setState(() => _composeTemplatesLoading = false);
    }
  }

  void _applyComposeTemplate(Map<String, dynamic> template) {
    final id = (template['id'] ?? template['_id'])?.toString().trim() ?? '';
    final name = (template['name'] ?? '').toString().trim();
    final subject = (template['subject'] ?? '').toString().trim();
    final text = (template['text'] ?? '').toString().trim();
    if (subject.isNotEmpty) _subjectCtrl.text = subject;
    // Replace existing content. Use document.length - 1 to preserve the
    // mandatory trailing newline that Quill always keeps at the end.
    final docLen = _quillController.document.length;
    final replaceLen = docLen > 1 ? docLen - 1 : 0;
    _quillController.replaceText(
      0,
      replaceLen,
      text,
      TextSelection.collapsed(offset: text.length),
    );
    setState(() {
      _selectedComposeTemplateId = id.isNotEmpty ? id : null;
      _selectedComposeTemplateName = name.isNotEmpty ? name : null;
    });
  }

  Future<void> _showTemplatePicker() async {
    if (_composeTemplatesLoading) return;
    if (_composeTemplates.isEmpty) {
      final loaded = await _loadComposeTemplates();
      if (!mounted) return;
      if (!loaded) return;
    }
    if (_composeTemplates.isEmpty) {
      _showError(_isSpanishLocale
          ? 'No hay plantillas disponibles. Crea una en la sección Templates.'
          : 'No templates are available. Create one in the Templates section.');
      return;
    }
    final hasSelected = _selectedComposeTemplateId != null;
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
          child: _ComposeTemplatePicker(
            templates: _composeTemplates,
            selectedId: _selectedComposeTemplateId,
            onSelect: (template) {
              Navigator.pop(dialogCtx);
              _applyComposeTemplate(template);
            },
            onClear: hasSelected
                ? () {
                    Navigator.pop(dialogCtx);
                    setState(() {
                      _selectedComposeTemplateId = null;
                      _selectedComposeTemplateName = null;
                    });
                  }
                : null,
          ),
        ),
      ),
    );
  }

  List<String> _splitValues(String raw) {
    return raw
        .split(RegExp(r'[;,\n]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  void _flushRecipientInputs() {
    _consumeAddresses(_toCtrl, _toList);
    _consumeAddresses(_ccCtrl, _ccList);
    _consumeAddresses(_bccCtrl, _bccList);
  }

  void _consumeAddresses(TextEditingController controller, List<String> list) {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    final parts = text.split(RegExp(r'[;,\s]'));
    final added = <String>[];
    for (final raw in parts) {
      final value = raw.trim();
      if (value.isEmpty) continue;
      if (_isValidEmail(value) && !list.contains(value)) {
        added.add(value);
      }
    }
    if (added.isNotEmpty) {
      list.addAll(added);
      controller.clear();
    }
  }

  bool _isValidEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }

  String _clientPrimaryEmail(GroupClient client) {
    final billingEmail = (client.billing?.email ?? '').trim();
    if (_isValidEmail(billingEmail)) return billingEmail;
    final email = (client.email ?? '').trim();
    return _isValidEmail(email) ? email : '';
  }

  DateTime _invoiceDisplayDate(Invoice invoice) {
    return (invoice.issueDate ??
            invoice.issuedAtResolved ??
            invoice.registeredAt ??
            DateTime.fromMillisecondsSinceEpoch(0))
        .toLocal();
  }

  bool _isToday(DateTime value) {
    final local = value.toLocal();
    final now = DateTime.now();
    return local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
  }

  String _formatInvoiceDate(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year.toString().padLeft(4, '0')}';
  }

  String _formatInvoiceTotal(Invoice invoice) {
    final formatted = (invoice.totalFormatted ?? '').trim();
    if (formatted.isNotEmpty) return formatted;
    final total = invoice.total;
    if (total == null) return '-';
    final amount = total.toStringAsFixed(2);
    final currency = (invoice.currency ?? 'EUR').trim();
    return currency.isEmpty ? amount : '$amount $currency';
  }

  Future<void> _loadRecipientClientsIfNeeded() async {
    if (_loadingRecipientClients || _pickerClients.isNotEmpty) return;
    final groupId = _currentGroupId();
    if (groupId == null || groupId.isEmpty) return;
    setState(() {
      _loadingRecipientClients = true;
      _recipientClientError = null;
    });
    try {
      final clients = await _ensurePickerClientsLoaded(groupId);
      if (!mounted) return;
      final withEmail = clients
          .where((c) => _clientPrimaryEmail(c).isNotEmpty)
          .toList(growable: false);
      setState(() {
        _recipientClientId = withEmail.isNotEmpty ? withEmail.first.id : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _recipientClientError = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loadingRecipientClients = false);
      }
    }
  }

  List<GroupClient> _recipientClientsWithEmail() {
    return _pickerClients
        .where((c) => _clientPrimaryEmail(c).isNotEmpty)
        .toList(growable: false);
  }

  String? _selectedRecipientClientEmail() {
    final id = (_recipientClientId ?? '').trim();
    if (id.isEmpty) return null;
    for (final c in _pickerClients) {
      if (c.id != id) continue;
      final email = _clientPrimaryEmail(c);
      return email.isEmpty ? null : email;
    }
    return null;
  }

  bool _hasRecipientCandidate() {
    if (_toList.isNotEmpty) return true;
    final pending = _toCtrl.text.trim();
    if (pending.isNotEmpty && _isValidEmail(pending)) return true;
    return _selectedRecipientClientEmail() != null;
  }

  void _applySelectedClientEmailIfNeeded() {
    if (_toList.isNotEmpty) return;
    final email = _selectedRecipientClientEmail();
    if (email == null || email.isEmpty) return;
    if (_toList.contains(email)) return;
    _toList.add(email);
  }

  Future<void> _openRecentIssuedInvoicesPicker() async {
    if (_loadingRecentInvoices) return;
    final l = AppLocalizations.of(context)!;
    final groupId = _currentGroupId();
    if (groupId == null || groupId.isEmpty) {
      _showError(l.notAuthenticatedOrUserMissing);
      return;
    }

    setState(() => _loadingRecentInvoices = true);
    try {
      final responses = await Future.wait([
        _invoicesApi.listByGroup(
          groupId,
          status: 'issued',
          sortBy: 'issueDate',
          sortDir: 'desc',
        ),
        _ensurePickerClientsLoaded(groupId),
      ]);
      if (!mounted) return;
      final invoices = (responses[0] as List<Invoice>)
          .where((invoice) => _isToday(_invoiceDisplayDate(invoice)))
          .toList(growable: false)
        ..sort(
            (a, b) => _invoiceDisplayDate(b).compareTo(_invoiceDisplayDate(a)));
      final clients = responses[1] as List<GroupClient>;

      final selected = await showDialog<Invoice>(
        context: context,
        builder: (dialogContext) => _RecentIssuedInvoicesDialog(
          invoices: invoices,
          clients: clients,
          isSpanish: _isSpanishLocale,
          formatDate: _formatInvoiceDate,
          formatTotal: _formatInvoiceTotal,
        ),
      );
      if (!mounted || selected == null) return;
      _applyRecentInvoiceSelection(selected, clients);
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loadingRecentInvoices = false);
    }
  }

  void _applyRecentInvoiceSelection(
    Invoice invoice,
    List<GroupClient> clients,
  ) {
    final clientId = invoice.clientId.trim();
    if (clientId.isEmpty) {
      _showError(_isSpanishLocale
          ? 'La factura no tiene cliente asociado.'
          : 'This invoice has no linked client.');
      return;
    }
    final client = clients.cast<GroupClient?>().firstWhere(
          (item) => item?.id == clientId,
          orElse: () => null,
        );
    final email = client == null ? '' : _clientPrimaryEmail(client);
    if (email.isEmpty) {
      _showError(_isSpanishLocale
          ? 'Este cliente no tiene email guardado.'
          : 'This client has no saved email.');
    }

    setState(() {
      _useClientMode = true;
      _recipientClientId = clientId;
      _inlineClientId = clientId;
      final existing = _splitValues(_normalizeInvoiceIds(_invoiceIdsCtrl.text));
      final merged = <String>{...existing, invoice.id}
          .where((id) => id.trim().isNotEmpty)
          .toList(growable: false);
      _invoiceIdsCtrl.text = merged.join(',');
      _attachInvoicePdf = true;
      _includeInvoiceLinks = true;
      _invoiceExpanded = true;
      _toList.clear();
      if (email.isNotEmpty) _toList.add(email);
    });
  }

  String _normalizeInvoiceIds(String raw) {
    return raw.replaceAll(RegExp(r'[\s;]+'), ',');
  }

  Future<List<GroupClient>> _ensurePickerClientsLoaded(String groupId) async {
    if (_pickerClients.isNotEmpty) return _pickerClients;
    final clients = await _clientsApi.list(groupId: groupId, active: null);
    if (!mounted) return clients;
    setState(() => _pickerClients = clients);
    return clients;
  }

  Future<List<Invoice>> _loadInvoicesForClient({
    required String groupId,
    required String clientId,
  }) async {
    final cached = _pickerInvoicesByClient[clientId];
    if (cached != null) return cached;

    final responses = await Future.wait([
      _invoicesApi.listByGroup(groupId, status: 'issued'),
      _invoicesApi.listByGroup(groupId, status: 'draft'),
    ]);
    final merged = <String, Invoice>{};
    for (final invoice in [...responses[0], ...responses[1]]) {
      if (invoice.clientId == clientId) merged[invoice.id] = invoice;
    }
    final list = merged.values.toList()
      ..sort((a, b) {
        final aDate = a.registeredAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.registeredAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
    _pickerInvoicesByClient[clientId] = list;
    return list;
  }

  Future<List<Receipt>> _loadReceiptsForClient({
    required String groupId,
    required String clientId,
  }) async {
    final cached = _pickerReceiptsByClient[clientId];
    if (cached != null) return cached;

    final responses = await Future.wait([
      _receiptsApi.list(groupId: groupId, status: 'issued'),
      _receiptsApi.list(groupId: groupId, status: 'draft'),
    ]);
    final merged = <String, Receipt>{};
    for (final receipt in [...responses[0], ...responses[1]]) {
      if (receipt.clientId == clientId) merged[receipt.id] = receipt;
    }
    final list = merged.values.toList()
      ..sort((a, b) {
        final aDate = a.registeredAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.registeredAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
    _pickerReceiptsByClient[clientId] = list;
    return list;
  }

  DateTime _parseSortDate(dynamic raw) {
    if (raw is DateTime) return raw;
    if (raw is int) {
      return DateTime.fromMillisecondsSinceEpoch(
        raw.abs() < 1000000000000 ? raw * 1000 : raw,
      );
    }
    if (raw is String) {
      return DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<List<Map<String, dynamic>>> _loadPresupuestosForClient({
    required String groupId,
    required String clientId,
  }) async {
    final cached = _pickerPresupuestosByClient[clientId];
    if (cached != null) return cached;
    final list = await _presupuestosApi.listByGroup(
      groupId: groupId,
      clientId: clientId,
    );
    list.sort((a, b) {
      final aDate = _parseSortDate(a['createdAt'] ?? a['updatedAt']);
      final bDate = _parseSortDate(b['createdAt'] ?? b['updatedAt']);
      return bDate.compareTo(aDate);
    });
    _pickerPresupuestosByClient[clientId] = list;
    return list;
  }

  Future<void> _openPresupuestoPdfPreviewById(String id) async {
    final l = AppLocalizations.of(context)!;
    try {
      final r = await _presupuestosApi.previewPdf(id);
      final bytes = InvoiceEditorPdf.validatePdf(r);
      await pdf_launcher.launchPdfPreview(
        bytes,
        fileName: 'presupuesto-preview-$id.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '').trim();
      _showError(msg.isEmpty ? l.failedWithReason('') : msg);
    }
  }

  Future<void> _openInvoicePicker() async {
    if (_openingInvoicePicker) return;
    final l = AppLocalizations.of(context)!;
    final groupId = _currentGroupId();
    if (groupId == null || groupId.isEmpty) {
      _showError(l.notAuthenticatedOrUserMissing);
      return;
    }

    setState(() => _openingInvoicePicker = true);
    try {
      final clients = await _ensurePickerClientsLoaded(groupId);
      if (!mounted) return;
      if (clients.isEmpty) {
        _showError(l.noClientsYet);
        return;
      }

      final currentIds =
          _splitValues(_normalizeInvoiceIds(_invoiceIdsCtrl.text));
      final initialClientId = _inlineClientId ?? clients.first.id;
      final result = await Navigator.of(context).push<_InvoicePickerResult>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => Scaffold(
            appBar: AppBar(
              title: Text(l.mailComposeInvoiceOptions),
            ),
            body: SafeArea(
              child: _InvoicePickerSheet(
                clients: clients,
                initialClientId: initialClientId,
                initialInvoiceIds: currentIds,
                initialPresupuestoIds:
                    _selectedPresupuestoIds.toList(growable: false),
                onLoadInvoices: (clientId) => _loadInvoicesForClient(
                  groupId: groupId,
                  clientId: clientId,
                ),
                onLoadReceipts: (clientId) => _loadReceiptsForClient(
                  groupId: groupId,
                  clientId: clientId,
                ),
                onLoadPresupuestos: (clientId) => _loadPresupuestosForClient(
                  groupId: groupId,
                  clientId: clientId,
                ),
                onPreviewPresupuesto: _openPresupuestoPdfPreviewById,
                initialReceiptIds: _selectedReceiptIds.toList(growable: false),
              ),
            ),
          ),
        ),
      );
      if (!mounted || result == null) return;
      _applyInvoicePickerResult(result);
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _openingInvoicePicker = false);
    }
  }

  void _applyInvoicePickerResult(_InvoicePickerResult result) {
    if (!mounted) return;
    setState(() {
      _inlineClientId = result.clientId;
      final existing = _splitValues(_normalizeInvoiceIds(_invoiceIdsCtrl.text));
      final merged = <String>{...existing, ...result.invoiceIds}
          .where((id) => id.trim().isNotEmpty)
          .toList(growable: false);
      _invoiceIdsCtrl.text = merged.join(',');
      _selectedPresupuestoIds
        ..clear()
        ..addAll(result.presupuestoIds);
      _selectedReceiptIds
        ..clear()
        ..addAll(result.receiptIds);
      if (merged.isNotEmpty ||
          _selectedPresupuestoIds.isNotEmpty ||
          _selectedReceiptIds.isNotEmpty) {
        _attachInvoicePdf = true;
        _includeInvoiceLinks = true;
      }
    });
  }

  Future<void> _prepareInlineInvoiceFlow() async {
    final l = AppLocalizations.of(context)!;
    final groupId = _currentGroupId();
    if (groupId == null || groupId.isEmpty) {
      setState(() => _inlineInvoiceError = l.notAuthenticatedOrUserMissing);
      return;
    }
    setState(() {
      _inlineInvoiceLoading = true;
      _inlineInvoiceError = null;
    });
    try {
      final clients = await _ensurePickerClientsLoaded(groupId);
      if (!mounted) return;
      if (clients.isEmpty) {
        setState(() => _inlineClientId = null);
      } else {
        final clientId = _inlineClientId ?? clients.first.id;
        await _loadInvoicesForClient(groupId: groupId, clientId: clientId);
        await _loadReceiptsForClient(groupId: groupId, clientId: clientId);
        await _loadPresupuestosForClient(groupId: groupId, clientId: clientId);
        if (!mounted) return;
        setState(() => _inlineClientId = clientId);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _inlineInvoiceError = e.toString());
    } finally {
      if (mounted) setState(() => _inlineInvoiceLoading = false);
    }
  }

  Future<void> _promptLink() async {
    final l = AppLocalizations.of(context)!;
    final selection = _quillController.selection;
    final selectedText = selection.isCollapsed
        ? ''
        : _quillController.document
            .getPlainText(selection.start, selection.end - selection.start)
            .trim();
    final labelCtrl = TextEditingController(text: selectedText);
    final urlCtrl = TextEditingController(text: 'https://');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.mailComposeAddAttachment),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelCtrl,
              decoration: InputDecoration(
                labelText: l.mailComposeSubjectLabel,
                hintText: l.mailComposeSubjectHint,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(
                labelText: 'URL',
                hintText: 'https://example.com',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.mailComposeCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.mailComposeAddAttachment),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final url = urlCtrl.text.trim();
    if (url.isEmpty) return;
    final label = labelCtrl.text.trim().isEmpty ? url : labelCtrl.text.trim();

    final index = selection.start;
    final length = selection.end - selection.start;
    _quillController.replaceText(
      index,
      length,
      label,
      TextSelection.collapsed(offset: index + label.length),
    );
    _quillController.formatSelection(quill.LinkAttribute(url));
  }

  Future<void> _showAttachmentActions() async {
    final l = AppLocalizations.of(context)!;
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.cloud_upload_outlined),
                title: Text(l.mailComposeUploadAttachment),
                onTap: () => Navigator.of(context).pop('upload'),
              ),
              ListTile(
                leading: const Icon(Icons.link_outlined),
                title: Text(l.mailComposeAddAttachment),
                onTap: () => Navigator.of(context).pop('manual'),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || choice == null) return;
    if (choice == 'upload') {
      await _pickAndUploadAttachment();
    } else {
      await _addAttachment();
    }
  }
}
