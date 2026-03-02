import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/clients_view/chip_rows.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/widgets/clients_search_filters.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class RecurringSeriesFilters extends StatelessWidget {
  final TextEditingController searchController;
  final VoidCallback onSearchChanged;
  final int activeFilterCount;
  final List<String> statusOptions;
  final String selectedStatus;
  final ValueChanged<String> onStatusSelected;
  final VoidCallback onStatusClear;
  final List<String> clientOptions;
  final String? selectedClient;
  final ValueChanged<String> onClientSelected;
  final VoidCallback onClientClear;
  final bool dueSoonOnly;
  final ValueChanged<bool> onDueSoonChanged;
  final bool showInactiveClients;
  final ValueChanged<bool> onShowInactiveChanged;
  final List<String> activeFilters;
  final VoidCallback onClearFilters;

  const RecurringSeriesFilters({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.activeFilterCount,
    required this.statusOptions,
    required this.selectedStatus,
    required this.onStatusSelected,
    required this.onStatusClear,
    required this.clientOptions,
    required this.selectedClient,
    required this.onClientSelected,
    required this.onClientClear,
    required this.dueSoonOnly,
    required this.onDueSoonChanged,
    required this.showInactiveClients,
    required this.onShowInactiveChanged,
    required this.activeFilters,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: ClientsSearchFilters(
        searchController: searchController,
        onSearchChanged: onSearchChanged,
        searchHint: l.clientSearchHint,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        extraActiveFilterCount: activeFilterCount,
        autoExpandWhenActive: false,
        additionalFilters: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FilterChipRow(
              label: l.recurringInvoicesStatusFilterLabel,
              options: statusOptions,
              selected: selectedStatus,
              onToggle: onStatusSelected,
              onClear: onStatusClear,
            ),
            const SizedBox(height: 10),
            FilterChipRow(
              label: l.recurringInvoicesClientFilterLabel,
              options: clientOptions,
              selected: selectedClient,
              onToggle: onClientSelected,
              onClear: onClientClear,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: Text(l.recurringInvoicesDueSoon),
                  selected: dueSoonOnly,
                  onSelected: onDueSoonChanged,
                  selectedColor: cs.primaryContainer,
                  checkmarkColor: cs.onPrimaryContainer,
                ),
                FilterChip(
                  label: Text(showInactiveClients
                      ? l.hideInactiveClients
                      : l.showInactiveClients),
                  selected: showInactiveClients,
                  onSelected: onShowInactiveChanged,
                ),
              ],
            ),
            if (activeFilters.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                activeFilters.join(' · '),
                style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ],
        ),
        onClearFilters: onClearFilters,
      ),
    );
  }
}
