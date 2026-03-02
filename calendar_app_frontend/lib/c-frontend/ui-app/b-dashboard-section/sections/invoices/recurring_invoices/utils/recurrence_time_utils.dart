import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/utils/recurrence_frequency.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

bool _tzInitialized = false;
List<String>? _cachedTimezones;

void _ensureTz() {
  if (_tzInitialized) return;
  tz_data.initializeTimeZones();
  _tzInitialized = true;
}

List<String> availableTimezones() {
  _ensureTz();
  final cached = _cachedTimezones;
  if (cached != null) return cached;
  final list = tz.timeZoneDatabase.locations.keys.toList()..sort();
  _cachedTimezones = list;
  return list;
}

tz.Location? tryGetLocation(String? timezone) {
  _ensureTz();
  final name = (timezone ?? '').trim();
  if (name.isEmpty) return null;
  try {
    return tz.getLocation(name);
  } catch (_) {
    return null;
  }
}

String detectTimezone() {
  _ensureTz();
  final name = DateTime.now().timeZoneName;
  if (availableTimezones().contains(name)) {
    return name;
  }
  return 'Europe/Madrid';
}

String timezoneLabelFrom(String? tzName) {
  final value = (tzName ?? '').trim();
  if (value.isEmpty || value == 'Europe/Madrid') return 'Madrid';
  return value;
}

DateTime? parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
  if (v is Map && v[r'$date'] is num) {
    return DateTime.fromMillisecondsSinceEpoch((v[r'$date'] as num).toInt());
  }
  if (v is Map && v[r'$date'] is String) {
    return DateTime.tryParse(v[r'$date'] as String);
  }
  return null;
}

TimeOfDay? parseTimeOfDay(dynamic v) {
  if (v == null) return null;
  if (v is String && v.contains(':')) {
    final parts = v.split(':');
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '0');
    if (hour != null && minute != null) {
      return TimeOfDay(hour: hour, minute: minute);
    }
  }
  return null;
}

String formatTimeOfDay(TimeOfDay t) {
  final h = t.hour.toString().padLeft(2, '0');
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

DateTime localDateTime(DateTime date, TimeOfDay time) => DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

DateTime localDateTimeInZone(
  DateTime date,
  TimeOfDay time,
  String? timezone,
) {
  final location = tryGetLocation(timezone);
  if (location == null) return localDateTime(date, time);
  return tz.TZDateTime(
    location,
    date.year,
    date.month,
    date.day,
    time.hour,
    time.minute,
  );
}

DateTime utcDateTime(
  DateTime date,
  TimeOfDay time, [
  String? timezone,
]) {
  final location = tryGetLocation(timezone);
  if (location != null) {
    return tz
        .TZDateTime(
          location,
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        )
        .toUtc();
  }
  return localDateTime(date, time).toUtc();
}

String utcDateString(
  DateTime date,
  TimeOfDay time, [
  String? timezone,
]) =>
    DateFormat('yyyy-MM-dd').format(utcDateTime(date, time, timezone));

/// Returns local time string (NOT UTC) to preserve clock time across DST changes.
/// For recurring schedules, we want "19:00" to always mean "19:00 local time"
/// regardless of whether DST is active or not.
String utcTimeString(
  DateTime date,
  TimeOfDay time, [
  String? timezone,
]) {
  // Return local time instead of UTC to preserve clock time across DST
  final h = time.hour.toString().padLeft(2, '0');
  final m = time.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

DateTime utcToZoned(DateTime utc, String? timezone) {
  final location = tryGetLocation(timezone);
  if (location != null) {
    return tz.TZDateTime.from(utc, location);
  }
  return utc.toLocal();
}

String ruleSummary(Map? rule, AppLocalizations l) {
  if (rule == null) return l.recurringRuleEmpty;
  final freq = normalizeFrequencyFromApi(
    (rule['freq'] ?? rule['frequency'] ?? recurringFreqMonthly).toString(),
  );
  final intervalValue = int.tryParse((rule['interval'] ?? 1).toString()) ?? 1;
  final start = parseDate(rule['startDate']);
  final timeOfDay = rule['timeOfDay']?.toString();
  DateTime? localStart;
  if (start != null && timeOfDay != null && timeOfDay.isNotEmpty) {
    final parts = timeOfDay.split(':');
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '0');
    if (hour != null && minute != null) {
      // Interpret timeOfDay as LOCAL time in the specified timezone
      // (not UTC) to preserve clock time across DST changes
      final location = tryGetLocation(rule['timezone']?.toString());
      if (location != null) {
        localStart = tz.TZDateTime(
          location,
          start.year,
          start.month,
          start.day,
          hour,
          minute,
        );
      } else {
        localStart = DateTime(
          start.year,
          start.month,
          start.day,
          hour,
          minute,
        );
      }
    }
  }
  final startLabel = (localStart ?? start) == null
      ? ''
      : ' ${l.recurringStartFromLabel(DateFormat.yMMMd(l.localeName).format((localStart ?? start)!))}';
  final billDay = rule['billDay'];
  String timeLabel = '';
  if (localStart != null) {
    timeLabel =
        ' · ${DateFormat.Hm().format(localStart)} (${timezoneLabelFrom(rule['timezone']?.toString())})';
  }
  String base = recurringFrequencySummary(
    l,
    rawFrequency: freq,
    interval: intervalValue,
  );
  final monthlyLike = freq == recurringFreqMonthly ||
      freq == recurringFreqBimensual ||
      freq == recurringFreqTrimestral;
  if (billDay != null && (monthlyLike || freq == recurringFreqWeekly)) {
    base = '$base · ${l.recurringBillDaySummary(billDay.toString())}';
  }
  return '$base$startLabel$timeLabel';
}
Future<String?> showTimezonePicker({
  required BuildContext context,
  required String initial,
}) async {
  final options = availableTimezones();
  String query = '';
  final controller = TextEditingController(text: initial);
  final l = AppLocalizations.of(context)!;

  return showDialog<String>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          final filtered = options.where((tzName) {
            if (query.isEmpty) return true;
            return tzName.toLowerCase().contains(query.toLowerCase());
          }).take(200);

          return AlertDialog(
            title: Text(l.recurringInvoicesTimezoneLabel),
            content: SizedBox(
              width: 420,
              height: 420,
              child: Column(
                children: [
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: l.recurringInvoicesTimezoneSearchHint,
                    ),
                    onChanged: (value) {
                      setState(() => query = value.trim());
                    },
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      children: filtered
                          .map(
                            (tzName) => ListTile(
                              title: Text(tzName),
                              onTap: () => Navigator.of(context).pop(tzName),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: Text(l.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(controller.text),
                child: Text(l.recurringInvoicesTimezoneUseCta),
              ),
            ],
          );
        },
      );
    },
  );
}

