import 'package:hexora/presentation/features/shared/widgets/insights_chat_models.dart';

bool insightsMessageHasStructuredTable(InsightsChatMessage message) {
  if (message.view != 'table') return false;
  final rows = message.table?['rows'];
  return rows is List && rows.isNotEmpty;
}

List<Map<String, dynamic>> insightsTableColumnsForMessage(
  InsightsChatMessage message,
) {
  final columns = message.table?['columns'];
  if (columns is! List) return const [];
  return columns
      .map(insightsChatSafeMap)
      .whereType<Map<String, dynamic>>()
      .toList(growable: false);
}

List<Map<String, dynamic>> insightsTableRowsForMessage(
  InsightsChatMessage message,
) {
  final rows = message.table?['rows'];
  if (rows is! List) return const [];
  return rows
      .map(insightsChatSafeMap)
      .whereType<Map<String, dynamic>>()
      .toList(growable: false);
}

Map<String, dynamic>? insightsTableSummaryForMessage(
  InsightsChatMessage message,
) {
  return insightsChatSafeMap(message.table?['summary']);
}
