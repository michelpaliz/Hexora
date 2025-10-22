// lib/c-frontend/d-event-section/screens/event_detail/event_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:hexora/b-backend/business_logic/client/client_api.dart';
import 'package:hexora/b-backend/business_logic/service/service_api_client.dart';
// Widgets
import 'package:hexora/c-frontend/d-event-section/screens/event_screen/graphs/graphs_section.dart';
// Helpers
import 'package:hexora/c-frontend/d-event-section/screens/event_screen/helpers/recurrence_format.dart';
import 'package:hexora/c-frontend/d-event-section/screens/event_screen/widgets/action_bar.dart';
import 'package:hexora/c-frontend/d-event-section/screens/event_screen/widgets/header_card.dart';
import 'package:hexora/c-frontend/d-event-section/screens/event_screen/widgets/info_row.dart';
import 'package:hexora/c-frontend/d-event-section/screens/event_screen/widgets/section_card.dart';
import 'package:hexora/c-frontend/d-event-section/utils/color_manager.dart';
import 'package:hexora/f-themes/app_colors/themes/text_styles/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

typedef ClientNameFetcher = Future<String?> Function(String id);
typedef ServiceNameFetcher = Future<String?> Function(String id);

class EventDetailScreen extends StatefulWidget {
  final Event event;

  /// Optional custom fetchers; if not provided, we fallback to ClientsApi/ServiceApi.
  final ClientNameFetcher? fetchClientName;
  final ServiceNameFetcher? fetchServiceName;

  /// Optional actions
  final VoidCallback? onEdit;
  final VoidCallback? onDuplicate;
  final VoidCallback? onShare;

