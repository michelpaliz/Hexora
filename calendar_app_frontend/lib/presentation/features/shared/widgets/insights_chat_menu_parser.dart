import 'package:hexora/presentation/features/shared/widgets/insights_chat_models.dart';

InsightsMenu? extractInsightsMenu(dynamic raw) {
  final map = insightsChatSafeMap(raw);
  if (map == null || map.isEmpty) return null;
  final direct = InsightsMenu.fromDynamic(map['menu']);
  if (direct != null) return direct;
  final inline = InsightsMenu.fromDynamic(map);
  if (inline != null) return inline;
  return extractInsightsMenu(map['data']);
}

InsightsMenu? fallbackInsightsMenuFromText(String text) {
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

InsightsMenu? resolveInsightsMenuForResponse({
  required dynamic raw,
  required String text,
  Map<String, dynamic>? table,
}) {
  final directMenu = extractInsightsMenu(raw);
  if (directMenu != null) return directMenu;
  if (table != null && table.isNotEmpty) return null;
  return fallbackInsightsMenuFromText(text);
}
