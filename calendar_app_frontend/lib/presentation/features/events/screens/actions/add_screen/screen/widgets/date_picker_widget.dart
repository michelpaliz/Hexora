import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DatePickersWidget extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final VoidCallback onStartDateTap;
  final VoidCallback onEndDateTap;

  const DatePickersWidget({
    Key? key,
    required this.startDate,
    required this.endDate,
    required this.onStartDateTap,
    required this.onEndDateTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd – HH:mm');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Start Date & Time'),
        const SizedBox(height: 4),
        InkWell(
          onTap: onStartDateTap,
          child: InputDecorator(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(12),
            ),
            child: Text(dateFormat.format(startDate)),
          ),
        ),
        const SizedBox(height: 12),
        const Text('End Date & Time'),
        const SizedBox(height: 4),
        InkWell(
          onTap: onEndDateTap,
          child: InputDecorator(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(12),
            ),
            child: Text(dateFormat.format(endDate)),
          ),
        ),
      ],
    );
  }
}
