import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/utils/weather/weather_service.dart';
import 'package:hexora/c-frontend/utils/weather/weather_summary_localizer.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class WeatherForecastList extends StatelessWidget {
  final List<WeatherForecastDayView> days;
  final bool isLoading;
  final String? errorMessage;

  const WeatherForecastList({
    super.key,
    required this.days,
    required this.isLoading,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final l = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const SizedBox(
                    height: 12,
                    width: 12,
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l.weatherForecastLoading,
                    style: t.bodySmall.copyWith(color: cs.onSurfaceVariant, fontSize: 11),
                  ),
                ],
              ),
            )
          else if ((errorMessage ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                errorMessage!,
                style: t.bodySmall.copyWith(color: cs.error, fontSize: 11),
              ),
            )
          else if (days.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                l.weatherForecastEmpty,
                style: t.bodySmall.copyWith(color: cs.onSurfaceVariant, fontSize: 11),
              ),
            )
          else
            Column(
              children: [
                for (int i = 0; i < days.take(3).length; i++) ...[
                  if (i > 0)
                    Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.15)),
                  _WeatherForecastRow(day: days[i]),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _WeatherForecastRow extends StatelessWidget {
  final WeatherForecastDayView day;

  const _WeatherForecastRow({required this.day});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final l = AppLocalizations.of(context)!;
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final label = DateFormat('EEE dd', localeTag).format(day.date);
    final range = '${day.maxTemp.toStringAsFixed(0)}°/${day.minTemp.toStringAsFixed(0)}°';
    final rain = '${day.rainProbability.toStringAsFixed(0)}% ${l.weatherForecastRainShort}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(day.emoji, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 6),
          SizedBox(
            width: 52,
            child: Text(
              label,
              style: t.bodySmall.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: Text(
              localizeWeatherSummary(l, day.summary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.bodySmall.copyWith(
                color: cs.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.water_drop_outlined, size: 11, color: cs.onSurfaceVariant),
          const SizedBox(width: 2),
          Text(
            rain,
            style: t.bodySmall.copyWith(
              color: cs.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            range,
            style: t.bodySmall.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
