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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

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
          padding: const EdgeInsets.symmetric(vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.query_stats_rounded,
                  size: 26,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                (l.localeName.startsWith('es'))
                    ? 'Sin datos para este periodo'
                    : 'No data for this period',
                style: tt.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                (l.localeName.startsWith('es'))
                    ? 'Ajusta el rango de fechas para ver resultados.'
                    : 'Adjust the date range to see results.',
                style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );

    // Accent colors for top 3
    final List<Color> rankColors = [
      cs.primary,
      cs.secondary,
      cs.tertiary,
    ];

    final isMobile = MediaQuery.sizeOf(context).width < 700;
    final barHeight = isMobile ? 28.0 : 32.0;
    final barRadius = isMobile ? 7.0 : 9.0;

    List<Widget> buildRows() {
      return List.generate(top.length, (i) {
        final entry = top[i];
        final label = entry.key;
        final minutes = entry.value;
        final factor = maxVal == 0 ? 0.0 : minutes / maxVal;
        final pct = (factor * 100).round();
        final accentColor = i < 3 ? rankColors[i] : cs.primary;
        final isTop = i == 0;

        return Padding(
          padding: EdgeInsets.only(bottom: isMobile ? 8 : 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Rank number
              SizedBox(
                width: isMobile ? 18 : 22,
                child: Text(
                  '${i + 1}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isTop ? FontWeight.w800 : FontWeight.w600,
                    color: isTop
                        ? accentColor
                        : cs.onSurfaceVariant.withValues(alpha: 0.5),
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Bar + label
              Expanded(
                child: Stack(
                  children: [
                    // Track
                    Container(
                      height: barHeight,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(barRadius),
                      ),
                    ),
                    // Fill
                    FractionallySizedBox(
                      widthFactor: factor.clamp(0.04, 1.0),
                      child: Container(
                        height: barHeight,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              accentColor,
                              accentColor.withValues(alpha: 0.65),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(barRadius),
                          boxShadow: isTop
                              ? [
                                  BoxShadow(
                                    color: accentColor.withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  )
                                ]
                              : null,
                        ),
                      ),
                    ),
                    // Label inside bar
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: isMobile ? 11 : 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.95),
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Duration
              SizedBox(
                width: isMobile ? 52 : 60,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      fmt(minutes),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: isMobile ? 11 : 12,
                        fontWeight: FontWeight.w800,
                        color: isTop
                            ? accentColor
                            : cs.onSurface.withValues(alpha: 0.85),
                        height: 1.1,
                      ),
                    ),
                    Text(
                      '$pct%',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.45),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      });
    }

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.28)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final hasBoundedHeight = constraints.maxHeight.isFinite;
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: tt.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                    if (top.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${top.length}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: cs.onPrimaryContainer,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                if (top.isEmpty)
                  emptyState()
                else if (hasBoundedHeight)
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: buildRows(),
                    ),
                  )
                else
                  ...buildRows(),
              ],
            ),
          );
        },
      ),
    );
  }
}
