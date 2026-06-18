import 'package:intl/intl.dart';

/// Safe accessor for all optional event-related keys inside [NotificationUser.args].
///
/// Every getter returns null (never throws) when a key is absent, empty, or invalid.
/// Add new backend fields here as the contract evolves — the rest of the UI just
/// conditionally renders when the getter is non-null.
class EventArgsHelper {
  const EventArgsHelper(this.args);

  final Map<String, dynamic> args;

  // ── Core identifiers ───────────────────────────────────────────────────────
  String? get eventTitle        => _str('eventTitle');
  String? get eventId           => _str('eventId');

  // ── Scheduling ─────────────────────────────────────────────────────────────
  DateTime? get startDate       => _date('startDate');
  DateTime? get endDate         => _date('endDate');
  bool?     get allDay          => _bool('allDay');
  int?      get reminderTime    => _int('reminderTime'); // minutes before start

  // ── Status / classification ────────────────────────────────────────────────
  String?   get status          => _str('status');     // pending|confirmed|cancelled|completed
  String?   get eventType       => _str('eventType');  // work_visit|meeting|appointment|…
  String?   get action          => _str('action');     // created|updated|deleted|reminder|started|…
  bool?     get isDone          => _bool('isDone');

  // ── Ownership / context ────────────────────────────────────────────────────
  String?   get groupId         => _str('groupId');
  String?   get ownerId         => _str('ownerId');
  String?   get ownerName       => _str('ownerName');
  bool?     get notifyOwner     => _bool('notifyOwner');
  String?   get senderName      => _str('senderName');
  String?   get senderId        => _str('senderId');

  /// Name of the user who created the event.
  /// Reads common creator-name fields first, then falls back to `ownerName` / `senderName`.
  /// Returns null when none of the fields are present in args.
  String?   get createdByName   =>
      _str('createdByName') ??
      _str('creatorName') ??
      _str('createdByUserName') ??
      _str('createdByUsername') ??
      _str('createdBy') ??
      _str('ownerName') ??
      _str('senderName');

  // ── Classification ─────────────────────────────────────────────────────────
  String?   get categoryId      => _str('categoryId');
  String?   get subcategoryId   => _str('subcategoryId');
  String?   get recurrenceRuleId => _str('recurrenceRuleId');

  // ── Content ────────────────────────────────────────────────────────────────
  String?   get location        => _str('location');
  String?   get localization    => _str('localization');
  String?   get description     => _str('description');
  String?   get note            => _str('note');

  // ── Work-visit specific ────────────────────────────────────────────────────
  String?   get clientId        => _str('clientId');
  String?   get clientName      => _str('clientName');
  String?   get primaryServiceId => _str('primaryServiceId');
  String?   get stopId          => _str('stopId');

  // ── Grouping / legacy ──────────────────────────────────────────────────────
  String?   get groupName       => _str('groupName');

  // ── Formatted helpers ──────────────────────────────────────────────────────

  /// "Fri, Mar 7 · 09:00 AM" or null when startDate is absent/invalid.
  String? formattedStartDate(String locale) => _fmtDate(startDate, locale);

  /// "Fri, Mar 7 · 11:00 AM" or null when endDate is absent/invalid.
  String? formattedEndDate(String locale) => _fmtDate(endDate, locale);

  /// "15 min before" / "15 min antes" or null when reminderTime is absent.
  String? formattedReminderTime({required bool isEs}) {
    final mins = reminderTime;
    if (mins == null) return null;
    return isEs ? '$mins min antes' : '$mins min before';
  }

  /// Human-readable relative time. Future → "in 10 min"; past → "5 min ago".
  /// Returns null when [startDate] is absent.
  String? relativeTime({
    required String Function(int) inMin,
    required String Function(int) inHours,
    required String Function(int) agoMin,
    required String Function(int) agoHours,
    String Function(int)? agoDays,
    String Function(int)? inDays,
  }) {
    final d = startDate;
    if (d == null) return null;
    final now = DateTime.now();
    final diff = d.difference(now);
    if (diff.isNegative) {
      final ago = now.difference(d);
      if (ago.inMinutes < 60) return agoMin(ago.inMinutes.clamp(1, 999));
      if (ago.inDays < 1) return agoHours(ago.inHours.clamp(1, 23));
      if (agoDays != null) return agoDays(ago.inDays.clamp(1, 999));
      return agoHours(ago.inHours.clamp(1, 999));
    } else {
      if (diff.inMinutes < 60) return inMin(diff.inMinutes.clamp(1, 999));
      if (diff.inDays < 1) return inHours(diff.inHours.clamp(1, 23));
      if (inDays != null) return inDays(diff.inDays.clamp(1, 999));
      return inHours(diff.inHours.clamp(1, 999));
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  String? _str(String key) {
    final v = args[key];
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  DateTime? _date(String key) {
    final raw = args[key];
    if (raw == null) return null;
    try {
      return DateTime.parse(raw.toString());
    } catch (_) {
      return null;
    }
  }

  bool? _bool(String key) {
    final v = args[key];
    if (v == null) return null;
    if (v is bool) return v;
    final s = v.toString().toLowerCase();
    if (s == 'true') return true;
    if (s == 'false') return false;
    return null;
  }

  int? _int(String key) {
    final v = args[key];
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  String? _fmtDate(DateTime? d, String locale) {
    if (d == null) return null;
    try {
      return DateFormat('EEE, MMM d · hh:mm a', locale).format(d.toLocal());
    } catch (_) {
      return null;
    }
  }
}
