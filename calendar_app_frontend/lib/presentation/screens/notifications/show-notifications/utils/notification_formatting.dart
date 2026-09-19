import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

String formatTimeDifference(DateTime dt, BuildContext context) {
  final loc = AppLocalizations.of(context)!;
  final now = DateTime.now();
  final diff = now.difference(dt);
  final locale = Localizations.localeOf(context);
  final isEs = locale.languageCode == 'es';

  if (diff.inSeconds < 60) return loc.timeJustNow;
  if (diff.inMinutes < 60) return loc.timeMinutesAgo(diff.inMinutes.toString());
  if (diff.inHours < 24) return loc.timeHoursAgo(diff.inHours.toString());
  if (diff.inDays < 30) return loc.timeDaysAgo(diff.inDays.toString());

  final months = (diff.inDays / 30.4).floor().clamp(1, 11);
  if (diff.inDays < 365) {
    return isEs
        ? 'Hace $months ${months == 1 ? 'mes' : 'meses'}'
        : '$months ${months == 1 ? 'month' : 'months'} ago';
  }

  return DateFormat.yMMMd(locale.toString()).format(dt);
}
