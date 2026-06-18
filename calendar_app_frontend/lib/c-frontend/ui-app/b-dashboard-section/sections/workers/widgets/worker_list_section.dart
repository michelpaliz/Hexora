import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/worker/worker.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

// Future-ready per-worker metrics slot.  Pass null for any unknown metric.
// When the API gains per-worker stats, populate this from the parent and
// WorkerListSection will render them automatically.
class WorkerRowMetrics {
  final double? hoursThisMonth;
  final double? pendingPay;
  final String? lastActivityLabel;

  const WorkerRowMetrics({
    this.hoursThisMonth,
    this.pendingPay,
    this.lastActivityLabel,
  });
}

class WorkerListSection extends StatelessWidget {
  const WorkerListSection({
    super.key,
    required this.workers,
    required this.onEdit,
    required this.onAddHours,
    this.onOpenOverview,
    this.onOpenOverviewIcon,
    this.onSelect,
    this.selectedWorkerId,
    this.tapSelects = false,
    this.workerMetrics,
  });

  final List<Worker> workers;
  final void Function(Worker worker) onEdit;
  final void Function(Worker worker) onAddHours;
  final void Function(Worker worker)? onOpenOverview;
  final void Function(Worker worker)? onOpenOverviewIcon;
  final void Function(Worker worker)? onSelect;
  final String? selectedWorkerId;
  final bool tapSelects;
  // Optional per-worker runtime metrics (hours, pending pay, last activity).
  final Map<String, WorkerRowMetrics>? workerMetrics;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: workers
          .map(
            (w) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _WorkerRow(
                worker: w,
                isSelected:
                    selectedWorkerId != null && selectedWorkerId == w.id,
                metrics: workerMetrics?[w.id],
                onTap: () {
                  if (tapSelects && onSelect != null) {
                    onSelect!(w);
                    return;
                  }
                  onAddHours(w);
                },
                onEdit: () => onEdit(w),
                onAddHours: () => onAddHours(w),
                onOpenOverview: () =>
                    (onOpenOverviewIcon ?? onOpenOverview)?.call(w),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _WorkerRow extends StatefulWidget {
  final Worker worker;
  final bool isSelected;
  final WorkerRowMetrics? metrics;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onAddHours;
  final VoidCallback onOpenOverview;

  const _WorkerRow({
    required this.worker,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
    required this.onAddHours,
    required this.onOpenOverview,
    this.metrics,
  });

  @override
  State<_WorkerRow> createState() => _WorkerRowState();
}

class _WorkerRowState extends State<_WorkerRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final isLight = cs.brightness == Brightness.light;

    final w = widget.worker;
    final isSelected = widget.isSelected;

    final isLinked = (w.userId != null && w.userId!.isNotEmpty);
    final name = (w.displayName ?? w.userId ?? l.unknownWorker).trim();
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final role = (w.roleTag ?? '').trim();
    final isInactive = w.status == WorkerStatus.archived;
    final hasRate =
        w.defaultHourlyRate != null && w.defaultHourlyRate! > 0;
    final hasAdvance = w.advanceAmount != null && w.advanceAmount! > 0;
    final hasExternalId =
        (w.externalId ?? '').trim().isNotEmpty && !isLinked;
    final currency = (w.currency ?? 'EUR').trim();
    final hasNotes = (w.notes ?? '').trim().isNotEmpty;

    // Format helpers
    final locale = Localizations.localeOf(context).toString();
    String fmtNum(double v) =>
        NumberFormat('#,##0.##', locale).format(v);

    // Background
    Color rowBg;
    if (isSelected) {
      rowBg = cs.primaryContainer.withValues(alpha: 0.55);
    } else if (_hovered) {
      rowBg = isLight
          ? cs.surfaceContainerHighest.withValues(alpha: 0.55)
          : cs.surfaceContainerHighest.withValues(alpha: 0.35);
    } else {
      rowBg = cs.surface;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: rowBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? cs.primary.withValues(alpha: 0.35)
                : cs.outlineVariant.withValues(alpha: _hovered ? 0.55 : 0.38),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.10),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left selection accent bar
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isSelected ? 3 : 0,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(13),
                      bottomLeft: Radius.circular(13),
                    ),
                  ),
                ),
                // Main row content
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(13),
                    onTap: widget.onTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // ── Avatar ──────────────────────────────────
                          _WorkerAvatar(
                            initials: initials,
                            isSelected: isSelected,
                            isLinked: isLinked,
                            isInactive: isInactive,
                          ),
                          const SizedBox(width: 10),

                          // ── Identity column ──────────────────────────
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Name
                                Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: t.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: isInactive
                                        ? cs.onSurface.withValues(alpha: 0.5)
                                        : cs.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                // Status + role + type
                                Row(
                                  children: [
                                    _WorkerStatusChip(
                                        status: w.status, l: l),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: Text(
                                        _metaLine(l, isLinked, role),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: t.bodySmall.copyWith(
                                          color: cs.onSurfaceVariant,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),

                          // ── Middle metrics strip ──────────────────────
                          // Fills dead space with operational data.
                          // Future: add hoursThisMonth / pendingPay here.
                          if (!isInactive)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (widget.metrics?.hoursThisMonth != null)
                                  _MetricChip(
                                    icon: Icons.schedule_outlined,
                                    label:
                                        '${fmtNum(widget.metrics!.hoursThisMonth!)} h',
                                    color: cs.primary,
                                  ),
                                if (widget.metrics?.hoursThisMonth != null &&
                                    (hasRate || hasAdvance))
                                  const SizedBox(width: 5),
                                if (hasRate)
                                  _MetricChip(
                                    icon: Icons.payments_outlined,
                                    label:
                                        '${fmtNum(w.defaultHourlyRate!)} $currency/h',
                                    color: isLight
                                        ? const Color(0xFF2E7D32)
                                        : const Color(0xFF81C784),
                                  ),
                                if (hasRate && hasAdvance)
                                  const SizedBox(width: 5),
                                if (hasAdvance)
                                  _MetricChip(
                                    icon: Icons.account_balance_wallet_outlined,
                                    label:
                                        'Ant. ${fmtNum(w.advanceAmount!)} $currency',
                                    color: isLight
                                        ? const Color(0xFF5C6BC0)
                                        : const Color(0xFF9FA8DA),
                                  ),
                                if ((hasRate || hasAdvance) && hasExternalId)
                                  const SizedBox(width: 5),
                                if (hasExternalId && !hasRate && !hasAdvance)
                                  _MetricChip(
                                    icon: Icons.badge_outlined,
                                    label: w.externalId!.trim(),
                                    color: cs.onSurfaceVariant,
                                  ),
                                if (hasNotes &&
                                    !hasRate &&
                                    !hasAdvance &&
                                    !hasExternalId)
                                  _NotePreview(notes: w.notes!),
                              ],
                            ),

                          const SizedBox(width: 8),

                          // ── Actions ───────────────────────────────────
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _HoverActionIcon(
                                tooltip: l.addTimeEntryCta,
                                icon: Icons.schedule_outlined,
                                onTap: widget.onAddHours,
                                isPrimary: true,
                              ),
                              const SizedBox(width: 6),
                              _HoverActionIcon(
                                tooltip: l.overviewInfoTitle,
                                icon: Icons.calendar_view_month_outlined,
                                onTap: widget.onOpenOverview,
                              ),
                              const SizedBox(width: 6),
                              _HoverActionIcon(
                                tooltip: l.editWorker,
                                icon: Icons.edit_outlined,
                                onTap: widget.onEdit,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _metaLine(AppLocalizations l, bool isLinked, String role) {
    final typeLabel = isLinked ? l.linkedUser : l.externalWorker;
    return role.isNotEmpty ? '$typeLabel · $role' : typeLabel;
  }
}

// ── Avatar ──────────────────────────────────────────────────────────────────

class _WorkerAvatar extends StatelessWidget {
  final String initials;
  final bool isSelected;
  final bool isLinked;
  final bool isInactive;

  const _WorkerAvatar({
    required this.initials,
    required this.isSelected,
    required this.isLinked,
    required this.isInactive,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);

    final avatarColor = isInactive
        ? cs.onSurfaceVariant.withValues(alpha: 0.14)
        : isSelected
            ? cs.primary.withValues(alpha: 0.22)
            : cs.primary.withValues(alpha: 0.12);

    final textColor = isInactive
        ? cs.onSurfaceVariant.withValues(alpha: 0.5)
        : cs.primary;

    return Stack(
      children: [
        CircleAvatar(
          radius: 17,
          backgroundColor: avatarColor,
          child: Text(
            initials,
            style: t.bodySmall.copyWith(
              fontWeight: FontWeight.w900,
              color: textColor,
              fontSize: 13,
            ),
          ),
        ),
        // Linked user indicator dot
        if (isLinked)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: cs.primary,
                shape: BoxShape.circle,
                border: Border.all(color: cs.surface, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Status chip (scalable — ready for leave/vacation/sick/suspended) ─────────

enum _StatusTone {
  active,
  inactive,
  onLeave,
  vacation,
  sick,
  pendingOnboarding,
  suspended,
}

class _WorkerStatusChip extends StatelessWidget {
  final WorkerStatus status;
  final AppLocalizations l;

  const _WorkerStatusChip({required this.status, required this.l});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final isLight = cs.brightness == Brightness.light;

    final tone = status == WorkerStatus.archived
        ? _StatusTone.inactive
        : _StatusTone.active;

    final Color bg;
    final Color fg;
    final Color border;
    final String label;
    final IconData? icon;

    switch (tone) {
      case _StatusTone.active:
        bg = Colors.green.withValues(alpha: 0.12);
        fg = isLight ? Colors.green.shade700 : Colors.green.shade300;
        border = Colors.green.withValues(alpha: 0.3);
        label = l.statusActive;
        icon = null;
      case _StatusTone.inactive:
        bg = cs.surfaceContainerHighest.withValues(alpha: 0.7);
        fg = cs.onSurface.withValues(alpha: 0.55);
        border = cs.outlineVariant;
        label = l.statusInactive;
        icon = null;
      case _StatusTone.onLeave:
        bg = Colors.orange.withValues(alpha: 0.12);
        fg = isLight ? Colors.orange.shade800 : Colors.orange.shade300;
        border = Colors.orange.withValues(alpha: 0.3);
        label = 'Permiso';
        icon = Icons.beach_access_outlined;
      case _StatusTone.vacation:
        bg = Colors.blue.withValues(alpha: 0.12);
        fg = isLight ? Colors.blue.shade700 : Colors.blue.shade300;
        border = Colors.blue.withValues(alpha: 0.3);
        label = 'Vacaciones';
        icon = Icons.flight_takeoff_outlined;
      case _StatusTone.sick:
        bg = Colors.red.withValues(alpha: 0.09);
        fg = isLight ? Colors.red.shade700 : Colors.red.shade300;
        border = Colors.red.withValues(alpha: 0.28);
        label = 'Baja médica';
        icon = Icons.local_hospital_outlined;
      case _StatusTone.pendingOnboarding:
        bg = Colors.purple.withValues(alpha: 0.1);
        fg = isLight ? Colors.purple.shade700 : Colors.purple.shade300;
        border = Colors.purple.withValues(alpha: 0.28);
        label = 'Pendiente';
        icon = Icons.hourglass_empty_rounded;
      case _StatusTone.suspended:
        bg = Colors.red.withValues(alpha: 0.12);
        fg = isLight ? Colors.red.shade700 : Colors.red.shade300;
        border = Colors.red.withValues(alpha: 0.3);
        label = 'Suspendido';
        icon = Icons.block_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 9, color: fg),
            const SizedBox(width: 2),
          ],
          Text(
            label,
            style: t.bodySmall.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Compact metric chip ──────────────────────────────────────────────────────

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetricChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color.withValues(alpha: 0.75)),
          const SizedBox(width: 4),
          Text(
            label,
            style: t.bodySmall.copyWith(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: color.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Inline notes preview ──────────────────────────────────────────────────────

class _NotePreview extends StatelessWidget {
  final String notes;
  const _NotePreview({required this.notes});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final trimmed = notes.trim();
    final preview = trimmed.length > 38 ? '${trimmed.substring(0, 38)}…' : trimmed;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.notes_rounded,
            size: 10, color: cs.onSurfaceVariant.withValues(alpha: 0.45)),
        const SizedBox(width: 4),
        Text(
          preview,
          style: t.bodySmall.copyWith(
            fontSize: 10.5,
            color: cs.onSurfaceVariant.withValues(alpha: 0.6),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

// ── Hover-aware action icon ───────────────────────────────────────────────────

class _HoverActionIcon extends StatefulWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;

  const _HoverActionIcon({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  State<_HoverActionIcon> createState() => _HoverActionIconState();
}

class _HoverActionIconState extends State<_HoverActionIcon> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final Color bgBase = widget.isPrimary
        ? cs.primary.withValues(alpha: 0.09)
        : cs.surfaceContainerHighest.withValues(alpha: 0.7);

    final Color bgHover = widget.isPrimary
        ? cs.primary.withValues(alpha: 0.18)
        : cs.surfaceContainerHighest;

    final Color borderBase = widget.isPrimary
        ? cs.primary.withValues(alpha: 0.22)
        : cs.outlineVariant.withValues(alpha: 0.4);

    final Color borderHover = widget.isPrimary
        ? cs.primary.withValues(alpha: 0.5)
        : cs.outlineVariant.withValues(alpha: 0.7);

    final Color iconColor = widget.isPrimary
        ? cs.primary.withValues(alpha: _hovered ? 1.0 : 0.7)
        : _hovered
            ? cs.onSurface
            : cs.onSurfaceVariant;

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _hovered ? bgHover : bgBase,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _hovered ? borderHover : borderBase,
              ),
              boxShadow: _hovered && widget.isPrimary
                  ? [
                      BoxShadow(
                        color: cs.primary.withValues(alpha: 0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Icon(widget.icon, size: 15, color: iconColor),
          ),
        ),
      ),
    );
  }
}
