import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/presentation/features/notifications/show_notifications/notify_phone/local_notification_helper.dart';

void main() {
  group('androidReminderScheduleMode', () {
    test('uses exact scheduling when exact alarms are available', () {
      expect(
        androidReminderScheduleMode(true),
        ReminderScheduleMode.exact,
      );
      expect(
        androidScheduleModeFor(ReminderScheduleMode.exact),
        AndroidScheduleMode.exactAllowWhileIdle,
      );
    });

    test('falls back to inexact scheduling when exact alarms are unavailable',
        () {
      expect(
        androidReminderScheduleMode(false),
        ReminderScheduleMode.inexact,
      );
      expect(
        androidScheduleModeFor(ReminderScheduleMode.inexact),
        AndroidScheduleMode.inexactAllowWhileIdle,
      );
    });

    test('falls back to inexact scheduling when capability is unknown', () {
      expect(
        androidReminderScheduleMode(null),
        ReminderScheduleMode.inexact,
      );
    });
  });
}
