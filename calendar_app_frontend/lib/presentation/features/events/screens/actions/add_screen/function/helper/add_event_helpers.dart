import 'dart:developer' as devtools show log;

import 'package:flutter/material.dart';
import 'package:hexora/models/event/model/event.dart';
import 'package:hexora/models/recurrence_rule/recurrence_rule/legacy_recurrence_rule.dart';
import 'package:hexora/models/recurrence_rule/utils_recurrence_rule/recurrence_rule_utils.dart';
import 'package:hexora/data/group_management/group/domain/group_domain.dart';
import 'package:hexora/presentation/utils/loading/loading_dialog.dart';

bool validateTitle(
    BuildContext context, TextEditingController titleController) {
  final title = titleController.text.trim();
  if (title.isEmpty) {
    devtools.log("⚠️ [addEvent] Title is empty — showing snackbar");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enter a title for the event.')),
    );
    return false;
  }
  return true;
}

bool validateRecurrence({
  required dynamic recurrence_rule,
  required DateTime selectedStartDate,
  VoidCallback? onRepetitionError,
}) {
  if (recurrence_rule != null) {
    devtools.log(
        "ðŸ” [addEvent] RecurrenceRule (raw): ${recurrence_rule.toString()}");

    try {
      // final rrule = recurrence_rule.toRRuleString(selectedStartDate);
      final rrule = toRRuleStringUtils(recurrence_rule, selectedStartDate);

      devtools.log("ðŸ“… [addEvent] RecurrenceRule (RRULE): $rrule");

      if (recurrence_rule.recurrenceType.toString().contains('Weekly') &&
          (recurrence_rule.daysOfWeek?.isEmpty ?? true)) {
        devtools.log("❌ [addEvent] Weekly recurrence is missing daysOfWeek.");
        onRepetitionError?.call(); // ✅ safe way to call a nullable callback

        return false;
      }
    } catch (e) {
      devtools.log("❌ [addEvent] Error parsing recurrence rule: $e");
      onRepetitionError?.call(); // ✅ safe way to call a nullable callback

      return false;
    }
  } else {
    devtools.log("⚠️ [addEvent] No recurrence_rule set");
  }
  return true;
}

Event buildNewEvent({
  required String id,
  required DateTime startDate,
  required DateTime endDate,
  required String title,
  required String groupId,
  required String calendarId,
  required dynamic recurrence_rule,
  required String location,
  required String description,
  required int eventColorIndex,
  required List<String> recipients,
  required String ownerId,

  // NEW (all optional)
  String? type, // 'simple' | 'work_visit'
  String? clientId,
  String? primaryServiceId,
  String? categoryId,
  String? subcategoryId,
  List<VisitService>? visitServices,
  CompletionRequirements? completionRequirements,
}) {
  return Event(
    id: id,
    startDate: startDate,
    endDate: endDate,
    title: title,
    groupId: groupId,
    calendarId: calendarId,
    recurrence_rule: recurrence_rule,
    localization: location,
    allDay: false,
    description: description,
    eventColorIndex: eventColorIndex,
    recipients: recipients,
    ownerId: ownerId,
    isDone: false,
    completedAt: null,

    // pass through
    type: type ?? 'work_visit',
    clientId: clientId,
    primaryServiceId: primaryServiceId,
    categoryId: categoryId,
    subcategoryId: subcategoryId,
    visitServices: visitServices ?? const [],
    completionRequirements: completionRequirements,
  );
}

Future<LegacyRecurrenceRule?> hydrateRecurrenceRuleIfNeeded({
  required GroupDomain groupDomain,
  required String? rawRuleId,
}) async {
  if (rawRuleId == null) return null;

  const maxRetries = 5;
  int retries = 0;

  while (retries < maxRetries) {
    try {
      // final rule = await groupDomain.groupEventResolver.ruleService
      //     .getRuleById(rawRuleId);
      final rule = await groupDomain.groupEventResolver.ruleService
          .getRuleById(rawRuleId);

      devtools.log("✅ Recurrence rule hydrated after $retries retries");
      return rule;
    } catch (_) {
      retries++;
      devtools.log("⏳ Retry $retries: Recurrence rule not ready...");
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  devtools.log("❌ Recurrence rule not found after $maxRetries retries");
  return null;
}

// Future<T?> withLoadingDialog<T>(
//   BuildContext context,
//   Future<T> Function() action, {
//   required String message,
// }) async {
//   final nav = Navigator.of(context, rootNavigator: true);
//   await LoadingDialog.show(context, message: message);
//   try {
//     return await action();
//   } finally {
//     if (nav.canPop()) nav.pop(); // safely dismiss the dialog
//   }
// }

Future<T> withLoadingDialog<T>(
  BuildContext context,
  Future<T> Function() action, {
  required String message,
}) async {
  // 1️⃣  SHOW the dialog (do NOT await)
  LoadingDialog.show(context, message: message);

  try {
    // 2️⃣  Run your async work
    return await action();
  } finally {
    // 3️⃣  Always dismiss the dialog
    Navigator.of(context, rootNavigator: true).pop();
  }
}
