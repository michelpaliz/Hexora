import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_services/auth_service.dart';
import 'package:hexora/b-backend/insights/insights_api.dart';
import 'package:hexora/c-frontend/routes/appRoutes.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InsightsChatFab extends StatefulWidget {
  const InsightsChatFab({
    super.key,
    required this.groupId,
    this.heroTag = 'insights-chat-fab',
  });

  final String heroTag;
  final String groupId;

  @override
  State<InsightsChatFab> createState() => _InsightsChatFabState();
}

class _InsightsChatFabState extends State<InsightsChatFab> {
  final _runtime = _InsightsChatRuntime.instance;
  int _lastBackgroundEvents = 0;

  @override
  void initState() {
    super.initState();
    _runtime.addListener(_onRuntimeChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    unawaited(_runtime.ensureLoaded(context));
  }

  void _onRuntimeChanged() {
    if (!mounted) return;
    final events = _runtime.backgroundReplyEvents;
    if (events > _lastBackgroundEvents &&
        !_runtime.isSheetOpen &&
        ModalRoute.of(context)?.settings.name == AppRoutes.groupDashboard) {
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.insightsChatAnswerReady)),
      );
    }
    _lastBackgroundEvents = events;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _runtime.removeListener(_onRuntimeChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final routeName = ModalRoute.of(context)?.settings.name;
    if (routeName != AppRoutes.groupDashboard) {
      return const SizedBox.shrink();
    }
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return FloatingActionButton.small(
      heroTag: widget.heroTag,
      tooltip: l.insightsChatFabTooltip,
      onPressed: () => _openSheet(context),
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 180),
        offset: _runtime.sending ? const Offset(0, -0.06) : Offset.zero,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              _runtime.sending
                  ? Icons.hourglass_top_rounded
                  : Icons.auto_awesome_rounded,
            ),
            if (_runtime.unreadCount > 0)
              Positioned(
                right: -8,
                top: -8,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: cs.error,
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _runtime.unreadCount > 9
                        ? '9+'
                        : _runtime.unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InsightsChatSheet(groupId: widget.groupId),
    );
  }
}

class _ChatMessage {
  final bool isUser;
  final String text;
  final DateTime timestamp;
  final bool isTimeoutFallback;
  final bool canRetry;
  final String? retryMessage;

  const _ChatMessage({
    required this.isUser,
    required this.text,
    required this.timestamp,
    this.isTimeoutFallback = false,
    this.canRetry = false,
    this.retryMessage,
  });

  _ChatMessage copyWith({
    bool? isUser,
    String? text,
    DateTime? timestamp,
    bool? isTimeoutFallback,
    bool? canRetry,
    String? retryMessage,
  }) {
    return _ChatMessage(
      isUser: isUser ?? this.isUser,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isTimeoutFallback: isTimeoutFallback ?? this.isTimeoutFallback,
      canRetry: canRetry ?? this.canRetry,
      retryMessage: retryMessage ?? this.retryMessage,
    );
  }

  Map<String, dynamic> toJson() => {
        'isUser': isUser,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
        'isTimeoutFallback': isTimeoutFallback,
        'canRetry': canRetry,
        'retryMessage': retryMessage,
      };

  static _ChatMessage? fromJson(dynamic json) {
    if (json is! Map) return null;
    final isUser = json['isUser'] == true;
    final text = _safeString(json['text']);
    final rawTimestamp = _safeString(json['timestamp']);
    final timestamp = DateTime.tryParse(rawTimestamp);
    final isTimeoutFallback = json['isTimeoutFallback'] == true;
    final canRetry = json['canRetry'] == true;
    final retryMessage = _safeString(json['retryMessage']).trim();
    if (text.trim().isEmpty || timestamp == null) return null;
    return _ChatMessage(
      isUser: isUser,
      text: text,
      timestamp: timestamp,
      isTimeoutFallback: isTimeoutFallback,
      canRetry: canRetry,
      retryMessage: retryMessage.isEmpty ? null : retryMessage,
    );
  }

  static String _safeString(dynamic value) {
    if (value is String) return value;
    if (value is num || value is bool) return value.toString();
    return '';
  }
}

enum _InsightsResponseMode { auto, stream }

enum _InsightsChatEndpointType {
  chat,
  chatAuto,
  chatStream,
  chatAutoStream,
}

