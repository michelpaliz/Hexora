import 'package:flutter/material.dart';
import 'package:hexora/a-models/weather/day_summary.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class WeatherGreetingCard extends StatelessWidget {
  final String userName;
  final DaySummary summary;
  final double tempMax;
  final double tempMin;
  final String? location;

  const WeatherGreetingCard({
    super.key,
    required this.userName,
    required this.summary,
    required this.tempMax,
    required this.tempMin,
    this.location,
  });

  String _localizedSummary(AppLocalizations l) {
    return switch (summary.summary) {
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final t = AppTypography.of(context);
    final l = AppLocalizations.of(context)!;
    final locationText = _locationText();

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.surface,
            cs.surfaceVariant.withOpacity(0.3),
          ],
        ),
        border: Border.all(
          color: cs.outlineVariant.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            summary.emoji,
            style: const TextStyle(fontSize: 36),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _buildMainLine(l),
                  style: t.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _buildTempLine(l),
                  style: t.bodyMedium.copyWith(
                    color: cs.onSurfaceVariant.withOpacity(0.8),
                  ),
                ),
                if (locationText != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: cs.onSurfaceVariant,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          locationText,
                          style: t.bodyMedium.copyWith(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  _buildFunLine(l),
                  style: t.bodySmall.copyWith(
                    color: cs.onSurfaceVariant.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
