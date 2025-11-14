import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DatePickerRow extends StatelessWidget {
  final DateTime selectedStartDate;
  final DateTime selectedEndDate;
  final Function(bool, DateTime) onDateSelected;
  final Future<DateTime?> Function(BuildContext, bool) selectDateFn;

  const DatePickerRow({
    Key? key,
    required this.selectedStartDate,
    required this.selectedEndDate,
    required this.onDateSelected,
    required this.selectDateFn,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
          color: Colors.blue, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSinglePicker(context, true, selectedStartDate),
          const SizedBox(width: 10),
          _buildSinglePicker(context, false, selectedEndDate),
        ],
      ),
    );
  }

  Widget _buildSinglePicker(BuildContext context, bool isStart, DateTime date) {
    return Flexible(
      flex: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: isStart ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(5.0),
            ),
            child: Text(
              isStart ? "Start Date" : "End Date",
              style: const TextStyle(fontSize: 15, color: Colors.black),
            ),
          ),
          const SizedBox(height: 8.0),
          InkWell(
            onTap: () async {
              DateTime? newDate = await selectDateFn(context, isStart);
              if (newDate != null) onDateSelected(isStart, newDate);
            },
            child: Column(
              children: [
                Text(DateFormat('yyyy-MM-dd').format(date),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.white)),
                Text(DateFormat('hh:mm a').format(date),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color.fromARGB(255, 28, 58, 82))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
