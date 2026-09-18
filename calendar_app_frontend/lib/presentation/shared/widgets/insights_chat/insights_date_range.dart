class InsightsDateRange {
  const InsightsDateRange({
    required this.from,
    required this.inclusiveTo,
  });

  final DateTime from;
  final DateTime inclusiveTo;

  DateTime get normalizedFrom => DateTime(from.year, from.month, from.day);
  DateTime get normalizedInclusiveTo =>
      DateTime(inclusiveTo.year, inclusiveTo.month, inclusiveTo.day);

  Map<String, dynamic> toApiJson() {
    final exclusiveTo = normalizedInclusiveTo.add(const Duration(days: 1));
    return <String, dynamic>{
      'dateFrom': formatInsightsApiDate(normalizedFrom),
      'dateTo': formatInsightsApiDate(exclusiveTo),
    };
  }

  String label({required bool isEs}) {
    final start = formatInsightsUiDate(normalizedFrom, isEs: isEs);
    final end = formatInsightsUiDate(normalizedInclusiveTo, isEs: isEs);
    return start == end ? start : '$start - $end';
  }

  bool sameRange(InsightsDateRange? other) {
    if (other == null) return false;
    return normalizedFrom == other.normalizedFrom &&
        normalizedInclusiveTo == other.normalizedInclusiveTo;
  }
}
String twoDigitInsights(int value) => value.toString().padLeft(2, '0');

String formatInsightsApiDate(DateTime date) {
  return '${date.year}-${twoDigitInsights(date.month)}-${twoDigitInsights(date.day)}';
}

String formatInsightsUiDate(DateTime date, {required bool isEs}) {
  const esMonths = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sept',
    'oct',
    'nov',
    'dic',
  ];
  const enMonths = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sept',
    'Oct',
    'Nov',
    'Dec',
  ];
  final months = isEs ? esMonths : enMonths;
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

InsightsDateRange insightsRangeForPreset(String preset) {
  final today = DateTime.now();
  final current = DateTime(today.year, today.month, today.day);
  switch (preset) {
    case 'today':
      return InsightsDateRange(from: current, inclusiveTo: current);
    case 'week':
      final start = current.subtract(Duration(days: current.weekday - 1));
      return InsightsDateRange(
        from: start,
        inclusiveTo: start.add(const Duration(days: 6)),
      );
    case 'lastMonth':
      final start = DateTime(current.year, current.month - 1);
      return InsightsDateRange(
        from: start,
        inclusiveTo: DateTime(current.year, current.month, 0),
      );
    case 'month':
    default:
      final start = DateTime(current.year, current.month);
      return InsightsDateRange(
        from: start,
        inclusiveTo: DateTime(current.year, current.month + 1, 0),
      );
  }
}
