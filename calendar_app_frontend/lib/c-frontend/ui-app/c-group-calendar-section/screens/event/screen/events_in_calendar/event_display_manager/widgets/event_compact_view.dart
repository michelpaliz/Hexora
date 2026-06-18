import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/event/logic/actions/event_actions_manager.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/event/screen/events_in_calendar/event_display_manager/sheets/utils/action_sheet_helpers.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/utils/color_manager.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class EventCompactView extends StatelessWidget {
  final Event event;
  final CalendarAppointmentDetails details;
  final Color textColor;
  final EventActionManager? actionManager;
  final ColorManager colorManager;
  final String userRole;

  const EventCompactView({
    super.key,
    required this.event,
    required this.details,
    required this.textColor,
    required this.colorManager,
    required this.userRole,
    this.actionManager,
  });

  String _formatTimeRange(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final fmt = DateFormat.jm(locale);
    return '${fmt.format(event.startDate)} – ${fmt.format(event.endDate)}';
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = colorManager.getColor(event.eventColorIndex);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canEditEvent = canEdit(userRole);

    final h = details.bounds.height;
    // Thresholds: <28px → micro (icon only), <46px → single line, else full
    final isMicro = h < 28;
    final isCompact = h < 46;

    // Text colors: title uses the event color for pop, meta slightly muted
    final titleColor = isDark
        ? Color.lerp(Colors.white, cardColor, 0.35)!
        : Color.lerp(Colors.black87, cardColor, 0.55)!;
    final metaColor = isDark
        ? Colors.white.withValues(alpha: 0.52)
        : cardColor.withValues(alpha: 0.65);

    // Background: tinted with the event color
    final bgColor = cardColor.withValues(alpha: isDark ? 0.18 : 0.10);

    Widget content;

    if (isMicro) {
      // Tiny slot — just show a colored dot + clipped title
      content = Row(
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: cardColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              event.title,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: titleColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    } else if (isCompact) {
      // Single-line: title only
      content = Text(
        event.title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: titleColor,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    } else {
      // Full: title + time range
      final maxTitleLines = h > 68 ? 2 : 1;
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            event.title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: titleColor,
              height: 1.25,
            ),
            maxLines: maxTitleLines,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 9,
                color: metaColor,
              ),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  _formatTimeRange(context),
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                    color: metaColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: () {
        if (canEditEvent) actionManager?.editEvent(event, context);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: details.bounds.width,
          height: h,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(6),
            border: Border(
              left: BorderSide(color: cardColor, width: 3),
            ),
          ),
          padding: EdgeInsets.only(
            left: 6,
            right: 4,
            top: isMicro ? 0 : 4,
            bottom: isMicro ? 0 : 4,
          ),
          alignment: isMicro ? Alignment.centerLeft : Alignment.topLeft,
          child: content,
        ),
      ),
    );
  }
}
