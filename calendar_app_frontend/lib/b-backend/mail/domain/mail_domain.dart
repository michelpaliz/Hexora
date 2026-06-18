import 'package:flutter/foundation.dart';
import 'package:hexora/a-models/mail/mail_folder.dart';
import 'package:hexora/a-models/mail/mail_message.dart';
import 'package:hexora/a-models/mail/mail_page.dart';
import 'package:hexora/a-models/mail/mail_thread.dart';
import 'package:hexora/b-backend/mail/models/mail_requests.dart';
import 'package:hexora/b-backend/mail/repository/i_mail_repository.dart';
import 'package:http/http.dart' as http;

class MailDomain extends ChangeNotifier {
  MailDomain({required IMailRepository repository}) : _repository = repository;

  final IMailRepository _repository;

  MailFolder _currentFolder = MailFolder.inbox;
  MailFolder get currentFolder => _currentFolder;

  set currentFolder(MailFolder folder) {
    if (_currentFolder == folder) return;
    _currentFolder = folder;
    notifyListeners();
  }

  final Map<MailFolder, MailFolderState> _folderStates = {
    for (final folder in MailFolder.values) folder: const MailFolderState(),
  };

  MailFolderState folderState(MailFolder folder) =>
      _folderStates[folder] ?? const MailFolderState();

  MailSearchState _searchState = const MailSearchState();
  MailSearchState get searchState => _searchState;

  MailThreadsState _threadsState = const MailThreadsState();
  MailThreadsState get threadsState => _threadsState;
  Object? _threadsRequestMarker;

  final Map<String, MailMessageDetailState> _messageStates = {};
  final Map<String, MailThreadDetailState> _threadStates = {};
  final Map<String, MailMessage> _messageCache = {};

  bool _sending = false;
  String? _sendError;

  bool get isSending => _sending;
  String? get sendError => _sendError;

  MailMessageDetailState messageState(String id) =>
      _messageStates[id] ?? const MailMessageDetailState();

  MailThreadDetailState threadState(String threadKey) =>
      _threadStates[threadKey] ?? const MailThreadDetailState();

