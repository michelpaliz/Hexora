import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/a-models/mail/mail_attachment.dart';
import 'package:hexora/a-models/mail/mail_folder.dart';
import 'package:hexora/a-models/mail/mail_message.dart';
import 'package:hexora/a-models/mail/mail_thread.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_services/auth_service.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:hexora/b-backend/emails/email_api.dart';
import 'package:hexora/b-backend/mail/domain/mail_domain.dart';
import 'package:hexora/b-backend/mail/models/mail_requests.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/pdf_preview/file_download_launcher.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/mail/mail_compose_screen.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

part 'console/mail_console_empty_card.dart';
part 'console/mail_console_left_rail.dart';
part 'console/mail_console_thread_row.dart';
part 'console/mail_console_thread_toolbar.dart';

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
      final token = await context.read<AuthService>().getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Not authenticated');
      }
      final uri = _clientsUri(email);
      final r = await _http().get(uri, headers: _authHeaders(token));
      if (r.statusCode < 200 || r.statusCode >= 300) {
        throw Exception(r.body.isNotEmpty ? r.body : r.reasonPhrase);
      }
      final decoded = jsonDecode(r.body);
      if (decoded is! Map) {
        throw Exception('Unexpected client payload');
      }
      final client = GroupClient.fromJson(decoded.cast<String, dynamic>());
      setState(() => _client = client);
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
      final token = await context.read<AuthService>().getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Not authenticated');
      }
      final uri = _invoicesUri(clientId);
      final r = await _http().get(uri, headers: _authHeaders(token));
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
      });
      _toast(l.mailConsoleInvoiceResent);
    } catch (e) {
      _toast(l.mailConsoleActionFailed(e.toString()));
    }
  }

  Future<void> _sendPaymentLink(Invoice invoice) async {
    final l = AppLocalizations.of(context)!;
    final token = await context.read<AuthService>().getToken();
    if (token == null || token.isEmpty) {
      _toast(l.notAuthenticatedOrUserMissing);
      return;
    }
    final clientEmail = _client?.billing?.email ?? _client?.email;
    if (clientEmail == null || clientEmail.isEmpty) {
      _toast(l.mailConsoleClientEmailMissing);
      return;
    }
    final uri = _invoiceActionUri(invoice.id, 'send-payment-link');
    try {
      final r = await _http().post(
        uri,
        headers: _authHeaders(token),
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
    final token = await context.read<AuthService>().getToken();
    if (token == null || token.isEmpty) {
      _toast(l.notAuthenticatedOrUserMissing);
      return;
    }
    final uri = _invoiceActionUri(invoice.id, 'mark-paid');
    try {
      final r = await _http().post(uri, headers: _authHeaders(token));
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
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MailComposeScreen()),
    );
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

  Uri _clientsUri(String email) {
    final base = ApiConstants.baseUrl.endsWith('/api')
        ? '${ApiConstants.baseUrl}/clients'
        : '${ApiConstants.baseUrl}/api/clients';
    return Uri.parse('$base/lookup').replace(queryParameters: {'email': email});
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

  Map<String, String> _authHeaders(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=UTF-8',
      };

  http.Client _http() => context.read<http.Client>();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final domain = context.watch<MailDomain>();
    final threadsState = domain.threadsState;
    final threadState = _selectedThreadKey == null
        ? null
        : domain.threadState(_selectedThreadKey!);
    final selectedThread = threadState?.thread;

    Widget leftColumn() {
      final railWidth = _leftCollapsed ? 68.0 : 240.0;
      return Container(
        width: railWidth,
        padding: const EdgeInsets.fromLTRB(14, 16, 12, 12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
          border: Border(
            right: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _leftCollapsed
                      ? const SizedBox.shrink()
                      : Text(
                          l.mailConsoleTitle,
                          style:
                              t.bodyLarge.copyWith(fontWeight: FontWeight.w800),
                        ),
                ),
                IconButton(
                  tooltip: _leftCollapsed ? 'Expand' : 'Collapse',
                  icon: Icon(
                    _leftCollapsed
                        ? Icons.chevron_right_rounded
                        : Icons.chevron_left_rounded,
                  ),
                  onPressed: () =>
                      setState(() => _leftCollapsed = !_leftCollapsed),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_leftCollapsed)
              IconButton(
                tooltip: l.mailComposeTitle,
                icon: const Icon(Icons.edit_outlined),
                onPressed: _openCompose,
              )
            else
              FilledButton.icon(
                onPressed: _openCompose,
                icon: const Icon(Icons.edit_outlined),
                label: Text(l.mailComposeTitle),
              ),
            const SizedBox(height: 18),
            if (!_leftCollapsed)
              Text(
                l.mailConsoleFoldersTitle,
                style: t.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 8),
            ...MailFolder.values.map(
              (folder) => _FolderNavTile(
                label: _folderLabel(folder, l),
                icon: _folderIcon(folder),
                selected: _folder == folder,
                compact: _leftCollapsed,
                onTap: () {
                  if (_folder == folder) return;
                  setState(() {
                    _folder = folder;
                    _selectedThreadKey = null;
                  });
                  _syncRoute();
                  _loadThreads(refresh: true);
                },
              ),
            ),
            const SizedBox(height: 12),
            Divider(color: cs.outlineVariant.withValues(alpha: 0.5)),
            const SizedBox(height: 8),
            if (!_leftCollapsed)
              Text(
                l.mailConsoleInvoiceActionsTitle,
                style: t.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 6),
            _SideActionTile(
              icon: Icons.send_outlined,
              label: l.mailConsoleResendInvoice,
              compact: _leftCollapsed,
            ),
            _SideActionTile(
              icon: Icons.link_outlined,
              label: l.mailConsoleSendPaymentLink,
              compact: _leftCollapsed,
            ),
            _SideActionTile(
              icon: Icons.check_circle_outline,
              label: l.mailConsoleMarkPaid,
              compact: _leftCollapsed,
            ),
          ],
        ),
      );
    }

    Widget threadList() {
      final threads = threadsState.folder == _folder
          ? threadsState.threads
          : const <MailThread>[];
      if (threadsState.loading && threads.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (threadsState.error != null && threads.isEmpty) {
        return _EmptyCard(
          title: l.mailConsoleLoadError,
          subtitle: l.tryAgain,
          icon: Icons.cloud_off_outlined,
          actionLabel: l.refreshAction,
          onAction: () => _loadThreads(refresh: true),
        );
      }
      if (!threadsState.loading && threads.isEmpty) {
        return _EmptyCard(
          title: l.mailThreadsEmpty,
          subtitle: l.mailConsoleSelectThread,
          icon: Icons.inbox_outlined,
          actionLabel: l.mailComposeTitle,
          onAction: _openCompose,
        );
      }

      final itemCount = threads.length + (threadsState.loadingMore ? 1 : 0);

      return ListView.separated(
        controller: _threadScroll,
        padding: const EdgeInsets.all(12),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index >= threads.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final thread = threads[index];
          return _ThreadRow(
            thread: thread,
            selected: thread.threadKey == _selectedThreadKey,
            onTap: () => _selectThread(thread.threadKey),
          );
        },
      );
    }

    Widget middleColumn() {
      return Expanded(
        flex: 2,
        child: Column(
          children: [
            _ThreadToolbar(
              folder: _folder,
              hasSelection: selectedThread != null,
              hasUnread: selectedThread?.messages.any((m) => m.unread) ?? false,
              onRefresh: _refreshAll,
              onToggleRead: () => _markSelectedRead(
                unread:
                    !(selectedThread?.messages.any((m) => m.unread) ?? false),
              ),
              onArchive: () => _moveSelectedThread(
                context.read<MailDomain>().archive,
                toastMessage: l.mailDetailArchived,
              ),
              onSpam: () => _moveSelectedThread(
                context.read<MailDomain>().spam,
                toastMessage: l.mailDetailSpammed,
              ),
              onTrash: () => _moveSelectedThread(
                context.read<MailDomain>().trash,
                toastMessage: l.mailDetailTrashed,
              ),
            ),
            Expanded(child: threadList()),
          ],
        ),
      );
    }

    Widget rightColumn() {
      return Expanded(
        flex: 3,
        child: _selectedThreadKey == null
            ? Center(child: Text(l.mailConsoleSelectThread))
            : (selectedThread == null)
                ? (threadState?.error != null)
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(l.mailConsoleLoadError),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => context
                                  .read<MailDomain>()
                                  .loadThreadDetail(_selectedThreadKey!),
                              child: Text(l.tryAgain),
                            ),
                          ],
                        ),
                      )
                    : const Center(child: CircularProgressIndicator())
                : _ConversationPane(
                    thread: selectedThread,
                    onReply: _sendReply,
                    replyController: _replyCtrl,
                    sendingReply: _sendingReply,
                    onDownloadAttachment: (attachment) =>
                        _downloadAttachment(attachment, domain),
                    client: _client,
                    clientLoading: _loadingClient,
                    clientError: _clientError,
                    invoices: _invoices,
                    invoicesLoading: _loadingInvoices,
                    invoicesError: _invoiceError,
                    selectedInvoiceId: _selectedInvoiceId,
                    onSelectInvoice: (id) =>
                        setState(() => _selectedInvoiceId = id),
                    onResendInvoice: _resendInvoice,
                    onMarkPaid: _markPaid,
                    onSendPaymentLink: _sendPaymentLink,
                  ),
      );
    }

    final content = Row(
      children: [
        leftColumn(),
        Expanded(
          child: Row(
            children: [
              middleColumn(),
              Container(
                width: 1,
                color: cs.outlineVariant.withValues(alpha: 0.5),
              ),
              rightColumn(),
            ],
          ),
        ),
      ],
    );

    if (widget.embedded) return content;
    return Scaffold(
      appBar: AppBar(title: Text(l.mailConsoleTitle)),
      body: content,
    );
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

