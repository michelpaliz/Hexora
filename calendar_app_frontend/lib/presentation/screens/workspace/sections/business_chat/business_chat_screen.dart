import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hexora/navigation/shell/hexora_nav_components.dart';
import 'package:hexora/presentation/screens/workspace/sections/telegram/components/telegram_client_document_picker_dialog.dart';
import 'package:hexora/presentation/screens/workspace/sections/telegram/components/telegram_worker_document_picker_dialog.dart';
import 'package:hexora/presentation/shared/widgets/buttons/hexora_button.dart';
import 'package:hexora/presentation/shared/widgets/collapsible_sidebar.dart';
import 'package:hexora/presentation/shared/widgets/sidebar_item.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/tabs/workspace_content.dart';
import 'package:hexora/services/auth/token/token_service.dart';
import 'package:hexora/services/business_chat/business_chat_api.dart';
import 'package:hexora/services/business_chat/business_chat_drafts.dart';
import 'package:hexora/services/config/api_constants.dart';
import 'package:hexora/services/shared/backend_api_exception.dart';
import 'package:hexora/services/groups/domain/group_domain.dart';
import 'package:hexora/presentation/screens/workspace/sections/enable_banking/enable_banking_screen.dart';
import 'package:hexora/presentation/screens/workspace/sections/enable_banking/statements/shared/bank_transaction_share_dialog.dart';
import 'package:provider/provider.dart';
import 'bank_transaction_chat_card.dart';
import 'bank_transaction_picker.dart';
import 'business_chat_search_dialog.dart';
import 'package:intl/intl.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:url_launcher/url_launcher.dart';
import 'business_chat_expense_picker.dart';

class BusinessChatScreen extends StatefulWidget {
  const BusinessChatScreen(
      {super.key,
      required this.groupId,
      required this.currentUserId,
      this.initialConversationId});
  final String groupId;
  final String? currentUserId;
  final String? initialConversationId;

  @override
  State<BusinessChatScreen> createState() => _BusinessChatScreenState();
}

class _BusinessChatScreenState extends State<BusinessChatScreen> {
  final _api = BusinessChatApi();
  final _draftStore = BusinessChatDrafts();
  final _composer = TextEditingController();
  final _composerFocus = FocusNode();
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
  bool _showChatOnNarrow = false;
  bool _menuCollapsed = false;
  String? _error;
  String? _pendingConversationId;
  bool get _es => Localizations.localeOf(context).languageCode == 'es';

  @override
  void initState() {
    super.initState();
    _pendingConversationId = widget.initialConversationId;
    _composer.addListener(_onComposerChanged);
    _refresh();
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
      _canManageIssues = false;
      _canAssignIssues = false;
      _refresh();
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
      _canManageIssues = false;
      _canAssignIssues = false;
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
    final entry = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => BankTransactionPicker(groupId: widget.groupId),
    );
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

