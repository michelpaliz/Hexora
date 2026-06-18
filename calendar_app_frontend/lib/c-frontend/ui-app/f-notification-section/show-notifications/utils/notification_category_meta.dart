import 'package:flutter/material.dart';
import 'package:hexora/a-models/notification_model/notification_user.dart';
import 'package:hexora/c-frontend/ui-app/f-notification-section/show-notifications/utils/notification_payload_helper.dart';

/// Visual metadata (icon + color) for a notification.
class NotifCategoryMeta {
  final IconData icon;
  final Color color;

  const NotifCategoryMeta({required this.icon, required this.color});
}

// ── Per-action metadata ────────────────────────────────────────────────────────

/// Maps an `args.action` string → icon + color.
/// Falls back to a generic event icon when the action is unknown/absent.
NotifCategoryMeta resolveActionMeta(String? action, ColorScheme cs) {
  switch (action) {
    case 'created':
      return NotifCategoryMeta(
          icon: Icons.event_available_rounded, color: Colors.teal.shade600);
    case 'updated':
      return NotifCategoryMeta(
          icon: Icons.edit_calendar_rounded, color: cs.primary);
    case 'deleted':
      return NotifCategoryMeta(
          icon: Icons.event_busy_rounded, color: cs.error);
    case 'reminder':
      return const NotifCategoryMeta(
          icon: Icons.alarm_rounded, color: Color(0xFFFF8F00));
    case 'started':
      return NotifCategoryMeta(
          icon: Icons.play_circle_filled_rounded, color: Colors.green.shade600);
    case 'recurrence_added':
      return NotifCategoryMeta(
          icon: Icons.repeat_rounded, color: cs.tertiary);
    case 'marked_done':
      return NotifCategoryMeta(
          icon: Icons.task_alt_rounded, color: Colors.green.shade700);
    case 'reopened':
      return NotifCategoryMeta(
          icon: Icons.redo_rounded, color: Colors.orange.shade700);
    default:
      return NotifCategoryMeta(
          icon: Icons.event_rounded, color: cs.primary);
  }
}

/// Human-readable label for an `args.action` value.
String actionLabel(String? action, {required bool isEs}) {
  switch (action) {
    case 'created':         return isEs ? 'Creado'       : 'Created';
    case 'updated':         return isEs ? 'Actualizado'  : 'Updated';
    case 'deleted':         return isEs ? 'Eliminado'    : 'Deleted';
    case 'reminder':        return isEs ? 'Recordatorio' : 'Reminder';
    case 'started':         return isEs ? 'Iniciado'     : 'Started';
    case 'recurrence_added':return isEs ? 'Recurrencia'  : 'Recurrence';
    case 'marked_done':     return isEs ? 'Completado'   : 'Completed';
    case 'reopened':        return isEs ? 'Reabierto'    : 'Reopened';
    default:                return action ?? '';
  }
}

// ── Per-status metadata ────────────────────────────────────────────────────────

NotifCategoryMeta resolveStatusMeta(String? status, ColorScheme cs) {
  switch (status) {
    case 'confirmed':
      return NotifCategoryMeta(
          icon: Icons.check_circle_rounded, color: Colors.green.shade600);
    case 'cancelled':
      return NotifCategoryMeta(
          icon: Icons.cancel_rounded, color: cs.error);
    case 'completed':
      return NotifCategoryMeta(
          icon: Icons.task_alt_rounded, color: Colors.blue.shade600);
    case 'pending':
    default:
      return NotifCategoryMeta(
          icon: Icons.hourglass_top_rounded, color: Colors.amber.shade700);
  }
}

String statusLabel(String? status, {required bool isEs}) {
  switch (status) {
    case 'confirmed':  return isEs ? 'Confirmado' : 'Confirmed';
    case 'cancelled':  return isEs ? 'Cancelado'  : 'Cancelled';
    case 'completed':  return isEs ? 'Completado' : 'Completed';
    case 'pending':    return isEs ? 'Pendiente'  : 'Pending';
    default:           return status ?? '';
  }
}

// ── Per-eventType metadata ─────────────────────────────────────────────────────

NotifCategoryMeta resolveEventTypeMeta(String? eventType, ColorScheme cs) {
  switch (eventType) {
    case 'work_visit':    return NotifCategoryMeta(icon: Icons.handyman_rounded, color: cs.secondary);
    case 'meeting':       return NotifCategoryMeta(icon: Icons.people_rounded, color: cs.primary);
    case 'appointment':   return NotifCategoryMeta(icon: Icons.calendar_today_rounded, color: Colors.indigo.shade400);
    default:              return NotifCategoryMeta(icon: Icons.event_rounded, color: cs.onSurface.withValues(alpha: 0.55));
  }
}

