import 'package:hexora/models/calendar/recurrence/utils/custom_day_week.dart';

extension CustomDayOfWeekRRuleExtension on CustomDayOfWeek {
  String toRRuleDay() {
    return CustomDayOfWeek.getPattern(name);
  }
}
