// Defines the weather day summary model and mapper utilities.

class DaySummary {
  final String summary; // e.g. "Sunny"
  final String emoji; // e.g. "🌞"
  final String grade; // e.g. "A", "B", "C", "D"
  final bool isTooHot;
  final bool isTooCold;

  const DaySummary({
    required this.summary,
    required this.emoji,
    required this.grade,
    required this.isTooHot,
    required this.isTooCold,
  });
}

DaySummary mapToDaySummary({
  required int weatherCode,
  required double precip,
  required double tempMax,
  required double tempMin,
}) {
  const hotThreshold = 30.0; // >= 30°C -> too hot
  const coldThreshold = 5.0; // <= 5°C -> too cold

  final bool isTooHot = tempMax >= hotThreshold;
  final bool isTooCold = tempMax <= coldThreshold || tempMin <= 0;

  String summary;
  String emoji;
  String grade;

  if (weatherCode == 0 || weatherCode == 1) {
    summary = 'Sunny';
    emoji = '🌞';
    grade = 'A';
  } else if (weatherCode == 2 || weatherCode == 3) {
    if (precip < 1.0) {
      summary = 'Partly cloudy';
      emoji = '⛅';
      grade = 'B';
    } else {
      summary = 'Cloudy with rain';
      emoji = '🌦️';
      grade = 'C';
    }
  } else if ((weatherCode >= 51 && weatherCode <= 67) ||
      (weatherCode >= 80 && weatherCode <= 82)) {
    if (precip < 5.0) {
      summary = 'Light rain';
      emoji = '🌦️';
      grade = 'C';
    } else {
      summary = 'Heavy rain';
      emoji = '🌧️';
      grade = 'D';
    }
  } else if ((weatherCode >= 71 && weatherCode <= 77) ||
      (weatherCode >= 95 && weatherCode <= 99)) {
    summary = 'Stormy';
    emoji = '⛈️';
    grade = 'D';
  } else {
    summary = 'Cloudy';
    emoji = '☁️';
    grade = 'B';
  }

  if (isTooHot || isTooCold) {
    if (grade == 'A') {
      grade = 'B';
    } else if (grade == 'B') {
      grade = 'C';
    } else if (grade == 'C') {
      grade = 'D';
    }
  }

  return DaySummary(
    summary: summary,
    emoji: emoji,
    grade: grade,
    isTooHot: isTooHot,
    isTooCold: isTooCold,
  );
}
