import 'package:flutter/foundation.dart';
import '../../../a-models/telegram/telegram.dart';
import '../api/telegram_api_client.dart';

/// Telegram domain manages connection state, chats, message history, and exports.
class TelegramComposerAttachment {
  const TelegramComposerAttachment({
    required this.fileName,
    required this.bytes,
    this.fileSize,
    this.mimeType,
  });

  final String fileName;
  final Uint8List bytes;
  final int? fileSize;
  final String? mimeType;

  bool get isPdf =>
      fileName.toLowerCase().endsWith('.pdf') ||
      (mimeType ?? '').toLowerCase().contains('pdf');
}

class TelegramDomain extends ChangeNotifier {
  TelegramDomain({required ITelegramApiClient apiClient})
      : _apiClient = apiClient;

  final ITelegramApiClient _apiClient;

  // ===== Connection State =====
  TelegramAccount? _account;
  bool _loadingAccount = false;
  String? _accountError;

  TelegramAccount? get account => _account;
  bool get isConnected => _account?.isActive ?? false;
  bool get loadingAccount => _loadingAccount;
  String? get accountError => _accountError;

  // ===== QR State =====
  TelegramConnectResponse? _qrResponse;
  bool _generatingQr = false;
  String? _qrError;

  TelegramConnectResponse? get qrResponse => _qrResponse;
  bool get generatingQr => _generatingQr;
  String? get qrError => _qrError;

  bool get qrIsExpired => _qrResponse?.qrIsExpired ?? false;

  // ===== Fallback Code State =====
  bool _submittingCode = false;
  String? _codeError;

  bool get submittingCode => _submittingCode;
  String? get codeError => _codeError;

  // ===== Chat List State =====
  List<TelegramChat> _chats = [];
  bool _loadingChats = false;
  String? _chatsError;
  String? _selectedChatId;
  String? _preferredExportChatId;
  Map<String, _TelegramForumTopicState>? _forumTopics;
  Map<String, String?>? _selectedForumTopicIds;

  List<TelegramChat> get chats => _chats;
  bool get loadingChats => _loadingChats;
  String? get chatsError => _chatsError;
  String? get selectedChatId => _selectedChatId;
  String? get preferredExportChatId => _preferredExportChatId;

  TelegramChat? get selectedChat {
    final chatId = _selectedChatId;
    if (chatId == null || chatId.isEmpty) return null;
    for (final chat in _chats) {
      if (chat.id == chatId) return chat;
    }
    final detail = _chatDetailsStore[chatId];
    if (detail != null) {
      return TelegramChat(
        id: detail.id,
        title: detail.title,
        description: detail.description,
        type: detail.type,
        photoPath: detail.photoPath,
        membersCount: detail.membersCount,
        lastMessageDate: detail.lastMessageDate,
        messageCount: detail.messageCount,
        isArchived: detail.isArchived,
        isMuted: detail.isMuted,
        forum: detail.forum,
      );
    }
    return null;
  }

  Map<String, _TelegramForumTopicState> get _forumTopicStore =>
      _forumTopics ??= <String, _TelegramForumTopicState>{};

  Map<String, String?> get _selectedForumTopicIdStore =>
      _selectedForumTopicIds ??= <String, String?>{};

  List<TelegramForumTopic> topicsForChat(String chatId) =>
      List<TelegramForumTopic>.unmodifiable(
        _forumTopicStore[chatId]?.topics ?? const <TelegramForumTopic>[],
      );

  bool isLoadingTopics(String chatId) =>
      _forumTopicStore[chatId]?.loading ?? false;

  String? topicsErrorForChat(String chatId) => _forumTopicStore[chatId]?.error;

  String? selectedTopicIdForChat(String chatId) {
    final topicId = _selectedForumTopicIdStore[chatId];
    if (topicId == null || topicId.trim().isEmpty) return null;
    return topicId;
  }

  TelegramForumTopic? selectedTopicForChat(String chatId) {
    final topicId = selectedTopicIdForChat(chatId);
    if (topicId == null) return null;
    final topics = _forumTopicStore[chatId]?.topics;
    if (topics == null) return null;
    for (final topic in topics) {
      if (topic.forumTopicId == topicId) {
        return topic;
      }
    }
    return null;
  }

  // ===== Chat Detail State =====
  Map<String, TelegramChatDetail>? _chatDetails;
  Map<String, _TelegramChatFeedState>? _messageFeeds;
  Map<String, _TelegramChatComposerState>? _composerStates;

  Map<String, TelegramChatDetail> get _chatDetailsStore =>
      _chatDetails ??= <String, TelegramChatDetail>{};

  Map<String, _TelegramChatFeedState> get _messageFeedsStore =>
      _messageFeeds ??= <String, _TelegramChatFeedState>{};

  Map<String, _TelegramChatComposerState> get _composerStatesStore =>
      _composerStates ??= <String, _TelegramChatComposerState>{};

  TelegramChatDetail? getChatDetail(String chatId) => _chatDetailsStore[chatId];

