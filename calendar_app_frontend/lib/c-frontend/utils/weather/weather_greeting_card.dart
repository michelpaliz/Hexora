import 'package:flutter/material.dart';
import 'package:hexora/a-models/weather/day_summary.dart';
import 'package:hexora/c-frontend/utils/weather/weather_forecast_list.dart';
import 'package:hexora/c-frontend/utils/weather/weather_service.dart';
import 'package:hexora/c-frontend/utils/weather/weather_summary_localizer.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
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
  });

  String _localizedSummary(AppLocalizations l) {
    return localizeWeatherSummary(l, summary.summary);
  }

  String _buildMainLine(AppLocalizations l) {
    return l.weatherGreeting(
      summary.emoji,
      userName,
      _localizedSummary(l),
    );
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

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.surface,
            cs.surfaceContainerHighest.withValues(alpha: 0.25),
          ],
        ),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: emoji + greeting + temp badge + location
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(summary.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _buildMainLine(l),
                      style: t.bodySmall.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: cs.onSurface,
                      ),
                      maxLines: 1,
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
                          Icon(Icons.location_on_outlined, size: 13, color: cs.onSurfaceVariant),
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
          const SizedBox(height: 4),
          Text(
            _buildFunLine(l),
            style: t.bodySmall.copyWith(
              color: cs.onSurfaceVariant,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
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
