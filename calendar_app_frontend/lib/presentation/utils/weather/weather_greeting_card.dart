import 'package:flutter/material.dart';
import 'package:hexora/models/weather/day_summary.dart';
import 'package:hexora/presentation/utils/weather/weather_forecast_list.dart';
import 'package:hexora/presentation/utils/weather/weather_service.dart';
import 'package:hexora/presentation/utils/weather/weather_summary_localizer.dart';
import 'package:hexora/theme/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class WeatherGreetingCard extends StatelessWidget {
  final String userName;
  final DaySummary summary;
  final double tempMax;
  final double tempMin;
  final String? location;
  final List<WeatherForecastDayView> forecastDays;
  final bool isForecastLoading;
  final String? forecastError;
  final bool isDay;
  final DateTime? sunrise;
  final DateTime? sunset;

  /// When false the top greeting row and fun-fact chip are hidden.
  /// Use in wide layouts where a separate hero greeting is already shown.
  final bool showGreeting;

  const WeatherGreetingCard({
    super.key,
    required this.userName,
    required this.summary,
    required this.tempMax,
    required this.tempMin,
    this.location,
    this.forecastDays = const [],
    this.isForecastLoading = false,
    this.forecastError,
    this.isDay = true,
    this.sunrise,
    this.sunset,
    this.showGreeting = true,
  });

  String _localizedSummary(AppLocalizations l) {
    return localizeWeatherSummary(l, summary.summary);
  }

  String _buildMainLine(AppLocalizations l) {
    return l.weatherGreeting(
      _weatherEmoji(),
      userName,
      _localizedSummary(l),
    );
  }

  String _weatherEmoji() {
    if (isDay) return summary.emoji;
    final condition = summary.summary.toLowerCase();
    if (condition.contains('sun') ||
        condition.contains('clear') ||
        condition.contains('pleasant')) {
      return '🌙';
    }
    return summary.emoji;
  }

  String? _solarTimesLabel(BuildContext context, {required bool isEs}) {
    if (sunrise == null || sunset == null) return null;
    final material = MaterialLocalizations.of(context);
    final use24Hour = MediaQuery.alwaysUse24HourFormatOf(context);
    final sunriseTime = material.formatTimeOfDay(
      TimeOfDay.fromDateTime(sunrise!),
      alwaysUse24HourFormat: use24Hour,
    );
    final sunsetTime = material.formatTimeOfDay(
      TimeOfDay.fromDateTime(sunset!),
      alwaysUse24HourFormat: use24Hour,
    );
    return isEs
        ? 'Amanecer $sunriseTime · Atardecer $sunsetTime'
        : 'Sunrise $sunriseTime · Sunset $sunsetTime';
  }

  String _buildTempLine(AppLocalizations l) {
    final max = tempMax.toStringAsFixed(0);
    final min = tempMin.toStringAsFixed(0);

    return l.weatherTempLine(max, min);
  }

  String? _locationText() {
    final clean = location?.trim();
    if (clean == null || clean.isEmpty) return null;
    return clean;
  }

  String _buildFunLine(AppLocalizations l) {
    if (summary.isTooHot) {
      return l.weatherFunTooHot;
    }
    if (summary.isTooCold) {
      return l.weatherFunTooCold;
    }

    switch (summary.grade) {
      case 'A':
        return l.weatherFunGradeA;
      case 'B':
        return l.weatherFunGradeB;
      case 'C':
        return l.weatherFunGradeC;
      case 'D':
        return l.weatherFunGradeD;
      default:
        return l.weatherFunDefault;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final l = AppLocalizations.of(context)!;
    final locationText = _locationText();
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final daylightLabel =
        isDay ? (isEs ? 'Día' : 'Day') : (isEs ? 'Noche' : 'Night');
    final daylightIcon =
        isDay ? Icons.wb_sunny_rounded : Icons.nightlight_round;
    final solarTimesLabel = _solarTimesLabel(context, isEs: isEs);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDay
                ? cs.surface
                : Color.alphaBlend(
                    cs.primary.withValues(alpha: 0.10),
                    cs.surface,
                  ),
            isDay
                ? cs.surfaceContainerHighest.withValues(alpha: 0.25)
                : Color.alphaBlend(
                    cs.tertiary.withValues(alpha: 0.14),
                    cs.surfaceContainerHighest,
                  ),
          ],
        ),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showGreeting) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(daylightIcon, size: 14, color: cs.primary),
                const SizedBox(width: 4),
                Text(
                  daylightLabel,
                  style: t.bodySmall.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Top row: emoji + greeting + temp + location
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(_weatherEmoji(), style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _buildMainLine(l),
                        style: t.bodySmall.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: cs.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            _buildTempLine(l),
                            style: t.bodySmall.copyWith(
                              color: cs.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                          if (locationText != null) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.location_on_outlined,
                                size: 13, color: cs.onSurfaceVariant),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                locationText,
                                style: t.bodySmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: cs.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (solarTimesLabel != null) ...[
              Row(
                children: [
                  Icon(Icons.wb_twilight_rounded,
                      size: 13, color: cs.onSurfaceVariant),
                  const SizedBox(width: 5),
                  Text(
                    solarTimesLabel,
                    style: t.bodySmall.copyWith(
                      color: cs.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _buildFunLine(l),
                style: t.bodySmall.copyWith(
                  color: cs.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ] else ...[
            // Compact header: emoji + condition + temp + location (no name)
            Row(
              children: [
                Text(_weatherEmoji(), style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _buildTempLine(l),
                    style: t.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                if (locationText != null) ...[
                  Icon(Icons.location_on_outlined,
                      size: 13, color: cs.onSurfaceVariant),
                  const SizedBox(width: 3),
                  Text(
                    locationText,
                    style: t.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                Icon(daylightIcon, size: 15, color: cs.primary),
                const SizedBox(width: 3),
                Text(
                  daylightLabel,
                  style: t.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (solarTimesLabel != null) ...[
              Text(
                solarTimesLabel,
                style: t.bodySmall.copyWith(
                  color: cs.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _buildFunLine(l),
                style: t.bodySmall.copyWith(
                  color: cs.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          WeatherForecastList(
            days: forecastDays,
            isLoading: isForecastLoading,
            errorMessage: forecastError,
          ),
        ],
      ),
    );
  }
}
