import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/client/client_api.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/service/service_api_client.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

import 'widgets/detail_utils.dart';
import 'package:provider/provider.dart';

typedef ClientNameFetcher = Future<String?> Function(String id);
typedef ServiceNameFetcher = Future<String?> Function(String id);

class EventDetailScreen extends StatefulWidget {
  final Event event;
  final ClientNameFetcher? fetchClientName;
  final ServiceNameFetcher? fetchServiceName;
  final VoidCallback? onEdit;
  final VoidCallback? onDuplicate;
  final VoidCallback? onShare;
  final VoidCallback? onDelete;

  const EventDetailScreen({
    super.key,
    required this.event,
    this.fetchClientName,
    this.fetchServiceName,
    this.onEdit,
    this.onDuplicate,
    this.onShare,
    this.onDelete,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  String? _clientName;
  String? _primaryServiceName;
  bool _loadingClient = false;
  bool _loadingService = false;
  bool _loadingOwner = false;
  String? _ownerDisplayName;
  String? _ownerUsername;
  final Map<String, String> _serviceNames = {};
  bool _loadingServices = false;

  @override
  void initState() {
    super.initState();
    _loadNamesIfNeeded();
  }

  Future<void> _loadNamesIfNeeded() async {
    final e = widget.event;

    _loadOwnerName();

    if ((e.clientId?.isNotEmpty ?? false)) {
      setState(() => _loadingClient = true);
      try {
        String? name;
        if (widget.fetchClientName != null) {
          name = await widget.fetchClientName!(e.clientId!);
        } else {
          try {
            final c = await ClientsApi().getById(e.clientId!);
            name = c.name;
          } catch (_) {}
        }
        if (!mounted) return;
        setState(() => _clientName =
            (name?.trim().isNotEmpty ?? false) ? name!.trim() : null);
      } finally {
        if (mounted) setState(() => _loadingClient = false);
      }
    }

    if ((e.primaryServiceId?.isNotEmpty ?? false)) {
      setState(() => _loadingService = true);
      try {
        String? name;
        if (widget.fetchServiceName != null) {
          name = await widget.fetchServiceName!(e.primaryServiceId!);
        } else {
          try {
            final s = await ServiceApi().getById(e.primaryServiceId!);
            name = s.name;
          } catch (_) {}
        }
        if (!mounted) return;
        setState(() => _primaryServiceName =
            (name?.trim().isNotEmpty ?? false) ? name!.trim() : null);
      } finally {
        if (mounted) setState(() => _loadingService = false);
      }
    }

    // Resolve visit service names
    final serviceIds = e.visitServices
        .map((vs) => vs.serviceId)
        .where((id) => id.trim().isNotEmpty)
        .toList();
    if (serviceIds.isNotEmpty) {
      setState(() => _loadingServices = true);
      final api = ServiceApi();
      for (final id in serviceIds) {
        try {
          final s = await api.getById(id);
          if (!mounted) return;
          _serviceNames[id] = s.name;
        } catch (_) {
          _serviceNames[id] = id;
        }
      }
      if (mounted) setState(() => _loadingServices = false);
    }
  }

  Future<void> _loadOwnerName() async {
    final ownerId = widget.event.ownerId;
    if (ownerId.isEmpty) return;
    setState(() => _loadingOwner = true);
    try {
      final userDomain = context.read<UserDomain>();
      final owner = await userDomain.getUserById(ownerId);
      if (!mounted) return;
      setState(() {
        _ownerDisplayName = _resolveDisplayName(owner);
        _ownerUsername = _resolveUsername(owner);
      });
    } catch (_) {
      if (mounted) {
        setState(() => _ownerDisplayName = _ownerDisplayName ?? ownerId);
      }
    } finally {
      if (mounted) setState(() => _loadingOwner = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);
    final isWorkVisit = (e.type.toLowerCase() == 'work_visit');
    final locale = Localizations.localeOf(context);

    final dateRange = formatDateRange(context, e.startDate, e.endDate);
    final statusLabel = statusLabelFor(
      e.status,
      pending: l.statusPending,
      inProgress: l.statusInProgress,
      done: l.statusDone,
      cancelled: l.statusCancelled,
      overdue: l.statusOverdue,
    );
    final statusColor = statusColorFor(e.status, cs);
    final eventColor = safeEventColor(e.eventColorIndex, cs);

    final clientLabel = (e.clientId?.isNotEmpty ?? false)
        ? (_loadingClient ? '...' : (_clientName ?? e.clientId!))
        : '';
    final primaryServiceLabel = (e.primaryServiceId?.isNotEmpty ?? false)
        ? (_loadingService
            ? '...'
            : (_primaryServiceName ?? e.primaryServiceId!))
        : '';
    final ownerLabel = _ownerDisplayName ??
        (_loadingOwner
            ? '...'
            : (e.ownerId.isNotEmpty ? e.ownerId : null));

    final recText = e.recurrenceRule != null
        ? buildRecurrenceText(e.recurrenceRule, e.startDate, locale)
        : '';

    return Scaffold(
      backgroundColor: cs.surface,
      body: Column(
        children: [
          // ── Compact top bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 8, 0),
            child: Row(
              children: [
                Icon(Icons.event_note_rounded, size: 16, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l.eventDetailsTitle,
                    style: typo.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                if (widget.onShare != null)
                  IconButton(
                    icon: Icon(Icons.ios_share, size: 16, color: cs.primary),
                    tooltip: l.shareButtonTooltip,
                    onPressed: widget.onShare,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),

          // ── Scrollable content ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
              children: [
                // ── Header: color dot + title ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(top: 5, right: 10),
                      decoration: BoxDecoration(
                        color: eventColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        e.title.isEmpty ? l.untitledEvent : e.title,
                        style: typo.bodyLarge.copyWith(
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // ── Status + type badges ──
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildBadge(
                      context,
                      icon: Icons.label_important_outline,
                      label: statusLabel,
                      color: statusColor,
                    ),
                    if (isWorkVisit)
                      _buildBadge(
                        context,
                        icon: Icons.build_outlined,
                        label: l.workVisitBadge,
                        color: cs.tertiary,
                      ),
                    if (e.allDay)
                      _buildBadge(
                        context,
                        icon: Icons.wb_sunny_outlined,
                        label: 'Todo el dia',
                        color: Colors.orange,
                      ),
                  ],
                ),

                const SizedBox(height: 16),
                _divider(cs),
                const SizedBox(height: 14),

                // ── Details rows ──
                _buildDetailRow(
                  context,
                  icon: Icons.schedule_rounded,
                  label: l.eventWhenLabel,
                  value: dateRange,
                ),
                if (ownerLabel != null)
                  _buildDetailRow(
                    context,
                    icon: Icons.person_outline_rounded,
                    label: l.createdByLabel,
                    value: _ownerUsername != null
                        ? '$ownerLabel  $_ownerUsername'
                        : ownerLabel,
                  ),
                if (e.localization != null &&
                    e.localization!.trim().isNotEmpty)
                  _buildDetailRow(
                    context,
                    icon: Icons.location_on_outlined,
                    label: l.eventLocationHint,
                    value: e.localization!.trim(),
                  ),
                if (e.description != null &&
                    e.description!.trim().isNotEmpty)
                  _buildDetailRow(
                    context,
                    icon: Icons.description_outlined,
                    label: l.eventDescriptionHint,
                    value: e.description!.trim(),
                  ),
                if (e.note != null && e.note!.trim().isNotEmpty)
                  _buildDetailRow(
                    context,
                    icon: Icons.sticky_note_2_outlined,
                    label: l.eventNoteHint,
                    value: e.note!.trim(),
                  ),
                if (recText.isNotEmpty)
                  _buildDetailRow(
                    context,
                    icon: Icons.repeat_rounded,
                    label: l.eventRecurrenceHint,
                    value: recText,
                  ),

                // ── Work visit section ──
                if (isWorkVisit &&
                    (clientLabel.isNotEmpty ||
                        primaryServiceLabel.isNotEmpty)) ...[
                  const SizedBox(height: 8),
                  _divider(cs),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Icon(Icons.work_outline_rounded,
                          size: 14, color: cs.tertiary),
                      const SizedBox(width: 6),
                      Text(
                        l.workVisitSectionTitle,
                        style: typo.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.tertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (clientLabel.isNotEmpty)
                    _buildDetailRow(
                      context,
                      icon: Icons.person_pin_circle_outlined,
                      label: l.clientLabel,
                      value: clientLabel,
                    ),
                  if (primaryServiceLabel.isNotEmpty)
                    _buildDetailRow(
                      context,
                      icon: Icons.home_repair_service_outlined,
                      label: l.servicePrimaryLabel,
                      value: primaryServiceLabel,
                    ),
                  if (e.visitServices.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      l.services,
                      style: typo.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final vs in e.visitServices)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: cs.secondaryContainer
                                  .withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _loadingServices
                                  ? '...'
                                  : (_serviceNames[vs.serviceId] ??
                                      vs.serviceId),
                              style: typo.caption.copyWith(
                                fontWeight: FontWeight.w600,
                                color: cs.onSecondaryContainer,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],

                // ── Actions ──
                if (widget.onEdit != null ||
                    widget.onDuplicate != null ||
                    widget.onDelete != null) ...[
                  const SizedBox(height: 20),
                  _divider(cs),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      if (widget.onEdit != null)
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: widget.onEdit,
                            icon: const Icon(Icons.edit_outlined, size: 15),
                            label: Text(
                              l.editAction,
                              style: typo.caption.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: cs.primary,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      if (widget.onEdit != null &&
                          widget.onDuplicate != null)
                        const SizedBox(width: 10),
                      if (widget.onDuplicate != null)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: widget.onDuplicate,
                            icon: Icon(Icons.copy_all_outlined,
                                size: 15, color: cs.onSurface),
                            label: Text(
                              l.duplicateAction,
                              style: typo.caption.copyWith(
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                  color: cs.outlineVariant
                                      .withValues(alpha: 0.5)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      if (widget.onDelete != null &&
                          (widget.onEdit != null ||
                              widget.onDuplicate != null))
                        const SizedBox(width: 10),
                      if (widget.onDelete != null)
                        _DeleteButton(onDelete: widget.onDelete!),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final typo = AppTypography.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: typo.caption.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: cs.primary.withValues(alpha: 0.7)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: typo.caption.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: typo.bodySmall.copyWith(
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(ColorScheme cs) {
    return Divider(
      height: 1,
      color: cs.outlineVariant.withValues(alpha: 0.3),
    );
  }

  String _resolveDisplayName(User user) {
    final dn = (user.displayName ?? '').trim();
    if (dn.isNotEmpty) return dn;
    if (user.name.trim().isNotEmpty) return user.name.trim();
    if (user.userName.trim().isNotEmpty) return user.userName.trim();
    final email = user.email.trim();
    return email.contains('@') ? email.split('@').first : 'User';
  }

  String? _resolveUsername(User user) {
    final handle = user.userName.trim();
    if (handle.isEmpty) return null;
    final at = handle.startsWith('@') ? handle : '@$handle';
    if ((user.displayName ?? '').trim() == at || user.name.trim() == at) {
      return null;
    }
    return at;
  }
}

// ── Delete button with built-in confirmation dialog ───────────────────────────

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.onDelete});

  final VoidCallback onDelete;

  Future<void> _confirm(BuildContext context) async {
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';
    final cs = Theme.of(context).colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: cs.errorContainer.withValues(alpha: 0.35),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.delete_outline_rounded,
              size: 24, color: cs.error),
        ),
        title: Text(
          isSpanish ? 'Eliminar evento' : 'Delete event',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        content: Text(
          isSpanish
              ? '¿Seguro que quieres eliminar este evento? Esta acción no se puede deshacer.'
              : 'Are you sure you want to delete this event? This cannot be undone.',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 13,
              color: Theme.of(ctx).colorScheme.onSurfaceVariant),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding:
            const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(isSpanish ? 'Cancelar' : 'Cancel'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: cs.onError,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(isSpanish ? 'Eliminar' : 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) onDelete();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return OutlinedButton.icon(
      onPressed: () => _confirm(context),
      icon: Icon(Icons.delete_outline_rounded, size: 15, color: cs.error),
      label: Text(
        Localizations.localeOf(context).languageCode == 'es'
            ? 'Eliminar'
            : 'Delete',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: cs.error,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: cs.error.withValues(alpha: 0.45)),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
