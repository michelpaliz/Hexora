// calendar_surface.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:hexora/a-models/weather/day_summary.dart';
import 'package:hexora/b-backend/group_mng_flow/event/domain/event_domain.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/calendar/presentation/view_adapater/widgets/widgets_cells/cells_widgets/calendar_month_cell.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/calendar/presentation/view_adapater/widgets/widgets_cells/cells_widgets/calendar_styles.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/calendar/presentation/view_adapater/widgets/widgets_cells/month_schedule_img/calendar_styles.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart' as sf;

import '../adapter/calendar_state.dart';
import 'appointment_builder_bridge.dart';

typedef TimeRangeSelected = void Function(DateTime start, DateTime end);

// calendar_surface.dart
class CalendarSurface extends StatefulWidget {
  final CalendarState state;
  final AppointmentBuilderBridge apptBridge;
  final EventDomain eventDomain;
  final String? forcedViewMode;
  final bool showMonthAgenda;
  final TimeRangeSelected? onTimeRangeSelected;

  const CalendarSurface({
    super.key,
    required this.state,
    required this.apptBridge,
    required this.eventDomain,
    this.forcedViewMode,
    this.showMonthAgenda = true,
    this.onTimeRangeSelected,
  });

  @override
  State<CalendarSurface> createState() => _CalendarSurfaceState();
}

class _CalendarSurfaceState extends State<CalendarSurface> {
  final sf.CalendarController _controller = sf.CalendarController();
  sf.CalendarView _selectedView = sf.CalendarView.month;
  DateTime? _selectedDate;
  DateTime? _selectionStart;
  DateTime? _selectionEnd;
  DateTime? _dragSelectionAnchor;
  bool _syncScheduled = false;
  bool _isDraggingEvent = false;
  bool _isSelectingTimeRange = false;

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

  List<sf.TimeRegion> _buildSelectedSlotRegion() {
    final start = _selectionStart;
    final end = _selectionEnd;
    if (start == null || end == null) return const [];
    return [
      sf.TimeRegion(
        startTime: start,
        endTime: end,
        enablePointerInteraction: false,
        color: Colors.transparent,
        text: '__selected__',
      ),
    ];
  }

