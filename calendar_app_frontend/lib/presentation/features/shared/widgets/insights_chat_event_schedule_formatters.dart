import 'package:hexora/presentation/features/shared/widgets/insights_chat_event_assistant.dart';
import 'package:hexora/presentation/features/shared/widgets/insights_chat_models.dart';

String insightsEventDurationLabel(InsightsChatMessage message, bool isEs) {
  final preview = insightsEventPreviewForMessage(message);
  if (preview == null) return '-';
  if (preview['allDay'] == true) return isEs ? 'Todo el dia' : 'All day';
  final minutes = insightsChatReadInt(preview['durationMinutes']);
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

String insightsEventRecurrenceSummary(InsightsChatMessage message, bool isEs) {
  final rule = insightsChatSafeMap(
    insightsEventPreviewForMessage(message)?['recurrence_rule'],
  );
  if (rule == null || rule.isEmpty) return '';
  final type = rule['recurrenceType']?.toString().trim() ?? '';
  final interval = insightsChatReadInt(rule['repeatInterval']) ?? 1;
  final days = ((rule['daysOfWeek'] as List?) ?? const [])
      .map((item) => item?.toString().trim() ?? '')
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
  final dayOfMonth = insightsChatReadInt(rule['dayOfMonth']);
  final ordinalWeek = insightsChatReadInt(rule['ordinalWeek']);
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
        final ordinalText = insightsEventOrdinalLabel(ordinalWeek, isEs);
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

String insightsEventOrdinalLabel(int ordinal, bool isEs) {
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
