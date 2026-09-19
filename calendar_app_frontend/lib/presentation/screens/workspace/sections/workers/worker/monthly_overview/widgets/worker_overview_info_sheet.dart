import 'package:flutter/material.dart';
import 'package:hexora/presentation/screens/workspace/sections/workers/worker/monthly_overview/widgets/overview_legend_raw.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class WorkerOverviewInfoSheet extends StatelessWidget {
  const WorkerOverviewInfoSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.overviewInfoTitle,
            style: t.titleLarge.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            l.overviewInfoBody,
            style: t.bodyMedium.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 12),
          const OverviewLegendRow(),
          const SizedBox(height: 8),
          Text(
            '• ${l.tipTapMonthToOpen}\n• ${l.tipPullToRefresh}',
            style: t.bodySmall.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
