import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:flutter/material.dart';

class CustomMergedCell extends StatelessWidget {
  final List<DateTime> mergedDates;
  final List<Event> events;

  CustomMergedCell({required this.mergedDates, required this.events});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue, // Background color for the merged cell
        border: Border.all(color: Colors.black),
      ),
      child: Column(
        children: [
          for (var date in mergedDates)
            Text(
              date.day.toString(),
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          for (var event in events)
            Text(
              event.title,
              style: TextStyle(fontSize: 12, color: Colors.white),
            ),
        ],
      ),
    );
  }
}
