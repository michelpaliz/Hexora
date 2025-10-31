// lib/c-frontend/c-group-calendar-section/screens/event/logic/actions/event_actions_sheet.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/event/logic/actions/event_actions_manager.dart';
import 'package:hexora/c-frontend/d-event-section/screens/event_screen/event_detail/event_detail_screen.dart';
import 'package:hexora/l10n/app_localizations.dart';

/// A stateless widget that displays a bottom sheet with actions related to an event.
///
/// [resolveClient] / [resolveService] are optional ID→name resolvers used by the
/// details screen to render client/service names instead of raw IDs.
class EventActionsSheet extends StatelessWidget {
  final Event event;
  final bool canEdit;
  final EventActionManager? actionManager;

  /// Optional resolvers (id → name). Pass these in from wherever you load clients/services.

  final Map<String, String>? clientNames;
  final Map<String, String>? serviceNames;

  const EventActionsSheet({
    super.key,
    required this.event,
    required this.canEdit,
    required this.actionManager,
    this.clientNames,
    this.serviceNames,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(loc.viewDetails),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EventDetailScreen(
                    event: event,
                  ),
                ),
              );
            },
          ),
          if (canEdit)
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(loc.editEvent),
              onTap: () {
                Navigator.pop(context);
                actionManager?.editEvent(event, context);
              },
            ),
          if (canEdit)
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text(
                loc.removeEvent,
                style: const TextStyle(color: Colors.red),
              ),
              onTap: () async {
                Navigator.pop(context);
                await actionManager?.removeEvent(event, true);
              },
            ),
        ],
      ),
    );
  }
}
