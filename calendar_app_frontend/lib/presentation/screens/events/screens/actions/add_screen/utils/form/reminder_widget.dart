/// Utilities and UI widget for choosing an event reminder time.
///
/// The **reminderTime** is stored as an **int** representing **minutes before
/// the event starts**.
///
/// * Default  : 10 minutes ([`kDefaultReminderMinutes`]).
/// * Maximum  : 4 320 minutes → **3 days** ([`kMaxReminderMinutes`]).
///
/// A couple of helper functions and a reusable **`ReminderTimeField`** form
/// widget are provided so you can add or edit the *reminder* in any screen.
/// ---------------------------------------------------------------------------
/// Usage example inside a `Form`:
/// ```dart
/// int? _reminder;
/// ...
/// ReminderTimeField(
///   initialValue: _reminder,
///   onSaved: (val) => _reminder = val,
/// ),
/// ```
/// ---------------------------------------------------------------------------
/// Author: PROJECT_AI_YOLO ✨
/// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';

// ────────────────────────────────────────────────────────────────────────────
// Constants & helpers
// ────────────────────────────────────────────────────────────────────────────

/// Default reminder in **minutes** (10 min).
const int kDefaultReminderMinutes = 10;

/// Maximum reminder in **minutes** (3 days).
const int kMaxReminderMinutes = 3 * 24 * 60; // 4 320

/// Clamp [minutes] so that `0 ≤ minutes ≤ kMaxReminderMinutes`.
int clampReminder(int? minutes) {
  if (minutes == null) return kDefaultReminderMinutes;
  return minutes.clamp(0, kMaxReminderMinutes);
}

/// Pretty‑prints a minutes value, e.g. `125` → "2 h 5 min".
String formatReminder(int minutes) {
  if (minutes <= 0) return 'At time of event';
  final d = minutes ~/ (24 * 60);
  final h = (minutes % (24 * 60)) ~/ 60;
  final m = minutes % 60;
  final parts = <String>[];
  if (d > 0) parts.add('${d}d');
  if (h > 0) parts.add('${h}h');
  if (m > 0) parts.add('${m}min');
  return parts.join(' ');
}

// ────────────────────────────────────────────────────────────────────────────
// Form Field widget
// ────────────────────────────────────────────────────────────────────────────

/// A simple [`FormField<int>`] that lets the user pick a reminder time in
/// minutes with validation against [kMaxReminderMinutes].
class ReminderTimeField extends FormField<int> {
  ReminderTimeField({
    Key? key,
    int? initialValue,
    FormFieldSetter<int>? onSaved,
    FormFieldValidator<int>? validator,
    AutovalidateMode autovalidateMode = AutovalidateMode.disabled,
    bool enabled = true,
    InputDecoration decoration = const InputDecoration(
      labelText: 'Reminder',
      prefixIcon: Icon(Icons.alarm),
    ),
  }) : super(
          key: key,
          initialValue: clampReminder(initialValue),
          onSaved: onSaved,
          validator: (val) {
            final v = val ?? kDefaultReminderMinutes;
            if (v < 0) return 'Cannot be negative';
            if (v > kMaxReminderMinutes) {
              return 'Cannot exceed 3 days (4 320 min)';
            }
            return validator?.call(v);
          },
          autovalidateMode: autovalidateMode,
          enabled: enabled,
          builder: (state) {
            return TextField(
              keyboardType: TextInputType.number,
              enabled: enabled,
              decoration: decoration.copyWith(
                errorText: state.errorText,
                helperText: '0 = at start, max 4 320',
              ),
              controller: TextEditingController(
                text: state.value?.toString() ?? '',
              ),
              onChanged: (txt) {
                final parsed = int.tryParse(txt) ?? kDefaultReminderMinutes;
                state.didChange(clampReminder(parsed));
              },
            );
          },
        );
}
