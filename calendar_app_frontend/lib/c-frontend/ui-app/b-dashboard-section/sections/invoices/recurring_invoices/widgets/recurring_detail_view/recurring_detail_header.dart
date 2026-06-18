import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/widgets/series_status_pill.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class RecurringDetailHeader extends StatelessWidget {
  final String title;
  final String status;
  final bool showStatusPill;
  final VoidCallback? onBack;
  final String? backTooltip;
  final String? infoTooltip;
  final String recurrenceLabel;
  final String nextRunLabel;
  final String previewLabel;
  final VoidCallback onPreview;
  final bool canManage;
  final bool showActionRow;

  const RecurringDetailHeader({
    super.key,
    required this.title,
    required this.status,
    this.showStatusPill = true,
    this.onBack,
    this.backTooltip,
    this.infoTooltip,
    required this.recurrenceLabel,
    required this.nextRunLabel,
    required this.previewLabel,
    required this.onPreview,
    required this.canManage,
    this.showActionRow = true,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    ButtonStyle compactTonal = FilledButton.styleFrom(
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      textStyle: const TextStyle(fontSize: 12),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (onBack != null)
              IconButton(
                tooltip: backTooltip,
                onPressed: onBack,
                iconSize: 20,
                icon: const Icon(Icons.arrow_back),
              ),
            if (showStatusPill) SeriesStatusPill(status: status),
          ],
        ),
        if (title.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.24),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.28),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.person_outline_rounded,
                    size: 16, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  '${l.clientLabel}:',
                  style: t.bodySmall.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodyMedium.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (showActionRow) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              FilledButton.tonalIcon(
                onPressed: onPreview,
                icon: const Icon(Icons.calendar_today_outlined, size: 16),
                label: Text(previewLabel),
                style: compactTonal,
              ),
            ],
          ),
        ],
      ],
    );
  }
}
