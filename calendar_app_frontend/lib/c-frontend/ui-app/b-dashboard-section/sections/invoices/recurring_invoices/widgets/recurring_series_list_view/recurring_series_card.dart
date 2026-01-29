import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/utils/recurrence_time_utils.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/utils/recurring_invoices_helpers.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class RecurringSeriesCard extends StatelessWidget {
  final Map<String, dynamic> series;
  final Map<String, String> clientNamesById;
  final ValueChanged<Map<String, dynamic>> onOpen;
  final ValueChanged<Map<String, dynamic>> onPreview;
  final ValueChanged<Map<String, dynamic>>? onPause;
  final ValueChanged<Map<String, dynamic>>? onResume;
  final ValueChanged<Map<String, dynamic>>? onCancel;
  final bool canManage;

  const RecurringSeriesCard({
    super.key,
    required this.series,
    required this.clientNamesById,
    required this.onOpen,
    required this.onPreview,
    required this.onPause,
    required this.onResume,
    required this.onCancel,
    required this.canManage,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final status = (series['status'] ?? 'active').toString().toLowerCase();
    final nextRun = parseDate(series['nextRunAt']);
    final total = seriesTotal(context, series);
    final rule = series['rule'];
    final schedule = ruleSummary(rule is Map ? rule : series, l);
    final rawClientId =
        series['clientId'] ?? series['client']?['id'] ?? series['client']?['_id'];
    final clientId = rawClientId is Map
        ? (rawClientId[r'$oid'] ?? '').toString()
        : rawClientId?.toString();
    final clientName = (series['clientName'] ??
            series['client']?['name'] ??
            (clientId == null ? null : clientNamesById[clientId]) ??
            '-')
        .toString();
    final ruleName = (series['name'] ?? '').toString();

    final endDate = parseDate(
      (rule is Map ? rule['endDate'] : null) ?? series['endDate'],
    );
    final isExpired = status == 'active' &&
        endDate != null &&
        endDate.isBefore(DateTime.now());
    final statusLabel = isExpired
        ? l.expired
        : status == 'paused'
            ? l.recurringInvoicesStatusPaused
            : status == 'cancelled'
                ? l.recurringInvoicesStatusCancelled
                : status == 'completed'
                    ? l.recurringInvoicesStatusCompleted
                    : l.recurringInvoicesStatusActive;
    final statusColor = isExpired
        ? cs.errorContainer
        : status == 'paused'
            ? cs.tertiaryContainer
            : status == 'cancelled'
                ? cs.errorContainer
                : status == 'completed'
                    ? cs.primaryContainer
                    : cs.secondaryContainer;
    final statusText = isExpired
        ? cs.onErrorContainer
        : status == 'paused'
            ? cs.onTertiaryContainer
            : status == 'cancelled'
                ? cs.onErrorContainer
                : status == 'completed'
                    ? cs.onPrimaryContainer
                    : cs.onSecondaryContainer;
    final nextRunLabel = nextRun == null
        ? l.recurringInvoicesNextRunLabel
        : DateFormat.yMMMd(l.localeName).add_Hm().format(nextRun);
    final compactButtonStyle = ButtonStyle(
      visualDensity: VisualDensity.compact,
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      minimumSize: WidgetStateProperty.all(const Size(0, 32)),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: WidgetStateProperty.all(
        t.bodySmall.copyWith(fontWeight: FontWeight.w700),
      ),
    );

    return Card(
      elevation: 0,
      color: cs.surfaceContainerHighest.withValues(alpha: 0.7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: cs.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onOpen(series),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${l.clientLabel}: $clientName',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: t.bodyMedium.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (ruleName.trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              ruleName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t.bodySmall.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest
                              .withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          total,
                          style: t.bodyMedium.copyWith(
                            fontWeight: FontWeight.w900,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      _MetaChip(
                        label: statusLabel,
                        background: statusColor,
                        foreground: statusText,
                        icon: Icons.verified_rounded,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _MetaColumn(
                      icon: Icons.repeat_rounded,
                      label: l.recurringInvoicesFrequencyLabel,
                      value: schedule,
                      emphasized: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetaColumn(
                      icon: Icons.event_outlined,
                      label: l.recurringInvoicesNextRunLabel,
                      value: nextRun == null ? '-' : nextRunLabel,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () => onPreview(series),
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(l.recurringInvoicesPreviewCta),
                    style: compactButtonStyle,
                  ),
                  if (status == 'active' && canManage)
                    OutlinedButton.icon(
                      onPressed: onPause == null ? null : () => onPause!(series),
                      icon: const Icon(Icons.pause_circle_outline),
                      label: Text(l.recurringInvoicesPauseCta),
                      style: compactButtonStyle,
                    )
                  else if (status == 'paused' && canManage)
                    OutlinedButton.icon(
                      onPressed:
                          onResume == null ? null : () => onResume!(series),
                      icon: const Icon(Icons.play_circle_outline),
                      label: Text(l.recurringInvoicesResumeCta),
                      style: compactButtonStyle,
                    ),
                  if (canManage)
                    TextButton.icon(
                      onPressed: onCancel == null ? null : () => onCancel!(series),
                      icon: const Icon(Icons.cancel_outlined),
                      label: Text(l.recurringInvoicesCancelCta),
                      style: TextButton.styleFrom(
                        foregroundColor: cs.error,
                      ).merge(compactButtonStyle),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final IconData icon;

  const _MetaChip({
    required this.label,
    required this.background,
    required this.foreground,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.bodySmall.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaColumn extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool emphasized;

  const _MetaColumn({
    required this.icon,
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: emphasized ? 18 : 16,
          color: emphasized ? cs.onSurface : cs.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.bodySmall.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: emphasized ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: (emphasized ? t.bodyMedium : t.bodySmall).copyWith(
                  color: cs.onSurface,
                  fontWeight: emphasized ? FontWeight.w800 : FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
