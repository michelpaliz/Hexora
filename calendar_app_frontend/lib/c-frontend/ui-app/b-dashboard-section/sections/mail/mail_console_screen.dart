import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/a-models/mail/mail_attachment.dart';
import 'package:hexora/a-models/mail/mail_folder.dart';
import 'package:hexora/a-models/mail/mail_message.dart';
import 'package:hexora/a-models/mail/mail_thread.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_services/auth_service.dart';
import 'package:hexora/b-backend/auth_user/auth/token/service/authenticated_http_client.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:hexora/b-backend/emails/email_api.dart';
import 'package:hexora/b-backend/mail/domain/mail_domain.dart';
import 'package:hexora/b-backend/mail/models/mail_requests.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/dashboard/controller/group_dashboard_state.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/pdf_preview/file_download_launcher.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/mail/mail_compose_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/enable_banking/widgets/folder_section_card.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

part 'console/mail_console_conversation_pane.dart';
part 'console/mail_console_empty_card.dart';
part 'console/mail_console_left_rail.dart';
part 'console/mail_console_thread_row.dart';
part 'console/mail_console_thread_toolbar.dart';
part 'console/mail_console_utils.dart';
part 'console/mail_console_view.dart';
part 'console/mail_console_footer_manager.dart';
part 'console/mail_console_templates_manager.dart';

class MailConsoleScreen extends StatefulWidget {
  const MailConsoleScreen({
    super.key,
    this.initialFolder = MailFolder.inbox,
    this.initialThreadKey,
    this.embedded = false,
  });

  final MailFolder initialFolder;
  final String? initialThreadKey;
  final bool embedded;

  static MailConsoleScreen fromRoute(BuildContext context) {
    final name = ModalRoute.of(context)?.settings.name;
    final uri = name == null ? null : Uri.tryParse(name);
    final folderParam = uri?.queryParameters['folder'];
    final threadKey = uri?.queryParameters['thread'];
    final folder = MailFolderWire.fromWire(folderParam) ?? MailFolder.inbox;
    return MailConsoleScreen(
      initialFolder: folder,
      initialThreadKey: threadKey,
    );
  }

  @override
  State<MailConsoleScreen> createState() => _MailConsoleScreenState();
}

class _MailConsoleScreenState extends State<MailConsoleScreen> {
  late MailFolder _folder;
  String? _selectedThreadKey;
  String? _lastRoute;
  final ScrollController _threadScroll = ScrollController();
  final TextEditingController _replyCtrl = TextEditingController();

  bool _leftCollapsed = false;
  bool _showCompose = false;
  bool _showFooterManager = false;
  bool _showTemplateManager = false;

  bool _loadingClient = false;
  String? _clientError;
  GroupClient? _client;

  bool _loadingInvoices = false;
  String? _invoiceError;
  List<Invoice> _invoices = const [];
  String? _selectedInvoiceId;

  bool _sendingReply = false;
  bool _downloadingAttachment = false;
  Timer? _threadDebounce;

  final EmailApi _emailApi = EmailApi();

  void update(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  final TextEditingController _footerNameCtrl = TextEditingController();
  final TextEditingController _footerTextCtrl = TextEditingController();
  final TextEditingController _footerHtmlCtrl = TextEditingController();
  bool _footerDefault = true;
  bool _footerFormExpanded = true;
  String? _footerPreviewName;
  String? _footerPreviewText;
  String? _footerPreviewHtml;
  bool _footerPreviewDefault = false;
  bool _footerPreviewLoading = false;
  String? _footerPreviewError;
  DateTime? _footerPreviewedAt;

  final TextEditingController _templateNameCtrl = TextEditingController();
  final TextEditingController _templateSubjectCtrl = TextEditingController();
  final TextEditingController _templateTextCtrl = TextEditingController();
  final TextEditingController _templateHtmlCtrl = TextEditingController();
  bool _templateDefault = false;
  bool _templatesLoading = false;
  bool _templateSaving = false;
  bool _templateDeleting = false;
  String? _templateError;
  List<Map<String, dynamic>> _templates = const [];
  String? _selectedTemplateId;

  @override
  void initState() {
    super.initState();
    _folder = widget.initialFolder;
    _selectedThreadKey = widget.initialThreadKey;
    _threadScroll.addListener(_onThreadScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadThreads(refresh: true);
      if (_selectedThreadKey != null) {
        _selectThread(_selectedThreadKey!);
      }
    });
  }

