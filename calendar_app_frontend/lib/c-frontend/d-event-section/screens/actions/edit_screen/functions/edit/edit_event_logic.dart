// lib/c-frontend/d-event-section/screens/actions/shared/edit_event_logic.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/b-backend/auth_user/user/domain/user_domain.dart';
import 'package:hexora/b-backend/group_mng_flow/event/domain/event_domain.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/c-frontend/d-event-section/screens/actions/shared/base/base_event_logic.dart';
import 'package:hexora/c-frontend/d-event-section/utils/color_manager.dart';
import 'package:hexora/l10n/app_localizations.dart';

/// Base logic for editing an existing event.
abstract class EditEventLogic<T extends StatefulWidget>
    extends BaseEventLogic<T> {
  // Domains

  late final UserDomain _userDomain;

  // Models
  late final Group _group;
  late Event _event;

  bool isLoading = true;

  Future<void> initLogic({
    required Event event,
    required GroupDomain gm,
    required UserDomain um,
  }) async {
    _userDomain = um;
    _event = event;
    _group = gm.currentGroup!;

    // Base state setup from the existing event
    setReminderMinutes(event.reminderTime ?? 10);
    setSelectedColor(ColorManager.eventColors[event.eventColorIndex].value);
    setRecurrenceRule(event.recurrenceRule);
    setStartDate(event.startDate);
    setEndDate(event.endDate);

    titleController.text = event.title;
    descriptionController.text = event.description ?? '';
    noteController.text = event.note ?? '';
    locationController.text = event.localization ?? '';

    // Fetch users for this group through the repository (token handled inside)
    final fetchedUsers =
        await _userDomain.userRepository.getUsersForGroup(_group);

    // Preselect recipients that are on the event already
    setSelectedUsers(
      fetchedUsers.where((u) => event.recipients.contains(u.id)).toList(),
    );

    users
      ..clear()
      ..addAll(fetchedUsers);

    // (Optional) If you can load clients/services here, do it before seeding values:
    // final fetchedClients = await gm.clientRepository.getClientsForGroup(_group);
    // final fetchedServices = await gm.serviceRepository.getServicesForGroup(_group);
    // setAvailableClients(fetchedClients.map((c)=>ClientLite(id:c.id,name:c.name)).toList());
    // setAvailableServices(fetchedServices.map((s)=>ServiceLite(id:s.id,name:s.name)).toList());

    // 🔧 Preselect client & service from the event being edited
    setClientId?.call(event.clientId);
    setPrimaryServiceId?.call(event.primaryServiceId);

    if (mounted) {
      isLoading = false;
      setState(() {});
    }
  }

  void disposeLogic() {
    disposeBaseControllers();
  }

  Future<void> saveEditedEvent(EventDomain read) async {
    final loc = AppLocalizations.of(context)!;
    final eventDomain = read;

    // Required title
    if (titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(loc.requiredTextFields),
            backgroundColor: Colors.redAccent),
      );
      return;
    }

    // At least one participant
    if (selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(loc.pleaseSelectAtLeastOneUser),
            backgroundColor: Colors.redAccent),
      );
      return;
    }

    // Start before end
    if (selectedEndDate.isBefore(selectedStartDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(loc.endDateMustBeAfterStartDate),
            backgroundColor: Colors.redAccent),
      );
      return;
    }

    final updated = Event(
      id: _event.id,
      startDate: selectedStartDate,
      endDate: selectedEndDate,
      title: titleController.text,
      groupId: _event.groupId,
      description: descriptionController.text,
      note: noteController.text,
      localization: locationController.text.replaceAll(RegExp(r'[┤├]'), ''),
      recurrenceRule: recurrenceRule,
      eventColorIndex: ColorManager().getColorIndex(Color(selectedEventColor!)),
      recipients: selectedUsers.map((u) => u.id).toList(),
      updateHistory: _event.updateHistory,
      ownerId: _event.ownerId,
      reminderTime: reminderMinutes,
      calendarId: _event.calendarId,

      // keep other custom fields if your model has them
      type: _event.type,

      // 🔧 use current UI selections instead of stale _event values
      clientId: clientId,
      primaryServiceId: primaryServiceId,

      categoryId: _event.categoryId,
      subcategoryId: _event.subcategoryId,
      visitServices:
          _event.visitServices, // keep as-is unless you also edit these in UI
      rawRuleId: _event.rawRuleId,
    );

    await eventDomain.updateEvent(context, updated);

    // Nudge calendar/UI
    if (eventDomain.onExternalEventUpdate != null) {
      eventDomain.onExternalEventUpdate!.call();
    } else {
      await eventDomain.manualRefresh(context);
    }

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Future<bool> addEvent(BuildContext context) async => false;

  @override
  bool get isRepetitive => recurrenceRule != null;
}
