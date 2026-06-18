import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/group_model/service/service.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_services/auth_service.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/service/service_api_client.dart';
import 'package:hexora/b-backend/group_mng_flow/event/domain/event_domain.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/client/client_api.dart';
import 'package:hexora/b-backend/insights/insights_api.dart';
import 'package:hexora/b-backend/invoicing/invoice_api.dart';
import 'package:hexora/b-backend/statements/statements_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/enable_banking/statements/statements_controller.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/enable_banking/statements/statements_shared.dart';
import 'package:hexora/c-frontend/routes/appRoutes.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/pdf_preview/file_download_launcher.dart';
import 'package:hexora/c-frontend/ui-app/shared/downloads/download_jobs_store.dart';
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
  late final _InsightsChatRuntime _runtime;
  int _lastBackgroundEvents = 0;

  @override
  void initState() {
    super.initState();
    _runtime = _InsightsChatRuntime.instanceFor('fab::${widget.groupId}');
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
                  constraints:
                      const BoxConstraints(minWidth: 18, minHeight: 18),
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
      builder: (_) => _InsightsChatSheet(
        groupId: widget.groupId,
        runtime: _runtime,
      ),
    );
  }
}

class InsightsChatPanel extends StatelessWidget {
  const InsightsChatPanel({
    super.key,
    required this.groupId,
  });

  final String groupId;

  @override
  Widget build(BuildContext context) {
    return _InsightsChatSheet(
      groupId: groupId,
      embedded: true,
      runtime: _InsightsChatRuntime.instanceFor('panel::$groupId'),
    );
  }
}

class _ChatMessage {
  final bool isUser;
  final String text;
  final String? displayText;
  final DateTime timestamp;
  final String? conversationId;
  final bool isTimeoutFallback;
  final bool canRetry;
  final bool canExport;
  final String? retryMessage;
  final String? sourceUserMessage;
  final Map<String, dynamic>? exportAction;
  final String? view;
  final Map<String, dynamic>? table;
  final List<String>? followUps;
  final _InsightsMenu? menu;
  final Map<String, dynamic>? eventAssistant;

  const _ChatMessage({
    required this.isUser,
    required this.text,
    this.displayText,
    required this.timestamp,
    this.conversationId,
    this.isTimeoutFallback = false,
    this.canRetry = false,
    this.canExport = false,
    this.retryMessage,
    this.sourceUserMessage,
    this.exportAction,
    this.view,
    this.table,
    this.followUps,
    this.menu,
    this.eventAssistant,
  });

  _ChatMessage copyWith({
    bool? isUser,
    String? text,
    String? displayText,
    DateTime? timestamp,
    String? conversationId,
    bool? isTimeoutFallback,
    bool? canRetry,
    bool? canExport,
    String? retryMessage,
    String? sourceUserMessage,
    Map<String, dynamic>? exportAction,
    String? view,
    Map<String, dynamic>? table,
    List<String>? followUps,
    _InsightsMenu? menu,
    Map<String, dynamic>? eventAssistant,
  }) {
    return _ChatMessage(
      isUser: isUser ?? this.isUser,
      text: text ?? this.text,
      displayText: displayText ?? this.displayText,
      timestamp: timestamp ?? this.timestamp,
      conversationId: conversationId ?? this.conversationId,
      isTimeoutFallback: isTimeoutFallback ?? this.isTimeoutFallback,
      canRetry: canRetry ?? this.canRetry,
      canExport: canExport ?? this.canExport,
      retryMessage: retryMessage ?? this.retryMessage,
      sourceUserMessage: sourceUserMessage ?? this.sourceUserMessage,
      exportAction: exportAction ?? this.exportAction,
      view: view ?? this.view,
      table: table ?? this.table,
      followUps: followUps ?? this.followUps,
      menu: menu ?? this.menu,
      eventAssistant: eventAssistant ?? this.eventAssistant,
    );
  }

  Map<String, dynamic> toJson() => {
        'isUser': isUser,
        'text': text,
        'displayText': displayText,
        'timestamp': timestamp.toIso8601String(),
        'conversationId': conversationId,
        'isTimeoutFallback': isTimeoutFallback,
        'canRetry': canRetry,
        'canExport': canExport,
        'retryMessage': retryMessage,
        'sourceUserMessage': sourceUserMessage,
        'exportAction': exportAction,
        'view': view,
        'table': table,
        'followUps': followUps,
        'menu': menu?.toJson(),
        'eventAssistant': eventAssistant,
      };

  static _ChatMessage? fromJson(dynamic json) {
    if (json is! Map) return null;
    final isUser = json['isUser'] == true;
    final text = _safeString(json['text']);
    final displayText = _safeString(json['displayText']).trim();
    final rawTimestamp = _safeString(json['timestamp']);
    final conversationId = _safeString(json['conversationId']).trim();
    final timestamp = DateTime.tryParse(rawTimestamp);
    final isTimeoutFallback = json['isTimeoutFallback'] == true;
    final canRetry = json['canRetry'] == true;
    final canExport = json['canExport'] == true;
    final retryMessage = _safeString(json['retryMessage']).trim();
    final sourceUserMessage = _safeString(json['sourceUserMessage']).trim();
    final exportAction = _safeMap(json['exportAction']);
    final view = _safeString(json['view']).trim();
    final table = _safeMap(json['table']);
    final followUps = _safeStringList(json['followUps']);
    final menu = _InsightsMenu.fromDynamic(json['menu']);
    final eventAssistant = _safeMap(json['eventAssistant']);
    if (text.trim().isEmpty || timestamp == null) return null;
    return _ChatMessage(
      isUser: isUser,
      text: text,
      displayText: displayText.isEmpty ? null : displayText,
      timestamp: timestamp,
      conversationId: conversationId.isEmpty ? null : conversationId,
      isTimeoutFallback: isTimeoutFallback,
      canRetry: canRetry,
      canExport: canExport,
      retryMessage: retryMessage.isEmpty ? null : retryMessage,
      sourceUserMessage: sourceUserMessage.isEmpty ? null : sourceUserMessage,
      exportAction: exportAction,
      view: view.isEmpty ? null : view,
      table: table,
      followUps: followUps,
      menu: menu,
      eventAssistant: eventAssistant,
    );
  }

  static String _safeString(dynamic value) {
    if (value is String) return value;
    if (value is num || value is bool) return value.toString();
    return '';
  }

  static Map<String, dynamic>? _safeMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  static List<String>? _safeStringList(dynamic value) {
    if (value is! List) return null;
    final items = value
        .map((item) => _safeString(item).trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    return items.isEmpty ? null : items;
  }
}

class _InsightsMenuOption {
  const _InsightsMenuOption({
    required this.index,
    required this.label,
    this.action,
  });

  final int index;
  final String label;
  final String? action;

  Map<String, dynamic> toJson() => {
        'index': index,
        'label': label,
        'action': action,
      };

  static _InsightsMenuOption? fromDynamic(dynamic raw) {
    if (raw is String) {
      final label = raw.trim();
      if (label.isEmpty) return null;
      return _InsightsMenuOption(index: 0, label: label);
    }
    final map = _safeMap(raw);
    if (map == null) return null;
    final index = _readInt(map['index']) ??
        _readInt(map['number']) ??
        _readInt(map['key']) ??
        _readInt(map['id']);
    final label = (map['label']?.toString() ??
            map['text']?.toString() ??
            map['title']?.toString() ??
            map['name']?.toString() ??
            '')
        .trim();
    final action = (map['action']?.toString() ??
            map['token']?.toString() ??
            map['value']?.toString() ??
            '')
        .trim();
    if (index == null || label.isEmpty) return null;
    return _InsightsMenuOption(
      index: index,
      label: label,
      action: action.isEmpty ? null : action,
    );
  }
}

class _InsightsMenu {
  const _InsightsMenu({
    required this.id,
    required this.parentId,
    required this.backAction,
    required this.title,
    required this.options,
  });

  final String? id;
  final String? parentId;
  final String? backAction;
  final String? title;
  final List<_InsightsMenuOption> options;

  bool get hasOptions => options.isNotEmpty;
  bool get hasBackAction => (backAction?.trim().isNotEmpty ?? false);

  Map<String, dynamic> toJson() => {
        'id': id,
        'parentId': parentId,
        'backAction': backAction,
        'title': title,
        'options': options.map((option) => option.toJson()).toList(),
      };

  static List<_InsightsMenuOption> _optionsFromDynamic(dynamic raw) {
    if (raw is List) {
      return raw
          .map(_InsightsMenuOption.fromDynamic)
          .whereType<_InsightsMenuOption>()
          .toList(growable: false);
    }

    final map = _safeMap(raw);
    if (map == null || map.isEmpty) return const <_InsightsMenuOption>[];

    final sortable = <MapEntry<int, _InsightsMenuOption>>[];
    map.forEach((key, value) {
      final index = _readInt(key);
      if (index == null) return;
      if (value is String) {
        final label = value.trim();
        if (label.isEmpty) return;
        sortable.add(
          MapEntry(index, _InsightsMenuOption(index: index, label: label)),
        );
        return;
      }
      final item = _safeMap(value);
      if (item == null) return;
      final enriched = <String, dynamic>{'index': index, ...item};
      final option = _InsightsMenuOption.fromDynamic(enriched);
      if (option != null) {
        sortable.add(MapEntry(index, option));
      }
    });

    sortable.sort((a, b) => a.key.compareTo(b.key));
    return sortable.map((entry) => entry.value).toList(growable: false);
  }

  static _InsightsMenu? fromDynamic(dynamic raw) {
    final map = _safeMap(raw);
    if (map == null || map.isEmpty) return null;
    final metadata = _safeMap(map['metadata']) ?? const <String, dynamic>{};
    final directOptions = _optionsFromDynamic(map['options']);
    final optionMapOptions = _optionsFromDynamic(map['optionMap']);
    final optionMapSnakeOptions = _optionsFromDynamic(map['option_map']);
    final options = directOptions.isNotEmpty
        ? directOptions
        : optionMapOptions.isNotEmpty
            ? optionMapOptions
            : optionMapSnakeOptions;
    final id = (map['id']?.toString() ??
            map['menuId']?.toString() ??
            map['menu_id']?.toString() ??
            metadata['id']?.toString() ??
            metadata['menuId']?.toString() ??
            '')
        .trim();
    final parentId = (map['parentId']?.toString() ??
            map['parent_id']?.toString() ??
            metadata['parentId']?.toString() ??
            metadata['parent_id']?.toString() ??
            '')
        .trim();
    final backAction = (map['backAction']?.toString() ??
            map['back_action']?.toString() ??
            metadata['backAction']?.toString() ??
            metadata['back_action']?.toString() ??
            '')
        .trim();
    final title = (map['title']?.toString() ??
            metadata['title']?.toString() ??
            metadata['label']?.toString() ??
            '')
        .trim();
    if (id.isEmpty &&
        parentId.isEmpty &&
        backAction.isEmpty &&
        title.isEmpty &&
        options.isEmpty) {
      return null;
    }
    return _InsightsMenu(
      id: id.isEmpty ? null : id,
      parentId: parentId.isEmpty ? null : parentId,
      backAction: backAction.isEmpty ? null : backAction,
      title: title.isEmpty ? null : title,
      options: options,
    );
  }
}

Map<String, dynamic>? _safeMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return null;
}

Map<String, dynamic>? _extractExportActionMap(dynamic raw) {
  final map = _safeMap(raw);
  if (map == null || map.isEmpty) return null;
  final directRaw = _safeMap(map['exportAction']);
  if (directRaw != null) {
    final direct = InsightsExcelExportAction.fromDynamic(directRaw);
    if (direct == null) return _extractExportActionMap(map['data']);
    return <String, dynamic>{
      'type': direct.type,
      'endpoint': direct.endpoint,
      'method': direct.method,
      'body': direct.body,
      'filename': direct.filename,
    };
  }
  return _extractExportActionMap(map['data']);
}

bool _extractCanExport(dynamic raw) {
  final map = _safeMap(raw);
  if (map == null || map.isEmpty) return false;
  final rawFlag = map['canExport'];
  if (rawFlag == true || rawFlag?.toString().toLowerCase() == 'true') {
    return true;
  }
  return _extractCanExport(map['data']);
}

String? _extractResponseView(dynamic raw) {
  final map = _safeMap(raw);
  if (map == null || map.isEmpty) return null;
  final direct = map['view']?.toString().trim();
  if (direct != null && direct.isNotEmpty) return direct;
  return _extractResponseView(map['data']);
}

int? _readInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

bool _isFiniteNum(dynamic value) {
  return value is num && value.isFinite;
}

// ignore: unused_element
bool _isExportPlaceholderText(String text) {
  final normalized = text.trim().toLowerCase();
  if (normalized.isEmpty) return false;
  return normalized.contains('usa esta accion para descargarlo') ||
      normalized.contains('usa esta acción para descargarlo') ||
      normalized.contains('use this action to download it');
}

bool _looksLikeActionToken(String text) {
  final trimmed = text.trim();
  return trimmed.startsWith('__menu__:') || trimmed.startsWith('__back__:');
}

const String _incomeInvoicesByAmountAction =
    '__menu__:category_income:facturas_por_importe';

bool _isIncomeInvoicesByAmountAction(String? text) {
  return (text ?? '').trim() == _incomeInvoicesByAmountAction;
}

bool _looksLikeExcelExportOption(String text) {
  final normalized = text.trim().toLowerCase();
  if (normalized.isEmpty) return false;
  return normalized.contains('export') ||
      normalized.contains('excel') ||
      normalized.contains('descargar');
}

bool _isExcelExportMenuOption(_InsightsMenuOption option) {
  final action = option.action?.trim().toLowerCase() ?? '';
  return action.contains(':export') ||
      action.contains('export_excel') ||
      _looksLikeExcelExportOption(option.label);
}

Map<String, dynamic>? _extractStructuredTableMap(dynamic raw) {
  final map = _safeMap(raw);
  if (map == null || map.isEmpty) return null;
  if (map['columns'] is List && map['rows'] is List) return map;
  final table = _safeMap(map['table']);
  if (table != null) return table;
  return _extractStructuredTableMap(map['data']);
}

List<String>? _extractFollowUps(dynamic raw) {
  final map = _safeMap(raw);
  if (map == null || map.isEmpty) return null;
  final value = map['followUps'];
  if (value is List) {
    final items = value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    if (items.isNotEmpty) return items;
  }
  return _extractFollowUps(map['data']);
}

Map<String, dynamic>? _extractEventAssistantMap(dynamic raw) {
  final map = _safeMap(raw);
  if (map == null || map.isEmpty) return null;
  final direct = _safeMap(map['eventAssistant']);
  if (direct != null && direct.isNotEmpty) return direct;
  return _extractEventAssistantMap(map['data']);
}

bool _messageHasEventAssistant(_ChatMessage message) {
  return message.eventAssistant != null && message.eventAssistant!.isNotEmpty;
}

Map<String, dynamic> _cloneJsonMap(Map<String, dynamic> input) {
  final cloned = jsonDecode(jsonEncode(input));
  if (cloned is Map<String, dynamic>) return cloned;
  if (cloned is Map) {
    return cloned.map((key, value) => MapEntry(key.toString(), value));
  }
  return <String, dynamic>{};
}

_InsightsMenu? _extractMenu(dynamic raw) {
  final map = _safeMap(raw);
  if (map == null || map.isEmpty) return null;
  final direct = _InsightsMenu.fromDynamic(map['menu']);
  if (direct != null) return direct;
  final inline = _InsightsMenu.fromDynamic(map);
  if (inline != null) return inline;
  return _extractMenu(map['data']);
}

_InsightsMenu? _fallbackMenuFromText(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return null;
  final lines = trimmed
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList(growable: false);
  if (lines.length < 2) return null;

  final options = <_InsightsMenuOption>[];
  for (final line in lines) {
    final match = RegExp(r'^(\d+)[\)\.\-:]\s*(.+)$').firstMatch(line);
    if (match == null) continue;
    final index = int.tryParse(match.group(1) ?? '');
    final label = (match.group(2) ?? '').trim();
    if (index == null || label.isEmpty) continue;
    options.add(_InsightsMenuOption(index: index, label: label));
  }
  if (options.isEmpty) return null;

  final titleLines = lines
      .where((line) => !RegExp(r'^\d+[\)\.\-:]\s*').hasMatch(line))
      .toList(growable: false);

  return _InsightsMenu(
    id: null,
    parentId: null,
    backAction: null,
    title: titleLines.isEmpty ? null : titleLines.first,
    options: options,
  );
}

_InsightsMenu? _menuForResponse({
  required dynamic raw,
  required String text,
  Map<String, dynamic>? table,
}) {
  final directMenu = _extractMenu(raw);
  if (directMenu != null) return directMenu;
  if (table != null && table.isNotEmpty) return null;
  return _fallbackMenuFromText(text);
}

InsightsExcelExportAction? _getExportActionFromMessage(_ChatMessage message) {
  if (message.canExport != true) return null;
  return InsightsExcelExportAction.fromDynamic(message.exportAction);
}

bool _messageHasMenu(_ChatMessage message) =>
    message.menu?.hasOptions == true || message.menu?.hasBackAction == true;

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

enum _InsightsSendSource {
  typedInput,
  followUpButton,
  backButton,
  newConversationAction,
  retryAction,
}

class _InsightsChatRuntime extends ChangeNotifier {
  _InsightsChatRuntime._(this.scopeKey);
  static final Map<String, _InsightsChatRuntime> _instances = {};

  static _InsightsChatRuntime instanceFor(String scopeKey) {
    return _instances.putIfAbsent(
      scopeKey,
      () => _InsightsChatRuntime._(scopeKey),
    );
  }

  final String scopeKey;
  final _api = InsightsApi();
  final _messages = <_ChatMessage>[];
  int _generation = 0;
  String _conversationId = _newConversationId();
  bool _resetConversationOnNextSend = false;
  bool _bootstrapped = false;
  late String _historyKey = 'insights_chat_history::anon::$scopeKey';
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

