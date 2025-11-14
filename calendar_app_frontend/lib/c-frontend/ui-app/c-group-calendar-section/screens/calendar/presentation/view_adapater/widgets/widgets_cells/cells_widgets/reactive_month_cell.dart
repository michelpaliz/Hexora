import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:hexora/b-backend/group_mng_flow/event/domain/event_domain.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/calendar/presentation/view_adapater/widgets/widgets_cells/cells_widgets/calendar_mont_cell.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class ReactiveMonthCell extends StatelessWidget {
  final MonthCellDetails details;
  final DateTime? selectedDate;
  final bool isDarkMode;

  const ReactiveMonthCell({
    required this.details,
    required this.selectedDate,
    required this.isDarkMode,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final eventDomain = context.watch<EventDomain>();

    return ValueListenableBuilder<List<Event>>(
      valueListenable: eventDomain.eventsNotifier,
      builder: (context, events, _) {
        return buildMonthCell(
          context: context,
          details: details,
          selectedDate: selectedDate,
          // isDarkMode: isDarkMode,
          events: events,
        );
      },
    );
  }
}
