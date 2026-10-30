import 'package:hexora/presentation/shared/widgets/hexora_list_row.dart';
import 'package:hexora/presentation/screens/workspace/sections/services_clients/widgets/client_filter_controls.dart';
import 'package:flutter/material.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/presentation/screens/workspace/sections/services_clients/widgets/clients_search_filters.dart';
import 'package:hexora/presentation/screens/workspace/sections/services_clients/widgets/common_views.dart';
import 'package:hexora/presentation/shared/widgets/buttons/buttons.dart';
import 'package:hexora/theme/colors/theme_colors.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class ClientsListPanel extends StatefulWidget {
  final List<GroupClient> allClients;
  final List<GroupClient> filteredClients;
  final GroupClient? selectedClient;
  final bool selectedHiddenByFilters;
  final bool hideInactive;
  final VoidCallback onToggleHideInactive;
  final bool missingCurrentMonthInvoiceOnly;
  final ValueChanged<bool> onToggleMissingCurrentMonthInvoiceOnly;
  final TextEditingController searchController;
  final VoidCallback onSearchChanged;
  final String? entityFilter;
  final String? propertyFilter;
  final List<String> entityOptions;
  final List<String> propertyOptions;

  final VoidCallback onClearFilters;
  final ValueChanged<String> onToggleEntityFilter;
  final ValueChanged<String> onTogglePropertyFilter;
  final VoidCallback onClearEntityFilter;
  final VoidCallback onClearPropertyFilter;
  final ValueChanged<GroupClient> onSelectClient;
  final VoidCallback? onAddClient;
  final VoidCallback? onRefresh;
  final bool refreshing;

  const ClientsListPanel({
    super.key,
    required this.allClients,
    required this.filteredClients,
    required this.selectedClient,
    required this.selectedHiddenByFilters,
    required this.hideInactive,
    required this.onToggleHideInactive,
    required this.missingCurrentMonthInvoiceOnly,
    required this.onToggleMissingCurrentMonthInvoiceOnly,
    required this.searchController,
    required this.onSearchChanged,
    required this.entityFilter,
    required this.propertyFilter,
    required this.entityOptions,
    required this.propertyOptions,
    required this.onClearFilters,
    required this.onToggleEntityFilter,
    required this.onTogglePropertyFilter,
    required this.onClearEntityFilter,
    required this.onClearPropertyFilter,
    required this.onSelectClient,
    this.onAddClient,
    this.onRefresh,
    this.refreshing = false,
  });

  @override
  State<ClientsListPanel> createState() => _ClientsListPanelState();
}

class _ClientsListPanelState extends State<ClientsListPanel> {
  String _status = 'all';
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final hasInvoiceFlagData =
        widget.allClients.any((c) => c.hasCurrentMonthInvoiceFlagData);
    final missingInvoiceCount = widget.allClients
        .where((c) => c.missingCurrentMonthInvoice == true)
        .length;
    final countsSource = widget.missingCurrentMonthInvoiceOnly
        ? widget.allClients
            .where((c) => c.missingCurrentMonthInvoice == true)
            .toList(growable: false)
        : widget.allClients;
    final visibleClients = widget.filteredClients
        .where((client) =>
            _status == 'all' ||
            (_status == 'active'
                ? client.isActive != false
                : client.isActive == false))
        .toList(growable: false);
    final hasSearch = widget.searchController.text.trim().isNotEmpty;
    final hasStructuredFilters =
        (widget.entityFilter ?? '').trim().isNotEmpty ||
            (widget.propertyFilter ?? '').trim().isNotEmpty ||
            _status != 'all';

