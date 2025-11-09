// lib/c-frontend/c-group-calendar-section/screens/calendar/no_calendar_screen.dart
import 'package:flutter/material.dart';

class NoCalendarScreen extends StatelessWidget {
  const NoCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'No calendar found',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