class _ConversationPane extends StatelessWidget {
  const _ConversationPane({
    required this.thread,
    required this.onReply,
    required this.replyController,
    required this.sendingReply,
    required this.onDownloadAttachment,
    required this.client,
    required this.clientLoading,
    required this.clientError,
    required this.invoices,
    required this.invoicesLoading,
    required this.invoicesError,
    required this.selectedInvoiceId,
    required this.onSelectInvoice,
    required this.onResendInvoice,
    required this.onMarkPaid,
    required this.onSendPaymentLink,
  });

  final MailThreadDetail thread;
  final Future<void> Function(List<MailMessage>) onReply;
  final TextEditingController replyController;
  final bool sendingReply;
  final ValueChanged<MailAttachment> onDownloadAttachment;

  final GroupClient? client;
  final bool clientLoading;
  final String? clientError;
  final List<Invoice> invoices;
  final bool invoicesLoading;
  final String? invoicesError;
  final String? selectedInvoiceId;
  final ValueChanged<String> onSelectInvoice;
  final ValueChanged<Invoice> onResendInvoice;
  final ValueChanged<Invoice> onMarkPaid;
  final ValueChanged<Invoice> onSendPaymentLink;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final messages = [...thread.messages]..sort((a, b) {
        final aDate = a.date ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.date ?? DateTime.fromMillisecondsSinceEpoch(0);
        return aDate.compareTo(bDate);
      });
    final subject = thread.subject.trim().isEmpty
        ? l.mailDetailNoSubject
        : thread.subject.trim();
    final participants =
        thread.participants.isEmpty ? '-' : thread.participants.join(', ');

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
            border: Border(
              bottom:
                  BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(subject,
                        style:
                            t.bodyLarge.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(
                      participants,
                      style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          return _MessageCard(
                            message: messages[index],
                            onDownloadAttachment: onDownloadAttachment,
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            cs.surfaceContainerHighest.withValues(alpha: 0.5),
                        border: Border(
                          top: BorderSide(
                            color: cs.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: replyController,
                              maxLines: 2,
                              decoration: InputDecoration(
                                hintText: l.mailConsoleReplyPlaceholder,
                                filled: true,
                                fillColor: cs.surfaceContainerHighest
                                    .withValues(alpha: 0.6),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: cs.outlineVariant),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: cs.outlineVariant),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            onPressed:
                                sendingReply ? null : () => onReply(messages),
                            icon: sendingReply
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.send_rounded),
                            label: Text(
                              sendingReply
                                  ? l.mailConsoleReplySending
                                  : l.mailConsoleReplySend,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                color: cs.outlineVariant.withValues(alpha: 0.5),
              ),
              SizedBox(
                width: 320,
                child: _ClientInvoicePanel(
                  client: client,
                  loading: clientLoading,
                  error: clientError,
                  invoices: invoices,
                  invoicesLoading: invoicesLoading,
                  invoicesError: invoicesError,
                  selectedInvoiceId: selectedInvoiceId,
                  onSelectInvoice: onSelectInvoice,
                  onResendInvoice: onResendInvoice,
                  onSendPaymentLink: onSendPaymentLink,
                  onMarkPaid: onMarkPaid,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.message,
    required this.onDownloadAttachment,
  });

  final MailMessage message;
  final ValueChanged<MailAttachment> onDownloadAttachment;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final fromLabel = message.fromAddress.isEmpty
        ? l.mailDetailUnknownSender
        : message.fromAddress;
    final toLabel =
        message.to.isEmpty ? '-' : message.to.map((e) => e.display).join(', ');
    final dateLabel = message.date == null
        ? '-'
        : DateFormat.yMMMd(l.localeName).add_jm().format(message.date!);
    final htmlBody = message.htmlBody?.trim();
    final textBody = message.textBody?.trim();
    final hasHtml = htmlBody != null && htmlBody.isNotEmpty;
    final body = hasHtml ? htmlBody : (textBody ?? '');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    fromLabel,
                    style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  dateLabel,
                  style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _MetadataRow(label: l.mailDetailToLabel, value: toLabel),
            const SizedBox(height: 8),
            if (body.isNotEmpty)
              hasHtml
                  ? Html(
                      data: body,
                      style: {
                        'body': Style(
                          margin: Margins.zero,
                          padding: HtmlPaddings.zero,
                          color: cs.onSurface,
                          fontSize: FontSize(t.bodySmall.fontSize ?? 14),
                          fontFamily: t.bodySmall.fontFamily,
                        ),
                        'p': Style(margin: Margins.only(bottom: 10)),
                      },
                    )
                  : Text(
                      body,
                      style: t.bodySmall.copyWith(color: cs.onSurface),
                    ),
            if (message.attachments.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                l.mailDetailAttachmentsLabel,
                style: t.bodySmall.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              ...message.attachments.map(
                (attachment) => _AttachmentRow(
                  attachment: attachment,
                  onDownload: () => onDownloadAttachment(attachment),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AttachmentRow extends StatelessWidget {
  const _AttachmentRow({required this.attachment, required this.onDownload});

  final MailAttachment attachment;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final filename = attachment.filename?.trim().isNotEmpty == true
        ? attachment.filename!.trim()
        : l.mailDetailAttachmentFallback;
    final sizeLabel = _formatBytes(attachment.size);

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.attach_file, size: 18),
      title: Text(filename, style: t.bodySmall),
      subtitle: sizeLabel == null
          ? null
          : Text(sizeLabel,
              style: t.bodySmall.copyWith(color: cs.onSurfaceVariant)),
      trailing: IconButton(
        tooltip: l.mailDetailDownloadTooltip,
        icon: const Icon(Icons.download_outlined),
        onPressed: onDownload,
      ),
    );
  }
}

class _ClientInvoicePanel extends StatelessWidget {
  const _ClientInvoicePanel({
    required this.client,
    required this.loading,
    required this.error,
    required this.invoices,
    required this.invoicesLoading,
    required this.invoicesError,
    required this.selectedInvoiceId,
    required this.onSelectInvoice,
    required this.onResendInvoice,
    required this.onSendPaymentLink,
    required this.onMarkPaid,
  });

  final GroupClient? client;
  final bool loading;
  final String? error;
  final List<Invoice> invoices;
  final bool invoicesLoading;
  final String? invoicesError;
  final String? selectedInvoiceId;
  final ValueChanged<String> onSelectInvoice;
  final ValueChanged<Invoice> onResendInvoice;
  final ValueChanged<Invoice> onSendPaymentLink;
  final ValueChanged<Invoice> onMarkPaid;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    Invoice? selected;
    for (final inv in invoices) {
      if (inv.id == selectedInvoiceId) {
        selected = inv;
        break;
      }
    }
    selected ??= invoices.isNotEmpty ? invoices.first : null;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.mailConsoleClientPanelTitle,
            style: t.bodyMedium.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (loading)
            const Center(child: CircularProgressIndicator())
          else if (error != null)
            Text(error!, style: t.bodySmall.copyWith(color: cs.error))
          else if (client == null)
            Text(l.mailConsoleClientNotFound,
                style: t.bodySmall.copyWith(color: cs.onSurfaceVariant))
          else
            Card(
              margin: EdgeInsets.zero,
              color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
              child: ListTile(
                title: Text(client!.name, style: t.bodySmall),
                subtitle: Text(
                  client!.billing?.email ?? client!.email ?? '-',
                  style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            l.mailConsoleOpenInvoicesTitle,
            style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (invoicesLoading)
            const Center(child: CircularProgressIndicator())
          else if (invoicesError != null)
            Text(invoicesError!, style: t.bodySmall.copyWith(color: cs.error))
          else if (invoices.isEmpty)
            Text(l.mailConsoleInvoicesEmpty,
                style: t.bodySmall.copyWith(color: cs.onSurfaceVariant))
          else
            ...invoices.take(3).map(
                  (inv) => _InvoiceRow(
                    invoice: inv,
                    selected: inv.id == selectedInvoiceId,
                    onTap: () => onSelectInvoice(inv.id),
                  ),
                ),
          const Spacer(),
          if (selected != null) ...[
            Text(
              l.mailConsoleInvoiceActionsTitle,
              style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => onResendInvoice(selected!),
              child: Text(l.mailConsoleResendInvoice),
            ),
            const SizedBox(height: 6),
            OutlinedButton(
              onPressed: () => onSendPaymentLink(selected!),
              child: Text(l.mailConsoleSendPaymentLink),
            ),
            const SizedBox(height: 6),
            OutlinedButton(
              onPressed: () => onMarkPaid(selected!),
              child: Text(l.mailConsoleMarkPaid),
            ),
          ],
        ],
      ),
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  const _InvoiceRow({
    required this.invoice,
    required this.selected,
    required this.onTap,
  });

  final Invoice invoice;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final number = invoice.invoiceNumber.isEmpty
        ? l.mailConsoleInvoiceUnknown
        : invoice.invoiceNumber;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: selected
          ? cs.primaryContainer.withValues(alpha: 0.4)
          : cs.surfaceContainerHighest.withValues(alpha: 0.6),
      child: ListTile(
        onTap: onTap,
        title: Text(number, style: t.bodySmall),
        subtitle: Text(
          invoice.status ?? l.invoiceStatusUnknown,
          style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(label,
              style: t.bodySmall.copyWith(color: cs.onSurfaceVariant)),
        ),
        Expanded(
          child: Text(
            value,
            style: t.bodySmall.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

String _folderLabel(MailFolder folder, AppLocalizations l) {
  switch (folder) {
    case MailFolder.inbox:
      return 'INBOX';
    case MailFolder.sent:
      return 'Sent';
    case MailFolder.archive:
      return 'Archive';
    case MailFolder.trash:
      return 'Trash';
    case MailFolder.spam:
      return 'Spam';
  }
}

IconData _folderIcon(MailFolder folder) {
  switch (folder) {
    case MailFolder.inbox:
      return Icons.inbox_outlined;
    case MailFolder.sent:
      return Icons.send_outlined;
    case MailFolder.archive:
      return Icons.archive_outlined;
    case MailFolder.trash:
      return Icons.delete_outline;
    case MailFolder.spam:
      return Icons.report_gmailerrorred_outlined;
  }
}

String _shortParticipants(List<String> participants) {
  if (participants.isEmpty) return '';
  if (participants.length <= 2) return participants.join(', ');
  final rest = participants.length - 2;
  return '${participants.take(2).join(', ')} +$rest';
}

String _formatRelativeDate(DateTime? date) {
  if (date == null) return '-';
  final now = DateTime.now();
  final diff = now.difference(date);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  final weeks = (diff.inDays / 7).floor();
  if (weeks < 5) return '${weeks}w';
  final months = (diff.inDays / 30).floor();
  if (months < 12) return '${months}mo';
  final years = (diff.inDays / 365).floor();
  return '${years}y';
}

String? _formatBytes(int? bytes) {
  if (bytes == null) return null;
  if (bytes < 1024) return '${bytes} B';
  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
  final mb = kb / 1024;
  if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
  final gb = mb / 1024;
  return '${gb.toStringAsFixed(2)} GB';
}
