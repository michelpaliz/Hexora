// event_form_router.dart
import 'package:flutter/material.dart';
import 'package:hexora/b-backend/group_mng_flow/category/category_api_client.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/actions/shared/base/base_event_logic.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/actions/shared/form/event_dialogs.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/actions/shared/form/type/event_types/work/event_form_work_visit.dart';

class EventFormRouter extends StatefulWidget {
  final BaseEventLogic logic;
  final Future<void> Function() onSubmit;
  final String ownerUserId;
  final CategoryApi categoryApi;
  final bool isEditing;

  /// Parent’s dialog impl (e.g., `this`)
  final EventDialogs dialogs;

  /// (Kept for backward-compat but ignored by option B)
  final bool enableClientServicePickers;

  const EventFormRouter({
    super.key,
    required this.logic,
    required this.onSubmit,
    required this.ownerUserId,
    required this.categoryApi,
    required this.dialogs,
    this.isEditing = false,
    this.enableClientServicePickers = false,
  });

  @override
  State<EventFormRouter> createState() => _EventFormRouterState();
}

class _EventFormRouterState extends State<EventFormRouter> {
  // Always use work_visit type
  static const String _type = 'work_visit';

  @override
  void initState() {
    super.initState();

    // Inform logic on first frame - always work_visit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.logic.setEventType?.call(_type);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Always show work visit form
    return EventFormWorkVisit(
      logic: widget.logic,
      onSubmit: widget.onSubmit,
      ownerUserId: widget.ownerUserId,
      isEditing: widget.isEditing,
      dialogs: widget.dialogs,
      enableClientServicePickers: true,
    );
  }
}
