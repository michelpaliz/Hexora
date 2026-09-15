import 'package:hexora/presentation/features/shared/widgets/insights_chat_models.dart';

bool looksLikeInsightsActionToken(String text) {
  final trimmed = text.trim();
  return trimmed.startsWith('__menu__:') ||
      trimmed.startsWith('__back__:') ||
      trimmed.startsWith('__anchored_') ||
      trimmed.startsWith('__') && trimmed.contains(':');
}

String visibleInsightsTextForRawValue(
  String raw, {
  required bool isUser,
  required bool isEs,
}) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';
  if (looksLikeInsightsActionToken(trimmed)) {
    return isUser
        ? (isEs ? 'Opcion seleccionada' : 'Option selected')
        : (isEs ? 'Procesando opcion...' : 'Processing option...');
  }
  return raw;
}

String visibleInsightsMessageText(
  InsightsChatMessage message, {
  required bool isEs,
  bool preserveStructuredAssistantText = false,
}) {
  if (!message.isUser && preserveStructuredAssistantText) {
    return message.text.trim();
  }
  final display = message.displayText?.trim() ?? '';
  if (display.isNotEmpty) return display;
  return visibleInsightsTextForRawValue(
    message.text,
    isUser: message.isUser,
    isEs: isEs,
  );
}
