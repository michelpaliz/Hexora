import 'package:hexora/l10n/app_localizations.dart';

const String recurringFreqDaily = 'daily';
const String recurringFreqWeekly = 'weekly';
const String recurringFreqMonthly = 'monthly';
const String recurringFreqBimensual = 'bimensual';
const String recurringFreqTrimestral = 'trimestral';
const String recurringFreqYearly = 'yearly';

// Legacy typo accepted by backend on read, but never written by frontend.
const String recurringFreqTrimestalLegacy = 'trimestal';

const List<String> recurringFrequencyDropdownOrder = <String>[
  recurringFreqDaily,
  recurringFreqWeekly,
  recurringFreqMonthly,
  recurringFreqBimensual,
  recurringFreqTrimestral,
  recurringFreqYearly,
];

String normalizeFrequencyFromApi(String? raw) {
  final value = (raw ?? '').trim().toLowerCase();
  if (value == recurringFreqTrimestalLegacy) {
    return recurringFreqTrimestral;
  }
  if (recurringFrequencyDropdownOrder.contains(value)) {
    return value;
  }
  return recurringFreqMonthly;
}

String canonicalFrequencyForApi(String? raw) {
  return normalizeFrequencyFromApi(raw);
}

String recurringFrequencyLabel(
  AppLocalizations l,
  String? raw,
) {
  final freq = normalizeFrequencyFromApi(raw);
  switch (freq) {
    case recurringFreqDaily:
      return l.recurringFrequencyDaily;
    case recurringFreqWeekly:
      return l.recurringFrequencyWeekly;
    case recurringFreqMonthly:
      return l.recurringFrequencyMonthly;
    case recurringFreqYearly:
      return l.recurringFrequencyYearly;
    case recurringFreqBimensual:
      return l.localeName.toLowerCase().startsWith('es')
          ? 'Bimensual'
          : 'Bimonthly';
    case recurringFreqTrimestral:
      return l.localeName.toLowerCase().startsWith('es')
          ? 'Trimestral'
          : 'Quarterly';
    default:
      return freq;
  }
}

String recurringFrequencySummary(
  AppLocalizations l, {
  required String? rawFrequency,
  required int interval,
}) {
  final isEs = l.localeName.toLowerCase().startsWith('es');
  final freq = normalizeFrequencyFromApi(rawFrequency);
  final n = interval < 1 ? 1 : interval;

  switch (freq) {
    case recurringFreqDaily:
      return n == 1 ? l.recurringFrequencyDaily : l.recurringEveryDays('$n');
    case recurringFreqWeekly:
      return n == 1 ? l.recurringFrequencyWeekly : l.recurringEveryWeeks('$n');
    case recurringFreqMonthly:
      return n == 1
          ? l.recurringFrequencyMonthly
          : l.recurringEveryMonths('$n');
    case recurringFreqYearly:
      return n == 1 ? l.recurringFrequencyYearly : l.recurringEveryYears('$n');
    case recurringFreqBimensual:
      if (isEs) return 'Cada $n ${n == 1 ? 'bimestre' : 'bimestres'}';
      return 'Every $n ${n == 1 ? 'bimonth' : 'bimonths'}';
    case recurringFreqTrimestral:
      if (isEs) return 'Cada $n ${n == 1 ? 'trimestre' : 'trimestres'}';
      return 'Every $n ${n == 1 ? 'quarter' : 'quarters'}';
    default:
      return n == 1
          ? l.recurringFrequencyMonthly
          : l.recurringEveryMonths('$n');
  }
}

