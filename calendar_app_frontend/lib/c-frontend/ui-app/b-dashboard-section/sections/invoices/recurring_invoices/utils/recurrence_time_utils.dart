import 'package:flutter/material.dart';
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

String utcTimeString(
  DateTime date,
  TimeOfDay time, [
  String? timezone,
]) =>
    DateFormat('HH:mm').format(utcDateTime(date, time, timezone));

DateTime utcToZoned(DateTime utc, String? timezone) {
  final location = tryGetLocation(timezone);
  if (location != null) {
    return tz.TZDateTime.from(utc, location);
  }
  return utc.toLocal();
}

String ruleSummary(Map? rule, AppLocalizations l) {
  if (rule == null) return l.recurringRuleEmpty;
  final freq = (rule['freq'] ?? rule['frequency'] ?? 'monthly').toString();
  final interval = (rule['interval'] ?? 1).toString();
  final start = parseDate(rule['startDate']);
  final timeOfDay = rule['timeOfDay']?.toString();
  DateTime? localStart;
  if (start != null && timeOfDay != null && timeOfDay.isNotEmpty) {
    final parts = timeOfDay.split(':');
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '0');
    if (hour != null && minute != null) {
      final utcStart = DateTime.utc(
        start.year,
        start.month,
        start.day,
        hour,
        minute,
      );
      localStart = utcToZoned(utcStart, rule['timezone']?.toString());
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
  String base;
  switch (freq) {
    case 'daily':
      base = interval == '1'
          ? l.recurringFrequencyDaily
          : l.recurringEveryDays(interval);
      break;
    case 'weekly':
      base = interval == '1'
          ? l.recurringFrequencyWeekly
          : l.recurringEveryWeeks(interval);
      if (billDay != null) {
        base = '$base · ${l.recurringBillDaySummary(billDay.toString())}';
      }
      break;
    case 'yearly':
      base = interval == '1'
          ? l.recurringFrequencyYearly
          : l.recurringEveryYears(interval);
      break;
    default:
      base = interval == '1'
          ? l.recurringFrequencyMonthly
          : l.recurringEveryMonths(interval);
      if (billDay != null) {
        base = '$base · ${l.recurringBillDaySummary(billDay.toString())}';
      }
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