  Future<void> loadFolder(
    MailFolder folder, {
    bool refresh = false,
  }) async {
    final state = folderState(folder);
    if (state.loading || state.loadingMore) return;

    final bool initial = refresh || !state.hasRequested;
    if (initial) {
      _setFolderState(
        folder,
        state.copyWith(
          loading: true,
          error: null,
          hasRequested: true,
        ),
      );
    } else {
      if (!state.hasMore) return;
      _setFolderState(
        folder,
        state.copyWith(
          loadingMore: true,
          error: null,
        ),
      );
    }

    try {
      final MailPage<MailMessage> page = await _repository.getMessages(
        folder: folder,
        limit: 25,
        cursor: initial ? null : state.nextCursor,
      );

      final nextMessages = initial
          ? page.items
          : [...state.messages, ...page.items];

      for (final message in page.items) {
        _messageCache[message.id] = message;
      }

      _setFolderState(
        folder,
        state.copyWith(
          loading: false,
          loadingMore: false,
          messages: nextMessages,
          nextCursor: page.nextCursor,
          error: null,
        ),
      );
    } catch (e) {
      _setFolderState(
        folder,
        state.copyWith(
          loading: false,
          loadingMore: false,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> refreshFolder(MailFolder folder) =>
      loadFolder(folder, refresh: true);

  Future<void> loadMoreFolder(MailFolder folder) => loadFolder(folder);

  Future<MailMessage?> loadMessage(
    String id, {
    bool refresh = false,
  }) async {
    final current = _messageStates[id] ?? const MailMessageDetailState();
    if (!refresh && current.message != null) return current.message;
    if (current.loading) return current.message;

    _messageStates[id] = current.copyWith(loading: true, error: null);
    notifyListeners();

    try {
      final message = await _repository.getMessage(id);
      _messageCache[id] = message;
      _messageStates[id] = current.copyWith(
        loading: false,
        message: message,
        error: null,
      );
      _updateMessageEverywhere(message);
      return message;
    } catch (e) {
      _messageStates[id] = current.copyWith(
        loading: false,
        error: e.toString(),
      );
      notifyListeners();
      return current.message;
    }
  }

  Future<void> markRead(String id) async {
    await _repository.markRead(id);
    _applyReadState(id, unread: false);
  }

  Future<void> markUnread(String id) async {
    await _repository.markUnread(id);
    _applyReadState(id, unread: true);
  }

  Future<void> archive(String id) async {
    await _repository.archive(id);
    _applyFolderMove(id, MailFolder.archive);
  }

  Future<void> trash(String id) async {
    await _repository.trash(id);
    _applyFolderMove(id, MailFolder.trash);
  }

  Future<void> spam(String id) async {
    await _repository.spam(id);
    _applyFolderMove(id, MailFolder.spam);
  }

  Future<http.Response> downloadAttachment(String attachmentId) {
    return _repository.downloadAttachment(attachmentId);
  }

  void updateSearchQuery(String query) {
    _searchState = _searchState.copyWith(query: query, error: null);
    notifyListeners();
  }

  void updateSearchFilters(MailSearchFilters filters) {
    _searchState = _searchState.copyWith(filters: filters, error: null);
    notifyListeners();
  }

  Future<void> runSearch({bool refresh = true}) async {
    final trimmed = _searchState.query.trim();
    if (trimmed.length < 2) {
      _searchState = _searchState.copyWith(
        error: 'Search query must be at least 2 characters.',
        loading: false,
        loadingMore: false,
        hasRequested: true,
        results: const [],
        nextCursor: null,
      );
      notifyListeners();
      return;
    }

    if (_searchState.loading || _searchState.loadingMore) return;

    if (refresh) {
      _searchState = _searchState.copyWith(
        loading: true,
        error: null,
        hasRequested: true,
        nextCursor: null,
        results: const [],
      );
    } else {
      if (!_searchState.hasMore) return;
      _searchState = _searchState.copyWith(
        loadingMore: true,
        error: null,
      );
    }
    notifyListeners();

    try {
      final page = await _repository.searchMessages(
        query: trimmed,
        folder: _searchState.filters.folder,
        unread: _searchState.filters.unreadOnly
            ? true
            : null,
        after: _searchState.filters.after,
        before: _searchState.filters.before,
        limit: 25,
        cursor: refresh ? null : _searchState.nextCursor,
      );

      final nextResults = refresh
          ? page.items
          : [..._searchState.results, ...page.items];
      for (final message in page.items) {
        _messageCache[message.id] = message;
      }

      _searchState = _searchState.copyWith(
        loading: false,
        loadingMore: false,
        results: nextResults,
        nextCursor: page.nextCursor,
        error: null,
      );
      notifyListeners();
    } catch (e) {
      _searchState = _searchState.copyWith(
        loading: false,
        loadingMore: false,
        error: e.toString(),
      );
      notifyListeners();
    }
  }

  Future<void> loadThreads({
    MailFolder folder = MailFolder.inbox,
    bool refresh = false,
    String? query,
  }) async {
    if ((_threadsState.loading || _threadsState.loadingMore) && !refresh) return;

    final currentQuery = (_threadsState.query ?? '').trim();
    final effectiveQuery = (query ?? currentQuery).trim();
    final changedQuery = effectiveQuery != currentQuery;

    final initial = refresh || !_threadsState.hasRequested ||
        _threadsState.folder != folder ||
        changedQuery;

    final requestMarker = Object();
    _threadsRequestMarker = requestMarker;

    if (initial) {
      _threadsState = _threadsState.copyWith(
        loading: true,
        error: null,
        folder: folder,
        query: effectiveQuery,
        hasRequested: true,
        nextCursor: null,
        threads: const [],
      );
    } else {
      if (!_threadsState.hasMore) return;
      _threadsState = _threadsState.copyWith(
        loadingMore: true,
        error: null,
      );
    }
    notifyListeners();

    try {
      final page = await _repository.getThreads(
        folder: folder,
        limit: 25,
        cursor: initial ? null : _threadsState.nextCursor,
        query: effectiveQuery.length >= 2 ? effectiveQuery : null,
      );

      if (!identical(requestMarker, _threadsRequestMarker)) return;

      final nextThreads = initial
          ? page.items
          : [..._threadsState.threads, ...page.items];

      _threadsState = _threadsState.copyWith(
        loading: false,
        loadingMore: false,
        threads: nextThreads,
        query: effectiveQuery,
        nextCursor: page.nextCursor,
        error: null,
      );
      notifyListeners();
    } catch (e) {
      if (!identical(requestMarker, _threadsRequestMarker)) return;
      _threadsState = _threadsState.copyWith(
        loading: false,
        loadingMore: false,
        query: effectiveQuery,
        error: e.toString(),
      );
      notifyListeners();
    }
  }

  Future<void> loadThreadDetail(String threadKey) async {
    final current = _threadStates[threadKey] ?? const MailThreadDetailState();
    if (current.loading) return;

    _threadStates[threadKey] = current.copyWith(loading: true, error: null);
    notifyListeners();

    try {
      final detail = await _repository.getThread(threadKey);
      _threadStates[threadKey] = current.copyWith(
        loading: false,
        thread: detail,
        error: null,
      );

      for (final message in detail.messages) {
        _messageCache[message.id] = message;
      }
      notifyListeners();
    } catch (e) {
      _threadStates[threadKey] = current.copyWith(
        loading: false,
        error: e.toString(),
      );
      notifyListeners();
    }
  }

  Future<void> sendMessage(MailSendRequest request) async {
    _sending = true;
    _sendError = null;
    notifyListeners();
    try {
      await _repository.sendMessage(request);
    } catch (e) {
      _sendError = e.toString();
      rethrow;
    } finally {
      _sending = false;
      notifyListeners();
    }
  }

  Future<void> reply(String id, MailReplyRequest request) async {
    await _repository.reply(id, request);
  }

  Future<void> forward(String id, MailForwardRequest request) async {
    await _repository.forward(id, request);
  }

  void _setFolderState(MailFolder folder, MailFolderState state) {
    _folderStates[folder] = state;
    notifyListeners();
  }

  void _applyReadState(String id, {required bool unread}) {
    final cached = _messageCache[id];
    if (cached != null) {
      _messageCache[id] = cached.copyWith(unread: unread);
    }

    _updateMessageEverywhere(
      cached?.copyWith(unread: unread) ??
          MailMessage(id: id, unread: unread),
      addIfMissing: false,
    );
  }

  void _applyFolderMove(String id, MailFolder target) {
    final cached = _messageCache[id];
    MailMessage? updated;
    if (cached != null) {
      updated = cached.copyWith(folder: target.wireName);
      _messageCache[id] = updated;
    }

    for (final entry in _folderStates.entries) {
      final folder = entry.key;
      final state = entry.value;
      if (state.messages.isEmpty) continue;
      final exists = state.messages.any((m) => m.id == id);
      if (!exists) continue;
      final next = state.messages.where((m) => m.id != id).toList();
      _folderStates[folder] = state.copyWith(messages: next);
    }

    if (updated != null) {
      final targetState = _folderStates[target] ?? const MailFolderState();
      final next = [updated, ...targetState.messages.where((m) => m.id != id)];
      _folderStates[target] = targetState.copyWith(messages: next);
    }

    notifyListeners();
  }

  void _updateMessageEverywhere(
    MailMessage message, {
    bool addIfMissing = false,
  }) {
    for (final entry in _folderStates.entries) {
      final state = entry.value;
      final idx = state.messages.indexWhere((m) => m.id == message.id);
      if (idx == -1) {
        if (addIfMissing &&
            message.folderEnum != null &&
            message.folderEnum == entry.key) {
          final next = [message, ...state.messages];
          _folderStates[entry.key] = state.copyWith(messages: next);
        }
        continue;
      }
      final next = [...state.messages];
      next[idx] = message;
      _folderStates[entry.key] = state.copyWith(messages: next);
    }

    final searchIdx = _searchState.results.indexWhere((m) => m.id == message.id);
    if (searchIdx != -1) {
      final next = [..._searchState.results];
      next[searchIdx] = message;
      _searchState = _searchState.copyWith(results: next);
    }

    for (final entry in _threadStates.entries) {
      final detail = entry.value.thread;
      if (detail == null) continue;
      final idx = detail.messages.indexWhere((m) => m.id == message.id);
      if (idx == -1) continue;
      final nextMessages = [...detail.messages];
      nextMessages[idx] = message;
      _threadStates[entry.key] = entry.value.copyWith(
        thread: MailThreadDetail(
          threadKey: detail.threadKey,
          subject: detail.subject,
          participants: detail.participants,
          latestDate: detail.latestDate,
          unreadCount: detail.unreadCount,
          messageCount: detail.messageCount,
          messages: nextMessages,
        ),
      );
    }

    notifyListeners();
  }
}

class MailFolderState {
  static const Object _nextCursorNoChange = Object();
  final List<MailMessage> messages;
  final bool loading;
  final bool loadingMore;
  final String? error;
  final String? nextCursor;
  final bool hasRequested;

  const MailFolderState({
    this.messages = const [],
    this.loading = false,
    this.loadingMore = false,
    this.error,
    this.nextCursor,
    this.hasRequested = false,
  });

  bool get hasMore => nextCursor != null && nextCursor!.isNotEmpty;

  MailFolderState copyWith({
    List<MailMessage>? messages,
    bool? loading,
    bool? loadingMore,
    String? error,
    Object? nextCursor = _nextCursorNoChange,
    bool? hasRequested,
  }) {
    return MailFolderState(
      messages: messages ?? this.messages,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      error: error,
      nextCursor: identical(nextCursor, _nextCursorNoChange)
          ? this.nextCursor
          : nextCursor as String?,
      hasRequested: hasRequested ?? this.hasRequested,
    );
  }
}

class MailSearchFilters {
  final MailFolder? folder;
  final bool unreadOnly;
  final DateTime? after;
  final DateTime? before;

  const MailSearchFilters({
    this.folder,
    this.unreadOnly = false,
    this.after,
    this.before,
  });

  MailSearchFilters copyWith({
    MailFolder? folder,
    bool? unreadOnly,
    DateTime? after,
    DateTime? before,
  }) {
    return MailSearchFilters(
      folder: folder ?? this.folder,
      unreadOnly: unreadOnly ?? this.unreadOnly,
      after: after ?? this.after,
      before: before ?? this.before,
    );
  }
}

class MailSearchState {
  static const Object _nextCursorNoChange = Object();
  final String query;
  final MailSearchFilters filters;
  final List<MailMessage> results;
  final bool loading;
  final bool loadingMore;
  final String? error;
  final String? nextCursor;
  final bool hasRequested;

  const MailSearchState({
    this.query = '',
    this.filters = const MailSearchFilters(),
    this.results = const [],
    this.loading = false,
    this.loadingMore = false,
    this.error,
    this.nextCursor,
    this.hasRequested = false,
  });

  bool get hasMore => nextCursor != null && nextCursor!.isNotEmpty;

  MailSearchState copyWith({
    String? query,
    MailSearchFilters? filters,
    List<MailMessage>? results,
    bool? loading,
    bool? loadingMore,
    String? error,
    Object? nextCursor = _nextCursorNoChange,
    bool? hasRequested,
  }) {
    return MailSearchState(
      query: query ?? this.query,
      filters: filters ?? this.filters,
      results: results ?? this.results,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      error: error,
      nextCursor: identical(nextCursor, _nextCursorNoChange)
          ? this.nextCursor
          : nextCursor as String?,
      hasRequested: hasRequested ?? this.hasRequested,
    );
  }
}

class MailThreadsState {
  static const Object _nextCursorNoChange = Object();
  final MailFolder folder;
  final List<MailThread> threads;
  final String? query;
  final bool loading;
  final bool loadingMore;
  final String? error;
  final String? nextCursor;
  final bool hasRequested;

  const MailThreadsState({
    this.folder = MailFolder.inbox,
    this.threads = const [],
    this.query = '',
    this.loading = false,
    this.loadingMore = false,
    this.error,
    this.nextCursor,
    this.hasRequested = false,
  });

  bool get hasMore => nextCursor != null && nextCursor!.isNotEmpty;

  MailThreadsState copyWith({
    MailFolder? folder,
    List<MailThread>? threads,
    String? query,
    bool? loading,
    bool? loadingMore,
    String? error,
    Object? nextCursor = _nextCursorNoChange,
    bool? hasRequested,
  }) {
    return MailThreadsState(
      folder: folder ?? this.folder,
      threads: threads ?? this.threads,
      query: query ?? this.query ?? '',
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      error: error,
      nextCursor: identical(nextCursor, _nextCursorNoChange)
          ? this.nextCursor
          : nextCursor as String?,
      hasRequested: hasRequested ?? this.hasRequested,
    );
  }
}

class MailMessageDetailState {
  final MailMessage? message;
  final bool loading;
  final String? error;

  const MailMessageDetailState({
    this.message,
    this.loading = false,
    this.error,
  });

  MailMessageDetailState copyWith({
    MailMessage? message,
    bool? loading,
    String? error,
  }) {
    return MailMessageDetailState(
      message: message ?? this.message,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class MailThreadDetailState {
  final MailThreadDetail? thread;
  final bool loading;
  final String? error;

  const MailThreadDetailState({
    this.thread,
    this.loading = false,
    this.error,
  });

  MailThreadDetailState copyWith({
    MailThreadDetail? thread,
    bool? loading,
    String? error,
  }) {
    return MailThreadDetailState(
      thread: thread ?? this.thread,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}
