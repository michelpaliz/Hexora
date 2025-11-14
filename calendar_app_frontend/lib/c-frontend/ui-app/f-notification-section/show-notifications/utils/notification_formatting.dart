import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

// flutter gen-l10n == run this to update

String formatTimeDifference(DateTime dt, BuildContext context) {
  final loc = AppLocalizations.of(context)!;
  final now = DateTime.now();
  final diff = now.difference(dt);

  if (diff.inSeconds < 60) return loc.timeJustNow;
  if (diff.inMinutes < 60) return loc.timeMinutesAgo(diff.inMinutes.toString());
  if (diff.inHours < 24) return loc.timeHoursAgo(diff.inHours.toString());
  if (diff.inDays < 7) return loc.timeDaysAgo(diff.inDays.toString());
  if (diff.inDays < 30) return loc.timeLast30Days;

  return DateFormat('MMM d, yyyy').format(dt);
}
