import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/services/auth/auth_service.dart';
import 'package:hexora/services/insights/insights_api.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'insights_action_tokens.dart';
import 'insights_chat_enums.dart';
import 'insights_chat_menu.dart';
import 'insights_chat_message.dart';
import 'insights_date_range.dart';
import 'insights_json_utils.dart';

class InsightsChatRuntime extends ChangeNotifier {
  InsightsChatRuntime._(this.scopeKey);
  static final Map<String, InsightsChatRuntime> _instances = {};

  static InsightsChatRuntime instanceFor(String scopeKey) {
    return _instances.putIfAbsent(
      scopeKey,
      () => InsightsChatRuntime._(scopeKey),
    );
  }

  final String scopeKey;
  final _api = InsightsApi();
  final _messages = <ChatMessage>[];
  int _generation = 0;
  String _conversationId = _newConversationId();
  bool _resetConversationOnNextSend = false;
  bool _bootstrapped = false;
  late String _historyKey = 'insights_chat_history::anon::$scopeKey';
  InsightsResponseMode _mode = InsightsResponseMode.auto;
  bool _sending = false;
  String? _error;
  bool _sheetOpen = false;
  int _unreadCount = 0;
  int _backgroundReplyEvents = 0;
  int _days = 90;
  int _timeoutMs = 15000;
  bool _takingTooLong = false;
  Timer? _slowTimer;
  InsightsChatEndpointType _endpointType = InsightsChatEndpointType.chatAuto;
  InsightsDateRange? _dateRange;
  String? _lastUserMessage;
  String? _lastTimeoutMessage;
  int _chatTimeoutCount = 0;

  static const _maxPersistedMessages = 80;

  static String _newConversationId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  InsightsResponseMode get mode => _mode;
  bool get sending => _sending;
  String? get error => _error;
  bool get isSheetOpen => _sheetOpen;
  int get unreadCount => _unreadCount;
  int get backgroundReplyEvents => _backgroundReplyEvents;
  int get days => _days;
  int get timeoutMs => _timeoutMs;
  bool get takingTooLong => _takingTooLong;
  InsightsChatEndpointType get endpointType => _endpointType;
  InsightsDateRange? get dateRange => _dateRange;
  String? get lastTimeoutMessage => _lastTimeoutMessage;
  int get chatTimeoutCount => _chatTimeoutCount;

  void setMode(InsightsResponseMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    _endpointType = mode == InsightsResponseMode.auto
        ? InsightsChatEndpointType.chatAuto
        : InsightsChatEndpointType.chatAutoStream;
    notifyListeners();
  }

  void setDays(int nextDays) {
    final clamped = nextDays.clamp(30, 180);
    if (_days == clamped) return;
    _days = clamped;
    notifyListeners();
  }

  void setTimeoutMs(int nextTimeoutMs) {
    final safe = nextTimeoutMs.clamp(3000, 60000);
    if (_timeoutMs == safe) return;
    _timeoutMs = safe;
    notifyListeners();
  }

  void setDateRange(InsightsDateRange? range) {
    if (range == null && _dateRange == null) return;
    if (range != null && range.sameRange(_dateRange)) return;
    _dateRange = range;
    notifyListeners();
  }

  Map<String, dynamic> _dateRangePayload() {
    return _dateRange?.toApiJson() ?? const <String, dynamic>{};
  }

  Map<String, dynamic> _scopePayload() {
    final datePayload = _dateRangePayload();
    if (datePayload.isNotEmpty) return datePayload;
    return <String, dynamic>{'days': _days};
  }

  InsightsExcelExportAction _withScope(
    InsightsExcelExportAction action,
  ) {
    final scopePayload = _scopePayload();
    return InsightsExcelExportAction(
      type: action.type,
      endpoint: action.endpoint,
      method: action.method,
      body: <String, dynamic>{
        ...action.body,
        ...scopePayload,
      },
      filename: action.filename,
    );
  }

  void setSheetOpen(bool open, {bool notify = true}) {
    if (_sheetOpen == open) return;
    _sheetOpen = open;
    if (open && _unreadCount > 0) {
      _unreadCount = 0;
    }
    if (notify) {
      notifyListeners();
    }
  }

  String _resolveHistoryKey(BuildContext context) {
    String userId = 'anon';
    try {
      final auth = context.read<AuthService>();
      final rawId = auth.currentUser?.id;
      final id = rawId is String ? rawId.trim() : '';
      if (id.isNotEmpty) {
        userId = id;
      }
    } catch (_) {}
    return 'insights_chat_history::$userId::$scopeKey';
  }

