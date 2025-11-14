import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/notification_model/userInvitation_status.dart';
import 'package:hexora/b-backend/group_mng_flow/event/domain/event_domain.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/b-backend/notification/domain/notification_domain.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/actions/edit_screen/screen/edit_event_screen.dart';
import 'package:hexora/c-frontend/routes/appRoutes.dart';
import 'package:provider/provider.dart';

class EventActionManager {
  final EventDomain eventDomain;
  final GroupDomain groupDomain;
  final UserDomain userDomain;
  final NotificationDomain notificationDomain;
  Map<String, UserInviteStatus>? invitedUsers;

  EventActionManager(
    this.groupDomain,
    this.userDomain,
    this.notificationDomain, {
    required this.eventDomain,
  });

  // Build the add event button
  Widget buildAddEventButton(BuildContext context, Group group) {
    return Expanded(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(25),
          ),
          width: 50,
          height: 50,
          child: IconButton(
            icon: const Icon(Icons.add, color: Colors.white, size: 25),
            onPressed: () async {
              final added = await Navigator.pushNamed(
                context,
                AppRoutes.addEvent,
                arguments: group,
              );

              if (added != null) {
                // ✅ Refresh group via repository (handles token)
                final refreshedGroup =
                    await groupDomain.groupRepository.getGroupById(group.id);

                // Update domain state (and broadcast to listeners/streams)
                await groupDomain.updateGroup(refreshedGroup, userDomain);

                // 🔁 Refresh calendar events
                await eventDomain.manualRefresh(context);
              }
            },
          ),
        ),
      ),
    );
  }

  void editEvent(Event event, BuildContext context) {
    final sharedeventDomain = eventDomain;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Provider<EventDomain>.value(
          value: sharedeventDomain,
          child: EditEventScreen(event: event),
        ),
      ),
    );
  }

  /// Strip any `-timestamp` suffix you added client-side
  String baseId(String id) => id.split('-').first;

  Future<bool> removeEvent(Event ev, bool confirmed) async {
    if (!confirmed) return false;

    final mongoId = baseId(ev.id);
    debugPrint('🗑️  [UI] removeEvent for ${ev.id}  →  $mongoId');

    try {
      await eventDomain.deleteEvent(mongoId);
      debugPrint('✅  [UI] deleteEvent completed for $mongoId');
      return true;
    } catch (e, st) {
      debugPrint('❌  [UI] deleteEvent threw: $e');
      debugPrintStack(stackTrace: st);
      return false;
    }
  }
}
