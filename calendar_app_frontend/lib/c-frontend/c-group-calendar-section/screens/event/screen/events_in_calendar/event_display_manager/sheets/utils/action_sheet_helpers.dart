import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/event/logic/actions/event_actions_manager.dart';

import '../event_actions_sheet.dart';
// showEventActionsSheet launcher (your action_sheet_helpers.dart)
void showEventActionsSheet({
  required BuildContext context,
  required Event event,
  required bool canEdit,
  required EventActionManager? actionManager,

}) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => EventActionsSheet(
      event: event,
      canEdit: canEdit,
      actionManager: actionManager,
    ),
  );
}



/// Normalize a role string: lowercase and remove non-letters (spaces/dashes).
String _norm(String? s) =>
    (s ?? '').toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');

/// Returns true if the single `userRole` grants edit/delete.
/// Allowed: owner, admin/administrator, coadmin/co-administrator (any casing/spacing).
bool canEdit(String? userRole) {
  final r = _norm(userRole);
  const allowed = {
    'owner',
    'admin',
    'administrator',
    'coadmin',
    'coadministrator',
  };
  return allowed.contains(r);
}

/// Variant for multiple roles, if you ever hold a list like ["member","coadmin"].
bool canEditAny(Iterable<String> roles) => roles.any((r) => canEdit(r));
