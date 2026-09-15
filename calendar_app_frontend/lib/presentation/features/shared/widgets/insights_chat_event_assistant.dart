import 'package:hexora/presentation/features/shared/widgets/insights_chat_models.dart';

Map<String, dynamic>? insightsEventAssistantForMessage(
  InsightsChatMessage message,
) {
  return insightsChatSafeMap(message.eventAssistant);
}

Map<String, dynamic>? insightsEventPreviewForMessage(
  InsightsChatMessage message,
) {
  return insightsChatSafeMap(
    insightsEventAssistantForMessage(message)?['preview'],
  );
}

Map<String, dynamic>? insightsEventPayloadForMessage(
  InsightsChatMessage message,
) {
  return insightsChatSafeMap(
    insightsEventPreviewForMessage(message)?['eventPayload'],
  );
}

String insightsEventStatus(InsightsChatMessage message) {
  return insightsEventAssistantForMessage(message)?['status']
          ?.toString()
          .trim() ??
      '';
}

bool insightsEventIsCancelled(InsightsChatMessage message) {
  return insightsEventAssistantForMessage(message)?['cancelled'] == true;
}

bool insightsEventCanCreate(InsightsChatMessage message) {
  final assistant = insightsEventAssistantForMessage(message);
  if (assistant == null || assistant['cancelled'] == true) return false;
  return assistant['canCreate'] == true;
}

bool insightsEventHasPendingClarification(InsightsChatMessage? message) {
  if (message == null || insightsEventIsCancelled(message)) return false;
  return insightsEventStatus(message) == 'needs_clarification';
}

bool insightsEventShouldPromptForClientAndService(
  InsightsChatMessage message,
) {
  final payload = insightsEventPayloadForMessage(message);
  final preview = insightsEventPreviewForMessage(message);
  if (payload == null || preview == null) return false;
  final missing = insightsEventStringList(preview['missing'])
      .map((item) => item.toLowerCase())
      .toList(growable: false);
  final clientId = payload['clientId']?.toString().trim() ?? '';
  final primaryServiceId = payload['primaryServiceId']?.toString().trim() ?? '';
  final needsClient = clientId.isEmpty ||
      missing
          .any((item) => item.contains('client') || item.contains('cliente'));
  final needsService = primaryServiceId.isEmpty ||
      missing.any(
        (item) => item.contains('service') || item.contains('servicio'),
      );
  return needsClient || needsService;
}

List<String> insightsEventStringList(dynamic value) {
  if (value is! List) return const <String>[];
  return value
      .map((item) => item?.toString().trim() ?? '')
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}
