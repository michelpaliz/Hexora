import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

Future<DateTime?> selectDate(
  BuildContext context,
  bool isStartDate,
  DateTime currentStart,
  DateTime currentEnd,
) async {
  final pickedDate = await showDatePicker(
    context: context,
    initialDate: isStartDate ? currentStart : currentEnd,
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
  );

  if (pickedDate == null) return null;

  final pickedTime = await showTimePicker(
    context: context,
    initialTime: isStartDate
        ? TimeOfDay.fromDateTime(currentStart)
        : TimeOfDay.fromDateTime(currentEnd),
  );

  if (pickedTime == null) return null;

  final combined = DateTime(
    pickedDate.year,
    pickedDate.month,
    pickedDate.day,
    pickedTime.hour,
    pickedTime.minute,
  );

  final formatted = DateFormat('yyyy-MM-dd HH:mm:ss').format(combined);
  return DateFormat('yyyy-MM-dd HH:mm:ss').parse(formatted, true);
}
