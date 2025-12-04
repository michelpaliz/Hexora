import 'package:hexora/a-models/group_model/recurrenceRule/recurrence_rule/legacy_recurrence_rule.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/repetition_dialog/dialog/repetition_dialog.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

mixin AddEventDialogs {
  /// Opens the recurrence configuration screen and returns the selected rule.
  Future<List?> showRepetitionDialog(
    BuildContext context, {
    required DateTime selectedStartDate,
    required DateTime selectedEndDate,
    LegacyRecurrenceRule? initialRule,
  }) {
    return Navigator.of(context).push<List?>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => RepetitionScreen(
          selectedStartDate: selectedStartDate,
          selectedEndDate: selectedEndDate,
          initialRecurrenceRule: initialRule,
        ),
      ),
    );
  }

  void showErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.event),
          content: Text(AppLocalizations.of(context)!.errorEventCreation),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void showGroupFetchErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Group Error"),
          content: const Text(
            "Could not fetch the updated group. Please try again.",
          ),
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void showRepetitionInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.repetitionEvent),
          content: Text(AppLocalizations.of(context)!.repetitionEventInfo),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
}
