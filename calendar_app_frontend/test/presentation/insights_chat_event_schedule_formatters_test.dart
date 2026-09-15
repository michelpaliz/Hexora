import 'package:hexora/presentation/features/shared/widgets/insights_chat_event_schedule_formatters.dart';
import 'package:hexora/presentation/features/shared/widgets/insights_chat_models.dart';
import 'package:test/test.dart';

void main() {
  InsightsChatMessage message(Map<String, dynamic>? preview) {
    return InsightsChatMessage(
      isUser: false,
      text: 'Event preview',
      timestamp: DateTime.utc(2026, 9, 15),
      eventAssistant: preview == null ? null : {'preview': preview},
    );
  }

  test('formats all-day, hour, minute, and missing durations', () {
    expect(insightsEventDurationLabel(message(null), false), '-');
    expect(
      insightsEventDurationLabel(message({'allDay': true}), true),
      'Todo el dia',
    );
    expect(
      insightsEventDurationLabel(message({'durationMinutes': 120}), false),
      '2 h',
    );
    expect(
      insightsEventDurationLabel(message({'durationMinutes': 30}), false),
      '30 min',
    );
    expect(
      insightsEventDurationLabel(message({'durationMinutes': 90}), true),
      '1h 30m',
    );
    expect(
      insightsEventDurationLabel(message({'durationMinutes': 0}), false),
      '-',
    );
  });

  test('formats daily, weekly, and yearly recurrence intervals', () {
    String summary(Map<String, dynamic> rule, bool isEs) {
      return insightsEventRecurrenceSummary(
        message({'recurrence_rule': rule}),
        isEs,
      );
    }

    expect(summary({'recurrenceType': 'Daily'}, false), 'Every day');
    expect(
      summary({'recurrenceType': 'Daily', 'repeatInterval': 2}, true),
      'Cada 2 dias',
    );
    expect(
      summary({
        'recurrenceType': 'Weekly',
        'repeatInterval': 2,
        'daysOfWeek': ['Monday', '', 'Friday'],
      }, false),
      'Every 2 weeks · Monday, Friday',
    );
    expect(
      summary({'recurrenceType': 'Yearly', 'repeatInterval': 3}, true),
      'Cada 3 anos',
    );
  });

  test('formats monthly day and ordinal recurrence variants', () {
    String summary(Map<String, dynamic> rule, bool isEs) {
      return insightsEventRecurrenceSummary(
        message({'recurrence_rule': rule}),
        isEs,
      );
    }

    expect(
      summary({'recurrenceType': 'Monthly', 'dayOfMonth': '15'}, false),
      'Monthly on day 15',
    );
    expect(
      summary({
        'recurrenceType': 'Monthly',
        'ordinalWeek': -1,
        'ordinalWeekday': 'Friday',
      }, false),
      'Last Friday of the month',
    );
    expect(
      summary({
        'recurrenceType': 'Monthly',
        'ordinalWeek': 2,
        'ordinalWeekday': 'martes',
      }, true),
      'Segundo martes de cada mes',
    );
    expect(summary({'recurrenceType': 'Monthly'}, true), 'Mensual');
  });

  test('preserves empty and unknown recurrence behavior', () {
    expect(insightsEventRecurrenceSummary(message(null), false), isEmpty);
    expect(
      insightsEventRecurrenceSummary(
        message({'recurrence_rule': <String, dynamic>{}}),
        false,
      ),
      isEmpty,
    );
    expect(
      insightsEventRecurrenceSummary(
        message({
          'recurrence_rule': {'recurrenceType': 'Hourly'},
        }),
        false,
      ),
      isEmpty,
    );
    expect(insightsEventOrdinalLabel(7, false), '7');
  });
}
