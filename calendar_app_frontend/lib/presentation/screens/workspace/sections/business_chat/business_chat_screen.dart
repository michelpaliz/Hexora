import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/services/auth/token/token_service.dart';
import 'package:hexora/services/business_chat/business_chat_api.dart';
import 'package:hexora/services/business_chat/business_chat_drafts.dart';
import 'package:hexora/services/config/api_constants.dart';
import 'package:hexora/services/shared/backend_api_exception.dart';
import 'package:hexora/services/groups/domain/group_domain.dart';
import 'package:hexora/presentation/shared/widgets/avatars/avatar_utils.dart';
import 'package:hexora/presentation/screens/workspace/sections/enable_banking/enable_banking_screen.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/group_invoices_screen.dart';
import 'package:hexora/presentation/screens/workspace/sections/expenses/upload/expense_upload_screen.dart';
import 'package:hexora/presentation/screens/workspace/sections/workers/workers_hub_screen.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/tabs/workspace_content.dart';
import 'package:hexora/presentation/screens/workspace/sections/enable_banking/statements/shared/bank_transaction_share_dialog.dart';
import 'package:hexora/theme/colors/app_colors.dart';
import 'package:hexora/theme/themes/navigation_tokens.dart';
import 'package:hexora/presentation/shared/widgets/sidebar_edge_shell.dart';
import 'package:provider/provider.dart';
import 'bank_transaction_chat_card.dart';
import 'bank_transaction_picker.dart';
import 'document_review_dialog.dart';
import 'business_chat_search_dialog.dart';
import 'compact_conversation_tile.dart';
import 'widgets/chat_user_avatar.dart';
import 'widgets/compact_chat_bubble.dart';
import 'widgets/chat_message_actions.dart';
import 'widgets/chat_channel_header.dart';
import 'widgets/chat_composer.dart';
import 'widgets/chat_inbox_search.dart';
import 'widgets/mobile_chat_inbox_header.dart';
import 'package:intl/intl.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:url_launcher/url_launcher.dart';

class BusinessChatScreen extends StatefulWidget {
  const BusinessChatScreen(
      {super.key,
      required this.groupId,
      required this.currentUserId,
      this.initialConversationId,
      this.onExit});
  final String groupId;
  final String? currentUserId;
  final String? initialConversationId;

  /// When provided, the chat owns its header (no outer app bar) and shows a
  /// back button that invokes this; used by the full-screen mobile entry
  /// points. Left null for the embedded desktop panel.
  final VoidCallback? onExit;

  @override
  State<BusinessChatScreen> createState() => _BusinessChatScreenState();
}

class _BusinessChatScreenState extends State<BusinessChatScreen> {
  final _api = BusinessChatApi();
  final _draftStore = BusinessChatDrafts();
  final _composer = TextEditingController();
  final _conversationSearch = TextEditingController();
  final _scroll = ScrollController();
  final _drafts = <String, String>{};
  Timer? _draftTimer;
  int _draftRevision = 0;
  bool _restoringDraft = false;
  BusinessChatMessage? _replyingTo;
  List<BusinessChatConversation> _conversations = const [];
  List<BusinessChatMessage> _messages = const [];
  bool _hasOlderMessages = false;
  bool _loadingOlderMessages = false;
  String? _olderCursor;
  BusinessChatConversation? _selected;
  Timer? _timer;
  int _refreshTicks = 0;
  Timer? _socketDebounce;
  io.Socket? _socket;
  bool _loading = false;
  bool _refreshQueued = false;
  bool _sending = false;
  bool _liveConnected = false;
  bool _canCreateTeam = false;
  bool _canCreateIssues = true;
  bool _canManageIssues = false;
  bool _canAssignIssues = false;
  bool _canShareBankTransactions = false;
  bool _canRequestDocumentReview = false;
  bool _showActions = false;
  bool _chatPaneCollapsed = false;
  String? _activeBusinessAction;
  Widget? _reviewPanel;
  bool _reviewCollapsed = false;
  bool _showChatOnNarrow = false;
  String? _error;
  String? _pendingConversationId;
  final _composerFocus = FocusNode();
  Map<String, String?> _memberPhotos = const {};
  bool get _es => Localizations.localeOf(context).languageCode == 'es';

  Future<void> _loadMemberPhotos() async {
    final requestedGroupId = widget.groupId;
    try {
      final members = await _api.memberPresence(requestedGroupId);
      if (!mounted || requestedGroupId != widget.groupId) return;
      setState(() => _memberPhotos = {
            for (final member in members) member.id: member.photoUrl,
          });
    } catch (_) {
      // Avatars fall back to initials when presence is unavailable.
    }
  }