String eventTypeLabel(String? eventType, {required bool isEs}) {
  switch (eventType) {
    case 'work_visit':   return isEs ? 'Visita de trabajo' : 'Work visit';
    case 'meeting':      return isEs ? 'Reunión'           : 'Meeting';
    case 'appointment':  return isEs ? 'Cita'              : 'Appointment';
    default:             return eventType ?? '';
  }
}

NotifCategoryMeta resolveDocumentTypeMeta(
  IssuedDocumentType type,
  ColorScheme cs,
) {
  switch (type) {
    case IssuedDocumentType.invoice:
      return NotifCategoryMeta(
        icon: Icons.receipt_long_rounded,
        color: cs.primary,
      );
    case IssuedDocumentType.receipt:
      return NotifCategoryMeta(
        icon: Icons.point_of_sale_rounded,
        color: Colors.green.shade700,
      );
    case IssuedDocumentType.presupuesto:
      return NotifCategoryMeta(
        icon: Icons.request_quote_rounded,
        color: cs.tertiary,
      );
    case IssuedDocumentType.unknown:
      return NotifCategoryMeta(
        icon: Icons.description_rounded,
        color: cs.primary,
      );
  }
}

// ── Main resolver (used by card & details panel) ───────────────────────────────

/// Resolves the best icon/color for [n] by checking (in order):
/// 1. `args.action` field (most specific)
/// 2. `titleKey` prefix
/// 3. Broad [Category] fallback
NotifCategoryMeta resolveNotifMeta(NotificationUser n, ColorScheme cs) {
  if (isConcurrentEventNotification(n)) {
    return const NotifCategoryMeta(
      icon: Icons.warning_amber_rounded,
      color: Color(0xFFE69100),
    );
  }
  if (isIssuedDocumentNotification(n)) {
    return resolveDocumentTypeMeta(
      documentIssuedNotification(n).documentType,
      cs,
    );
  }

  // 1. Prefer action when present
  final action = n.args['action'] as String?;
  if (action != null && action.isNotEmpty) {
    return resolveActionMeta(action, cs);
  }

  // 2. Fallback to titleKey sub-type
  switch (n.titleKey) {
    case 'notification.event.reminder.title':
      return const NotifCategoryMeta(
          icon: Icons.alarm_rounded, color: Color(0xFFFF8F00));
    case 'notification.event.started.title':
      return NotifCategoryMeta(
          icon: Icons.play_circle_filled_rounded, color: Colors.green.shade600);
    case 'notification.event.created.title':
      return NotifCategoryMeta(
          icon: Icons.event_available_rounded, color: Colors.teal.shade600);
    case 'notification.event.updated.title':
      return NotifCategoryMeta(icon: Icons.edit_calendar_rounded, color: cs.primary);
    case 'notification.event.deleted.title':
      return NotifCategoryMeta(icon: Icons.event_busy_rounded, color: cs.error);
    case 'notification.eventMarkedDone.title':
      return NotifCategoryMeta(icon: Icons.task_alt_rounded, color: Colors.green.shade700);
    case 'notification.eventReopened.title':
      return NotifCategoryMeta(icon: Icons.redo_rounded, color: Colors.orange.shade700);
    case 'notification.recurrenceAdded.title':
      return NotifCategoryMeta(icon: Icons.repeat_rounded, color: cs.tertiary);
    default:
      break;
  }

  // 3. Broad category fallback
  switch (n.category) {
    case Category.groupInvitation:
      return NotifCategoryMeta(icon: Icons.group_add_rounded, color: cs.primary);
    case Category.groupCreation:
    case Category.groupUpdate:
      return NotifCategoryMeta(icon: Icons.group_rounded, color: cs.secondary);
    case Category.userRemoval:
    case Category.userInvitation:
      return NotifCategoryMeta(icon: Icons.person_rounded, color: cs.secondary);
    case Category.systemAlert:
    case Category.errorReport:
      return NotifCategoryMeta(icon: Icons.warning_amber_rounded, color: cs.error);
    case Category.achievement:
      return NotifCategoryMeta(icon: Icons.emoji_events_rounded, color: Colors.amber.shade700);
    case Category.billing:
      return NotifCategoryMeta(icon: Icons.receipt_long_rounded, color: cs.tertiary);
    default:
      return NotifCategoryMeta(icon: Icons.notifications_rounded, color: cs.primary);
  }
}

/// Whether this notification should render the richer event-card layout.
bool isEventNotification(NotificationUser n) =>
    n.category == Category.eventReminder ||
    isConcurrentEventNotification(n) ||
    n.titleKey.startsWith('notification.event.') ||
    n.titleKey.startsWith('notification.recurrenceAdded') ||
    n.titleKey.startsWith('notification.eventMarkedDone') ||
    n.titleKey.startsWith('notification.eventReopened');