  Widget _buildTimeRegionWidget(
      BuildContext ctx, sf.TimeRegionDetails details) {
    if (details.region.text != '__selected__') return const SizedBox.shrink();
    final cs = Theme.of(ctx).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.13),
        border: Border(
          left: BorderSide(color: cs.primary, width: 3),
        ),
      ),
    );
  }

  bool _isTimeGridView() =>
      _selectedView == sf.CalendarView.day ||
      _selectedView == sf.CalendarView.week ||
      _selectedView == sf.CalendarView.workWeek;

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DateTime _slotStart(DateTime slot) => DateTime(
        slot.year,
        slot.month,
        slot.day,
        slot.hour,
      );

  DateTime? _timeGridSlotAt(Offset localPosition) {
    if (!_isTimeGridView()) return null;
    final details = _controller.getCalendarDetailsAtOffset?.call(localPosition);
    if (details == null ||
        details.targetElement != sf.CalendarElement.calendarCell ||
        details.date == null) {
      return null;
    }
    return _slotStart(details.date!);
  }

  void _updateDraggedTimeSelection(DateTime slot) {
    final anchor = _dragSelectionAnchor;
    if (anchor == null || !_isSameDate(anchor, slot)) return;

    final start = slot.isBefore(anchor) ? slot : anchor;
    final lastSlot = slot.isAfter(anchor) ? slot : anchor;
    final end = lastSlot.add(const Duration(hours: 1));

    if (_selectionStart == start && _selectionEnd == end) return;
    setState(() {
      _selectionStart = start;
      _selectionEnd = end;
    });
  }

  void _handleSelectionPointerDown(Offset localPosition) {
    if (_isDraggingEvent) return;
    final slot = _timeGridSlotAt(localPosition);
    if (slot == null) return;
    _dragSelectionAnchor = slot;
    _isSelectingTimeRange = true;
    _updateDraggedTimeSelection(slot);
  }

  void _handleSelectionPointerMove(Offset localPosition) {
    if (!_isSelectingTimeRange) return;
    final slot = _timeGridSlotAt(localPosition);
    if (slot == null) return;
    _updateDraggedTimeSelection(slot);
  }

  void _handleSelectionPointerEnd() {
    _isSelectingTimeRange = false;
    _dragSelectionAnchor = null;
  }

  void _selectTimeSlot(DateTime slot) {
    final tappedStart = _slotStart(slot);
    final tappedEnd = tappedStart.add(const Duration(hours: 1));
    final currentStart = _selectionStart;
    final sameDay = currentStart != null &&
        currentStart.year == tappedStart.year &&
        currentStart.month == tappedStart.month &&
        currentStart.day == tappedStart.day;

    setState(() {
      if (!sameDay) {
        _selectionStart = tappedStart;
        _selectionEnd = tappedEnd;
        return;
      }

      _selectionStart =
          tappedStart.isBefore(currentStart) ? tappedStart : currentStart;
      final currentEnd =
          _selectionEnd ?? currentStart.add(const Duration(hours: 1));
      _selectionEnd = tappedEnd.isAfter(currentEnd) ? tappedEnd : currentEnd;
    });
  }

  void _clearTimeSelection() {
    setState(() {
      _selectionStart = null;
      _selectionEnd = null;
    });
  }

  Widget _buildTimeSelectionBar(BuildContext context) {
    final start = _selectionStart!;
    final end = _selectionEnd!;
    final localizations = MaterialLocalizations.of(context);
    final date = localizations.formatMediumDate(start);
    final startTime = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(start),
      alwaysUse24HourFormat: true,
    );
    final endTime = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(end),
      alwaysUse24HourFormat: true,
    );
    final cs = Theme.of(context).colorScheme;
    final label = '$date  |  $startTime - $endTime';

    void createEvent() {
      widget.onTimeRangeSelected?.call(start, end);
      _clearTimeSelection();
    }

    return Material(
      elevation: 6,
      color: cs.surface,
      shadowColor: Colors.black.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 520;
            final selectionLabel = Row(
              mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
              children: [
                Icon(Icons.schedule_rounded, size: 19, color: cs.primary),
                const SizedBox(width: 9),
                if (compact)
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  )
                else
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                IconButton(
                  tooltip: 'Cancelar seleccion',
                  onPressed: _clearTimeSelection,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            );

            final createButton = FilledButton.icon(
              onPressed: createEvent,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Crear evento'),
            );

            if (compact) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  selectionLabel,
                  const SizedBox(height: 6),
                  SizedBox(width: double.infinity, child: createButton),
                ],
              );
            }

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                selectionLabel,
                const SizedBox(width: 4),
                createButton,
              ],
            );
          },
        ),
      ),
    );
  }

  void _scheduleSync(VoidCallback action) {
    if (_syncScheduled) return;
    _syncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncScheduled = false;
      action();
    });
  }

  Event? _extractDraggedEvent(Object? raw) {
    if (raw is Event) return raw;
    if (raw is List && raw.isNotEmpty) {
      final first = raw.first;
      if (first is Event) return first;
    }
    return null;
  }

  Future<bool> _confirmMoveEvent(
    BuildContext context, {
    required Event event,
    required DateTime newStart,
    required DateTime newEnd,
  }) async {
    final localizations = MaterialLocalizations.of(context);
    final dateLabel = localizations.formatMediumDate(newStart);
    final startLabel = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(newStart),
      alwaysUse24HourFormat: true,
    );
    final endLabel = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(newEnd),
      alwaysUse24HourFormat: true,
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final cs = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          title: const Text('Confirmar cambio de fecha'),
          content: Text(
            'Quieres mover "${event.title}" al $dateLabel de $startLabel a $endLabel?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(localizations.cancelButtonLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
              ),
              child: const Text('Mover evento'),
            ),
          ],
        );
      },
    );

    return confirmed == true;
  }

  Future<void> _handleAppointmentDragEnd(
    BuildContext context,
    sf.AppointmentDragEndDetails details,
  ) async {
    final dragged = _extractDraggedEvent(details.appointment);
    final droppedTime = details.droppingTime;
    if (dragged == null || droppedTime == null || _isDraggingEvent) return;

    if (dragged.recurrenceRule != null || dragged.rawRuleId != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Los eventos recurrentes deben editarse manualmente.',
          ),
        ),
      );
      return;
    }

    final duration = dragged.endDate.difference(dragged.startDate);
    final newStart = dragged.allDay
        ? DateTime(
            droppedTime.year,
            droppedTime.month,
            droppedTime.day,
            dragged.startDate.hour,
            dragged.startDate.minute,
            dragged.startDate.second,
            dragged.startDate.millisecond,
            dragged.startDate.microsecond,
          )
        : droppedTime;
    final newEnd = newStart.add(duration);

    if (newStart == dragged.startDate && newEnd == dragged.endDate) return;

    final confirmed = await _confirmMoveEvent(
      context,
      event: dragged,
      newStart: newStart,
      newEnd: newEnd,
    );
    if (!mounted || !confirmed) return;

    final movedEvent = dragged.copyWith(
      startDate: newStart,
      endDate: newEnd,
    );

    _isDraggingEvent = true;
    try {
      await widget.eventDomain.updateEvent(this.context, movedEvent);
      widget.state.jumpTo(newStart);
      if (!mounted) return;
      ScaffoldMessenger.of(this.context).showSnackBar(
        const SnackBar(
          content: Text('Evento movido correctamente.'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(this.context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo mover el evento.'),
        ),
      );
    } finally {
      _isDraggingEvent = false;
    }
  }

  // calendar_surface.dart (add near other fields)
  double _responsiveMonthHeaderHeight(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final shortest = size.shortestSide;
    final portrait = MediaQuery.of(context).orientation == Orientation.portrait;

    // Base height scales with width; clamp to tighter bounds for web/inline.
    final base = size.width * (portrait ? 0.14 : 0.10);

    // Slightly larger on tablets/desktop
    final tabletBump = shortest >= 600 ? 8.0 : 0.0;

    // Clamp between 80–140 so headers don't dominate the card
    return base.clamp(80.0, 140.0) + tabletBump;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = getTextColor(context);
    final backgroundColor = Theme.of(context).canvasColor;
    // Keep headers legible but compact on web/inline layouts
    final fontSize =
        (MediaQuery.of(context).size.width * 0.014).clamp(11.0, 14.0);
    // inside build(BuildContext context) just after you compute fontSize, etc.
    final double monthHeaderHeight = _responsiveMonthHeaderHeight(context);

    // 1) Listen to view mode
    return ValueListenableBuilder<String>(
      valueListenable: widget.state.viewMode,
      builder: (_, mode, __) {
        final effectiveMode = widget.forcedViewMode ?? mode;
        final view = _mapModeToSf(effectiveMode);
        if (_controller.view != view) {
          _selectedView = view;
          _scheduleSync(() {
            _controller.view = view;
          });
        }

        // 2) Listen to anchor date (jump/scroll target)
        return ValueListenableBuilder<DateTime>(
          valueListenable: widget.state.anchorDate,
          builder: (_, anchor, __) {
            if (anchor != _controller.displayDate) {
              _selectedDate = anchor;
              _scheduleSync(() {
                _controller.displayDate = anchor;
                _controller.selectedDate = anchor;
              });
            }

            // 3) Listen to data source (events)
            return ValueListenableBuilder<sf.CalendarDataSource>(
              valueListenable: widget.state.dataSource,
              builder: (_, ds, __) {
                // 4) Keep allEvents for month cell builder
                return ValueListenableBuilder<List<Event>>(
                  valueListenable: widget.state.allEvents,
                  builder: (_, events, __) {
                    return ValueListenableBuilder<Map<DateTime, DaySummary>>(
                      valueListenable: widget.state.weatherForecast,
                      builder: (_, forecast, __) {
                        return ValueListenableBuilder<bool>(
                          valueListenable: widget.state.showWeatherIcons,
                          builder: (_, showWeatherIcons, __) {
                            final weatherMap = showWeatherIcons
                                ? _resolveForecast(forecast)
                                : const <DateTime, DaySummary>{};
                            final isTimeGridView = _isTimeGridView();
                            final calendarHeaderHeight =
                                isTimeGridView ? 42.0 : 36.0;
                            final calendarViewHeaderHeight =
                                isTimeGridView ? 56.0 : 40.0;

                            return Container(
                              decoration:
                                  buildContainerDecoration(backgroundColor),
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Listener(
                                      onPointerDown: (event) =>
                                          _handleSelectionPointerDown(
                                              event.localPosition),
                                      onPointerMove: (event) =>
                                          _handleSelectionPointerMove(
                                              event.localPosition),
                                      onPointerUp: (_) =>
                                          _handleSelectionPointerEnd(),
                                      onPointerCancel: (_) =>
                                          _handleSelectionPointerEnd(),
                                      child: sf.SfCalendar(
                                        key: ObjectKey(
                                            '${ds.hashCode}-$effectiveMode'),
                                        controller: _controller,
                                        dataSource: ds,
                                        view: _selectedView,
                                        headerHeight: calendarHeaderHeight,
                                        viewHeaderHeight:
                                            calendarViewHeaderHeight,
                                        onViewChanged: (_) =>
                                            _selectedView = _controller.view!,
                                        onSelectionChanged: (d) {
                                          if (d.date == null) return;
                                          _selectedDate = d.date!;
                                          _scheduleSync(() {
                                            _controller.selectedDate =
                                                _selectedDate;
                                            widget.state.jumpTo(_selectedDate!);
                                          });
                                        },
                                        onTap: (details) {
                                          final tapped = details.date;
                                          if (tapped == null) return;
                                          final target = details.targetElement;
                                          if (target !=
                                              sf.CalendarElement.calendarCell) {
                                            return;
                                          }
                                          if (!_isTimeGridView()) {
                                            return;
                                          }
                                          _selectTimeSlot(tapped);
                                        },
                                        // ✅ Keep Month custom tiles (old behavior)
                                        monthCellBuilder: (context, d) =>
                                            buildMonthCell(
                                          context: context,
                                          details: d,
                                          selectedDate: _selectedDate,
                                          events: events,
                                          weatherSummaries: weatherMap,
                                        ),

                                        scheduleViewMonthHeaderBuilder:
                                            (context, d) =>
                                                buildScheduleMonthHeader(
                                                    context,
                                                    d,
                                                    monthHeaderHeight),
                                        scheduleViewSettings:
                                            sf.ScheduleViewSettings(
                                          monthHeaderSettings:
                                              sf.MonthHeaderSettings(
                                            height:
                                                monthHeaderHeight, // <-- must match builder height
                                            backgroundColor: Colors
                                                .transparent, // keep images visible
                                            monthFormat: 'MMMM yyyy',
                                            textAlign: TextAlign.left,
                                          ),
                                          appointmentItemHeight: 60,
                                        ),

                                        appointmentBuilder:
                                            (context, details) =>
                                                widget.apptBridge.build(
                                                    context,
                                                    _selectedView,
                                                    details,
                                                    textColor),
                                        allowDragAndDrop: isTimeGridView,
                                        onDragEnd: (details) =>
                                            _handleAppointmentDragEnd(
                                                context, details),
                                        specialRegions:
                                            _buildSelectedSlotRegion(),
                                        timeRegionBuilder:
                                            _buildTimeRegionWidget,
                                        selectionDecoration:
                                            const BoxDecoration(
                                                color: Colors.transparent),
                                        showNavigationArrow: true,
                                        showDatePickerButton: true,
                                        firstDayOfWeek: DateTime.monday,
                                        initialSelectedDate: DateTime.now(),
                                        headerStyle: buildHeaderStyle(
                                            fontSize, textColor),
                                        viewHeaderStyle: buildViewHeaderStyle(
                                            fontSize, textColor, isDarkMode),
                                        // scheduleViewSettings: buildScheduleSettings(
                                        //     fontSize, backgroundColor,
                                        //     monthHeaderHeight: monthHeaderHeight),
                                        monthViewSettings: buildMonthSettings(
                                          showAgenda: widget.showMonthAgenda,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (_selectionStart != null &&
                                      _selectionEnd != null)
                                    Positioned(
                                      left: 16,
                                      right: 16,
                                      bottom: 16,
                                      child: Align(
                                        alignment: Alignment.bottomCenter,
                                        child: _buildTimeSelectionBar(context),
                                      ),
                                    ),
                                ],
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
          },
        );
      },
    );
  }
}

Map<DateTime, DaySummary> _resolveForecast(Map<DateTime, DaySummary> forecast) {
  return forecast;
}
