import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:hexora/app/session/session_expiry_handler.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_services/auth_service.dart';
import 'package:hexora/b-backend/group_mng_flow/event/repository/i_event_repository.dart';
import 'package:hexora/c-frontend/routes/appRoutes.dart';
import 'package:provider/provider.dart';

typedef EventLookup = Future<Event?> Function(String eventId);
typedef EventDetailsNavigator = void Function(Event event);

/// Routes an event reminder payload only when an authenticated event exists.
///
/// A missing or deleted event leaves the user on their current screen.
class EventNotificationTapHandler {
  EventNotificationTapHandler({
    required bool Function() isAuthenticated,
    required EventLookup findEvent,
    required EventDetailsNavigator showEventDetails,
    VoidCallback? onEventUnavailable,
  })  : _isAuthenticated = isAuthenticated,
        _findEvent = findEvent,
        _showEventDetails = showEventDetails,
        _onEventUnavailable = onEventUnavailable;

  final bool Function() _isAuthenticated;
  final EventLookup _findEvent;
  final EventDetailsNavigator _showEventDetails;
  final VoidCallback? _onEventUnavailable;

  Future<void> handlePayload(String? payload) async {
    final eventId = payload?.trim();
    if (eventId == null || eventId.isEmpty || !_isAuthenticated()) return;

    Event? event;
    try {
      event = await _findEvent(eventId);
    } catch (_) {
      _onEventUnavailable?.call();
      return;
    }

    if (event == null) {
      _onEventUnavailable?.call();
      return;
    }

    if (!_isAuthenticated()) return;

    _showEventDetails(event);
  }
}

Future<void> routeEventNotificationTap(String? payload) async {
  final navigator = SessionExpiryHandler.navigatorKey.currentState;
  if (navigator == null) return;
  final context = navigator.context;

  final authService = context.read<AuthService>();
  final handler = EventNotificationTapHandler(
    isAuthenticated: () => authService.isAuthenticated,
    findEvent: (eventId) =>
        context.read<IEventRepository>().getEventById(eventId),
    showEventDetails: (event) {
      if (navigator.mounted) {
        navigator.pushNamed(AppRoutes.eventDetail, arguments: event);
      }
    },
    onEventUnavailable: () {
      debugPrint('Event notification target is no longer available.');
    },
  );
  await handler.handlePayload(payload);
}
