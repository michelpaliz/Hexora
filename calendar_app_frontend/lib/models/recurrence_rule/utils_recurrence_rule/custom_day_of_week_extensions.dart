import 'package:hexora/models/recurrence_rule/utils_recurrence_rule/custom_day_week.dart';

extension CustomDayOfWeekRRuleExtension on CustomDayOfWeek {
  String toRRuleDay() {
    return CustomDayOfWeek.getPattern(name);
  }
}
