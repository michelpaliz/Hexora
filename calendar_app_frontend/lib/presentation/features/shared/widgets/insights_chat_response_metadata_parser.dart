import 'package:hexora/presentation/features/shared/widgets/insights_chat_models.dart';

T? _extractNestedInsightsValue<T>(
  dynamic raw,
  T? Function(Map<String, dynamic> map) extractDirect,
) {
  final map = insightsChatSafeMap(raw);
  if (map == null || map.isEmpty) return null;
  final direct = extractDirect(map);
  if (direct != null) return direct;
  return _extractNestedInsightsValue(map['data'], extractDirect);
}

bool extractInsightsCanExport(dynamic raw) {
  return _extractNestedInsightsValue<bool>(raw, (map) {
        final rawFlag = map['canExport'];
        return rawFlag == true || rawFlag?.toString().toLowerCase() == 'true'
            ? true
            : null;
      }) ??
      false;
}

String? extractInsightsResponseView(dynamic raw) {
  return _extractNestedInsightsValue<String>(raw, (map) {
    final direct = map['view']?.toString().trim();
    return direct == null || direct.isEmpty ? null : direct;
  });
}

Map<String, dynamic>? extractInsightsStructuredTable(dynamic raw) {
  return _extractNestedInsightsValue<Map<String, dynamic>>(raw, (map) {
    if (map['columns'] is List && map['rows'] is List) return map;
    return insightsChatSafeMap(map['table']);
  });
}

List<String>? extractInsightsFollowUps(dynamic raw) {
  return _extractNestedInsightsValue<List<String>>(raw, (map) {
    final value = map['followUps'];
    if (value is! List) return null;
    final items = value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    return items.isEmpty ? null : items;
  });
}

Map<String, dynamic>? extractInsightsEventAssistant(dynamic raw) {
  return _extractNestedInsightsValue<Map<String, dynamic>>(raw, (map) {
    final direct = insightsChatSafeMap(map['eventAssistant']);
    return direct == null || direct.isEmpty ? null : direct;
  });
}