  Future<void> ensureLoaded(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final nextHistoryKey = _resolveHistoryKey(context);
    if (_bootstrapped && _historyKey == nextHistoryKey) return;
    _historyKey = nextHistoryKey;
    _bootstrapped = true;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    final next = <ChatMessage>[];
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            final message = ChatMessage.fromJson(item);
            if (message != null && message.text != l.insightsChatWelcome) {
              next.add(message);
            }
          }
        } else if (decoded is Map) {
          final map = decoded.map(
            (key, value) => MapEntry(key.toString(), value),
          );
          final persistedConversationId =
              map['conversationId']?.toString().trim() ?? '';
          if (persistedConversationId.isNotEmpty) {
            _conversationId = persistedConversationId;
          }
          final persistedReset = map['resetConversationOnNextSend'];
          _resetConversationOnNextSend =
              persistedReset == true || persistedReset?.toString() == 'true';
          final items = map['messages'];
          if (items is List) {
            for (final item in items) {
              final message = ChatMessage.fromJson(item);
              if (message != null && message.text != l.insightsChatWelcome) {
                next.add(message);
              }
            }
          }
        }
      } catch (_) {}
    }
    _messages
      ..clear()
      ..addAll(next);
    debugPrint(
      '[insights_history] loaded conversationId=$_conversationId '
      'messages=${_messages.length} resetPending=$_resetConversationOnNextSend '
      'scope=$scopeKey',
    );
    notifyListeners();
  }

  Future<void> _persistHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = _messages.length > _maxPersistedMessages
        ? _messages.sublist(_messages.length - _maxPersistedMessages)
        : List<ChatMessage>.from(_messages);
    final payload = <String, dynamic>{
      'conversationId': _conversationId,
      'resetConversationOnNextSend': _resetConversationOnNextSend,
      'messages': trimmed.map((m) => m.toJson()).toList(),
    };
    await prefs.setString(_historyKey, jsonEncode(payload));
  }

  Future<void> updateTableRow({
    required ChatMessage message,
    required String entryId,
    required Map<String, dynamic> rowPatch,
  }) async {
    await updateTableRows(
      message: message,
      patchesByEntryId: {entryId: rowPatch},
    );
  }

  Future<void> updateTableRows({
    required ChatMessage message,
    required Map<String, Map<String, dynamic>> patchesByEntryId,
  }) async {
    if (patchesByEntryId.isEmpty) return;
    final messageIndex = _messages.indexOf(message);
    if (messageIndex < 0) return;
    final table = safeMap(message.table);
    final rows = table?['rows'];
    if (table == null || rows is! List) return;

    final nextRows = rows.map((item) {
      final row = safeMap(item);
      if (row == null) return item;
      final rowId =
          (row['id'] ?? row['_id'] ?? row['entryId'] ?? row['entry_id'])
                  ?.toString()
                  .trim() ??
              '';
      final patch = patchesByEntryId[rowId];
      if (patch == null) return item;
      return <String, dynamic>{...row, ...patch};
    }).toList(growable: false);

    final nextTable = <String, dynamic>{...table, 'rows': nextRows};
    _messages[messageIndex] = message.copyWith(table: nextTable);
    notifyListeners();
    await _persistHistory();
  }

  Future<void> clearChat(BuildContext context) async {
    _generation += 1;
    _conversationId = _newConversationId();
    _resetConversationOnNextSend = true;
    _messages.clear();
    _error = null;
    _lastUserMessage = null;
    _lastTimeoutMessage = null;
    _unreadCount = 0;
    debugPrint(
      '[insights_history] cleared conversationId=$_conversationId scope=$scopeKey',
    );
    notifyListeners();
    await _persistHistory();
  }

  Future<void> replaceMessage(
    ChatMessage previous,
    ChatMessage next,
  ) async {
    final index = _messages.indexOf(previous);
    if (index < 0) return;
    _messages[index] = next;
    notifyListeners();
    await _persistHistory();
  }

  Future<void> appendMessage(ChatMessage message) async {
    _messages.add(message);
    notifyListeners();
    await _persistHistory();
  }

  void _startSlowTimer() {
    _slowTimer?.cancel();
    _takingTooLong = false;
    _slowTimer = Timer(const Duration(seconds: 8), () {
      _takingTooLong = true;
      notifyListeners();
    });
  }

  void _stopSlowTimer() {
    _slowTimer?.cancel();
    _slowTimer = null;
    _takingTooLong = false;
  }

  void _trackTimeout({
    required InsightsChatEndpointType endpoint,
    required int timeoutMs,
  }) {
    _chatTimeoutCount += 1;
    debugPrint(
      '[insights_telemetry] event=chat_timeout_count endpoint=${endpoint.name} timeoutMs=$timeoutMs count=$_chatTimeoutCount',
    );
  }

  void _trackRetry({
    required InsightsChatEndpointType endpoint,
    required int timeoutMs,
  }) {
    debugPrint(
      '[insights_telemetry] event=chat_retry_clicked endpoint=${endpoint.name} timeoutMs=$timeoutMs',
    );
  }

  String _quickSummaryPrompt(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode.toLowerCase();
    if (locale.startsWith('es')) {
      return 'Dame un resumen rapido en 5 puntos clave, con ingresos, gastos, margen y una accion recomendada.';
    }
    return 'Give me a quick summary in 5 key bullets with revenue, expenses, margin, and one recommended action.';
  }

  String? _starterOptionLabel(BuildContext context, String text) {
    final normalized = text.trim();
    if (normalized.isEmpty) return null;
    final isEs = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('es');
    switch (normalized) {
      case '1':
        return isEs ? 'Ingresos' : 'Revenue';
      case '2':
        return isEs ? 'Gastos' : 'Expenses';
      case '3':
        return isEs ? 'Facturas' : 'Invoices';
      case '4':
        return isEs ? 'Clientes' : 'Clients';
      default:
        return null;
    }
  }

  InsightsMenu _defaultRootMenu(bool isEs) {
    return InsightsMenu(
      id: 'guided_root',
      parentId: null,
      backAction: null,
      title: isEs ? 'Areas' : 'Areas',
      options: <InsightsMenuOption>[
        InsightsMenuOption(
          index: 1,
          label: isEs ? 'Ingresos' : 'Revenue',
        ),
        InsightsMenuOption(
          index: 2,
          label: isEs ? 'Gastos' : 'Expenses',
        ),
        InsightsMenuOption(
          index: 3,
          label: isEs ? 'Facturas' : 'Invoices',
        ),
        InsightsMenuOption(
          index: 4,
          label: isEs ? 'Clientes' : 'Clients',
        ),
      ],
    );
  }

  InsightsMenu? _localStarterMenuForArea({
    required bool isEs,
    required String areaLabel,
  }) {
    final normalized = areaLabel.trim().toLowerCase();
    final isIncome = normalized == 'ingresos' || normalized == 'revenue';
    final isExpenses = normalized == 'gastos' || normalized == 'expenses';
    final isInvoices = normalized == 'facturas' || normalized == 'invoices';
    final isClients = normalized == 'clientes' || normalized == 'clients';

    if (isIncome) {
      return InsightsMenu(
        id: 'guided_income',
        parentId: 'guided_root',
        backAction: 'menu:root',
        title: isEs ? 'Ingresos' : 'Revenue',
        options: <InsightsMenuOption>[
          InsightsMenuOption(
            index: 1,
            label: isEs ? 'Resumen de ingresos' : 'Revenue summary',
            action: isEs
                ? 'Dame un resumen de ingresos del periodo seleccionado.'
                : 'Give me a revenue summary for the selected period.',
          ),
          InsightsMenuOption(
            index: 2,
            label: isEs ? 'Tendencia mensual' : 'Monthly trend',
            action: isEs
                ? 'Analiza la tendencia mensual de ingresos.'
                : 'Analyze the monthly revenue trend.',
          ),
          InsightsMenuOption(
            index: 3,
            label: isEs ? 'Clientes con mas ingresos' : 'Top revenue clients',
            action: isEs
                ? 'Muestra los clientes que generan mas ingresos.'
                : 'Show the clients generating the most revenue.',
          ),
          InsightsMenuOption(
            index: 4,
            label: isEs
                ? 'Ingresos vinculados que requieren revisión'
                : 'Linked income requiring review',
            action: linkedIncomeReviewAction,
          ),
        ],
      );
    }

    if (isExpenses) {
      return InsightsMenu(
        id: 'guided_expenses',
        parentId: 'guided_root',
        backAction: 'menu:root',
        title: isEs ? 'Gastos' : 'Expenses',
        options: <InsightsMenuOption>[
          InsightsMenuOption(
            index: 1,
            label: isEs ? 'Resumen de gastos' : 'Expense summary',
            action: isEs
                ? 'Dame un resumen de gastos del periodo seleccionado.'
                : 'Give me an expense summary for the selected period.',
          ),
          InsightsMenuOption(
            index: 2,
            label: isEs ? 'Mayores proveedores' : 'Top suppliers',
            action: isEs
                ? 'Muestra los proveedores con mas gasto.'
                : 'Show the suppliers with the highest spend.',
          ),
          InsightsMenuOption(
            index: 3,
            label: isEs ? 'Gastos con incidencias' : 'Expense issues',
            action: isEs
                ? 'Revisa gastos con posibles incidencias o datos pendientes.'
                : 'Review expenses with possible issues or pending data.',
          ),
        ],
      );
    }

    if (isInvoices) {
      return InsightsMenu(
        id: 'guided_invoices',
        parentId: 'guided_root',
        backAction: 'menu:root',
        title: isEs ? 'Facturas' : 'Invoices',
        options: <InsightsMenuOption>[
          InsightsMenuOption(
            index: 1,
            label: isEs ? 'Facturas emitidas' : 'Issued invoices',
            action: isEs
                ? 'Resume las facturas emitidas del periodo seleccionado.'
                : 'Summarize issued invoices for the selected period.',
          ),
          InsightsMenuOption(
            index: 2,
            label: isEs ? 'Pendientes de cobro' : 'Pending collection',
            action: isEs
                ? 'Muestra facturas pendientes de cobro.'
                : 'Show invoices pending collection.',
          ),
          InsightsMenuOption(
            index: 3,
            label: isEs ? 'Vencidas' : 'Overdue',
            action: isEs
                ? 'Muestra facturas vencidas y acciones recomendadas.'
                : 'Show overdue invoices and recommended actions.',
          ),
        ],
      );
    }

    if (isClients) {
      return InsightsMenu(
        id: 'guided_clients',
        parentId: 'guided_root',
        backAction: 'menu:root',
        title: isEs ? 'Clientes' : 'Clients',
        options: <InsightsMenuOption>[
          InsightsMenuOption(
            index: 1,
            label: isEs ? 'Resumen de clientes' : 'Client summary',
            action: isEs
                ? 'Dame un resumen de clientes y actividad reciente.'
                : 'Give me a client summary and recent activity.',
          ),
          InsightsMenuOption(
            index: 2,
            label: isEs ? 'Clientes principales' : 'Top clients',
            action: isEs
                ? 'Muestra los clientes principales por ingresos.'
                : 'Show top clients by revenue.',
          ),
          InsightsMenuOption(
            index: 3,
            label: isEs ? 'Clientes sin actividad' : 'Inactive clients',
            action: isEs
                ? 'Detecta clientes sin actividad reciente.'
                : 'Find clients with no recent activity.',
          ),
        ],
      );
    }

    return null;
  }

  bool openLocalStarterArea({
    required BuildContext context,
    required InsightsMenuOption option,
  }) {
    if (_sending) return true;
    final isEs = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('es');
    final menu = _localStarterMenuForArea(isEs: isEs, areaLabel: option.label);
    if (menu == null) return false;
    final conversationId = _conversationId;
    final label = option.label.trim();
    _messages.add(
      ChatMessage(
        isUser: true,
        text: label,
        displayText: label,
        timestamp: DateTime.now(),
        conversationId: conversationId,
      ),
    );
    final text = isEs
        ? 'Perfecto. Elige que quieres revisar en $label.'
        : 'Perfect. Choose what you want to review in $label.';
    _messages.add(
      ChatMessage(
        isUser: false,
        text: text,
        displayText: text,
        timestamp: DateTime.now(),
        conversationId: conversationId,
        menu: menu,
      ),
    );
    notifyListeners();
    unawaited(_persistHistory());
    return true;
  }

  bool openLocalRootMenu({required BuildContext context}) {
    if (_sending) return true;
    final isEs = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('es');
    final text =
        isEs ? 'Elige un area para continuar.' : 'Choose an area to continue.';
    _messages.add(
      ChatMessage(
        isUser: false,
        text: text,
        displayText: text,
        timestamp: DateTime.now(),
        conversationId: _conversationId,
        menu: _defaultRootMenu(isEs),
      ),
    );
    notifyListeners();
    unawaited(_persistHistory());
    return true;
  }

  bool handleLocalMenuBack({
    required BuildContext context,
    required InsightsMenu menu,
  }) {
    if ((menu.backAction ?? '').trim() != 'menu:root') return false;
    return openLocalRootMenu(context: context);
  }

  bool handleLocalMenuChoice({
    required BuildContext context,
    required ChatMessage message,
    required String action,
    required String displayLabel,
  }) {
    if (_sending) return true;
    if (isFinanceBreakdownAction(action) &&
        messageIndicatesZeroFinanceMovements(message.text)) {
      final isEs = Localizations.localeOf(context)
          .languageCode
          .toLowerCase()
          .startsWith('es');
      final conversationId = message.conversationId?.trim().isNotEmpty == true
          ? message.conversationId!.trim()
          : _conversationId;
      final userText =
          displayLabel.trim().isNotEmpty ? displayLabel.trim() : '1';
      final replyText = isEs
          ? 'No hay movimientos bancarios en este ciclo, asi que no existe un desglose para mostrar.'
          : 'There are no bank movements in this cycle, so there is no breakdown to show.';
      _messages.add(
        ChatMessage(
          isUser: true,
          text: action,
          displayText: userText,
          timestamp: DateTime.now(),
          conversationId: conversationId,
        ),
      );
      _messages.add(
        ChatMessage(
          isUser: false,
          text: replyText,
          displayText: replyText,
          timestamp: DateTime.now(),
          conversationId: conversationId,
          sourceUserMessage: action,
          menu: _defaultRootMenu(isEs),
        ),
      );
      notifyListeners();
      unawaited(_persistHistory());
      return true;
    }
    return false;
  }

  ChatMessage _buildRecoveryMessage({
    required bool isEs,
    required String conversationId,
    required InsightsApiException error,
  }) {
    final isInvalidMenu =
        error.code == 'INVALID_MENU_ACTION' || error.statusCode == 409;
    final isTemporaryServerFailure = error.statusCode == 500 ||
        error.statusCode == 502 ||
        error.statusCode == 503 ||
        error.statusCode == 504;
    final text = isInvalidMenu
        ? (isEs
            ? 'Esa opcion ya no es valida para esta conversacion. Vamos a empezar de nuevo.'
            : 'That option is no longer valid for this conversation. Let\'s start again.')
        : isTemporaryServerFailure
            ? (isEs
                ? 'Insights no esta disponible ahora mismo. Intentalo de nuevo en unos segundos o elige otra area.'
                : 'Insights is not available right now. Try again in a few seconds or choose another area.')
            : (isEs
                ? 'No pude completar esa accion ahora mismo. Elige un area para continuar.'
                : 'I could not complete that action right now. Choose an area to continue.');
    return ChatMessage(
      isUser: false,
      text: text,
      displayText: text,
      timestamp: DateTime.now(),
      conversationId: conversationId,
      menu: _defaultRootMenu(isEs),
    );
  }

  String _messageForFreshConversation(
    BuildContext context,
    String text,
  ) {
    final locale = Localizations.localeOf(context).languageCode.toLowerCase();
    if (locale.startsWith('es')) {
      return 'Nueva conversacion. Ignora todo el contexto anterior y responde solo a esta solicitud.\n\n$text';
    }
    return 'New conversation. Ignore all previous context and respond only to this request.\n\n$text';
  }

  InsightsChatEndpoint _apiEndpointForNonStream(
      InsightsChatEndpointType type) {
    switch (type) {
      case InsightsChatEndpointType.chat:
        return InsightsChatEndpoint.chat;
      case InsightsChatEndpointType.chatAuto:
        return InsightsChatEndpoint.chatAuto;
      case InsightsChatEndpointType.chatStream:
      case InsightsChatEndpointType.chatAutoStream:
        return InsightsChatEndpoint.chatAuto;
    }
  }

  InsightsChatEndpoint _apiEndpointForStream(InsightsChatEndpointType type) {
    switch (type) {
      case InsightsChatEndpointType.chat:
      case InsightsChatEndpointType.chatAuto:
        return InsightsChatEndpoint.chatAutoStream;
      case InsightsChatEndpointType.chatStream:
        return InsightsChatEndpoint.chatStream;
      case InsightsChatEndpointType.chatAutoStream:
        return InsightsChatEndpoint.chatAutoStream;
    }
  }

  bool _isTemporaryInsightsFailure(InsightsApiException error) {
    return error.statusCode == 500 ||
        error.statusCode == 502 ||
        error.statusCode == 503;
  }

  Future<InsightsChatResult> _sendAutoChatWithFallback({
    required String message,
    required String groupId,
    required Map<String, dynamic> extra,
  }) async {
    final endpoint = _apiEndpointForNonStream(_endpointType);
    try {
      return await _api.chat(
        endpoint: endpoint,
        message: message,
        groupId: groupId,
        days: _days,
        temperature: 0.2,
        maxTokens: 800,
        timeoutMs: _timeoutMs,
        extra: extra,
      );
    } on InsightsApiException catch (error) {
      final canFallback = endpoint == InsightsChatEndpoint.chatAuto &&
          _isTemporaryInsightsFailure(error);
      if (!canFallback) rethrow;
      debugPrint(
        '[insights_send] chatAuto failed with ${error.statusCode}; retrying via chat',
      );
      return _api.chat(
        endpoint: InsightsChatEndpoint.chat,
        message: message,
        groupId: groupId,
        days: _days,
        temperature: 0.2,
        maxTokens: 800,
        timeoutMs: _timeoutMs,
        extra: extra,
      );
    }
  }

  Future<InsightsSendOutcome> send({
    required BuildContext context,
    required String text,
    required String groupId,
    bool isRetry = false,
    InsightsSendSource source = InsightsSendSource.typedInput,
    String? conversationIdOverride,
    String? displayTextOverride,
  }) async {
    final trimmed = text.trim();
    final resolvedGroupId = groupId.trim();
    if (trimmed.isEmpty || _sending || resolvedGroupId.isEmpty) {
      return InsightsSendOutcome(timedOut: false, originalText: trimmed);
    }
    final l = AppLocalizations.of(context)!;
    final isEs = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('es');
    final requestGeneration = _generation;
    final starterLabel =
        _messages.isEmpty ? _starterOptionLabel(context, trimmed) : null;
    final isFollowUpLike = source == InsightsSendSource.followUpButton ||
        source == InsightsSendSource.backButton;
    final activeConversationId =
        (conversationIdOverride?.trim().isNotEmpty ?? false)
            ? conversationIdOverride!.trim()
            : _conversationId;
    if (activeConversationId != _conversationId) {
      _conversationId = activeConversationId;
    }
    final shouldResetConversation =
        !isFollowUpLike && _resetConversationOnNextSend;
    final semanticText = starterLabel ?? trimmed;
    final outboundText = shouldResetConversation
        ? _messageForFreshConversation(context, semanticText)
        : semanticText;
    final extra = <String, dynamic>{
      'conversationId': activeConversationId,
      'resetConversation': shouldResetConversation,
      ..._scopePayload(),
    };
    if (shouldResetConversation) {
      _resetConversationOnNextSend = false;
    }
    debugPrint(
      '[insights_send] source=${source.name} '
      'message=${jsonEncode(trimmed)} '
      'conversationId=$activeConversationId '
      'resetConversation=$shouldResetConversation '
      'scope=${jsonEncode(_scopePayload())}',
    );
    _lastUserMessage = trimmed;
    _lastTimeoutMessage = null;

    _sending = true;
    _error = null;
    _startSlowTimer();
    if (isRetry) {
      _trackRetry(endpoint: _endpointType, timeoutMs: _timeoutMs);
    }
    _messages.add(
      ChatMessage(
        isUser: true,
        text: trimmed,
        displayText: displayTextOverride ?? starterLabel,
        timestamp: DateTime.now(),
        conversationId: activeConversationId,
      ),
    );
    notifyListeners();
    unawaited(_persistHistory());

    var addedAssistant = false;
    var timedOut = false;
    try {
      if (_mode == InsightsResponseMode.auto) {
        final response = await _sendAutoChatWithFallback(
          message: outboundText,
          groupId: resolvedGroupId,
          extra: extra,
        );
        if (requestGeneration != _generation) {
          return InsightsSendOutcome(timedOut: false, originalText: trimmed);
        }
        final exportAction = extractExportActionMap(response.raw);
        final canExport = extractCanExport(response.raw);
        final responseView = extractResponseView(response.raw);
        final responseTable = extractStructuredTableMap(response.raw);
        final responseTableQuery = extractTableQueryMap(response.raw);
        final responseFollowUps = extractFollowUps(response.raw);
        final responseMenu = menuForResponse(
          raw: response.raw,
          text: response.text,
          table: responseTable,
        );
        if (response.timedOut) {
          timedOut = true;
          _lastTimeoutMessage = trimmed;
          _trackTimeout(endpoint: _endpointType, timeoutMs: _timeoutMs);
          _messages.add(
            ChatMessage(
              isUser: false,
              text: response.text.trim().isEmpty
                  ? l.insightsChatNoResponse
                  : response.text.trim(),
              timestamp: DateTime.now(),
              conversationId: activeConversationId,
              isTimeoutFallback: true,
              canRetry: response.timeout?.canRetry ?? true,
              canExport: canExport,
              retryMessage: trimmed,
              sourceUserMessage: trimmed,
              exportAction: exportAction,
              view: responseView,
              table: responseTable,
              tableQuery: responseTableQuery,
              followUps: responseFollowUps,
              menu: responseMenu,
            ),
          );
        } else {
          final textOut = response.text.trim().isEmpty
              ? l.insightsChatNoResponse
              : response.text.trim();
          _messages.add(
            ChatMessage(
              isUser: false,
              text: textOut,
              timestamp: DateTime.now(),
              conversationId: activeConversationId,
              canExport: canExport,
              sourceUserMessage: trimmed,
              exportAction: exportAction,
              view: responseView,
              table: responseTable,
              tableQuery: responseTableQuery,
              followUps: responseFollowUps,
              menu: responseMenu,
            ),
          );
        }
        addedAssistant = !(_messages.isNotEmpty && _messages.last.isUser);
        notifyListeners();
      } else {
        _messages.add(
          ChatMessage(
            isUser: false,
            text: '',
            timestamp: DateTime.now(),
            conversationId: activeConversationId,
            sourceUserMessage: trimmed,
          ),
        );
        final assistantIndex = _messages.length - 1;
        Map<String, dynamic>? latestExportAction;
        var latestCanExport = false;
        String? latestView;
        Map<String, dynamic>? latestTable;
        Map<String, dynamic>? latestTableQuery;
        List<String>? latestFollowUps;
        InsightsMenu? latestMenu;
        notifyListeners();
        await for (final event in _api.streamChat(
          endpoint: _apiEndpointForStream(_endpointType),
          message: outboundText,
          groupId: resolvedGroupId,
          days: _days,
          temperature: 0.2,
          maxTokens: 800,
          timeoutMs: _timeoutMs,
          extra: extra,
        )) {
          if (requestGeneration != _generation ||
              assistantIndex >= _messages.length) {
            return InsightsSendOutcome(
              timedOut: false,
              originalText: trimmed,
            );
          }
          final eventAction = extractExportActionMap(event.raw);
          if (eventAction != null) {
            latestExportAction = eventAction;
          }
          latestCanExport = latestCanExport || extractCanExport(event.raw);
          latestView = extractResponseView(event.raw) ?? latestView;
          latestTable = extractStructuredTableMap(event.raw) ?? latestTable;
          latestTableQuery =
              extractTableQueryMap(event.raw) ?? latestTableQuery;
          latestFollowUps = extractFollowUps(event.raw) ?? latestFollowUps;
          if (event.hasTimeout) {
            timedOut = true;
            _lastTimeoutMessage = trimmed;
            _trackTimeout(endpoint: _endpointType, timeoutMs: _timeoutMs);
          }
          final chunk = event.delta.trim();
          final current = _messages[assistantIndex];
          final nextText =
              '${current.text}$chunk${event.hasTimeout ? '\n' : ''}';
          latestMenu = menuForResponse(
                raw: event.raw,
                text: nextText,
                table: latestTable,
              ) ??
              latestMenu;
          if (chunk.isEmpty) {
            _messages[assistantIndex] = current.copyWith(
              isTimeoutFallback: event.hasTimeout || current.isTimeoutFallback,
              canRetry: event.hasTimeout || current.canRetry,
              canExport: latestCanExport || current.canExport,
              retryMessage: event.hasTimeout ? trimmed : current.retryMessage,
              exportAction: latestExportAction ?? current.exportAction,
              view: latestView ?? current.view,
              table: latestTable ?? current.table,
              tableQuery: latestTableQuery ?? current.tableQuery,
              followUps: latestFollowUps ?? current.followUps,
              menu: latestMenu ?? current.menu,
            );
            notifyListeners();
            if (event.hasTimeout) {
              break;
            }
            continue;
          }
          _messages[assistantIndex] = current.copyWith(
            text: nextText,
            isTimeoutFallback: event.hasTimeout || current.isTimeoutFallback,
            canRetry: event.hasTimeout || current.canRetry,
            canExport: latestCanExport || current.canExport,
            retryMessage: event.hasTimeout ? trimmed : current.retryMessage,
            exportAction: latestExportAction ?? current.exportAction,
            view: latestView ?? current.view,
            table: latestTable ?? current.table,
            tableQuery: latestTableQuery ?? current.tableQuery,
            followUps: latestFollowUps ?? current.followUps,
            menu: latestMenu ?? current.menu,
          );
          notifyListeners();
          if (event.hasTimeout) {
            break;
          }
        }
        if (requestGeneration != _generation ||
            assistantIndex >= _messages.length) {
          return InsightsSendOutcome(timedOut: false, originalText: trimmed);
        }
        final current = _messages[assistantIndex];
        if (current.text.trim().isEmpty) {
          final fallbackResponse = await _api.chat(
            endpoint: _apiEndpointForNonStream(_endpointType),
            message: outboundText,
            groupId: resolvedGroupId,
            days: _days,
            temperature: 0.2,
            maxTokens: 800,
            timeoutMs: _timeoutMs,
            extra: extra,
          );
          if (requestGeneration != _generation ||
              assistantIndex >= _messages.length) {
            return InsightsSendOutcome(
              timedOut: false,
              originalText: trimmed,
            );
          }
          final fallbackAction = extractExportActionMap(fallbackResponse.raw);
          final fallbackCanExport = extractCanExport(fallbackResponse.raw);
          final fallbackView = extractResponseView(fallbackResponse.raw);
          final fallbackTable =
              extractStructuredTableMap(fallbackResponse.raw);
          final fallbackTableQuery =
              extractTableQueryMap(fallbackResponse.raw);
          final fallbackFollowUps = extractFollowUps(fallbackResponse.raw);
          final fallbackText = fallbackResponse.text.trim().isEmpty
              ? l.insightsChatNoResponse
              : fallbackResponse.text.trim();
          final fallbackMenu = menuForResponse(
            raw: fallbackResponse.raw,
            text: fallbackText,
            table: fallbackTable,
          );
          _messages[assistantIndex] = current.copyWith(
            text: fallbackText,
            canExport:
                fallbackCanExport || latestCanExport || current.canExport,
            exportAction:
                fallbackAction ?? latestExportAction ?? current.exportAction,
            view: fallbackView ?? latestView ?? current.view,
            table: fallbackTable ?? latestTable ?? current.table,
            tableQuery:
                fallbackTableQuery ?? latestTableQuery ?? current.tableQuery,
            followUps:
                fallbackFollowUps ?? latestFollowUps ?? current.followUps,
            menu: fallbackMenu ?? latestMenu ?? current.menu,
            isTimeoutFallback:
                fallbackResponse.timedOut || current.isTimeoutFallback,
            canRetry: fallbackResponse.timedOut || current.canRetry,
            retryMessage:
                fallbackResponse.timedOut ? trimmed : current.retryMessage,
          );
        } else if (latestCanExport || latestExportAction != null) {
          _messages[assistantIndex] = current.copyWith(
            canExport: latestCanExport || current.canExport,
            exportAction: latestExportAction ?? current.exportAction,
            view: latestView ?? current.view,
            table: latestTable ?? current.table,
            tableQuery: latestTableQuery ?? current.tableQuery,
            followUps: latestFollowUps ?? current.followUps,
            menu: latestMenu ?? current.menu,
          );
        }
        addedAssistant = true;
        notifyListeners();
      }
    } on InsightsApiException catch (e) {
      final isActionDrivenSend = source == InsightsSendSource.followUpButton ||
          source == InsightsSendSource.backButton ||
          looksLikeActionToken(trimmed);
      final shouldRecover = isActionDrivenSend &&
          (e.statusCode == 409 ||
              e.statusCode == 400 ||
              e.statusCode == 502 ||
              e.statusCode == 500 ||
              e.statusCode == 503 ||
              e.code == 'INVALID_MENU_ACTION' ||
              e.code == 'NETWORK_BLOCKED');
      if (shouldRecover) {
        _error = null;
        _messages.add(
          _buildRecoveryMessage(
            isEs: isEs,
            conversationId: activeConversationId,
            error: e,
          ),
        );
        addedAssistant = true;
        notifyListeners();
      } else {
        _error = e.message;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _stopSlowTimer();
      _sending = false;
      if (addedAssistant && !_sheetOpen) {
        _unreadCount += 1;
        _backgroundReplyEvents += 1;
      }
      notifyListeners();
      unawaited(_persistHistory());
    }
    return InsightsSendOutcome(timedOut: timedOut, originalText: trimmed);
  }

  Future<void> retryLastTimedOut({
    required BuildContext context,
    required String groupId,
  }) async {
    final text = (_lastTimeoutMessage ?? _lastUserMessage ?? '').trim();
    if (text.isEmpty) return;
    await send(
      context: context,
      text: text,
      groupId: groupId,
      isRetry: true,
      source: InsightsSendSource.retryAction,
    );
  }

  Future<void> askQuickSummary({
    required BuildContext context,
    required String groupId,
  }) async {
    final prompt = _quickSummaryPrompt(context);
    await send(
      context: context,
      text: prompt,
      groupId: groupId,
      source: InsightsSendSource.newConversationAction,
    );
  }

  Future<InsightsExcelExport> exportExcel({
    required String groupId,
    required String message,
  }) {
    return _api.downloadInsightsExcelFromAction(
      _withScope(
        InsightsExcelExportAction(
          type: 'export_excel',
          endpoint: '/api/insights/chat/export/excel',
          method: 'POST',
          body: <String, dynamic>{
            'groupId': groupId.trim(),
            'message': message.trim(),
          },
          filename: null,
        ),
      ),
    );
  }

  Future<InsightsExcelExport> downloadExcelFromAction(
    InsightsExcelExportAction action,
  ) {
    return _api.downloadInsightsExcelFromAction(_withScope(action));
  }

  Future<Map<String, dynamic>> executeJsonAction(
    Map<String, dynamic> action,
  ) {
    return _api.executeJsonAction(action);
  }

  Future<void> refreshMessageFromSourceAction({
    required ChatMessage message,
    required String groupId,
  }) async {
    final source = message.sourceUserMessage?.trim() ?? '';
    if (source.isEmpty) return;
    final messageIndex = _messages.indexOf(message);
    if (messageIndex < 0) return;
    final response = await _api.chat(
      endpoint: _apiEndpointForNonStream(_endpointType),
      message: source,
      groupId: groupId,
      days: _days,
      temperature: 0.2,
      maxTokens: 800,
      timeoutMs: _timeoutMs,
      extra: <String, dynamic>{
        'conversationId': _conversationId,
        'resetConversation': false,
        ..._scopePayload(),
      },
    );
    final text = response.text.trim().isEmpty
        ? (message.text.trim().isEmpty ? source : message.text)
        : response.text.trim();
    _messages[messageIndex] = message.copyWith(
      text: text,
      table: extractStructuredTableMap(response.raw) ?? message.table,
      tableQuery: extractTableQueryMap(response.raw) ?? message.tableQuery,
      followUps: extractFollowUps(response.raw) ?? message.followUps,
      menu: menuForResponse(
            raw: response.raw,
            text: text,
            table: extractStructuredTableMap(response.raw),
          ) ??
          message.menu,
      view: extractResponseView(response.raw) ?? message.view,
      canExport: extractCanExport(response.raw) || message.canExport,
      exportAction:
          extractExportActionMap(response.raw) ?? message.exportAction,
    );
    notifyListeners();
    await _persistHistory();
  }

  Future<InsightsSendOutcome> previewEventRequest({
    required BuildContext context,
    required String text,
    required String groupId,
    InsightsSendSource source = InsightsSendSource.typedInput,
    String? conversationIdOverride,
    String? displayTextOverride,
  }) async {
    final trimmed = text.trim();
    final resolvedGroupId = groupId.trim();
    if (trimmed.isEmpty || _sending || resolvedGroupId.isEmpty) {
      return InsightsSendOutcome(timedOut: false, originalText: trimmed);
    }
    final l = AppLocalizations.of(context)!;
    final activeConversationId =
        (conversationIdOverride?.trim().isNotEmpty ?? false)
            ? conversationIdOverride!.trim()
            : _conversationId;
    if (activeConversationId != _conversationId) {
      _conversationId = activeConversationId;
    }

    _sending = true;
    _error = null;
    _lastUserMessage = trimmed;
    _lastTimeoutMessage = null;
    _messages.add(
      ChatMessage(
        isUser: true,
        text: trimmed,
        displayText: displayTextOverride,
        timestamp: DateTime.now(),
        conversationId: activeConversationId,
      ),
    );
    notifyListeners();
    unawaited(_persistHistory());

    var addedAssistant = false;
    try {
      final response = await _api.previewChatEvent(
        groupId: resolvedGroupId,
        message: trimmed,
      );
      final textOut =
          (response['message']?.toString().trim().isNotEmpty ?? false)
              ? response['message'].toString().trim()
              : l.insightsChatNoResponse;
      _messages.add(
        ChatMessage(
          isUser: false,
          text: textOut,
          timestamp: DateTime.now(),
          conversationId: activeConversationId,
          sourceUserMessage: trimmed,
          eventAssistant: extractEventAssistantMap(response),
        ),
      );
      addedAssistant = true;
      notifyListeners();
    } on InsightsApiException catch (e) {
      _error = e.message;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _sending = false;
      if (addedAssistant && !_sheetOpen) {
        _unreadCount += 1;
        _backgroundReplyEvents += 1;
      }
      notifyListeners();
      unawaited(_persistHistory());
    }

    return InsightsSendOutcome(timedOut: false, originalText: trimmed);
  }
}
