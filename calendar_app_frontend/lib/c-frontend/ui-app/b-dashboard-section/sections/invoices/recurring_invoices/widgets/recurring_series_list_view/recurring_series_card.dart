import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/utils/recurrence_time_utils.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/utils/recurrence_frequency.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/utils/recurring_invoices_helpers.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class RecurringSeriesCard extends StatefulWidget {
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
  State<RecurringSeriesCard> createState() => _RecurringSeriesCardState();
}

class _RecurringSeriesCardState extends State<RecurringSeriesCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final series = widget.series;
    final status = (series['status'] ?? 'active').toString().toLowerCase();
    final nextRun = parseDate(series['nextRunAt']);
    final total = seriesTotal(context, series);
    final rule = series['rule'];
    final schedule = ruleSummary(rule is Map ? rule : series, l);
    final rawClientId = series['clientId'] ??
        series['client']?['id'] ??
        series['client']?['_id'];
    final clientId = rawClientId is Map
        ? (rawClientId[r'$oid'] ?? '').toString()
        : rawClientId?.toString();
    final clientName = (series['clientName'] ??
            series['client']?['name'] ??
            (clientId == null ? null : widget.clientNamesById[clientId]) ??
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
    final rawTz = (rule is Map ? rule['timezone'] : null) ?? series['timezone'];
    final timezone = rawTz?.toString();
    final nextRunDisplay = nextRun == null
        ? null
        : (nextRun.isUtc ? utcToZoned(nextRun, timezone) : nextRun);
    final nextRunLabel = nextRunDisplay == null
        ? l.recurringInvoicesNextRunLabel
        : DateFormat.yMMMd(l.localeName).add_Hm().format(nextRunDisplay);
    final issuePolicySummary = recurringIssueDatePolicySummary(series, l);
    final freq = normalizeFrequencyFromApi((series['frequency'] ??
            series['freq'] ??
            rule?['frequency'] ??
            rule?['freq'] ??
            recurringFreqMonthly)
        .toString());
    final freqLabel = recurringFrequencyLabel(l, freq);
    final compactButtonStyle = ButtonStyle(
      visualDensity: VisualDensity.compact,
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      minimumSize: WidgetStateProperty.all(const Size(0, 28)),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: WidgetStateProperty.all(
        t.bodySmall.copyWith(fontWeight: FontWeight.w700),
      ),
    );

    return Card(
      elevation: 0,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: _expanded
              ? cs.primary.withValues(alpha: 0.5)
              : cs.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Collapsed header: always visible ---
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            clientName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.bodyMedium.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (ruleName.trim().isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            flex: 0,
                            child: Text(
                              freqLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t.bodySmall.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      total,
                      style: t.bodySmall.copyWith(
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  _MetaChip(
                    label: statusLabel,
                    background: statusColor,
                    foreground: statusText,
                    icon: Icons.verified_rounded,
                    iconOnly: true,
                  ),
                  if (widget.canManage) ...[
                    const SizedBox(width: 4),
                    Tooltip(
                      message: l.edit,
                      child: OutlinedButton(
                        onPressed: () => widget.onOpen(series),
                        style: compactButtonStyle.copyWith(
                          padding: WidgetStateProperty.all(
                            const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                          ),
                          minimumSize: WidgetStateProperty.all(
                            const Size(30, 28),
                          ),
                        ),
                        child: const Icon(Icons.edit_outlined, size: 16),
                      ),
                    ),
                  ],
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: _expanded ? 0.5 : 0,
                    child: Icon(
                      Icons.expand_more,
                      size: 18,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              // --- Expanded details ---
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 200),
                sizeCurve: Curves.easeInOut,
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _MetaInline(
                              icon: Icons.repeat_rounded,
                              label: l.recurringInvoicesFrequencyLabel,
                              value: schedule,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MetaInline(
                              icon: Icons.event_outlined,
                              label: l.recurringInvoicesNextRunLabel,
                              value: nextRunDisplay == null ? '-' : nextRunLabel,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MetaInline(
                              icon: Icons.event_note_outlined,
                              label: 'Fecha factura',
                              value: issuePolicySummary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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
  final bool iconOnly;

  const _MetaChip({
    required this.label,
    required this.background,
    required this.foreground,
    required this.icon,
    this.iconOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          if (!iconOnly) ...[
            const SizedBox(width: 4),
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
        ],
      ),
    );
    if (!iconOnly) return chip;
    return Tooltip(message: label, child: chip);
  }
}

class _MetaInline extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetaInline({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: cs.onSurfaceVariant),
        const SizedBox(width: 4),
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
                  fontSize: 10,
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.bodySmall.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

