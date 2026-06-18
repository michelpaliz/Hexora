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
  final ValueChanged<Map<String, dynamic>>? onSelect;
  final bool canManage;
  final bool selected;

  const RecurringSeriesCard({
    super.key,
    required this.series,
    required this.clientNamesById,
    required this.onOpen,
    required this.onPreview,
    required this.onPause,
    required this.onResume,
    required this.onCancel,
    this.onSelect,
    required this.canManage,
    this.selected = false,
  });

  @override
  State<RecurringSeriesCard> createState() => _RecurringSeriesCardState();
}

class _RecurringSeriesCardState extends State<RecurringSeriesCard> {
  bool _expanded = false;

  Color _stripeColor(
    String status,
    bool isExpired,
    ColorScheme cs,
    Brightness brightness,
  ) {
    if (isExpired) return cs.error;
    switch (status) {
      case 'paused':
        return cs.tertiary;
      case 'cancelled':
        return cs.error;
      case 'completed':
        return cs.primary;
      default:
        return brightness == Brightness.dark
            ? cs.secondary
            : const Color(0xFF0F766E);
    }
  }

  IconData _statusIcon(String status, bool isExpired) {
    if (isExpired) return Icons.timer_off_outlined;
    switch (status) {
      case 'paused':
        return Icons.pause_circle_outline_rounded;
      case 'cancelled':
        return Icons.cancel_outlined;
      case 'completed':
        return Icons.check_circle_outline_rounded;
      default:
        return Icons.play_circle_outline_rounded;
    }
  }

  IconData _freqIcon(String freq) {
    switch (freq) {
      case 'daily':
        return Icons.wb_sunny_outlined;
      case 'weekly':
        return Icons.view_week_outlined;
      case 'yearly':
        return Icons.celebration_outlined;
      case 'bimensual':
        return Icons.date_range_outlined;
      case 'trimestral':
        return Icons.event_repeat_outlined;
      default:
        return Icons.calendar_month_outlined;
    }
  }

  int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  DateTime? _emissionDateForNextRun(DateTime? executionDate) {
    if (executionDate == null) return null;
    final mode = recurringInvoiceDateModeFrom(widget.series);
    if (mode == 'offset_days') {
      final offset = recurringInvoiceDateOffsetDaysFrom(widget.series) ?? 0;
      return executionDate.add(Duration(days: offset));
    }
    if (mode == 'fixed_day') {
      final requestedDay = recurringInvoiceDateDayFrom(widget.series) ?? 1;
      final day = requestedDay
          .clamp(
            1,
            _daysInMonth(executionDate.year, executionDate.month),
          )
          .toInt();
      return DateTime(
        executionDate.year,
        executionDate.month,
        day,
        executionDate.hour,
        executionDate.minute,
      );
    }
    return executionDate;
  }

