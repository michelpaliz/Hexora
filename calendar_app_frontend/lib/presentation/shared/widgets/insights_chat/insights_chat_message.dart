import 'package:hexora/services/insights/insights_api.dart';

import 'insights_action_tokens.dart';
import 'insights_chat_menu.dart';
import 'insights_json_utils.dart';

class ChatMessage {
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
  final Map<String, dynamic>? tableQuery;
  final List<String>? followUps;
  final InsightsMenu? menu;
  final Map<String, dynamic>? eventAssistant;

  const ChatMessage({
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
    this.tableQuery,
    this.followUps,
    this.menu,
    this.eventAssistant,
  });

  ChatMessage copyWith({
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
    Map<String, dynamic>? tableQuery,
    List<String>? followUps,
    InsightsMenu? menu,
    Map<String, dynamic>? eventAssistant,
  }) {
    return ChatMessage(
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
      tableQuery: tableQuery ?? this.tableQuery,
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
        'tableQuery': tableQuery,
        'followUps': followUps,
        'menu': menu?.toJson(),
        'eventAssistant': eventAssistant,
      };

  static ChatMessage? fromJson(dynamic json) {
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
    final exportAction = safeMap(json['exportAction']);
    final view = _safeString(json['view']).trim();
    final table = safeMap(json['table']);
    final tableQuery = safeMap(json['tableQuery']);
    final followUps = _safeStringList(json['followUps']);
    final menu = InsightsMenu.fromDynamic(json['menu']);
    final eventAssistant = safeMap(json['eventAssistant']);
    if (text.trim().isEmpty || timestamp == null) return null;
    return ChatMessage(
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
      tableQuery: tableQuery,
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

  static List<String>? _safeStringList(dynamic value) {
    if (value is! List) return null;
    final items = value
        .map((item) => _safeString(item).trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    return items.isEmpty ? null : items;
  }
}
Map<String, dynamic>? extractExportActionMap(dynamic raw) {
  final map = safeMap(raw);
  if (map == null || map.isEmpty) return null;
  final directRaw = safeMap(map['exportAction']);
  if (directRaw != null) {
    final direct = InsightsExcelExportAction.fromDynamic(directRaw);
    if (direct == null) return extractExportActionMap(map['data']);
    return <String, dynamic>{
      'type': direct.type,
      'endpoint': direct.endpoint,
      'method': direct.method,
      'body': direct.body,
      'filename': direct.filename,
    };
  }
  return extractExportActionMap(map['data']);
}

bool extractCanExport(dynamic raw) {
  final map = safeMap(raw);
  if (map == null || map.isEmpty) return false;
  final rawFlag = map['canExport'];
  if (rawFlag == true || rawFlag?.toString().toLowerCase() == 'true') {
    return true;
  }
  return extractCanExport(map['data']);
}

String? extractResponseView(dynamic raw) {
  final map = safeMap(raw);
  if (map == null || map.isEmpty) return null;
  final direct = map['view']?.toString().trim();
  if (direct != null && direct.isNotEmpty) return direct;
  return extractResponseView(map['data']);
}

Map<String, dynamic>? extractStructuredTableMap(dynamic raw) {
  final map = safeMap(raw);
  if (map == null || map.isEmpty) return null;
  if (map['columns'] is List && map['rows'] is List) return map;
  final table = safeMap(map['table']);
  if (table != null) return table;
  return extractStructuredTableMap(map['data']);
}

Map<String, dynamic>? extractTableQueryMap(dynamic raw) {
  final map = safeMap(raw);
  if (map == null || map.isEmpty) return null;
  final direct = safeMap(map['tableQuery']);
  final endpoint = direct?['endpoint']?.toString().trim() ?? '';
  if (direct != null && endpoint.isNotEmpty) return direct;
  return extractTableQueryMap(map['data']);
}

List<String>? extractFollowUps(dynamic raw) {
  final map = safeMap(raw);
  if (map == null || map.isEmpty) return null;
  final value = map['followUps'];
  if (value is List) {
    final items = value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    if (items.isNotEmpty) return items;
  }
  return extractFollowUps(map['data']);
}

Map<String, dynamic>? extractEventAssistantMap(dynamic raw) {
  final map = safeMap(raw);
  if (map == null || map.isEmpty) return null;
  final direct = safeMap(map['eventAssistant']);
  if (direct != null && direct.isNotEmpty) return direct;
  return extractEventAssistantMap(map['data']);
}

bool messageHasEventAssistant(ChatMessage message) {
  return message.eventAssistant != null && message.eventAssistant!.isNotEmpty;
}

InsightsExcelExportAction? getExportActionFromMessage(ChatMessage message) {
  if (message.canExport != true) return null;
  return InsightsExcelExportAction.fromDynamic(message.exportAction);
}

bool messageHasMenu(ChatMessage message) =>
    message.menu?.hasOptions == true || message.menu?.hasBackAction == true;

String visibleTextForRawValue(
  String raw, {
  required bool isUser,
  required bool isEs,
}) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';
  if (looksLikeActionToken(trimmed)) {
    return isUser
        ? (isEs ? 'Opcion seleccionada' : 'Option selected')
        : (isEs ? 'Procesando opcion...' : 'Processing option...');
  }
  return raw;
}

String visibleMessageText(
  ChatMessage message, {
  required bool isEs,
  bool preserveStructuredAssistantText = false,
}) {
  if (!message.isUser && preserveStructuredAssistantText) {
    return message.text.trim();
  }
  final display = message.displayText?.trim() ?? '';
  if (display.isNotEmpty) return display;
  return visibleTextForRawValue(
    message.text,
    isUser: message.isUser,
    isEs: isEs,
  );
}
