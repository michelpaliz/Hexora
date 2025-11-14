import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/client/client_api.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/service/service_api_client.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/event_screen/event_detail/sections/work_visit/work_visit_section.dart';
// Shared widgets
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/event_screen/graphs/graphs_section.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/event_screen/widgets/action_bar.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/event_screen/widgets/header_card.dart';
// Theme / i18n
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

// Sections
import 'sections/details_section.dart';
// Helpers
import 'widgets/detail_utils.dart';
import 'widgets/section_surface.dart'; // <-- NEW: generic card shell

typedef ClientNameFetcher = Future<String?> Function(String id);
typedef ServiceNameFetcher = Future<String?> Function(String id);

class EventDetailScreen extends StatefulWidget {
  final Event event;
  final ClientNameFetcher? fetchClientName;
  final ServiceNameFetcher? fetchServiceName;
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

    final clientLabel = (e.clientId?.isNotEmpty ?? false)
        ? (_loadingClient ? '…' : (_clientName ?? e.clientId!))
        : '';
    final primaryServiceLabel = (e.primaryServiceId?.isNotEmpty ?? false)
        ? (_loadingService ? '…' : (_primaryServiceName ?? e.primaryServiceId!))
        : '';

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        centerTitle: true,
        title: Text(
          l.eventDetailsTitle,
          style: typo.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: l.shareButtonTooltip,
            icon: Icon(Icons.ios_share, color: cs.primary),
            onPressed: widget.onShare ??
                () => ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(l.soonLabel))),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // HEADER in a Card
          SectionSurface(
            child: HeaderCard(
              title: e.title,
              isDark: Theme.of(context).brightness == Brightness.dark,
              eventColor: safeEventColor(e.eventColorIndex, cs),
              statusLabel: statusLabel,
              statusColor: statusColor,
              isWorkVisit: isWorkVisit,
            ),
          ),

          const SizedBox(height: 12),

          // DETAILS (already uses SectionCard internally)
          DetailsSection(
            dateRange: dateRange,
            location: e.localization?.trim(),
            description: e.description?.trim(),
            note: e.note?.trim(),
            recurrenceText: e.recurrenceRule == null
                ? null
                : buildRecurrenceText(e.recurrenceRule, e.startDate, locale),
          ),

          if (isWorkVisit) ...[
            const SizedBox(height: 12),
            // WORK VISIT (already uses SectionCard internally)
            WorkVisitSection(
              clientLabel: clientLabel,
              primaryServiceLabel: primaryServiceLabel,
              visitServices: e.visitServices.map((vs) => vs.serviceId).toList(),
            ),
          ],

          const SizedBox(height: 12),

          // GRAPHS in a Card
          const SectionSurface(
            child: GraphsSection(),
          ),

          const SizedBox(height: 28),

          // ACTIONS in a Card (optional but keeps consistency)
          SectionSurface(
            child: ActionBar(
              onPrimary: widget.onEdit ??
                  () => ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(l.soonLabel))),
              onSecondary: widget.onDuplicate ??
                  () => ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(l.soonLabel))),
            ),
          ),
        ],
      ),
    );
  }
}
