import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/b-backend/group_mng_flow/event/domain/event_domain.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/l10n/app_localizations.dart';

Future<void> saveEditedEvent({
  required BuildContext context,
  required EventDomain eventDomain,
  required Event updatedData,
  required List<Event> eventList,
  required Group group,
  required GroupDomain groupDomain,
  required String?
      currentUserName, // (unused; keep if needed for logging/audit)
  required bool startDateChanged,
}) async {
  const bool allowRepetitiveHours = true;

  bool isStartHourUnique = true;

  if (allowRepetitiveHours) {
    final startDateOnly = DateTime(
      updatedData.startDate.year,
      updatedData.startDate.month,
      updatedData.startDate.day,
    );

    isStartHourUnique = eventList.every((e) {
      final eventStartDateOnly = DateTime(
        e.startDate.year,
        e.startDate.month,
        e.startDate.day,
      );

      if (!startDateChanged && e.id == updatedData.id) return true;
      return eventStartDateOnly != startDateOnly;
    });
  }

  if (isStartHourUnique || !allowRepetitiveHours) {
    try {
      await eventDomain.updateEvent(context, updatedData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.eventEdited)),
      );

      // ✅ Use repository (handles token) instead of service
      final updatedGroup =
          await groupDomain.groupRepository.getGroupById(group.id);
      groupDomain.currentGroup = updatedGroup;

      // Optional: refresh calendar data
      await eventDomain.manualRefresh(context);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.eventEditFailed)),
      );
    }
  } else {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.repetitionEvent),
        content: Text(AppLocalizations.of(context)!.repetitionEventInfo),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
