import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/utils/recurrence_time_utils.dart';

void main() {
  group('recurrence date and time serialization', () {
    test('keeps a date-only value on the selected calendar day', () {
      final selectedDate = DateTime(2026, 9, 1);

      expect(dateOnlyString(selectedDate), '2026-09-01');
    });

    test('formats execution time separately as HH:mm', () {
      expect(formatTimeOfDay(const TimeOfDay(hour: 9, minute: 5)), '09:05');
    });
  });
}
