import 'package:flutter/material.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

import '../statements_controller.dart';
import '../statements_formatters.dart';

/// Compact, derived view of a batch's real freshness status
/// (`controller.batchStatus[id]`). This is the actual status returned by the
/// backend — not inferred from skipped/omitted counts.
class FreshnessView {
  const FreshnessView({
    required this.shortLabel,
    required this.fullLabel,
    required this.color,
    required this.icon,
    required this.pending,
    required this.hasData,
  });

  /// Compact badge text, e.g. "Al día" / "Desactualizado".
  final String shortLabel;

  /// Full sentence for tooltips/details, e.g. "Al día (18/11/2026)".
  final String fullLabel;
  final Color color;
  final IconData icon;

  /// The status is still being fetched.
  final bool pending;

  /// A status payload exists (vs. not yet loaded / errored / empty).
  final bool hasData;
}

FreshnessView resolveFreshnessView(
  BuildContext context,
  StatementsController controller,
  String id,
) {
  final l = AppLocalizations.of(context)!;
  final cs = Theme.of(context).colorScheme;
  final es = Localizations.localeOf(context).languageCode == 'es';

  final status = controller.batchStatus[id];
  final loading = controller.loadingStatus[id] == true;
  final err = controller.statusError[id];

  if (loading && status == null) {
    return FreshnessView(
      shortLabel: es ? 'Cargando…' : 'Loading…',
      fullLabel: l.statementsFreshnessLoading,
      color: cs.onSurfaceVariant,
      icon: Icons.hourglass_empty_rounded,
      pending: true,
      hasData: false,
    );
  }
  if (status == null || err != null) {
    return FreshnessView(
      shortLabel: '—',
      fullLabel: err ?? (es ? 'Sin estado' : 'No status'),
      color: cs.onSurfaceVariant,
      icon: Icons.remove_rounded,
      pending: false,
      hasData: false,
    );
  }

  final isStale = status['stale'] == true;
  final lastDate = status['lastDate'];
  final daysSince = status['daysSince'];
  final hasLastDate = lastDate != null && lastDate.toString().isNotEmpty;
  final lastDateLabel =
      hasLastDate ? StatementsFormatters.formatDate(context, lastDate) : '';
  final daysLabel = daysSince == null
      ? ''
      : StatementsFormatters.formatCount(context, daysSince);

  if (!hasLastDate) {
    return FreshnessView(
      shortLabel: es ? 'Sin datos' : 'No data',
      fullLabel: l.statementsFreshnessNoData,
      color: cs.onSurfaceVariant,
      icon: Icons.help_outline_rounded,
      pending: false,
      hasData: true,
    );
  }
  if (isStale) {
    return FreshnessView(
      shortLabel: es ? 'Desactualizado' : 'Outdated',
      fullLabel: l.statementsFreshnessStale(lastDateLabel, daysLabel),
      color: cs.error,
      icon: Icons.warning_amber_outlined,
      pending: false,
      hasData: true,
    );
  }
  return FreshnessView(
    shortLabel: es ? 'Al día' : 'Up to date',
    fullLabel: l.statementsFreshnessUpToDate(lastDateLabel),
    color: cs.primary,
    icon: Icons.check_circle_outline,
    pending: false,
    hasData: true,
  );
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon ?? Icons.verified_outlined, size: 12, color: color),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.caption.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MetaItem extends StatelessWidget {
  const MetaItem({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.valueTooltip,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? valueTooltip;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final valueText = Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: t.bodySmall.copyWith(
        color: cs.onSurface,
        fontWeight: FontWeight.w600,
      ),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 13, color: cs.onSurfaceVariant),
        const SizedBox(width: 5),
        Expanded(
          child: Row(
            children: [
              Text(
                label,
                style: t.caption.copyWith(
                  color: cs.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: valueTooltip == null
                    ? valueText
                    : Tooltip(message: valueTooltip!, child: valueText),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class TechLine extends StatelessWidget {
  const TechLine({
    super.key,
    required this.label,
    required this.value,
    required this.onCopy,
  });

  final String label;
  final String value;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$label: $value',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.bodySmall.copyWith(
                color: cs.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: AppLocalizations.of(context)!.statementsCopy,
            icon: const Icon(Icons.copy, size: 13),
            onPressed: onCopy,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