class _InsightsSendOutcome {
  final bool timedOut;
  final String originalText;

  const _InsightsSendOutcome({
    required this.timedOut,
    required this.originalText,
  });
}

class _InsightsChatRuntime extends ChangeNotifier {
  _InsightsChatRuntime._();
  static final _InsightsChatRuntime instance = _InsightsChatRuntime._();

  final _api = InsightsApi();
  final _messages = <_ChatMessage>[];
  bool _bootstrapped = false;
  String _historyKey = 'insights_chat_history::anon';
  _InsightsResponseMode _mode = _InsightsResponseMode.auto;
  bool _sending = false;
  String? _error;
  bool _sheetOpen = false;
  int _unreadCount = 0;
  int _backgroundReplyEvents = 0;
  int _days = 90;
  int _timeoutMs = 15000;
  bool _takingTooLong = false;
  Timer? _slowTimer;
  _InsightsChatEndpointType _endpointType = _InsightsChatEndpointType.chatAuto;
  String? _lastUserMessage;
  String? _lastTimeoutMessage;
  int _chatTimeoutCount = 0;

  static const _maxPersistedMessages = 80;

  List<_ChatMessage> get messages => List.unmodifiable(_messages);
  _InsightsResponseMode get mode => _mode;
  bool get sending => _sending;
  String? get error => _error;
  bool get isSheetOpen => _sheetOpen;
  int get unreadCount => _unreadCount;
  int get backgroundReplyEvents => _backgroundReplyEvents;
  int get days => _days;
  int get timeoutMs => _timeoutMs;
  bool get takingTooLong => _takingTooLong;
  _InsightsChatEndpointType get endpointType => _endpointType;
  String? get lastTimeoutMessage => _lastTimeoutMessage;
  int get chatTimeoutCount => _chatTimeoutCount;

