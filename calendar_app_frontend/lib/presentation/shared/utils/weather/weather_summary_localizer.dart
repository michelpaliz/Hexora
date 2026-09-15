import 'package:hexora/l10n/app_localizations.dart';

String localizeWeatherSummary(AppLocalizations l, String summary) {
  return switch (summary) {
    'Sunny' => l.weatherSummarySunny,
    'Partly cloudy' => l.weatherSummaryPartlyCloudy,
    'Cloudy with rain' => l.weatherSummaryCloudyWithRain,
    'Light rain' => l.weatherSummaryLightRain,
    'Heavy rain' => l.weatherSummaryHeavyRain,
    'Stormy' => l.weatherSummaryStormy,
    'Cloudy' => l.weatherSummaryCloudy,
    _ => l.weatherSummaryDefault,
  };
}
