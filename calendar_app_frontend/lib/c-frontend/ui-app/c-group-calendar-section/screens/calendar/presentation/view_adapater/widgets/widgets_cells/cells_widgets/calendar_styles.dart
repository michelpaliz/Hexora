import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

Color getTextColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black87;

Color getBackgroundColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.grey[900]!
        : Colors.white;

BoxDecoration buildContainerDecoration(Color backgroundColor) => BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      color: backgroundColor,
      boxShadow: const [],
    );

CalendarHeaderStyle buildHeaderStyle(double fontSize, Color textColor) =>
    CalendarHeaderStyle(
      textAlign: TextAlign.center,
      backgroundColor: Colors.transparent,
      textStyle: GoogleFonts.poppins(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );

ViewHeaderStyle buildViewHeaderStyle(
        double fontSize, Color textColor, bool isDarkMode) =>
    ViewHeaderStyle(
      backgroundColor: Colors.transparent,
      dateTextStyle: GoogleFonts.poppins(fontSize: fontSize, color: textColor),
      dayTextStyle: GoogleFonts.poppins(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );


double responsiveMonthHeaderHeight(BuildContext context) {
  final size = MediaQuery.of(context).size;
  final shortest = size.shortestSide;
  final portrait = MediaQuery.of(context).orientation == Orientation.portrait;

  // Scale with width; clamp to sane bounds; add a small tablet bump.
  final base = size.width * (portrait ? 0.18 : 0.12);
  final tabletBump = shortest >= 600 ? 8.0 : 0.0;
  return base.clamp(80.0, 140.0) + tabletBump;
}

ScheduleViewSettings buildScheduleSettings(
  double fontSize,
  Color backgroundColor, {
  double? monthHeaderHeight, // <-- new, optional
}) =>
    ScheduleViewSettings(
      appointmentItemHeight: 60,
      monthHeaderSettings: MonthHeaderSettings(
        monthFormat: 'MMMM yyyy',
        height: monthHeaderHeight ?? 60, // <-- use responsive value when passed
        textAlign: TextAlign.left,
        // If you’re rendering an image in the header builder, keep this transparent
        // so the image isn’t covered by a solid color.
        backgroundColor: Colors.transparent,
        monthTextStyle: GoogleFonts.poppins(
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
        ),
      ),
    );

MonthViewSettings buildMonthSettings() => MonthViewSettings(
      showAgenda: true,
      agendaItemHeight: 48,
      dayFormat: 'EEE',
      appointmentDisplayMode: MonthAppointmentDisplayMode.none,
      appointmentDisplayCount: 4,
      showTrailingAndLeadingDates: false,
      navigationDirection: MonthNavigationDirection.vertical,
    );
