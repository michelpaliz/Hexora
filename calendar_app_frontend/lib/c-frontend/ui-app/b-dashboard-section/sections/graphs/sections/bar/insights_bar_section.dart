import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';

class InsightsBarsCard extends StatelessWidget {
  final String title;
  final Map<String, int> minutesByKey;

  const InsightsBarsCard({
    super.key,
    required this.title,
    required this.minutesByKey,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final entries = minutesByKey.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(10).toList();
    final maxVal = top.isEmpty ? 0 : top.map((e) => e.value).reduce(math.max);

    String fmt(int minutes) {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      if (h == 0) return '${m}m';
      if (m == 0) return '${h}h';
      return '${h}h ${m}m';
    }

    Widget emptyState() => Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              Icon(Icons.query_stats_rounded,
                  size: 64, color: cs.onSurfaceVariant.withOpacity(.6)),
              const SizedBox(height: 10),
              Text(
                // You can localize this pair later if you prefer
                (l.localeName.startsWith('es'))
                    ? 'No hay datos para este periodo'
                    : 'No data for this period',
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                (l.localeName.startsWith('es'))
                    ? 'Ajusta el rango o activa la búsqueda por rango en el servidor.'
                    : 'Adjust the range or enable server-side range queries.',
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
            ],
          ),
        );

    return Card(
      elevation: 0,
      color: cs.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            if (top.isEmpty)
              emptyState()
            else
              ...top.map((e) {
                final label =
                    e.key; // map ID -> display name upstream if available
                final minutes = e.value;
                final factor = maxVal == 0 ? 0.0 : minutes / maxVal;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              height: 28,
                              decoration: BoxDecoration(
                                color: cs.onSurface.withOpacity(.06),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: factor.clamp(0.0, 1.0),
                              child: Container(
                                height: 28,
                                decoration: BoxDecoration(
                                  color: cs.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: tt.bodyMedium?.copyWith(
                                      color: cs.onPrimary.withOpacity(.95),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 64,
                        child: Text(fmt(minutes),
                            textAlign: TextAlign.right, style: tt.bodyMedium),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
