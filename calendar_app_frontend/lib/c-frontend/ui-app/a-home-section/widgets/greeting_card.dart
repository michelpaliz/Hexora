// lib/c-frontend/home/widgets/greeting_card.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/a-models/weather/day_summary.dart';
import 'package:hexora/c-frontend/utils/weather/weather_greeting_card.dart';

class GreetingCard extends StatelessWidget {
  final User user;
  final DaySummary daySummary;
  final double tempMax;
  final double tempMin;

  const GreetingCard({
    super.key,
    required this.user,
    required this.daySummary,
    required this.tempMax,
    required this.tempMin,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = (user.name.isNotEmpty ? user.name : user.userName);
    final prettyName = displayName.isEmpty
        ? 'User'
        : displayName[0].toUpperCase() + displayName.substring(1);

    return WeatherGreetingCard(
      userName: prettyName,
      summary: daySummary,
      tempMax: tempMax,
      tempMin: tempMin,
    );
  }
}