    return Card(
      color: Colors.transparent,
      elevation: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: ClientsSearchFilters(
              searchController: widget.searchController,
              onSearchChanged: widget.onSearchChanged,
              searchHint: l.clientSearchHint,
              padding: EdgeInsets.zero,
              clientsForCounts: countsSource,
              statusValue: widget.hideInactive ? 'active' : _status,
              onStatusChanged: (value) {
                setState(() => _status = value);
                if (value != 'active' && widget.hideInactive) {
                  widget.onToggleHideInactive();
                }
              },
              activeCountLabel: l.activeClientsSection,
              inactiveCountLabel: l.statusInactive,
              // The Todos / Activos / Inactivos segments already cover
              // hiding inactive clients, so no separate switch here.
              countInactiveAsFilter: false,
              clearInactiveOnClear: false,
              inactiveValueMeansHidden: true,
              moveSummaryIntoFilters: true,
              // Keep interactive filters in the panel tree. A MenuAnchor is
              // removed while its hovered children rebuild on Flutter Web,
              // which can re-enter MouseTracker and trip its scheduler assert.
              filtersInMenu: false,
              // Keep the monthly-invoice toggle beside the status segments;
              // entity/property selectors use the compact row below.
              additionalFiltersInFilterBody: false,
              additionalFilters: ClientMissingInvoiceFilter(
                  count: hasInvoiceFlagData ? missingInvoiceCount : null,
                  selected: widget.missingCurrentMonthInvoiceOnly,
                  onTap: () => widget.onToggleMissingCurrentMonthInvoiceOnly(
                      !widget.missingCurrentMonthInvoiceOnly)),
              extraActiveFilterCount:
                  (widget.missingCurrentMonthInvoiceOnly ? 1 : 0) +
                      (_status != 'all' ? 1 : 0),
              onClearFilters: () {
                setState(() => _status = 'all');
                widget.onClearFilters();
              },
              entityLabel: l.clientEntityTypeLabel,
              entityOptions: widget.entityOptions,
              entityFilter: widget.entityFilter,
              onToggleEntity: widget.onToggleEntityFilter,
              onClearEntity: widget.onClearEntityFilter,
              propertyLabel: l.clientPropertyKindLabel,
              propertyOptions: widget.propertyOptions,
              propertyFilter: widget.propertyFilter,
              onToggleProperty: widget.onTogglePropertyFilter,
              onClearProperty: widget.onClearPropertyFilter,
              trailingActions: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.onRefresh != null)
                      HexoraButton.iconOnly(
                        onPressed: widget.refreshing ? null : widget.onRefresh,
                        tooltip: l.refreshAction,
                        icon: Icons.refresh_rounded,
                        loading: widget.refreshing,
                        variant: HexoraButtonVariant.secondary,
                        size: HexoraButtonSize.large,
                      ),
                    if (widget.onRefresh != null && widget.onAddClient != null)
                      const SizedBox(width: 4),
                    if (widget.onAddClient != null)
                      HexoraButton.iconOnly(
                        onPressed: widget.onAddClient,
                        tooltip: l.addClient,
                        icon: Icons.person_add_outlined,
                        size: HexoraButtonSize.large,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: widget.allClients.isEmpty
                ? EmptyView(
                    icon: Icons.person_outline,
                    title: l.noClientsYet,
                    subtitle: l.noClientsYet,
                    cta: widget.onAddClient != null ? l.addClient : null,
                    onPressed: widget.onAddClient,
                  )
                : visibleClients.isEmpty
                    ? EmptyView(
                        icon: widget.missingCurrentMonthInvoiceOnly &&
                                !hasSearch &&
                                !hasStructuredFilters
                            ? (hasInvoiceFlagData
                                ? Icons.verified_outlined
                                : Icons.hourglass_empty_rounded)
                            : Icons.search_off_rounded,
                        title: widget.missingCurrentMonthInvoiceOnly &&
                                !hasSearch &&
                                !hasStructuredFilters
                            ? (hasInvoiceFlagData
                                ? l.clientAllHaveInvoiceTitle
                                : l.clientInvoiceStatusUnavailableTitle)
                            : l.clientNoMatchFiltersTitle,
                        subtitle: widget.missingCurrentMonthInvoiceOnly &&
                                !hasSearch &&
                                !hasStructuredFilters
                            ? (hasInvoiceFlagData
                                ? l.clientAllHaveInvoiceDesc
                                : l.clientInvoiceStatusUnavailableDesc)
                            : l.clientNoMatchFiltersDesc,
                      )
                    : Column(
                        children: [
                          if (widget.selectedHiddenByFilters ||
                              (widget.selectedClient != null &&
                                  !visibleClients.any((client) =>
                                      client.id == widget.selectedClient!.id)))
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: cs.outlineVariant.withValues(
                                      alpha: 0.35,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.filter_alt_outlined,
                                      size: 18,
                                      color: cs.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        l.clientSelectedHiddenByFilters,
                                        style: t.bodySmall.copyWith(
                                          color: cs.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: widget.onClearFilters,
                                      child: Text(l.clientFiltersClear),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: visibleClients.length,
                              itemBuilder: (_, i) {
                                final c = visibleClients[i];
                                return _ClientRow(
                                  client: c,
                                  selected: widget.selectedClient?.id == c.id,
                                  onTap: () => widget.onSelectClient(c),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

class _ClientRow extends StatelessWidget {
  final GroupClient client;
  final bool selected;
  final VoidCallback onTap;

  const _ClientRow({
    required this.client,
    required this.selected,
    required this.onTap,
  });

  static String _clean(String? v) => (v ?? '').trim();

  static String _capitalize(String v) =>
      v.isEmpty ? v : v[0].toUpperCase() + v.substring(1);

  /// One concise secondary line: the client's category, falling back to the
  /// legal name only when it adds information, then the email.
  String? _secondary() {
    final property = _clean(client.propertyKind);
    if (property.isNotEmpty) return _capitalize(property);
    final entity = _clean(client.entityType);
    if (entity.isNotEmpty) return _capitalize(entity);
    final legal = _clean(client.billing?.legalName);
    final name = client.name.trim().toLowerCase();
    if (legal.isNotEmpty && !legal.toLowerCase().contains(name)) return legal;
    final email = _clean(client.email);
    return email.isEmpty ? null : email;
  }

  /// Full metadata, still available on hover.
  String _details() {
    final seen = <String>{};
    return [
      _clean(client.billing?.legalName),
      _clean(client.entityType),
      _clean(client.propertyKind),
      _clean(client.email),
    ].where((v) => v.isNotEmpty && seen.add(v.toLowerCase())).join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    final title = client.name.trim();
    final secondary = _secondary();
    final details = _details();
    final initial = title.isEmpty ? '?' : title[0].toUpperCase();

    Widget summary = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: t.bodyMedium.copyWith(
            fontSize: HexoraTypography.body,
            fontWeight: FontWeight.w600,
            color: ThemeColors.textPrimary(context),
          ),
        ),
        if (secondary != null) ...[
          const SizedBox(height: 2),
          Text(
            secondary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.bodySmall.copyWith(
              fontSize: HexoraTypography.caption,
              fontWeight: FontWeight.w400,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
    if (details.isNotEmpty && details != secondary) {
      summary = Tooltip(
        message: details,
        waitDuration: const Duration(milliseconds: 600),
        child: summary,
      );
    }

    return HexoraListRow(
      selected: selected,
      onTap: onTap,
      minHeight: 56,
      verticalPadding: 6,
      child: Row(children: [
        // Neutral avatars: identity comes from the name, not a loud color.
        CircleAvatar(
          radius: 16,
          backgroundColor:
              selected ? cs.primaryContainer : cs.surfaceContainerHighest,
          child: Text(
            initial,
            style: t.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: summary),
        if (_buildTrailing(l, cs) case final trailing?) ...[
          const SizedBox(width: 8),
          trailing,
        ],
      ]),
    );
  }

  Widget? _buildTrailing(AppLocalizations l, ColorScheme cs) {
    final parts = <Widget>[];

    if (client.missingCurrentMonthInvoice == true) {
      parts.add(
        Tooltip(
          message: l.clientMissingInvoiceThisMonth,
          child: Icon(Icons.receipt_long_outlined, size: 16, color: cs.error),
        ),
      );
    }

    if (!client.isActive) {
      if (parts.isNotEmpty) parts.add(const SizedBox(width: 6));
      parts.add(
        Tooltip(
          message: l.statusInactive,
          child: Icon(
            Icons.pause_circle_outline,
            size: 16,
            color: cs.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
      );
    }

    if (parts.isEmpty) return null;
    return Row(mainAxisSize: MainAxisSize.min, children: parts);
  }
}