  static String _newConversationId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }

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
    final next = <_ChatMessage>[];
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            final message = _ChatMessage.fromJson(item);
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
              final message = _ChatMessage.fromJson(item);
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
        : List<_ChatMessage>.from(_messages);
    final payload = <String, dynamic>{
      'conversationId': _conversationId,
      'resetConversationOnNextSend': _resetConversationOnNextSend,
      'messages': trimmed.map((m) => m.toJson()).toList(),
    };
    await prefs.setString(_historyKey, jsonEncode(payload));
  }

  Future<void> updateTableRow({
    required _ChatMessage message,
    required String entryId,
    required Map<String, dynamic> rowPatch,
  }) async {
    await updateTableRows(
      message: message,
      patchesByEntryId: {entryId: rowPatch},
    );
  }

  Future<void> updateTableRows({
    required _ChatMessage message,
    required Map<String, Map<String, dynamic>> patchesByEntryId,
  }) async {
    if (patchesByEntryId.isEmpty) return;
    final messageIndex = _messages.indexOf(message);
    if (messageIndex < 0) return;
    final table = _safeMap(message.table);
    final rows = table?['rows'];
    if (table == null || rows is! List) return;

    final nextRows = rows.map((item) {
      final row = _safeMap(item);
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
    _ChatMessage previous,
    _ChatMessage next,
  ) async {
    final index = _messages.indexOf(previous);
    if (index < 0) return;
    _messages[index] = next;
    notifyListeners();
    await _persistHistory();
  }

  Future<void> appendMessage(_ChatMessage message) async {
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

  // ignore: unused_element
  Future<void> _autoDownloadExportAction(
    InsightsExcelExportAction action,
  ) async {
    debugPrint(
      '[insights_export_auto] endpoint=${action.endpoint} '
      'method=${action.method} body=${jsonEncode(action.body)}',
    );
    final export = await _api.downloadInsightsExcelFromAction(action);
    debugPrint(
      '[insights_export_auto] contentType=${export.mimeType} '
      'size=${export.bytes.lengthInBytes} filename=${export.fileName}',
    );
    await launchFileDownload(
      export.bytes,
      fileName: export.fileName,
      mimeType: export.mimeType,
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

  _InsightsMenu _defaultRootMenu(bool isEs) {
    return _InsightsMenu(
      id: 'guided_root',
      parentId: null,
      backAction: null,
      title: isEs ? 'Areas' : 'Areas',
      options: <_InsightsMenuOption>[
        _InsightsMenuOption(
          index: 1,
          label: isEs ? 'Ingresos' : 'Revenue',
        ),
        _InsightsMenuOption(
          index: 2,
          label: isEs ? 'Gastos' : 'Expenses',
        ),
        _InsightsMenuOption(
          index: 3,
          label: isEs ? 'Facturas' : 'Invoices',
        ),
        _InsightsMenuOption(
          index: 4,
          label: isEs ? 'Clientes' : 'Clients',
        ),
      ],
    );
  }

  _ChatMessage _buildRecoveryMessage({
    required bool isEs,
    required String conversationId,
    required InsightsApiException error,
  }) {
    final isInvalidMenu =
        error.code == 'INVALID_MENU_ACTION' || error.statusCode == 409;
    final text = isInvalidMenu
        ? (isEs
            ? 'Esa opcion ya no es valida para esta conversacion. Vamos a empezar de nuevo.'
            : 'That option is no longer valid for this conversation. Let\'s start again.')
        : (isEs
            ? 'No pude completar esa accion ahora mismo. Elige un area para continuar.'
            : 'I could not complete that action right now. Choose an area to continue.');
    return _ChatMessage(
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
      _InsightsChatEndpointType type) {
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
    _InsightsSendSource source = _InsightsSendSource.typedInput,
    String? conversationIdOverride,
    String? displayTextOverride,
  }) async {
    final trimmed = text.trim();
    final resolvedGroupId = groupId.trim();
    if (trimmed.isEmpty || _sending || resolvedGroupId.isEmpty) {
      return _InsightsSendOutcome(timedOut: false, originalText: trimmed);
    }
    final l = AppLocalizations.of(context)!;
    final isEs = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('es');
    final requestGeneration = _generation;
    final starterLabel =
        _messages.isEmpty ? _starterOptionLabel(context, trimmed) : null;
    final isFollowUpLike = source == _InsightsSendSource.followUpButton ||
        source == _InsightsSendSource.backButton;
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
    };
    if (shouldResetConversation) {
      _resetConversationOnNextSend = false;
    }
    debugPrint(
      '[insights_send] source=${source.name} '
      'message=${jsonEncode(trimmed)} '
      'conversationId=$activeConversationId '
      'resetConversation=$shouldResetConversation',
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
      _ChatMessage(
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
      if (_mode == _InsightsResponseMode.auto) {
        final response = await _api.chat(
          endpoint: _apiEndpointForNonStream(_endpointType),
          message: outboundText,
          groupId: resolvedGroupId,
          days: _days,
          temperature: 0.2,
          maxTokens: 800,
          timeoutMs: _timeoutMs,
          extra: extra,
        );
        if (requestGeneration != _generation) {
          return _InsightsSendOutcome(timedOut: false, originalText: trimmed);
        }
        final exportAction = _extractExportActionMap(response.raw);
        final canExport = _extractCanExport(response.raw);
        final responseView = _extractResponseView(response.raw);
        final responseTable = _extractStructuredTableMap(response.raw);
        final responseFollowUps = _extractFollowUps(response.raw);
        final responseMenu = _menuForResponse(
          raw: response.raw,
          text: response.text,
          table: responseTable,
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
              conversationId: activeConversationId,
              isTimeoutFallback: true,
              canRetry: response.timeout?.canRetry ?? true,
              canExport: canExport,
              retryMessage: trimmed,
              sourceUserMessage: trimmed,
              exportAction: exportAction,
              view: responseView,
              table: responseTable,
              followUps: responseFollowUps,
              menu: responseMenu,
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
              conversationId: activeConversationId,
              canExport: canExport,
              sourceUserMessage: trimmed,
              exportAction: exportAction,
              view: responseView,
              table: responseTable,
              followUps: responseFollowUps,
              menu: responseMenu,
            ),
          );
        }
        addedAssistant = !(_messages.isNotEmpty && _messages.last.isUser);
        notifyListeners();
      } else {
        _messages.add(
          _ChatMessage(
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
        List<String>? latestFollowUps;
        _InsightsMenu? latestMenu;
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
            return _InsightsSendOutcome(
              timedOut: false,
              originalText: trimmed,
            );
          }
          final eventAction = _extractExportActionMap(event.raw);
          if (eventAction != null) {
            latestExportAction = eventAction;
          }
          latestCanExport = latestCanExport || _extractCanExport(event.raw);
          latestView = _extractResponseView(event.raw) ?? latestView;
          latestTable = _extractStructuredTableMap(event.raw) ?? latestTable;
          latestFollowUps = _extractFollowUps(event.raw) ?? latestFollowUps;
          if (event.hasTimeout) {
            timedOut = true;
            _lastTimeoutMessage = trimmed;
            _trackTimeout(endpoint: _endpointType, timeoutMs: _timeoutMs);
          }
          final chunk = event.delta.trim();
          final current = _messages[assistantIndex];
          final nextText =
              '${current.text}$chunk${event.hasTimeout ? '\n' : ''}';
          latestMenu = _menuForResponse(
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
          return _InsightsSendOutcome(timedOut: false, originalText: trimmed);
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
            return _InsightsSendOutcome(
              timedOut: false,
              originalText: trimmed,
            );
          }
          final fallbackAction = _extractExportActionMap(fallbackResponse.raw);
          final fallbackCanExport = _extractCanExport(fallbackResponse.raw);
          final fallbackView = _extractResponseView(fallbackResponse.raw);
          final fallbackTable =
              _extractStructuredTableMap(fallbackResponse.raw);
          final fallbackFollowUps = _extractFollowUps(fallbackResponse.raw);
          final fallbackText = fallbackResponse.text.trim().isEmpty
              ? l.insightsChatNoResponse
              : fallbackResponse.text.trim();
          final fallbackMenu = _menuForResponse(
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
            followUps: latestFollowUps ?? current.followUps,
            menu: latestMenu ?? current.menu,
          );
        }
        addedAssistant = true;
        notifyListeners();
      }
    } on InsightsApiException catch (e) {
      final isActionDrivenSend = source == _InsightsSendSource.followUpButton ||
          source == _InsightsSendSource.backButton ||
          _looksLikeActionToken(trimmed);
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
      source: _InsightsSendSource.retryAction,
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
      source: _InsightsSendSource.newConversationAction,
    );
  }

  Future<InsightsExcelExport> exportExcel({
    required String groupId,
    required String message,
  }) {
    return _api.exportChatExcel(
      groupId: groupId,
      message: message,
    );
  }

  Future<InsightsExcelExport> downloadExcelFromAction(
    InsightsExcelExportAction action,
  ) {
    return _api.downloadInsightsExcelFromAction(action);
  }

  Future<Map<String, dynamic>> executeJsonAction(
    Map<String, dynamic> action,
  ) {
    return _api.executeJsonAction(action);
  }

  Future<void> refreshMessageFromSourceAction({
    required _ChatMessage message,
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
      },
    );
    final text = response.text.trim().isEmpty
        ? (message.text.trim().isEmpty ? source : message.text)
        : response.text.trim();
    _messages[messageIndex] = message.copyWith(
      text: text,
      table: _extractStructuredTableMap(response.raw) ?? message.table,
      followUps: _extractFollowUps(response.raw) ?? message.followUps,
      menu: _menuForResponse(
            raw: response.raw,
            text: text,
            table: _extractStructuredTableMap(response.raw),
          ) ??
          message.menu,
      view: _extractResponseView(response.raw) ?? message.view,
      canExport: _extractCanExport(response.raw) || message.canExport,
      exportAction:
          _extractExportActionMap(response.raw) ?? message.exportAction,
    );
    notifyListeners();
    await _persistHistory();
  }

  Future<_InsightsSendOutcome> previewEventRequest({
    required BuildContext context,
    required String text,
    required String groupId,
    _InsightsSendSource source = _InsightsSendSource.typedInput,
    String? conversationIdOverride,
    String? displayTextOverride,
  }) async {
    final trimmed = text.trim();
    final resolvedGroupId = groupId.trim();
    if (trimmed.isEmpty || _sending || resolvedGroupId.isEmpty) {
      return _InsightsSendOutcome(timedOut: false, originalText: trimmed);
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
      _ChatMessage(
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
      final textOut = (response['message']?.toString().trim().isNotEmpty ?? false)
          ? response['message'].toString().trim()
          : l.insightsChatNoResponse;
      _messages.add(
        _ChatMessage(
          isUser: false,
          text: textOut,
          timestamp: DateTime.now(),
          conversationId: activeConversationId,
          sourceUserMessage: trimmed,
          eventAssistant: _extractEventAssistantMap(response),
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

    return _InsightsSendOutcome(timedOut: false, originalText: trimmed);
  }
}

class _InsightsChatSheet extends StatefulWidget {
  const _InsightsChatSheet({
    required this.groupId,
    required this.runtime,
    this.embedded = false,
  });

  final String groupId;
  final _InsightsChatRuntime runtime;
  final bool embedded;

  @override
  State<_InsightsChatSheet> createState() => _InsightsChatSheetState();
}

class _InsightsChatSheetState extends State<_InsightsChatSheet> {
  late final _InsightsChatRuntime _runtime;
  final _invoicesApi = InvoicesApi();
  final _clientsApi = ClientsApi();
  final _servicesApi = ServiceApi();
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  String? _exportingMessageKey;
  String? _selectedAssistantMessageKey;
  String? _eventActionMessageKey;
  final Map<String, _PendingInvoiceLinkEdit> _pendingInvoiceLinkEdits = {};
  final Map<String, Map<String, dynamic>> _invoiceDisplayCache = {};
  bool _loadingInvoiceDisplayCache = false;
  bool _bulkLinkingInvoices = false;
  final Map<String, String> _bulkLinkErrors = {};
  final Set<String> _searchingBankIncomeRows = {};
  final Set<String> _linkingBankIncomeRows = {};

  @override
  void initState() {
    super.initState();
    _runtime = widget.runtime;
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
    if (_runtime.messages.isEmpty &&
        (_selectedAssistantMessageKey != null ||
            _exportingMessageKey != null ||
            _eventActionMessageKey != null)) {
      _selectedAssistantMessageKey = null;
      _exportingMessageKey = null;
      _eventActionMessageKey = null;
    }
    setState(() {});
    _scrollToBottom();
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

  String? _conversationIdForMessage(_ChatMessage? message) {
    final conversationId = message?.conversationId?.trim() ?? '';
    if (conversationId.isEmpty) return null;
    return conversationId;
  }

  Future<void> _sendMessageAction(
    String text, {
    required _InsightsSendSource source,
    _ChatMessage? message,
    String? displayTextOverride,
  }) async {
    final result = await _runtime.send(
      context: context,
      text: text,
      groupId: widget.groupId,
      source: source,
      conversationIdOverride: _conversationIdForMessage(message),
      displayTextOverride: displayTextOverride,
    );
    if (!mounted) return;
    if (result.timedOut) {
      _inputCtrl.text = result.originalText;
      _inputCtrl.selection = TextSelection.fromPosition(
        TextPosition(offset: _inputCtrl.text.length),
      );
    }
  }

  Future<void> _sendMenuChoice(
    int index, {
    String? action,
    String? label,
    _ChatMessage? message,
  }) async {
    if (_runtime.sending) return;
    await _sendMessageAction(
      (action?.trim().isNotEmpty ?? false) ? action!.trim() : '$index',
      source: _InsightsSendSource.followUpButton,
      message: message,
      displayTextOverride: label,
    );
  }

  Future<void> _sendStarterChoice(_InsightsMenuOption option) async {
    if (_runtime.sending) return;
    await _sendMessageAction(
      option.action?.trim().isNotEmpty == true
          ? option.action!.trim()
          : option.label,
      source: _InsightsSendSource.newConversationAction,
      displayTextOverride: option.label,
    );
  }

  void _prefillEventCreationShortcut(bool isEs) {
    if (_runtime.sending) return;
    _inputCtrl.text = isEs
        ? 'Crear evento: mantenimiento de piscina cada lunes y viernes a las 8 hasta septiembre'
        : 'Create event: pool maintenance every Monday and Friday at 8am until September';
    _inputCtrl.selection = TextSelection.fromPosition(
      TextPosition(offset: _inputCtrl.text.length),
    );
  }

  Future<void> _sendMenuBack(
    _InsightsMenu menu, {
    _ChatMessage? message,
  }) async {
    final backAction = menu.backAction?.trim() ?? '';
    if (backAction.isEmpty || _runtime.sending) return;
    await _sendMessageAction(
      backAction,
      source: _InsightsSendSource.backButton,
      message: message,
      displayTextOverride: 'Back',
    );
  }

  bool _isIncomeAmountPromptMessage(_ChatMessage message) {
    if (message.isUser) return false;
    if (_messageHasStructuredTable(message)) return false;
    return _isIncomeInvoicesByAmountAction(message.sourceUserMessage);
  }

  _ChatMessage? _latestAssistantMessage(List<_ChatMessage> messages) {
    return messages.reversed.cast<_ChatMessage?>().firstWhere(
          (message) => message != null && !message.isUser,
          orElse: () => null,
        );
  }

  _ChatMessage? _latestIncomeAmountPromptMessage(List<_ChatMessage> messages) {
    final latestAssistant = _latestAssistantMessage(messages);
    if (latestAssistant == null) return null;
    return _isIncomeAmountPromptMessage(latestAssistant)
        ? latestAssistant
        : null;
  }

  Future<void> _submitIncomeAmountPrompt(_ChatMessage promptMessage) async {
    if (_runtime.sending) return;
    final amount = _inputCtrl.text.trim();
    if (amount.isEmpty) return;
    _inputCtrl.clear();
    await _sendMessageAction(
      amount,
      source: _InsightsSendSource.typedInput,
      message: promptMessage,
    );
  }

  Future<void> _submitTypedMessage() async {
    if (_runtime.sending) return;
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    _inputCtrl.clear();
    if (_shouldUseEventPreview(text)) {
      await _runtime.previewEventRequest(
        context: context,
        text: text,
        groupId: widget.groupId,
      );
      if (!mounted) return;
      final latestAssistant = _latestAssistantMessage(_runtime.messages);
      if (latestAssistant != null &&
          _eventShouldPromptForClientAndService(latestAssistant)) {
        await _editEventDraft(latestAssistant);
      }
      return;
    }
    await _sendMessageAction(
      text,
      source: _InsightsSendSource.typedInput,
    );
  }

  bool _shouldUseEventPreview(String text) {
    final latestAssistant = _latestAssistantMessage(_runtime.messages);
    if (_hasPendingEventClarification(latestAssistant)) {
      return true;
    }
    return _looksLikeEventCreationRequest(text);
  }

  bool _hasPendingEventClarification(_ChatMessage? message) {
    final assistant = _safeMap(message?.eventAssistant);
    if (assistant == null) return false;
    if (assistant['cancelled'] == true) return false;
    return (assistant['status']?.toString().trim() ?? '') ==
        'needs_clarification';
  }

  bool _looksLikeEventCreationRequest(String text) {
    final normalized = text.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    final hasEventWord = RegExp(
      r'\b(event|meeting|appointment|reminder|maintenance|schedule|calendar|evento|reunion|reunión|cita|recordatorio|mantenimiento|agenda|calendario)\b',
    ).hasMatch(normalized);
    final hasCreateVerb = RegExp(
      r'\b(create|schedule|add|book|plan|set up|remind|program|crear|crea|agendar|agenda|anade|añade|programa|recordar|reservar)\b',
    ).hasMatch(normalized);
    final hasTimeHint = RegExp(
      r'\b(every|each|daily|weekly|monthly|yearly|weekday|weekdays|monday|tuesday|wednesday|thursday|friday|saturday|sunday|tomorrow|next|until|at\s+\d|first|last|cada|diario|semanal|mensual|anual|laborable|lunes|martes|miercoles|miércoles|jueves|viernes|sabado|sábado|domingo|mañana|proximo|próximo|hasta|a las)\b',
    ).hasMatch(normalized);
    final hasDateLike = RegExp(r'\b\d{1,2}([/:.-]\d{1,2})?([/:.-]\d{2,4})?\b')
        .hasMatch(normalized);
    return hasEventWord || (hasCreateVerb && (hasTimeHint || hasDateLike));
  }

  Map<String, dynamic>? _eventAssistantForMessage(_ChatMessage message) =>
      _safeMap(message.eventAssistant);

  Map<String, dynamic>? _eventPreviewForMessage(_ChatMessage message) =>
      _safeMap(_eventAssistantForMessage(message)?['preview']);

  Map<String, dynamic>? _eventPayloadForMessage(_ChatMessage message) =>
      _safeMap(_eventPreviewForMessage(message)?['eventPayload']);

  String _eventStatus(_ChatMessage message) =>
      _eventAssistantForMessage(message)?['status']?.toString().trim() ?? '';

  bool _eventIsCancelled(_ChatMessage message) =>
      _eventAssistantForMessage(message)?['cancelled'] == true;

  bool _eventCanCreate(_ChatMessage message) {
    final assistant = _eventAssistantForMessage(message);
    if (assistant == null || assistant['cancelled'] == true) return false;
    return assistant['canCreate'] == true;
  }

  bool _eventShouldPromptForClientAndService(_ChatMessage message) {
    final payload = _eventPayloadForMessage(message);
    final preview = _eventPreviewForMessage(message);
    if (payload == null || preview == null) return false;
    final missing = _stringList(preview['missing'])
        .map((item) => item.toLowerCase())
        .toList(growable: false);
    final clientId = payload['clientId']?.toString().trim() ?? '';
    final primaryServiceId =
        payload['primaryServiceId']?.toString().trim() ?? '';
    final needsClient = clientId.isEmpty ||
        missing.any((item) => item.contains('client') || item.contains('cliente'));
    final needsService = primaryServiceId.isEmpty ||
        missing.any(
          (item) => item.contains('service') || item.contains('servicio'),
        );
    return needsClient || needsService;
  }

  DateTime? _eventDate(dynamic value) {
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }

  String _eventStatusLabel(String status, bool isEs) {
    switch (status) {
      case 'ready_to_create':
        return isEs ? 'Listo para crear' : 'Ready to create';
      case 'needs_clarification':
        return isEs ? 'Necesita aclaracion' : 'Needs clarification';
      case 'created':
        return isEs ? 'Creado' : 'Created';
      case 'error':
        return isEs ? 'Error' : 'Error';
      case 'not_event':
        return isEs ? 'No es evento' : 'Not an event';
      default:
        return status.isEmpty ? (isEs ? 'Evento' : 'Event') : status;
    }
  }

  Color _eventStatusColor(ColorScheme cs, String status) {
    switch (status) {
      case 'ready_to_create':
        return cs.primary;
      case 'needs_clarification':
        return cs.tertiary;
      case 'created':
        return Colors.green.shade700;
      case 'error':
        return cs.error;
      default:
        return cs.onSurfaceVariant;
    }
  }

  String _formatEventDateTime(
    BuildContext context,
    DateTime? date, {
    required bool allDay,
  }) {
    if (date == null) return '-';
    final localizations = MaterialLocalizations.of(context);
    final dateLabel = localizations.formatMediumDate(date);
    if (allDay) return dateLabel;
    final timeLabel = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(date),
      alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
    );
    return '$dateLabel · $timeLabel';
  }

  String _eventDateRangeLabel(BuildContext context, _ChatMessage message) {
    final preview = _eventPreviewForMessage(message);
    if (preview == null) return '-';
    final allDay = preview['allDay'] == true;
    final start = _eventDate(preview['startDate']);
    final end = _eventDate(preview['endDate']);
    final startLabel = _formatEventDateTime(context, start, allDay: allDay);
    final endLabel = _formatEventDateTime(context, end, allDay: allDay);
    return startLabel == endLabel ? startLabel : '$startLabel → $endLabel';
  }

  String _eventDurationLabel(_ChatMessage message, bool isEs) {
    final preview = _eventPreviewForMessage(message);
    if (preview == null) return '-';
    if (preview['allDay'] == true) return isEs ? 'Todo el dia' : 'All day';
    final minutes = _readInt(preview['durationMinutes']);
    if (minutes == null || minutes <= 0) return '-';
    if (minutes % 60 == 0) {
      final hours = minutes ~/ 60;
      return isEs ? '$hours h' : '$hours h';
    }
    final hours = minutes ~/ 60;
    final rem = minutes % 60;
    if (hours <= 0) return isEs ? '$rem min' : '$rem min';
    return '${hours}h ${rem}m';
  }

  String _eventRecurrenceSummary(_ChatMessage message, bool isEs) {
    final rule = _safeMap(_eventPreviewForMessage(message)?['recurrenceRule']);
    if (rule == null || rule.isEmpty) return '';
    final type = rule['recurrenceType']?.toString().trim() ?? '';
    final interval = _readInt(rule['repeatInterval']) ?? 1;
    final days = ((rule['daysOfWeek'] as List?) ?? const [])
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    final dayOfMonth = _readInt(rule['dayOfMonth']);
    final ordinalWeek = _readInt(rule['ordinalWeek']);
    final ordinalWeekday = rule['ordinalWeekday']?.toString().trim() ?? '';
    switch (type) {
      case 'Daily':
        return isEs
            ? (interval == 1 ? 'Cada dia' : 'Cada $interval dias')
            : (interval == 1 ? 'Every day' : 'Every $interval days');
      case 'Weekly':
        final dayText = days.join(', ');
        return isEs
            ? (interval == 1 ? 'Cada semana' : 'Cada $interval semanas') +
                (dayText.isEmpty ? '' : ' · $dayText')
            : (interval == 1 ? 'Every week' : 'Every $interval weeks') +
                (dayText.isEmpty ? '' : ' · $dayText');
      case 'Monthly':
        if (ordinalWeek != null && ordinalWeekday.isNotEmpty) {
          final ordinalText = _ordinalLabel(ordinalWeek, isEs);
          return isEs
              ? '$ordinalText $ordinalWeekday de cada mes'
              : '$ordinalText $ordinalWeekday of the month';
        }
        if (dayOfMonth != null) {
          return isEs
              ? 'Cada mes el dia $dayOfMonth'
              : 'Monthly on day $dayOfMonth';
        }
        return isEs ? 'Mensual' : 'Monthly';
      case 'Yearly':
        return isEs
            ? (interval == 1 ? 'Cada ano' : 'Cada $interval anos')
            : (interval == 1 ? 'Every year' : 'Every $interval years');
      default:
        return '';
    }
  }

  String _ordinalLabel(int ordinal, bool isEs) {
    const en = <int, String>{
      1: 'First',
      2: 'Second',
      3: 'Third',
      4: 'Fourth',
      -1: 'Last',
    };
    const es = <int, String>{
      1: 'Primer',
      2: 'Segundo',
      3: 'Tercer',
      4: 'Cuarto',
      -1: 'Ultimo',
    };
    return (isEs ? es : en)[ordinal] ?? ordinal.toString();
  }

  List<String> _stringList(dynamic value) {
    if (value is! List) return const <String>[];
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> _cancelEventDraft(_ChatMessage message) async {
    final assistant = _eventAssistantForMessage(message);
    if (assistant == null) return;
    final updated = _cloneJsonMap(assistant)..['cancelled'] = true;
    await _runtime.replaceMessage(
      message,
      message.copyWith(eventAssistant: updated),
    );
  }

  Future<void> _confirmEventCreation(_ChatMessage message) async {
    if (_eventShouldPromptForClientAndService(message)) {
      await _editEventDraft(message);
      return;
    }
    final payload = _eventPayloadForMessage(message);
    if (payload == null || payload.isEmpty) return;
    final messageKey = _messageKey(message);
    final isEs = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('es');
    setState(() => _eventActionMessageKey = messageKey);
    try {
      final response = await InsightsApi().confirmChatEvent(
        groupId: widget.groupId,
        eventPayload: _cloneJsonMap(payload),
        confirm: true,
      );
      final assistant = _cloneJsonMap(_eventAssistantForMessage(message) ?? {});
      assistant['status'] = 'created';
      assistant['canCreate'] = false;
      assistant['confirmationRequired'] = false;
      final createdAssistant = _safeMap(response['eventAssistant']);
      if (createdAssistant != null && createdAssistant.isNotEmpty) {
        assistant['event'] = createdAssistant['event'];
      }
      await _runtime.replaceMessage(
        message,
        message.copyWith(eventAssistant: assistant),
      );
      await _runtime.appendMessage(
        _ChatMessage(
          isUser: false,
          text: (response['message']?.toString().trim().isNotEmpty ?? false)
              ? response['message'].toString().trim()
              : (isEs ? 'Evento creado.' : 'Event created.'),
          timestamp: DateTime.now(),
          conversationId: message.conversationId,
          sourceUserMessage: message.sourceUserMessage,
        ),
      );
      await _refreshEventState();
    } on InsightsApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) {
        setState(() => _eventActionMessageKey = null);
      }
    }
  }

  Future<void> _refreshEventState() async {
    try {
      final domain = context.read<EventDomain>();
      await domain.manualRefresh(context, silent: true);
    } catch (_) {}
  }

  Future<void> _openCalendarForCurrentGroup() async {
    try {
      final group = context.read<GroupDomain>().currentGroup;
      if (group == null || !mounted) return;
      await Navigator.of(context).pushNamed(
        AppRoutes.groupCalendar,
        arguments: group,
      );
    } catch (_) {}
  }

  Future<void> _editEventDraft(_ChatMessage message) async {
    final assistant = _eventAssistantForMessage(message);
    final preview = _eventPreviewForMessage(message);
    if (assistant == null || preview == null) return;
    final updated = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _InsightsEventEditDialog(
        groupId: widget.groupId,
        clientsApi: _clientsApi,
        servicesApi: _servicesApi,
        initialAssistant: assistant,
      ),
    );
    if (updated == null) return;
    await _runtime.replaceMessage(
      message,
      message.copyWith(eventAssistant: updated),
    );
  }

  String _messageKey(_ChatMessage message) {
    return '${message.isUser ? 'u' : 'a'}::${message.timestamp.toIso8601String()}';
  }

  String _invoiceLinkKey(String messageKey, String entryId) =>
      '$messageKey::$entryId';

  bool _messageSupportsManualInvoiceLink(_ChatMessage message) {
    if (!_messageHasStructuredTable(message)) return false;
    final columns = _tableColumnsFromMessage(message);
    return columns.any(
      (column) => column['key']?.toString() == 'linkStatusLabel',
    );
  }

  List<Map<String, dynamic>> _columnsWithTransactionLinkedState(
    List<Map<String, dynamic>> columns, {
    required bool isEs,
  }) {
    const stateKey = 'transactionLinkedStateLabel';
    if (columns.any((column) => column['key']?.toString() == stateKey)) {
      return columns;
    }

    final next = <Map<String, dynamic>>[];
    var inserted = false;
    for (final column in columns) {
      final key = column['key']?.toString();
      if (!inserted && key == 'linkStatusLabel') {
        next.add({
          'key': stateKey,
          'label': isEs ? 'Vinculada' : 'Linked',
        });
        inserted = true;
      }
      next.add(column);
    }
    if (!inserted) {
      next.add({
        'key': stateKey,
        'label': isEs ? 'Vinculada' : 'Linked',
      });
    }
    return next;
  }

  Map<String, dynamic>? _rowBankIncomeSearchAction(Map<String, dynamic> row) {
    final action = _safeMap(row['bankIncomeSearchAction']);
    if (action == null || action.isEmpty) return null;
    final endpoint = action['endpoint']?.toString().trim() ?? '';
    return endpoint.isEmpty ? null : action;
  }

  bool _rowsHaveBankIncomeSearch(List<Map<String, dynamic>> rows) {
    return rows.any((row) => _rowBankIncomeSearchAction(row) != null);
  }

  List<Map<String, dynamic>> _columnsWithBankIncomeSearchAction(
    List<Map<String, dynamic>> columns, {
    required bool isEs,
  }) {
    const actionKey = '__bankIncomeSearchAction';
    if (columns.any((column) => column['key']?.toString() == actionKey)) {
      return columns;
    }
    return <Map<String, dynamic>>[
      ...columns,
      {
        'key': actionKey,
        'label': isEs ? 'Ingreso' : 'Income',
      },
    ];
  }

  String _invoiceIdFromInsightsInvoiceRow(Map<String, dynamic> row) {
    for (final key in const [
      'invoiceId',
      'invoice_id',
      'id',
      '_id',
    ]) {
      final value = row[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    final ids = row['invoiceIds'];
    if (ids is List) {
      for (final item in ids) {
        final value = item?.toString().trim() ?? '';
        if (value.isNotEmpty) return value;
      }
    }
    return '';
  }

  String _normalizedInsightText(Object? value) {
    return (value?.toString() ?? '')
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u');
  }

  bool _isInvoiceStatusColumn(Map<String, dynamic> column) {
    final key = _normalizedInsightText(column['key']);
    final label = _normalizedInsightText(column['label']);
    return key == 'estado' ||
        key == 'status' ||
        key == 'statuslabel' ||
        key == 'paymentstatus' ||
        label == 'estado' ||
        label == 'status';
  }

  bool _rowIsUnlinkedInvoice(Map<String, dynamic> row) {
    for (final key in const [
      'estado',
      'status',
      'statusLabel',
      'paymentStatus',
      'paymentStatusLabel',
      'linkStatus',
      'linkStatusLabel',
    ]) {
      final text = _normalizedInsightText(row[key]);
      if (text.isEmpty) continue;
      if (text.contains('no vincul') ||
          text.contains('sin vincul') ||
          text.contains('unlinked') ||
          text.contains('not linked')) {
        return true;
      }
    }
    return false;
  }

  bool _rowHasExistingInvoiceLink(Map<String, dynamic> row) {
    if (row['hasExistingInvoiceLink'] == true) return true;
    final status = row['linkStatus']?.toString().trim().toLowerCase();
    if (status == 'linked') return true;
    final ids = row['existingLinkedInvoiceIds'];
    if (ids is List &&
        ids.where((id) => id.toString().trim().isNotEmpty).isNotEmpty) {
      return true;
    }
    final id = row['existingLinkedInvoiceId']?.toString().trim() ?? '';
    return id.isNotEmpty;
  }

  List<String> _linkedInvoiceIdsFromRow(Map<String, dynamic> row) {
    final ids = <String>{
      for (final key in const [
        'existingLinkedInvoiceIds',
        'matchedInvoiceIds',
        'linkedInvoiceIds',
        'invoiceIds',
      ])
        if (row[key] is List)
          for (final item in row[key] as List)
            if ((item?.toString().trim() ?? '').isNotEmpty)
              item.toString().trim(),
      for (final key in const [
        'existingLinkedInvoiceId',
        'matchedInvoiceId',
        'linkedInvoiceId',
        'invoiceId',
        'invoice_id',
      ])
        if ((row[key]?.toString().trim() ?? '').isNotEmpty)
          row[key].toString().trim(),
    }.toList(growable: false);
    return ids;
  }

  bool _linkedRowNeedsInvoiceDisplayHydration(Map<String, dynamic> row) {
    if (!_rowHasExistingInvoiceLink(row)) return false;
    if (_linkedInvoiceIdsFromRow(row).isEmpty) return false;
    final number = row['matchedInvoiceNumber']?.toString().trim() ?? '';
    final client = row['matchedInvoiceClientName']?.toString().trim() ?? '';
    final amount =
        row['matchedInvoiceAmountFormatted']?.toString().trim() ?? '';
    return number.isEmpty || client.isEmpty || amount.isEmpty;
  }

  String _formatEuroAmount(num? amount, String? currency) {
    if (amount == null) return '';
    final parts = amount.toStringAsFixed(2).split('.');
    final whole = parts.first;
    final buffer = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      final left = whole.length - i;
      buffer.write(whole[i]);
      if (left > 1 && left % 3 == 1) buffer.write('.');
    }
    final code = (currency ?? 'EUR').trim().isEmpty ? 'EUR' : currency!.trim();
    return '${buffer.toString()},${parts.last} $code';
  }

  Future<void> _ensureInvoiceDisplayCacheLoaded() async {
    if (_invoiceDisplayCache.isNotEmpty || _loadingInvoiceDisplayCache) return;
    _loadingInvoiceDisplayCache = true;
    try {
      final invoices = await _invoicesApi.listByGroup(
        widget.groupId,
        status: 'issued',
      );
      final clients = await _clientsApi.list(groupId: widget.groupId);
      final clientNamesById = {
        for (final client in clients)
          if (client.id.trim().isNotEmpty)
            client.id.trim():
                (client.billing?.legalName?.trim().isNotEmpty == true)
                    ? client.billing!.legalName!.trim()
                    : client.name.trim(),
      };
      for (final invoice in invoices) {
        final id = invoice.id.trim();
        if (id.isEmpty) continue;
        final clientName =
            (invoice.clientSnapshot?.legalName?.trim().isNotEmpty == true)
                ? invoice.clientSnapshot!.legalName!.trim()
                : (invoice.billingName?.trim().isNotEmpty == true)
                    ? invoice.billingName!.trim()
                    : (clientNamesById[invoice.clientId.trim()] ?? '').trim();
        _invoiceDisplayCache[id] = <String, dynamic>{
          'id': id,
          'invoiceNumber': invoice.invoiceNumber.trim(),
          'clientName': clientName,
          'total': invoice.total,
          'totalFormatted': _formatEuroAmount(invoice.total, invoice.currency),
        };
      }
    } catch (_) {
      // Best-effort fallback; backend hydrated fields remain the source of truth.
    } finally {
      _loadingInvoiceDisplayCache = false;
    }
  }

  Future<void> _hydrateLinkedInvoiceDisplayFields(
    _ChatMessage message,
    List<Map<String, dynamic>> rows,
    bool isEs,
  ) async {
    final needsHydration = rows
        .where(_linkedRowNeedsInvoiceDisplayHydration)
        .toList(growable: false);
    if (needsHydration.isEmpty) return;
    await _ensureInvoiceDisplayCacheLoaded();
    if (_invoiceDisplayCache.isEmpty) return;

    for (final row in needsHydration) {
      final entryId = _rowEntryId(row);
      if (entryId == null) continue;
      final ids = _linkedInvoiceIdsFromRow(row);
      final invoices = ids
          .map((id) => _invoiceDisplayCache[id])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
      if (invoices.isEmpty) continue;

      final numbers = invoices
          .map((invoice) => invoice['invoiceNumber']?.toString().trim() ?? '')
          .where((value) => value.isNotEmpty)
          .toList(growable: false);
      final clients = invoices
          .map((invoice) => invoice['clientName']?.toString().trim() ?? '')
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList(growable: false);
      final total = invoices.fold<num>(
        0,
        (sum, invoice) =>
            sum + ((invoice['total'] is num) ? invoice['total'] as num : 0),
      );

      await _runtime.updateTableRow(
        message: message,
        entryId: entryId,
        rowPatch: <String, dynamic>{
          'matchedInvoiceNumber': numbers.join(' + '),
          'matchedInvoiceClientName': clients.join(' + '),
          'matchedInvoiceAmount': total,
          'matchedInvoiceAmountFormatted': _formatEuroAmount(total, 'EUR'),
          'linkStatus': 'linked',
          'linkStatusLabel': isEs ? 'Vinculado' : 'Linked',
          'hasExistingInvoiceLink': true,
          'existingLinkedInvoiceIds': ids,
        },
      );
    }
  }

  Map<String, dynamic> _linkedRowPatchFromBulkResponse(
    Map<String, dynamic> item,
    bool isEs,
  ) {
    List<String> stringList(dynamic raw) {
      if (raw is! List) return const <String>[];
      return raw
          .map((value) => value?.toString().trim() ?? '')
          .where((value) => value.isNotEmpty)
          .toList(growable: false);
    }

    final entry = _safeMap(item['entry']);
    final invoiceIds = stringList(item['invoiceIds']);
    final invoiceNumbers = stringList(item['invoiceNumbers']);
    final invoiceNumber =
        (item['invoiceNumber']?.toString().trim().isNotEmpty == true)
            ? item['invoiceNumber'].toString().trim()
            : invoiceNumbers.join(' + ');
    final clientName = item['clientName']?.toString().trim() ?? '';
    final total = item['total'];
    final totalFormatted = item['totalFormatted']?.toString().trim() ?? '';

    return <String, dynamic>{
      if (entry != null) ...entry,
      'bulkLinkEntry': entry,
      'matchedInvoiceId': invoiceIds.isNotEmpty ? invoiceIds.first : null,
      'matchedInvoiceIds': invoiceIds,
      'matchedInvoiceNumber': invoiceNumber,
      'matchedInvoiceClientName': clientName,
      if (total is num) 'matchedInvoiceAmount': total,
      'matchedInvoiceAmountFormatted': totalFormatted,
      'linkStatus': item['linkStatus']?.toString().trim().isNotEmpty == true
          ? item['linkStatus']
          : 'linked',
      'linkStatusLabel':
          item['linkStatusLabel']?.toString().trim().isNotEmpty == true
              ? item['linkStatusLabel']
              : (isEs ? 'Vinculado' : 'Linked'),
      'hasExistingInvoiceLink': true,
      'alreadyLinked': item['alreadyLinked'] == true,
      'existingLinkedInvoiceIds': invoiceIds,
      'invoiceIds': invoiceIds,
      'invoiceNumbers': invoiceNumbers,
      'invoiceNumber': invoiceNumber,
      'invoice_number': invoiceNumber,
      if (clientName.isNotEmpty) 'clientName': clientName,
      if (clientName.isNotEmpty) 'counterpartyName': clientName,
    };
  }

  List<Map<String, dynamic>> _bulkLinkableRows(
    List<Map<String, dynamic>> rows,
  ) {
    return rows.where((row) {
      if (_rowHasExistingInvoiceLink(row)) return false;
      if (_rowEntryId(row) == null) return false;
      return _linkedInvoiceIdsFromRow(row).isNotEmpty;
    }).toList(growable: false);
  }

  Future<void> _linkAllSuggestedInvoices(
    _ChatMessage message,
    List<Map<String, dynamic>> rows,
    bool isEs,
  ) async {
    final candidates = _bulkLinkableRows(rows);
    if (candidates.isEmpty || _bulkLinkingInvoices) return;
    setState(() => _bulkLinkingInvoices = true);
    try {
      setState(() => _bulkLinkErrors.clear());
      final links = [
        for (final row in candidates)
          {
            'entryId': _rowEntryId(row),
            'invoiceIds': _linkedInvoiceIdsFromRow(row),
          },
      ];
      final response = await StatementsApi().bulkLinkEntryInvoices(
        links: links,
      );
      final entries = response['entries'];
      var linked = 0;
      final patchesByEntryId = <String, Map<String, dynamic>>{};
      if (entries is List) {
        for (final raw in entries) {
          final item = _safeMap(raw);
          if (item == null) continue;
          final entryId = item['entryId']?.toString().trim() ??
              _safeMap(item['entry'])?['id']?.toString().trim() ??
              _safeMap(item['entry'])?['_id']?.toString().trim() ??
              '';
          if (entryId.isEmpty) continue;
          patchesByEntryId[entryId] = _linkedRowPatchFromBulkResponse(
            item,
            isEs,
          );
          linked += 1;
        }
      }
      await _runtime.updateTableRows(
        message: message,
        patchesByEntryId: patchesByEntryId,
      );

      final failed = response['failed'];
      final nextErrors = <String, String>{};
      if (failed is List) {
        for (final raw in failed) {
          final item = _safeMap(raw);
          if (item == null) continue;
          final entryId = item['entryId']?.toString().trim() ?? '';
          if (entryId.isEmpty) continue;
          nextErrors[entryId] = item['message']?.toString().trim() ??
              (isEs ? 'No se pudo vincular' : 'Could not link');
        }
      }
      if (mounted) {
        setState(() {
          _bulkLinkErrors
            ..clear()
            ..addAll(nextErrors);
        });
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nextErrors.isEmpty
                ? (isEs
                    ? 'Se vincularon $linked factura(s).'
                    : 'Linked $linked invoice(s).')
                : (isEs
                    ? 'Se vincularon $linked factura(s). ${nextErrors.length} fallaron.'
                    : 'Linked $linked invoice(s). ${nextErrors.length} failed.'),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _bulkLinkingInvoices = false);
      }
    }
  }

  String _tableCellValue(
    Map<String, dynamic> row,
    Map<String, dynamic> column,
  ) {
    final key = column['key']?.toString() ?? '';
    if (!_rowHasExistingInvoiceLink(row)) {
      return row[key]?.toString() ?? '';
    }

    final label = (column['label']?.toString() ?? '').trim().toLowerCase();
    final normalizedLabel =
        label.replaceAll('á', 'a').replaceAll('é', 'e').replaceAll('í', 'i');

    if (key == 'matchedInvoiceNumber' ||
        key == 'invoiceNumber' ||
        key == 'invoice_number' ||
        normalizedLabel == 'factura') {
      return row['matchedInvoiceNumber']?.toString() ?? '';
    }

    if (key == 'matchedInvoiceClientName' ||
        key == 'invoiceClientName' ||
        key == 'clientInvoiceName' ||
        normalizedLabel == 'cliente factura') {
      return row['matchedInvoiceClientName']?.toString() ?? '';
    }

    if (key == 'matchedInvoiceAmountFormatted' ||
        key == 'invoiceAmountFormatted' ||
        key == 'invoiceAmount' ||
        normalizedLabel == 'importe factura') {
      return row['matchedInvoiceAmountFormatted']?.toString() ?? '';
    }

    if (key == 'linkStatusLabel') {
      return row['linkStatusLabel']?.toString() ?? '';
    }

    return row[key]?.toString() ?? '';
  }

  String? _rowEntryId(Map<String, dynamic> row) {
    for (final key in const ['id', '_id', 'entryId', 'entry_id']) {
      final value = row[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return null;
  }

  Map<String, dynamic> _rowWithPendingLink(
    _ChatMessage message,
    Map<String, dynamic> row,
  ) {
    final entryId = _rowEntryId(row);
    if (entryId == null) return row;
    final key = _invoiceLinkKey(_messageKey(message), entryId);
    final pending = _pendingInvoiceLinkEdits[key];
    if (pending == null) return row;
    final next = Map<String, dynamic>.from(row);
    next['matchedInvoiceId'] = pending.invoiceId;
    next['matchedInvoiceIds'] = <String>[pending.invoiceId];
    next['matchedInvoiceNumber'] = pending.invoiceNumber;
    next['matchedInvoiceClientName'] = pending.clientName;
    next['matchedInvoiceAmount'] = pending.total;
    next['matchedInvoiceAmountFormatted'] = pending.totalFormatted;
    next['hasExistingInvoiceLink'] = true;
    next['linkStatus'] = 'pending';
    next['linkStatusLabel'] = pending.pendingStatusLabel;
    next['existingLinkedInvoiceIds'] = <String>[pending.invoiceId];
    return next;
  }

  Map<String, dynamic> _statementEntryFromInsightsRow(
    Map<String, dynamic> row,
  ) {
    final entryId = _rowEntryId(row) ?? '';
    final invoiceIds = <String>{
      for (final key in const [
        'matchedInvoiceIds',
        'existingLinkedInvoiceIds',
        'existingLinkedInvoices',
        'linkedInvoiceIds',
        'invoiceIds',
      ])
        if (row[key] is List)
          for (final item in row[key] as List)
            if ((item?.toString().trim() ?? '').isNotEmpty)
              item.toString().trim(),
      for (final key in const [
        'matchedInvoiceId',
        'existingLinkedInvoiceId',
        'linkedInvoiceId',
        'invoiceId',
        'invoice_id',
      ])
        if ((row[key]?.toString().trim() ?? '').isNotEmpty)
          row[key].toString().trim(),
    }.toList(growable: false);
    final invoiceNumber = (row['matchedInvoiceNumber'] ??
            row['invoiceNumber'] ??
            row['invoice_number'])
        ?.toString()
        .trim();
    final invoiceNumbers = invoiceNumber == null || invoiceNumber.isEmpty
        ? const <String>[]
        : invoiceNumber
            .split(RegExp(r'\s*\+\s*'))
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList(growable: false);
    final clientId = (row['matchedInvoiceClientId'] ??
            row['invoiceClientId'] ??
            row['clientId'] ??
            row['client_id'])
        ?.toString()
        .trim();
    final clientName = (row['matchedInvoiceClientName'] ??
            row['invoiceClientName'] ??
            row['clientName'] ??
            row['counterpartyName'])
        ?.toString()
        .trim();
    return <String, dynamic>{
      ...row,
      '_id': entryId,
      'id': entryId,
      'date': row['date'] ?? row['fecha'],
      'description': row['concept'] ?? row['concepto'] ?? row['description'],
      'amount': row['amount'] ?? row['importe'] ?? row['amountFormatted'],
      if (invoiceIds.isNotEmpty) 'invoiceIds': invoiceIds,
      if (invoiceIds.isNotEmpty) 'invoiceId': invoiceIds.first,
      if (invoiceIds.isNotEmpty) 'invoice_id': invoiceIds.first,
      if (invoiceNumbers.isNotEmpty) 'invoiceNumbers': invoiceNumbers,
      if ((invoiceNumber ?? '').isNotEmpty) 'invoiceNumber': invoiceNumber,
      if ((invoiceNumber ?? '').isNotEmpty) 'invoice_number': invoiceNumber,
      if ((clientId ?? '').isNotEmpty) 'clientId': clientId,
      if ((clientId ?? '').isNotEmpty) 'client_id': clientId,
      if ((clientName ?? '').isNotEmpty) 'clientName': clientName,
      if ((clientName ?? '').isNotEmpty) 'counterpartyName': clientName,
    };
  }

  _PendingInvoiceLinkEdit? _linkEditFromStatementEntry(
    Map<String, dynamic> entry,
    Map<String, dynamic> row,
    bool isEs,
  ) {
    List<String> stringList(dynamic raw) {
      if (raw is! List) return const <String>[];
      return raw
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }

    final invoiceIds = stringList(entry['invoiceIds']);
    final invoiceId = invoiceIds.isNotEmpty
        ? invoiceIds.first
        : (entry['invoiceId'] ?? entry['invoice_id'])?.toString().trim() ?? '';
    if (invoiceId.isEmpty) return null;
    final invoiceNumbers = stringList(entry['invoiceNumbers']);
    final invoiceNumber = invoiceNumbers.isNotEmpty
        ? invoiceNumbers.join(' + ')
        : (entry['invoiceNumber'] ??
                    entry['invoice_number'] ??
                    row['matchedInvoiceNumber'])
                ?.toString()
                .trim() ??
            '';
    final clientName = (entry['clientName'] ??
                entry['counterpartyName'] ??
                row['matchedInvoiceClientName'])
            ?.toString()
            .trim() ??
        '';
    final totalFormatted =
        (row['matchedInvoiceAmountFormatted'] ?? row['invoiceAmountFormatted'])
                ?.toString()
                .trim() ??
            '';
    final displayParts = <String>[
      if (invoiceNumber.isNotEmpty) invoiceNumber,
      if (clientName.isNotEmpty) clientName,
    ];
    return _PendingInvoiceLinkEdit(
      invoiceId: invoiceId,
      invoiceNumber: invoiceNumber,
      clientName: clientName,
      total: null,
      totalFormatted: totalFormatted,
      pendingStatusLabel: isEs ? 'Vinculado' : 'Linked',
      displayLabel: displayParts.isEmpty
          ? (isEs ? 'Factura vinculada' : 'Linked invoice')
          : displayParts.join(' · '),
    );
  }

  Map<String, dynamic> _insightsRowPatchFromLinkedEntry(
    Map<String, dynamic> entry,
    _PendingInvoiceLinkEdit edit,
    bool isEs,
  ) {
    List<String> stringList(dynamic raw) {
      if (raw is! List) return const <String>[];
      return raw
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }

    final invoiceIds = stringList(entry['invoiceIds']);
    final invoiceNumbers = stringList(entry['invoiceNumbers']);
    final primaryId = invoiceIds.isNotEmpty ? invoiceIds.first : edit.invoiceId;
    final number = invoiceNumbers.isNotEmpty
        ? invoiceNumbers.join(' + ')
        : edit.invoiceNumber;
    final effectiveIds =
        invoiceIds.isNotEmpty ? invoiceIds : <String>[primaryId];
    final effectiveNumbers =
        invoiceNumbers.isNotEmpty ? invoiceNumbers : <String>[number];

    return <String, dynamic>{
      'matchedInvoiceId': primaryId,
      'matchedInvoiceIds': effectiveIds,
      'matchedInvoiceNumber': number,
      'matchedInvoiceClientName': edit.clientName,
      'matchedInvoiceAmount': edit.total,
      'matchedInvoiceAmountFormatted': edit.totalFormatted,
      'hasExistingInvoiceLink': true,
      'linkStatus': 'linked',
      'linkStatusLabel': isEs ? 'Vinculado' : 'Linked',
      'existingLinkedInvoiceIds': effectiveIds,
      'invoiceIds': effectiveIds,
      'invoiceNumbers': effectiveNumbers,
      'invoiceNumber': number,
      'invoice_number': number,
      if (edit.clientName.isNotEmpty) 'clientName': edit.clientName,
      if (edit.clientName.isNotEmpty) 'counterpartyName': edit.clientName,
    };
  }

  Future<Map<String, dynamic>> _entryWithResolvedInvoiceIds(
    Map<String, dynamic> entry,
    Map<String, dynamic> row,
  ) async {
    final currentIds = entry['invoiceIds'];
    if (currentIds is List && currentIds.isNotEmpty) return entry;
    final rawNumbers = entry['invoiceNumbers'];
    final numbers = rawNumbers is List
        ? rawNumbers
            .map((item) => item?.toString().trim() ?? '')
            .where((item) => item.isNotEmpty)
            .toList(growable: false)
        : const <String>[];
    if (numbers.isEmpty) return entry;

    final resolvedIds = <String>[];
    for (final number in numbers) {
      try {
        final matches = await _invoicesApi.searchManualLinkCandidates(
          groupId: widget.groupId,
          q: number,
          status: 'issued',
          limit: 10,
        );
        final exact = matches.cast<Map<String, dynamic>?>().firstWhere(
              (candidate) =>
                  candidate?['invoiceNumber']?.toString().trim() == number,
              orElse: () => matches.isNotEmpty ? matches.first : null,
            );
        final id =
            (exact?['id'] ?? exact?['invoiceId'])?.toString().trim() ?? '';
        if (id.isNotEmpty) resolvedIds.add(id);
      } catch (_) {
        // The shared dialog can still open normally if lookup fails.
      }
    }
    if (resolvedIds.isEmpty) return entry;
    return <String, dynamic>{
      ...entry,
      'invoiceIds': resolvedIds,
      'invoiceId': resolvedIds.first,
      'invoice_id': resolvedIds.first,
    };
  }

  Map<String, dynamic> _entryWithResolvedClientId(
    Map<String, dynamic> entry,
    List<Map<String, dynamic>> clients,
  ) {
    final existingClientId =
        (entry['clientId'] ?? entry['client_id'])?.toString().trim() ?? '';
    if (existingClientId.isNotEmpty) return entry;
    final targetName =
        (entry['clientName'] ?? entry['counterpartyName'])?.toString().trim() ??
            '';
    if (targetName.isEmpty) return entry;

    String normalize(String value) => value
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .trim();

    final normalizedTarget = normalize(targetName);
    final match = clients.cast<Map<String, dynamic>?>().firstWhere(
      (client) {
        final id = client?['id']?.toString().trim() ?? '';
        final name = client?['name']?.toString().trim() ?? '';
        if (id.isEmpty || name.isEmpty) return false;
        final normalizedName = normalize(name);
        return normalizedName == normalizedTarget ||
            normalizedTarget.contains(normalizedName) ||
            normalizedName.contains(normalizedTarget);
      },
      orElse: () => null,
    );
    final clientId = match?['id']?.toString().trim() ?? '';
    if (clientId.isEmpty) return entry;
    return <String, dynamic>{
      ...entry,
      'clientId': clientId,
      'client_id': clientId,
    };
  }

  Future<void> _pickInvoiceLinkForRow(
    _ChatMessage message,
    Map<String, dynamic> row,
  ) async {
    final entryId = _rowEntryId(row);
    if (entryId == null || _runtime.sending) return;
    final isEs = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('es');
    final stateKey = _invoiceLinkKey(_messageKey(message), entryId);
    var entry = await _entryWithResolvedInvoiceIds(
      _statementEntryFromInsightsRow(row),
      row,
    );
    if (!mounted) return;
    final controller = StatementsController(groupId: widget.groupId)
      ..entries = <Map<String, dynamic>>[entry]
      ..allEntries = <Map<String, dynamic>>[entry];
    await controller.loadClients();
    entry = _entryWithResolvedClientId(entry, controller.clients);
    controller
      ..entries = <Map<String, dynamic>>[entry]
      ..allEntries = <Map<String, dynamic>>[entry];
    if (!mounted) {
      controller.dispose();
      return;
    }
    await StatementsShared.showInvoiceLinkDialog(
      context,
      controller,
      entry,
      expenseOnly: false,
    );
    final updated = (controller.entries.isNotEmpty
            ? controller.entries.first
            : controller.allEntries.isNotEmpty
                ? controller.allEntries.first
                : entry)
        .cast<String, dynamic>();
    controller.dispose();
    if (!mounted) return;
    final edit = _linkEditFromStatementEntry(updated, row, isEs);
    if (edit == null) return;
    setState(() {
      _pendingInvoiceLinkEdits[stateKey] = edit;
    });
    await _runtime.updateTableRow(
      message: message,
      entryId: entryId,
      rowPatch: _insightsRowPatchFromLinkedEntry(updated, edit, isEs),
    );
  }

  Widget _buildInvoiceLinkStatusCell(
    BuildContext context, {
    required _ChatMessage message,
    required Map<String, dynamic> row,
    required String value,
    required ColorScheme cs,
    required AppTypography t,
  }) {
    final entryId = _rowEntryId(row);
    final canEdit = entryId != null;
    final messageKey = _messageKey(message);
    final stateKey =
        entryId == null ? '' : _invoiceLinkKey(messageKey, entryId);
    final pending = entryId == null ? null : _pendingInvoiceLinkEdits[stateKey];
    final bulkError = entryId == null ? null : _bulkLinkErrors[entryId];
    final isEs = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('es');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final actionBackground =
        isDark ? cs.primary.withValues(alpha: 0.08) : const Color(0xFFEAF3FF);
    final actionBorder =
        isDark ? cs.primary.withValues(alpha: 0.18) : const Color(0xFFBDD3F0);
    final actionForeground = isDark ? cs.primary : const Color(0xFF245C99);
    final editLabel = (row['hasExistingInvoiceLink'] == true ||
            (row['linkStatus']?.toString() == 'linked'))
        ? (isEs ? 'Editar vínculo' : 'Edit link')
        : (isEs ? 'Vincular' : 'Link');

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 170),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (canEdit) ...[
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                InkWell(
                  onTap: () => _pickInvoiceLinkForRow(message, row),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: actionBackground,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: actionBorder,
                      ),
                    ),
                    child: Text(
                      editLabel,
                      style: t.caption.copyWith(
                        color: actionForeground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (pending != null) ...[
            const SizedBox(height: 4),
            Text(
              pending.displayLabel,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: t.caption.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (bulkError != null && bulkError.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              bulkError,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: t.caption.copyWith(
                color: cs.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransactionLinkedStateCell(
    Map<String, dynamic> row, {
    required ColorScheme cs,
    required AppTypography t,
    required bool isEs,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final linked = _rowHasExistingInvoiceLink(row);
    final color = linked
        ? (isDark ? Colors.greenAccent : const Color(0xFF0F9F72))
        : (isDark ? cs.onSurfaceVariant : const Color(0xFF526173));
    final background = linked
        ? (isDark
            ? Colors.greenAccent.withValues(alpha: 0.16)
            : const Color(0xFFE5F8F1))
        : (isDark
            ? cs.onSurfaceVariant.withValues(alpha: 0.08)
            : const Color(0xFFF2F5F8));
    final border = linked
        ? (isDark
            ? Colors.greenAccent.withValues(alpha: 0.28)
            : const Color(0xFFAEE7D4))
        : (isDark
            ? cs.onSurfaceVariant.withValues(alpha: 0.16)
            : const Color(0xFFD5DCE5));
    final label = linked ? (isEs ? 'Sí' : 'Yes') : 'No';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            linked ? Icons.link_rounded : Icons.link_off_rounded,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: t.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic>? _linkInvoiceToEntryAction(Map<String, dynamic> row) {
    final actions = row['actions'];
    if (actions is List) {
      for (final raw in actions) {
        final action = _safeMap(raw);
        if (action == null) continue;
        if (action['type']?.toString().trim() == 'link_invoice_to_entry') {
          return action;
        }
      }
    }
    final action = _safeMap(row['action']);
    if (action?['type']?.toString().trim() == 'link_invoice_to_entry') {
      return action;
    }
    return null;
  }

  Map<String, dynamic>? _bankIncomeSearchPayload(
    Map<String, dynamic>? response,
  ) {
    if (response == null) return null;
    if (response['rows'] is List ||
        response['columns'] is List ||
        _safeMap(response['table'])?['rows'] is List ||
        _safeMap(response['table'])?['columns'] is List) {
      return response;
    }
    for (final key in const ['table', 'data', 'result', 'payload']) {
      final nested = _safeMap(response[key]);
      final payload = _bankIncomeSearchPayload(nested);
      if (payload != null) return payload;
    }
    return response;
  }

  List<Map<String, dynamic>> _bankIncomeCandidateRowsFromResponse(
    Map<String, dynamic>? response,
  ) {
    final payload = _bankIncomeSearchPayload(response);
    final table = _safeMap(payload?['table']);
    final rows = table?['rows'] ?? payload?['rows'];
    if (rows is! List) return const <Map<String, dynamic>>[];
    return rows
        .map((item) => _safeMap(item))
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _candidateColumnsFromTable(
    Map<String, dynamic>? table,
    List<Map<String, dynamic>> rows,
  ) {
    final columns = table?['columns'];
    if (columns is List) {
      final parsed = columns
          .map((item) => _safeMap(item))
          .whereType<Map<String, dynamic>>()
          .where((column) {
        final key = column['key']?.toString() ?? '';
        return key.isNotEmpty && key != 'actions';
      }).toList(growable: false);
      if (parsed.isNotEmpty) return parsed;
    }
    final first = rows.isNotEmpty ? rows.first : const <String, dynamic>{};
    return first.keys
        .where((key) => key != 'actions' && _safeMap(first[key]) == null)
        .take(6)
        .map((key) => {'key': key, 'label': key})
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _bankIncomeCandidateColumnsFromResponse(
    Map<String, dynamic>? response,
    List<Map<String, dynamic>> rows,
  ) {
    final payload = _bankIncomeSearchPayload(response);
    final table = _safeMap(payload?['table']);
    final columns = table?['columns'] ?? payload?['columns'];
    if (columns is List) {
      final parsed = columns
          .map((item) => _safeMap(item))
          .whereType<Map<String, dynamic>>()
          .where((column) {
        final key = column['key']?.toString() ?? '';
        return key.isNotEmpty && key != 'actions';
      }).toList(growable: false);
      if (parsed.isNotEmpty) return parsed;
    }
    return _candidateColumnsFromTable(null, rows);
  }

  double _bankIncomeCandidateColumnWidth(Map<String, dynamic> column) {
    final width = num.tryParse(column['width']?.toString() ?? '');
    if (width != null && width > 0) return width.clamp(96, 240).toDouble();
    final key = column['key']?.toString().toLowerCase() ?? '';
    final align = column['align']?.toString();
    if (align == 'right' || key.contains('amount') || key.contains('importe')) {
      return 132;
    }
    if (key.contains('date') || key.contains('fecha')) return 118;
    return 170;
  }

  Future<Map<String, dynamic>?> _showBankIncomeCandidatesDialog({
    required Future<Map<String, dynamic>> responseFuture,
    required bool isEs,
  }) async {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        final cs = Theme.of(dialogContext).colorScheme;
        final t = AppTypography.of(dialogContext);
        return AlertDialog(
          backgroundColor: cs.surface,
          surfaceTintColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 28,
            vertical: 28,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
            side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.45)),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 22, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 10),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      cs.primary.withValues(alpha: 0.24),
                      cs.secondaryContainer.withValues(alpha: 0.42),
                    ],
                  ),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 18,
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isEs ? 'Ingresos candidatos' : 'Income candidates',
                  style: t.titleLarge.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          content: Container(
            width: 900,
            height: 430,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cs.surfaceContainerHighest.withValues(alpha: 0.30),
                  cs.surfaceContainerLow.withValues(alpha: 0.12),
                ],
              ),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.28),
              ),
            ),
            padding: const EdgeInsets.all(14),
            child: FutureBuilder<Map<String, dynamic>>(
              future: responseFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(strokeWidth: 2.5),
                        const SizedBox(height: 12),
                        Text(
                          isEs
                              ? 'Buscando ingresos bancarios...'
                              : 'Searching bank income...',
                          style: t.bodySmall.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  final msg = snapshot.error
                      .toString()
                      .replaceFirst('Exception: ', '')
                      .trim();
                  return Center(
                    child: Text(
                      msg.isEmpty
                          ? (isEs
                              ? 'No se pudo buscar ingresos.'
                              : 'Could not search income.')
                          : msg,
                      textAlign: TextAlign.center,
                      style: t.bodySmall.copyWith(
                        color: cs.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                }

                final response = snapshot.data;
                final rows = _bankIncomeCandidateRowsFromResponse(response);
                final columns = _bankIncomeCandidateColumnsFromResponse(
                  response,
                  rows,
                );
                debugPrint(
                  'bank income search response rows=${rows.length} columns=${columns.length}',
                );
                if (rows.isEmpty) {
                  debugPrint(
                    'bank income search response ${jsonEncode(response)}',
                  );
                  return Center(
                    child: Text(
                      isEs
                          ? 'No hay ingresos candidatos para esta factura.'
                          : 'No income candidates found for this invoice.',
                      textAlign: TextAlign.center,
                      style: t.bodySmall.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                }

                final columnWidths = [
                  for (final column in columns)
                    _bankIncomeCandidateColumnWidth(column),
                ];
                final tableWidth = (columnWidths.fold<double>(
                          0,
                          (sum, width) => sum + width,
                        ) +
                        132)
                    .clamp(720, 1280)
                    .toDouble();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEs
                          ? '${rows.length} ingreso${rows.length == 1 ? '' : 's'} encontrado${rows.length == 1 ? '' : 's'}'
                          : '${rows.length} income candidate${rows.length == 1 ? '' : 's'} found',
                      style: t.caption.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: tableWidth,
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cs.surfaceContainerHighest
                                        .withValues(alpha: 0.42),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: cs.outlineVariant
                                          .withValues(alpha: 0.28),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      for (int i = 0; i < columns.length; i++)
                                        SizedBox(
                                          width: columnWidths[i],
                                          child: Text(
                                            columns[i]['label']?.toString() ??
                                                columns[i]['key']?.toString() ??
                                                '',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: t.caption.copyWith(
                                              color: cs.onSurfaceVariant,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      const SizedBox(width: 108),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: ListView.separated(
                                    itemCount: rows.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (_, index) {
                                      final row = rows[index];
                                      final action =
                                          _linkInvoiceToEntryAction(row);
                                      final canLink = action != null;
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: cs.surfaceContainerHighest
                                              .withValues(alpha: 0.22),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                            color: cs.outlineVariant
                                                .withValues(alpha: 0.20),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            for (int i = 0;
                                                i < columns.length;
                                                i++)
                                              SizedBox(
                                                width: columnWidths[i],
                                                child: Text(
                                                  row[columns[i]['key']
                                                                  ?.toString() ??
                                                              '']
                                                          ?.toString() ??
                                                      '',
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: t.bodySmall.copyWith(
                                                    color: cs.onSurface,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            const SizedBox(width: 12),
                                            SizedBox(
                                              height: 34,
                                              child: FilledButton.tonalIcon(
                                                style: FilledButton.styleFrom(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 14,
                                                  ),
                                                  visualDensity:
                                                      VisualDensity.compact,
                                                ),
                                                onPressed: canLink
                                                    ? () => Navigator.of(
                                                          dialogContext,
                                                        ).pop(row)
                                                    : null,
                                                icon: const Icon(
                                                  Icons.link_rounded,
                                                  size: 15,
                                                ),
                                                label: Text(
                                                  action?['label']
                                                          ?.toString() ??
                                                      (isEs
                                                          ? 'Vincular'
                                                          : 'Link'),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(isEs ? 'Cerrar' : 'Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _searchAndLinkBankIncomeForInvoiceRow(
    _ChatMessage message,
    Map<String, dynamic> row,
    bool isEs,
  ) async {
    final searchAction = _rowBankIncomeSearchAction(row);
    if (searchAction == null) return;
    final invoiceId = _invoiceIdFromInsightsInvoiceRow(row);
    final stateKey = '${_messageKey(message)}::$invoiceId';
    if (_searchingBankIncomeRows.contains(stateKey) ||
        _linkingBankIncomeRows.contains(stateKey)) {
      return;
    }
    setState(() => _searchingBankIncomeRows.add(stateKey));
    try {
      final responseFuture = _runtime.executeJsonAction(searchAction);
      final candidate = await _showBankIncomeCandidatesDialog(
        responseFuture: responseFuture,
        isEs: isEs,
      );
      if (!mounted || candidate == null) return;
      final linkAction = _linkInvoiceToEntryAction(candidate);
      if (linkAction == null) {
        throw Exception(isEs
            ? 'El ingreso no incluye accion de vinculo.'
            : 'The income candidate has no link action.');
      }
      setState(() => _linkingBankIncomeRows.add(stateKey));
      await _runtime.executeJsonAction(linkAction);
      await _runtime.refreshMessageFromSourceAction(
        message: message,
        groupId: widget.groupId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEs ? 'Ingreso vinculado a la factura.' : 'Income linked.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            msg.isEmpty
                ? (isEs ? 'No se pudo vincular.' : 'Could not link.')
                : msg,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _searchingBankIncomeRows.remove(stateKey);
          _linkingBankIncomeRows.remove(stateKey);
        });
      }
    }
  }

  Widget _buildBankIncomeSearchCell(
    BuildContext context, {
    required _ChatMessage message,
    required Map<String, dynamic> row,
    required ColorScheme cs,
    required AppTypography t,
    required bool isEs,
  }) {
    final action = _rowBankIncomeSearchAction(row);
    if (action == null) return const SizedBox.shrink();
    final invoiceId = _invoiceIdFromInsightsInvoiceRow(row);
    final stateKey = '${_messageKey(message)}::$invoiceId';
    final loading = _searchingBankIncomeRows.contains(stateKey) ||
        _linkingBankIncomeRows.contains(stateKey);
    final label = action['label']?.toString().trim().isNotEmpty == true
        ? action['label'].toString().trim()
        : (isEs ? 'Buscar ingreso' : 'Find income');
    return Tooltip(
      message: label,
      child: IconButton.filledTonal(
        onPressed: loading
            ? null
            : () => _searchAndLinkBankIncomeForInvoiceRow(message, row, isEs),
        icon: loading
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: cs.primary,
                ),
              )
            : const Icon(Icons.manage_search_rounded, size: 16),
        constraints: const BoxConstraints.tightFor(width: 30, height: 30),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        style: IconButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: cs.primary.withValues(alpha: 0.16),
          foregroundColor: cs.primary,
          disabledBackgroundColor:
              cs.surfaceContainerHighest.withValues(alpha: 0.35),
          disabledForegroundColor: cs.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildUnlinkedInvoiceStatusCell({
    required String value,
    required ColorScheme cs,
    required AppTypography t,
    required bool isDark,
  }) {
    const accent = Color(0xFFFFB020);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.16 : 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.42)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.link_off_rounded,
            size: 13,
            color: isDark ? accent : const Color(0xFF9A5B00),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.caption.copyWith(
              color: isDark ? accent : const Color(0xFF7A4600),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  String? _resolveSelectedAssistantKey(List<_ChatMessage> messages) {
    if (_selectedAssistantMessageKey != null) {
      for (final message in messages) {
        if (!message.isUser &&
            _messageKey(message) == _selectedAssistantMessageKey &&
            _messageHasStructuredTable(message)) {
          return _selectedAssistantMessageKey;
        }
      }
    }
    for (final message in messages.reversed) {
      if (!message.isUser && _messageHasStructuredTable(message)) {
        return _messageKey(message);
      }
    }
    return null;
  }

  _ChatMessage? _findMessageByKey(List<_ChatMessage> messages, String? key) {
    if (key == null) return null;
    for (final message in messages) {
      if (_messageKey(message) == key) return message;
    }
    return null;
  }

  void _selectAssistantMessage(_ChatMessage message) {
    if (message.isUser) return;
    setState(() => _selectedAssistantMessageKey = _messageKey(message));
  }

  Future<void> _exportMessageToExcel(_ChatMessage message) async {
    if (_exportingMessageKey != null) return;
    final key = _messageKey(message);
    setState(() => _exportingMessageKey = key);
    try {
      final action = _getExportActionFromMessage(message);
      if (action == null) {
        throw Exception('Missing export action');
      }
      final messages = _runtime.messages;
      final messageIndex = messages.indexWhere(
        (candidate) => identical(candidate, message),
      );
      debugPrint(
        '[insights_export] messageKey=$key index=$messageIndex '
        'endpoint=${action.endpoint} method=${action.method} '
        'body=${jsonEncode(action.body)}',
      );
      final export = await _runtime.downloadExcelFromAction(action);
      debugPrint(
        '[insights_export] messageKey=$key contentType=${export.mimeType} '
        'size=${export.bytes.lengthInBytes} filename=${export.fileName} '
        'downloadJobId=${export.downloadJobId} '
        'downloadJobUrl=${export.downloadJobUrl}',
      );
      if ((export.downloadJobId?.trim().isNotEmpty ?? false)) {
        unawaited(
          DownloadJobsStore.instance.fetchJob(export.downloadJobId!.trim()),
        );
      }
      await launchFileDownload(
        export.bytes,
        fileName: export.fileName,
        mimeType: export.mimeType,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Localizations.localeOf(context).languageCode == 'es'
                ? 'Descargando Excel'
                : 'Downloading Excel',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo descargar el Excel'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _exportingMessageKey = null);
      }
    }
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
      _inputCtrl.clear();
      setState(() {
        _selectedAssistantMessageKey = null;
        _exportingMessageKey = null;
        _eventActionMessageKey = null;
      });
      await _runtime.clearChat(context);
    }
  }

  @override
  void dispose() {
    _runtime.removeListener(_onRuntimeChanged);
    _runtime.setSheetOpen(false, notify: false);
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      final target = _scrollCtrl.position.maxScrollExtent + 120;
      if (!target.isFinite) return;
      _scrollCtrl.animateTo(
        target,
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

  // ── Formatted response renderer ───────────────────────────────────────────

  // ignore: unused_element
  Widget _buildFormattedResponse(
    BuildContext context, {
    required String text,
    required ColorScheme cs,
    required AppTypography t,
  }) {
    final sanitized = _sanitizeModelOutput(text);
    final lines = sanitized.split('\n');
    final widgets = <Widget>[];
    final numListPattern = RegExp(r'^\s*(\d+)\.\s+(.+)$');

    final baseStyle = t.bodySmall.copyWith(
      color: cs.onSurface,
      fontSize: 13,
      height: 1.65,
      fontWeight: FontWeight.w500,
    );
    final listItemStyle = baseStyle.copyWith(fontSize: 12.5);
    final mutedStyle = baseStyle.copyWith(
      color: cs.onSurfaceVariant,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    );

    bool prevWasListItem = false;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trimRight();

      // Empty line → spacing
      if (line.trim().isEmpty) {
        widgets.add(SizedBox(height: prevWasListItem ? 10 : 6));
        prevWasListItem = false;
        continue;
      }

      // Numbered list item: "1. ..."
      final numMatch = numListPattern.firstMatch(line);
      if (numMatch != null) {
        final number = numMatch.group(1)!;
        final content = numMatch.group(2)!;

        // Thin separator between consecutive list items
        if (prevWasListItem) {
          widgets.add(Divider(
            height: 1,
            thickness: 1,
            color: cs.outlineVariant.withValues(alpha: 0.15),
          ));
        }

        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 22,
                child: Text(
                  '$number.',
                  style: mutedStyle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: SelectableText.rich(
                  TextSpan(
                    children: _markdownBoldSpans(
                      text: content,
                      baseStyle: listItemStyle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ));
        prevWasListItem = true;
        continue;
      }

      // Normal line
      prevWasListItem = false;
      widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: SelectableText.rich(
          TextSpan(
            children: _markdownBoldSpans(text: line, baseStyle: baseStyle),
          ),
        ),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
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
    // Remove markdown horizontal rules (---, ===, ___)
    out = out.replaceAll(RegExp(r'^[-=_]{3,}\s*$', multiLine: true), '');
    out = out.replaceAll(RegExp(r'[ ]{2,}'), ' ');
    out = out.replaceAll(RegExp(r'[ \t]+\n'), '\n');
    out = out.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return out.trim();
  }

  String _formatChatTime(DateTime value) {
    final hh = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Widget _buildStarterQuestionCard(
    BuildContext context, {
    required ColorScheme cs,
    required AppTypography t,
    required bool isEs,
  }) {
    final options = <_InsightsMenuOption>[
      _InsightsMenuOption(index: 1, label: isEs ? 'Ingresos' : 'Revenue'),
      _InsightsMenuOption(index: 2, label: isEs ? 'Gastos' : 'Expenses'),
      _InsightsMenuOption(index: 3, label: isEs ? 'Facturas' : 'Invoices'),
      _InsightsMenuOption(index: 4, label: isEs ? 'Clientes' : 'Clients'),
      _InsightsMenuOption(index: 5, label: isEs ? 'Crear evento' : 'Create event'),
    ];
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.26),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      size: 16,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isEs
                          ? 'Elige un area para empezar'
                          : 'Choose an area to start',
                      style: t.bodySmall.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final option in options)
                    ActionChip(
                      onPressed: _runtime.sending
                          ? null
                          : option.index == 5
                              ? () => _prefillEventCreationShortcut(isEs)
                              : () => _sendStarterChoice(option),
                      avatar: CircleAvatar(
                        radius: 10,
                        backgroundColor: cs.primary.withValues(alpha: 0.16),
                        child: Text(
                          '${option.index}',
                          style: t.bodySmall.copyWith(
                            color: cs.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      backgroundColor: cs.primary.withValues(alpha: 0.08),
                      side: BorderSide.none,
                      label: Text(
                        option.label,
                        style: t.bodySmall.copyWith(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
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

  bool _messageHasStructuredTable(_ChatMessage message) {
    if (message.view != 'table') return false;
    final rows = message.table?['rows'];
    return rows is List && rows.isNotEmpty;
  }

  Widget _buildMenuActions(
    BuildContext context, {
    required _ChatMessage message,
    required ColorScheme cs,
    required AppTypography t,
    required bool isEs,
    bool compact = false,
    bool selected = false,
  }) {
    final menu = message.menu;
    final followUps = (menu?.hasOptions ?? false)
        ? const <String>[]
        : (message.followUps ?? const <String>[])
            .where((item) => !_looksLikeExcelExportOption(item))
            .toList(growable: false);
    final menuOptions = (menu?.options ?? const <_InsightsMenuOption>[])
        .where((option) => !_isExcelExportMenuOption(option))
        .toList(growable: false);
    final hasBack = menu?.hasBackAction ?? false;
    final hasMenuOptions = menuOptions.isNotEmpty;
    final hasLegacyFollowUps = followUps.isNotEmpty;
    if (!hasBack && !hasMenuOptions && !hasLegacyFollowUps) {
      return const SizedBox.shrink();
    }

    final title = menu?.title?.trim();
    final titleText = (title != null && title.isNotEmpty)
        ? title
        : (isEs ? 'Opciones' : 'Options');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                titleText,
                style: t.bodySmall.copyWith(
                  color: cs.onSurfaceVariant,
                  fontSize: compact ? 11.5 : 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (hasBack)
              TextButton.icon(
                onPressed: _runtime.sending
                    ? null
                    : () => _sendMenuBack(menu!, message: message),
                icon: const Icon(Icons.arrow_back_rounded, size: 14),
                label: const Text('Back'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: selected ? cs.primary : cs.onSurfaceVariant,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in menuOptions)
              ActionChip(
                onPressed: _runtime.sending
                    ? null
                    : () => _sendMenuChoice(
                          option.index,
                          action: option.action,
                          label: option.label,
                          message: message,
                        ),
                avatar: CircleAvatar(
                  radius: 10,
                  backgroundColor: cs.primary.withValues(alpha: 0.16),
                  child: Text(
                    '${option.index}',
                    style: t.bodySmall.copyWith(
                      color: cs.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                backgroundColor: selected
                    ? cs.primary.withValues(alpha: 0.14)
                    : cs.surfaceContainerHigh.withValues(alpha: 0.42),
                side: BorderSide.none,
                label: Text(
                  option.label,
                  style: t.bodySmall.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: compact ? 11.5 : 12,
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
            for (int index = 0; index < followUps.length; index++)
              ActionChip(
                onPressed: _runtime.sending
                    ? null
                    : () => _sendMenuChoice(index + 1, message: message),
                avatar: CircleAvatar(
                  radius: 10,
                  backgroundColor: cs.primary.withValues(alpha: 0.16),
                  child: Text(
                    '${index + 1}',
                    style: t.bodySmall.copyWith(
                      color: cs.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                backgroundColor: selected
                    ? cs.primary.withValues(alpha: 0.14)
                    : cs.surfaceContainerHigh.withValues(alpha: 0.42),
                side: BorderSide.none,
                label: Text(
                  followUps[index],
                  style: t.bodySmall.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: compact ? 11.5 : 12,
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
          ],
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _tableColumnsFromMessage(_ChatMessage message) {
    final columns = message.table?['columns'];
    if (columns is! List) return const [];
    return columns
        .map((item) => _safeMap(item))
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _tableRowsFromMessage(_ChatMessage message) {
    final rows = message.table?['rows'];
    if (rows is! List) return const [];
    return rows
        .map((item) => _safeMap(item))
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

  Map<String, dynamic>? _tableSummaryFromMessage(_ChatMessage message) {
    return _safeMap(message.table?['summary']);
  }

  Widget _buildInsightsTableView(
    BuildContext context, {
    required _ChatMessage message,
    required ColorScheme cs,
    required AppTypography t,
  }) {
    final l = AppLocalizations.of(context)!;
    final isEs = l.localeName.toLowerCase().startsWith('es');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColumns = _tableColumnsFromMessage(message);
    final rows = _tableRowsFromMessage(message)
        .map((row) => _rowWithPendingLink(message, row))
        .toList(growable: false);
    final supportsManualLinking = _messageSupportsManualInvoiceLink(message);
    final hasEditableLinkRows = rows.any((row) => _rowEntryId(row) != null);
    final hasManualLinking = supportsManualLinking && hasEditableLinkRows;
    final columnsWithLinkedState = supportsManualLinking
        ? _columnsWithTransactionLinkedState(baseColumns, isEs: isEs)
        : baseColumns;
    final columns = hasManualLinking
        ? columnsWithLinkedState
        : columnsWithLinkedState
            .where((column) => column['key']?.toString() != 'linkStatusLabel')
            .toList(growable: false);
    final summary = _tableSummaryFromMessage(message);
    final dataRows = rows
        .where((row) => row['isSummaryRow'] != true)
        .toList(growable: false);
    final hasBankIncomeSearch = _rowsHaveBankIncomeSearch(dataRows);
    final displayedColumns = hasBankIncomeSearch
        ? _columnsWithBankIncomeSearchAction(columns, isEs: isEs)
        : columns;
    final bulkLinkableRows = hasManualLinking
        ? _bulkLinkableRows(dataRows)
        : const <Map<String, dynamic>>[];
    if (hasManualLinking) {
      unawaited(_hydrateLinkedInvoiceDisplayFields(message, dataRows, isEs));
    }
    final summaryRow = rows.cast<Map<String, dynamic>?>().firstWhere(
          (row) => row?['isSummaryRow'] == true,
          orElse: () => null,
        );
    final hasMore = message.table?['hasMore'] == true;
    final truncatedTo = message.table?['truncatedTo'];
    final totalAvailable = message.table?['totalAvailable'];
    final summaryLabel = summary?['label']?.toString().trim().isNotEmpty == true
        ? summary!['label'].toString().trim()
        : (summaryRow?['label']?.toString().trim().isNotEmpty == true
            ? summaryRow!['label'].toString().trim()
            : null);
    final rightAlignedColumnKey = displayedColumns
        .firstWhere(
          (column) => column['align']?.toString() == 'right',
          orElse: () => const <String, dynamic>{},
        )['key']
        ?.toString();
    final summaryAmount =
        summary?['amountFormatted']?.toString().trim().isNotEmpty == true
            ? summary!['amountFormatted'].toString().trim()
            : ((rightAlignedColumnKey != null &&
                    rightAlignedColumnKey.isNotEmpty &&
                    summaryRow?[rightAlignedColumnKey]
                            ?.toString()
                            .trim()
                            .isNotEmpty ==
                        true)
                ? summaryRow![rightAlignedColumnKey].toString().trim()
                : '');

    const lightHeaderBackground = Color(0xFFEAF2FF);
    const lightHeaderForeground = Color(0xFF24364B);
    const lightTableBorder = Color(0xFFDCE4F0);
    const lightRowEven = Color(0xFFFFFFFF);
    const lightRowOdd = Color(0xFFF8FAFD);
    const lightRowHover = Color(0xFFF1F6FF);
    const lightUnlinkedRow = Color(0xFFFFFBF3);

    final headerStyle = t.bodySmall.copyWith(
      color: isDark ? cs.onSurfaceVariant : lightHeaderForeground,
      fontWeight: FontWeight.w700,
      fontSize: 12,
    );
    final cellStyle = t.bodySmall.copyWith(
      color: isDark ? cs.onSurface : const Color(0xFF344052),
      fontWeight: FontWeight.w500,
      fontSize: 12.5,
      height: 1.35,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (bulkLinkableRows.isNotEmpty) ...[
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonalIcon(
              onPressed: _bulkLinkingInvoices
                  ? null
                  : () => _linkAllSuggestedInvoices(
                        message,
                        dataRows,
                        isEs,
                      ),
              icon: _bulkLinkingInvoices
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.primary,
                      ),
                    )
                  : const Icon(Icons.link_rounded, size: 16),
              label: Text(
                isEs
                    ? 'Vincular sugeridas (${bulkLinkableRows.length})'
                    : 'Link suggested (${bulkLinkableRows.length})',
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        Scrollbar(
          thumbVisibility: true,
          notificationPredicate: (notification) =>
              notification.metrics.axis == Axis.horizontal,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            primary: false,
            child: Container(
              constraints: const BoxConstraints(minWidth: 620),
              decoration: BoxDecoration(
                color: isDark
                    ? cs.surfaceContainerHighest.withValues(alpha: 0.16)
                    : lightRowEven,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? cs.outlineVariant.withValues(alpha: 0.28)
                      : lightTableBorder,
                ),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color:
                              const Color(0xFF274060).withValues(alpha: 0.06),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
              ),
              clipBehavior: Clip.antiAlias,
              child: DataTable(
                headingRowHeight: 38,
                dataRowMinHeight: hasManualLinking ? 54 : 38,
                dataRowMaxHeight: hasManualLinking ? 88 : 46,
                horizontalMargin: 14,
                columnSpacing: 18,
                dividerThickness: 0.5,
                headingRowColor: WidgetStateProperty.all(
                  isDark
                      ? cs.surfaceContainerHighest.withValues(alpha: 0.55)
                      : lightHeaderBackground,
                ),
                headingTextStyle: headerStyle,
                dataTextStyle: cellStyle,
                columns: [
                  for (final column in displayedColumns)
                    DataColumn(
                      numeric: column['align']?.toString() == 'right',
                      label: Text(column['label']?.toString() ?? ''),
                    ),
                ],
                rows: [
                  for (final entry in dataRows.asMap().entries)
                    DataRow(
                      color: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.hovered)) {
                          return isDark
                              ? cs.primary.withValues(alpha: 0.08)
                              : lightRowHover;
                        }
                        if (_rowIsUnlinkedInvoice(entry.value)) {
                          return isDark
                              ? const Color(0xFFFFB020).withValues(alpha: 0.075)
                              : lightUnlinkedRow;
                        }
                        if (isDark) return null;
                        return entry.key.isEven ? lightRowEven : lightRowOdd;
                      }),
                      cells: [
                        for (final column in displayedColumns)
                          DataCell(
                            Tooltip(
                              message: _tableCellValue(entry.value, column),
                              waitDuration: const Duration(milliseconds: 350),
                              child: column['key']?.toString() ==
                                      '__bankIncomeSearchAction'
                                  ? _buildBankIncomeSearchCell(
                                      context,
                                      message: message,
                                      row: entry.value,
                                      cs: cs,
                                      t: t,
                                      isEs: isEs,
                                    )
                                  : column['key']?.toString() ==
                                          'linkStatusLabel'
                                      ? _buildInvoiceLinkStatusCell(
                                          context,
                                          message: message,
                                          row: entry.value,
                                          value: _tableCellValue(
                                            entry.value,
                                            column,
                                          ),
                                          cs: cs,
                                          t: t,
                                        )
                                      : column['key']?.toString() ==
                                              'transactionLinkedStateLabel'
                                          ? _buildTransactionLinkedStateCell(
                                              entry.value,
                                              cs: cs,
                                              t: t,
                                              isEs: isEs,
                                            )
                                          : Align(
                                              alignment:
                                                  column['align']?.toString() ==
                                                          'right'
                                                      ? Alignment.centerRight
                                                      : Alignment.centerLeft,
                                              child: ConstrainedBox(
                                                constraints: BoxConstraints(
                                                  maxWidth: (column['key']
                                                                  ?.toString() ==
                                                              'description' ||
                                                          column['key']
                                                                  ?.toString() ==
                                                              'concept')
                                                      ? 360
                                                      : 180,
                                                ),
                                                child: _rowIsUnlinkedInvoice(
                                                          entry.value,
                                                        ) &&
                                                        _isInvoiceStatusColumn(
                                                          column,
                                                        )
                                                    ? _buildUnlinkedInvoiceStatusCell(
                                                        value: _tableCellValue(
                                                          entry.value,
                                                          column,
                                                        ),
                                                        cs: cs,
                                                        t: t,
                                                        isDark: isDark,
                                                      )
                                                    : Text(
                                                        _tableCellValue(
                                                          entry.value,
                                                          column,
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        textAlign: column[
                                                                        'align']
                                                                    ?.toString() ==
                                                                'right'
                                                            ? TextAlign.right
                                                            : TextAlign.left,
                                                        style: cellStyle,
                                                      ),
                                              ),
                                            ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
        if ((summaryLabel != null && summaryLabel.isNotEmpty) ||
            summaryAmount.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: isDark ? 0.12 : 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    summaryLabel ??
                        (hasMore
                            ? (isEs ? 'Total mostrado' : 'Displayed total')
                            : (isEs ? 'Total periodo' : 'Period total')),
                    style: t.bodySmall.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),
                ),
                if (summaryAmount.isNotEmpty)
                  SizedBox(
                    width: 180,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        summaryAmount,
                        textAlign: TextAlign.right,
                        style: t.bodySmall.copyWith(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (hasMore) const SizedBox(height: 14),
        if (hasMore)
          Text(
            _isFiniteNum(totalAvailable) && _isFiniteNum(truncatedTo)
                ? (isEs
                    ? 'Mostrando ${truncatedTo.toInt()} de ${totalAvailable.toInt()} filas.'
                    : 'Showing ${truncatedTo.toInt()} of ${totalAvailable.toInt()} rows.')
                : (isEs
                    ? 'Hay mas resultados disponibles.'
                    : 'More results are available.'),
            style: t.bodySmall.copyWith(
              color: cs.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  Widget _buildIncomeAmountPromptInput(
    BuildContext context, {
    required _ChatMessage promptMessage,
    required ColorScheme cs,
    required AppTypography t,
    required bool isEs,
  }) {
    final sending = _runtime.sending;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: TextField(
        controller: _inputCtrl,
        enabled: !sending,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.send,
        onSubmitted: (_) => _submitIncomeAmountPrompt(promptMessage),
        decoration: InputDecoration(
          hintText: isEs
              ? 'Escribe el importe, ej. 742,70'
              : 'Enter amount, e.g. 742.70',
          prefixIcon: const Icon(Icons.payments_outlined, size: 18),
          suffixIcon: IconButton(
            tooltip: isEs ? 'Enviar importe' : 'Send amount',
            onPressed:
                sending ? null : () => _submitIncomeAmountPrompt(promptMessage),
            icon: const Icon(Icons.send_rounded, size: 18),
          ),
          filled: true,
          fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.28),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: cs.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: cs.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: cs.primary, width: 1.4),
          ),
        ),
        style: t.bodySmall.copyWith(
          color: cs.onSurface,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildChatComposer(
    BuildContext context, {
    required ColorScheme cs,
    required AppTypography t,
    required bool isEs,
  }) {
    final sending = _runtime.sending;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputCtrl,
              enabled: !sending,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submitTypedMessage(),
              decoration: InputDecoration(
                hintText: isEs
                    ? 'Escribe un mensaje o crea un evento con lenguaje natural'
                    : 'Write a message or create an event with natural language',
                filled: true,
                fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.28),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.45),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.45),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: cs.primary, width: 1.4),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
              style: t.bodySmall.copyWith(
                color: cs.onSurface,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: sending ? null : _submitTypedMessage,
            style: FilledButton.styleFrom(
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: sending
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: cs.onPrimary,
                    ),
                  )
                : const Icon(Icons.send_rounded, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildEventPreviewBubble(
    BuildContext context,
    _ChatMessage message,
  ) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final isEs = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('es');
    final preview = _eventPreviewForMessage(message);
    final status = _eventStatus(message);
    final statusColor = _eventStatusColor(cs, status);
    final eventKey = _messageKey(message);
    final busy = _eventActionMessageKey == eventKey;
    final recurrence = _eventRecurrenceSummary(message, isEs);
    final untilDate =
        _eventDate(_safeMap(preview?['recurrenceRule'])?['untilDate']);
    final missing = _stringList(preview?['missing']);
    final assumptions = _stringList(preview?['assumptions']);
    final needsClientAndService = _eventShouldPromptForClientAndService(message);

    Widget infoRow(String label, String value) {
      if (value.trim().isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 104,
              child: Text(
                label,
                style: t.bodySmall.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: t.bodySmall.copyWith(
                  color: cs.onSurface,
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget stringSection(String title, List<String> items, Color color) {
      if (items.isEmpty) return const SizedBox.shrink();
      return Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: t.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 11.5,
              ),
            ),
            const SizedBox(height: 6),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• $item',
                  style: t.bodySmall.copyWith(
                    color: cs.onSurface,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.text.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              message.text.trim(),
              style: t.bodySmall.copyWith(
                color: cs.onSurface,
                fontSize: 12.8,
                height: 1.45,
              ),
            ),
          ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: statusColor.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _eventStatusLabel(status, isEs),
                      style: t.bodySmall.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                  if (_eventIsCancelled(message)) ...[
                    const SizedBox(width: 8),
                    Text(
                      isEs ? 'Cancelado' : 'Cancelled',
                      style: t.bodySmall.copyWith(
                        color: cs.onSurfaceVariant,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
              if (preview != null) ...[
                const SizedBox(height: 12),
                Text(
                  preview['title']?.toString().trim().isNotEmpty == true
                      ? preview['title'].toString().trim()
                      : (isEs ? 'Sin titulo' : 'Untitled'),
                  style: t.bodySmall.copyWith(
                    color: cs.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                infoRow(
                  isEs ? 'Fecha' : 'Date',
                  _eventDateRangeLabel(context, message),
                ),
                  infoRow(
                    isEs ? 'Duracion' : 'Duration',
                    _eventDurationLabel(message, isEs),
                  ),
                if (needsClientAndService)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cs.tertiary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: cs.tertiary.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Text(
                        isEs
                            ? 'Selecciona cliente y servicio para continuar.'
                            : 'Select client and service to continue.',
                        style: t.bodySmall.copyWith(
                          color: cs.onSurface,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                if (recurrence.isNotEmpty)
                  infoRow(isEs ? 'Recurrencia' : 'Recurrence', recurrence),
                if (untilDate != null)
                  infoRow(
                    isEs ? 'Finaliza' : 'Ends',
                    _formatEventDateTime(
                      context,
                      untilDate,
                      allDay: true,
                    ),
                  ),
                if ((preview['localization']?.toString().trim().isNotEmpty ??
                    false))
                  infoRow(
                    isEs ? 'Ubicacion' : 'Location',
                    preview['localization'].toString().trim(),
                  ),
                if ((preview['description']?.toString().trim().isNotEmpty ??
                    false))
                  infoRow(
                    isEs ? 'Descripcion' : 'Description',
                    preview['description'].toString().trim(),
                  ),
                stringSection(
                  isEs ? 'Falta por confirmar' : 'Missing information',
                  missing,
                  cs.tertiary,
                ),
                stringSection(
                  isEs ? 'Suposiciones' : 'Assumptions',
                  assumptions,
                  cs.primary,
                ),
              ],
              if (!_eventIsCancelled(message) && status == 'ready_to_create')
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed:
                            busy || !_eventCanCreate(message) ? null : () => _confirmEventCreation(message),
                        icon: busy
                            ? SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: cs.onPrimary,
                                ),
                              )
                            : const Icon(Icons.check_circle_rounded, size: 16),
                        label: Text(isEs ? 'Crear evento' : 'Create event'),
                      ),
                      OutlinedButton.icon(
                        onPressed: busy ? null : () => _editEventDraft(message),
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        label: Text(isEs ? 'Editar detalles' : 'Edit details'),
                      ),
                      TextButton(
                        onPressed: busy ? null : () => _cancelEventDraft(message),
                        child: Text(isEs ? 'Cancelar' : 'Cancel'),
                      ),
                    ],
                  ),
                ),
              if (status == 'created')
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: FilledButton.tonalIcon(
                    onPressed: _openCalendarForCurrentGroup,
                    icon: const Icon(Icons.calendar_month_rounded, size: 16),
                    label: Text(isEs ? 'Ver en calendario' : 'View in calendar'),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
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
    final isEs = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('es');
    final takingTooLongText = isEs
        ? 'Tardando mas de lo esperado...'
        : 'Taking longer than expected...';
    final retryText = isEs ? 'Reintentar' : 'Retry';
    final quickSummaryText = isEs ? 'Resumen rapido' : 'Quick summary';
    final modeLabel = mode == _InsightsResponseMode.auto
        ? l.insightsChatModeAuto
        : l.insightsChatModeStream;
    final helperText = isEs
        ? 'Contexto activo: ultimos $days dias · modo $modeLabel. Puedes pedir resumenes, tendencias, clientes con mas carga o gastos e ingresos.'
        : 'Active context: last $days days · $modeLabel mode. Ask for summaries, trends, busiest clients, or expense and revenue breakdowns.';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktopEmbedded =
        widget.embedded && MediaQuery.of(context).size.width >= 1180;
    final selectedAssistantKey = _resolveSelectedAssistantKey(messages);
    final selectedAssistantMessage =
        _findMessageByKey(messages, selectedAssistantKey);
    final latestAssistantMessage = _latestAssistantMessage(messages);
    final latestIncomeAmountPromptMessage =
        _latestIncomeAmountPromptMessage(messages);
    final latestAssistantMenuMessage =
        latestIncomeAmountPromptMessage == null &&
                latestAssistantMessage != null &&
                _messageHasMenu(latestAssistantMessage)
            ? latestAssistantMessage
            : null;
    final showComposer = latestIncomeAmountPromptMessage == null;
    final showEmptyComposer = messages.isEmpty && !sending && showComposer;
    final desktopUserMessages =
        messages.where((message) => message.isUser).toList(growable: false);

    Widget buildDesktopMessageList() {
      _ChatMessage? firstReplyForUser(_ChatMessage userMessage) {
        final startIndex = messages.indexOf(userMessage);
        if (startIndex < 0) return null;
        for (int i = startIndex + 1; i < messages.length; i++) {
          final candidate = messages[i];
          if (!candidate.isUser) return candidate;
        }
        return null;
      }

      _ChatMessage? tableReplyForUser(_ChatMessage userMessage) {
        final startIndex = messages.indexOf(userMessage);
        if (startIndex < 0) return null;
        for (int i = startIndex + 1; i < messages.length; i++) {
          final candidate = messages[i];
          if (candidate.isUser) break;
          if (_messageHasStructuredTable(candidate)) return candidate;
        }
        return null;
      }

      if (desktopUserMessages.isEmpty && !sending) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStarterQuestionCard(
                context,
                cs: cs,
                t: t,
                isEs: isEs,
              ),
              if (showEmptyComposer)
                _buildChatComposer(
                  context,
                  cs: cs,
                  t: t,
                  isEs: isEs,
                ),
            ],
          ),
        );
      }

      return ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
        itemCount: desktopUserMessages.length +
            (sending && mode == _InsightsResponseMode.auto ? 1 : 0),
        itemBuilder: (context, index) {
          if (sending && index == desktopUserMessages.length) {
            return Align(
              alignment: Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                decoration: BoxDecoration(
                  color: isDark
                      ? cs.surfaceContainerHighest
                      : cs.surfaceContainerHigh,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                    bottomRight: Radius.circular(14),
                    bottomLeft: Radius.circular(4),
                  ),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.primary,
                      ),
                    ),
                    if (takingTooLong) ...[
                      const SizedBox(width: 10),
                      Text(
                        takingTooLongText,
                        style: t.bodySmall.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }
          final message = desktopUserMessages[index];
          final linkedReply = firstReplyForUser(message);
          final tableReply = tableReplyForUser(message);
          final hasStructuredReply = tableReply != null;
          final isSelected = tableReply != null &&
              _messageKey(tableReply) == selectedAssistantKey;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: tableReply == null
                ? null
                : () => _selectAssistantMessage(tableReply),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? cs.primary.withValues(alpha: isDark ? 0.13 : 0.08)
                    : cs.surfaceContainerHighest.withValues(
                        alpha: isDark ? 0.22 : 0.32,
                      ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? cs.primary.withValues(alpha: 0.38)
                      : cs.outlineVariant
                          .withValues(alpha: isDark ? 0.20 : 0.25),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 3,
                        color: isSelected ? cs.primary : Colors.transparent,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 11, 11, 11),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      cs.primary.withValues(alpha: 0.22),
                                      cs.primary.withValues(alpha: 0.09),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.person_rounded,
                                  size: 14,
                                  color: cs.primary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      message.text,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: t.bodySmall.copyWith(
                                        color: cs.onSurface,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.5,
                                        height: 1.35,
                                      ),
                                    ),
                                    if (linkedReply != null &&
                                        !hasStructuredReply) ...[
                                      const SizedBox(height: 5),
                                      Text(
                                        linkedReply.text,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: t.bodySmall.copyWith(
                                          color: cs.onSurfaceVariant,
                                          fontSize: 11.5,
                                          height: 1.35,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 7),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time_rounded,
                                          size: 10,
                                          color: cs.onSurfaceVariant
                                              .withValues(alpha: 0.65),
                                        ),
                                        const SizedBox(width: 3),
                                        Expanded(
                                          child: Text(
                                            _formatChatTime(message.timestamp),
                                            style: t.bodySmall.copyWith(
                                              color: cs.onSurfaceVariant
                                                  .withValues(alpha: 0.75),
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        if (hasStructuredReply) ...[
                                          const SizedBox(width: 5),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? cs.primary
                                                      .withValues(alpha: 0.18)
                                                  : cs.primary
                                                      .withValues(alpha: 0.10),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.table_chart_rounded,
                                                  size: 9,
                                                  color: cs.primary,
                                                ),
                                                const SizedBox(width: 3),
                                                Text(
                                                  isEs ? 'Tabla' : 'Table',
                                                  style: t.bodySmall.copyWith(
                                                    color: cs.primary,
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        const SizedBox(width: 3),
                                        Icon(
                                          hasStructuredReply
                                              ? Icons.chevron_right_rounded
                                              : Icons.remove_rounded,
                                          size: isSelected ? 12 : 15,
                                          color: isSelected
                                              ? cs.primary
                                                  .withValues(alpha: 0.9)
                                              : cs.onSurfaceVariant
                                                  .withValues(alpha: 0.55),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    Widget buildDesktopResponsePanel() {
      if (selectedAssistantMessage == null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 34,
                  color: cs.primary.withValues(alpha: 0.8),
                ),
                const SizedBox(height: 14),
                Text(
                  isEs ? 'Selecciona una respuesta' : 'Select a response',
                  style: t.bodyLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isEs
                      ? 'A la izquierda veras la conversacion. Selecciona una respuesta del asistente para verla aqui con mas detalle.'
                      : 'Use the left panel for the conversation. Select an assistant response to inspect it here in more detail.',
                  textAlign: TextAlign.center,
                  style: t.bodySmall.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      final exportAction =
          _getExportActionFromMessage(selectedAssistantMessage);
      final selectedKey = _messageKey(selectedAssistantMessage);
      final isTableResponse =
          _messageHasStructuredTable(selectedAssistantMessage);
      if (!isTableResponse) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.table_chart_outlined,
                  size: 34,
                  color: cs.primary.withValues(alpha: 0.8),
                ),
                const SizedBox(height: 14),
                Text(
                  isEs ? 'Sin datos tabulares' : 'No tabular data',
                  style: t.bodyLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isEs
                      ? 'El panel derecho solo muestra respuestas de datos, como tablas y desgloses estructurados.'
                      : 'The right panel only shows data responses such as tables and structured breakdowns.',
                  textAlign: TextAlign.center,
                  style: t.bodySmall.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        );
      }
      final rowCount = _tableRowsFromMessage(selectedAssistantMessage)
          .where((r) => r['isSummaryRow'] != true)
          .length;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color:
                      cs.outlineVariant.withValues(alpha: isDark ? 0.22 : 0.28),
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        cs.primary.withValues(alpha: 0.22),
                        cs.primary.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.table_chart_rounded,
                    size: 16,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            isEs
                                ? 'Respuesta seleccionada'
                                : 'Selected response',
                            style: t.bodySmall.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                              color: cs.onSurface,
                            ),
                          ),
                          if (rowCount > 0) ...[
                            const SizedBox(width: 7),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: cs.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '$rowCount ${isEs ? 'filas' : 'rows'}',
                                style: t.bodySmall.copyWith(
                                  color: cs.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (selectedAssistantMessage.sourceUserMessage
                              ?.trim()
                              .isNotEmpty ==
                          true) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(
                              Icons.search_rounded,
                              size: 11,
                              color:
                                  cs.onSurfaceVariant.withValues(alpha: 0.65),
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                selectedAssistantMessage.sourceUserMessage!
                                    .trim(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: t.bodySmall.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 11.5,
                                  height: 1.3,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (exportAction != null) ...[
                  const SizedBox(width: 8),
                  Tooltip(
                    message: isEs ? 'Descargar Excel' : 'Download Excel',
                    child: IconButton(
                      onPressed: _exportingMessageKey != null
                          ? null
                          : () =>
                              _exportMessageToExcel(selectedAssistantMessage),
                      icon: Icon(
                        _exportingMessageKey == selectedKey
                            ? Icons.hourglass_top_rounded
                            : Icons.download_rounded,
                        size: 17,
                      ),
                      style: IconButton.styleFrom(
                        foregroundColor: cs.primary,
                        backgroundColor: cs.primary.withValues(alpha: 0.10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                        padding: const EdgeInsets.all(7),
                        minimumSize: const Size(34, 34),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              child: _buildInsightsTableView(
                context,
                message: selectedAssistantMessage,
                cs: cs,
                t: t,
              ),
            ),
          ),
        ],
      );
    }

    final panel = Column(
      children: [
        // ── Drag handle + header ─────────────────────────────────────
        Container(
          padding: EdgeInsets.fromLTRB(
            14,
            widget.embedded ? 12 : 10,
            8,
            10,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? cs.surfaceContainerHighest.withValues(alpha: 0.5)
                : cs.surfaceContainerLow.withValues(alpha: 0.7),
            borderRadius: widget.embedded
                ? const BorderRadius.vertical(top: Radius.circular(16))
                : const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              if (!widget.embedded) ...[
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          cs.primary.withValues(alpha: 0.2),
                          cs.primary.withValues(alpha: 0.08),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: cs.primary,
                      size: 15,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l.insightsChatTitle,
                      style: t.bodySmall.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l.insightsChatClearTooltip,
                    onPressed: sending ? null : _confirmClearChat,
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: cs.onSurfaceVariant,
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Toolbar chips ────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          child: SingleChildScrollView(
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
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 11, color: cs.onSurfaceVariant),
                        const SizedBox(width: 5),
                        Text(
                          '${l.insightsChatDaysPrefix}: ${days}d',
                          style: t.bodySmall.copyWith(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  avatar: Icon(
                    Icons.auto_fix_high_rounded,
                    size: 13,
                    color: mode == _InsightsResponseMode.auto
                        ? cs.onPrimaryContainer
                        : cs.onSurfaceVariant,
                  ),
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
                  avatar: Icon(
                    Icons.stream_rounded,
                    size: 13,
                    color: mode == _InsightsResponseMode.stream
                        ? cs.onPrimaryContainer
                        : cs.onSurfaceVariant,
                  ),
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
        ),

        // ── Message list ─────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(
                alpha: isDark ? 0.32 : 0.5,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.insights_rounded,
                  size: 15,
                  color: cs.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    helperText,
                    style: t.bodySmall.copyWith(
                      color: cs.onSurfaceVariant,
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: messages.isEmpty && !sending
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildStarterQuestionCard(
                        context,
                        cs: cs,
                        t: t,
                        isEs: isEs,
                      ),
                      if (showEmptyComposer)
                        _buildChatComposer(
                          context,
                          cs: cs,
                          t: t,
                          isEs: isEs,
                        ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
                  itemCount: messages.length +
                      (sending && mode == _InsightsResponseMode.auto ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (sending && index == messages.length) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? cs.surfaceContainerHighest
                                : cs.surfaceContainerHigh,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(14),
                              topRight: Radius.circular(14),
                              bottomRight: Radius.circular(14),
                              bottomLeft: Radius.circular(4),
                            ),
                            border: Border.all(
                              color: cs.outlineVariant.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: cs.primary,
                                ),
                              ),
                              if (takingTooLong) ...[
                                const SizedBox(width: 10),
                                Text(
                                  takingTooLongText,
                                  style: t.bodySmall.copyWith(
                                    color: cs.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
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
                      isEs: isEs,
                      sending: sending,
                      buildMenuActions: _buildMenuActions,
                      buildEventPreview: _buildEventPreviewBubble,
                      buildStructuredTable: (context, message) =>
                          _buildInsightsTableView(
                        context,
                        message: message,
                        cs: Theme.of(context).colorScheme,
                        t: AppTypography.of(context),
                      ),
                      isStructuredTableResponse: !message.isUser &&
                          _messageHasStructuredTable(message),
                      canExportToExcel: false,
                      isExporting: false,
                      onExportExcel: null,
                      showInlineMenuActions: false,
                    );
                  },
                ),
        ),
        if (latestIncomeAmountPromptMessage != null)
          _buildIncomeAmountPromptInput(
            context,
            promptMessage: latestIncomeAmountPromptMessage,
            cs: cs,
            t: t,
            isEs: isEs,
          ),
        if (error != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: Text(
              error,
              style: t.bodySmall.copyWith(
                color: cs.error,
                fontSize: 12,
              ),
            ),
          ),
        ],
        if (showTimeoutActions) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                OutlinedButton.icon(
                  onPressed: _retryLast,
                  icon: const Icon(Icons.refresh_rounded, size: 14),
                  label: Text(
                    retryText,
                    style: t.bodySmall.copyWith(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: _quickSummary,
                  icon: const Icon(Icons.summarize_outlined, size: 14),
                  label: Text(
                    quickSummaryText,
                    style: t.bodySmall.copyWith(fontSize: 12),
                  ),
                  style: FilledButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (latestAssistantMenuMessage != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: _buildMenuActions(
              context,
              message: latestAssistantMenuMessage,
              cs: cs,
              t: t,
              isEs: isEs,
            ),
          ),
        ],
        if (latestAssistantMenuMessage != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: Text(
              isEs
                  ? 'Selecciona una opcion para continuar.'
                  : 'Select an option to continue.',
              style: t.bodySmall.copyWith(
                color: cs.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        if (showComposer && !showEmptyComposer)
          _buildChatComposer(
            context,
            cs: cs,
            t: t,
            isEs: isEs,
          ),
        SizedBox(height: 10 + bottomInset),
      ],
    );

    if (widget.embedded) {
      if (isDesktopEmbedded) {
        return Container(
          decoration: BoxDecoration(
            color: canvas,
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            bottom: false,
            child: Column(
              children: [
                panel.children.first,
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Container(
                            decoration: BoxDecoration(
                              color: cs.surface
                                  .withValues(alpha: isDark ? 0.20 : 0.35),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: cs.outlineVariant.withValues(
                                  alpha: isDark ? 0.18 : 0.22,
                                ),
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(12, 8, 12, 6),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        PopupMenuButton<int>(
                                          tooltip: l.insightsChatDaysTooltip,
                                          onSelected: _runtime.setDays,
                                          itemBuilder: (context) => const [
                                            PopupMenuItem(
                                                value: 30, child: Text('30d')),
                                            PopupMenuItem(
                                                value: 60, child: Text('60d')),
                                            PopupMenuItem(
                                                value: 90, child: Text('90d')),
                                            PopupMenuItem(
                                                value: 120,
                                                child: Text('120d')),
                                            PopupMenuItem(
                                                value: 180,
                                                child: Text('180d')),
                                          ],
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: canvas,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: cs.outlineVariant
                                                    .withValues(alpha: 0.6),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.calendar_today_rounded,
                                                  size: 11,
                                                  color: cs.onSurfaceVariant,
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  '${l.insightsChatDaysPrefix}: ${days}d',
                                                  style: t.bodySmall.copyWith(
                                                    color: cs.onSurface,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        ChoiceChip(
                                          avatar: Icon(
                                            Icons.auto_fix_high_rounded,
                                            size: 13,
                                            color: mode ==
                                                    _InsightsResponseMode.auto
                                                ? cs.onPrimaryContainer
                                                : cs.onSurfaceVariant,
                                          ),
                                          label: Text(l.insightsChatModeAuto),
                                          selected: mode ==
                                              _InsightsResponseMode.auto,
                                          selectedColor: cs.primaryContainer,
                                          backgroundColor: canvas,
                                          visualDensity: VisualDensity.compact,
                                          labelStyle: t.bodySmall.copyWith(
                                            fontSize: 11,
                                            color: mode ==
                                                    _InsightsResponseMode.auto
                                                ? cs.onPrimaryContainer
                                                : cs.onSurfaceVariant,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          side: BorderSide(
                                            color: cs.outlineVariant
                                                .withValues(alpha: 0.6),
                                          ),
                                          onSelected: sending
                                              ? null
                                              : (_) => _runtime.setMode(
                                                  _InsightsResponseMode.auto),
                                        ),
                                        const SizedBox(width: 6),
                                        ChoiceChip(
                                          avatar: Icon(
                                            Icons.stream_rounded,
                                            size: 13,
                                            color: mode ==
                                                    _InsightsResponseMode.stream
                                                ? cs.onPrimaryContainer
                                                : cs.onSurfaceVariant,
                                          ),
                                          label: Text(l.insightsChatModeStream),
                                          selected: mode ==
                                              _InsightsResponseMode.stream,
                                          selectedColor: cs.primaryContainer,
                                          backgroundColor: canvas,
                                          visualDensity: VisualDensity.compact,
                                          labelStyle: t.bodySmall.copyWith(
                                            fontSize: 11,
                                            color: mode ==
                                                    _InsightsResponseMode.stream
                                                ? cs.onPrimaryContainer
                                                : cs.onSurfaceVariant,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          side: BorderSide(
                                            color: cs.outlineVariant
                                                .withValues(alpha: 0.6),
                                          ),
                                          onSelected: sending
                                              ? null
                                              : (_) => _runtime.setMode(
                                                  _InsightsResponseMode.stream),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(12, 0, 12, 6),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          cs.surfaceContainerHighest.withValues(
                                        alpha: isDark ? 0.32 : 0.5,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.insights_rounded,
                                          size: 15,
                                          color: cs.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            helperText,
                                            style: t.bodySmall.copyWith(
                                              color: cs.onSurfaceVariant,
                                              fontSize: 12,
                                              height: 1.35,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Expanded(child: buildDesktopMessageList()),
                                if (latestIncomeAmountPromptMessage != null)
                                  _buildIncomeAmountPromptInput(
                                    context,
                                    promptMessage:
                                        latestIncomeAmountPromptMessage,
                                    cs: cs,
                                    t: t,
                                    isEs: isEs,
                                  ),
                                if (latestAssistantMenuMessage != null) ...[
                                  Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(12, 4, 12, 0),
                                    child: _buildMenuActions(
                                      context,
                                      message: latestAssistantMenuMessage,
                                      cs: cs,
                                      t: t,
                                      isEs: isEs,
                                    ),
                                  ),
                                ],
                                if (latestAssistantMenuMessage != null) ...[
                                  Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(12, 4, 12, 0),
                                    child: Text(
                                      isEs
                                          ? 'Selecciona una opcion para continuar.'
                                          : 'Select an option to continue.',
                                      style: t.bodySmall.copyWith(
                                        color: cs.onSurfaceVariant,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                                if (error != null) ...[
                                  Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(12, 4, 12, 0),
                                    child: Text(
                                      error,
                                      style: t.bodySmall.copyWith(
                                        color: cs.error,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                                if (showTimeoutActions) ...[
                                  Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(12, 4, 12, 0),
                                    child: Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        OutlinedButton.icon(
                                          onPressed: _retryLast,
                                          icon: const Icon(
                                              Icons.refresh_rounded,
                                              size: 14),
                                          label: Text(
                                            retryText,
                                            style: t.bodySmall
                                                .copyWith(fontSize: 12),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                        ),
                                        FilledButton.tonalIcon(
                                          onPressed: _quickSummary,
                                          icon: const Icon(
                                              Icons.summarize_outlined,
                                              size: 14),
                                          label: Text(
                                            quickSummaryText,
                                            style: t.bodySmall
                                                .copyWith(fontSize: 12),
                                          ),
                                          style: FilledButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                if (showComposer && !showEmptyComposer)
                                  _buildChatComposer(
                                    context,
                                    cs: cs,
                                    t: t,
                                    isEs: isEs,
                                  ),
                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          flex: 9,
                          child: Container(
                            decoration: BoxDecoration(
                              color: cs.surface
                                  .withValues(alpha: isDark ? 0.20 : 0.35),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: cs.outlineVariant.withValues(
                                  alpha: isDark ? 0.18 : 0.22,
                                ),
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: buildDesktopResponsePanel(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      return Container(
        decoration: BoxDecoration(
          color: canvas,
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          bottom: false,
          child: panel,
        ),
      );
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.84,
      decoration: BoxDecoration(
        color: canvas,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: isDark ? 0.45 : 0.55),
        ),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: panel,
      ),
    );
  }
}

class _ChatBubble extends StatefulWidget {
  const _ChatBubble({
    required this.message,
    required this.markdownBoldSpans,
    required this.isEs,
    required this.sending,
    required this.buildMenuActions,
    required this.buildEventPreview,
    required this.buildStructuredTable,
    this.isStructuredTableResponse = false,
    this.canExportToExcel = false,
    this.isExporting = false,
    this.onExportExcel,
    this.showInlineMenuActions = true,
  });

  final _ChatMessage message;
  final List<InlineSpan> Function({
    required String text,
    required TextStyle baseStyle,
  }) markdownBoldSpans;
  final bool isEs;
  final bool sending;
  final bool isStructuredTableResponse;
  final Widget Function(
    BuildContext context,
    _ChatMessage message,
  ) buildEventPreview;
  final Widget Function(
    BuildContext context, {
    required _ChatMessage message,
    required ColorScheme cs,
    required AppTypography t,
    required bool isEs,
    bool compact,
    bool selected,
  }) buildMenuActions;
  final Widget Function(BuildContext context, _ChatMessage message)
      buildStructuredTable;
  final bool canExportToExcel;
  final bool isExporting;
  final VoidCallback? onExportExcel;
  final bool showInlineMenuActions;

  @override
  State<_ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<_ChatBubble> {
  bool _hovering = false;
  bool _copied = false;

  String get _visibleText {
    if (!widget.message.isUser && widget.isStructuredTableResponse) {
      return widget.message.text.trim();
    }
    final display = widget.message.displayText?.trim() ?? '';
    if (display.isNotEmpty) return display;
    final text = widget.message.text.trim();
    if (_looksLikeActionToken(text)) {
      return widget.message.isUser ? 'Option selected' : '';
    }
    return widget.message.text;
  }

  void _copyText() {
    Clipboard.setData(ClipboardData(text: _visibleText));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final message = widget.message;
    final isUser = message.isUser;
    final align = isUser ? Alignment.centerRight : Alignment.centerLeft;
    // AI bubble uses a clearly distinct surface so text is always legible
    // in both dark and light themes.
    final bg = isUser
        ? cs.primary
        : (isDark ? cs.surfaceContainerHighest : cs.surfaceContainerHigh);
    final fg = isUser ? cs.onPrimary : cs.onSurface;
    final l = AppLocalizations.of(context)!;
    final showCopyAction = _hovering || _copied;
    final showExportAction = !isUser && widget.canExportToExcel;
    final showActions =
        showCopyAction || showExportAction || widget.isExporting;
    final hasMenuActions = widget.showInlineMenuActions &&
        !isUser &&
        (_messageHasMenu(message) || (message.followUps?.isNotEmpty ?? false));
    final visibleText = _visibleText;

    return Align(
      alignment: align,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          constraints: BoxConstraints(
            maxWidth: widget.isStructuredTableResponse ? 620 : 520,
          ),
          child: Column(
            crossAxisAlignment:
                isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isUser ? 11 : 13,
                  vertical: isUser ? 9 : 11,
                ),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(14),
                    topRight: const Radius.circular(14),
                    bottomLeft: Radius.circular(isUser ? 14 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 14),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: cs.shadow.withValues(alpha: isDark ? 0.18 : 0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: !isUser && widget.isStructuredTableResponse
                    ? widget.buildStructuredTable(context, message)
                    : !isUser && _messageHasEventAssistant(message)
                        ? widget.buildEventPreview(context, message)
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: Icon(
                              isUser
                                  ? Icons.person_rounded
                                  : Icons.auto_awesome_rounded,
                              size: 14,
                              color: isUser
                                  ? fg.withValues(alpha: 0.85)
                                  : cs.primary.withValues(alpha: 0.75),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: visibleText.trim().isEmpty
                                ? const SizedBox.shrink()
                                : RichText(
                                    text: TextSpan(
                                      children: widget.markdownBoldSpans(
                                        text: visibleText,
                                        baseStyle: t.bodySmall.copyWith(
                                          color: fg,
                                          height: 1.55,
                                          fontSize: isUser ? 12.5 : 13,
                                          fontWeight: isUser
                                              ? FontWeight.w500
                                              : FontWeight.w400,
                                          letterSpacing: 0.1,
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      ),
              ),
              if (hasMenuActions)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: widget.buildMenuActions(
                    context,
                    message: message,
                    cs: cs,
                    t: t,
                    isEs: widget.isEs,
                    compact: true,
                  ),
                ),
              // Action row: copy button appears on hover or after tap
              AnimatedSize(
                duration: const Duration(milliseconds: 150),
                alignment:
                    isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: showActions
                    ? Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            if (showExportAction)
                              _BubbleActionButton(
                                icon: widget.isExporting
                                    ? Icons.hourglass_top_rounded
                                    : Icons.table_view_rounded,
                                tooltip: l.insightsChatExportExcelTooltip,
                                label: l.insightsChatExportExcel,
                                loading: widget.isExporting,
                                onTap: widget.isExporting
                                    ? null
                                    : widget.onExportExcel,
                                color: cs.primary,
                              ),
                            if (showCopyAction)
                              _BubbleActionButton(
                                icon: _copied
                                    ? Icons.check_rounded
                                    : Icons.copy_rounded,
                                tooltip: _copied ? 'Copiado' : 'Copiar',
                                onTap: _copied ? null : _copyText,
                                color: _copied
                                    ? cs.primary
                                    : cs.onSurfaceVariant
                                        .withValues(alpha: 0.7),
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
    this.label,
    this.loading = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final Color color;
  final String? label;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final text = label?.trim() ?? '';
    final hasLabel = text.isNotEmpty;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: hasLabel || loading
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: color.withValues(alpha: 0.18)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (loading)
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: color,
                        ),
                      )
                    else
                      Icon(icon, size: 14, color: color),
                    if (hasLabel) ...[
                      const SizedBox(width: 5),
                      Text(
                        text,
                        style: AppTypography.of(context).caption.copyWith(
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(icon, size: 14, color: color),
              ),
      ),
    );
  }
}

class _InsightsEventEditDialog extends StatefulWidget {
  const _InsightsEventEditDialog({
    required this.groupId,
    required this.clientsApi,
    required this.servicesApi,
    required this.initialAssistant,
  });

  final String groupId;
  final ClientsApi clientsApi;
  final ServiceApi servicesApi;
  final Map<String, dynamic> initialAssistant;

  @override
  State<_InsightsEventEditDialog> createState() => _InsightsEventEditDialogState();
}

class _InsightsEventEditDialogState extends State<_InsightsEventEditDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _locationCtrl;
  late Map<String, dynamic> _assistant;
  late Map<String, dynamic> _preview;
  late Map<String, dynamic> _payload;
  late DateTime _start;
  late DateTime _end;
  late bool _allDay;
  late Set<String> _daysOfWeek;
  List<GroupClient> _clients = const <GroupClient>[];
  List<Service> _services = const <Service>[];
  String? _selectedClientId;
  String? _selectedPrimaryServiceId;
  bool _loadingAssignments = true;
  DateTime? _untilDate;

  @override
  void initState() {
    super.initState();
    _assistant = _cloneJsonMap(widget.initialAssistant);
    _preview = _cloneJsonMap(_safeMap(_assistant['preview']) ?? <String, dynamic>{});
    _payload =
        _cloneJsonMap(_safeMap(_preview['eventPayload']) ?? <String, dynamic>{});
    _titleCtrl = TextEditingController(
      text: _preview['title']?.toString().trim() ?? '',
    );
    _locationCtrl = TextEditingController(
      text: (_preview['localization'] ?? _preview['location'])
              ?.toString()
              .trim() ??
          '',
    );
    _allDay = _preview['allDay'] == true;
    _start = DateTime.tryParse(_preview['startDate']?.toString() ?? '')
            ?.toLocal() ??
        DateTime.now();
    _end = DateTime.tryParse(_preview['endDate']?.toString() ?? '')
            ?.toLocal() ??
        _start.add(const Duration(hours: 1));
    final rule = _safeMap(_preview['recurrenceRule']);
    _untilDate = DateTime.tryParse(rule?['untilDate']?.toString() ?? '')?.toLocal();
    _daysOfWeek = ((rule?['daysOfWeek'] as List?) ?? const [])
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toSet();
    _selectedClientId = _payload['clientId']?.toString().trim();
    _selectedPrimaryServiceId =
        _payload['primaryServiceId']?.toString().trim();
    unawaited(_loadAssignments());
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickStart() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null) return;
    if (!mounted) return;
    TimeOfDay pickedTime = TimeOfDay.fromDateTime(_start);
    if (!_allDay) {
      final time = await showTimePicker(
        context: context,
        initialTime: pickedTime,
      );
      if (time == null) return;
      if (!mounted) return;
      pickedTime = time;
    }
    setState(() {
      _start = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        _allDay ? 0 : pickedTime.hour,
        _allDay ? 0 : pickedTime.minute,
      );
      if (!_end.isAfter(_start)) {
        _end = _allDay
            ? DateTime(_start.year, _start.month, _start.day, 23, 59)
            : _start.add(const Duration(hours: 1));
      }
    });
  }

  Future<void> _pickEnd() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _end,
      firstDate: _start,
      lastDate: DateTime(2100),
    );
    if (pickedDate == null) return;
    if (!mounted) return;
    TimeOfDay pickedTime = TimeOfDay.fromDateTime(_end);
    if (!_allDay) {
      final time = await showTimePicker(
        context: context,
        initialTime: pickedTime,
      );
      if (time == null) return;
      if (!mounted) return;
      pickedTime = time;
    }
    setState(() {
      _end = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        _allDay ? 23 : pickedTime.hour,
        _allDay ? 59 : pickedTime.minute,
      );
    });
  }

  Future<void> _pickUntilDate() async {
    final initial = _untilDate ?? _start;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: _start,
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    if (!mounted) return;
    setState(() {
      _untilDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
    });
  }

  Future<void> _loadAssignments() async {
    try {
      final results = await Future.wait([
        widget.clientsApi.list(groupId: widget.groupId, active: true),
        widget.servicesApi.list(groupId: widget.groupId, active: true),
      ]);
      if (!mounted) return;
      setState(() {
        _clients = results[0] as List<GroupClient>;
        _services = results[1] as List<Service>;
        _loadingAssignments = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingAssignments = false);
    }
  }

  void _save() {
    if ((_selectedClientId?.isEmpty ?? true) ||
        (_selectedPrimaryServiceId?.isEmpty ?? true)) {
      final isEs = Localizations.localeOf(context)
          .languageCode
          .toLowerCase()
          .startsWith('es');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEs
                ? 'Selecciona cliente y servicio para esta visita.'
                : 'Select both client and service for this work visit.',
          ),
        ),
      );
      return;
    }
    final title = _titleCtrl.text.trim();
    final location = _locationCtrl.text.trim();
    _preview['title'] = title;
    _preview['startDate'] = _start.toUtc().toIso8601String();
    _preview['endDate'] = _end.toUtc().toIso8601String();
    _preview['durationMinutes'] = _allDay ? 1440 : _end.difference(_start).inMinutes;
    _preview['localization'] = location;
    _payload['title'] = title;
    _payload['startDate'] = _start.toUtc().toIso8601String();
    _payload['endDate'] = _end.toUtc().toIso8601String();
    _payload['durationMinutes'] = _preview['durationMinutes'];
    _payload['localization'] = location;
    if (_payload.containsKey('location')) {
      _payload['location'] = location;
    }
    _payload['type'] = 'work_visit';
    _payload['clientId'] = _selectedClientId;
    _payload['primaryServiceId'] = _selectedPrimaryServiceId;
    _payload['visitServices'] = [
      {
        'serviceId': _selectedPrimaryServiceId,
      },
    ];

    final previewRule = _safeMap(_preview['recurrenceRule']);
    final payloadRule = _safeMap(_payload['recurrenceRule']);
    if (previewRule != null || payloadRule != null) {
      final nextPreviewRule = _cloneJsonMap(previewRule ?? <String, dynamic>{});
      final nextPayloadRule = _cloneJsonMap(payloadRule ?? <String, dynamic>{});
      if (_untilDate != null) {
        final iso = _untilDate!.toUtc().toIso8601String();
        nextPreviewRule['untilDate'] = iso;
        nextPayloadRule['untilDate'] = iso;
      }
      if ((nextPreviewRule['recurrenceType']?.toString() ?? '') == 'Weekly' ||
          (nextPayloadRule['recurrenceType']?.toString() ?? '') == 'Weekly') {
        final days = _daysOfWeek.toList(growable: false);
        nextPreviewRule['daysOfWeek'] = days;
        nextPayloadRule['daysOfWeek'] = days;
      }
      _preview['recurrenceRule'] = nextPreviewRule;
      _payload['recurrenceRule'] = nextPayloadRule;
    }

    final missing = ((_preview['missing'] as List?) ?? const [])
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    _preview['missing'] = missing
        .where((item) {
          final lower = item.toLowerCase();
          if ((_selectedClientId?.isNotEmpty ?? false) &&
              lower.contains('client')) {
            return false;
          }
          if ((_selectedClientId?.isNotEmpty ?? false) &&
              lower.contains('cliente')) {
            return false;
          }
          if ((_selectedPrimaryServiceId?.isNotEmpty ?? false) &&
              lower.contains('service')) {
            return false;
          }
          if ((_selectedPrimaryServiceId?.isNotEmpty ?? false) &&
              lower.contains('servicio')) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
    _preview['eventPayload'] = _payload;
    _assistant['preview'] = _preview;
    _assistant['cancelled'] = false;
    Navigator.of(context).pop(_assistant);
  }

  String _dateLabel(DateTime date) {
    final localizations = MaterialLocalizations.of(context);
    final dateLabel = localizations.formatMediumDate(date);
    if (_allDay) return dateLabel;
    final timeLabel = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(date),
      alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
    );
    return '$dateLabel · $timeLabel';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final l = AppLocalizations.of(context)!;
    final isEs = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('es');
    const weekdayOptions = <String>[
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final recurrenceType =
        _safeMap(_preview['recurrenceRule'])?['recurrenceType']?.toString() ?? '';

    return AlertDialog(
      title: Text(isEs ? 'Editar evento' : 'Edit event'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleCtrl,
                decoration: InputDecoration(
                  labelText: isEs ? 'Titulo' : 'Title',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _locationCtrl,
                decoration: InputDecoration(
                  labelText: isEs ? 'Ubicacion' : 'Location',
                ),
              ),
              const SizedBox(height: 12),
              if (_loadingAssignments)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(minHeight: 2),
                )
              else ...[
                DropdownButtonFormField<String>(
                  initialValue: (_selectedClientId?.isNotEmpty ?? false)
                      ? _selectedClientId
                      : null,
                  decoration: InputDecoration(
                    labelText: l.clientLabel,
                    helperText: isEs
                        ? 'Obligatorio para visitas de trabajo'
                        : 'Required for work visits',
                  ),
                  items: _clients
                      .map(
                        (client) => DropdownMenuItem<String>(
                          value: client.id,
                          child: Text(client.name),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) =>
                      setState(() => _selectedClientId = value?.trim()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: (_selectedPrimaryServiceId?.isNotEmpty ?? false)
                      ? _selectedPrimaryServiceId
                      : null,
                  decoration: InputDecoration(
                    labelText: l.servicePrimaryLabel,
                    helperText: isEs
                        ? 'Obligatorio para visitas de trabajo'
                        : 'Required for work visits',
                  ),
                  items: _services
                      .map(
                        (service) => DropdownMenuItem<String>(
                          value: service.id,
                          child: Text(service.name),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) => setState(
                    () => _selectedPrimaryServiceId = value?.trim(),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(isEs ? 'Inicio' : 'Start'),
                subtitle: Text(_dateLabel(_start)),
                trailing: const Icon(Icons.edit_calendar_rounded),
                onTap: _pickStart,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(isEs ? 'Fin' : 'End'),
                subtitle: Text(_dateLabel(_end)),
                trailing: const Icon(Icons.schedule_rounded),
                onTap: _pickEnd,
              ),
              if (recurrenceType == 'Weekly') ...[
                const SizedBox(height: 8),
                Text(
                  isEs ? 'Dias de la semana' : 'Days of week',
                  style: t.bodySmall.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final day in weekdayOptions)
                      FilterChip(
                        selected: _daysOfWeek.contains(day),
                        label: Text(day),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _daysOfWeek.add(day);
                            } else {
                              _daysOfWeek.remove(day);
                            }
                          });
                        },
                      ),
                  ],
                ),
              ],
              if (recurrenceType.isNotEmpty) ...[
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(isEs ? 'Fin de recurrencia' : 'Recurrence end'),
                  subtitle: Text(
                    _untilDate == null
                        ? (isEs ? 'Sin fecha' : 'No end date')
                        : _dateLabel(_untilDate!),
                  ),
                  trailing: const Icon(Icons.event_repeat_rounded),
                  onTap: _pickUntilDate,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(isEs ? 'Cancelar' : 'Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(isEs ? 'Guardar' : 'Save'),
        ),
      ],
    );
  }
}

class _PendingInvoiceLinkEdit {
  const _PendingInvoiceLinkEdit({
    required this.invoiceId,
    required this.invoiceNumber,
    required this.clientName,
    required this.total,
    required this.totalFormatted,
    required this.pendingStatusLabel,
    required this.displayLabel,
  });

  final String invoiceId;
  final String invoiceNumber;
  final String clientName;
  final num? total;
  final String totalFormatted;
  final String pendingStatusLabel;
  final String displayLabel;
}

class _InsightsInvoiceLinkPickerDialog extends StatefulWidget {
  const _InsightsInvoiceLinkPickerDialog({
    required this.invoicesApi,
    required this.groupId,
    required this.row,
  });

  final InvoicesApi invoicesApi;
  final String groupId;
  final Map<String, dynamic> row;

  @override
  State<_InsightsInvoiceLinkPickerDialog> createState() =>
      _InsightsInvoiceLinkPickerDialogState();
}

class _InsightsInvoiceLinkPickerDialogState
    extends State<_InsightsInvoiceLinkPickerDialog> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _results = const <Map<String, dynamic>>[];
  bool _loading = true;
  String? _error;
  String? _selectedInvoiceId;

  @override
  void initState() {
    super.initState();
    _searchCtrl.text = _initialQuery();
    _runSearch();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _initialQuery() {
    for (final key in const [
      'matchedInvoiceNumber',
      'matchedInvoiceClientName',
      'clientName',
      'counterpartyName',
    ]) {
      final value = widget.row[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  String _statusLabel(String status, bool isEs) {
    switch (status.trim().toLowerCase()) {
      case 'issued':
        return isEs ? 'Emitida' : 'Issued';
      case 'draft':
        return isEs ? 'Borrador' : 'Draft';
      case 'paid':
        return isEs ? 'Pagada' : 'Paid';
      case 'cancelled':
      case 'canceled':
        return isEs ? 'Cancelada' : 'Cancelled';
      default:
        return status.trim().isEmpty ? '-' : status.trim();
    }
  }

  String _formatDateValue(dynamic value) {
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final hh = parsed.hour.toString().padLeft(2, '0');
    final mm = parsed.minute.toString().padLeft(2, '0');
    final hasTime = parsed.hour != 0 || parsed.minute != 0;
    return hasTime
        ? '${parsed.day}/${parsed.month}/${parsed.year} · $hh:$mm'
        : '${parsed.day}/${parsed.month}/${parsed.year}';
  }

  String _formatAmountNumber(num amount, String? currency) {
    final parts = amount.toStringAsFixed(2).split('.');
    final whole = parts.first;
    final buffer = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      final left = whole.length - i;
      buffer.write(whole[i]);
      if (left > 1 && left % 3 == 1) buffer.write('.');
    }
    final code = (currency ?? 'EUR').trim().isEmpty ? 'EUR' : currency!.trim();
    return '${buffer.toString()},${parts.last} $code';
  }

  String _formatAmountValue(Map<String, dynamic> item) {
    final formatted = (item['totalFormatted'] ??
            item['amountFormatted'] ??
            item['invoiceAmountFormatted'])
        ?.toString()
        .trim();
    if (formatted != null && formatted.isNotEmpty) return formatted;
    final total = item['total'] ?? item['amount'] ?? item['invoiceAmount'];
    if (total is num) {
      return _formatAmountNumber(total, item['currency']?.toString());
    }
    return total?.toString().trim() ?? '';
  }

  num? _rowAmount() {
    for (final key in const [
      'amount',
      'amountValue',
      'importe',
      'importeValue',
      'transactionAmount',
      'matchedInvoiceAmount',
    ]) {
      final value = widget.row[key];
      if (value is num) return value;
      if (value is String) {
        final normalized = value
            .replaceAll('.', '')
            .replaceAll(',', '.')
            .replaceAll(RegExp(r'[^0-9\.\-]'), '');
        final parsed = num.tryParse(normalized);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  Future<void> _runSearch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await widget.invoicesApi.searchManualLinkCandidates(
        groupId: widget.groupId,
        q: _searchCtrl.text,
        amount: _rowAmount(),
        status: 'issued',
        limit: 20,
      );
      if (!mounted) return;
      setState(() {
        _results = results;
        if (_selectedInvoiceId == null ||
            !_results.any((item) =>
                (item['id'] ?? item['invoiceId'])?.toString() ==
                _selectedInvoiceId)) {
          _selectedInvoiceId = _results.isNotEmpty
              ? (_results.first['id'] ?? _results.first['invoiceId'])
                  ?.toString()
              : null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '').trim();
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final isEs = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('es');
    final selected = _results.cast<Map<String, dynamic>?>().firstWhere(
          (item) =>
              (item?['id'] ?? item?['invoiceId'])?.toString() ==
              _selectedInvoiceId,
          orElse: () => null,
        );

    return AlertDialog(
      title: Text(isEs ? 'Vincular factura' : 'Link invoice'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchCtrl,
              onSubmitted: (_) => _runSearch(),
              decoration: InputDecoration(
                hintText: isEs
                    ? 'Buscar por numero o cliente'
                    : 'Search by invoice or client',
                suffixIcon: IconButton(
                  onPressed: _loading ? null : _runSearch,
                  icon: const Icon(Icons.search_rounded),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : (_error?.trim().isNotEmpty ?? false)
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _error!,
                              style: t.bodySmall.copyWith(color: cs.error),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _runSearch,
                              child: Text(isEs ? 'Reintentar' : 'Retry'),
                            ),
                          ],
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: _results.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = _results[index];
                            final invoiceId =
                                (item['id'] ?? item['invoiceId'])?.toString() ??
                                    '';
                            final invoiceNumber =
                                item['invoiceNumber']?.toString() ?? '';
                            final clientName =
                                item['clientName']?.toString() ?? '';
                            final amount = _formatAmountValue(item);
                            final issueDate = _formatDateValue(
                              item['issueDate'] ??
                                  item['createdAt'] ??
                                  item['updatedAt'],
                            );
                            final status = _statusLabel(
                              item['status']?.toString() ?? '',
                              isEs,
                            );
                            final delta = item['delta'];
                            final selected = invoiceId == _selectedInvoiceId;
                            return InkWell(
                              onTap: () => setState(
                                  () => _selectedInvoiceId = invoiceId),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? cs.primary.withValues(alpha: 0.08)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: selected
                                        ? cs.primary.withValues(alpha: 0.35)
                                        : Colors.transparent,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      selected
                                          ? Icons.radio_button_checked_rounded
                                          : Icons
                                              .radio_button_unchecked_rounded,
                                      size: 18,
                                      color: selected
                                          ? cs.primary
                                          : cs.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            invoiceNumber.isEmpty
                                                ? invoiceId
                                                : invoiceNumber,
                                            style: t.bodySmall.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          if (clientName.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              '${isEs ? 'Cliente' : 'Client'}: $clientName',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: t.caption.copyWith(
                                                color: cs.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 4),
                                          Wrap(
                                            spacing: 10,
                                            runSpacing: 4,
                                            children: [
                                              if (amount.isNotEmpty)
                                                Text(
                                                  '${isEs ? 'Importe' : 'Amount'}: $amount',
                                                  style: t.caption.copyWith(
                                                    color: cs.onSurface,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              if (issueDate.isNotEmpty)
                                                Text(
                                                  '${isEs ? 'Fecha' : 'Date'}: $issueDate',
                                                  style: t.caption.copyWith(
                                                    color: cs.onSurfaceVariant,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Wrap(
                                            spacing: 10,
                                            runSpacing: 4,
                                            children: [
                                              Text(
                                                '${isEs ? 'Estado' : 'Status'}: $status',
                                                style: t.caption.copyWith(
                                                  color: cs.onSurfaceVariant,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              if (delta != null)
                                                Text(
                                                  'Δ $delta',
                                                  style: t.caption.copyWith(
                                                    color: cs.onSurfaceVariant,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(isEs ? 'Cancelar' : 'Cancel'),
        ),
        FilledButton(
          onPressed: selected == null
              ? null
              : () => Navigator.of(context).pop(selected),
          child: Text(isEs ? 'Usar factura' : 'Use invoice'),
        ),
      ],
    );
  }
}
