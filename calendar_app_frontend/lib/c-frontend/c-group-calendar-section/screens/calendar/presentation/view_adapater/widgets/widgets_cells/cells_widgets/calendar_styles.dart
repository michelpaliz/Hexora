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
      borderRadius: BorderRadius.circular(16),
      color: backgroundColor,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          spreadRadius: 2,
          offset: Offset(0, 4),
        ),
      ],
    );

CalendarHeaderStyle buildHeaderStyle(double fontSize, Color textColor) =>
    CalendarHeaderStyle(
      textAlign: TextAlign.center,
      backgroundColor: Colors.transparent,
      textStyle: GoogleFonts.poppins(
        fontSize: fontSize * 1.2,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );

ViewHeaderStyle buildViewHeaderStyle(
        double fontSize, Color textColor, bool isDarkMode) =>
    ViewHeaderStyle(
      backgroundColor: isDarkMode ? Colors.grey[850] : Colors.grey[100],
      dateTextStyle: GoogleFonts.poppins(fontSize: fontSize, color: textColor),
      dayTextStyle: GoogleFonts.poppins(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );

// ScheduleViewSettings buildScheduleSettings(
//         double fontSize, Color backgroundColor) =>
//     ScheduleViewSettings(
//       appointmentItemHeight: 80,
//       monthHeaderSettings: MonthHeaderSettings(
//         monthFormat: 'MMMM yyyy',
//         height: 60,
//         textAlign: TextAlign.left,
//         backgroundColor: backgroundColor,
//         monthTextStyle: GoogleFonts.poppins(
//           fontSize: fontSize,
//           fontWeight: FontWeight.w500,
//         ),
//       ),
//     );

// styles.dart (same file you showed)

double responsiveMonthHeaderHeight(BuildContext context) {
  final size = MediaQuery.of(context).size;
  final shortest = size.shortestSide;
  final portrait = MediaQuery.of(context).orientation == Orientation.portrait;

  // Scale with width; clamp to sane bounds; add a small tablet bump.
  final base = size.width * (portrait ? 0.26 : 0.20);
  final tabletBump = shortest >= 600 ? 24.0 : 0.0;
  return base.clamp(140.0, 240.0) + tabletBump;
}

ScheduleViewSettings buildScheduleSettings(
  double fontSize,
  Color backgroundColor, {
  double? monthHeaderHeight, // <-- new, optional
}) =>
    ScheduleViewSettings(
      appointmentItemHeight: 80,
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
      agendaItemHeight: 60,
      dayFormat: 'EEE',
      appointmentDisplayMode: MonthAppointmentDisplayMode.none,
      appointmentDisplayCount: 4,
      showTrailingAndLeadingDates: false,
      navigationDirection: MonthNavigationDirection.vertical,
    );
