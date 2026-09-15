import 'package:hexora/data/insights/insights_api.dart';
import 'package:hexora/presentation/features/shared/widgets/insights_chat_models.dart';

Map<String, dynamic>? extractInsightsExportActionMap(dynamic raw) {
  final map = insightsChatSafeMap(raw);
  if (map == null || map.isEmpty) return null;
  final directRaw = insightsChatSafeMap(map['exportAction']);
  if (directRaw != null) {
    final direct = InsightsExcelExportAction.fromDynamic(directRaw);
    if (direct == null) return extractInsightsExportActionMap(map['data']);
    return <String, dynamic>{
      'type': direct.type,
      'endpoint': direct.endpoint,
      'method': direct.method,
      'body': direct.body,
      'filename': direct.filename,
    };
  }
  return extractInsightsExportActionMap(map['data']);
}

InsightsExcelExportAction? insightsExportActionForMessage(
  InsightsChatMessage message,
) {
  if (message.canExport != true) return null;
  return InsightsExcelExportAction.fromDynamic(message.exportAction);
}
