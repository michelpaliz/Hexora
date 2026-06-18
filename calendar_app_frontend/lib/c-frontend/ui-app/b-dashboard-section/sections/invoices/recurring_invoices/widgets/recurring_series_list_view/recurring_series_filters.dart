import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/utils/recurrence_frequency.dart';

/// Modern filter bar for the recurring invoices list.
///
/// Layout:
///   [🔍 Search field ──────────────────────────────────────]
///   [Estado ▾]  [Cliente ▾]  [⏰ Vencen pronto]  [👁 Inactivos]  | Limpiar
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
  final List<String> frequencyOptions;
  final String? selectedFrequency;
  final ValueChanged<String> onFrequencySelected;
  final VoidCallback onFrequencyClear;
  final bool dueSoonOnly;
  final ValueChanged<bool> onDueSoonChanged;
  final bool showInactiveClients;
  final ValueChanged<bool> onShowInactiveChanged;
  final bool sortByClientName;
  final ValueChanged<bool> onSortByClientNameChanged;
  final List<String> activeFilters;
  final VoidCallback onClearFilters;

  // The "all" status label — when selected it means "no status filter".
  // We receive it already localised via [statusOptions] index 0.
  final String? allStatusLabel;

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
    required this.frequencyOptions,
    required this.selectedFrequency,
    required this.onFrequencySelected,
    required this.onFrequencyClear,
    required this.dueSoonOnly,
    required this.onDueSoonChanged,
    required this.showInactiveClients,
    required this.onShowInactiveChanged,
    required this.sortByClientName,
    required this.onSortByClientNameChanged,
    required this.activeFilters,
    required this.onClearFilters,
    this.allStatusLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    // The "all" option is always index 0 in statusOptions.
    final allLabel =
        allStatusLabel ?? (statusOptions.isNotEmpty ? statusOptions.first : '');
    final isStatusFiltered = selectedStatus != allLabel;

    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Search bar ──────────────────────────────────────────────────────
        TextField(
          controller: searchController,
          onChanged: (_) => onSearchChanged(),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: l.clientSearchHint,
            filled: true,
            fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.7),
            border: fieldBorder,
            enabledBorder: fieldBorder,
            focusedBorder: fieldBorder.copyWith(
              borderSide: BorderSide(color: cs.primary, width: 1.4),
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            suffixIcon: searchController.text.trim().isEmpty
                ? null
                : IconButton(
                    tooltip:
                        MaterialLocalizations.of(context).deleteButtonTooltip,
                    onPressed: () {
                      searchController.clear();
                      onSearchChanged();
                    },
                    icon: const Icon(Icons.close),
                  ),
          ),
          style: t.bodySmall.copyWith(fontSize: 13),
        ),

        const SizedBox(height: 8),

        // ── Filter chips row ────────────────────────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Status dropdown chip
              _DropdownFilterChip(
                icon: Icons.flag_outlined,
                label: l.recurringInvoicesStatusFilterLabel,
                activeValue: isStatusFiltered ? selectedStatus : null,
                options: statusOptions,
                onSelected: onStatusSelected,
                onClear: onStatusClear,
              ),
              const SizedBox(width: 6),

              // Client searchable chip
              _SearchableFilterChip(
                icon: Icons.person_outline_rounded,
                label: l.recurringInvoicesClientFilterLabel,
                activeValue: selectedClient,
                options: clientOptions,
                onSelected: onClientSelected,
                onClear: onClientClear,
              ),
              const SizedBox(width: 6),

              if (frequencyOptions.isNotEmpty) ...[
                _DropdownFilterChip(
                  icon: Icons.repeat_rounded,
                  label: l.recurringInvoicesFrequencyLabel,
                  activeValue: selectedFrequency == null
                      ? null
                      : recurringFrequencyLabel(l, selectedFrequency),
                  options: frequencyOptions
                      .map((value) => recurringFrequencyLabel(l, value))
                      .toList(growable: false),
                  onSelected: (label) {
                    final match = frequencyOptions.firstWhere(
                      (value) => recurringFrequencyLabel(l, value) == label,
                      orElse: () => frequencyOptions.first,
                    );
                    onFrequencySelected(match);
                  },
                  onClear: onFrequencyClear,
                ),
                const SizedBox(width: 6),
              ],

              // Due soon toggle chip
              _ToggleFilterChip(
                icon: Icons.alarm_outlined,
                label: l.recurringInvoicesDueSoon,
                selected: dueSoonOnly,
                onToggle: onDueSoonChanged,
              ),
              const SizedBox(width: 6),

              // Show inactive clients toggle chip
              _ToggleFilterChip(
                icon: Icons.visibility_outlined,
                label: showInactiveClients
                    ? l.hideInactiveClients
                    : l.showInactiveClients,
                selected: showInactiveClients,
                onToggle: onShowInactiveChanged,
              ),
              const SizedBox(width: 6),
              _ToggleFilterChip(
                icon: Icons.sort_by_alpha_rounded,
                label: 'A-Z cliente',
                selected: sortByClientName,
                onToggle: onSortByClientNameChanged,
              ),

              // Clear all — shown only when any filter is active
              if (activeFilterCount > 0) ...[
                const SizedBox(width: 10),
                Container(
                  height: 20,
                  width: 1,
                  color: cs.outlineVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: onClearFilters,
                  icon: const Icon(Icons.close_rounded, size: 13),
                  label: Text(l.clientFiltersClear),
                  style: TextButton.styleFrom(
                    foregroundColor: cs.onSurfaceVariant,
                    visualDensity: VisualDensity.compact,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    textStyle: t.bodySmall
                        .copyWith(fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ── Shared chip button ─────────────────────────────────────────────────────────

class _ChipButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? activeValue;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _ChipButton({
    required this.icon,
    required this.label,
    required this.activeValue,
    required this.isActive,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);

    final chipColor = isActive ? cs.primaryContainer : Colors.transparent;
    final borderColor = isActive
        ? cs.primary.withValues(alpha: 0.55)
        : cs.outlineVariant.withValues(alpha: 0.55);
    final contentColor = isActive ? cs.onPrimaryContainer : cs.onSurfaceVariant;
    final displayText = isActive ? '$label: $activeValue' : label;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(left: 10, top: 6, bottom: 6, right: 6),
        decoration: BoxDecoration(
          color: chipColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: contentColor),
            const SizedBox(width: 5),
            Text(
              displayText,
              style: t.bodySmall.copyWith(
                color: contentColor,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 4),
            // Right icon: X to clear when active, arrow when not
            if (isActive && onClear != null)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onClear,
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    Icons.close_rounded,
                    size: 13,
                    color: contentColor.withValues(alpha: 0.75),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 15,
                  color: contentColor.withValues(alpha: 0.6),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Dropdown filter chip (uses MenuAnchor) ─────────────────────────────────────

class _DropdownFilterChip extends StatefulWidget {
  final IconData icon;
  final String label;
  final String? activeValue;
  final List<String> options;
  final ValueChanged<String> onSelected;
  final VoidCallback onClear;

  const _DropdownFilterChip({
    required this.icon,
    required this.label,
    required this.activeValue,
    required this.options,
    required this.onSelected,
    required this.onClear,
  });

  @override
  State<_DropdownFilterChip> createState() => _DropdownFilterChipState();
}

class _DropdownFilterChipState extends State<_DropdownFilterChip> {
  final MenuController _menu = MenuController();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final isActive = widget.activeValue != null;

    return MenuAnchor(
      controller: _menu,
      style: MenuStyle(
        elevation: const WidgetStatePropertyAll(6),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        backgroundColor: WidgetStatePropertyAll(cs.surfaceContainerHigh),
        padding:
            const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 4)),
      ),
      menuChildren: widget.options.map((opt) {
        final isSel = widget.activeValue == opt;
        return MenuItemButton(
          onPressed: () {
            _menu.close();
            widget.onSelected(opt);
          },
          leadingIcon: isSel
              ? Icon(Icons.check_rounded, size: 15, color: cs.primary)
              : const SizedBox(width: 15),
          style: const ButtonStyle(
            minimumSize: WidgetStatePropertyAll(Size(160, 36)),
            padding: WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
          ),
          child: Text(
            opt,
            style: t.bodySmall.copyWith(
              fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
              color: isSel ? cs.primary : cs.onSurface,
              fontSize: 13,
            ),
          ),
        );
      }).toList(),
      builder: (context, controller, _) => _ChipButton(
        icon: widget.icon,
        label: widget.label,
        activeValue: widget.activeValue,
        isActive: isActive,
        onTap: () => controller.isOpen ? controller.close() : controller.open(),
        onClear: isActive
            ? () {
                controller.close();
                widget.onClear();
              }
            : null,
      ),
    );
  }
}

// ── Searchable filter chip (opens compact dialog) ──────────────────────────────

class _SearchableFilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? activeValue;
  final List<String> options;
  final ValueChanged<String> onSelected;
  final VoidCallback onClear;

  const _SearchableFilterChip({
    required this.icon,
    required this.label,
    required this.activeValue,
    required this.options,
    required this.onSelected,
    required this.onClear,
  });

  Future<void> _openPicker(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => _PickerDialog(
        label: label,
        options: options,
        activeValue: activeValue,
      ),
    );
    if (result != null) onSelected(result);
  }

  @override
  Widget build(BuildContext context) {
    final isActive = activeValue != null;
    return _ChipButton(
      icon: icon,
      label: label,
      activeValue: activeValue,
      isActive: isActive,
      onTap: () => _openPicker(context),
      onClear: isActive ? onClear : null,
    );
  }
}

// ── Toggle filter chip ─────────────────────────────────────────────────────────

class _ToggleFilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final ValueChanged<bool> onToggle;

  const _ToggleFilterChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);

    final chipColor = selected ? cs.primaryContainer : Colors.transparent;
    final borderColor = selected
        ? cs.primary.withValues(alpha: 0.55)
        : cs.outlineVariant.withValues(alpha: 0.55);
    final contentColor = selected ? cs.onPrimaryContainer : cs.onSurfaceVariant;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => onToggle(!selected),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: chipColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.check_rounded : icon,
              size: 13,
              color: contentColor,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: t.bodySmall.copyWith(
                color: contentColor,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Picker dialog (for searchable client picker) ───────────────────────────────

class _PickerDialog extends StatefulWidget {
  final String label;
  final List<String> options;
  final String? activeValue;

  const _PickerDialog({
    required this.label,
    required this.options,
    required this.activeValue,
  });

  @override
  State<_PickerDialog> createState() => _PickerDialogState();
}

class _PickerDialogState extends State<_PickerDialog> {
  final TextEditingController _search = TextEditingController();
  List<String> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.options;
  }

  void _onSearch(String q) {
    final lower = q.trim().toLowerCase();
    setState(() {
      _filtered = lower.isEmpty
          ? widget.options
          : widget.options
              .where((o) => o.toLowerCase().contains(lower))
              .toList();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360, maxHeight: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
              child: Row(
                children: [
                  Icon(Icons.person_outline_rounded,
                      size: 18, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.label,
                      style: t.bodyMedium.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),

            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                controller: _search,
                autofocus: true,
                onChanged: _onSearch,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, size: 18),
                  hintText: '${widget.label}…',
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.7),
                  border: fieldBorder,
                  enabledBorder: fieldBorder,
                  focusedBorder: fieldBorder.copyWith(
                    borderSide: BorderSide(color: cs.primary, width: 1.4),
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _search.clear();
                            _onSearch('');
                          },
                          icon: const Icon(Icons.close),
                        ),
                ),
                style: t.bodySmall.copyWith(fontSize: 13),
              ),
            ),

            const SizedBox(height: 8),
            Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.4)),

            // List
            Flexible(
              child: _filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off_rounded,
                              size: 32,
                              color:
                                  cs.onSurfaceVariant.withValues(alpha: 0.4)),
                          const SizedBox(height: 8),
                          Text(
                            '…',
                            style: t.bodySmall
                                .copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) {
                        final opt = _filtered[i];
                        final isSel = widget.activeValue == opt;
                        return ListTile(
                          dense: true,
                          leading: isSel
                              ? Icon(Icons.check_rounded,
                                  size: 16, color: cs.primary)
                              : const SizedBox(width: 16),
                          title: Text(
                            opt,
                            style: t.bodySmall.copyWith(
                              fontWeight:
                                  isSel ? FontWeight.w700 : FontWeight.w500,
                              color: isSel ? cs.primary : cs.onSurface,
                              fontSize: 13,
                            ),
                          ),
                          onTap: () => Navigator.pop(context, opt),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
