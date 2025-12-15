import 'package:hexora/a-models/group_model/recurrenceRule/recurrence_rule/legacy_recurrence_rule.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/repetition_dialog/dialog/repetition_dialog.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

mixin AddEventDialogs {
  /// Opens the recurrence configuration screen and returns the selected rule.
  Future<List?> showRepetitionDialog(
    BuildContext context, {
    required DateTime selectedStartDate,
    required DateTime selectedEndDate,
    LegacyRecurrenceRule? initialRule,
  }) {
    if (kIsWeb) {
      // Keep the add-event flow in place on web by using a dialog instead of a full navigation push.
      return showDialog<List?>(
        context: context,
        builder: (dialogCtx) {
          final media = MediaQuery.of(dialogCtx).size;
          return Dialog(
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 1200,
                maxHeight: media.height * 0.94,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: media.width * 0.9,
                  height: media.height * 0.9,
                  child: RepetitionScreen(
                    selectedStartDate: selectedStartDate,
                    selectedEndDate: selectedEndDate,
                    initialRecurrenceRule: initialRule,
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

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
