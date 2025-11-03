// calendar_surface.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/calendar/presentation/view_adapater/widgets/widgets_cells/cells_widgets/calendar_mont_cell.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/calendar/presentation/view_adapater/widgets/widgets_cells/cells_widgets/calendar_styles.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/calendar/presentation/view_adapater/widgets/widgets_cells/month_schedule_img/calendar_styles.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart' as sf;

import '../adapter/calendar_state.dart';
import 'appointment_builder_bridge.dart';

// calendar_surface.dart
class CalendarSurface extends StatefulWidget {
  final CalendarState state;
  final AppointmentBuilderBridge apptBridge;

  const CalendarSurface({
    super.key,
    required this.state,
    required this.apptBridge,
  });

  @override
  State<CalendarSurface> createState() => _CalendarSurfaceState();
}

class _CalendarSurfaceState extends State<CalendarSurface> {
  final sf.CalendarController _controller = sf.CalendarController();
  sf.CalendarView _selectedView = sf.CalendarView.month;
  DateTime? _selectedDate;

  sf.CalendarView _mapModeToSf(String mode) {
    switch (mode) {
      case 'day':
        return sf.CalendarView.day;
      case 'week':
        return sf.CalendarView.week;
      case 'month':
        return sf.CalendarView.month;
      case 'agenda':
      case 'schedule': // alias
        return sf.CalendarView.schedule;
      default:
        return sf.CalendarView.week; // sane default
    }
  }

  @override
  void initState() {
    super.initState();
    // Initialize controller’s view to current mode
    _selectedView = _mapModeToSf(widget.state.currentViewMode);
    _controller.view = _selectedView;
  }

  // calendar_surface.dart (add near other fields)
  double _responsiveMonthHeaderHeight(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final shortest = size.shortestSide;
    final portrait = MediaQuery.of(context).orientation == Orientation.portrait;

    // Base height scales with width; clamp to sane bounds.
    final base = size.width * (portrait ? 0.28 : 0.22);

    // Slightly larger on tablets/desktop
    final tabletBump = shortest >= 600 ? 32.0 : 0.0;

    // Clamp between 140–260 so images don’t get ridiculous
    return base.clamp(140.0, 260.0) + tabletBump;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = getTextColor(context);
    final backgroundColor = getBackgroundColor(context).withOpacity(0.8);
    final fontSize = MediaQuery.of(context).size.width * 0.035;
    // inside build(BuildContext context) just after you compute fontSize, etc.
    final double monthHeaderHeight = _responsiveMonthHeaderHeight(context);

    // 1) Listen to view mode
    return ValueListenableBuilder<String>(
      valueListenable: widget.state.viewMode,
      builder: (_, mode, __) {
        final view = _mapModeToSf(mode);
        if (_controller.view != view) {
          _controller.view = view;
          _selectedView = view;
        }

        // 2) Listen to anchor date (jump/scroll target)
        return ValueListenableBuilder<DateTime>(
          valueListenable: widget.state.anchorDate,
          builder: (_, anchor, __) {
            if (anchor != _controller.displayDate) {
              _controller.displayDate = anchor;
              _controller.selectedDate = anchor;
              _selectedDate = anchor;
            }

            // 3) Listen to data source (events)
            return ValueListenableBuilder<sf.CalendarDataSource>(
              valueListenable: widget.state.dataSource,
              builder: (_, ds, __) {
                // 4) Keep allEvents for month cell builder
                return ValueListenableBuilder<List<Event>>(
                  valueListenable: widget.state.allEvents,
                  builder: (_, events, __) {
                    return Container(
                      decoration: buildContainerDecoration(backgroundColor),
                      child: sf.SfCalendar(
                        key: ObjectKey('${ds.hashCode}-$mode'),
                        controller: _controller,
                        dataSource: ds,
                        view: _selectedView,
                        allowedViews: const [
                          sf.CalendarView.day,
                          sf.CalendarView.week,
                          sf.CalendarView.month,
                          sf.CalendarView.schedule,
                        ],
                        onViewChanged: (_) => _selectedView = _controller.view!,
                        onSelectionChanged: (d) {
                          if (d.date != null) {
                            _selectedDate = d.date!;
                            _controller.selectedDate = _selectedDate;
                            widget.state.selectedDate = _selectedDate;
                            widget.state.dailyEvents.value =
                                widget.state.eventsForDate(
                              _selectedDate!,
                              widget.state.allEvents.value,
                            );
                          }
                        },
                        // ✅ Keep Month custom tiles (old behavior)
                        monthCellBuilder: (context, d) => buildMonthCell(
                          context: context,
                          details: d,
                          selectedDate: _selectedDate,
                          events: events,
                        ),

                        scheduleViewMonthHeaderBuilder: (context, d) =>
                            buildScheduleMonthHeader(
                                context, d, monthHeaderHeight),
                        scheduleViewSettings: sf.ScheduleViewSettings(
                          monthHeaderSettings: sf.MonthHeaderSettings(
                            height:
                                monthHeaderHeight, // <-- must match builder height
                            backgroundColor:
                                Colors.transparent, // keep images visible
                            monthFormat: 'MMMM yyyy',
                            textAlign: TextAlign.left,
                          ),
                          appointmentItemHeight: 80,
                        ),

                        appointmentBuilder: (context, details) => widget
                            .apptBridge
                            .build(context, _selectedView, details, textColor),
                        selectionDecoration:
                            const BoxDecoration(color: Colors.transparent),
                        showNavigationArrow: true,
                        showDatePickerButton: true,
                        firstDayOfWeek: DateTime.monday,
                        initialSelectedDate: DateTime.now(),
                        headerStyle: buildHeaderStyle(fontSize, textColor),
                        viewHeaderStyle: buildViewHeaderStyle(
                            fontSize, textColor, isDarkMode),
                        // scheduleViewSettings: buildScheduleSettings(
                        //     fontSize, backgroundColor,
                        //     monthHeaderHeight: monthHeaderHeight),
                        monthViewSettings: buildMonthSettings(),
                      ),
                    ).animate().fadeIn(duration: 300.ms);
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
