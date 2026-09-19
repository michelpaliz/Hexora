import 'package:flutter/material.dart';
import 'package:hexora/models/weather/work_condition_result.dart';
import 'package:hexora/presentation/utils/weather/work_conditions_api.dart';
import 'package:intl/intl.dart';

class WorkConditionsCard extends StatefulWidget {
  const WorkConditionsCard({super.key, required this.groupId});

  final String groupId;

  @override
  State<WorkConditionsCard> createState() => _WorkConditionsCardState();
}

class _WorkConditionsCardState extends State<WorkConditionsCard> {
  final _api = WorkConditionsApi();
  WorkConditionResult? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant WorkConditionsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupId != widget.groupId) _load();
  }

  Future<void> _load() async {
    final requestedGroupId = widget.groupId;
    setState(() {
      _error = null;
      _result = null;
    });
    try {
      final result = await _api.today(requestedGroupId);
      if (mounted && widget.groupId == requestedGroupId) {
        setState(() => _result = result);
      }
    } catch (error) {
      if (mounted && widget.groupId == requestedGroupId) {
        setState(() => _error = error.toString());
      }
    }
  }

  String _reason(String value, bool es) => switch (value) {
        'rain' => es ? 'lluvia' : 'rain',
        'highWind' => es ? 'viento fuerte' : 'high wind',
        'highTemperature' => es ? 'temperatura alta' : 'high temperature',
        'lowTemperature' => es ? 'temperatura baja' : 'low temperature',
        _ => value,
      };

  void _showAffected(WorkConditionResult result) {
    final es = Localizations.localeOf(context).languageCode == 'es';
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text(es ? 'Trabajos afectados' : 'Affected jobs',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            for (final visit in result.affectedVisits)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.warning_amber_rounded),
                title: Text(
                  '${DateFormat.Hm().format(visit.startDate.toLocal())} — ${visit.title}',
                ),
                subtitle: Text(
                  '${visit.clientName}\n'
                  '🌧 ${visit.rainProbability.toStringAsFixed(0)}% · '
                  '💨 ${visit.windSpeed.toStringAsFixed(0)} km/h · '
                  '🌡 ${visit.temperature.toStringAsFixed(0)}°C\n'
                  '${visit.reasons.map((reason) => _reason(reason, es)).join(', ')}',
                ),
                isThreeLine: true,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final es = Localizations.localeOf(context).languageCode == 'es';
    final cs = Theme.of(context).colorScheme;
    if (_error != null) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.cloud_off_outlined),
          title: Text(es ? 'Condiciones de trabajo' : 'Work conditions'),
          subtitle: Text(es
              ? 'El análisis meteorológico no está disponible.'
              : 'Weather analysis is unavailable.'),
          trailing:
              IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ),
      );
    }
    final result = _result;
    if (result == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final caution = result.rating != 'good';
    final color = caution ? cs.error : Colors.green.shade700;
    final rating = switch (result.rating) {
      'poor' => es ? 'Atención requerida' : 'Attention required',
      'caution' => es ? 'Precaución' : 'Caution',
      _ => es ? 'Buenas' : 'Good',
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(
                  caution
                      ? Icons.warning_amber_rounded
                      : Icons.wb_sunny_rounded,
                  color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  es
                      ? 'Hoy · Condiciones de trabajo'
                      : 'Today · Work conditions',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Text(rating,
                  style: TextStyle(color: color, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 10),
            Text(es
                ? '${result.outdoorVisitCount} trabajos exteriores hoy'
                : '${result.outdoorVisitCount} outdoor jobs today'),
            const SizedBox(height: 6),
            Text(
              result.affectedVisitCount == 0
                  ? (es
                      ? '✓ No se espera un impacto meteorológico significativo'
                      : '✓ No significant weather impact expected')
                  : (es
                      ? '⚠ ${result.affectedVisitCount} trabajos pueden verse afectados por ${result.reasons.map((r) => _reason(r, es)).join(', ')}'
                      : '⚠ ${result.affectedVisitCount} jobs may be affected by ${result.reasons.map((r) => _reason(r, es)).join(', ')}'),
              style: TextStyle(color: caution ? color : cs.onSurfaceVariant),
            ),
            if (result.unavailableLocationCount > 0) ...[
              const SizedBox(height: 6),
              Text(
                es
                    ? 'Análisis no disponible para ${result.unavailableLocationCount} trabajos: ubicación sin geocodificar.'
                    : 'Analysis unavailable for ${result.unavailableLocationCount} jobs: location not geocoded.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (result.affectedVisitCount > 0) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => _showAffected(result),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(es
                    ? 'Ver ${result.affectedVisitCount} trabajos afectados'
                    : 'View ${result.affectedVisitCount} affected jobs'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