  List<String> _conceptsFromSeries(Map<String, dynamic> series) {
    final concepts = <String>[];
    final seen = <String>{};

    void addConcept(dynamic raw) {
      if (raw is! Map) return;
      final map = Map<String, dynamic>.from(raw);
      final type = (map['type'] ?? '').toString().toLowerCase();
      if (type == 'note' ||
          type == 'date' ||
          type == 'section' ||
          type == 'subsection' ||
          type == 'divider') {
        return;
      }
      if (map['isBillable'] == false) return;
      final description = (map['description'] ??
              map['conceptTitle'] ??
              map['title'] ??
              map['name'] ??
              '')
          .toString()
          .trim();
      if (description.isEmpty) return;
      final conceptItems = map['conceptItems'];
      final sku = conceptItems is List && conceptItems.isNotEmpty
          ? conceptItems.map((e) => e.toString()).join(', ')
          : (map['sku'] ?? '').toString().trim();
      final label = sku.isNotEmpty && !description.startsWith('[')
          ? '[$sku] $description'
          : description;
      if (!seen.add(label.toLowerCase())) return;
      concepts.add(label);
    }

    void collect(dynamic raw) {
      if (raw is List) {
        for (final item in raw) {
          addConcept(item);
        }
      } else if (raw is Map) {
        final map = Map<String, dynamic>.from(raw);
        collect(map['lines']);
        collect(map['blocks']);
        collect(map['items']);
        collect(map['draftLines']);
      }
    }

    collect(series['lines']);
    collect(series['blocks']);
    collect(series['template']);
    collect(series['invoiceTemplate']);
    collect(series['payload']);
    return concepts.take(3).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
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

    final stripe = _stripeColor(status, isExpired, cs, theme.brightness);

    final rawTz = (rule is Map ? rule['timezone'] : null) ?? series['timezone'];
    final timezone = rawTz?.toString();
    final nextRunDisplay = nextRun == null
        ? null
        : (nextRun.isUtc ? utcToZoned(nextRun, timezone) : nextRun);
    final nextRunLabel = nextRunDisplay == null
        ? '-'
        : DateFormat.yMMMd(l.localeName).add_Hm().format(nextRunDisplay);
    final issuePolicySummary = recurringIssueDatePolicySummary(series, l);
    final emissionDateDisplay = _emissionDateForNextRun(nextRunDisplay);
    final emissionDateLabel = emissionDateDisplay == null
        ? issuePolicySummary
        : DateFormat.yMMMd(l.localeName).format(emissionDateDisplay);
    final freq = normalizeFrequencyFromApi((series['frequency'] ??
            series['freq'] ??
            rule?['frequency'] ??
            rule?['freq'] ??
            recurringFreqMonthly)
        .toString());
    final freqLabel = recurringFrequencyLabel(l, freq);
    final concepts = _conceptsFromSeries(series);

    final canPause =
        widget.canManage && widget.onPause != null && status == 'active';
    final canResume =
        widget.canManage && widget.onResume != null && status == 'paused';
    final canCancel = widget.canManage &&
        widget.onCancel != null &&
        (status == 'active' || status == 'paused');

    return Card(
      elevation: 0,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: widget.selected
              ? cs.primary.withValues(alpha: 0.7)
              : _expanded
                  ? stripe.withValues(alpha: 0.45)
                  : cs.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          widget.onSelect?.call(series);
          setState(() => _expanded = !_expanded);
        },
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Left status stripe ────────────────────────────────────
              Container(
                width: 4,
                color: stripe.withValues(alpha: _expanded ? 1.0 : 0.55),
              ),

              // ── Main content ──────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Collapsed header row ──────────────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Frequency icon box
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: stripe.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _freqIcon(freq),
                              size: 18,
                              color: stripe,
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Client name + frequency label
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  clientName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: t.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (freqLabel.isNotEmpty ||
                                    nextRunDisplay != null)
                                  Row(
                                    children: [
                                      if (freqLabel.isNotEmpty)
                                        Flexible(
                                          child: Text(
                                            freqLabel,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: t.bodySmall.copyWith(
                                              color: cs.onSurfaceVariant,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      if (freqLabel.isNotEmpty &&
                                          nextRunDisplay != null) ...[
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                          ),
                                          child: Text(
                                            '·',
                                            style: t.bodySmall.copyWith(
                                              color: cs.onSurfaceVariant
                                                  .withValues(alpha: 0.7),
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                      if (nextRunDisplay != null) ...[
                                        Icon(
                                          Icons.event_available_outlined,
                                          size: 12,
                                          color: stripe,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            nextRunLabel,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: t.bodySmall.copyWith(
                                              color: cs.onSurfaceVariant,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 10.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: _TinyDateMeta(
                                          icon: Icons.receipt_long_outlined,
                                          label: 'Emision',
                                          value: emissionDateLabel,
                                          color: cs.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),

                          // Amount badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest
                                  .withValues(alpha: 0.6),
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
                          const SizedBox(width: 6),

                          // Status pill
                          _StatusPill(
                            label: statusLabel,
                            icon: _statusIcon(status, isExpired),
                            color: stripe,
                          ),

                          // Edit button
                          if (widget.canManage) ...[
                            const SizedBox(width: 4),
                            Tooltip(
                              message: l.edit,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () => widget.onOpen(series),
                                child: Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: Icon(
                                    Icons.edit_outlined,
                                    size: 16,
                                    color: cs.onSurfaceVariant
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(width: 2),

                          // Expand chevron
                          AnimatedRotation(
                            duration: const Duration(milliseconds: 200),
                            turns: _expanded ? 0.5 : 0,
                            child: Icon(
                              Icons.expand_more,
                              size: 18,
                              color:
                                  cs.onSurfaceVariant.withValues(alpha: 0.55),
                            ),
                          ),
                        ],
                      ),

                      // ── Expanded details ──────────────────────────────
                      if (concepts.isNotEmpty) ...[
                        const SizedBox(height: 7),
                        Wrap(
                          spacing: 6,
                          runSpacing: 5,
                          children: [
                            for (final concept in concepts)
                              _ConceptChip(label: concept),
                          ],
                        ),
                      ],
                      AnimatedCrossFade(
                        duration: const Duration(milliseconds: 200),
                        sizeCurve: Curves.easeInOut,
                        crossFadeState: _expanded
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        firstChild: const SizedBox.shrink(),
                        secondChild: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Divider(
                                height: 1,
                                color:
                                    cs.outlineVariant.withValues(alpha: 0.35),
                              ),
                              const SizedBox(height: 10),
                              // Meta row
                              Row(
                                children: [
                                  Expanded(
                                    child: _MetaInline(
                                      icon: Icons.loop_rounded,
                                      iconColor: stripe,
                                      label: l.recurringInvoicesFrequencyLabel,
                                      value: schedule,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _MetaInline(
                                      icon: Icons.event_available_outlined,
                                      iconColor: nextRunDisplay == null
                                          ? cs.onSurfaceVariant
                                          : stripe,
                                      label: l.recurringInvoicesNextRunLabel,
                                      value: nextRunLabel,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _MetaInline(
                                      icon: Icons.receipt_long_outlined,
                                      iconColor: cs.onSurfaceVariant,
                                      label: 'Fecha factura',
                                      value: issuePolicySummary,
                                    ),
                                  ),
                                ],
                              ),

                              // Quick actions
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  // Preview
                                  _ActionChip(
                                    icon: Icons.calendar_view_month_outlined,
                                    label: l.recurringInvoicesPreviewCta,
                                    onTap: () => widget.onPreview(series),
                                    color: stripe,
                                  ),
                                  if (canPause)
                                    _ActionChip(
                                      icon: Icons.pause_circle_outline_rounded,
                                      label: l.recurringInvoicesPauseCta,
                                      onTap: () => widget.onPause!(series),
                                      color: cs.tertiary,
                                    ),
                                  if (canResume)
                                    _ActionChip(
                                      icon: Icons.play_circle_outline_rounded,
                                      label: l.recurringInvoicesResumeCta,
                                      onTap: () => widget.onResume!(series),
                                      color: cs.secondary,
                                    ),
                                  if (canCancel)
                                    _ActionChip(
                                      icon: Icons.cancel_outlined,
                                      label: l.recurringInvoicesCancelCta,
                                      onTap: () => widget.onCancel!(series),
                                      color: cs.error,
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
            ],
          ),
        ),
      ),
    );
  }
}

// ── Status pill ────────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _StatusPill({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: t.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action chip ────────────────────────────────────────────────────────────────

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: t.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Meta inline ────────────────────────────────────────────────────────────────

class _ConceptChip extends StatelessWidget {
  final String label;

  const _ConceptChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.subject_rounded,
            size: 12,
            color: cs.onSurfaceVariant.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.bodySmall.copyWith(
                fontSize: 10,
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyDateMeta extends StatelessWidget {
  const _TinyDateMeta({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            '$label $value',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.bodySmall.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              fontSize: 10.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _MetaInline extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _MetaInline({
    required this.icon,
    required this.iconColor,
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
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 14, color: iconColor),
        ),
        const SizedBox(width: 5),
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
                maxLines: 2,
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