  Future<void> _attach({bool imagesOnly = false}) async {
    final conversation = _selected;
    if (_sending || conversation == null) return;
    final picked = await FilePicker.platform.pickFiles(
        type: imagesOnly ? FileType.image : FileType.custom,
        allowedExtensions:
            imagesOnly ? null : ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
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

  Future<void> _shareClientDocuments(Set<String> documentKinds) async {
    final conversation = _selected;
    if (_sending || conversation == null) return;
    final selected = await showTelegramClientDocumentPickerDialog(
      context,
      groupId: widget.groupId,
      allowedDocumentKinds: documentKinds,
    );
    if (!mounted || selected == null || selected.isEmpty) return;

    setState(() => _sending = true);
    try {
      for (final (index, document) in selected.indexed) {
        await _api.sendAttachment(
          widget.groupId,
          conversation.id,
          PlatformFile(
            name: document.fileName,
            size: document.bytes.length,
            bytes: document.bytes,
          ),
          index == 0 ? _composer.text.trim() : '',
          replyToMessageId: index == 0 ? _replyingTo?.id : null,
          businessRecord: {
            'type': document.documentKind,
            'id': document.documentId,
            'clientId': document.clientId,
            'label': document.documentLabel,
          },
        );
      }
      if (!mounted) return;
      _composer.clear();
      _drafts.remove(conversation.id);
      _saveDraft(conversation.id);
      setState(() => _replyingTo = null);
      await _loadMessages(conversation);
      _scrollToEnd();
      _refresh(silent: true);
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _shareWorkerHours() async {
    final conversation = _selected;
    if (_sending || conversation == null) return;
    final document = await showTelegramWorkerDocumentPickerDialog(
      context,
      groupId: widget.groupId,
    );
    if (!mounted || document == null) return;
    setState(() => _sending = true);
    try {
      await _api.sendAttachment(
        widget.groupId,
        conversation.id,
        PlatformFile(
          name: document.fileName,
          size: document.bytes.length,
          bytes: document.bytes,
        ),
        _composer.text.trim(),
        replyToMessageId: _replyingTo?.id,
        businessRecord: {
          'type': 'timesheet',
          'id': document.workerId,
          'workerId': document.workerId,
          'label': document.documentLabel,
        },
      );
      if (!mounted) return;
      _composer.clear();
      _drafts.remove(conversation.id);
      _saveDraft(conversation.id);
      setState(() => _replyingTo = null);
      await _loadMessages(conversation);
      _scrollToEnd();
      _refresh(silent: true);
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _shareExpense() async {
    final conversation = _selected;
    if (_sending || conversation == null) return;
    final expense = await showBusinessChatExpensePicker(
      context,
      groupId: widget.groupId,
    );
    if (!mounted || expense == null) return;
    setState(() => _sending = true);
    try {
      await _api.sendAttachment(
        widget.groupId,
        conversation.id,
        PlatformFile(
          name: expense.fileName,
          size: expense.bytes.length,
          bytes: expense.bytes,
        ),
        _composer.text.trim(),
        replyToMessageId: _replyingTo?.id,
        businessRecord: {
          'type': 'expense',
          'id': expense.id,
          'label': expense.label,
        },
      );
      if (!mounted) return;
      _composer.clear();
      _drafts.remove(conversation.id);
      _saveDraft(conversation.id);
      setState(() => _replyingTo = null);
      await _loadMessages(conversation);
      _scrollToEnd();
      _refresh(silent: true);
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _configureChannelActions(
      BusinessChatConversation conversation) async {
    var type = conversation.channelType;
    final selected = <BusinessChatComposerAction>{
      ...conversation.composerActions
    };
    final result = await showDialog<
        ({
          BusinessChatChannelType type,
          Set<BusinessChatComposerAction> actions
        })>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(_es ? 'Acciones del canal' : 'Channel actions'),
          content: SizedBox(
            width: 420,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<BusinessChatChannelType>(
                initialValue: type,
                decoration: InputDecoration(
                    labelText: _es ? 'Tipo de canal' : 'Channel type'),
                items: BusinessChatChannelType.values
                    .map((value) => DropdownMenuItem(
                          value: value,
                          child: Text(value.name),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setDialogState(() => type = value);
                },
              ),
              const SizedBox(height: 8),
              for (final action in BusinessChatComposerAction.values)
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: action == BusinessChatComposerAction.attachFile ||
                      selected.contains(action),
                  enabled: action != BusinessChatComposerAction.attachFile,
                  title: Text(_composerActionLabel(action)),
                  onChanged: (checked) => setDialogState(() {
                    if (checked == true) {
                      selected.add(action);
                    } else {
                      selected.remove(action);
                    }
                  }),
                ),
            ]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(_es ? 'Cancelar' : 'Cancel'),
            ),
            FilledButton(
              onPressed: () {
                selected.add(BusinessChatComposerAction.attachFile);
                Navigator.pop(dialogContext, (type: type, actions: selected));
              },
              child: Text(_es ? 'Guardar' : 'Save'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || result == null) return;
    try {
      await _api.updateChannelConfiguration(
        widget.groupId,
        conversation.id,
        channelType: result.type,
        allowedActions: result.actions,
      );
      await _refresh(silent: true);
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  String _composerActionLabel(BusinessChatComposerAction action) =>
      switch (action) {
        BusinessChatComposerAction.attachFile =>
          _es ? 'Adjuntar archivos' : 'Attach files',
        BusinessChatComposerAction.image => _es ? 'Imágenes' : 'Images',
        BusinessChatComposerAction.link => _es ? 'Enlaces' : 'Links',
        BusinessChatComposerAction.invoice => _es ? 'Facturas' : 'Invoices',
        BusinessChatComposerAction.receipt => _es ? 'Recibos' : 'Receipts',
        BusinessChatComposerAction.expense => _es ? 'Gastos' : 'Expenses',
        BusinessChatComposerAction.quote => _es ? 'Presupuestos' : 'Quotes',
        BusinessChatComposerAction.timesheet =>
          _es ? 'Horas de trabajadores' : 'Worker hours',
        BusinessChatComposerAction.bankTransaction =>
          _es ? 'Movimientos bancarios' : 'Bank transactions',
      };

  void _insertLink() {
    final current = _composer.text;
    final separator = current.isEmpty || current.endsWith(' ') ? '' : ' ';
    final next = '$current${separator}https://';
    _composer.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
    _composerFocus.requestFocus();
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
                        TextButton.icon(
                            onPressed: () async {
                              Navigator.pop(dialogContext);
                              await _configureChannelActions(conversation);
                            },
                            icon: const Icon(Icons.tune, size: 18),
                            label: Text(_es ? 'Acciones' : 'Actions')),
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

  Widget _composerAction({
    required IconData icon,
    required String label,
    required String tooltip,
    required VoidCallback? onPressed,
  }) =>
      HexoraButton(
        onPressed: onPressed,
        icon: icon,
        label: label,
        tooltip: tooltip,
        variant: HexoraButtonVariant.ghost,
        size: HexoraButtonSize.compact,
      );

  Widget _businessRecordCard(BusinessChatMessage message) {
    final record = message.businessRecord!;
    final type = (record['type'] ?? '').toString();
    final label = (record['label'] ?? '').toString().trim();
    final icon = switch (type) {
      'invoice' => Icons.receipt_long_outlined,
      'receipt' => Icons.receipt_outlined,
      'presupuesto' || 'quote' => Icons.request_quote_outlined,
      'expense' => Icons.payments_outlined,
      'timesheet' => Icons.schedule_outlined,
      _ => Icons.description_outlined,
    };
    final typeLabel = switch (type) {
      'invoice' => _es ? 'Factura' : 'Invoice',
      'receipt' => _es ? 'Recibo' : 'Receipt',
      'presupuesto' || 'quote' => _es ? 'Presupuesto' : 'Quote',
      'expense' => _es ? 'Gasto' : 'Expense',
      'timesheet' => _es ? 'Horas de trabajador' : 'Worker hours',
      _ => _es ? 'Documento' : 'Document',
    };
    return Card.outlined(
      margin: const EdgeInsets.only(top: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap:
            message.attachment == null ? null : () => _openAttachment(message),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(typeLabel,
                      style: Theme.of(context).textTheme.labelSmall),
                  Text(
                    label.isEmpty ? typeLabel : label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            if (message.attachment != null)
              const Icon(Icons.open_in_new, size: 17),
          ]),
        ),
      ),
    );
  }

  List<Widget> _buildComposerActions() {
    final conversation = _selected;
    if (conversation == null) return const [];
    final actions = conversation.composerActions;
    final enabled = !_sending;
    final widgets = <Widget>[
      _composerAction(
        icon: Icons.attach_file,
        label: _es ? 'Archivo' : 'File',
        tooltip: _es ? 'Adjuntar archivo' : 'Attach file',
        onPressed: enabled ? () => _attach() : null,
      ),
    ];
    if (actions.contains(BusinessChatComposerAction.image)) {
      widgets.add(_composerAction(
        icon: Icons.image_outlined,
        label: _es ? 'Imagen' : 'Image',
        tooltip: _es ? 'Adjuntar imagen' : 'Attach image',
        onPressed: enabled ? () => _attach(imagesOnly: true) : null,
      ));
    }
    if (actions.contains(BusinessChatComposerAction.invoice) ||
        actions.contains(BusinessChatComposerAction.receipt)) {
      final hasInvoices = actions.contains(BusinessChatComposerAction.invoice);
      final hasReceipts = actions.contains(BusinessChatComposerAction.receipt);
      final kinds = <String>{
        if (hasInvoices) ClientDocumentKinds.invoice,
        if (hasReceipts) ClientDocumentKinds.receipt,
      };
      widgets.add(_composerAction(
        icon:
            hasInvoices ? Icons.receipt_long_outlined : Icons.receipt_outlined,
        label: hasInvoices && hasReceipts
            ? (_es ? 'Facturas y recibos' : 'Invoices & receipts')
            : hasInvoices
                ? (_es ? 'Facturas' : 'Invoices')
                : (_es ? 'Recibos' : 'Receipts'),
        tooltip: hasInvoices && hasReceipts
            ? (_es
                ? 'Compartir una factura o un recibo existente'
                : 'Share an existing invoice or receipt')
            : hasInvoices
                ? (_es
                    ? 'Compartir una factura existente'
                    : 'Share an existing invoice')
                : (_es
                    ? 'Compartir un recibo existente'
                    : 'Share an existing receipt'),
        onPressed: enabled ? () => _shareClientDocuments(kinds) : null,
      ));
    }
    if (actions.contains(BusinessChatComposerAction.quote)) {
      widgets.add(_composerAction(
        icon: Icons.request_quote_outlined,
        label: _es ? 'Presupuesto' : 'Quote',
        tooltip: _es
            ? 'Compartir un presupuesto existente'
            : 'Share an existing quote',
        onPressed: enabled
            ? () => _shareClientDocuments({ClientDocumentKinds.quote})
            : null,
      ));
    }
    if (actions.contains(BusinessChatComposerAction.expense)) {
      widgets.add(_composerAction(
        icon: Icons.payments_outlined,
        label: _es ? 'Gasto' : 'Expense',
        tooltip:
            _es ? 'Compartir un gasto existente' : 'Share an existing expense',
        onPressed: enabled ? _shareExpense : null,
      ));
    }
    if (actions.contains(BusinessChatComposerAction.timesheet)) {
      widgets.add(_composerAction(
        icon: Icons.schedule_outlined,
        label: _es ? 'Horas' : 'Hours',
        tooltip:
            _es ? 'Compartir horas de un trabajador' : 'Share worker hours',
        onPressed: enabled ? _shareWorkerHours : null,
      ));
    }
    if (actions.contains(BusinessChatComposerAction.link)) {
      widgets.add(_composerAction(
        icon: Icons.link,
        label: _es ? 'Enlace' : 'Link',
        tooltip: _es ? 'Insertar enlace' : 'Insert link',
        onPressed: enabled ? _insertLink : null,
      ));
    }
    if (_canShareBankTransactions && conversation.canShareBankTransaction) {
      widgets.add(_composerAction(
        icon: Icons.account_balance_outlined,
        label: _es ? 'Movimiento' : 'Transaction',
        tooltip:
            _es ? 'Compartir movimiento bancario' : 'Share bank transaction',
        onPressed: enabled ? _shareBankTransactionFromChat : null,
      ));
      widgets.add(_composerAction(
        icon: Icons.rate_review_outlined,
        label: _es ? 'Pedir revisión' : 'Request review',
        tooltip: _es
            ? 'Compartir un movimiento para revisar su vínculo'
            : 'Share a transaction to review its link',
        onPressed: enabled
            ? () => _shareBankTransactionFromChat(requestReview: true)
            : null,
      ));
    }
    return widgets;
  }

  Widget _buildChatMenuHeader(
    ColorScheme colors, {
    required bool dark,
    bool showTitle = true,
  }) {
    final foreground =
        dark ? HexoraGlobalNavColors.foreground : colors.onSurfaceVariant;
    final unread = _conversations.fold<int>(
        0, (sum, conversation) => sum + conversation.unreadCount);
    final buttonStyle = IconButton.styleFrom(
      foregroundColor: foreground,
      minimumSize: const Size.square(36),
      fixedSize: const Size.square(36),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (showTitle) ...[
          Row(children: [
            Badge(
                isLabelVisible: unread > 0,
                label: Text('$unread'),
                child: Icon(Icons.forum_outlined, color: foreground)),
            const SizedBox(width: 10),
            Expanded(
                child: Text('Hexora Chat',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: foreground, fontWeight: FontWeight.w700))),
          ]),
          const SizedBox(height: 6),
        ],
        Wrap(
            alignment: WrapAlignment.end,
            spacing: 2,
            runSpacing: 2,
            children: [
              Tooltip(
                  message: _liveConnected
                      ? (_es ? 'Actualizaciones en directo' : 'Live updates')
                      : (_es
                          ? 'Sin conexión en directo; se actualiza cada minuto'
                          : 'Live connection unavailable; checks every minute'),
                  child: SizedBox.square(
                      dimension: 36,
                      child: Icon(_liveConnected ? Icons.wifi : Icons.wifi_off,
                          size: 18,
                          color: _liveConnected
                              ? (dark ? Colors.white : colors.primary)
                              : foreground.withValues(alpha: 0.58)))),
              IconButton(
                  style: buttonStyle,
                  onPressed: _loading ? null : _refresh,
                  tooltip: _es ? 'Actualizar' : 'Refresh',
                  icon: const Icon(Icons.refresh, size: 19)),
              IconButton(
                  style: buttonStyle,
                  onPressed: _showMemberPresence,
                  tooltip: _es
                      ? 'Ver miembros y conexión'
                      : 'View members and presence',
                  icon: const Icon(Icons.people_alt_outlined, size: 19)),
              if (_canShareBankTransactions)
                IconButton(
                    style: buttonStyle,
                    onPressed: () =>
                        _shareBankTransactionFromChat(requestReview: true),
                    tooltip: _es
                        ? 'Pedir revisión de un movimiento bancario'
                        : 'Request bank transaction review',
                    icon: const Icon(Icons.account_balance_outlined, size: 19)),
              if (_canCreateIssues)
                IconButton(
                    style: buttonStyle,
                    onPressed: _createIssue,
                    tooltip: _es ? 'Nueva incidencia' : 'New incident',
                    icon: const Icon(Icons.report_gmailerrorred_outlined,
                        size: 19)),
              if (_canCreateTeam)
                IconButton(
                    style: buttonStyle,
                    onPressed: _createTeam,
                    tooltip: _es ? 'Nuevo chat de equipo' : 'New team chat',
                    icon: const Icon(Icons.group_add_outlined, size: 19)),
            ]),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
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
    const menuForeground = HexoraGlobalNavColors.foreground;
    return LayoutBuilder(builder: (context, constraints) {
      final narrow = constraints.maxWidth < 700;
      return Row(children: [
        if (!narrow || !_showChatOnNarrow)
          SizedBox(
            width: narrow ? constraints.maxWidth : null,
            child: CollapsibleSidebarShell(
                title: 'Hexora Chat',
                collapsed: !narrow && _menuCollapsed,
                drawer: narrow,
                onToggleCollapsed: narrow
                    ? null
                    : () => setState(() => _menuCollapsed = !_menuCollapsed),
                secondaryHeader: false,
                expandTooltip: _es ? 'Expandir menú' : 'Expand menu',
                collapseTooltip: _es ? 'Contraer menú' : 'Collapse menu',
                builder: (navigationContext, layoutCollapsed) =>
                    Column(children: [
                      if (!layoutCollapsed)
                        _buildChatMenuHeader(
                            Theme.of(navigationContext).colorScheme,
                            dark: true,
                            showTitle: narrow),
                      if (!layoutCollapsed)
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: TextField(
                            controller: _conversationSearch,
                            onChanged: (_) => setState(() {}),
                            style: const TextStyle(color: menuForeground),
                            decoration: InputDecoration(
                              isDense: true,
                              filled: true,
                              fillColor: menuForeground.withValues(alpha: 0.08),
                              prefixIcon: const Icon(Icons.search),
                              prefixIconColor:
                                  menuForeground.withValues(alpha: 0.72),
                              suffixIconColor:
                                  menuForeground.withValues(alpha: 0.72),
                              hintText: _es
                                  ? 'Buscar conversaciones'
                                  : 'Search conversations',
                              hintStyle: TextStyle(
                                  color:
                                      menuForeground.withValues(alpha: 0.64)),
                              suffixIcon: query.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: _es
                                          ? 'Borrar búsqueda'
                                          : 'Clear search',
                                      icon: const Icon(Icons.close),
                                      onPressed: () =>
                                          setState(_conversationSearch.clear),
                                    ),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(9),
                                  borderSide: BorderSide(
                                      color: menuForeground.withValues(
                                          alpha: 0.16))),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(9),
                                  borderSide: const BorderSide(
                                      color: HexoraGlobalNavColors.active)),
                            ),
                          ),
                        ),
                      Expanded(
                          child: visibleConversations.isEmpty
                              ? Center(
                                  child: _loading
                                      ? const CircularProgressIndicator()
                                      : Padding(
                                          padding: const EdgeInsets.all(20),
                                          child: Text(
                                              _error ??
                                                  (query.isNotEmpty
                                                      ? (_es
                                                          ? 'Sin resultados'
                                                          : 'No results')
                                                      : (_es
                                                          ? 'No hay conversaciones'
                                                          : 'No conversations')),
                                              textAlign: TextAlign.center)))
                              : ListView.builder(
                                  itemCount: visibleConversations.length,
                                  itemBuilder: (context, index) {
                                    final conversation =
                                        visibleConversations[index];
                                    final selected =
                                        _selected?.id == conversation.id;
                                    final status =
                                        conversation.issue?['status'];
                                    final lastMessage =
                                        conversation.lastMessage;
                                    final preview = lastMessage == null
                                        ? (status == null
                                            ? _typeLabel(conversation.type)
                                            : _statusLabel(status.toString()))
                                        : lastMessage.isDeleted
                                            ? (_es
                                                ? 'Mensaje eliminado'
                                                : 'Message deleted')
                                            : lastMessage.bankTransaction !=
                                                    null
                                                ? (_es
                                                    ? 'Movimiento bancario compartido'
                                                    : 'Shared bank transaction')
                                                : lastMessage.body
                                                        .trim()
                                                        .isNotEmpty
                                                    ? lastMessage.body
                                                    : (lastMessage.attachment?[
                                                                'fileName'] ??
                                                            (_es
                                                                ? 'Archivo adjunto'
                                                                : 'Attachment'))
                                                        .toString();
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      child: SidebarItem(
                                        icon: conversation.type == 'issue'
                                            ? Icons.report_outlined
                                            : conversation.type == 'team'
                                                ? Icons.groups_outlined
                                                : Icons.campaign_outlined,
                                        label: conversation.issue?['title']
                                                ?.toString() ??
                                            conversation.title,
                                        subtitle:
                                            layoutCollapsed ? null : preview,
                                        isSelected: selected,
                                        collapsed: layoutCollapsed,
                                        count: conversation.unreadCount > 0
                                            ? conversation.unreadCount
                                            : null,
                                        trailing: conversation.muted
                                            ? const Icon(
                                                Icons
                                                    .notifications_off_outlined,
                                                size: 17)
                                            : null,
                                        onTap: () {
                                          final oldId = _selected?.id;
                                          setState(() {
                                            _selected = conversation;
                                            _messages = const [];
                                            _showChatOnNarrow = true;
                                          });
                                          _switchDraft(oldId, conversation.id);
                                          _loadMessages(conversation,
                                              forceScroll: true);
                                        },
                                      ),
                                    );
                                  })),
                    ])),
          ),
        if (!narrow || _showChatOnNarrow)
          Expanded(
              child: WorkspaceMainContent(
                  child: Column(children: [
            if (narrow) ...[
              _buildChatMenuHeader(colors, dark: false),
              const Divider(height: 1),
            ],
            if (_selected != null)
              Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  color: colors.surfaceContainerLow,
                  child: Row(children: [
                    if (narrow)
                      IconButton(
                          tooltip: _es ? 'Conversaciones' : 'Conversations',
                          onPressed: () =>
                              setState(() => _showChatOnNarrow = false),
                          icon: const Icon(Icons.arrow_back)),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(
                              _selected!.issue?['title']?.toString() ??
                                  _selected!.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          if (_selected!.type == 'issue')
                            Text(
                                _selected!.issue?['assigneeName'] == null
                                    ? (_es ? 'Sin asignar' : 'Unassigned')
                                    : '${_es ? 'Asignada a' : 'Assigned to'} ${_selected!.issue!['assigneeName']}',
                                style: Theme.of(context).textTheme.bodySmall),
                          if (_selected!.type == 'team' ||
                              _selected!.type == 'issue')
                            Text(
                                _es
                                    ? '${_selected!.participantIds.length} participantes'
                                    : '${_selected!.participantIds.length} participants',
                                style: Theme.of(context).textTheme.bodySmall),
                          if (_selected!.issue?['clientName'] != null ||
                              _selected!.issue?['eventTitle'] != null)
                            Text(
                                [
                                  _selected!.issue?['clientName'],
                                  _selected!.issue?['eventTitle']
                                ].whereType<String>().join(' · '),
                                style: Theme.of(context).textTheme.bodySmall)
                        ])),
                    if (!narrow) Text(_typeLabel(_selected!.type)),
                    IconButton(
                        tooltip: _es ? 'Buscar mensajes' : 'Search messages',
                        onPressed: _searchHistory,
                        icon: const Icon(Icons.search)),
                    if (_selected!.type == 'general')
                      IconButton(
                          tooltip: _es
                              ? 'Miembros de General (se gestionan en Miembros)'
                              : 'General members (managed in Business Members)',
                          onPressed: _showGeneralMembers,
                          icon: const Icon(Icons.groups_outlined)),
                    if ((_selected!.type == 'team' ||
                            _selected!.type == 'issue') &&
                        _selected!.canManageParticipants)
                      narrow
                          ? IconButton(
                              tooltip: _es
                                  ? 'Añadir o quitar participantes'
                                  : 'Add or remove participants',
                              onPressed: () => _manageParticipants(_selected!),
                              icon: const Icon(Icons.manage_accounts_outlined))
                          : TextButton.icon(
                              onPressed: () => _manageParticipants(_selected!),
                              icon: const Icon(Icons.manage_accounts_outlined),
                              label:
                                  Text(_es ? 'Participantes' : 'Participants')),
                    if (_selected!.type != 'general' &&
                        widget.currentUserId != null &&
                        _selected!.participantIds
                            .contains(widget.currentUserId))
                      IconButton(
                          tooltip: _es ? 'Salir del chat' : 'Leave chat',
                          onPressed: () => _leaveConversation(_selected!),
                          icon: const Icon(Icons.exit_to_app_outlined)),
                    if (_selected!.type == 'issue')
                      IconButton(
                          tooltip: _es ? 'Ver incidencia' : 'View incident',
                          onPressed: () => _showIssueDetails(_selected!),
                          icon: const Icon(Icons.info_outline)),
                    IconButton(
                        tooltip: _selected!.muted
                            ? (_es
                                ? 'Activar avisos de mensajes'
                                : 'Unmute messages')
                            : (_es
                                ? 'Silenciar avisos de mensajes'
                                : 'Mute messages'),
                        onPressed: () => _toggleMute(_selected!),
                        icon: Icon(_selected!.muted
                            ? Icons.notifications_off_outlined
                            : Icons.notifications_active_outlined)),
                    if (_selected!.issue?['status'] != null && _canAssignIssues)
                      IconButton(
                          tooltip:
                              _es ? 'Cambiar responsable' : 'Change assignee',
                          onPressed: () => _assignIssue(_selected!),
                          icon: const Icon(Icons.assignment_ind_outlined)),
                    if (_selected!.issue?['status'] != null)
                      Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _canManageIssues
                              ? DropdownButton<String>(
                                  value: _selected!.issue!['status'].toString(),
                                  items: [
                                    DropdownMenuItem(
                                        value: 'open',
                                        child: Text(_statusLabel('open'))),
                                    DropdownMenuItem(
                                        value: 'in_progress',
                                        child:
                                            Text(_statusLabel('in_progress'))),
                                    DropdownMenuItem(
                                        value: 'review',
                                        child: Text(_statusLabel('review'))),
                                    DropdownMenuItem(
                                        value: 'resolved',
                                        child: Text(_statusLabel('resolved'))),
                                    DropdownMenuItem(
                                        value: 'closed',
                                        child: Text(_statusLabel('closed')))
                                  ],
                                  onChanged: (value) {
                                    if (value != null) _setIssueStatus(value);
                                  })
                              : Chip(
                                  label: Text(_statusLabel(
                                      _selected!.issue!['status'].toString()))))
                  ])),
            Expanded(
                child: _error != null && _messages.isEmpty
                    ? Center(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                        Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(_error!, textAlign: TextAlign.center)),
                        TextButton(
                            onPressed: _refresh,
                            child: Text(_es ? 'Reintentar' : 'Retry'))
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
                            : ListView.builder(
                                controller: _scroll,
                                padding: const EdgeInsets.all(14),
                                itemCount: _messages.length +
                                    (_hasOlderMessages ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (_hasOlderMessages && index == 0) {
                                    return Center(
                                        child: TextButton.icon(
                                      onPressed: _loadingOlderMessages
                                          ? null
                                          : _loadOlderMessages,
                                      icon: _loadingOlderMessages
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2))
                                          : const Icon(Icons.history),
                                      label: Text(_es
                                          ? 'Cargar mensajes anteriores'
                                          : 'Load older messages'),
                                    ));
                                  }
                                  final message = _messages[
                                      index - (_hasOlderMessages ? 1 : 0)];
                                  final mine =
                                      message.senderId == widget.currentUserId;
                                  final canEdit = mine &&
                                      !message.isDeleted &&
                                      DateTime.now()
                                              .difference(
                                                  message.createdAt.toLocal())
                                              .inMinutes <
                                          15;
                                  final canDelete = !message.isDeleted &&
                                      (mine ||
                                          (_selected?.canModerateMessages ==
                                              true));
                                  return Align(
                                      alignment: mine
                                          ? Alignment.centerRight
                                          : Alignment.centerLeft,
                                      child: ConstrainedBox(
                                          constraints: const BoxConstraints(
                                              maxWidth: 520),
                                          child: Card(
                                              color: mine
                                                  ? colors.primaryContainer
                                                  : colors
                                                      .surfaceContainerHighest,
                                              child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(10),
                                                  child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Row(children: [
                                                          Expanded(
                                                              child: Text(
                                                                  message
                                                                      .senderName,
                                                                  style: const TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w700))),
                                                          if (!message
                                                              .isDeleted)
                                                            IconButton(
                                                                visualDensity:
                                                                    VisualDensity
                                                                        .compact,
                                                                tooltip: _es
                                                                    ? 'Responder a este mensaje'
                                                                    : 'Reply to this message',
                                                                onPressed: () =>
                                                                    setState(() =>
                                                                        _replyingTo =
                                                                            message),
                                                                icon: const Icon(
                                                                    Icons.reply,
                                                                    size: 18)),
                                                          if (canEdit ||
                                                              canDelete)
                                                            PopupMenuButton<
                                                                    String>(
                                                                onSelected: (value) =>
                                                                    _messageAction(
                                                                        message,
                                                                        value),
                                                                itemBuilder:
                                                                    (_) => [
                                                                          if (canEdit)
                                                                            PopupMenuItem(
                                                                                value: 'edit',
                                                                                child: Text(_es ? 'Editar' : 'Edit')),
                                                                          if (canDelete)
                                                                            PopupMenuItem(
                                                                                value: 'delete',
                                                                                child: Text(_es ? 'Eliminar' : 'Delete'))
                                                                        ])
                                                        ]),
                                                        if (message.replyTo !=
                                                            null)
                                                          Container(
                                                            width:
                                                                double.infinity,
                                                            margin:
                                                                const EdgeInsets
                                                                    .only(
                                                                    bottom: 6),
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(6),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: colors
                                                                  .surface
                                                                  .withValues(
                                                                      alpha:
                                                                          0.55),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          6),
                                                            ),
                                                            child: Text(
                                                              message.replyTo![
                                                                          'unavailable'] ==
                                                                      true
                                                                  ? (_es
                                                                      ? 'Mensaje original no disponible'
                                                                      : 'Original message unavailable')
                                                                  : '${message.replyTo!['senderName'] ?? ''}: ${message.replyTo!['body']?.toString().isNotEmpty == true ? message.replyTo!['body'] : (_es ? 'Adjunto o referencia' : 'Attachment or reference')}',
                                                              maxLines: 2,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style: Theme.of(
                                                                      context)
                                                                  .textTheme
                                                                  .labelSmall,
                                                            ),
                                                          ),
                                                        if (message.isDeleted ||
                                                            message.body
                                                                .isNotEmpty)
                                                          Text(message.isDeleted
                                                              ? (_es
                                                                  ? 'Mensaje eliminado'
                                                                  : 'Message deleted')
                                                              : message.body),
                                                        if (!message
                                                                .isDeleted &&
                                                            message.bankTransaction !=
                                                                null)
                                                          BankTransactionChatCard(
                                                            transaction: message
                                                                .bankTransaction!,
                                                            onOpen: () =>
                                                                _openBankTransaction(
                                                                    message
                                                                        .bankTransaction!),
                                                            onReview: () =>
                                                                _openBankTransaction(
                                                                    message
                                                                        .bankTransaction!,
                                                                    reviewLink:
                                                                        true),
                                                            onRequestReview:
                                                                () {
                                                              setState(() {
                                                                _replyingTo =
                                                                    message;
                                                                if (_composer
                                                                    .text
                                                                    .trim()
                                                                    .isEmpty) {
                                                                  _composer.text = _es
                                                                      ? '¿Podéis revisar este movimiento y confirmar si está vinculado correctamente?'
                                                                      : 'Could you review this transaction and confirm its link is correct?';
                                                                }
                                                              });
                                                            },
                                                            sharedBy: message
                                                                .senderName,
                                                            sharedAt: message
                                                                .createdAt,
                                                          ),
                                                        if (!message
                                                                .isDeleted &&
                                                            message.businessRecord !=
                                                                null)
                                                          _businessRecordCard(
                                                              message),
                                                        if (!message.isDeleted &&
                                                            message.attachment !=
                                                                null &&
                                                            message.businessRecord ==
                                                                null)
                                                          TextButton.icon(
                                                              onPressed: () =>
                                                                  _openAttachment(
                                                                      message),
                                                              icon: Icon((message.attachment!['mimeType'] ?? '')
                                                                      .toString()
                                                                      .startsWith(
                                                                          'image/')
                                                                  ? Icons
                                                                      .image_outlined
                                                                  : Icons
                                                                      .attach_file),
                                                              label: Text((message.attachment!['fileName'] ??
                                                                      (_es ? 'Adjunto' : 'Attachment'))
                                                                  .toString())),
                                                        Align(
                                                            alignment: Alignment
                                                                .centerRight,
                                                            child: Text(
                                                                '${DateFormat('HH:mm').format(message.createdAt.toLocal())}${message.editedAt != null ? (_es ? ' · Editado' : ' · Edited') : ''}',
                                                                style: Theme.of(
                                                                        context)
                                                                    .textTheme
                                                                    .labelSmall)),
                                                      ])))));
                                })),
            const Divider(height: 1),
            Padding(
                padding: const EdgeInsets.all(10),
                child: SafeArea(
                    top: false,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      if (_replyingTo != null)
                        Card(
                          child: ListTile(
                            dense: true,
                            leading: const Icon(Icons.reply),
                            title: Text(_es
                                ? 'Respondiendo a ${_replyingTo!.senderName}'
                                : 'Replying to ${_replyingTo!.senderName}'),
                            subtitle: Text(
                              _replyingTo!.body.isNotEmpty
                                  ? _replyingTo!.body
                                  : (_es
                                      ? 'Adjunto o referencia'
                                      : 'Attachment or reference'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: IconButton(
                              tooltip:
                                  _es ? 'Cancelar respuesta' : 'Cancel reply',
                              onPressed: () =>
                                  setState(() => _replyingTo = null),
                              icon: const Icon(Icons.close),
                            ),
                          ),
                        ),
                      if (_selected != null)
                        Builder(builder: (context) {
                          final actions = _buildComposerActions();
                          return SizedBox(
                            height: 38,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: actions.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 2),
                              itemBuilder: (_, index) => actions[index],
                            ),
                          );
                        }),
                      Row(children: [
                        Expanded(
                            child: TextField(
                                controller: _composer,
                                focusNode: _composerFocus,
                                enabled: _selected != null && !_sending,
                                maxLength: 2000,
                                minLines: 1,
                                maxLines: 4,
                                decoration: InputDecoration(
                                    hintText: _es
                                        ? 'Escribe un mensaje…'
                                        : 'Write a message…',
                                    counterText: '',
                                    border: const OutlineInputBorder()))),
                        const SizedBox(width: 8),
                        IconButton.filled(
                            onPressed:
                                _sending || _selected == null ? null : _send,
                            icon: _sending
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : const Icon(Icons.send))
                      ]),
                    ]))),
          ]))),
      ]);
    });
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
  String? _error;
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
    try {
      final members = await widget.api.memberPresence(widget.groupId);
      if (!mounted) return;
      setState(() {
        _members = members;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = widget.spanish
            ? 'No se pudo cargar la conexión de los miembros.'
            : 'Could not load member presence.';
      });
    }
  }

  String _lastSeen(DateTime? value) {
    if (value == null) {
      return widget.spanish
          ? 'Sin conexión anterior registrada'
          : 'No previous connection recorded';
    }
    final local = value.toLocal();
    return '${widget.spanish ? 'Última conexión' : 'Last seen'} · ${DateFormat('dd/MM/yyyy HH:mm').format(local)}';
  }

  @override
  Widget build(BuildContext context) {
    final online = _members.where((member) => member.isOnline).length;
    return AlertDialog(
      title: Row(children: [
        Expanded(
            child: Text(
                widget.spanish ? 'Miembros del negocio' : 'Business members')),
        IconButton(
          tooltip: widget.spanish ? 'Actualizar' : 'Refresh',
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh),
        ),
      ]),
      content: SizedBox(
        width: 420,
        height: 400,
        child: _loading && _members.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _error != null && _members.isEmpty
                ? Text(_error!)
                : Column(mainAxisSize: MainAxisSize.min, children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(widget.spanish
                            ? '$online en línea · ${_members.length} miembros'
                            : '$online online · ${_members.length} members'),
                      ),
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(_error!,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error)),
                      ),
                    Expanded(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _members.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final member = _members[index];
                          final photo = member.photoUrl;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundImage: photo == null || photo.isEmpty
                                  ? null
                                  : NetworkImage(photo),
                              child: photo == null || photo.isEmpty
                                  ? Text(member.name.isEmpty
                                      ? '?'
                                      : member.name[0].toUpperCase())
                                  : null,
                            ),
                            title: Text(member.name),
                            subtitle: Text(member.isOnline
                                ? (widget.spanish ? 'En línea' : 'Online')
                                : _lastSeen(member.lastActiveAt)),
                            trailing: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: member.isOnline
                                    ? Colors.green
                                    : Theme.of(context)
                                        .colorScheme
                                        .outlineVariant,
                                shape: BoxShape.circle,
                              ),
                            ),
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