  const EventDetailScreen({
    super.key,
    required this.event,
    this.fetchClientName,
    this.fetchServiceName,
    this.onEdit,
    this.onDuplicate,
    this.onShare,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  String? _clientName;
  String? _primaryServiceName;
  bool _loadingClient = false;
  bool _loadingService = false;

  @override
  void initState() {
    super.initState();
    _loadNamesIfNeeded();
  }

  Future<void> _loadNamesIfNeeded() async {
    final e = widget.event;

    // --- Client name (use fetcher or ClientsApi fallback)
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
          } catch (_) {
            // keep null -> UI falls back to raw id
          }
        }
        if (!mounted) return;
        setState(() => _clientName =
            (name?.trim().isNotEmpty ?? false) ? name!.trim() : null);
      } finally {
        if (mounted) setState(() => _loadingClient = false);
      }
    }

    // --- Primary service name (use fetcher or ServiceApi fallback)
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
          } catch (_) {
            // keep null -> UI falls back to raw id
          }
        }
        if (!mounted) return;
        setState(() => _primaryServiceName =
            (name?.trim().isNotEmpty ?? false) ? name!.trim() : null);
      } finally {
        if (mounted) setState(() => _loadingService = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    final loc = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final dateRange = _formatDateRange(context, e.startDate, e.endDate);
    final statusLabel = _statusLabel(e.status, loc);
    final statusColor = _statusColor(e.status, scheme);
    final isWorkVisit = (e.type.toLowerCase() == 'work_visit');
    final locale = Localizations.localeOf(context);

    final clientLabel = (e.clientId?.isNotEmpty ?? false)
        ? (_loadingClient ? '…' : (_clientName ?? e.clientId!))
        : '';

    final primaryServiceLabel = (e.primaryServiceId?.isNotEmpty ?? false)
        ? (_loadingService ? '…' : (_primaryServiceName ?? e.primaryServiceId!))
        : '';

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        centerTitle: true,
        title: Text(
          loc.eventDetailsTitle,
          style: typo.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: loc.shareButtonTooltip,
            icon: Icon(Icons.ios_share, color: scheme.primary),
            onPressed: widget.onShare ??
                () => ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(loc.soonLabel))),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          HeaderCard(
            title: e.title,
            isDark: isDark,
            eventColor: _safeEventColor(e.eventColorIndex, scheme),
            statusLabel: statusLabel,
            statusColor: statusColor,
            isWorkVisit: isWorkVisit,
          ),

          const SizedBox(height: 12),

          // ===== Details =====
          SectionCard(
            title: loc.detailsSectionTitle,
            children: [
              InfoRow(
                icon: Icons.event_outlined,
                label: loc.eventWhenLabel,
                value: dateRange,
              ),
              if (e.localization?.trim().isNotEmpty == true)
                InfoRow(
                  icon: Icons.location_on_outlined,
                  label: loc.eventLocationHint,
                  value: e.localization!.trim(),
                ),
              if (e.description?.trim().isNotEmpty == true)
                InfoRow(
                  icon: Icons.description_outlined,
                  label: loc.eventDescriptionHint,
                  value: e.description!.trim(),
                ),
              if (e.note?.trim().isNotEmpty == true)
                InfoRow(
                  icon: Icons.sticky_note_2_outlined,
                  label: loc.eventNoteHint,
                  value: e.note!.trim(),
                ),
              if (e.recurrenceRule != null)
                InfoRow(
                  icon: Icons.repeat,
                  label: loc.eventRecurrenceHint,
                  value: formatRecurrenceRule(
                    e.recurrenceRule,
                    e.startDate,
                    locale,
                  ),
                ),
            ],
          ),

          // ===== Work visit =====
          if (isWorkVisit) ...[
            const SizedBox(height: 12),
            SectionCard(
              title: loc.workVisitSectionTitle,
              children: [
                if (clientLabel.isNotEmpty)
                  InfoRow.chip(
                    icon: Icons.person_pin_circle_outlined,
                    label: loc.clientLabel,
                    value: clientLabel,
                  ),
                if (primaryServiceLabel.isNotEmpty)
                  InfoRow.chip(
                    icon: Icons.home_repair_service_outlined,
                    label: loc.servicePrimaryLabel,
                    value: primaryServiceLabel,
                  ),
                if (e.visitServices.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: e.visitServices.map((vs) {
                      // For now, show raw ids for the list; you can batch-fetch names with Future.wait if needed.
                      final name = vs.serviceId;
                      return Chip(
                        label: Text(
                          name,
                          style: AppTypography.of(context).bodySmall.copyWith(
                                color: scheme.onSecondaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        backgroundColor: scheme.secondaryContainer,
                        side: BorderSide(
                            color: scheme.outlineVariant, width: 0.5),
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ],

          const SizedBox(height: 20),

          // ===== Graphs placeholder =====
          const GraphsSection(),

          const SizedBox(height: 28),

          ActionBar(
            onPrimary: widget.onEdit ??
                () => ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(loc.soonLabel))),
            onSecondary: widget.onDuplicate ??
                () => ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(loc.soonLabel))),
          ),
        ],
      ),
    );
  }

  // ----- helpers -----
  String _formatDateRange(BuildContext context, DateTime start, DateTime end) {
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final sameDay = start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;
    final d = DateFormat.yMMMMd(localeTag);
    final t = DateFormat.Hm(localeTag);
    return sameDay
        ? '${d.format(start)} • ${t.format(start)}–${t.format(end)}'
        : '${d.format(start)} ${t.format(start)}  —  ${d.format(end)} ${t.format(end)}';
  }

  String _statusLabel(String? status, AppLocalizations loc) {
    switch ((status ?? '').toLowerCase()) {
      case 'in_progress':
        return loc.statusInProgress;
      case 'done':
        return loc.statusDone;
      case 'cancelled':
        return loc.statusCancelled;
      case 'overdue':
        return loc.statusOverdue;
      case 'pending':
      default:
        return loc.statusPending;
    }
  }

  Color _statusColor(String? status, ColorScheme scheme) {
    switch ((status ?? '').toLowerCase()) {
      case 'in_progress':
        return scheme.primary;
      case 'done':
        return Colors.teal;
      case 'cancelled':
        return scheme.error;
      case 'overdue':
        return Colors.orange;
      case 'pending':
      default:
        return scheme.secondary;
    }
  }

  Color _safeEventColor(int index, ColorScheme scheme) {
    final palette = ColorManager.eventColors;
    if (palette.isNotEmpty && index >= 0 && index < palette.length) {
      return palette[index];
    }
    return scheme.primary;
  }
}
