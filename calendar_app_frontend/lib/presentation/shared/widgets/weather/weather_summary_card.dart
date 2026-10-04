import 'package:flutter/material.dart';
import 'package:hexora/services/weather/weather_service.dart';
import 'package:hexora/presentation/shared/utils/weather/weather_summary_localizer.dart';
import 'package:hexora/l10n/app_localizations.dart';

class WeatherSummaryCard extends StatefulWidget {
  const WeatherSummaryCard({super.key, required this.location});
  final String? location;

  @override
  State<WeatherSummaryCard> createState() => _WeatherSummaryCardState();
}

class _WeatherSummaryCardState extends State<WeatherSummaryCard> {
  final _service = WeatherService();
  late Future<WeatherBundle> _weather;
  String get _location => widget.location?.trim().isNotEmpty == true
      ? widget.location!.trim()
      : 'Denia';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _weather = _service.fetchWeatherBundle(location: _location, days: 1);
  }

  @override
  void didUpdateWidget(covariant WeatherSummaryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location) _load();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final es = l.localeName.startsWith('es');
    return FutureBuilder<WeatherBundle>(
      future: _weather,
      builder: (context, snapshot) {
        final weather = snapshot.data?.today;
        final loading = snapshot.connectionState == ConnectionState.waiting;
        return Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              Icon(
                  weather == null
                      ? Icons.cloud_outlined
                      : weather.isDay
                          ? Icons.wb_sunny_outlined
                          : Icons.nightlight_outlined,
                  color: cs.primary),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(
                        '${es ? 'Tiempo' : 'Weather'} · ${weather?.cityName ?? _location}',
                        style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 3),
                    Text(
                        loading
                            ? (es ? 'Cargando previsión…' : 'Loading forecast…')
                            : weather == null
                                ? (es
                                    ? 'Previsión no disponible'
                                    : 'Forecast unavailable')
                                : '${localizeWeatherSummary(l, weather.summary.summary)} · ${l.weatherTempLine(weather.tempMax.toStringAsFixed(0), weather.tempMin.toStringAsFixed(0))}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant)),
                  ])),
              if (loading)
                const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
              else
                IconButton(
                    tooltip: l.refresh,
                    onPressed: () => setState(_load),
                    icon: const Icon(Icons.refresh, size: 20)),
            ]),
          ),
        );
      },
    );
  }
}