  List<TelegramChatMessage> messagesForChat(
    String chatId, {
    String? forumTopicId,
  }) {
    final feed = _messageFeedsStore[_threadKey(chatId,
        forumTopicId: _effectiveTopicId(chatId, forumTopicId))];
    if (feed == null) return const <TelegramChatMessage>[];
    return List<TelegramChatMessage>.unmodifiable(feed.messages);
  }

  bool isLoadingMessages(
    String chatId, {
    String? forumTopicId,
  }) =>
      _messageFeedsStore[_threadKey(
        chatId,
        forumTopicId: _effectiveTopicId(chatId, forumTopicId),
      )]
          ?.loadingInitial ??
      false;

  bool isLoadingOlderMessages(
    String chatId, {
    String? forumTopicId,
  }) =>
      _messageFeedsStore[_threadKey(
        chatId,
        forumTopicId: _effectiveTopicId(chatId, forumTopicId),
      )]
          ?.loadingOlder ??
      false;

  bool isPollingMessages(
    String chatId, {
    String? forumTopicId,
  }) =>
      _messageFeedsStore[_threadKey(
        chatId,
        forumTopicId: _effectiveTopicId(chatId, forumTopicId),
      )]
          ?.pollingNewer ??
      false;

  String? messageErrorForChat(
    String chatId, {
    String? forumTopicId,
  }) =>
      _messageFeedsStore[_threadKey(chatId,
              forumTopicId: _effectiveTopicId(chatId, forumTopicId))]
          ?.error;

  bool hasMoreHistory(
    String chatId, {
    String? forumTopicId,
  }) =>
      (_messageFeedsStore[_threadKey(
            chatId,
            forumTopicId: _effectiveTopicId(chatId, forumTopicId),
          )]
              ?.messages
              .isNotEmpty ??
          false) &&
      !(_messageFeedsStore[_threadKey(
            chatId,
            forumTopicId: _effectiveTopicId(chatId, forumTopicId),
          )]
              ?.historyExhausted ??
          false);

  String? oldestLoadedMessageId(
    String chatId, {
    String? forumTopicId,
  }) {
    final feed = _messageFeedsStore[_threadKey(chatId,
        forumTopicId: _effectiveTopicId(chatId, forumTopicId))];
    if (feed == null) return null;
    return feed.paging.beforeMessageId ??
        (feed.messages.isNotEmpty ? feed.messages.first.messageId : null);
  }

  String? latestLoadedMessageId(
    String chatId, {
    String? forumTopicId,
  }) {
    final feed = _messageFeedsStore[_threadKey(chatId,
        forumTopicId: _effectiveTopicId(chatId, forumTopicId))];
    if (feed == null) return null;
    return feed.paging.afterMessageId ??
        feed.paging.pollCursor ??
        (feed.messages.isNotEmpty ? feed.messages.last.messageId : null);
  }

  String draftForChat(
    String chatId, {
    String? forumTopicId,
  }) =>
      _composerStatesStore[_threadKey(
        chatId,
        forumTopicId: _effectiveTopicId(chatId, forumTopicId),
      )]
          ?.draftText ??
      '';

  bool isSendingMessage(
    String chatId, {
    String? forumTopicId,
  }) =>
      _composerStatesStore[_threadKey(
        chatId,
        forumTopicId: _effectiveTopicId(chatId, forumTopicId),
      )]
          ?.sending ??
      false;

  String? sendErrorForChat(
    String chatId, {
    String? forumTopicId,
  }) =>
      _composerStatesStore[_threadKey(chatId,
              forumTopicId: _effectiveTopicId(chatId, forumTopicId))]
          ?.error;

  TelegramChatMessage? replyTargetForChat(
    String chatId, {
    String? forumTopicId,
  }) =>
      _composerStatesStore[_threadKey(chatId,
              forumTopicId: _effectiveTopicId(chatId, forumTopicId))]
          ?.replyTarget;

  TelegramComposerAttachment? attachmentForChat(
    String chatId, {
    String? forumTopicId,
  }) =>
      _composerStatesStore[_threadKey(chatId,
              forumTopicId: _effectiveTopicId(chatId, forumTopicId))]
          ?.attachment;

  // ===== Export State =====
  TelegramExport? _currentExport;
  List<TelegramExport>? _exports;
  bool _creatingExport = false;
  String? _exportError;
  bool _pollingExport = false;

  TelegramExport? get currentExport => _currentExport;
  List<TelegramExport> get exports => _exports ??= <TelegramExport>[];
  bool get creatingExport => _creatingExport;
  String? get exportError => _exportError;
  bool get pollingExport => _pollingExport;

  // ===== Account Loading =====
  Future<void> loadAccount({bool force = false}) async {
    if (_loadingAccount && !force) return;

    _loadingAccount = true;
    _accountError = null;
    notifyListeners();

    try {
      _account = await _apiClient.getAccount();
      if (_account?.isActive ?? false) {
        _qrResponse = null;
        _qrError = null;
        _codeError = null;
      }
      _accountError = null;
    } catch (e) {
      _accountError = e.toString();
      _account = null;
      _selectedChatId = null;
    } finally {
      _loadingAccount = false;
      notifyListeners();
    }
  }