  @override
  void initState() {
    super.initState();
    _pendingConversationId = widget.initialConversationId;
    _composer.addListener(_onComposerChanged);
    _refresh();
    _loadMemberPhotos();
    _connectSocket();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      _refreshTicks += 1;
      if (_refreshTicks % 4 == 0 ||
          _messages.any((message) => message.bankTransaction != null)) {
        _refresh(silent: true);
      }
    });
  }

  Future<void> _connectSocket() async {
    final token = await TokenService.loadToken();
    if (!mounted || token == null || token.isEmpty) return;
    final socket = io.io(ApiConstants.socketBaseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'forceNew': true,
      'auth': {'token': token},
    });
    _socket = socket;
    socket.onConnect((_) {
      if (mounted) setState(() => _liveConnected = true);
    });
    socket.onDisconnect((_) {
      if (mounted) setState(() => _liveConnected = false);
    });
    socket.onConnectError((_) {
      if (mounted) setState(() => _liveConnected = false);
    });
    socket.on('business-chat:changed', (data) {
      if (!mounted ||
          data is! Map ||
          data['groupId']?.toString() != widget.groupId) return;
      _socketDebounce?.cancel();
      _socketDebounce = Timer(
          const Duration(milliseconds: 250), () => _refresh(silent: true));
    });
    socket.on('business-chat:revoked', (data) {
      if (!mounted ||
          data is! Map ||
          data['groupId']?.toString() != widget.groupId) return;
      _revokeVisibleAccess();
    });
    socket.connect();
  }

  @override
  void didUpdateWidget(covariant BusinessChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupId != widget.groupId ||
        oldWidget.currentUserId != widget.currentUserId) {
      _saveDraft(_selected?.id,
          groupId: oldWidget.groupId, userId: oldWidget.currentUserId);
      _draftTimer?.cancel();
      _draftRevision++;
      _drafts.clear();
      _replyingTo = null;
      _restoringDraft = true;
      _composer.clear();
      _restoringDraft = false;
      _conversations = const [];
      _selected = null;
      _messages = const [];
      _hasOlderMessages = false;
      _olderCursor = null;
      _conversationSearch.clear();
      _pendingConversationId = widget.initialConversationId;
      _showChatOnNarrow = false;
      _error = null;
      _canCreateTeam = false;
      _canCreateIssues = false;
      _canShareBankTransactions = false;
      _canRequestDocumentReview = false;
      _activeBusinessAction = null;
      _showActions = false;
      _reviewPanel = null;
      _canManageIssues = false;
      _canAssignIssues = false;
      _memberPhotos = const {};
      _refresh();
      _loadMemberPhotos();
    } else if (oldWidget.initialConversationId !=
        widget.initialConversationId) {
      _pendingConversationId = widget.initialConversationId;
      _refresh();
    }
  }

  @override
  void dispose() {
    _saveDraft(_selected?.id);
    _draftTimer?.cancel();
    _composer.removeListener(_onComposerChanged);
    _timer?.cancel();
    _socketDebounce?.cancel();
    _socket?.dispose();
    _composer.dispose();
    _composerFocus.dispose();
    _conversationSearch.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _revokeVisibleAccess() {
    if (!mounted) return;
    _draftTimer?.cancel();
    _draftRevision++;
    _drafts.clear();
    _replyingTo = null;
    _restoringDraft = true;
    _composer.clear();
    _restoringDraft = false;
    final userId = widget.currentUserId;
    if (userId != null) {
      unawaited(
          _draftStore.clearGroup(userId, widget.groupId).catchError((_) {}));
    }
    setState(() {
      _conversations = const [];
      _messages = const [];
      _selected = null;
      _showChatOnNarrow = false;
      _canCreateTeam = false;
      _canCreateIssues = false;
      _canShareBankTransactions = false;
      _canRequestDocumentReview = false;
      _canManageIssues = false;
      _canAssignIssues = false;
      _reviewPanel = null;
      _error = _es
          ? 'Ya no tienes acceso al chat de este negocio.'
          : 'You no longer have access to this business chat.';
    });
  }

  void _onComposerChanged() {
    if (_restoringDraft || _selected == null) return;
    final conversationId = _selected!.id;
    _drafts[conversationId] = _composer.text;
    _draftTimer?.cancel();
    _draftTimer = Timer(
        const Duration(milliseconds: 500), () => _saveDraft(conversationId));
  }

  void _saveDraft(String? conversationId, {String? groupId, String? userId}) {
    final ownerId = userId ?? widget.currentUserId;
    if (conversationId == null || ownerId == null) return;
    final text = _drafts[conversationId] ?? _composer.text;
    unawaited(_draftStore
        .write(ownerId, groupId ?? widget.groupId, conversationId, text)
        .catchError((_) {}));
  }

  void _switchDraft(String? oldId, String? newId) {
    if (oldId == newId) return;
    _draftTimer?.cancel();
    _saveDraft(oldId);
    final revision = ++_draftRevision;
    _replyingTo = null;
    _restoringDraft = true;
    _composer.text = _drafts[newId] ?? '';
    _restoringDraft = false;
    final userId = widget.currentUserId;
    if (newId == null || userId == null || _drafts.containsKey(newId)) return;
    unawaited(_draftStore.read(userId, widget.groupId, newId).then((saved) {
      if (!mounted ||
          revision != _draftRevision ||
          _selected?.id != newId ||
          _composer.text.isNotEmpty ||
          saved == null) return;
      _drafts[newId] = saved;
      _restoringDraft = true;
      _composer.text = saved;
      _restoringDraft = false;
    }).catchError((_) {}));
  }

  Future<void> _refresh({bool silent = false}) async {
    if (_loading) {
      _refreshQueued = true;
      return;
    }
    final requestedGroupId = widget.groupId;
    setState(() {
      _loading = true;
      if (!silent) _error = null;
    });
    try {
      final data = await _api.conversations(requestedGroupId);
      if (!mounted || requestedGroupId != widget.groupId) return;
      final next =
          List<BusinessChatConversation>.from(data['conversations'] as List);
      final oldId = _selected?.id;
      final pendingId = _pendingConversationId;
      final pendingFound =
          pendingId == null || next.any((item) => item.id == pendingId);
      setState(() {
        _error = pendingFound
            ? null
            : (_es
                ? 'Esta conversación ya no está disponible o no tienes acceso.'
                : 'This conversation is no longer available or you do not have access.');
        _conversations = next;
        _selected = pendingFound
            ? (next.where((item) => item.id == pendingId).firstOrNull ??
                next.where((item) => item.id == oldId).firstOrNull ??
                next.where((item) => item.type == 'general').firstOrNull ??
                (next.isEmpty ? null : next.first))
            : null;
        if (_selected?.id != oldId) {
          _messages = const [];
          _hasOlderMessages = false;
          _olderCursor = null;
        }
        if (_selected == null) _showChatOnNarrow = false;
        if (pendingId != null && pendingFound) _showChatOnNarrow = true;
        _canCreateTeam =
            (data['capabilities'] as Map?)?['canCreateTeam'] == true;
        _canCreateIssues =
            (data['capabilities'] as Map?)?['canCreateIssues'] == true;
        _canManageIssues =
            (data['capabilities'] as Map?)?['canManageIssues'] == true;
        _canAssignIssues =
            (data['capabilities'] as Map?)?['canAssignIssues'] == true;
        _canShareBankTransactions =
            (data['capabilities'] as Map?)?['canShareBankTransactions'] == true;
        _canRequestDocumentReview =
            (data['capabilities'] as Map?)?['canRequestDocumentReview'] == true;
      });
      _switchDraft(oldId, _selected?.id);
      _pendingConversationId = null;
      if (_selected != null) {
        await _loadMessages(_selected!, forceScroll: oldId != _selected!.id);
      }
    } catch (error) {
      if (requestedGroupId != widget.groupId) {
        return;
      } else if (error is BackendApiException && error.statusCode == 403) {
        _revokeVisibleAccess();
      } else if (mounted && !silent) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        if (requestedGroupId != widget.groupId || _refreshQueued) {
          final groupChanged = requestedGroupId != widget.groupId;
          _refreshQueued = false;
          Future<void>.microtask(() => _refresh(silent: !groupChanged));
        }
      }
    }
  }

  Future<void> _showMemberPresence() async {
    await showDialog<void>(
      context: context,
      builder: (_) => _BusinessChatMembersDialog(
        api: _api,
        groupId: widget.groupId,
        spanish: _es,
      ),
    );
  }

  Future<void> _showGeneralMembers() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_es ? 'Miembros de General' : 'General members'),
        content: Text(_es
            ? 'General incluye automáticamente a los miembros del negocio. Para añadir o quitar a alguien, gestiona su acceso en Miembros. Los chats de equipo e incidencias sí permiten gestionar participantes por separado.'
            : 'General automatically includes business members. Add or remove people through Business Members. Team and incident chats manage participants separately.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(_es ? 'Cerrar' : 'Close'),
          ),
          if (_canCreateTeam)
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _createTeam();
              },
              child: Text(_es ? 'Crear chat de equipo' : 'Create team chat'),
            ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _showMemberPresence();
            },
            child: Text(_es ? 'Ver miembros' : 'View members'),
          ),
        ],
      ),
    );
  }

  Future<void> _searchHistory() async {
    final conversation = _selected;
    if (conversation == null) return;
    final result = await showDialog<BusinessChatMessage>(
      context: context,
      builder: (_) => BusinessChatSearchDialog(
        api: _api,
        groupId: widget.groupId,
        conversationId: conversation.id,
      ),
    );
    if (!mounted || result == null || _selected?.id != conversation.id) return;
    setState(() => _replyingTo = result);
  }

  Future<void> _loadMessages(BusinessChatConversation conversation,
      {bool forceScroll = false}) async {
    try {
      final nearLatest =
          !_scroll.hasClients || _scroll.position.extentAfter < 120;
      final page = await _api.messages(widget.groupId, conversation.id);
      if (!mounted || _selected?.id != conversation.id) return;
      setState(() {
        if (_messages.isEmpty ||
            forceScroll ||
            (page.hasMore &&
                !page.messages
                    .any((message) => message.id == _messages.last.id))) {
          _messages = page.messages;
          _hasOlderMessages = page.hasMore;
          _olderCursor = page.nextCursor;
        } else {
          final byId = <String, BusinessChatMessage>{
            for (final message in _messages) message.id: message,
            for (final message in page.messages) message.id: message,
          };
          _messages = byId.values.toList()
            ..sort((a, b) {
              final date = a.createdAt.compareTo(b.createdAt);
              return date != 0 ? date : a.id.compareTo(b.id);
            });
          if (_olderCursor == null) {
            _hasOlderMessages = page.hasMore;
            _olderCursor = page.nextCursor;
          }
        }
      });
      if (forceScroll || nearLatest) _scrollToEnd();
      await _api.markRead(widget.groupId, conversation.id);
      if (mounted && _selected?.id == conversation.id) {
        final readConversation = conversation.copyWith(unreadCount: 0);
        setState(() {
          _selected = readConversation;
          _conversations = _conversations
              .map((item) =>
                  item.id == conversation.id ? readConversation : item)
              .toList();
        });
      }
    } catch (error) {
      if (error is BackendApiException &&
          (error.statusCode == 403 || error.statusCode == 404)) {
        if (mounted) {
          setState(() => _messages = const []);
          Future<void>.delayed(const Duration(milliseconds: 100), () {
            if (mounted) _refresh(silent: true);
          });
        }
      } else if (mounted) {
        setState(() => _error = error.toString());
      }
    }
  }

  Future<void> _loadOlderMessages() async {
    final conversation = _selected;
    final cursor = _olderCursor;
    if (conversation == null || cursor == null || _loadingOlderMessages) return;
    setState(() => _loadingOlderMessages = true);
    try {
      final previousExtent =
          _scroll.hasClients ? _scroll.position.maxScrollExtent : 0.0;
      final page =
          await _api.messages(widget.groupId, conversation.id, before: cursor);
      if (!mounted || _selected?.id != conversation.id) return;
      setState(() {
        final existing = _messages.map((message) => message.id).toSet();
        _messages = [
          ...page.messages.where((message) => !existing.contains(message.id)),
          ..._messages
        ];
        _hasOlderMessages = page.hasMore;
        _olderCursor = page.nextCursor;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.jumpTo(_scroll.position.maxScrollExtent - previousExtent);
        }
      });
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _loadingOlderMessages = false);
    }
  }

  Future<void> _toggleMute(BusinessChatConversation conversation) async {
    try {
      await _api.setMuted(widget.groupId, conversation.id, !conversation.muted);
      await _refresh(silent: true);
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _openBankTransaction(Map<String, dynamic> reference,
      {bool reviewLink = false}) async {
    final entryId = (reference['entryId'] ?? '').toString();
    if (entryId.isEmpty) return;
    try {
      final entry = await _api.bankTransaction(widget.groupId, entryId);
      final group = await context
          .read<GroupDomain>()
          .groupRepository
          .getGroupById(widget.groupId);
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => EnableBankingScreen(
            group: group, initialEntry: entry, initialReviewLink: reviewLink),
      ));
    } catch (error) {
      if (!mounted) return;
      final unavailable =
          error is BackendApiException && error.statusCode == 404;
      final denied = error is BackendApiException && error.statusCode == 403;
      _showError(unavailable
          ? (_es
              ? 'Este movimiento ya no está disponible.'
              : 'This transaction is no longer available.')
          : denied
              ? (_es
                  ? 'No tienes permiso para ver este movimiento.'
                  : 'You cannot view this transaction.')
              : error);
    }
  }

  Future<void> _shareBankTransactionFromChat(
      {bool requestReview = false}) async {
    if (!_canShareBankTransactions) return;
    final destinations = _conversations
        .where((conversation) => conversation.canShareBankTransaction)
        .toList();
    if (destinations.isEmpty) {
      _showError(_es
          ? 'Para compartir movimientos, crea un chat de equipo solo con administradores y coadministradores.'
          : 'To share transactions, create a team chat with only admins and co-admins.');
      return;
    }
    final selection = Completer<Map<String, dynamic>?>();
    setState(() {
      _reviewCollapsed = false;
      _reviewPanel = BankTransactionPicker(
        key: const ValueKey('chat-bank-transaction-panel'),
        groupId: widget.groupId,
        presentation: BankTransactionPickerPresentation.sidePanel,
        onClose: () {
          if (!selection.isCompleted) selection.complete();
          if (mounted) setState(() => _reviewPanel = null);
        },
        onSelected: (entry) {
          if (!selection.isCompleted) selection.complete(entry);
          if (mounted) setState(() => _reviewPanel = null);
        },
      );
    });
    final entry = await selection.future;
    if (!mounted || entry == null) return;
    final destinationId = await BankTransactionShareDialog.show(
        context, widget.groupId, entry,
        initialMessage: requestReview
            ? (_es
                ? '¿Podéis revisar este movimiento y confirmar si está vinculado correctamente?'
                : 'Could you review this transaction and confirm its link is correct?')
            : null,
        initialConversationId:
            _selected?.canShareBankTransaction == true ? _selected!.id : null);
    if (!mounted || destinationId == null) return;
    _pendingConversationId = destinationId;
    _showChatOnNarrow = true;
    await _refresh(silent: true);
  }

  Future<void> _requestDocumentReview(String kind) async {
    if (!_canRequestDocumentReview || _sending) return;
    final destinations =
        _conversations.where((c) => c.canRequestReview).toList();
    if (destinations.isEmpty) {
      _showError(_es
          ? 'Crea un chat de equipo solo con propietarios, administradores y coadministradores.'
          : 'Create a team chat with only owners, admins, and co-admins.');
      return;
    }
    Future<void> createExpense() async {
      final group = await context
          .read<GroupDomain>()
          .groupRepository
          .getGroupById(widget.groupId);
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => ExpenseUploadScreen(
              groupId: widget.groupId,
              groupName: group.name,
              uploadOnly: true)));
    }

    // All review kinds (factura, gasto, horas) open as the right-side action
    // column on desktop/tablet; only narrow viewports fall back to a modal.
    if (MediaQuery.sizeOf(context).width >= 720) {
      setState(() {
        _reviewCollapsed = false;
        _reviewPanel = DocumentReviewDialog(
          key: ValueKey('chat-review-panel-$kind'),
          groupId: widget.groupId,
          kind: kind,
          conversations: destinations,
          initialConversationId:
              _selected?.canRequestReview == true ? _selected!.id : null,
          presentation: DocumentReviewPresentation.sidePanel,
          onClose: () => setState(() {
            _reviewPanel = null;
            _reviewCollapsed = false;
          }),
          onCollapse: () => setState(() => _reviewCollapsed = true),
          onSelection: (selection) {
            setState(() {
              _reviewPanel = null;
              _reviewCollapsed = false;
            });
            _submitDocumentReview(selection);
          },
          onOpenBanking: _openBankingFromReview,
          onCreateExpense: kind == 'expense' ? createExpense : null,
        );
      });
      return;
    }
    final selection = await showDialog<DocumentReviewSelection>(
      context: context,
      builder: (_) => DocumentReviewDialog(
        groupId: widget.groupId,
        kind: kind,
        conversations: destinations,
        initialConversationId:
            _selected?.canRequestReview == true ? _selected!.id : null,
        onOpenBanking: () async {
          final group = await context
              .read<GroupDomain>()
              .groupRepository
              .getGroupById(widget.groupId);
          if (!mounted) return;
          await Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => EnableBankingScreen(group: group)));
        },
        onCreateExpense: createExpense,
      ),
    );
    if (!mounted || selection == null) return;
    await _submitDocumentReview(selection);
  }

  Future<void> _submitDocumentReview(DocumentReviewSelection selection) async {
    if (_sending) return;
    setState(() => _sending = true);
    try {
      await _api.requestReview(widget.groupId, selection.conversationId,
          kind: selection.kind,
          documentId: selection.documentId,
          year: selection.year,
          quarter: selection.quarter,
          body: selection.body,
          file: selection.file);
      if (!mounted) return;
      _pendingConversationId = selection.conversationId;
      _showChatOnNarrow = true;
      await _refresh(silent: true);
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _openBankingFromReview() async {
    final group = await context
        .read<GroupDomain>()
        .groupRepository
        .getGroupById(widget.groupId);
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => EnableBankingScreen(group: group)));
  }

  Future<void> _openReviewDocument(Map<String, dynamic> review) async {
    final id = (review['documentId'] ?? '').toString();
    if (id.isEmpty) return;
    try {
      final group = await context
          .read<GroupDomain>()
          .groupRepository
          .getGroupById(widget.groupId);
      if (!mounted) return;
      final kind = (review['kind'] ?? '').toString();
      await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) {
        if (kind == 'invoice')
          return GroupInvoicesScreen(group: group, initialInvoiceId: id);
        if (kind == 'expense')
          return ExpenseUploadScreen(
              groupId: widget.groupId,
              groupName: group.name,
              initialExpenseId: id);
        return WorkersHubScreen(group: group);
      }));
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  String _reviewSubtitle(Map<String, dynamic> review) {
    final count = review['timeEntriesCount'] ?? 0;
    final number = review['kind'] == 'worker_hours'
        ? '$count ${_es ? 'registros' : 'entries'}'
        : (review['number'] ?? '').toString();
    final date = DateTime.tryParse((review['documentDate'] ?? '').toString());
    return [
      (review['counterparty'] ?? '').toString(),
      if (number.isNotEmpty) number,
      if (date != null)
        DateFormat.yMMMd(_es ? 'es' : 'en').format(date.toLocal()),
      '${_es ? 'T' : 'Q'}${review['quarter']}/${review['year']}',
    ].join(' · ');
  }

  Future<void> _send() async {
    final conversation = _selected;
    final body = _composer.text.trim();
    if (_sending || body.isEmpty || conversation == null) return;
    final replyId = _replyingTo?.id;
    setState(() => _sending = true);
    try {
      await _api.send(widget.groupId, conversation.id, body,
          replyToMessageId: replyId);
      if (!mounted) return;
      _composer.clear();
      _drafts.remove(conversation.id);
      _saveDraft(conversation.id);
      setState(() => _replyingTo = null);
      await _loadMessages(conversation);
      _scrollToEnd();
      _refresh(silent: true);
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _attach() async {
    final conversation = _selected;
    if (_sending || conversation == null) return;
    final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
        withData: true);
    if (picked == null || picked.files.isEmpty || !mounted) return;
    final file = picked.files.single;
    if (file.size > 10 * 1024 * 1024) {
      _showError(_es
          ? 'El archivo debe ser menor de 10 MB.'
          : 'File must be under 10 MB.');
      return;
    }
    setState(() => _sending = true);
    try {
      await _api.sendAttachment(
          widget.groupId, conversation.id, file, _composer.text.trim(),
          replyToMessageId: _replyingTo?.id);
      if (!mounted) return;
      _composer.clear();
      _drafts.remove(conversation.id);
      _saveDraft(conversation.id);
      setState(() => _replyingTo = null);
      await _loadMessages(conversation);
      _scrollToEnd();
      _refresh(silent: true);
    } catch (error) {
      if (mounted) {
        _showError(error is BackendApiException && error.statusCode == 400
            ? (_es
                ? 'No se pudo adjuntar. Usa una imagen JPG, PNG, WebP o un PDF válido de hasta 10 MB.'
                : 'Could not attach this file. Use a valid JPG, PNG, WebP, or PDF up to 10 MB.')
            : error);
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _showBusinessActionsSheet() async {
    if (_selected == null || _sending) return;
    final showBusinessActions = MediaQuery.sizeOf(context).width < 700;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _es ? 'Acciones del chat' : 'Chat actions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.attach_file_rounded),
                title: Text(_es ? 'Adjuntar archivo' : 'Attach file'),
                subtitle: Text(
                    _es ? 'JPG, PNG, WebP o PDF' : 'JPG, PNG, WebP, or PDF'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _attach();
                },
              ),
              if (showBusinessActions && _canShareBankTransactions)
                ListTile(
                  leading: const Icon(Icons.account_balance_outlined),
                  title: Text(_es
                      ? 'Compartir movimiento bancario'
                      : 'Share bank transaction'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _shareBankTransactionFromChat();
                  },
                ),
              if (showBusinessActions && _canRequestDocumentReview)
                ListTile(
                  leading: const Icon(Icons.receipt_long_outlined),
                  title: Text(_es ? 'Revisar factura' : 'Review invoice'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _requestDocumentReview('invoice');
                  },
                ),
              if (showBusinessActions && _canRequestDocumentReview)
                ListTile(
                  leading: const Icon(Icons.payments_outlined),
                  title: Text(_es ? 'Revisar gasto' : 'Review expense'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _requestDocumentReview('expense');
                  },
                ),
              if (showBusinessActions && _canRequestDocumentReview)
                ListTile(
                  leading: const Icon(Icons.access_time_outlined),
                  title: Text(_es ? 'Revisar horas' : 'Review hours'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _requestDocumentReview('worker_hours');
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showMobileMessageActions(
    BusinessChatMessage message, {
    required bool canEdit,
    required bool canDelete,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.reply_rounded),
                title: Text(_es ? 'Responder' : 'Reply'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  setState(() => _replyingTo = message);
                },
              ),
              if (message.body.trim().isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.copy_outlined),
                  title: Text(_es ? 'Copiar' : 'Copy'),
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: message.body));
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  },
                ),
              if (canEdit)
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: Text(_es ? 'Editar' : 'Edit'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _messageAction(message, 'edit');
                  },
                ),
              if (canDelete)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded),
                  title: Text(_es ? 'Eliminar' : 'Delete'),
                  iconColor: Theme.of(context).colorScheme.error,
                  textColor: Theme.of(context).colorScheme.error,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _messageAction(message, 'delete');
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openAttachment(BusinessChatMessage message) async {
    try {
      final url = await _api.attachmentUrl(widget.groupId, message);
      if (!await launchUrl(url, mode: LaunchMode.platformDefault))
        throw StateError('Could not open attachment');
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  void _scrollToEnd() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients)
          _scroll.animateTo(_scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut);
      });

  Future<void> _createIssue() async {
    try {
      final values = await _issueDialog();
      if (values == null) return;
      final created = await _api.createIssue(
          widget.groupId, values.$1, values.$2,
          workerId: values.$3, clientId: values.$4, eventId: values.$5);
      await _refresh();
      final id = (created['conversation'] as Map)['id'].toString();
      if (mounted)
        setState(() =>
            _selected = _conversations.where((c) => c.id == id).firstOrNull);
      if (_selected != null) await _loadMessages(_selected!);
    } catch (error) {
      _showError(error);
    }
  }

  Future<(String, String, String?, String?, String?)?> _issueDialog() async {
    final workers = _canAssignIssues
        ? await _api.workers(widget.groupId)
        : const <Map<String, dynamic>>[];
    final links = await _api.issueLinks(widget.groupId);
    final clients = (links['clients'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((c) => Map<String, dynamic>.from(c))
        .toList();
    final events = (links['events'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    if (!mounted) return null;
    final title = TextEditingController();
    final description = TextEditingController();
    var workerId = '';
    var clientId = '';
    var eventId = '';
    return showDialog<(String, String, String?, String?, String?)>(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, refreshDialog) => AlertDialog(
                  title: Text(_es ? 'Nueva incidencia' : 'New incident'),
                  content: SizedBox(
                      width: 440,
                      child: SingleChildScrollView(
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                        TextField(
                            controller: title,
                            maxLength: 160,
                            decoration: InputDecoration(
                                labelText: _es ? 'Título' : 'Title',
                                border: const OutlineInputBorder())),
                        const SizedBox(height: 12),
                        TextField(
                            controller: description,
                            maxLength: 4000,
                            maxLines: 4,
                            decoration: InputDecoration(
                                labelText: _es ? 'Descripción' : 'Description',
                                border: const OutlineInputBorder())),
                        if (clients.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                              initialValue: clientId,
                              decoration: InputDecoration(
                                  labelText: _es
                                      ? 'Cliente (opcional)'
                                      : 'Client (optional)',
                                  border: const OutlineInputBorder()),
                              items: [
                                DropdownMenuItem(
                                    value: '',
                                    child: Text(
                                        _es ? 'Sin cliente' : 'No client')),
                                ...clients.map((client) => DropdownMenuItem(
                                    value: client['id'].toString(),
                                    child: Text(client['name'].toString(),
                                        overflow: TextOverflow.ellipsis)))
                              ],
                              onChanged: (value) => refreshDialog(() {
                                    clientId = value ?? '';
                                    eventId = '';
                                  })),
                        ],
                        if (events.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                              key: ValueKey(clientId),
                              initialValue: eventId,
                              decoration: InputDecoration(
                                  labelText: _es
                                      ? 'Evento (opcional)'
                                      : 'Event (optional)',
                                  border: const OutlineInputBorder()),
                              items: [
                                DropdownMenuItem(
                                    value: '',
                                    child:
                                        Text(_es ? 'Sin evento' : 'No event')),
                                ...events
                                    .where((event) =>
                                        clientId.isEmpty ||
                                        event['clientId']?.toString() ==
                                            clientId)
                                    .map((event) => DropdownMenuItem(
                                        value: event['id'].toString(),
                                        child: Text(event['title'].toString(),
                                            overflow: TextOverflow.ellipsis)))
                              ],
                              onChanged: (value) =>
                                  refreshDialog(() => eventId = value ?? '')),
                        ],
                        if (_canAssignIssues && workers.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                              initialValue: workerId,
                              decoration: InputDecoration(
                                  labelText: _es
                                      ? 'Asignar a (opcional)'
                                      : 'Assign to (optional)',
                                  border: const OutlineInputBorder()),
                              items: [
                                DropdownMenuItem<String>(
                                    value: '',
                                    child: Text(
                                        _es ? 'Sin asignar' : 'Unassigned')),
                                ...workers.map((worker) => DropdownMenuItem<
                                        String>(
                                    value: worker['id'].toString(),
                                    child: Text(
                                        '${worker['name']} · ${worker['role']}')))
                              ],
                              onChanged: (value) {
                                if (value != null)
                                  refreshDialog(() => workerId = value);
                              }),
                        ],
                      ]))),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(_es ? 'Cancelar' : 'Cancel')),
                    FilledButton(
                        onPressed: () {
                          final value = title.text.trim();
                          if (value.isNotEmpty)
                            Navigator.pop(context, (
                              value,
                              description.text.trim(),
                              workerId.isEmpty ? null : workerId,
                              clientId.isEmpty ? null : clientId,
                              eventId.isEmpty ? null : eventId
                            ));
                        },
                        child: Text(_es ? 'Crear' : 'Create'))
                  ],
                ))).then((value) {
      title.dispose();
      description.dispose();
      return value;
    });
  }

  Future<void> _assignIssue(BusinessChatConversation conversation) async {
    final issueId = conversation.issue?['id']?.toString();
    if (issueId == null) return;
    try {
      final workers = await _api.workers(widget.groupId);
      if (!mounted) return;
      if (workers.isEmpty) {
        _showError(_es
            ? 'No hay trabajadores activos con una cuenta Hexora.'
            : 'No active workers with a Hexora account are available.');
        return;
      }
      final workerId = await showDialog<String>(
          context: context,
          builder: (context) => SimpleDialog(
                title: Text(_es ? 'Asignar incidencia' : 'Assign incident'),
                children: workers
                    .map((worker) => SimpleDialogOption(
                        onPressed: () =>
                            Navigator.pop(context, worker['id'].toString()),
                        child: Text('${worker['name']} · ${worker['role']}')))
                    .toList(),
              ));
      if (workerId == null) return;
      await _api.assignIssue(widget.groupId, issueId, workerId);
      await _refresh();
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _createTeam() async {
    final title = await _textDialog(
        _es ? 'Nuevo chat de equipo' : 'New team chat',
        maxLength: 120);
    if (title == null) return;
    try {
      final members = await _api.members(widget.groupId);
      if (!mounted) return;
      final selected = <String>{};
      final chosen = await showDialog<List<String>>(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, refreshDialog) => AlertDialog(
                  title:
                      Text(_es ? 'Añadir participantes' : 'Add participants'),
                  content: SizedBox(
                      width: 420,
                      height: 360,
                      child: Column(children: [
                        Text(_es
                            ? '${selected.length + 1}/50 participantes (incluyéndote)'
                            : '${selected.length + 1}/50 participants (including you)'),
                        const SizedBox(height: 8),
                        Expanded(
                            child: ListView(
                                children: members.map((member) {
                          final id = (member['id'] ?? '').toString();
                          if (id.isEmpty || id == widget.currentUserId)
                            return const SizedBox.shrink();
                          return CheckboxListTile(
                              value: selected.contains(id),
                              title: Text(
                                  (member['name'] ?? member['userName'] ?? '')
                                      .toString()),
                              onChanged: !selected.contains(id) &&
                                      selected.length >= 49
                                  ? null
                                  : (value) => refreshDialog(() {
                                        value == true
                                            ? selected.add(id)
                                            : selected.remove(id);
                                      }));
                        }).toList())),
                      ])),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(_es ? 'Cancelar' : 'Cancel')),
                    FilledButton(
                        onPressed: () =>
                            Navigator.pop(context, selected.toList()),
                        child: Text(_es ? 'Crear' : 'Create'))
                  ],
                )),
      );
      if (chosen == null) return;
      await _api.createTeam(widget.groupId, title.$1, chosen);
      await _refresh();
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _manageParticipants(
      BusinessChatConversation conversation) async {
    try {
      final members = await _api.members(widget.groupId);
      final workers = conversation.type == 'team' && _canCreateTeam
          ? await _api.workers(widget.groupId)
          : const <Map<String, dynamic>>[];
      if (!mounted) return;
      final supervisorIds = workers
          .where((worker) => worker['operationalRole'] == 'supervisor')
          .map((worker) => worker['userId'].toString())
          .toSet();
      final moderators = conversation.moderatorIds.toSet();
      final byId = {
        for (final member in members) (member['id'] ?? '').toString(): member
      };
      await showDialog<void>(
          context: context,
          builder: (dialogContext) => StatefulBuilder(
              builder: (dialogContext, refreshDialog) => AlertDialog(
                    title: Text(_es
                        ? 'Participantes de ${conversation.title}'
                        : '${conversation.title} participants'),
                    content: SizedBox(
                        width: 440,
                        height: 360,
                        child: Column(children: [
                          Text(_es
                              ? '${conversation.participantIds.length}/50 participantes'
                              : '${conversation.participantIds.length}/50 participants'),
                          const SizedBox(height: 8),
                          Expanded(
                              child: ListView(children: [
                            for (final id in conversation.participantIds)
                              ListTile(
                                title: Text((byId[id]?['name'] ??
                                        byId[id]?['userName'] ??
                                        id)
                                    .toString()),
                                subtitle: conversation.type == 'team' &&
                                        moderators.contains(id)
                                    ? Text(_es
                                        ? 'Moderador del equipo'
                                        : 'Team moderator')
                                    : null,
                                trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (conversation.type == 'team' &&
                                          _canCreateTeam &&
                                          supervisorIds.contains(id))
                                        IconButton(
                                          icon: Icon(moderators.contains(id)
                                              ? Icons.shield_rounded
                                              : Icons.shield_outlined),
                                          tooltip: moderators.contains(id)
                                              ? (_es
                                                  ? 'Quitar moderador'
                                                  : 'Remove moderator')
                                              : (_es
                                                  ? 'Delegar moderación'
                                                  : 'Delegate moderation'),
                                          onPressed: () async {
                                            try {
                                              final enable =
                                                  !moderators.contains(id);
                                              await _api.setTeamModerator(
                                                  widget.groupId,
                                                  conversation.id,
                                                  id,
                                                  enable);
                                              refreshDialog(() {
                                                if (enable) {
                                                  moderators.add(id);
                                                } else {
                                                  moderators.remove(id);
                                                }
                                              });
                                              await _refresh(silent: true);
                                            } catch (error) {
                                              if (mounted) _showError(error);
                                            }
                                          },
                                        ),
                                      if (id != widget.currentUserId)
                                        IconButton(
                                            icon: const Icon(
                                                Icons.person_remove_outlined),
                                            tooltip: _es ? 'Quitar' : 'Remove',
                                            onPressed: () async {
                                              try {
                                                await _api.removeParticipant(
                                                    widget.groupId,
                                                    conversation.id,
                                                    id);
                                                conversation.participantIds
                                                    .remove(id);
                                                moderators.remove(id);
                                                refreshDialog(() {});
                                                await _refresh(silent: true);
                                              } catch (error) {
                                                if (mounted) {
                                                  _showError(error
                                                              is BackendApiException &&
                                                          error.statusCode ==
                                                              409
                                                      ? (_es
                                                          ? 'Transfiere o resuelve la incidencia antes de quitar a su informante o responsable.'
                                                          : 'Transfer or resolve the incident before removing its reporter or assignee.')
                                                      : error);
                                                }
                                              }
                                            }),
                                    ]),
                              ),
                          ])),
                        ])),
                    actions: [
                      if (conversation.type == 'team' && _canCreateTeam)
                        TextButton(
                            onPressed: () async {
                              final value = await _textDialog(
                                  _es ? 'Renombrar equipo' : 'Rename team',
                                  initialValue: conversation.title,
                                  maxLength: 120,
                                  actionLabel: _es ? 'Guardar' : 'Save');
                              if (value == null) return;
                              try {
                                await _api.renameTeam(
                                    widget.groupId, conversation.id, value.$1);
                                if (dialogContext.mounted)
                                  Navigator.pop(dialogContext);
                                await _refresh();
                              } catch (error) {
                                if (mounted) _showError(error);
                              }
                            },
                            child: Text(_es ? 'Renombrar' : 'Rename')),
                      if (conversation.type == 'team' && _canCreateTeam)
                        TextButton(
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                  context: dialogContext,
                                  builder: (context) => AlertDialog(
                                          title: Text(_es
                                              ? '¿Eliminar chat de equipo?'
                                              : 'Delete team chat?'),
                                          content: Text(_es
                                              ? 'Se archivará para todos los participantes.'
                                              : 'It will be archived for all participants.'),
                                          actions: [
                                            TextButton(
                                                onPressed: () => Navigator.pop(
                                                    context, false),
                                                child: Text(_es
                                                    ? 'Cancelar'
                                                    : 'Cancel')),
                                            TextButton(
                                                onPressed: () => Navigator.pop(
                                                    context, true),
                                                child: Text(_es
                                                    ? 'Eliminar'
                                                    : 'Delete'))
                                          ]));
                              if (confirmed != true) return;
                              try {
                                await _api.archiveTeam(
                                    widget.groupId, conversation.id);
                                if (dialogContext.mounted)
                                  Navigator.pop(dialogContext);
                                await _refresh();
                              } catch (error) {
                                if (mounted) _showError(error);
                              }
                            },
                            child: Text(_es ? 'Eliminar chat' : 'Delete chat')),
                      TextButton(
                          onPressed: conversation.participantIds.length >= 50
                              ? null
                              : () async {
                                  final available = members
                                      .where((member) =>
                                          !conversation.participantIds.contains(
                                              (member['id'] ?? '').toString()))
                                      .toList();
                                  final selected = <String>{};
                                  final remaining =
                                      50 - conversation.participantIds.length;
                                  final chosen = await showDialog<List<String>>(
                                      context: dialogContext,
                                      builder: (context) => StatefulBuilder(
                                          builder: (context, update) =>
                                              AlertDialog(
                                                title: Text(_es
                                                    ? 'Añadir participantes'
                                                    : 'Add participants'),
                                                content: SizedBox(
                                                    width: 400,
                                                    height: 320,
                                                    child: Column(children: [
                                                      Text(_es
                                                          ? '${selected.length}/$remaining plazas seleccionadas'
                                                          : '${selected.length}/$remaining places selected'),
                                                      const SizedBox(height: 8),
                                                      Expanded(
                                                          child: ListView(
                                                              children:
                                                                  available.map(
                                                                      (member) {
                                                        final id =
                                                            (member['id'] ?? '')
                                                                .toString();
                                                        return CheckboxListTile(
                                                            value: selected
                                                                .contains(id),
                                                            title: Text((member[
                                                                        'name'] ??
                                                                    member[
                                                                        'userName'] ??
                                                                    id)
                                                                .toString()),
                                                            onChanged: !selected
                                                                        .contains(
                                                                            id) &&
                                                                    selected.length >=
                                                                        remaining
                                                                ? null
                                                                : (value) =>
                                                                    update(() {
                                                                      if (value ==
                                                                          true) {
                                                                        selected
                                                                            .add(id);
                                                                      } else {
                                                                        selected
                                                                            .remove(id);
                                                                      }
                                                                    }));
                                                      }).toList())),
                                                    ])),
                                                actions: [
                                                  TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context),
                                                      child: Text(_es
                                                          ? 'Cancelar'
                                                          : 'Cancel')),
                                                  FilledButton(
                                                      onPressed: selected
                                                              .isEmpty
                                                          ? null
                                                          : () => Navigator.pop(
                                                              context,
                                                              selected
                                                                  .toList()),
                                                      child: Text(_es
                                                          ? 'Añadir'
                                                          : 'Add'))
                                                ],
                                              )));
                                  if (chosen == null || chosen.isEmpty) return;
                                  try {
                                    await _api.addParticipants(widget.groupId,
                                        conversation.id, chosen);
                                    conversation.participantIds.addAll(chosen);
                                    refreshDialog(() {});
                                    await _refresh(silent: true);
                                  } catch (error) {
                                    if (mounted) _showError(error);
                                  }
                                },
                          child: Text(_es ? 'Añadir' : 'Add')),
                      FilledButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: Text(_es ? 'Cerrar' : 'Close')),
                    ],
                  )));
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _leaveConversation(BusinessChatConversation conversation) async {
    final userId = widget.currentUserId;
    if (userId == null ||
        !conversation.participantIds.contains(userId) ||
        conversation.type == 'general') return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_es ? '¿Salir del chat?' : 'Leave chat?'),
        content: Text(_es
            ? 'Dejarás de recibir avisos de este chat. No perderás tu acceso al negocio.${_canCreateTeam ? ' Como administrador, aún podrás consultarlo.' : ''}'
            : 'You will stop receiving alerts from this chat. Your business access will not change.${_canCreateTeam ? ' As an admin, you can still view it.' : ''}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(_es ? 'Cancelar' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(_es ? 'Salir' : 'Leave'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _api.removeParticipant(widget.groupId, conversation.id, userId);
      if (!mounted) return;
      _draftTimer?.cancel();
      _drafts[conversation.id] = '';
      _saveDraft(conversation.id);
      _switchDraft(conversation.id, null);
      setState(() {
        _selected = null;
        _messages = const [];
        _showChatOnNarrow = false;
      });
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      _showError(error is BackendApiException && error.statusCode == 409
          ? (_es
              ? 'No puedes salir mientras seas responsable o informante de una incidencia activa. Transfiérela o resuélvela primero.'
              : 'You cannot leave while responsible for an active incident. Transfer or resolve it first.')
          : error);
    }
  }

  Future<(String, String)?> _textDialog(String title,
      {bool withDescription = false,
      String initialValue = '',
      int maxLength = 160,
      int maxLines = 1,
      String? fieldLabel,
      String? actionLabel}) async {
    final name = TextEditingController(text: initialValue);
    final description = TextEditingController();
    return showDialog<(String, String)>(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(title),
              content: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                    controller: name,
                    maxLength: maxLength,
                    maxLines: maxLines,
                    decoration: InputDecoration(
                        labelText: fieldLabel ??
                            (maxLines > 1
                                ? (_es ? 'Nota' : 'Note')
                                : (_es ? 'Título' : 'Title')),
                        border: const OutlineInputBorder())),
                if (withDescription) ...[
                  const SizedBox(height: 12),
                  TextField(
                      controller: description,
                      maxLength: 4000,
                      maxLines: 4,
                      decoration: InputDecoration(
                          labelText: _es ? 'Descripción' : 'Description',
                          border: const OutlineInputBorder()))
                ],
              ])),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(_es ? 'Cancelar' : 'Cancel')),
                FilledButton(
                    onPressed: () {
                      final value = name.text.trim();
                      if (value.isNotEmpty)
                        Navigator.pop(
                            context, (value, description.text.trim()));
                    },
                    child: Text(actionLabel ?? (_es ? 'Crear' : 'Create')))
              ],
            )).then((value) {
      name.dispose();
      description.dispose();
      return value;
    });
  }

  Future<void> _messageAction(
      BusinessChatMessage message, String action) async {
    try {
      if (action == 'delete') {
        await _api.delete(widget.groupId, message);
      } else {
        final value = await _textDialog(_es ? 'Editar mensaje' : 'Edit message',
            initialValue: message.body,
            maxLength: 2000,
            maxLines: 4,
            fieldLabel: _es ? 'Mensaje' : 'Message',
            actionLabel: _es ? 'Guardar' : 'Save');
        if (value == null) return;
        await _api.edit(widget.groupId, message, value.$1);
      }
      if (_selected != null) await _loadMessages(_selected!);
    } catch (error) {
      _showError(error);
    }
  }

  void _showError(Object error) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(error.toString())));

  Future<void> _showConnectionInfo() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(_liveConnected
            ? Icons.cloud_done_outlined
            : Icons.cloud_off_outlined),
        title: Text(_liveConnected
            ? (_es ? 'Conectado' : 'Connected')
            : (_es
                ? 'Sin conexión en directo'
                : 'Live connection unavailable')),
        content: Text(_liveConnected
            ? (_es
                ? 'Los mensajes se actualizan en directo.'
                : 'Messages update live.')
            : (_es
                ? 'No hay conexión en directo; el chat se actualiza cada minuto.'
                : 'No live connection; the chat refreshes every minute.')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(_es ? 'Cerrar' : 'Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _setIssueStatus(String status) async {
    final issueId = _selected?.issue?['id']?.toString();
    if (issueId == null || issueId.isEmpty) return;
    try {
      String? note;
      if (status == 'resolved' || status == 'closed') {
        final existing = (_selected?.issue?['resolutionNote'] ?? '').toString();
        final result = await _textDialog(
            _es ? 'Nota de resolución' : 'Resolution note',
            initialValue: existing,
            maxLength: 4000,
            maxLines: 4,
            actionLabel: _es ? 'Guardar' : 'Save');
        if (result == null) return;
        note = result.$1;
        if (note.isEmpty) {
          _showError(_es
              ? 'Escribe cómo se resolvió la incidencia.'
              : 'Enter how the incident was resolved.');
          return;
        }
      }
      await _api.updateIssueStatus(widget.groupId, issueId, status, note: note);
      await _refresh();
    } catch (error) {
      _showError(error);
    }
  }

  void _showIssueDetails(BusinessChatConversation conversation) {
    final issue = conversation.issue;
    if (issue == null) return;
    showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(issue['title']?.toString() ?? conversation.title),
              content: SizedBox(
                  width: 440,
                  child: SingleChildScrollView(
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        if ((issue['description'] ?? '').toString().isNotEmpty)
                          Text(issue['description'].toString()),
                        if (issue['clientId'] != null)
                          Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                  '${_es ? 'Cliente' : 'Client'}: ${issue['clientName'] ?? issue['clientId']}')),
                        if (issue['eventId'] != null)
                          Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                  '${_es ? 'Evento' : 'Event'}: ${issue['eventTitle'] ?? issue['eventId']}')),
                        if ((issue['resolutionNote'] ?? '')
                            .toString()
                            .isNotEmpty)
                          Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                  '${_es ? 'Resolución' : 'Resolution'}: ${issue['resolutionNote']}')),
                        if (issue['statusHistory'] is List &&
                            (issue['statusHistory'] as List).isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(_es ? 'Historial de estados' : 'Status history',
                              style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 8),
                          for (final entry
                              in (issue['statusHistory'] as List).reversed)
                            if (entry is Map)
                              Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            '${_statusLabel((entry['status'] ?? '').toString())} · ${_formatChatDate(entry['changedAt'])}${entry['changedByName'] == null ? '' : ' · ${entry['changedByName']}'}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium),
                                        if ((entry['note'] ?? '')
                                            .toString()
                                            .trim()
                                            .isNotEmpty)
                                          Text(entry['note'].toString()),
                                      ])),
                        ],
                      ]))),
              actions: [
                FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(_es ? 'Cerrar' : 'Close'))
              ],
            ));
  }

  String _typeLabel(String type) => switch (type) {
        'general' => _es ? 'General' : 'General',
        'team' => _es ? 'Equipo' : 'Team',
        'issue' => _es ? 'Incidencia' : 'Incident',
        _ => type,
      };

  String _statusLabel(String status) => switch (status) {
        'open' => _es ? 'Abierta' : 'Open',
        'in_progress' => _es ? 'En curso' : 'In progress',
        'review' => _es ? 'En revisión' : 'In review',
        'resolved' => _es ? 'Resuelta' : 'Resolved',
        'closed' => _es ? 'Cerrada' : 'Closed',
        _ => status,
      };

  String _formatChatDate(Object? value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    return date == null
        ? ''
        : DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal());
  }

  /// Two messages belong to the same visual group when the same sender posts
  /// them close together (within 5 minutes) on the same calendar day.
  bool _isSameGroup(BusinessChatMessage a, BusinessChatMessage b) {
    if (a.senderId != b.senderId || a.senderId.isEmpty) return false;
    final first = a.createdAt.toLocal();
    final second = b.createdAt.toLocal();
    if (first.year != second.year ||
        first.month != second.month ||
        first.day != second.day) {
      return false;
    }
    return second.difference(first).inMinutes.abs() < 5;
  }

  Widget _dateSeparator(DateTime value) {
    final local = value.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(local.year, local.month, local.day);
    final difference = today.difference(day).inDays;
    final label = difference == 0
        ? (_es ? 'Hoy' : 'Today')
        : difference == 1
            ? (_es ? 'Ayer' : 'Yesterday')
            : DateFormat.yMMMMd(_es ? 'es' : 'en').format(local);
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest.withValues(alpha: .7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ),
    );
  }

  /// The rich body of a single message, without sender name or action icons
  /// (those are provided by the group header and the contextual toolbar).
  Widget _messageContent(BusinessChatMessage message, bool mine) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message.replyTo != null)
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              message.replyTo!['unavailable'] == true
                  ? (_es
                      ? 'Mensaje original no disponible'
                      : 'Original message unavailable')
                  : '${message.replyTo!['senderName'] ?? ''}: ${message.replyTo!['body']?.toString().isNotEmpty == true ? message.replyTo!['body'] : (_es ? 'Adjunto o referencia' : 'Attachment or reference')}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        if (message.isDeleted || message.body.isNotEmpty)
          Text(
            message.isDeleted
                ? (_es ? 'Mensaje eliminado' : 'Message deleted')
                : message.body,
            style: message.isDeleted
                ? TextStyle(
                    fontStyle: FontStyle.italic, color: colors.onSurfaceVariant)
                : null,
          ),
        if (!message.isDeleted && message.bankTransaction != null)
          BankTransactionChatCard(
            transaction: message.bankTransaction!,
            onOpen: () => _openBankTransaction(message.bankTransaction!),
            onReview: () => _openBankTransaction(message.bankTransaction!,
                reviewLink: true),
            onRequestReview: () {
              setState(() {
                _replyingTo = message;
                if (_composer.text.trim().isEmpty) {
                  _composer.text = _es
                      ? '¿Podéis revisar este movimiento y confirmar si está vinculado correctamente?'
                      : 'Could you review this transaction and confirm its link is correct?';
                }
              });
            },
            sharedBy: message.senderName,
            sharedAt: message.createdAt,
          ),
        if (!message.isDeleted && message.review != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      switch (message.review!['kind']) {
                        'invoice' =>
                          _es ? 'Revisión de factura' : 'Invoice review',
                        'expense' =>
                          _es ? 'Revisión de gasto' : 'Expense review',
                        _ => _es ? 'Revisión de horas' : 'Hours review',
                      },
                      style: Theme.of(context).textTheme.titleSmall),
                  Text(_reviewSubtitle(message.review!)),
                  TextButton.icon(
                    onPressed: () => _openReviewDocument(message.review!),
                    icon: const Icon(Icons.open_in_new),
                    label: Text(switch (message.review!['kind']) {
                      'invoice' => _es ? 'Abrir factura' : 'Open invoice',
                      'expense' => _es ? 'Abrir gasto' : 'Open expense',
                      _ => _es ? 'Abrir trabajadores' : 'Open workers',
                    }),
                  ),
                  if (message.review!['kind'] != 'worker_hours' &&
                      message.review!['bankLinkAvailable'] == true)
                    Text((message.review!['linkedTransactionIds'] as List? ??
                                const [])
                            .isEmpty
                        ? (_es
                            ? 'Sin movimiento vinculado'
                            : 'No linked transaction')
                        : (_es
                            ? 'Movimiento vinculado'
                            : 'Linked transaction')),
                  if (message.review!['bankLinkAvailable'] == true &&
                      (message.review!['linkedTransactionIds'] as List? ??
                              const [])
                          .isNotEmpty)
                    Wrap(children: [
                      for (final (index, entryId)
                          in (message.review!['linkedTransactionIds'] as List)
                              .indexed)
                        TextButton.icon(
                          onPressed: () => _openBankTransaction({
                            'entryId': entryId.toString(),
                          }),
                          icon: const Icon(Icons.account_balance_outlined),
                          label: Text(_es
                              ? 'Movimiento ${index + 1}'
                              : 'Transaction ${index + 1}'),
                        ),
                    ]),
                ],
              ),
            ),
          ),
        if (!message.isDeleted && message.attachment != null)
          TextButton.icon(
              onPressed: () => _openAttachment(message),
              icon: Icon((message.attachment!['mimeType'] ?? '')
                      .toString()
                      .startsWith('image/')
                  ? Icons.image_outlined
                  : Icons.attach_file),
              label: Text((message.attachment!['fileName'] ??
                      (_es ? 'Adjunto' : 'Attachment'))
                  .toString())),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '${DateFormat('HH:mm').format(message.createdAt.toLocal())}${message.editedAt != null ? (_es ? ' · Editado' : ' · Edited') : ''}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 10.5,
                    color: colors.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  /// A grouped message row: optional date separator, a bottom-aligned avatar
  /// (shown once per group), the sender name at the top of a group, and the
  /// content-sized bubble with contextual actions.
  Widget _buildMessageItem({
    required BusinessChatMessage message,
    required bool mine,
    required bool canEdit,
    required bool canDelete,
    required bool isFirstInGroup,
    required bool isLastInGroup,
    required bool showDateSeparator,
    required bool narrow,
    required double maxBubbleWidth,
  }) {
    const double avatarSize = 30;
    final colors = Theme.of(context).colorScheme;

    final actions = <ChatMessageAction>[
      if (!message.isDeleted)
        ChatMessageAction(
          icon: Icons.reply_rounded,
          label: _es ? 'Responder' : 'Reply',
          onSelected: () => setState(() => _replyingTo = message),
        ),
      if (!message.isDeleted && message.body.trim().isNotEmpty)
        ChatMessageAction(
          icon: Icons.copy_outlined,
          label: _es ? 'Copiar' : 'Copy',
          onSelected: () =>
              Clipboard.setData(ClipboardData(text: message.body)),
        ),
      if (canEdit)
        ChatMessageAction(
          icon: Icons.edit_outlined,
          label: _es ? 'Editar' : 'Edit',
          onSelected: () => _messageAction(message, 'edit'),
        ),
      if (canDelete)
        ChatMessageAction(
          icon: Icons.delete_outline_rounded,
          label: _es ? 'Eliminar' : 'Delete',
          destructive: true,
          onSelected: () => _messageAction(message, 'delete'),
        ),
    ];

    final avatar = isLastInGroup
        ? ChatUserAvatar(
            name: message.senderName,
            photoUrl: _memberPhotos[message.senderId],
            size: avatarSize,
          )
        : const SizedBox(width: avatarSize);

    final bubble = ChatMessageActions(
      mine: mine,
      enabled: !narrow && actions.isNotEmpty,
      actions: actions,
      child: CompactChatBubble(
        mine: mine,
        isFirstInGroup: isFirstInGroup,
        isLastInGroup: isLastInGroup,
        maxWidth: maxBubbleWidth,
        onLongPress: narrow && !message.isDeleted
            ? () => _showMobileMessageActions(message,
                canEdit: canEdit, canDelete: canDelete)
            : null,
        child: _messageContent(message, mine),
      ),
    );

    final column = Column(
      crossAxisAlignment:
          mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isFirstInGroup && !mine)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 2),
            child: Text(
              message.senderName,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.onSurfaceVariant,
                  ),
            ),
          ),
        bubble,
      ],
    );

    final row = Row(
      mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: mine
          ? [
              Flexible(child: column),
              const SizedBox(width: 8),
              avatar,
            ]
          : [
              avatar,
              const SizedBox(width: 8),
              Flexible(child: column),
            ],
    );

    return Padding(
      padding: EdgeInsets.only(top: isFirstInGroup ? 12 : 3),
      child: Column(children: [
        if (showDateSeparator) _dateSeparator(message.createdAt),
        row,
      ]),
    );
  }

  bool _sameDay(DateTime a, DateTime b) {
    final first = a.toLocal();
    final second = b.toLocal();
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  /// Centered, grouped conversation thread. On wide screens the content is
  /// constrained so messages do not stretch across the whole workspace.
  Widget _buildMessageList(bool narrow, double viewportWidth) {
    final hasOlder = _hasOlderMessages;
    final maxBubbleWidth = narrow
        ? viewportWidth * .85
        : (viewportWidth * .70).clamp(280.0, 520.0).toDouble();
    final list = ListView.builder(
      controller: _scroll,
      padding: EdgeInsets.symmetric(
        horizontal: narrow ? 10 : 20,
        vertical: narrow ? 8 : 12,
      ),
      itemCount: _messages.length + (hasOlder ? 1 : 0),
      itemBuilder: (context, index) {
        if (hasOlder && index == 0) {
          return Center(
              child: TextButton.icon(
            onPressed: _loadingOlderMessages ? null : _loadOlderMessages,
            icon: _loadingOlderMessages
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.history),
            label: Text(
                _es ? 'Cargar mensajes anteriores' : 'Load older messages'),
          ));
        }
        final i = index - (hasOlder ? 1 : 0);
        final message = _messages[i];
        final prev = i > 0 ? _messages[i - 1] : null;
        final next = i < _messages.length - 1 ? _messages[i + 1] : null;
        final mine = message.senderId == widget.currentUserId;
        final isFirstInGroup = prev == null || !_isSameGroup(prev, message);
        final isLastInGroup = next == null || !_isSameGroup(message, next);
        final showDateSeparator =
            prev == null || !_sameDay(prev.createdAt, message.createdAt);
        final canEdit = mine &&
            !message.isDeleted &&
            DateTime.now().difference(message.createdAt.toLocal()).inMinutes <
                15;
        final canDelete = !message.isDeleted &&
            (mine || (_selected?.canModerateMessages == true));
        return _buildMessageItem(
          message: message,
          mine: mine,
          canEdit: canEdit,
          canDelete: canDelete,
          isFirstInGroup: isFirstInGroup,
          isLastInGroup: isLastInGroup,
          showDateSeparator: showDateSeparator,
          narrow: narrow,
          maxBubbleWidth: maxBubbleWidth,
        );
      },
    );
    if (narrow) return list;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: list,
      ),
    );
  }

  /// Secondary conversation actions, consolidated into a single overflow menu
  /// so the header stays compact. Returns null when there is nothing to show.
  Widget? _threadOverflowMenu(BusinessChatConversation conversation) {
    final issue = conversation.issue;
    final isParticipant = conversation.type != 'general' &&
        widget.currentUserId != null &&
        conversation.participantIds.contains(widget.currentUserId);
    final hasStatus = issue?['status'] != null;
    final items = <PopupMenuEntry<String>>[
      PopupMenuItem(
        value: 'refresh',
        enabled: !_loading,
        child: Row(children: [
          const Icon(Icons.refresh, size: 18),
          const SizedBox(width: 10),
          Text(_es ? 'Actualizar' : 'Refresh'),
        ]),
      ),
      if (conversation.type == 'general')
        PopupMenuItem(
          value: 'connection',
          child: Row(children: [
            Icon(
              _liveConnected
                  ? Icons.cloud_done_outlined
                  : Icons.cloud_off_outlined,
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(_es ? 'Estado de conexión' : 'Connection status'),
          ]),
        ),
      const PopupMenuDivider(),
      if (conversation.type == 'issue')
        PopupMenuItem(
            value: 'issue', child: Text(_es ? 'Ver incidencia' : 'View issue')),
      if (hasStatus && _canAssignIssues)
        PopupMenuItem(
            value: 'assign',
            child: Text(_es ? 'Cambiar responsable' : 'Change assignee')),
      if (hasStatus && _canManageIssues)
        for (final status in const [
          'open',
          'in_progress',
          'review',
          'resolved',
          'closed',
        ])
          PopupMenuItem(
              value: 'status:$status', child: Text(_statusLabel(status))),
      if (_canCreateIssues)
        PopupMenuItem(
            value: 'newIssue',
            child: Text(_es ? 'Nueva incidencia' : 'New incident')),
      if (_canCreateTeam)
        PopupMenuItem(
            value: 'newTeam',
            child: Text(_es ? 'Nuevo chat de equipo' : 'New team chat')),
      if (isParticipant)
        PopupMenuItem(
            value: 'leave', child: Text(_es ? 'Salir del chat' : 'Leave chat')),
    ];
    if (items.isEmpty) return null;
    PopupMenuItem<String> structuredItem(
      String value,
      IconData icon,
      String label, {
      bool enabled = true,
      bool destructive = false,
    }) =>
        PopupMenuItem<String>(
          value: value,
          enabled: enabled,
          height: 40,
          textStyle:
              destructive ? const TextStyle(color: Color(0xFFDC2626)) : null,
          child: Row(children: [
            Icon(icon,
                size: 18, color: destructive ? const Color(0xFFDC2626) : null),
            const SizedBox(width: 10),
            Text(label),
          ]),
        );
    final hasWorkspaceActions = _canCreateIssues || _canCreateTeam;
    final structuredItems = <PopupMenuEntry<String>>[
      if (_canCreateIssues)
        structuredItem('newIssue', Icons.add_alert_outlined,
            _es ? 'Nueva incidencia' : 'New incident'),
      if (_canCreateTeam)
        structuredItem('newTeam', Icons.add_comment_outlined,
            _es ? 'Nuevo chat de equipo' : 'New team chat'),
      if (hasWorkspaceActions) const PopupMenuDivider(height: 9),
      structuredItem('refresh', Icons.refresh, _es ? 'Actualizar' : 'Refresh',
          enabled: !_loading),
      if (conversation.type == 'general')
        structuredItem(
          'connection',
          _liveConnected ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
          _es ? 'Estado de conexión' : 'Connection status',
        ),
      if (conversation.type == 'issue' ||
          (hasStatus && _canAssignIssues) ||
          (hasStatus && _canManageIssues))
        const PopupMenuDivider(height: 9),
      if (conversation.type == 'issue')
        structuredItem('issue', Icons.visibility_outlined,
            _es ? 'Ver incidencia' : 'View issue'),
      if (hasStatus && _canAssignIssues)
        structuredItem('assign', Icons.person_outline,
            _es ? 'Cambiar responsable' : 'Change assignee'),
      if (hasStatus && _canManageIssues)
        for (final status in const [
          'open',
          'in_progress',
          'review',
          'resolved',
          'closed',
        ])
          structuredItem('status:$status', Icons.check_circle_outline,
              _statusLabel(status)),
      if (isParticipant) const PopupMenuDivider(height: 9),
      if (isParticipant)
        structuredItem('leave', Icons.logout_outlined,
            _es ? 'Salir del chat' : 'Leave chat',
            destructive: true),
    ];
    return PopupMenuButton<String>(
      tooltip: _es ? 'Más acciones' : 'More actions',
      icon: const Icon(Icons.more_vert_rounded, size: 20),
      color: Theme.of(context).colorScheme.surface,
      elevation: 6,
      constraints: const BoxConstraints(minWidth: 224),
      menuPadding: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      onSelected: (value) {
        if (value == 'refresh') _refresh();
        if (value == 'connection') _showConnectionInfo();
        if (value == 'issue') _showIssueDetails(conversation);
        if (value == 'assign') _assignIssue(conversation);
        if (value == 'leave') _leaveConversation(conversation);
        if (value == 'newIssue') _createIssue();
        if (value == 'newTeam') _createTeam();
        if (value.startsWith('status:')) _setIssueStatus(value.substring(7));
      },
      itemBuilder: (_) => structuredItems,
    );
  }

  /// Compact single header for the active conversation: identity on the left,
  /// primary actions (search, members, notifications) plus an overflow menu on
  /// the right. Replaces the previous multi-line header that repeated the title
  /// and kept every action permanently visible.
  Widget _buildThreadHeader(bool narrow) {
    final conversation = _selected!;
    final colors = Theme.of(context).colorScheme;
    final issue = conversation.issue;
    final icon = conversation.type == 'issue'
        ? Icons.report_outlined
        : conversation.type == 'team'
            ? Icons.groups_outlined
            : Icons.campaign_outlined;
    final title = issue?['title']?.toString() ?? conversation.title;

    final parts = <String>[];
    bool? connected;
    if (conversation.type == 'general') {
      connected = _liveConnected;
      parts.add(_liveConnected
          ? (_es ? 'Conectado' : 'Connected')
          : (_es ? 'Sin conexión en directo' : 'Live connection unavailable'));
    }
    if (conversation.type == 'issue') {
      parts.add(issue?['assigneeName'] == null
          ? (_es ? 'Sin asignar' : 'Unassigned')
          : '${_es ? 'Asignada a' : 'Assigned to'} ${issue!['assigneeName']}');
      if (issue?['status'] != null) {
        parts.add(_statusLabel(issue!['status'].toString()));
      }
    }
    final participantLabel =
        conversation.type == 'team' || conversation.type == 'issue'
            ? (_es
                ? '${conversation.participantIds.length} participantes'
                : '${conversation.participantIds.length} participants')
            : null;
    final clientEvent = [issue?['clientName'], issue?['eventTitle']]
        .whereType<String>()
        .join(' · ');
    if (clientEvent.isNotEmpty) parts.add(clientEvent);

    final canManageParticipants =
        (conversation.type == 'team' || conversation.type == 'issue') &&
            conversation.canManageParticipants;
    final overflow = _threadOverflowMenu(conversation);

    final trailing = <Widget>[
      if (!narrow && _canCreateIssues)
        TextButton.icon(
          onPressed: _createIssue,
          icon: const Icon(Icons.add_alert_outlined, size: 18),
          label: Text(_es ? 'Nueva incidencia' : 'New incident'),
          style: TextButton.styleFrom(
            foregroundColor: colors.primary,
            minimumSize: const Size(0, 34),
            padding: const EdgeInsets.symmetric(horizontal: 10),
          ),
        ),
      IconButton(
        tooltip: _es ? 'Buscar mensajes' : 'Search messages',
        visualDensity: VisualDensity.compact,
        onPressed: _searchHistory,
        icon: const Icon(Icons.search, size: 20),
      ),
      if (conversation.type == 'general')
        IconButton(
          tooltip: _es ? 'Miembros' : 'Members',
          visualDensity: VisualDensity.compact,
          onPressed: _showGeneralMembers,
          icon: const Icon(Icons.groups_outlined, size: 20),
        ),
      if (canManageParticipants)
        IconButton(
          tooltip: _es ? 'Participantes' : 'Participants',
          visualDensity: VisualDensity.compact,
          onPressed: () => _manageParticipants(conversation),
          icon: const Icon(Icons.manage_accounts_outlined, size: 20),
        ),
      IconButton(
        tooltip: conversation.muted
            ? (_es ? 'Activar avisos de mensajes' : 'Unmute messages')
            : (_es ? 'Silenciar avisos de mensajes' : 'Mute messages'),
        visualDensity: VisualDensity.compact,
        onPressed: () => _toggleMute(conversation),
        icon: Icon(
            conversation.muted
                ? Icons.notifications_off_outlined
                : Icons.notifications_active_outlined,
            size: 20),
      ),
      if (overflow != null) overflow,
    ];

    return Material(
      color: colors.surfaceContainerLow,
      child: Column(children: [
        ChatChannelHeader(
          icon: icon,
          title: title,
          subtitle: parts.join(' · '),
          subtitleActionLabel: participantLabel,
          onSubtitleActionTap: canManageParticipants
              ? () => _manageParticipants(conversation)
              : null,
          connected: connected,
          onBack:
              narrow ? () => setState(() => _showChatOnNarrow = false) : null,
          trailing: trailing,
        ),
        const Divider(height: 1),
      ]),
    );
  }

  Widget _buildConversationHeader(
      BuildContext context, bool narrow, ColorScheme colors) {
    final totalUnread =
        _conversations.fold<int>(0, (sum, item) => sum + item.unreadCount);
    // ignore: unused_local_variable
    final wifi = Tooltip(
      message: _liveConnected
          ? (_es ? 'Actualizaciones en directo' : 'Live updates')
          : (_es
              ? 'Sin conexión en directo; se actualiza cada minuto'
              : 'Live connection unavailable; checks every minute'),
      child: Icon(_liveConnected ? Icons.wifi : Icons.wifi_off,
          size: 18, color: _liveConnected ? colors.primary : colors.outline),
    );
    // ignore: unused_local_variable
    final refreshButton = IconButton(
      onPressed: _loading ? null : _refresh,
      tooltip: _es ? 'Actualizar' : 'Refresh',
      visualDensity: VisualDensity.compact,
      icon: const Icon(Icons.refresh),
    );

    if (narrow) {
      // One compact inbox header: title, small connection dot, members and a
      // single overflow for refresh / connection info / creation actions.
      return Material(
        color: colors.surfaceContainerLow,
        child: Column(children: [
          MobileChatInboxHeader(
            title: _es ? 'Hexora Chat' : 'Hexora Chat',
            connected: _liveConnected,
            statusLabel: _liveConnected
                ? (_es ? 'Conectado' : 'Connected')
                : (_es ? 'Sin conexión en directo' : 'Offline'),
            unreadTotal: totalUnread,
            onBack: widget.onExit,
            trailing: [
              IconButton(
                onPressed: _showMemberPresence,
                tooltip: _es ? 'Miembros' : 'Members',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.people_alt_outlined, size: 20),
              ),
              PopupMenuButton<String>(
                tooltip: _es ? 'Más opciones' : 'More options',
                icon: const Icon(Icons.more_vert_rounded, size: 20),
                onSelected: (value) {
                  if (value == 'refresh') _refresh();
                  if (value == 'connection') _showConnectionInfo();
                  if (value == 'issue') _createIssue();
                  if (value == 'team') _createTeam();
                },
                itemBuilder: (_) => [
                  PopupMenuItem<String>(
                    value: 'refresh',
                    enabled: !_loading,
                    child: Row(children: [
                      const Icon(Icons.refresh, size: 18),
                      const SizedBox(width: 10),
                      Text(_es ? 'Actualizar' : 'Refresh'),
                    ]),
                  ),
                  PopupMenuItem<String>(
                    value: 'connection',
                    child: Row(children: [
                      Icon(
                          _liveConnected
                              ? Icons.cloud_done_outlined
                              : Icons.cloud_off_outlined,
                          size: 18),
                      const SizedBox(width: 10),
                      Text(_es ? 'Estado de conexión' : 'Connection status'),
                    ]),
                  ),
                  if (_canCreateIssues)
                    PopupMenuItem<String>(
                      value: 'issue',
                      child: Row(children: [
                        const Icon(Icons.report_gmailerrorred_outlined,
                            size: 18),
                        const SizedBox(width: 10),
                        Text(_es ? 'Nueva incidencia' : 'New incident'),
                      ]),
                    ),
                  if (_canCreateTeam)
                    PopupMenuItem<String>(
                      value: 'team',
                      child: Row(children: [
                        const Icon(Icons.group_add_outlined, size: 18),
                        const SizedBox(width: 10),
                        Text(_es ? 'Nuevo chat de equipo' : 'New team chat'),
                      ]),
                    ),
                ],
              ),
            ],
          ),
          const Divider(height: 1),
        ]),
      );
    }

    // Desktop no longer has an inbox-wide toolbar. Its controls live in the
    // active conversation header, keeping both panes aligned at their top edge.
    return const SizedBox.shrink();
  }

  String _conversationTimestamp(DateTime? value) {
    if (value == null) return '';
    final local = value.toLocal();
    final now = DateTime.now();
    final sameDay = local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    return sameDay
        ? DateFormat('HH:mm').format(local)
        : DateFormat(_es ? 'dd/MM' : 'MM/dd').format(local);
  }

  bool get _hasBusinessActions =>
      _canShareBankTransactions || _canRequestDocumentReview;

  void _runBusinessAction(String action) {
    setState(() => _activeBusinessAction = action);
    switch (action) {
      case 'bank':
        _shareBankTransactionFromChat();
        break;
      case 'invoice':
        _requestDocumentReview('invoice');
        break;
      case 'expense':
        _requestDocumentReview('expense');
        break;
      case 'hours':
        _requestDocumentReview('worker_hours');
        break;
    }
  }

  Widget _buildBusinessActionsList() {
    final actions = <_BusinessRailAction>[
      if (_canShareBankTransactions)
        _BusinessRailAction(
          id: 'bank',
          icon: Icons.account_balance_outlined,
          label: _es ? 'Compartir movimiento' : 'Share transaction',
        ),
      if (_canRequestDocumentReview)
        _BusinessRailAction(
          id: 'invoice',
          icon: Icons.receipt_long_outlined,
          label: _es ? 'Revisar factura' : 'Review invoice',
        ),
      if (_canRequestDocumentReview)
        _BusinessRailAction(
          id: 'expense',
          icon: Icons.payments_outlined,
          label: _es ? 'Revisar gasto' : 'Review expense',
        ),
      if (_canRequestDocumentReview)
        _BusinessRailAction(
          id: 'hours',
          icon: Icons.access_time_outlined,
          label: _es ? 'Revisar horas' : 'Review hours',
        ),
    ];

    return ColoredBox(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          for (final action in actions)
            _BusinessRailButton(
              action: action,
              expanded: true,
              navySurface: true,
              selected: _activeBusinessAction == action.id,
              onTap: () => _runBusinessAction(action.id),
            ),
        ],
      ),
    );
  }

  Widget _buildLeftNavigationTabs(ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
      child: Container(
        height: 34,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            _ChatNavigationTab(
              icon: Icons.forum_outlined,
              label: _es ? 'Chats' : 'Chats',
              selected: !_showActions,
              onTap: () => setState(() => _showActions = false),
            ),
            _ChatNavigationTab(
              icon: Icons.bolt_outlined,
              label: _es ? 'Acciones' : 'Actions',
              selected: _showActions,
              onTap: () => setState(() => _showActions = true),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final workspaceChrome = WorkspaceTabChromeScope.maybeOf(context);
    final isNarrowViewport = MediaQuery.sizeOf(context).width < 700;
    final query = _conversationSearch.text.trim().toLowerCase();
    final visibleConversations = query.isEmpty
        ? _conversations
        : _conversations
            .where((conversation) => [
                  conversation.title,
                  conversation.issue?['title']?.toString() ?? '',
                  conversation.issue?['clientName']?.toString() ?? '',
                  conversation.lastMessage?.body ?? '',
                ].join(' ').toLowerCase().contains(query))
            .toList();
    return SafeArea(
        top: widget.onExit != null,
        bottom: false,
        child: Stack(children: [
          Column(children: [
            if (isNarrowViewport && !_showChatOnNarrow) ...[
              _buildConversationHeader(context, isNarrowViewport, colors),
              const Divider(height: 1),
            ],
            Expanded(child: LayoutBuilder(builder: (context, constraints) {
              final narrow = constraints.maxWidth < 700;
              return Row(children: [
                if (!narrow || !_showChatOnNarrow)
                  SizedBox(
                      width: narrow
                          ? constraints.maxWidth
                          : (_chatPaneCollapsed
                              ? NavigationTokens.railWidth
                              : 250),
                      child: SidebarEdgeShell(
                        collapsed: !narrow && _chatPaneCollapsed,
                        onToggle: narrow
                            ? null
                            : () => setState(
                                () => _chatPaneCollapsed = !_chatPaneCollapsed),
                        showHandle: !narrow,
                        expandTooltip: _es
                            ? 'Mostrar conversaciones'
                            : 'Show conversations',
                        collapseTooltip: _es
                            ? 'Compactar conversaciones'
                            : 'Compact conversations',
                        backgroundColor: narrow
                            ? Colors.transparent
                            : AppColors.dashboardTopBar,
                        child: Column(children: [
                          if (narrow)
                            ChatInboxSearch(
                              controller: _conversationSearch,
                              onChanged: (_) => setState(() {}),
                              onClear: () =>
                                  setState(_conversationSearch.clear),
                              hintText: _es
                                  ? 'Buscar conversaciones'
                                  : 'Search conversations',
                              clearTooltip:
                                  _es ? 'Borrar búsqueda' : 'Clear search',
                            )
                          else ...[
                            if (!_chatPaneCollapsed) ...[
                              _buildLeftNavigationTabs(colors),
                            ],
                            if (!_showActions && !_chatPaneCollapsed)
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(12, 4, 12, 8),
                                child: TextField(
                                  controller: _conversationSearch,
                                  onChanged: (_) => setState(() {}),
                                  style: const TextStyle(
                                    color: Color(0xFFF1F5FC),
                                  ),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    filled: true,
                                    fillColor:
                                        Colors.white.withValues(alpha: .08),
                                    prefixIcon: const Icon(Icons.search,
                                        size: 20, color: Color(0xFFB8C7DB)),
                                    hintText: _es
                                        ? 'Buscar conversaciones'
                                        : 'Search conversations',
                                    hintStyle: const TextStyle(
                                      color: Color(0xFFB8C7DB),
                                    ),
                                    suffixIcon: query.isEmpty
                                        ? null
                                        : IconButton(
                                            tooltip: _es
                                                ? 'Borrar búsqueda'
                                                : 'Clear search',
                                            icon: const Icon(Icons.close,
                                                color: Color(0xFFB8C7DB)),
                                            onPressed: () => setState(
                                                _conversationSearch.clear),
                                          ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color:
                                            Colors.white.withValues(alpha: .22),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                          Expanded(
                              child: _showActions &&
                                      !narrow &&
                                      !_chatPaneCollapsed
                                  ? _buildBusinessActionsList()
                                  : visibleConversations.isEmpty
                                      ? Center(
                                          child: _loading
                                              ? const CircularProgressIndicator()
                                              : Padding(
                                                  padding:
                                                      const EdgeInsets.all(20),
                                                  child: Text(
                                                      _error ??
                                                          (query.isNotEmpty
                                                              ? (_es
                                                                  ? 'Sin resultados'
                                                                  : 'No results')
                                                              : (_es
                                                                  ? 'No hay conversaciones'
                                                                  : 'No conversations')),
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        color: narrow
                                                            ? null
                                                            : Colors.white
                                                                .withValues(
                                                                    alpha: .78),
                                                      ))))
                                      : ListView.separated(
                                          key: const PageStorageKey(
                                              'business-chat-conversations'),
                                          itemCount:
                                              visibleConversations.length,
                                          separatorBuilder: (_, __) => Divider(
                                                height: 1,
                                                indent: 64,
                                                color: narrow
                                                    ? colors.outlineVariant
                                                        .withValues(alpha: .45)
                                                    : Colors.white
                                                        .withValues(alpha: .10),
                                              ),
                                          itemBuilder: (context, index) {
                                            final conversation =
                                                visibleConversations[index];
                                            final selected = _selected?.id ==
                                                conversation.id;
                                            final status =
                                                conversation.issue?['status'];
                                            final lastMessage =
                                                conversation.lastMessage;
                                            final preview = lastMessage == null
                                                ? (status == null
                                                    ? _typeLabel(
                                                        conversation.type)
                                                    : _statusLabel(
                                                        status.toString()))
                                                : lastMessage.isDeleted
                                                    ? (_es
                                                        ? 'Mensaje eliminado'
                                                        : 'Message deleted')
                                                    : lastMessage
                                                                .bankTransaction !=
                                                            null
                                                        ? (_es
                                                            ? 'Movimiento bancario compartido'
                                                            : 'Shared bank transaction')
                                                        : lastMessage.review !=
                                                                null
                                                            ? (_es
                                                                ? 'Revisión solicitada'
                                                                : 'Review requested')
                                                            : lastMessage.body
                                                                    .trim()
                                                                    .isNotEmpty
                                                                ? lastMessage
                                                                    .body
                                                                : (lastMessage.attachment?[
                                                                            'fileName'] ??
                                                                        (_es
                                                                            ? 'Archivo adjunto'
                                                                            : 'Attachment'))
                                                                    .toString();
                                            if (_chatPaneCollapsed && !narrow) {
                                              return _CompactConversationRailItem(
                                                icon: conversation.type ==
                                                        'issue'
                                                    ? Icons.report_outlined
                                                    : conversation.type ==
                                                            'team'
                                                        ? Icons.groups_outlined
                                                        : Icons
                                                            .campaign_outlined,
                                                title: conversation
                                                        .issue?['title']
                                                        ?.toString() ??
                                                    conversation.title,
                                                selected: selected,
                                                unreadCount:
                                                    conversation.unreadCount,
                                                onTap: () {
                                                  final oldId = _selected?.id;
                                                  setState(() {
                                                    _selected = conversation;
                                                    _messages = const [];
                                                    _activeBusinessAction =
                                                        null;
                                                  });
                                                  _switchDraft(
                                                      oldId, conversation.id);
                                                  _loadMessages(conversation,
                                                      forceScroll: true);
                                                },
                                              );
                                            }
                                            return CompactConversationTile(
                                              icon: conversation.type == 'issue'
                                                  ? Icons.report_outlined
                                                  : conversation.type == 'team'
                                                      ? Icons.groups_outlined
                                                      : Icons.campaign_outlined,
                                              title: conversation
                                                      .issue?['title']
                                                      ?.toString() ??
                                                  conversation.title,
                                              preview: preview,
                                              timestamp: _conversationTimestamp(
                                                  lastMessage?.createdAt),
                                              unreadCount:
                                                  conversation.unreadCount,
                                              selected: selected,
                                              muted: conversation.muted,
                                              circularAvatar: narrow,
                                              navySurface: !narrow,
                                              onTap: () {
                                                final oldId = _selected?.id;
                                                setState(() {
                                                  _selected = conversation;
                                                  _messages = const [];
                                                  _showChatOnNarrow = true;
                                                  _activeBusinessAction = null;
                                                });
                                                _switchDraft(
                                                    oldId, conversation.id);
                                                _loadMessages(conversation,
                                                    forceScroll: true);
                                              },
                                            );
                                          })),
                        ]),
                      )),
                if (!narrow)
                  VerticalDivider(
                    width: 1,
                    color: Colors.white.withValues(alpha: .10),
                  ),
                if (!narrow || _showChatOnNarrow)
                  Expanded(
                      child: Column(children: [
                    if (!narrow && workspaceChrome?.active == true)
                      workspaceChrome!.tabBarBuilder(context),
                    Expanded(
                        child: Row(children: [
                      // Keep the review workspace below the shared Chrome
                      // strip, alongside the conversation rather than above it.
                      if (_reviewPanel != null &&
                          !narrow &&
                          constraints.maxWidth >= 1240) ...[
                        const VerticalDivider(width: 1),
                        Offstage(
                          offstage: !_reviewCollapsed,
                          child: _ReviewReopenRail(
                            es: _es,
                            onReopen: () =>
                                setState(() => _reviewCollapsed = false),
                          ),
                        ),
                        Offstage(
                          offstage: _reviewCollapsed,
                          child: SizedBox(
                            width: (constraints.maxWidth * .42)
                                .clamp(600.0, 800.0)
                                .toDouble(),
                            child: _reviewPanel!,
                          ),
                        ),
                      ],
                      Expanded(
                        child: Column(children: [
                          if (_selected != null) _buildThreadHeader(narrow),
                          Expanded(
                              child: _error != null && _messages.isEmpty
                                  ? Center(
                                      child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                          Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Text(_error!,
                                                  textAlign: TextAlign.center)),
                                          TextButton(
                                              onPressed: _refresh,
                                              child: Text(
                                                  _es ? 'Reintentar' : 'Retry'))
                                        ]))
                                  : _selected == null
                                      ? Center(
                                          child: _loading
                                              ? const CircularProgressIndicator()
                                              : Text(_es
                                                  ? 'Selecciona una conversación.'
                                                  : 'Select a conversation.'))
                                      : _messages.isEmpty
                                          ? Center(
                                              child: Text(_es
                                                  ? 'Todavía no hay mensajes.'
                                                  : 'No messages yet.'))
                                          : _buildMessageList(
                                              narrow, constraints.maxWidth)),
                          const Divider(height: 1),
                          Padding(
                              padding: EdgeInsets.all(narrow ? 8 : 10),
                              child: SafeArea(
                                  top: false,
                                  child: Center(
                                      child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                              maxWidth: narrow
                                                  ? double.infinity
                                                  : 1000),
                                          child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (_replyingTo != null)
                                                  Card(
                                                    child: ListTile(
                                                      dense: true,
                                                      leading: const Icon(
                                                          Icons.reply),
                                                      title: Text(_es
                                                          ? 'Respondiendo a ${_replyingTo!.senderName}'
                                                          : 'Replying to ${_replyingTo!.senderName}'),
                                                      subtitle: Text(
                                                        _replyingTo!
                                                                .body.isNotEmpty
                                                            ? _replyingTo!.body
                                                            : (_es
                                                                ? 'Adjunto o referencia'
                                                                : 'Attachment or reference'),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                      trailing: IconButton(
                                                        tooltip: _es
                                                            ? 'Cancelar respuesta'
                                                            : 'Cancel reply',
                                                        onPressed: () =>
                                                            setState(() =>
                                                                _replyingTo =
                                                                    null),
                                                        icon: const Icon(
                                                            Icons.close),
                                                      ),
                                                    ),
                                                  ),
                                                ChatComposer(
                                                  controller: _composer,
                                                  focusNode: _composerFocus,
                                                  enabled: _selected != null,
                                                  sending: _sending,
                                                  narrow: narrow,
                                                  onSend: _send,
                                                  onPlus:
                                                      _showBusinessActionsSheet,
                                                  hintText: _es
                                                      ? 'Escribe un mensaje…'
                                                      : 'Write a message…',
                                                  plusTooltip: _es
                                                      ? 'Acciones y adjuntos'
                                                      : 'Actions and attachments',
                                                  sendTooltip:
                                                      _es ? 'Enviar' : 'Send',
                                                ),
                                                if (_selected != null &&
                                                    !narrow &&
                                                    !_hasBusinessActions &&
                                                    _sending)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            left: 48, top: 4),
                                                    child: Align(
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      child: Wrap(
                                                        crossAxisAlignment:
                                                            WrapCrossAlignment
                                                                .center,
                                                        spacing: 8,
                                                        children: [
                                                          if (_canShareBankTransactions)
                                                            TextButton.icon(
                                                              onPressed:
                                                                  _shareBankTransactionFromChat,
                                                              icon: const Icon(
                                                                  Icons
                                                                      .account_balance_outlined,
                                                                  size: 17),
                                                              label: Text(_es
                                                                  ? 'Compartir movimiento bancario'
                                                                  : 'Share bank transaction'),
                                                            ),
                                                          if (_canRequestDocumentReview)
                                                            TextButton.icon(
                                                              onPressed: () =>
                                                                  _requestDocumentReview(
                                                                      'invoice'),
                                                              icon: const Icon(
                                                                  Icons
                                                                      .receipt_long_outlined,
                                                                  size: 17),
                                                              label: Text(_es
                                                                  ? 'Revisar factura'
                                                                  : 'Review invoice'),
                                                            ),
                                                          if (_canRequestDocumentReview)
                                                            TextButton.icon(
                                                              onPressed: () =>
                                                                  _requestDocumentReview(
                                                                      'expense'),
                                                              icon: const Icon(
                                                                  Icons
                                                                      .payments_outlined,
                                                                  size: 17),
                                                              label: Text(_es
                                                                  ? 'Revisar gasto'
                                                                  : 'Review expense'),
                                                            ),
                                                          if (_canRequestDocumentReview)
                                                            TextButton.icon(
                                                              onPressed: () =>
                                                                  _requestDocumentReview(
                                                                      'worker_hours'),
                                                              icon: const Icon(
                                                                  Icons
                                                                      .access_time_outlined,
                                                                  size: 17),
                                                              label: Text(_es
                                                                  ? 'Revisar horas'
                                                                  : 'Review hours'),
                                                            ),
                                                          Text(
                                                            _es
                                                                ? 'Adjuntos: JPG, PNG, WebP o PDF · máximo 10 MB'
                                                                : 'Attachments: JPG, PNG, WebP, or PDF · max 10 MB',
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .labelSmall,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                              ]))))),
                        ]),
                      ),
                    ])),
                  ])),
              ]);
            })),
          ]),
          if (_reviewPanel != null &&
              !isNarrowViewport &&
              MediaQuery.sizeOf(context).width < 1240) ...[
            // Keep the overlay panel mounted while collapsed to preserve its
            // state; Offstage hides it without disposing.
            Padding(
              padding: EdgeInsets.only(
                top: workspaceChrome?.active == true ? 36 : 0,
              ),
              child: Offstage(
                offstage: _reviewCollapsed,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Material(
                    elevation: 12,
                    color: Theme.of(context).colorScheme.surface,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: (MediaQuery.sizeOf(context).width - 24)
                            .clamp(320.0, 800.0)
                            .toDouble(),
                      ),
                      child: SizedBox(
                        width: (MediaQuery.sizeOf(context).width * .46)
                            .clamp(600.0, 800.0)
                            .toDouble(),
                        height: double.infinity,
                        child: _reviewPanel!,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_reviewCollapsed)
              Padding(
                padding: EdgeInsets.only(
                  top: workspaceChrome?.active == true ? 36 : 0,
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    height: double.infinity,
                    child: Material(
                      elevation: 12,
                      color: Theme.of(context).colorScheme.surface,
                      child: _ReviewReopenRail(
                        es: _es,
                        onReopen: () =>
                            setState(() => _reviewCollapsed = false),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ]));
  }
}

/// Slim vertical rail shown where the invoice review panel was, letting the
/// user reopen it. The panel itself stays mounted (via Offstage) so its state
/// is preserved while collapsed.
class _ReviewReopenRail extends StatelessWidget {
  const _ReviewReopenRail({required this.es, required this.onReopen});

  final bool es;
  final VoidCallback onReopen;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = es ? 'Revisar factura' : 'Review invoice';
    return Container(
      width: 44,
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          left: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          IconButton(
            tooltip: es ? 'Mostrar panel de revisión' : 'Show review panel',
            onPressed: onReopen,
            icon: const Icon(Icons.chevron_left_rounded, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: cs.primary.withValues(alpha: 0.10),
              foregroundColor: cs.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: RotatedBox(
              quarterTurns: 3,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long_outlined,
                        size: 14, color: cs.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
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
}

class _BusinessRailAction {
  const _BusinessRailAction({
    required this.id,
    required this.icon,
    required this.label,
  });

  final String id;
  final IconData icon;
  final String label;
}

class _CompactConversationRailItem extends StatelessWidget {
  const _CompactConversationRailItem({
    required this.icon,
    required this.title,
    required this.selected,
    required this.unreadCount,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool selected;
  final int unreadCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: title,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 56,
          alignment: Alignment.center,
          color: selected
              ? Colors.white.withValues(alpha: .12)
              : Colors.transparent,
          child: Badge(
            isLabelVisible: unreadCount > 0,
            label: Text(unreadCount > 9 ? '9+' : '$unreadCount'),
            backgroundColor: const Color(0xFF60A5FA),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF2563EB).withValues(alpha: .28)
                    : Colors.white.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 18,
                color: selected
                    ? const Color(0xFFBFDBFE)
                    : const Color(0xFFB8C7DB),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatNavigationTab extends StatelessWidget {
  const _ChatNavigationTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? Colors.white.withValues(alpha: .14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: selected
                      ? const Color(0xFF93C5FD)
                      : const Color(0xFFB8C7DB)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: selected
                            ? const Color(0xFFF1F5FC)
                            : const Color(0xFFB8C7DB),
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w600,
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

class _BusinessRailButton extends StatelessWidget {
  const _BusinessRailButton({
    required this.action,
    required this.expanded,
    this.navySurface = false,
    required this.selected,
    required this.onTap,
  });

  final _BusinessRailAction action;
  final bool expanded;
  final bool navySurface;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = navySurface
        ? (selected ? const Color(0xFF93C5FD) : const Color(0xFFB8C7DB))
        : (selected ? cs.primary : cs.onSurfaceVariant);
    final content = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 40,
        margin: EdgeInsets.symmetric(horizontal: expanded ? 8 : 6, vertical: 2),
        padding: EdgeInsets.symmetric(horizontal: expanded ? 10 : 0),
        decoration: BoxDecoration(
          color: selected
              ? (navySurface
                  ? cs.primary.withValues(alpha: .28)
                  : cs.primaryContainer.withValues(alpha: .65))
              : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment:
              expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            Icon(action.icon, size: 19, color: color),
            if (expanded) ...[
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  action.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: color,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w600,
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
    return expanded ? content : Tooltip(message: action.label, child: content);
  }
}

class _BusinessChatMembersDialog extends StatefulWidget {
  const _BusinessChatMembersDialog({
    required this.api,
    required this.groupId,
    required this.spanish,
  });

  final BusinessChatApi api;
  final String groupId;
  final bool spanish;

  @override
  State<_BusinessChatMembersDialog> createState() =>
      _BusinessChatMembersDialogState();
}

class _BusinessChatMembersDialogState
    extends State<_BusinessChatMembersDialog> {
  List<BusinessChatMember> _members = const [];
  bool _loading = true;
  bool _requestInFlight = false;
  String? _error;
  String _query = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (_requestInFlight) return;
    _requestInFlight = true;
    try {
      final members = await widget.api.memberPresence(widget.groupId);
      if (!mounted) return;
      members.sort((a, b) {
        if (a.isOnline != b.isOnline) return a.isOnline ? -1 : 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      setState(() {
        _members = members;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _members = const [];
        _loading = false;
        _error = widget.spanish
            ? 'No se pudo cargar la conexión de los miembros.'
            : 'Could not load member presence.';
      });
    } finally {
      _requestInFlight = false;
    }
  }

  String _lastSeen(DateTime? value) {
    if (value == null) {
      return widget.spanish
          ? 'Sin conexión anterior registrada'
          : 'No previous connection recorded';
    }
    final elapsed = DateTime.now().difference(value.toLocal());
    final ago = elapsed.inDays > 0
        ? '${elapsed.inDays} d'
        : elapsed.inHours > 0
            ? '${elapsed.inHours} h'
            : '${elapsed.inMinutes.clamp(1, 59)} min';
    return widget.spanish ? 'Última conexión hace $ago' : 'Last seen $ago ago';
  }

  String _role(String role) {
    switch (role) {
      case 'owner':
        return widget.spanish ? 'Propietario' : 'Owner';
      case 'admin':
        return widget.spanish ? 'Administrador' : 'Admin';
      case 'co-admin':
        return widget.spanish ? 'Coadministrador' : 'Co-Admin';
      case 'worker':
        return widget.spanish ? 'Trabajador' : 'Worker';
      default:
        return widget.spanish ? 'Miembro' : 'Member';
    }
  }

  @override
  Widget build(BuildContext context) {
    final online = _members.where((member) => member.isOnline).length;
    final visible = _members
        .where((member) =>
            member.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    final colors = Theme.of(context).colorScheme;
    final screen = MediaQuery.sizeOf(context);
    return AlertDialog(
      title: Row(children: [
        Expanded(
            child: Text(
                widget.spanish
                    ? 'Miembros · $online conectados'
                    : 'Members · $online online',
                style: Theme.of(context).textTheme.titleMedium)),
        IconButton(
          tooltip: widget.spanish ? 'Actualizar' : 'Refresh',
          onPressed: _load,
          icon: const Icon(Icons.refresh, size: 20),
        ),
      ]),
      content: SizedBox(
        width: screen.width < 488 ? screen.width - 128 : 360,
        height: (_members.length * 44.0 + (_members.length > 8 ? 60 : 0))
            .clamp(120.0, (screen.height - 180).clamp(120.0, 440.0))
            .toDouble(),
        child: _loading && _members.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _error != null && _members.isEmpty
                ? Text(_error!)
                : Column(mainAxisSize: MainAxisSize.min, children: [
                    if (_members.length > 8)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TextField(
                          onChanged: (value) => setState(() => _query = value),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: widget.spanish
                                ? 'Buscar miembros'
                                : 'Search members',
                            prefixIcon: const Icon(Icons.search, size: 18),
                          ),
                        ),
                      ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: visible.length,
                        itemBuilder: (context, index) {
                          final member = visible[index];
                          final status = !member.presenceVisible
                              ? (widget.spanish
                                  ? 'Estado oculto'
                                  : 'Status hidden')
                              : member.isOnline
                                  ? (widget.spanish ? 'En línea' : 'Online')
                                  : _lastSeen(member.lastActiveAt);
                          return SizedBox(
                            height: 44,
                            child: Row(children: [
                              Stack(clipBehavior: Clip.none, children: [
                                AvatarUtils.profileAvatar(
                                    context, member.photoUrl,
                                    radius: 15),
                                if (member.presenceVisible)
                                  Positioned(
                                    right: -1,
                                    bottom: -1,
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: member.isOnline
                                            ? Colors.green
                                            : colors.outlineVariant,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: colors.surface, width: 1.5),
                                      ),
                                    ),
                                  ),
                              ]),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(member.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium),
                                  Tooltip(
                                    message: member.isOnline ||
                                            member.lastActiveAt == null ||
                                            !member.presenceVisible
                                        ? status
                                        : '${_lastSeen(member.lastActiveAt)} · ${DateFormat('dd/MM/yyyy HH:mm').format(member.lastActiveAt!.toLocal())}',
                                    child: Text(
                                        '${_role(member.role)} · $status',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall),
                                  ),
                                ],
                              )),
                            ]),
                          );
                        },
                      ),
                    ),
                  ]),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.spanish ? 'Cerrar' : 'Close'),
        )
      ],
    );
  }
}
