import 'insights_json_utils.dart';

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
    final map = safeMap(raw);
    if (map == null) return null;
    final index = readInt(map['index']) ??
        readInt(map['number']) ??
        readInt(map['key']) ??
        readInt(map['id']);
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

    final map = safeMap(raw);
    if (map == null || map.isEmpty) return const <InsightsMenuOption>[];

    final sortable = <MapEntry<int, InsightsMenuOption>>[];
    map.forEach((key, value) {
      final index = readInt(key);
      if (index == null) return;
      if (value is String) {
        final label = value.trim();
        if (label.isEmpty) return;
        sortable.add(
          MapEntry(index, InsightsMenuOption(index: index, label: label)),
        );
        return;
      }
      final item = safeMap(value);
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
    final map = safeMap(raw);
    if (map == null || map.isEmpty) return null;
    final metadata = safeMap(map['metadata']) ?? const <String, dynamic>{};
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
InsightsMenu? extractMenu(dynamic raw) {
  final map = safeMap(raw);
  if (map == null || map.isEmpty) return null;
  final direct = InsightsMenu.fromDynamic(map['menu']);
  if (direct != null) return direct;
  final inline = InsightsMenu.fromDynamic(map);
  if (inline != null) return inline;
  return extractMenu(map['data']);
}

InsightsMenu? fallbackMenuFromText(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return null;
  final lines = trimmed
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList(growable: false);
  if (lines.length < 2) return null;

  final options = <InsightsMenuOption>[];
  for (final line in lines) {
    final match = RegExp(r'^(\d+)[\)\.\-:]\s*(.+)$').firstMatch(line);
    if (match == null) continue;
    final index = int.tryParse(match.group(1) ?? '');
    final label = (match.group(2) ?? '').trim();
    if (index == null || label.isEmpty) continue;
    options.add(InsightsMenuOption(index: index, label: label));
  }
  if (options.isEmpty) return null;

  final titleLines = lines
      .where((line) => !RegExp(r'^\d+[\)\.\-:]\s*').hasMatch(line))
      .toList(growable: false);

  return InsightsMenu(
    id: null,
    parentId: null,
    backAction: null,
    title: titleLines.isEmpty ? null : titleLines.first,
    options: options,
  );
}

InsightsMenu? menuForResponse({
  required dynamic raw,
  required String text,
  Map<String, dynamic>? table,
}) {
  final directMenu = extractMenu(raw);
  if (directMenu != null) return directMenu;
  if (table != null && table.isNotEmpty) return null;
  return fallbackMenuFromText(text);
}