  // ===== QR Generation =====
  Future<void> generateQr({String? accountLabel}) async {
    if (_generatingQr) return;

    _generatingQr = true;
    _qrError = null;
    notifyListeners();

    try {
      _qrResponse = await _apiClient.startConnect(
        accountLabel: accountLabel,
      );
      if (_qrResponse?.account != null) {
        _account = _qrResponse!.account;
      }
      _qrError = null;
    } catch (e) {
      _qrError = e.toString();
      _qrResponse = null;
    } finally {
      _generatingQr = false;
      notifyListeners();
    }
  }

  /// Refresh expired QR (same account)
  Future<void> refreshQr() async {
    if (_qrResponse == null || _generatingQr) return;
    await generateQr();
  }

  // ===== Fallback Code Submission =====
  Future<void> submitCode(String code) async {
    if (_submittingCode || _qrResponse == null) return;

    _submittingCode = true;
    _codeError = null;
    notifyListeners();

    try {
      _account = await _apiClient.completeConnect(
        requestId: _qrResponse!.requestId,
        code: code,
      );
      _codeError = null;
      _qrResponse = null;
    } catch (e) {
      _codeError = e.toString();
    } finally {
      _submittingCode = false;
      notifyListeners();
    }
  }

  // ===== Chat Selection =====
  void selectChat(String? chatId) {
    final normalized =
        (chatId == null || chatId.trim().isEmpty) ? null : chatId.trim();
    if (_selectedChatId == normalized) return;
    _selectedChatId = normalized;
    if (normalized != null) {
      _preferredExportChatId = normalized;
    }
    notifyListeners();
  }

  void prefillExportForChat(String chatId) {
    final normalized = chatId.trim();
    if (normalized.isEmpty) return;
    _preferredExportChatId = normalized;
    notifyListeners();
  }

  void updateDraft(
    String chatId,
    String value, {
    String? forumTopicId,
  }) {
    final composer = _composerStateFor(chatId, forumTopicId: forumTopicId);
    if (composer.draftText == value) return;
    composer.draftText = value;
    notifyListeners();
  }

  void setReplyTarget(
    String chatId,
    TelegramChatMessage? message, {
    String? forumTopicId,
  }) {
    final composer = _composerStateFor(chatId, forumTopicId: forumTopicId);
    final nextId = message?.messageId;
    final currentId = composer.replyTarget?.messageId;
    if (nextId == currentId) return;
    composer.replyTarget = message;
    composer.error = null;
    notifyListeners();
  }

  void clearReplyTarget(
    String chatId, {
    String? forumTopicId,
  }) {
    final composer = _composerStatesStore[_threadKey(chatId,
        forumTopicId: _effectiveTopicId(chatId, forumTopicId))];
    if (composer?.replyTarget == null) return;
    composer!.replyTarget = null;
    notifyListeners();
  }

  void clearSendError(
    String chatId, {
    String? forumTopicId,
  }) {
    final composer = _composerStatesStore[_threadKey(chatId,
        forumTopicId: _effectiveTopicId(chatId, forumTopicId))];
    if (composer?.error == null) return;
    composer!.error = null;
    notifyListeners();
  }

  void setAttachment(
    String chatId,
    TelegramComposerAttachment? attachment, {
    String? forumTopicId,
  }) {
    final composer = _composerStateFor(chatId, forumTopicId: forumTopicId);
    final current = composer.attachment;
    final sameAttachment = current?.fileName == attachment?.fileName &&
        current?.fileSize == attachment?.fileSize &&
        current?.bytes.length == attachment?.bytes.length;
    if (sameAttachment) return;
    composer.attachment = attachment;
    composer.error = null;
    notifyListeners();
  }

  void clearAttachment(
    String chatId, {
    String? forumTopicId,
  }) {
    final composer = _composerStatesStore[_threadKey(chatId,
        forumTopicId: _effectiveTopicId(chatId, forumTopicId))];
    if (composer?.attachment == null) return;
    composer!.attachment = null;
    notifyListeners();
  }

  // ===== Chat Loading =====
  Future<void> loadChats({bool refresh = false}) async {
    if (_loadingChats || account == null) return;

    _loadingChats = true;
    _chatsError = null;
    notifyListeners();

    try {
      final loaded = await _apiClient.getChats(
        accountId: account!.id,
        refresh: refresh,
      );
      _chats = List<TelegramChat>.from(loaded);
      if (_selectedChatId != null &&
          !_chats.any((chat) => chat.id == _selectedChatId)) {
        _selectedChatId = null;
      }
      if (_preferredExportChatId != null &&
          !_chats.any((chat) => chat.id == _preferredExportChatId)) {
        _preferredExportChatId = null;
      }
      final validChatIds = _chats.map((chat) => chat.id).toSet();
      _forumTopicStore
          .removeWhere((chatId, _) => !validChatIds.contains(chatId));
      _selectedForumTopicIdStore
          .removeWhere((chatId, _) => !validChatIds.contains(chatId));
      _chatsError = null;
    } catch (e) {
      _chatsError = e.toString();
      _chats = [];
      _selectedChatId = null;
    } finally {
      _loadingChats = false;
      notifyListeners();
    }
  }

