import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

Widget buildScheduleMonthHeader(
  BuildContext context,
  ScheduleViewMonthHeaderDetails details, [
  double height = 160,
]) {
  final l = AppLocalizations.of(context)!;

  // Get localized month name from ARB
  final months = [
    l.monthJanuary,
    l.monthFebruary,
    l.monthMarch,
    l.monthApril,
    l.monthMay,
    l.monthJune,
    l.monthJuly,
    l.monthAugust,
    l.monthSeptember,
    l.monthOctober,
    l.monthNovember,
    l.monthDecember,
  ];
  final monthName = months[details.date.month - 1];
  final monthLabel =
      l.monthYearFormat( monthName, '${details.date.year}');

  final imageAsset = _getImageForMonth(details.date.month);

  return Container(
    height: height,
    width: double.infinity,
    decoration: BoxDecoration(
      image: DecorationImage(
        image: AssetImage(imageAsset),
        fit: BoxFit.cover,
        alignment: Alignment.center,
        colorFilter: ColorFilter.mode(
          Colors.black.withOpacity(0.4),
          BlendMode.darken,
        ),
      ),
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
    ),
    alignment: Alignment.bottomLeft,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Text(
      monthLabel,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

String _getImageForMonth(int month) {
  const images = {
    1: 'assets/images/months/january.png',
    2: 'assets/images/months/february.png',
    3: 'assets/images/months/march.png',
    4: 'assets/images/months/april.png',
    5: 'assets/images/months/may.png',
    6: 'assets/images/months/june.png',
    7: 'assets/images/months/july.png',
    8: 'assets/images/months/august.png',
    9: 'assets/images/months/september.png',
    10: 'assets/images/months/october.png',
    11: 'assets/images/months/november.png',
    12: 'assets/images/months/december.png',
  };
  return images[month] ?? 'assets/images/default.png';
}