  @override
  void dispose() {
    _threadScroll.removeListener(_onThreadScroll);
    _threadScroll.dispose();
    _replyCtrl.dispose();
    _threadDebounce?.cancel();
    _footerNameCtrl.dispose();
    _footerTextCtrl.dispose();
    _footerHtmlCtrl.dispose();
    _templateNameCtrl.dispose();
    _templateSubjectCtrl.dispose();
    _templateTextCtrl.dispose();
    _templateHtmlCtrl.dispose();
    super.dispose();
  }

  void _onThreadScroll() {
    if (!_threadScroll.hasClients) return;
    final position = _threadScroll.position;
    if (position.maxScrollExtent - position.pixels > 220) return;
    final domain = context.read<MailDomain>();
    final state = domain.threadsState;
    if (state.folder != _folder) return;
    if (state.loading || state.loadingMore) return;
    if (!state.hasMore) return;
    _loadThreads(refresh: false);
  }

  void _loadThreads({required bool refresh}) {
    _threadDebounce?.cancel();
    _threadDebounce = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      context.read<MailDomain>().loadThreads(folder: _folder, refresh: refresh);
    });
  }

  Future<void> _selectThread(String threadKey) async {
    setState(() {
      _showFooterManager = false;
      _showTemplateManager = false;
      _showCompose = false;
      _selectedThreadKey = threadKey;
      _client = null;
      _clientError = null;
      _invoices = const [];
      _invoiceError = null;
      _selectedInvoiceId = null;
    });
    _syncRoute();
    final domain = context.read<MailDomain>();
    await domain.loadThreadDetail(threadKey);
    if (!mounted) return;
    final detail = domain.threadState(threadKey).thread;
    if (detail != null) {
      _autoMarkLatestRead(detail);
      await _loadClientAndInvoices(detail);
    }
  }

  void _autoMarkLatestRead(MailThreadDetail detail) {
    final unread = detail.messages.where((m) => m.unread).toList();
    if (unread.isEmpty) return;
    unread.sort((a, b) {
      final aDate = a.date ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.date ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    final latest = unread.first;
    context.read<MailDomain>().markRead(latest.id);
  }

  Future<void> _loadClientAndInvoices(MailThreadDetail detail) async {
    final email = _pickCustomerEmail(detail.messages);
    if (email == null || email.isEmpty) {
      setState(() {
        _client = null;
        _clientError = null;
        _invoices = const [];
        _invoiceError = null;
        _selectedInvoiceId = null;
      });
      return;
    }
    await _lookupClient(email);
    final clientId = _client?.id;
    if (clientId != null && clientId.isNotEmpty) {
      await _loadInvoices(clientId);
    } else {
      setState(() {
        _invoices = const [];
        _invoiceError = null;
      });
    }
  }

  String? _pickCustomerEmail(List<MailMessage> messages) {
    final authEmail = context.read<AuthService>().currentUser?.email ?? '';
    final candidates = <String>{};
    for (final message in messages) {
      if (message.from?.address != null && message.from!.address.isNotEmpty) {
        candidates.add(message.from!.address);
      }
      for (final to in message.to) {
        if (to.address.isNotEmpty) candidates.add(to.address);
      }
    }
    if (authEmail.isNotEmpty) {
      candidates.removeWhere((e) => e.toLowerCase() == authEmail.toLowerCase());
    }
    if (candidates.isEmpty) return null;
    return candidates.first;
  }

  Future<void> _lookupClient(String email) async {
    setState(() {
      _loadingClient = true;
      _clientError = null;
    });
    try {
      final groupId = _currentGroupId();
      if (groupId == null || groupId.isEmpty) {
        setState(() => _client = null);
        return;
      }
      final uri = _clientsListUri(groupId);
      final r = await AuthenticatedHttpClient.get(uri, client: _http());
      if (r.statusCode < 200 || r.statusCode >= 300) {
        throw Exception(r.body.isNotEmpty ? r.body : r.reasonPhrase);
      }
      final decoded = jsonDecode(r.body);
      final list =
          decoded is List ? decoded : (decoded['items'] ?? decoded['data']);
      if (list is! List) {
        throw Exception('Unexpected clients payload');
      }
      final clients = list
          .whereType<Map>()
          .map((e) => GroupClient.fromJson(e.cast<String, dynamic>()))
          .toList();
      final target = email.trim().toLowerCase();
      GroupClient? match;
      for (final client in clients) {
        final billingEmail = client.billing?.email?.trim().toLowerCase();
        final directEmail = client.email?.trim().toLowerCase();
        if (billingEmail == target || directEmail == target) {
          match = client;
          break;
        }
      }
      setState(() => _client = match);
    } catch (e) {
      setState(() => _clientError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingClient = false);
    }
  }

  Future<void> _loadInvoices(String clientId) async {
    setState(() {
      _loadingInvoices = true;
      _invoiceError = null;
    });
    try {
      final uri = _invoicesUri(clientId);
      final r = await AuthenticatedHttpClient.get(uri, client: _http());
      if (r.statusCode < 200 || r.statusCode >= 300) {
        throw Exception(r.body.isNotEmpty ? r.body : r.reasonPhrase);
      }
      final decoded = jsonDecode(r.body);
      final list =
          decoded is List ? decoded : (decoded['items'] ?? decoded['data']);
      if (list is! List) {
        throw Exception('Unexpected invoices payload');
      }
      final invoices = list
          .whereType<Map>()
          .map((e) => Invoice.fromJson(e.cast<String, dynamic>()))
          .toList();
      final nextSelected = invoices.any((inv) => inv.id == _selectedInvoiceId)
          ? _selectedInvoiceId
          : (invoices.isNotEmpty ? invoices.first.id : null);
      setState(() {
        _invoices = invoices;
        _selectedInvoiceId = nextSelected;
      });
    } catch (e) {
      setState(() => _invoiceError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingInvoices = false);
    }
  }

  Future<void> _resendInvoice(Invoice invoice) async {
    final l = AppLocalizations.of(context)!;
    final clientEmail = _client?.billing?.email ?? _client?.email;
    if (clientEmail == null || clientEmail.isEmpty) {
      _toast(l.mailConsoleClientEmailMissing);
      return;
    }
    try {
      await _emailApi.sendInvoice({
        'invoiceId': invoice.id,
        'groupId': invoice.groupId,
        'to': clientEmail,
        'subject': l.mailConsoleInvoiceSubject(invoice.invoiceNumber),
        'text': l.mailConsoleInvoiceBody(invoice.invoiceNumber),
        'html': '<p>${l.mailConsoleInvoiceBody(invoice.invoiceNumber)}</p>',
        'attachPdf': true,
        'applyDefaultFooter': true,
      });
      _toast(l.mailConsoleInvoiceResent);
    } catch (e) {
      _toast(l.mailConsoleActionFailed(e.toString()));
    }
  }

  Future<void> _sendPaymentLink(Invoice invoice) async {
    final l = AppLocalizations.of(context)!;
    final clientEmail = _client?.billing?.email ?? _client?.email;
    if (clientEmail == null || clientEmail.isEmpty) {
      _toast(l.mailConsoleClientEmailMissing);
      return;
    }
    final uri = _invoiceActionUri(invoice.id, 'send-payment-link');
    try {
      final r = await AuthenticatedHttpClient.post(
        uri,
        client: _http(),
        body: jsonEncode({'email': clientEmail}),
      );
      if (r.statusCode < 200 || r.statusCode >= 300) {
        throw Exception(r.body.isNotEmpty ? r.body : r.reasonPhrase);
      }
      _toast(l.mailConsolePaymentLinkSent);
    } catch (e) {
      _toast(l.mailConsoleActionFailed(e.toString()));
    }
  }

  Future<void> _markPaid(Invoice invoice) async {
    final l = AppLocalizations.of(context)!;
    final uri = _invoiceActionUri(invoice.id, 'mark-paid');
    try {
      final r = await AuthenticatedHttpClient.post(uri, client: _http());
      if (r.statusCode < 200 || r.statusCode >= 300) {
        throw Exception(r.body.isNotEmpty ? r.body : r.reasonPhrase);
      }
      _toast(l.mailConsoleMarkedPaid);
      if (_client != null) {
        await _loadInvoices(_client!.id);
      }
    } catch (e) {
      _toast(l.mailConsoleActionFailed(e.toString()));
    }
  }

  Future<void> _sendReply(List<MailMessage> messages) async {
    if (_sendingReply) return;
    final l = AppLocalizations.of(context)!;
    final body = _replyCtrl.text.trim();
    if (body.isEmpty) return;
    final target = _latestMessage(messages);
    if (target == null) return;
    setState(() => _sendingReply = true);
    try {
      await context.read<MailDomain>().reply(
            target.id,
            MailReplyRequest(textBody: body),
          );
      _replyCtrl.clear();
      if (_selectedThreadKey != null) {
        await context.read<MailDomain>().loadThreadDetail(_selectedThreadKey!);
      }
      _loadThreads(refresh: true);
      _toast(l.mailConsoleReplySent);
    } catch (e) {
      _toast(l.mailConsoleActionFailed(e.toString()));
    } finally {
      if (mounted) setState(() => _sendingReply = false);
    }
  }

  Future<void> _openCompose() async {
    if (!mounted) return;
    setState(() {
      _showCompose = true;
      _showFooterManager = false;
      _showTemplateManager = false;
      _selectedThreadKey = null;
    });
  }

  Future<void> _refreshAll() async {
    _loadThreads(refresh: true);
    if (_selectedThreadKey != null) {
      await context.read<MailDomain>().loadThreadDetail(_selectedThreadKey!);
    }
  }

  Future<void> _markSelectedRead({required bool unread}) async {
    final l = AppLocalizations.of(context)!;
    final detail = _selectedThreadKey == null
        ? null
        : context.read<MailDomain>().threadState(_selectedThreadKey!).thread;
    if (detail == null) return;
    if (unread) {
      final latest = _latestMessage(detail.messages);
      if (latest == null) return;
      await context.read<MailDomain>().markUnread(latest.id);
      _toast(l.mailDetailMarkedUnread);
    } else {
      final unreadMessages = detail.messages.where((m) => m.unread).toList();
      if (unreadMessages.isEmpty) return;
      for (final message in unreadMessages) {
        await context.read<MailDomain>().markRead(message.id);
      }
      _toast(l.mailDetailMarkedRead);
    }
    _loadThreads(refresh: true);
  }

  Future<void> _moveSelectedThread(
    Future<void> Function(String) action, {
    String? toastMessage,
  }) async {
    final detail = _selectedThreadKey == null
        ? null
        : context.read<MailDomain>().threadState(_selectedThreadKey!).thread;
    final latest = detail == null ? null : _latestMessage(detail.messages);
    if (latest == null) return;
    await action(latest.id);
    if (toastMessage != null && toastMessage.isNotEmpty) {
      _toast(toastMessage);
    }
    setState(() => _selectedThreadKey = null);
    _loadThreads(refresh: true);
  }

  MailMessage? _latestMessage(List<MailMessage> messages) {
    if (messages.isEmpty) return null;
    final sorted = [...messages]..sort((a, b) {
        final aDate = a.date ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.date ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
    return sorted.first;
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _openFooterManager() {
    setState(() {
      _showFooterManager = true;
      _showTemplateManager = false;
      _showCompose = false;
      _selectedThreadKey = null;
    });
    _syncRoute();
  }

  Future<void> _openTemplateManager() async {
    setState(() {
      _showTemplateManager = true;
      _showFooterManager = false;
      _showCompose = false;
      _selectedThreadKey = null;
      _templateError = null;
    });
    _syncRoute();
    await _loadTemplates();
  }

  Uri _footersUri() {
    final base = ApiConstants.baseUrl.endsWith('/api')
        ? ApiConstants.baseUrl
        : '${ApiConstants.baseUrl}/api';
    return Uri.parse('$base/mail/footers');
  }

  Uri _templatesUri({String? templateId, String? groupId}) {
    final base = ApiConstants.baseUrl.endsWith('/api')
        ? ApiConstants.baseUrl
        : '${ApiConstants.baseUrl}/api';
    final path = templateId == null || templateId.isEmpty
        ? '$base/mail/templates'
        : '$base/mail/templates/$templateId';
    final uri = Uri.parse(path);
    if (groupId == null || groupId.isEmpty) return uri;
    final query = Map<String, String>.from(uri.queryParameters)
      ..putIfAbsent('groupId', () => groupId);
    return uri.replace(queryParameters: query);
  }

  Uri _defaultTemplateUri({required String groupId}) {
    final base = ApiConstants.baseUrl.endsWith('/api')
        ? ApiConstants.baseUrl
        : '${ApiConstants.baseUrl}/api';
    return Uri.parse('$base/mail/templates/default')
        .replace(queryParameters: {'groupId': groupId});
  }

  Uri _setDefaultTemplateUri(String templateId) {
    final base = ApiConstants.baseUrl.endsWith('/api')
        ? ApiConstants.baseUrl
        : '${ApiConstants.baseUrl}/api';
    return Uri.parse('$base/mail/templates/$templateId/default');
  }

  Uri _footersPreviewUri() {
    final base = ApiConstants.baseUrl.endsWith('/api')
        ? ApiConstants.baseUrl
        : '${ApiConstants.baseUrl}/api';
    return Uri.parse('$base/mail/footers/preview');
  }

  Future<void> _previewFooter({bool useSystemDefault = false}) async {
    final l = AppLocalizations.of(context)!;
    final groupId = _currentGroupId();
    if (groupId == null || groupId.isEmpty) {
      _toast(l.notAuthenticatedOrUserMissing);
      return;
    }

    setState(() {
      _footerPreviewLoading = true;
      _footerPreviewError = null;
      _footerPreviewHtml = null;
      _footerPreviewName =
          useSystemDefault ? null : _footerNameCtrl.text.trim();
      _footerPreviewText =
          useSystemDefault ? null : _footerTextCtrl.text.trim();
      _footerPreviewDefault = useSystemDefault;
      _footerPreviewedAt = null;
    });

    try {
      final body = jsonEncode({
        'groupId': groupId,
        if (useSystemDefault) 'useSystemDefault': true,
        if (!useSystemDefault)
          'text': _footerTextCtrl.text.trim().isEmpty
              ? null
              : _footerTextCtrl.text.trim(),
        if (!useSystemDefault)
          'html': _footerHtmlCtrl.text.trim().isEmpty
              ? null
              : _footerHtmlCtrl.text.trim(),
      });
      final r = await AuthenticatedHttpClient.post(
        _footersPreviewUri(),
        client: _http(),
        body: body,
      );
      debugPrint('[MailFooterPreview] status=${r.statusCode} body=${r.body}');
      if (r.statusCode < 200 || r.statusCode >= 300) {
        throw Exception(r.body.isNotEmpty ? r.body : r.reasonPhrase);
      }
      final decoded = jsonDecode(r.body);
      String? previewHtml;
      if (decoded is Map) {
        previewHtml = decoded['previewHtml']?.toString();
        previewHtml ??= decoded['html']?.toString();
      } else if (decoded is String) {
        previewHtml = decoded;
      }
      if (previewHtml != null && previewHtml.isNotEmpty) {
        setState(() {
          _footerPreviewHtml = previewHtml;
          _footerPreviewedAt = DateTime.now();
        });
      }
    } catch (e) {
      setState(() => _footerPreviewError = e.toString());
    } finally {
      if (mounted) setState(() => _footerPreviewLoading = false);
    }
  }

  Future<void> _createFooter() async {
    final l = AppLocalizations.of(context)!;
    final groupId = _currentGroupId();
    if (groupId == null || groupId.isEmpty) {
      _toast(l.notAuthenticatedOrUserMissing);
      return;
    }
    if (_footerNameCtrl.text.trim().isEmpty) {
      _toast(l.mailFooterNameRequired);
      return;
    }
    try {
      final body = jsonEncode({
        'groupId': groupId,
        'name': _footerNameCtrl.text.trim(),
        'text': _footerTextCtrl.text.trim().isEmpty
            ? null
            : _footerTextCtrl.text.trim(),
        'html': _footerHtmlCtrl.text.trim().isEmpty
            ? null
            : _footerHtmlCtrl.text.trim(),
        'isDefault': _footerDefault,
      });
      final r = await AuthenticatedHttpClient.post(
        _footersUri(),
        client: _http(),
        body: body,
      );
      if (r.statusCode < 200 || r.statusCode >= 300) {
        throw Exception(r.body.isNotEmpty ? r.body : r.reasonPhrase);
      }
      setState(() {
        _footerPreviewName = _footerNameCtrl.text.trim();
        _footerPreviewText = _footerTextCtrl.text.trim();
        _footerPreviewHtml = _footerHtmlCtrl.text.trim();
        _footerPreviewDefault = _footerDefault;
      });
      _toast(l.mailFooterSaved);
    } catch (e) {
      _toast(l.mailFooterSaveFailed(e.toString()));
    }
  }

  Future<void> _loadTemplates() async {
    final l = AppLocalizations.of(context)!;
    final groupId = _currentGroupId();
    if (groupId == null || groupId.isEmpty) {
      setState(() => _templateError = l.notAuthenticatedOrUserMissing);
      return;
    }
    setState(() {
      _templatesLoading = true;
      _templateError = null;
    });

    try {
      final listResp = await AuthenticatedHttpClient.get(
        _templatesUri(groupId: groupId),
        client: _http(),
      );
      if (listResp.statusCode < 200 || listResp.statusCode >= 300) {
        throw Exception(
            listResp.body.isNotEmpty ? listResp.body : listResp.reasonPhrase);
      }
      final defaultResp = await AuthenticatedHttpClient.get(
        _defaultTemplateUri(groupId: groupId),
        client: _http(),
      );

      final decodedList = jsonDecode(listResp.body);
      final rawTemplates = decodedList is List
          ? decodedList
          : (decodedList['items'] ?? decodedList['data'] ?? const []);

      final templates = rawTemplates is List
          ? rawTemplates
              .whereType<Map>()
              .map((e) => e.cast<String, dynamic>())
              .toList(growable: false)
          : const <Map<String, dynamic>>[];

      String? defaultId;
      if (defaultResp.statusCode >= 200 &&
          defaultResp.statusCode < 300 &&
          defaultResp.body.trim().isNotEmpty) {
        final decodedDefault = jsonDecode(defaultResp.body);
        if (decodedDefault is Map) {
          defaultId = (decodedDefault['id'] ?? decodedDefault['_id'])
              ?.toString()
              .trim();
        }
      }

      for (final template in templates) {
        final id = (template['id'] ?? template['_id'])?.toString().trim();
        template['isDefault'] = defaultId != null && id == defaultId;
      }

      setState(() {
        _templates = templates;
        _selectedTemplateId = _selectedTemplateId != null &&
                templates.any((t) =>
                    (t['id'] ?? t['_id'])?.toString().trim() ==
                    _selectedTemplateId)
            ? _selectedTemplateId
            : (templates.isNotEmpty
                ? (templates.first['id'] ?? templates.first['_id'])
                    ?.toString()
                    .trim()
                : null);
      });
      if (mounted && _showTemplateManager) {
        _loadTemplateIntoForm(_selectedTemplateId);
      }
    } catch (e) {
      setState(() => _templateError = e.toString());
    } finally {
      if (mounted) {
        setState(() => _templatesLoading = false);
      }
    }
  }

  void _loadTemplateIntoForm(String? templateId) {
    if (!mounted || !_showTemplateManager) return;
    Map<String, dynamic>? template;
    if (templateId != null && templateId.isNotEmpty) {
      for (final row in _templates) {
        final id = (row['id'] ?? row['_id'])?.toString().trim();
        if (id == templateId) {
          template = row;
          break;
        }
      }
    }

    final name = (template?['name'] ?? '').toString();
    final subject = (template?['subject'] ?? '').toString();
    final text = (template?['text'] ?? '').toString();
    final html = (template?['html'] ?? '').toString();

    try {
      if (_templateNameCtrl.text != name) _templateNameCtrl.text = name;
      if (_templateSubjectCtrl.text != subject) {
        _templateSubjectCtrl.text = subject;
      }
      if (_templateTextCtrl.text != text) _templateTextCtrl.text = text;
      if (_templateHtmlCtrl.text != html) _templateHtmlCtrl.text = html;
    } catch (_) {
      // Guard against transient web controller state during hot reload/rebuild.
    }
    _templateDefault = template?['isDefault'] == true;
  }

  void _selectTemplate(String templateId) {
    if (!_showTemplateManager) return;
    setState(() {
      _selectedTemplateId = templateId;
      _loadTemplateIntoForm(templateId);
    });
  }

  void _setTemplateDefaultLocal(bool value) {
    setState(() => _templateDefault = value);
  }

  void _newTemplate() {
    setState(() {
      _selectedTemplateId = null;
      _templateNameCtrl.clear();
      _templateSubjectCtrl.clear();
      _templateTextCtrl.clear();
      _templateHtmlCtrl.clear();
      _templateDefault = false;
      _templateError = null;
    });
  }

  Future<void> _saveTemplate() async {
    final l = AppLocalizations.of(context)!;
    final groupId = _currentGroupId();
    if (groupId == null || groupId.isEmpty) {
      _toast(l.notAuthenticatedOrUserMissing);
      return;
    }
    if (_templateNameCtrl.text.trim().isEmpty) {
      _toast(l.fieldIsRequired);
      return;
    }

    setState(() {
      _templateSaving = true;
      _templateError = null;
    });

    try {
      final body = jsonEncode({
        'groupId': groupId,
        'name': _templateNameCtrl.text.trim(),
        'subject': _templateSubjectCtrl.text.trim(),
        'text': _templateTextCtrl.text.trim(),
        'html': _templateHtmlCtrl.text.trim(),
        'isDefault': _templateDefault,
      });
      http.Response response;
      if (_selectedTemplateId == null || _selectedTemplateId!.isEmpty) {
        response = await AuthenticatedHttpClient.post(
          _templatesUri(),
          client: _http(),
          body: body,
        );
      } else {
        response = await AuthenticatedHttpClient.patch(
          _templatesUri(templateId: _selectedTemplateId, groupId: groupId),
          client: _http(),
          body: body,
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
            response.body.isNotEmpty ? response.body : response.reasonPhrase);
      }
      await _loadTemplates();
      _toast(l.saveDraft);
    } catch (e) {
      setState(() => _templateError = e.toString());
      _toast(e.toString());
    } finally {
      if (mounted) setState(() => _templateSaving = false);
    }
  }

  Future<void> _deleteTemplate() async {
    final l = AppLocalizations.of(context)!;
    if (_selectedTemplateId == null || _selectedTemplateId!.isEmpty) return;
    final groupId = _currentGroupId();
    if (groupId == null || groupId.isEmpty) {
      _toast(l.notAuthenticatedOrUserMissing);
      return;
    }
    setState(() {
      _templateDeleting = true;
      _templateError = null;
    });
    try {
      final resp = await AuthenticatedHttpClient.delete(
        _templatesUri(templateId: _selectedTemplateId, groupId: groupId),
        client: _http(),
      );
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw Exception(resp.body.isNotEmpty ? resp.body : resp.reasonPhrase);
      }
      _newTemplate();
      await _loadTemplates();
      _toast(l.remove);
    } catch (e) {
      setState(() => _templateError = e.toString());
      _toast(e.toString());
    } finally {
      if (mounted) setState(() => _templateDeleting = false);
    }
  }

  Future<void> _setDefaultTemplate() async {
    final l = AppLocalizations.of(context)!;
    if (_selectedTemplateId == null || _selectedTemplateId!.isEmpty) return;
    final groupId = _currentGroupId();
    if (groupId == null || groupId.isEmpty) {
      _toast(l.notAuthenticatedOrUserMissing);
      return;
    }
    setState(() => _templateSaving = true);
    try {
      final resp = await AuthenticatedHttpClient.post(
        _setDefaultTemplateUri(_selectedTemplateId!),
        client: _http(),
        body: jsonEncode({'groupId': groupId}),
      );
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw Exception(resp.body.isNotEmpty ? resp.body : resp.reasonPhrase);
      }
      await _loadTemplates();
      _toast(l.mailFooterDefaultBadge);
    } catch (e) {
      setState(() => _templateError = e.toString());
      _toast(e.toString());
    } finally {
      if (mounted) setState(() => _templateSaving = false);
    }
  }

  void _syncRoute() {
    if (widget.embedded) return;
    final thread = _selectedThreadKey;
    final query = <String, String>{
      'folder': _folder.wireName,
      if (thread != null && thread.isNotEmpty) 'thread': thread,
    };
    final next = '/mail?${Uri(queryParameters: query).query}';
    final current = ModalRoute.of(context)?.settings.name;
    if (current == next) {
      _lastRoute = next;
      return;
    }
    if (_lastRoute == next) return;
    _lastRoute = next;
    Navigator.of(context).pushReplacementNamed(next);
  }

  String? _currentGroupId() {
    try {
      return context.read<GroupDashboardState>().group.id;
    } catch (_) {
      return null;
    }
  }

  Uri _clientsListUri(String groupId) {
    final base = ApiConstants.baseUrl.endsWith('/api')
        ? '${ApiConstants.baseUrl}/clients'
        : '${ApiConstants.baseUrl}/api/clients';
    return Uri.parse(base).replace(queryParameters: {'groupId': groupId});
  }

  Uri _invoicesUri(String clientId) {
    final base = ApiConstants.baseUrl.endsWith('/api')
        ? '${ApiConstants.baseUrl}/invoices'
        : '${ApiConstants.baseUrl}/api/invoices';
    return Uri.parse(base).replace(queryParameters: {
      'clientId': clientId,
      'status': 'open,overdue',
    });
  }

  Uri _invoiceActionUri(String invoiceId, String action) {
    final base = ApiConstants.baseUrl.endsWith('/api')
        ? '${ApiConstants.baseUrl}/invoices'
        : '${ApiConstants.baseUrl}/api/invoices';
    return Uri.parse('$base/$invoiceId/$action');
  }

  http.Client _http() => context.read<http.Client>();

  @override
  Widget build(BuildContext context) {
    return _MailConsoleView(state: this);
  }

  Future<void> _downloadAttachment(
    MailAttachment attachment,
    MailDomain domain,
  ) async {
    if (_downloadingAttachment) return;
    setState(() => _downloadingAttachment = true);
    try {
      final response = await domain.downloadAttachment(attachment.id);
      final bytes = response.bodyBytes;
      final filename = attachment.filename?.trim().isNotEmpty == true
          ? attachment.filename!.trim()
          : 'attachment-${attachment.id}';
      final mimeType =
          response.headers['content-type'] ?? 'application/octet-stream';
      await launchFileDownload(
        bytes,
        fileName: filename,
        mimeType: mimeType,
      );
    } catch (e) {
      _toast(
          AppLocalizations.of(context)!.mailDetailDownloadFailed(e.toString()));
    } finally {
      if (mounted) setState(() => _downloadingAttachment = false);
    }
  }
}
