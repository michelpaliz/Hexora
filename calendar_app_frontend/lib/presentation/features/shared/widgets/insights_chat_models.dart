class InsightsChatMessage {
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
  final InsightsMenu? menu;
  final Map<String, dynamic>? eventAssistant;

  const InsightsChatMessage({
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

  InsightsChatMessage copyWith({
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
    InsightsMenu? menu,
    Map<String, dynamic>? eventAssistant,
  }) {
    return InsightsChatMessage(
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

  static InsightsChatMessage? fromJson(dynamic json) {
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
    final exportAction = insightsChatSafeMap(json['exportAction']);
    final view = _safeString(json['view']).trim();
    final table = insightsChatSafeMap(json['table']);
    final followUps = _safeStringList(json['followUps']);
    final menu = InsightsMenu.fromDynamic(json['menu']);
    final eventAssistant = insightsChatSafeMap(json['eventAssistant']);
    if (text.trim().isEmpty || timestamp == null) return null;
    return InsightsChatMessage(
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

  static List<String>? _safeStringList(dynamic value) {
    if (value is! List) return null;
    final items = value
        .map((item) => _safeString(item).trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    return items.isEmpty ? null : items;
  }
}

class InsightsMenuOption {
  const InsightsMenuOption({
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

  static InsightsMenuOption? fromDynamic(dynamic raw) {
    if (raw is String) {
      final label = raw.trim();
      if (label.isEmpty) return null;
      return InsightsMenuOption(index: 0, label: label);
    }
    final map = insightsChatSafeMap(raw);
    if (map == null) return null;
    final index = insightsChatReadInt(map['index']) ??
        insightsChatReadInt(map['number']) ??
        insightsChatReadInt(map['key']) ??
        insightsChatReadInt(map['id']);
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
    return InsightsMenuOption(
      index: index,
      label: label,
      action: action.isEmpty ? null : action,
    );
  }
}

class InsightsMenu {
  const InsightsMenu({
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
  final List<InsightsMenuOption> options;

  bool get hasOptions => options.isNotEmpty;
  bool get hasBackAction => (backAction?.trim().isNotEmpty ?? false);

  Map<String, dynamic> toJson() => {
        'id': id,
        'parentId': parentId,
        'backAction': backAction,
        'title': title,
        'options': options.map((option) => option.toJson()).toList(),
      };

  static List<InsightsMenuOption> _optionsFromDynamic(dynamic raw) {
    if (raw is List) {
      return raw
          .map(InsightsMenuOption.fromDynamic)
          .whereType<InsightsMenuOption>()
          .toList(growable: false);
    }

    final map = insightsChatSafeMap(raw);
    if (map == null || map.isEmpty) return const <InsightsMenuOption>[];

    final sortable = <MapEntry<int, InsightsMenuOption>>[];
    map.forEach((key, value) {
      final index = insightsChatReadInt(key);
      if (index == null) return;
      if (value is String) {
        final label = value.trim();
        if (label.isEmpty) return;
        sortable.add(
          MapEntry(index, InsightsMenuOption(index: index, label: label)),
        );
        return;
      }
      final item = insightsChatSafeMap(value);
      if (item == null) return;
      final enriched = <String, dynamic>{'index': index, ...item};
      final option = InsightsMenuOption.fromDynamic(enriched);
      if (option != null) {
        sortable.add(MapEntry(index, option));
      }
    });

    sortable.sort((a, b) => a.key.compareTo(b.key));
    return sortable.map((entry) => entry.value).toList(growable: false);
  }

  static InsightsMenu? fromDynamic(dynamic raw) {
    final map = insightsChatSafeMap(raw);
    if (map == null || map.isEmpty) return null;
    final metadata =
        insightsChatSafeMap(map['metadata']) ?? const <String, dynamic>{};
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
    return InsightsMenu(
      id: id.isEmpty ? null : id,
      parentId: parentId.isEmpty ? null : parentId,
      backAction: backAction.isEmpty ? null : backAction,
      title: title.isEmpty ? null : title,
      options: options,
    );
  }
}

Map<String, dynamic>? insightsChatSafeMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return null;
}

int? insightsChatReadInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}
