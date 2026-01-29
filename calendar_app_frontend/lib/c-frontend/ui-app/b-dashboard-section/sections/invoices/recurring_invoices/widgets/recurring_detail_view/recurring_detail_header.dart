import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/widgets/series_status_pill.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';

class RecurringDetailHeader extends StatelessWidget {
  final String title;
  final String status;
  final VoidCallback onBack;
  final String? backTooltip;
  final String recurrenceLabel;
  final String nextRunLabel;
  final String previewLabel;
  final VoidCallback onPreview;
  final bool canManage;
  final VoidCallback? onTogglePause;
  final IconData? pauseResumeIcon;
  final String? pauseResumeLabel;
  final VoidCallback? onCancel;
  final String? cancelLabel;
  final VoidCallback? onRunNow;
  final String? runNowLabel;

  const RecurringDetailHeader({
    super.key,
    required this.title,
    required this.status,
    required this.onBack,
    this.backTooltip,
    required this.recurrenceLabel,
    required this.nextRunLabel,
    required this.previewLabel,
    required this.onPreview,
    required this.canManage,
    this.onTogglePause,
    this.pauseResumeIcon,
    this.pauseResumeLabel,
    this.onCancel,
    this.cancelLabel,
    this.onRunNow,
    this.runNowLabel,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    Widget infoChip({required IconData icon, required String label}) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: cs.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: t.bodySmall.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: backTooltip,
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
            ),
            Expanded(
              child: Text(
                title,
                style: t.titleLarge.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            SeriesStatusPill(status: status),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            infoChip(icon: Icons.repeat_outlined, label: recurrenceLabel),
            infoChip(icon: Icons.event_outlined, label: nextRunLabel),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              onPressed: onPreview,
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(previewLabel),
            ),
            if (canManage && onTogglePause != null)
              FilledButton.tonalIcon(
                onPressed: onTogglePause,
                icon: Icon(pauseResumeIcon ?? Icons.pause_circle_outline),
                label: Text(pauseResumeLabel ?? ''),
              ),
            if (canManage && onCancel != null)
              FilledButton.tonalIcon(
                onPressed: onCancel,
                icon: const Icon(Icons.cancel_outlined),
                label: Text(cancelLabel ?? ''),
                style: FilledButton.styleFrom(
                  foregroundColor: cs.error,
                  backgroundColor: cs.errorContainer,
                ),
              ),
            if (canManage && onRunNow != null)
              FilledButton.tonalIcon(
                onPressed: onRunNow,
                icon: const Icon(Icons.play_arrow_outlined),
                label: Text(runNowLabel ?? ''),
              ),
          ],
        ),
      ],
    );
  }
}