  // ===== Chat Detail Loading =====
  Future<void> loadChatDetail(String chatId, {bool force = false}) async {
    if (account == null) return;
    if (!force && _chatDetailsStore.containsKey(chatId)) {
      return;
    }

    try {
      final detail = await _apiClient.getChatDetail(
        chatId: chatId,
        accountId: account!.id,
      );
      _chatDetailsStore[chatId] = detail;
      notifyListeners();
    } catch (_) {
      // Silent fail for detail loads.
    }
  }

  Future<void> loadTopics(String chatId, {bool force = false}) async {
    if (account == null) return;
    final state = _topicStateFor(chatId);
    if (state.loading) return;
    if (!force && state.topics.isNotEmpty) {
      _ensureSelectedTopic(chatId, state.topics, notify: false);
      return;
    }

    final requestId = ++state.requestId;
    state.loading = true;
    state.error = null;
    notifyListeners();

    try {
      final response = await _apiClient.getChatTopics(
        chatId: chatId,
        accountId: account!.id,
      );
      if (requestId != state.requestId) return;

      state.topics = List<TelegramForumTopic>.from(response.topics);
      state.error = null;
      _ensureSelectedTopic(chatId, state.topics, notify: false);
    } catch (e) {
      if (requestId == state.requestId) {
        state.error = e.toString();
      }
    } finally {
      if (requestId == state.requestId) {
        state.loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> selectForumTopic(
    String chatId,
    String? forumTopicId, {
    bool forceMessages = false,
  }) async {
    final normalized = (forumTopicId == null || forumTopicId.trim().isEmpty)
        ? null
        : forumTopicId.trim();
    if (normalized == null) return;

    final current = selectedTopicIdForChat(chatId);
    if (current != normalized) {
      _selectedForumTopicIdStore[chatId] = normalized;
      notifyListeners();
    } else if (!forceMessages) {
      return;
    }

    await loadMessages(
      chatId,
      force: forceMessages,
      forumTopicId: normalized,
    );
  }

  Future<void> openChat(String chatId, {bool forceMessages = false}) async {
    selectChat(chatId);
    final chat = _chatById(chatId);
    if (chat?.isForumChat == true) {
      await loadTopics(chatId, force: forceMessages);
      final forumTopicId = selectedTopicIdForChat(chatId);
      if (forumTopicId != null) {
        await loadMessages(
          chatId,
          force: forceMessages,
          forumTopicId: forumTopicId,
        );
      }
    } else {
      await loadMessages(chatId, force: forceMessages);
    }
    await loadChatDetail(chatId);
  }

  // ===== Message Loading =====
  Future<int> loadMessages(
    String chatId, {
    bool force = false,
    int limit = 50,
    String? forumTopicId,
  }) async {
    if (account == null) return 0;
    final effectiveTopicId = _effectiveTopicId(chatId, forumTopicId);
    final feed = _feedFor(chatId, forumTopicId: effectiveTopicId);
    if (feed.loadingInitial) return 0;
    if (!force && feed.messages.isNotEmpty) return 0;

    final requestId = ++feed.initialRequestId;
    feed.loadingInitial = true;
    feed.error = null;
    notifyListeners();

    try {
      final response = await _apiClient.getChatMessages(
        chatId: chatId,
        accountId: account!.id,
        limit: limit,
        forumTopicId: effectiveTopicId,
      );
      if (requestId != feed.initialRequestId) return 0;

      var messages = _sortMessages(
        _filterMessagesForTopic(
          chatId,
          effectiveTopicId,
          response.messages,
        ),
      );
      var paging = _normalizePaging(
        response.paging,
        messages: messages,
      );
      var historyExhausted = messages.isEmpty;

      final initialBeforeMessageId = paging.beforeMessageId;
      if (messages.length <= 1 &&
          initialBeforeMessageId != null &&
          initialBeforeMessageId.isNotEmpty) {
        final olderResponse = await _apiClient.getChatMessages(
          chatId: chatId,
          accountId: account!.id,
          beforeMessageId: initialBeforeMessageId,
          limit: limit,
          forumTopicId: effectiveTopicId,
        );
        final filteredOlder = _filterMessagesForTopic(
          chatId,
          effectiveTopicId,
          olderResponse.messages,
        );
        final merged = _mergeMessages(messages, filteredOlder);
        final added = merged.length - messages.length;
        messages = merged;
        paging = TelegramChatMessagePaging(
          beforeMessageId: olderResponse.paging.beforeMessageId ??
              (messages.isNotEmpty ? messages.first.messageId : null),
          afterMessageId: paging.afterMessageId ??
              olderResponse.paging.afterMessageId ??
              (messages.isNotEmpty ? messages.last.messageId : null),
          hasMoreHistory: olderResponse.paging.hasMoreHistory,
          pollCursor: paging.pollCursor ??
              paging.afterMessageId ??
              olderResponse.paging.pollCursor ??
              olderResponse.paging.afterMessageId ??
              (messages.isNotEmpty ? messages.last.messageId : null),
        );
        historyExhausted = filteredOlder.isEmpty || added <= 0;
      }

      feed.messages = messages;
      feed.paging = paging;
      feed.historyExhausted = historyExhausted;
      feed.error = null;
      return feed.messages.length;
    } catch (e) {
      if (requestId == feed.initialRequestId) {
        feed.error = e.toString();
      }
      return 0;
    } finally {
      if (requestId == feed.initialRequestId) {
        feed.loadingInitial = false;
        notifyListeners();
      }
    }
  }

  Future<int> refreshMessages(
    String chatId, {
    int limit = 50,
    String? forumTopicId,
  }) async {
    return loadMessages(
      chatId,
      force: true,
      limit: limit,
      forumTopicId: forumTopicId,
    );
  }

  Future<int> loadOlderMessages(
    String chatId, {
    int limit = 50,
    String? forumTopicId,
  }) async {
    if (account == null) return 0;
    final effectiveTopicId = _effectiveTopicId(chatId, forumTopicId);
    final feed = _feedFor(chatId, forumTopicId: effectiveTopicId);
    if (feed.loadingInitial || feed.loadingOlder) return 0;
    if (feed.historyExhausted) return 0;

    final beforeMessageId = oldestLoadedMessageId(
      chatId,
      forumTopicId: effectiveTopicId,
    );
    if (beforeMessageId == null || beforeMessageId.isEmpty) return 0;

    final requestId = ++feed.olderRequestId;
    feed.loadingOlder = true;
    feed.error = null;
    notifyListeners();

    try {
      final response = await _apiClient.getChatMessages(
        chatId: chatId,
        accountId: account!.id,
        beforeMessageId: beforeMessageId,
        limit: limit,
        forumTopicId: effectiveTopicId,
      );
      if (requestId != feed.olderRequestId) return 0;

      final beforeIds =
          feed.messages.map((message) => message.messageId).toSet();
      final filteredIncoming = _filterMessagesForTopic(
        chatId,
        effectiveTopicId,
        response.messages,
      );
      final merged = _mergeMessages(feed.messages, filteredIncoming);
      final added = merged
          .where((message) => !beforeIds.contains(message.messageId))
          .length;

      feed.messages = merged;
      feed.paging = TelegramChatMessagePaging(
        beforeMessageId: response.paging.beforeMessageId ??
            (merged.isNotEmpty ? merged.first.messageId : null),
        afterMessageId: feed.paging.afterMessageId ??
            response.paging.afterMessageId ??
            (merged.isNotEmpty ? merged.last.messageId : null),
        hasMoreHistory: response.paging.hasMoreHistory,
        pollCursor: feed.paging.pollCursor ??
            feed.paging.afterMessageId ??
            response.paging.pollCursor ??
            response.paging.afterMessageId ??
            (merged.isNotEmpty ? merged.last.messageId : null),
      );
      feed.historyExhausted = filteredIncoming.isEmpty || added <= 0;
      feed.error = null;
      return added;
    } catch (e) {
      if (requestId == feed.olderRequestId) {
        feed.error = e.toString();
      }
      return 0;
    } finally {
      if (requestId == feed.olderRequestId) {
        feed.loadingOlder = false;
        notifyListeners();
      }
    }
  }

  Future<int> pollNewMessages(
    String chatId, {
    int limit = 50,
    String? forumTopicId,
  }) async {
    if (account == null) return 0;
    final effectiveTopicId = _effectiveTopicId(chatId, forumTopicId);
    final feed = _feedFor(chatId, forumTopicId: effectiveTopicId);
    if (feed.loadingInitial || feed.pollingNewer) return 0;

    final afterMessageId = latestLoadedMessageId(
      chatId,
      forumTopicId: effectiveTopicId,
    );
    if (afterMessageId == null || afterMessageId.isEmpty) return 0;

    final requestId = ++feed.pollRequestId;
    feed.pollingNewer = true;
    notifyListeners();

    try {
      final response = await _apiClient.getChatMessages(
        chatId: chatId,
        accountId: account!.id,
        afterMessageId: afterMessageId,
        limit: limit,
        forumTopicId: effectiveTopicId,
      );
      if (requestId != feed.pollRequestId) return 0;

      final beforeIds =
          feed.messages.map((message) => message.messageId).toSet();
      final filteredIncoming = _filterMessagesForTopic(
        chatId,
        effectiveTopicId,
        response.messages,
      );
      final merged = _mergeMessages(feed.messages, filteredIncoming);
      final added = merged
          .where((message) => !beforeIds.contains(message.messageId))
          .length;

      feed.messages = merged;
      feed.paging = TelegramChatMessagePaging(
        beforeMessageId: feed.paging.beforeMessageId ??
            response.paging.beforeMessageId ??
            (merged.isNotEmpty ? merged.first.messageId : null),
        afterMessageId: response.paging.afterMessageId ??
            response.paging.pollCursor ??
            (merged.isNotEmpty ? merged.last.messageId : null),
        hasMoreHistory: feed.paging.hasMoreHistory,
        pollCursor: response.paging.pollCursor ??
            response.paging.afterMessageId ??
            (merged.isNotEmpty ? merged.last.messageId : null),
      );
      feed.error = null;
      return added;
    } catch (e) {
      if (requestId == feed.pollRequestId) {
        feed.error = e.toString();
      }
      return 0;
    } finally {
      if (requestId == feed.pollRequestId) {
        feed.pollingNewer = false;
        notifyListeners();
      }
    }
  }

  Future<TelegramChatMessage?> sendMessage(
    String chatId, {
    String? text,
    String? forumTopicId,
  }) async {
    if (account == null || !isConnected) return null;

    final effectiveTopicId = _effectiveTopicId(chatId, forumTopicId);
    final isForumChat = _chatById(chatId)?.isForumChat == true;
    final composer = _composerStateFor(
      chatId,
      forumTopicId: effectiveTopicId,
    );
    final payloadText = (text ?? composer.draftText).trim();
    final attachment = composer.attachment;
    if ((payloadText.isEmpty && attachment == null) || composer.sending) {
      return null;
    }
    if (isForumChat && (effectiveTopicId == null || effectiveTopicId.isEmpty)) {
      composer.error = 'Select a topic to send a message.';
      notifyListeners();
      return null;
    }

    composer.sending = true;
    composer.error = null;
    notifyListeners();

    final replyTarget = composer.replyTarget;

    try {
      final sentMessage = attachment == null
          ? await _apiClient.sendChatMessage(
              chatId: chatId,
              accountId: account!.id,
              text: payloadText,
              replyToMessageId: replyTarget?.messageId,
              forumTopicId: effectiveTopicId,
            )
          : await _apiClient.sendChatDocument(
              chatId: chatId,
              accountId: account!.id,
              fileBytes: attachment.bytes,
              fileName: attachment.fileName,
              caption: payloadText.isEmpty ? null : payloadText,
              replyToMessageId: replyTarget?.messageId,
              mimeType: attachment.mimeType,
              forumTopicId: effectiveTopicId,
            );

      final hydrated = _hydrateSentMessage(
        sentMessage,
        replyTarget: replyTarget,
        forumTopicId: effectiveTopicId,
      );

      final feed = _feedFor(chatId, forumTopicId: effectiveTopicId);
      final merged = _mergeMessages(feed.messages, <TelegramChatMessage>[
        hydrated,
      ]);
      feed.messages = merged;
      feed.paging = TelegramChatMessagePaging(
        beforeMessageId: feed.paging.beforeMessageId ??
            (merged.isNotEmpty ? merged.first.messageId : hydrated.messageId),
        afterMessageId:
            merged.isNotEmpty ? merged.last.messageId : hydrated.messageId,
        hasMoreHistory: feed.paging.hasMoreHistory,
        pollCursor:
            merged.isNotEmpty ? merged.last.messageId : hydrated.messageId,
      );
      _touchChat(
        chatId,
        timestamp: hydrated.timestamp,
      );

      composer.draftText = '';
      composer.replyTarget = null;
      composer.attachment = null;
      composer.error = null;
      return hydrated;
    } catch (e) {
      composer.error = e.toString();
      return null;
    } finally {
      composer.sending = false;
      notifyListeners();
    }
  }

  // ===== Export Creation =====
  Future<void> createExport(TelegramExportRequest request) async {
    if (_creatingExport) return;

    _creatingExport = true;
    _exportError = null;
    notifyListeners();

    try {
      _currentExport = await _apiClient.createExport(request: request);
      _preferredExportChatId = request.chatId;
      _exportError = null;
    } catch (e) {
      _exportError = e.toString();
      _currentExport = null;
    } finally {
      _creatingExport = false;
      notifyListeners();
    }
  }

  // ===== Export Polling =====
  Future<void> pollExportStatus(String exportId) async {
    if (_pollingExport) return;

    _pollingExport = true;
    try {
      _currentExport = await _apiClient.getExportStatus(exportId);
      notifyListeners();
    } catch (e) {
      _exportError = e.toString();
    } finally {
      _pollingExport = false;
    }
  }

  // ===== Export Cancellation =====
  Future<void> cancelExport(String exportId) async {
    try {
      await _apiClient.cancelExport(exportId);
      _currentExport = null;
      notifyListeners();
    } catch (e) {
      _exportError = e.toString();
      notifyListeners();
    }
  }

  // ===== Disconnect =====
  Future<void> disconnect() async {
    try {
      await _apiClient.disconnectAccount();
      _account = null;
      _qrResponse = null;
      _chats = [];
      _selectedChatId = null;
      _preferredExportChatId = null;
      _currentExport = null;
      _chatDetailsStore.clear();
      _messageFeedsStore.clear();
      _composerStatesStore.clear();
      _forumTopicStore.clear();
      _selectedForumTopicIdStore.clear();
      notifyListeners();
    } catch (e) {
      _accountError = e.toString();
      notifyListeners();
    }
  }

  // ===== Reset State =====
  void resetQrError() {
    _qrError = null;
    notifyListeners();
  }

  void resetCodeError() {
    _codeError = null;
    notifyListeners();
  }

  void resetExportError() {
    _exportError = null;
    notifyListeners();
  }

  _TelegramChatComposerState _composerStateFor(
    String chatId, {
    String? forumTopicId,
  }) {
    return _composerStatesStore.putIfAbsent(
      _threadKey(
        chatId,
        forumTopicId: _effectiveTopicId(chatId, forumTopicId),
      ),
      _TelegramChatComposerState.new,
    );
  }

  _TelegramChatFeedState _feedFor(
    String chatId, {
    String? forumTopicId,
  }) {
    return _messageFeedsStore.putIfAbsent(
      _threadKey(chatId, forumTopicId: forumTopicId),
      _TelegramChatFeedState.new,
    );
  }

  _TelegramForumTopicState _topicStateFor(String chatId) {
    return _forumTopicStore.putIfAbsent(
      chatId,
      _TelegramForumTopicState.new,
    );
  }

  TelegramChat? _chatById(String chatId) {
    for (final chat in _chats) {
      if (chat.id == chatId) return chat;
    }
    final detail = _chatDetailsStore[chatId];
    if (detail == null) return null;
    return TelegramChat(
      id: detail.id,
      title: detail.title,
      description: detail.description,
      type: detail.type,
      photoPath: detail.photoPath,
      membersCount: detail.membersCount,
      lastMessageDate: detail.lastMessageDate,
      messageCount: detail.messageCount,
      isArchived: detail.isArchived,
      isMuted: detail.isMuted,
      forum: detail.forum,
    );
  }

  String? _effectiveTopicId(String chatId, String? forumTopicId) {
    final normalized = (forumTopicId == null || forumTopicId.trim().isEmpty)
        ? null
        : forumTopicId.trim();
    return normalized ?? selectedTopicIdForChat(chatId);
  }

  String _threadKey(String chatId, {String? forumTopicId}) {
    final normalized = (forumTopicId == null || forumTopicId.trim().isEmpty)
        ? null
        : forumTopicId.trim();
    if (normalized == null) return 'chat:$chatId';
    return 'chat:$chatId:topic:$normalized';
  }

  void _ensureSelectedTopic(
    String chatId,
    List<TelegramForumTopic> topics, {
    bool notify = true,
  }) {
    String? nextId;
    final current = selectedTopicIdForChat(chatId);
    if (current != null &&
        topics.any((topic) => topic.forumTopicId == current)) {
      nextId = current;
    } else {
      for (final topic in topics) {
        if (topic.isGeneral) {
          nextId = topic.forumTopicId;
          break;
        }
      }
      nextId ??= topics.isNotEmpty ? topics.first.forumTopicId : null;
    }

    if (_selectedForumTopicIdStore[chatId] == nextId) return;
    _selectedForumTopicIdStore[chatId] = nextId;
    if (notify) {
      notifyListeners();
    }
  }

  List<TelegramChatMessage> _filterMessagesForTopic(
    String chatId,
    String? forumTopicId,
    List<TelegramChatMessage> messages,
  ) {
    final normalizedTopicId = (forumTopicId ?? '').trim();
    if (normalizedTopicId.isEmpty) {
      return List<TelegramChatMessage>.from(messages);
    }

    var allowUntypedMessages = false;
    final topicState = _forumTopicStore[chatId];
    if (topicState != null) {
      for (final topic in topicState.topics) {
        if (topic.forumTopicId == normalizedTopicId) {
          allowUntypedMessages = topic.isGeneral;
          break;
        }
      }
    }

    return messages.where((message) {
      final messageTopicId = message.topic?.forumTopicId?.trim();
      if (message.isSystemThreadEvent) {
        return false;
      }
      if (messageTopicId == normalizedTopicId) {
        return true;
      }
      if (allowUntypedMessages &&
          (messageTopicId == null || messageTopicId.isEmpty)) {
        return true;
      }
      return false;
    }).toList();
  }

  TelegramChatMessage _hydrateSentMessage(
    TelegramChatMessage message, {
    TelegramChatMessage? replyTarget,
    String? forumTopicId,
  }) {
    final normalizedTopicId = (forumTopicId ?? '').trim();
    final topic = (message.topic?.forumTopicId?.trim().isNotEmpty ?? false) ||
            normalizedTopicId.isEmpty
        ? message.topic
        : TelegramChatMessageTopic(
            type: 'messageTopicForumTopic',
            forumTopicId: normalizedTopicId,
          );

    if (replyTarget == null && topic == message.topic) return message;
    if (replyTarget == null) {
      return TelegramChatMessage(
        messageId: message.messageId,
        timestamp: message.timestamp,
        editTimestamp: message.editTimestamp,
        sender: message.sender,
        text: message.text,
        caption: message.caption,
        topic: topic,
        replyTo: message.replyTo,
        forwardInfo: message.forwardInfo,
        messageType: message.messageType,
        media: message.media,
      );
    }

    final replyTo = message.replyTo;
    final hasReplyPreview =
        (replyTo?.displayName?.trim().isNotEmpty ?? false) ||
            (replyTo?.textPreview?.trim().isNotEmpty ?? false);
    if (hasReplyPreview) {
      return TelegramChatMessage(
        messageId: message.messageId,
        timestamp: message.timestamp,
        editTimestamp: message.editTimestamp,
        sender: message.sender,
        text: message.text,
        caption: message.caption,
        topic: topic,
        replyTo: message.replyTo,
        forwardInfo: message.forwardInfo,
        messageType: message.messageType,
        media: message.media,
      );
    }

    return TelegramChatMessage(
      messageId: message.messageId,
      timestamp: message.timestamp,
      editTimestamp: message.editTimestamp,
      sender: message.sender,
      text: message.text,
      caption: message.caption,
      topic: topic,
      replyTo: TelegramChatMessageReplyTo(
        messageId: replyTo?.messageId ?? replyTarget.messageId,
        displayName: replyTo?.displayName ??
            replyTarget.sender?.displayName ??
            replyTarget.sender?.username,
        textPreview: replyTo?.textPreview ?? replyTarget.previewText,
      ),
      forwardInfo: message.forwardInfo,
      messageType: message.messageType,
      media: message.media,
    );
  }

  List<TelegramChatMessage> _mergeMessages(
    List<TelegramChatMessage> current,
    List<TelegramChatMessage> incoming,
  ) {
    final byId = <String, TelegramChatMessage>{
      for (final message in current) message.messageId: message,
    };
    for (final message in incoming) {
      final duplicateKey = _findRecentDuplicateMessageKey(byId, message);
      if (duplicateKey != null && duplicateKey != message.messageId) {
        byId.remove(duplicateKey);
      }
      byId[message.messageId] = message;
    }
    return _sortMessages(byId.values);
  }

  String? _findRecentDuplicateMessageKey(
    Map<String, TelegramChatMessage> messages,
    TelegramChatMessage incoming,
  ) {
    if (messages.containsKey(incoming.messageId)) {
      return incoming.messageId;
    }
    final incomingFingerprint = _messageDedupeFingerprint(incoming);
    if (incomingFingerprint == null) return null;

    for (final entry in messages.entries) {
      final existing = entry.value;
      if (_messageDedupeFingerprint(existing) != incomingFingerprint) {
        continue;
      }
      if (!_areMessagesCloseEnough(existing.timestamp, incoming.timestamp)) {
        continue;
      }
      return entry.key;
    }
    return null;
  }

  String? _messageDedupeFingerprint(TelegramChatMessage message) {
    final text = (message.displayText ?? '').trim().toLowerCase();
    final documentName = message.isDocumentMessage
        ? message.documentDisplayName.trim().toLowerCase()
        : '';
    if (text.isEmpty && documentName.isEmpty) return null;

    final sender = (message.sender?.id ??
            message.sender?.username ??
            message.sender?.displayName ??
            '')
        .trim()
        .toLowerCase();
    final topicId = (message.topic?.forumTopicId ?? '').trim();
    final mediaType =
        (message.media?.type ?? message.messageType).trim().toLowerCase();
    final attachment = message.primaryAttachment;
    final fileSize = attachment?.size ??
        attachment?.expectedSize ??
        message.media?.fileSize ??
        0;

    return [
      sender,
      topicId,
      mediaType,
      documentName,
      fileSize.toString(),
      text,
    ].join('|');
  }

  bool _areMessagesCloseEnough(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.difference(b).abs() <= const Duration(seconds: 30);
  }

  List<TelegramChatMessage> _sortMessages(
    Iterable<TelegramChatMessage> messages,
  ) {
    final sorted = messages.toList()
      ..sort((a, b) {
        final aTime = a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
        final timeCompare = aTime.compareTo(bTime);
        if (timeCompare != 0) return timeCompare;
        return a.messageId.compareTo(b.messageId);
      });
    return sorted;
  }

  void _touchChat(
    String chatId, {
    DateTime? timestamp,
  }) {
    final index = _chats.indexWhere((chat) => chat.id == chatId);
    if (index == -1) return;

    final updated = _chats[index].copyWith(
      lastMessageDate: timestamp ?? _chats[index].lastMessageDate,
    );
    _chats[index] = updated;
  }

  TelegramChatMessagePaging _normalizePaging(
    TelegramChatMessagePaging paging, {
    required List<TelegramChatMessage> messages,
  }) {
    final firstId = messages.isNotEmpty ? messages.first.messageId : null;
    final lastId = messages.isNotEmpty ? messages.last.messageId : null;
    return TelegramChatMessagePaging(
      beforeMessageId: paging.beforeMessageId ?? firstId,
      afterMessageId: paging.afterMessageId ?? lastId,
      hasMoreHistory: paging.hasMoreHistory,
      pollCursor: paging.pollCursor ?? paging.afterMessageId ?? lastId,
    );
  }
}

class _TelegramChatFeedState {
  List<TelegramChatMessage> messages = <TelegramChatMessage>[];
  TelegramChatMessagePaging paging = const TelegramChatMessagePaging();
  bool historyExhausted = false;
  bool loadingInitial = false;
  bool loadingOlder = false;
  bool pollingNewer = false;
  String? error;
  int initialRequestId = 0;
  int olderRequestId = 0;
  int pollRequestId = 0;
}

class _TelegramChatComposerState {
  String draftText = '';
  bool sending = false;
  String? error;
  TelegramChatMessage? replyTarget;
  TelegramComposerAttachment? attachment;
}

class _TelegramForumTopicState {
  List<TelegramForumTopic> topics = <TelegramForumTopic>[];
  bool loading = false;
  String? error;
  int requestId = 0;
}
