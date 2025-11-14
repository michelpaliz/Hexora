import 'package:hexora/a-models/group_model/recurrenceRule/recurrence_rule/legacy_recurrence_rule.dart';
import 'package:flutter/material.dart';

abstract class EventDialogs {
  Widget buildRepetitionDialog(BuildContext context);
  void showErrorDialog(BuildContext context);
  Future<List?> showRepetitionDialog(
    BuildContext context, {
    required DateTime selectedStartDate,
    required DateTime selectedEndDate,
    LegacyRecurrenceRule? initialRule,
  });
}
