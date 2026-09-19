import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/models/calendar/recurrence/legacy_recurrence_rule.dart';

void main() {
  for (final wireValue in ['Daily', 'Weekly', 'Monthly', 'Yearly']) {
    test('preserves the legacy $wireValue API value', () {
      final payload = <String, dynamic>{
        'id': 'rule-1',
        'name': wireValue,
        'recurrenceType': wireValue,
        'repeatInterval': 2,
      };
      final rule = LegacyRecurrenceRule.fromJson(payload);

      expect(rule.toJson()['recurrenceType'], wireValue);
      expect(LegacyRecurrenceRule.fromJson(rule.toJson()).recurrenceType,
          rule.recurrenceType);
    });
  }

  test('keeps the RRULE frequency and interval unchanged', () {
    final start = DateTime.utc(2026, 9, 18);
    final rule = LegacyRecurrenceRule.daily(
      startDate: start,
      repeatInterval: 2,
    );
    expect(rule.toRRuleString(start), 'RRULE:FREQ=DAILY;INTERVAL=2');
  });
}