  void setMode(_InsightsResponseMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    _endpointType = mode == _InsightsResponseMode.auto
        ? _InsightsChatEndpointType.chatAuto
        : _InsightsChatEndpointType.chatAutoStream;
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

  void setSheetOpen(bool open) {
    if (_sheetOpen == open) return;
    _sheetOpen = open;
    if (open && _unreadCount > 0) {
      _unreadCount = 0;
    }
    notifyListeners();
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
    return 'insights_chat_history::$userId';
  }

  _ChatMessage _welcomeMessage(AppLocalizations l) {
    return _ChatMessage(
      isUser: false,
      text: l.insightsChatWelcome,
      timestamp: DateTime.now(),
    );
  }

  Future<void> ensureLoaded(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final nextHistoryKey = _resolveHistoryKey(context);
    if (_bootstrapped && _historyKey == nextHistoryKey) return;
    _historyKey = nextHistoryKey;
    _bootstrapped = true;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    final next = <_ChatMessage>[];
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            final message = _ChatMessage.fromJson(item);
            if (message != null) next.add(message);
          }
        }
      } catch (_) {}
    }
    _messages
      ..clear()
      ..addAll(next.isEmpty ? [_welcomeMessage(l)] : next);
    notifyListeners();
  }

  Future<void> _persistHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = _messages.length > _maxPersistedMessages
        ? _messages.sublist(_messages.length - _maxPersistedMessages)
        : List<_ChatMessage>.from(_messages);
    final payload = trimmed.map((m) => m.toJson()).toList();
    await prefs.setString(_historyKey, jsonEncode(payload));
  }

  Future<void> clearChat(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    _messages
      ..clear()
      ..add(_welcomeMessage(l));
    _error = null;
    _lastTimeoutMessage = null;
    _unreadCount = 0;
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
    required _InsightsChatEndpointType endpoint,
    required int timeoutMs,
  }) {
    _chatTimeoutCount += 1;
    debugPrint(
      '[insights_telemetry] event=chat_timeout_count endpoint=${endpoint.name} timeoutMs=$timeoutMs count=$_chatTimeoutCount',
    );
  }

  void _trackRetry({
    required _InsightsChatEndpointType endpoint,
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

  InsightsChatEndpoint _apiEndpointForNonStream(_InsightsChatEndpointType type) {
    switch (type) {
      case _InsightsChatEndpointType.chat:
        return InsightsChatEndpoint.chat;
      case _InsightsChatEndpointType.chatAuto:
        return InsightsChatEndpoint.chatAuto;
      case _InsightsChatEndpointType.chatStream:
      case _InsightsChatEndpointType.chatAutoStream:
        return InsightsChatEndpoint.chatAuto;
    }
  }

  InsightsChatEndpoint _apiEndpointForStream(_InsightsChatEndpointType type) {
    switch (type) {
      case _InsightsChatEndpointType.chat:
      case _InsightsChatEndpointType.chatAuto:
        return InsightsChatEndpoint.chatAutoStream;
      case _InsightsChatEndpointType.chatStream:
        return InsightsChatEndpoint.chatStream;
      case _InsightsChatEndpointType.chatAutoStream:
        return InsightsChatEndpoint.chatAutoStream;
    }
  }

  Future<_InsightsSendOutcome> send({
    required BuildContext context,
    required String text,
    required String groupId,
    bool isRetry = false,
  }) async {
    final trimmed = text.trim();
    final resolvedGroupId = groupId.trim();
    if (trimmed.isEmpty || _sending || resolvedGroupId.isEmpty) {
      return _InsightsSendOutcome(timedOut: false, originalText: trimmed);
    }
    final l = AppLocalizations.of(context)!;
    _lastUserMessage = trimmed;
    _lastTimeoutMessage = null;

    _sending = true;
    _error = null;
    _startSlowTimer();
    if (isRetry) {
      _trackRetry(endpoint: _endpointType, timeoutMs: _timeoutMs);
    }
    _messages.add(
      _ChatMessage(isUser: true, text: trimmed, timestamp: DateTime.now()),
    );
    notifyListeners();
    unawaited(_persistHistory());

    var addedAssistant = false;
    var timedOut = false;
    try {
      if (_mode == _InsightsResponseMode.auto) {
        final response = await _api.chat(
          endpoint: _apiEndpointForNonStream(_endpointType),
          message: trimmed,
          groupId: resolvedGroupId,
          days: _days,
          temperature: 0.2,
          maxTokens: 800,
          timeoutMs: _timeoutMs,
        );
        if (response.timedOut) {
          timedOut = true;
          _lastTimeoutMessage = trimmed;
          _trackTimeout(endpoint: _endpointType, timeoutMs: _timeoutMs);
          _messages.add(
            _ChatMessage(
              isUser: false,
              text: response.text.trim().isEmpty
                  ? l.insightsChatNoResponse
                  : response.text.trim(),
              timestamp: DateTime.now(),
              isTimeoutFallback: true,
              canRetry: response.timeout?.canRetry ?? true,
              retryMessage: trimmed,
            ),
          );
        } else {
          final textOut = response.text.trim().isEmpty
              ? l.insightsChatNoResponse
              : response.text.trim();
          _messages.add(
            _ChatMessage(
              isUser: false,
              text: textOut,
              timestamp: DateTime.now(),
            ),
          );
        }
        addedAssistant = true;
        notifyListeners();
      } else {
        _messages.add(
          _ChatMessage(isUser: false, text: '', timestamp: DateTime.now()),
        );
        final assistantIndex = _messages.length - 1;
        notifyListeners();
        await for (final event in _api.streamChat(
          endpoint: _apiEndpointForStream(_endpointType),
          message: trimmed,
          groupId: resolvedGroupId,
          days: _days,
          temperature: 0.2,
          maxTokens: 800,
          timeoutMs: _timeoutMs,
        )) {
          if (event.hasTimeout) {
            timedOut = true;
            _lastTimeoutMessage = trimmed;
            _trackTimeout(endpoint: _endpointType, timeoutMs: _timeoutMs);
          }
          final chunk = event.delta.trim();
          if (chunk.isEmpty) continue;
          final current = _messages[assistantIndex];
          _messages[assistantIndex] = current.copyWith(
            text: '${current.text}$chunk${event.hasTimeout ? '\n' : ''}',
            isTimeoutFallback: event.hasTimeout || current.isTimeoutFallback,
            canRetry: event.hasTimeout || current.canRetry,
            retryMessage: event.hasTimeout ? trimmed : current.retryMessage,
          );
          notifyListeners();
          if (event.hasTimeout) {
            break;
          }
        }
        final current = _messages[assistantIndex];
        if (current.text.trim().isEmpty) {
          _messages[assistantIndex] = current.copyWith(
            text: l.insightsChatNoResponse,
          );
        }
        addedAssistant = true;
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
    return _InsightsSendOutcome(timedOut: timedOut, originalText: trimmed);
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
    );
  }
}

class _InsightsChatSheet extends StatefulWidget {
  const _InsightsChatSheet({required this.groupId});

  final String groupId;

  @override
  State<_InsightsChatSheet> createState() => _InsightsChatSheetState();
}

class _InsightsChatSheetState extends State<_InsightsChatSheet> {
  final _runtime = _InsightsChatRuntime.instance;
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _runtime.addListener(_onRuntimeChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _runtime.setSheetOpen(true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    unawaited(_runtime.ensureLoaded(context));
  }

  void _onRuntimeChanged() {
    if (!mounted) return;
    setState(() {});
    _scrollToBottom();
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _runtime.sending) return;
    _inputCtrl.clear();
    final result = await _runtime.send(
      context: context,
      text: text,
      groupId: widget.groupId,
    );
    if (!mounted) return;
    if (result.timedOut) {
      _inputCtrl.text = result.originalText;
      _inputCtrl.selection = TextSelection.fromPosition(
        TextPosition(offset: _inputCtrl.text.length),
      );
    }
  }

  Future<void> _retryLast() async {
    if (_runtime.sending) return;
    await _runtime.retryLastTimedOut(
      context: context,
      groupId: widget.groupId,
    );
  }

  Future<void> _quickSummary() async {
    if (_runtime.sending) return;
    await _runtime.askQuickSummary(
      context: context,
      groupId: widget.groupId,
    );
  }

  Future<void> _confirmClearChat() async {
    if (_runtime.sending) return;
    final l = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.insightsChatClearTitle),
        content: Text(l.insightsChatClearMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.insightsChatClearAction),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await _runtime.clearChat(context);
    }
  }

  @override
  void dispose() {
    _runtime.setSheetOpen(false);
    _runtime.removeListener(_onRuntimeChanged);
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  List<InlineSpan> _markdownBoldSpans({
    required String text,
    required TextStyle baseStyle,
  }) {
    final sanitized = _sanitizeModelOutput(text);
    final spans = <InlineSpan>[];
    final pattern = RegExp(r'\*\*(.+?)\*\*');
    var lastEnd = 0;

    for (final match in pattern.allMatches(sanitized)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: sanitized.substring(lastEnd, match.start),
          style: baseStyle,
        ));
      }
      final boldText = match.group(1) ?? '';
      if (boldText.isNotEmpty) {
        spans.add(TextSpan(
          text: boldText,
          style: baseStyle.copyWith(fontWeight: FontWeight.w800),
        ));
      }
      lastEnd = match.end;
    }

    if (lastEnd < sanitized.length) {
      spans.add(TextSpan(
        text: sanitized.substring(lastEnd),
        style: baseStyle,
      ));
    }

    if (spans.isEmpty) {
      spans.add(TextSpan(text: sanitized, style: baseStyle));
    }
    return spans;
  }

  String _sanitizeModelOutput(String input) {
    var out = input;
    out = out.replaceAllMapped(
      RegExp(r'^\s{0,3}#{1,6}\s+', multiLine: true),
      (_) => '',
    );
    out = out.replaceAllMapped(
      RegExp(r'\\frac\{([^}]*)\}\{([^}]*)\}'),
      (m) {
        final num = (m.group(1) ?? '').trim();
        final den = (m.group(2) ?? '').trim();
        if (num.isEmpty && den.isEmpty) return '';
        if (den.isEmpty) return num;
        if (num.isEmpty) return den;
        return '$num / $den';
      },
    );
    out = out.replaceAllMapped(
      RegExp(r'\\text\{([^}]*)\}'),
      (m) => m.group(1) ?? '',
    );
    out = out.replaceAllMapped(
      RegExp(r'\^\{([^}]*)\}'),
      (m) => '^${(m.group(1) ?? '').trim()}',
    );
    out = out.replaceAllMapped(
      RegExp(r'_\{([^}]*)\}'),
      (m) => '_${(m.group(1) ?? '').trim()}',
    );
    out = out.replaceAll(r'\times', ' x ');
    out = out.replaceAll(r'\cdot', ' * ');
    out = out.replaceAllMapped(
      RegExp(r'\\([a-zA-Z]+)'),
      (m) => m.group(1) ?? '',
    );
    out = out.replaceAll('\\[', '');
    out = out.replaceAll('\\]', '');
    out = out.replaceAll('\\(', '');
    out = out.replaceAll('\\)', '');
    out = out.replaceAll('\\%', '%');
    out = out.replaceAll(r'\$', '\$');
    out = out.replaceAll('\\_', '_');
    out = out.replaceAll('\\{', '{');
    out = out.replaceAll('\\}', '}');
    out = out.replaceAll('\\,', ',');
    out = out.replaceAll('\\.', '.');
    out = out.replaceAll('\\;', ';');
    out = out.replaceAll('\\:', ':');
    out = out.replaceAllMapped(
      RegExp(r'(?<=\b[A-Za-zÁÉÍÓÚÑáéíóúñ]+):(?=\S)'),
      (_) => ': ',
    );
    out = out.replaceAllMapped(
      RegExp(r'(EUR|USD|GBP|€|\$)(?=[A-Za-zÁÉÍÓÚÑáéíóúñ])'),
      (m) => '${m.group(1)} ',
    );
    out = out.replaceAllMapped(
      RegExp(
        r'\b(de|del|al|el|la|los|las|total|suma|asciende|ascendio)(?=\d)',
        caseSensitive: false,
      ),
      (m) => '${m.group(1)} ',
    );
    out = out.replaceAll(RegExp(r'[ ]{2,}'), ' ');
    out = out.replaceAll(RegExp(r'[ \t]+\n'), '\n');
    out = out.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return out.trim();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final canvas = Theme.of(context).canvasColor;
    final t = AppTypography.of(context);
    final l = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final messages = _runtime.messages;
    final mode = _runtime.mode;
    final sending = _runtime.sending;
    final error = _runtime.error;
    final days = _runtime.days;
    final takingTooLong = _runtime.takingTooLong;
    final showTimeoutActions = _runtime.lastTimeoutMessage != null && !sending;
    final isEs =
        Localizations.localeOf(context).languageCode.toLowerCase().startsWith('es');
    final takingTooLongText = isEs
        ? 'Tardando mas de lo esperado...'
        : 'Taking longer than expected...';
    final retryText = isEs ? 'Reintentar' : 'Retry';
    final quickSummaryText = isEs ? 'Resumen rapido' : 'Quick summary';

    return Container(
      height: MediaQuery.of(context).size.height * 0.84,
      decoration: BoxDecoration(
        color: canvas,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(12, 6, 12, 10 + bottomInset),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.insights_outlined, color: cs.primary, size: 15),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.insightsChatTitle,
                      style: t.bodySmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l.insightsChatClearTooltip,
                    onPressed: sending ? null : _confirmClearChat,
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    PopupMenuButton<int>(
                      tooltip: l.insightsChatDaysTooltip,
                      onSelected: _runtime.setDays,
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 30, child: Text('30d')),
                        PopupMenuItem(value: 60, child: Text('60d')),
                        PopupMenuItem(value: 90, child: Text('90d')),
                        PopupMenuItem(value: 120, child: Text('120d')),
                        PopupMenuItem(value: 180, child: Text('180d')),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: canvas,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: cs.outlineVariant.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Text(
                          '${l.insightsChatDaysPrefix}: ${days}d',
                          style: t.bodySmall.copyWith(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: Text(l.insightsChatModeAuto),
                      selected: mode == _InsightsResponseMode.auto,
                      selectedColor: cs.primaryContainer,
                      backgroundColor: canvas,
                      visualDensity: VisualDensity.compact,
                      labelStyle: t.bodySmall.copyWith(
                        fontSize: 11,
                        color: mode == _InsightsResponseMode.auto
                            ? cs.onPrimaryContainer
                            : cs.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                      side: BorderSide(
                        color: cs.outlineVariant.withValues(alpha: 0.6),
                      ),
                      onSelected: sending
                          ? null
                          : (_) => _runtime.setMode(_InsightsResponseMode.auto),
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: Text(l.insightsChatModeStream),
                      selected: mode == _InsightsResponseMode.stream,
                      selectedColor: cs.primaryContainer,
                      backgroundColor: canvas,
                      visualDensity: VisualDensity.compact,
                      labelStyle: t.bodySmall.copyWith(
                        fontSize: 11,
                        color: mode == _InsightsResponseMode.stream
                            ? cs.onPrimaryContainer
                            : cs.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                      side: BorderSide(
                        color: cs.outlineVariant.withValues(alpha: 0.6),
                      ),
                      onSelected: sending
                          ? null
                          : (_) => _runtime.setMode(_InsightsResponseMode.stream),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                  itemCount: messages.length +
                      (sending && mode == _InsightsResponseMode.auto ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (sending && index == messages.length) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: canvas,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: cs.outlineVariant.withValues(alpha: 0.55),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              if (takingTooLong) ...[
                                const SizedBox(width: 8),
                                Text(
                                  takingTooLongText,
                                  style: t.bodySmall.copyWith(
                                    color: cs.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }
                    final message = messages[index];
                    return _ChatBubble(
                      message: message,
                      markdownBoldSpans: _markdownBoldSpans,
                    );
                  },
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    error,
                    style: t.bodySmall.copyWith(
                      color: cs.error,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
              if (showTimeoutActions) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _retryLast,
                        icon: const Icon(Icons.refresh_rounded, size: 15),
                        label: Text(
                          retryText,
                          style: t.bodySmall.copyWith(fontSize: 11),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: _quickSummary,
                        icon: const Icon(Icons.summarize_outlined, size: 15),
                        label: Text(
                          quickSummaryText,
                          style: t.bodySmall.copyWith(fontSize: 11),
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      enabled: !sending,
                      minLines: 1,
                      maxLines: 3,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: l.insightsChatInputHint,
                        filled: true,
                        fillColor: canvas,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        hintStyle: t.bodySmall.copyWith(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: cs.outlineVariant.withValues(alpha: 0.8),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: cs.outlineVariant.withValues(alpha: 0.8),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: cs.primary.withValues(alpha: 0.95),
                            width: 1.5,
                          ),
                        ),
                        isDense: true,
                      ),
                      style: t.bodySmall.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    height: 36,
                    child: FilledButton(
                      onPressed: sending ? null : _send,
                      style: FilledButton.styleFrom(
                        foregroundColor: cs.onPrimary,
                        backgroundColor: cs.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        disabledForegroundColor:
                            cs.onPrimary.withValues(alpha: 0.72),
                        disabledBackgroundColor:
                            cs.primary.withValues(alpha: 0.58),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.send_rounded, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            l.insightsChatSend,
                            style: t.bodySmall.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatefulWidget {
  const _ChatBubble({
    required this.message,
    required this.markdownBoldSpans,
  });

  final _ChatMessage message;
  final List<InlineSpan> Function({
    required String text,
    required TextStyle baseStyle,
  }) markdownBoldSpans;

  @override
  State<_ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<_ChatBubble> {
  bool _hovering = false;
  bool _copied = false;

  void _copyText() {
    Clipboard.setData(ClipboardData(text: widget.message.text));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final message = widget.message;
    final isUser = message.isUser;
    final align = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final bg = isUser ? cs.primary : cs.surfaceContainerLow;
    final fg = isUser ? cs.onPrimary : cs.onSurface;

    return Align(
      alignment: align,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment:
                isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isUser
                        ? cs.primary.withValues(alpha: 0.7)
                        : cs.outlineVariant.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isUser
                          ? Icons.person_rounded
                          : Icons.auto_awesome_rounded,
                      size: 13,
                      color: fg.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: RichText(
                        text: TextSpan(
                          children: widget.markdownBoldSpans(
                            text: message.text,
                            baseStyle: t.bodySmall.copyWith(
                              color: fg,
                              height: 1.35,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Action row: copy button appears on hover or after tap
              AnimatedSize(
                duration: const Duration(milliseconds: 150),
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: (_hovering || _copied)
                    ? Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _BubbleActionButton(
                              icon: _copied
                                  ? Icons.check_rounded
                                  : Icons.copy_rounded,
                              tooltip: _copied ? 'Copiado' : 'Copiar',
                              onTap: _copied ? null : _copyText,
                              color: _copied
                                  ? cs.primary
                                  : cs.onSurfaceVariant.withValues(alpha: 0.7),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BubbleActionButton extends StatelessWidget {
  const _BubbleActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 14, color: color),
        ),
      ),
    );
  }
}
